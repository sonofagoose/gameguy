//! The world: the rules.
//!
//! No platform, no clock, no allocation. A step takes the hands and gives back cues for the
//! sound; everything else is in `World`, which is plain values all the way down. The same hands
//! make the same world on every machine (spec/engine.md).
//!
//! So far it holds the first evening's first minute: the dark, Hum, the call, and things that
//! answer; and a proof field of asters as tall as cathedrals (asters.zig). Two laws are in it.
//! Travel: a call's ring moves at the speed of sound, along the ground and up whatever stands on
//! it, lights what it passes, and an answer is heard when it has travelled back. Sympathy: a thing
//! answers as much as its own overtones share with the note that called.
//!
//! The world also keeps witnesses (witness.zig): it notes when a promise's moment happens.
const std = @import("std");
const sound = @import("../sound/sound.zig");
pub const asters = @import("asters.zig");
pub const witness = @import("witness.zig");

pub const steps_per_second = 60;
pub const samples_per_step = 800;
pub const dt: f32 = 1.0 / 60.0;
/// Metres a second. About ten times Hum's run, so a ring can be watched (to tune).
pub const sound_speed: f32 = 60.0;
pub const run_speed: f32 = 6.0;
/// The garden's note: middle C.
pub const garden_hz: f32 = 261.63;
/// Every cue is stamped at least this many samples after its step begins, so the sound thread
/// has not already passed it.
pub const lead: u64 = 1600;
/// The world is one to a hundred: Hum stands one metre, a centimetre of the real garden
/// (spec/size.md).
pub const one_to: f32 = 100.0;
pub const hum_tall: f32 = 1.0;
/// The backlight's level in the first dark, of 255 (SPEC.md 6.1).
pub const first_dark_backlight: f32 = 14.0;
/// An answer fainter than this is seen and not sounded.
pub const quietest: f32 = 0.004;

/// The view of the place. Walking: the eye sits well behind Hum and low, looking up a little, so
/// the horizon is low in the frame and Hum is small in it. Leaned back at a tall thing's foot:
/// the eye drops to the ground and the view opens wide, so Hum and the crown are in one frame.
pub const cam_back: f32 = 12.0;
pub const cam_up: f32 = 1.4;
pub const walk_pitch: f32 = 0.28;
pub const place_fov: f32 = 55.0;
pub const lean_fov: f32 = 90.0;
pub const lean_back: f32 = 9.0;
pub const lean_up: f32 = 0.5;
/// Standing still within this of a tall thing's foot, the view leans back to take it in.
pub const lean_within: f32 = 40.0;
/// How near a tower's foot counts as standing at it.
pub const at_foot: f32 = 15.0;

/// What the hands are doing. Sticks run from -127 to 127.
pub const Hands = extern struct {
    lx: i8 = 0,
    ly: i8 = 0,
    rx: i8 = 0,
    ry: i8 = 0,
    buttons: u16 = 0,

    pub const call: u16 = 1 << 0; // R1
    pub const sing: u16 = 1 << 1; // R2
    pub const voice: u16 = 1 << 2; // L1
    pub const guard: u16 = 1 << 3; // L2
    pub const jump: u16 = 1 << 4; // bottom face
    pub const dodge: u16 = 1 << 5; // right face
    pub const strike: u16 = 1 << 6; // left face
    pub const grab: u16 = 1 << 7; // top face
    pub const select: u16 = 1 << 8;
    pub const start: u16 = 1 << 9;

    pub fn held(self: Hands, button: u16) bool {
        return self.buttons & button != 0;
    }
};

/// Whether the world is being read as a page from above or stood in as a place.
pub const View = enum(u8) { page, place };

pub const no_tower: u16 = 0xffff;

pub const Thing = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    /// How high its middle is above the ground.
    y: f32 = 0.0,
    tall: f32 = 4.0,
    hz: f32 = 261.63,
    family: sound.Family = .bell,
    /// How long its lowest note rings, in seconds.
    ring: f32 = 3.0,
    /// Light left on it by a ring that passed.
    lit: f32 = 0.0,
    /// How loud it is ringing.
    loud: f32 = 0.0,
    /// How far its sound carries before it has fallen to half.
    carry: f32 = 30.0,
    /// False for a part that a passing ring lights and that makes no sound of its own.
    sounds: bool = true,
    /// The tower it is part of, if it is.
    tower: u16 = no_tower,
};

/// A tall thing with a foot: the view leans back at it, and a call climbs it.
pub const Tower = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    tall: f32 = 0.0,
    first: u32 = 0,
    count: u32 = 0,
};

pub const Ring = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    born: u64 = 0,
    live: bool = false,
};

/// A sound on its way to Hum's ears.
const Arrival = struct {
    at: u64 = 0,
    cue: sound.Cue = .{ .at = 0, .kind = .strike },
    live: bool = false,
    /// The thing whose answer this is, if it is one.
    from: u32 = no_thing,
};

const no_thing: u32 = 0xffff_ffff;
pub const max_things = 4096;
pub const max_towers = asters.max_towers;
pub const max_rings = 6;
const max_arrivals = 1024;
pub const max_cues = 32;

/// How much two notes share, by law 1: everything at a pure match, nothing at a half step.
pub fn share(cents_apart: f32) f32 {
    const d = cents_apart / 15.0;
    return @exp(-(d * d));
}

fn cents(a: f32, b: f32) f32 {
    return 1200.0 * @log2(a / b);
}

/// How much a thing answers a voice at `voice_hz`: the best match between any of the voice's
/// first eight overtones and any of the thing's, weighted by how strong each is.
pub fn sympathy(voice_hz: f32, thing_hz: f32, mult: [8]f32, gain: [8]f32) f32 {
    var best: f32 = 0.0;
    for (1..9) |n| {
        const vh = voice_hz * @as(f32, @floatFromInt(n));
        const vw = 1.0 / @as(f32, @floatFromInt(n));
        for (mult, gain) |m, g| {
            if (m <= 0.0) continue;
            best = @max(best, vw * g * share(cents(vh, thing_hz * m)));
        }
    }
    return @min(best, 1.0);
}

const bell_mult = [8]f32{ 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0 };
const bell_gain = [8]f32{ 0.30, 1.0, 0.45, 0.35, 0.55, 0.20, 0.22, 0.10 };

pub const World = struct {
    step: u64 = 0,
    hum_x: f32 = 0.0,
    hum_z: f32 = 0.0,
    /// Which way Hum faces, in radians: 0 is toward -z.
    hum_face: f32 = 0.0,
    was: u16 = 0,
    singing: bool = false,
    view: View = .page,
    /// Which way the view looks, round and up, on top of where walking points it.
    look_yaw: f32 = 0.0,
    look_tilt: f32 = 0.0,
    /// How far the view has leaned back at a tall thing's foot, 0 to 1.
    lean: f32 = 0.0,
    /// The tower Hum is nearest, and how far its foot is.
    near_tower: u16 = no_tower,
    near_far: f32 = 0.0,
    /// How many steps Hum has stood still.
    still: u32 = 0,
    /// How far a call's ring goes before it is gone.
    ring_reach: f32 = 140.0,
    towers: [max_towers]Tower = @splat(.{}),
    tower_count: u32 = 0,
    seen: witness.Table = .{},
    things: [max_things]Thing = @splat(.{}),
    thing_count: u32 = 0,
    rings: [max_rings]Ring = @splat(.{}),
    arrivals: [max_arrivals]Arrival = @splat(.{}),
    calls: u32 = 0,
    answers: u32 = 0,
    dropped: u32 = 0,

    /// The garden in the dark: things standing round where Hum wakes, some kin to its note and
    /// some not.
    pub fn init() World {
        var w = World{};
        var s: u32 = 0x2545_f491;
        // notes of the pure garden, and three that share nothing with C
        const ratios = [_]f32{ 1.0, 1.5, 1.25, 2.0, 0.75, 1.125, 1.6667, 1.4063, 1.0595, 1.8877 };
        var i: u32 = 0;
        while (i < 72) : (i += 1) {
            s ^= s << 13;
            s ^= s >> 17;
            s ^= s << 5;
            const a = @as(f32, @floatFromInt(s >> 8)) * (6.2831853 / 16777216.0);
            s ^= s << 13;
            s ^= s >> 17;
            s ^= s << 5;
            const r = 9.0 + @as(f32, @floatFromInt(s >> 8)) * (70.0 / 16777216.0);
            const ratio = ratios[i % ratios.len];
            const octave: f32 = if (i % 3 == 0) 0.5 else if (i % 3 == 1) 1.0 else 2.0;
            w.things[i] = .{
                .x = r * @cos(a),
                .z = r * @sin(a),
                .tall = 3.0 + @as(f32, @floatFromInt(i % 7)) * 1.2,
                .hz = garden_hz * ratio * octave,
                .ring = 2.0 + @as(f32, @floatFromInt(i % 5)) * 0.7,
            };
        }
        w.thing_count = 72;
        return w;
    }

    /// The proof field of asters, stood in as a place (asters.zig). Each stalk is twelve parts
    /// that a climbing call lights one after another; each flower head is a bell.
    pub fn initAsters(self: *World) void {
        self.* = .{};
        self.view = .place;
        self.ring_reach = 900.0;
        var plans: [asters.max_towers]asters.Plan = undefined;
        const n = asters.field(&plans, garden_hz);
        var at: u32 = 0;
        for (plans[0..n], 0..) |*p, t| {
            const first = at;
            const part = p.tall / @as(f32, asters.segments);
            for (0..asters.segments) |k| {
                const mid = p.mast((@as(f32, @floatFromInt(k)) + 0.5) * part);
                self.things[at] = .{ .x = mid[0], .y = mid[1], .z = mid[2], .tall = part, .sounds = false, .tower = @intCast(t) };
                at += 1;
            }
            for (p.bells[0..p.bell_n]) |bell| {
                self.things[at] = .{
                    .x = bell.pos[0],
                    .y = bell.pos[1],
                    .z = bell.pos[2],
                    .tall = bell.r,
                    .hz = bell.hz,
                    .ring = 2.6 + bell.r * 1.4,
                    .carry = 110.0,
                    .tower = @intCast(t),
                };
                at += 1;
            }
            self.towers[t] = .{ .x = p.x, .z = p.z, .tall = p.tall, .first = first, .count = at - first };
        }
        self.tower_count = @intCast(n);
        self.thing_count = at;
    }

    fn later(self: *World, at: u64, cue: sound.Cue, from: u32) void {
        for (&self.arrivals) |*slot| {
            if (slot.live) continue;
            slot.* = .{ .at = at, .cue = cue, .live = true, .from = from };
            slot.cue.at = at;
            return;
        }
        self.dropped += 1;
    }

    /// One sixtieth of a second. `cues` gets the sounds that are due before the next step ends,
    /// in the order they are due; the return is how many.
    pub fn stepOnce(self: *World, hands: Hands, cues: *[max_cues]sound.Cue) usize {
        const now_sample = self.step * samples_per_step;
        const pressed = hands.buttons & ~self.was;
        const released = self.was & ~hands.buttons;
        self.was = hands.buttons;

        // Hum walks. Stood in as a place, "up" on the stick is away from the eye.
        const mx = @as(f32, @floatFromInt(hands.lx)) * (1.0 / 127.0);
        const mz = @as(f32, @floatFromInt(hands.ly)) * (1.0 / 127.0);
        const size = @sqrt(mx * mx + mz * mz);
        if (size > 0.12) {
            const scale = @min(size, 1.0) / size * run_speed * dt;
            var wx = mx;
            var wz = mz;
            if (self.view == .place) {
                const cy = @cos(self.look_yaw);
                const sy = @sin(self.look_yaw);
                wx = cy * mx - sy * mz;
                wz = sy * mx + cy * mz;
            }
            self.hum_x += wx * scale;
            self.hum_z += wz * scale;
            self.hum_face = std.math.atan2(wx, -wz);
            self.still = 0;
        } else {
            self.still +|= 1;
        }
        if (self.view == .place) self.look(hands);

        // the call: a ring of light, and Hum's own short note
        if (pressed & Hands.call != 0) {
            self.calls += 1;
            var oldest: usize = 0;
            for (self.rings, 0..) |ring, i| {
                if (!ring.live) {
                    oldest = i;
                    break;
                }
                if (ring.born < self.rings[oldest].born) oldest = i;
            }
            self.rings[oldest] = .{ .x = self.hum_x, .z = self.hum_z, .born = self.step, .live = true };
            self.later(now_sample + lead, .{ .at = 0, .kind = .strike, .family = .string, .hz = garden_hz, .gain = 0.3, .ring = 0.35 }, no_thing);
        }

        // singing: Hum's one note, for as long as R2 is held
        if (pressed & Hands.sing != 0) {
            self.singing = true;
            self.later(now_sample + lead, .{ .at = 0, .kind = .hum_on, .hz = garden_hz, .gain = 0.35 }, no_thing);
        }
        if (released & Hands.sing != 0) {
            self.singing = false;
            self.later(now_sample + lead, .{ .at = 0, .kind = .hum_off }, no_thing);
        }

        // rings travel, along the ground and up whatever stands on it; what they pass is lit, and
        // answers as much as its own overtones share with the call
        for (&self.rings) |*ring| {
            if (!ring.live) continue;
            const age: f32 = @floatFromInt(self.step - ring.born);
            const reach = age * dt * sound_speed;
            const before = @max(0.0, reach - dt * sound_speed);
            if (reach > self.ring_reach) {
                ring.live = false;
                continue;
            }
            for (self.things[0..self.thing_count], 0..) |*thing, index| {
                const dx = thing.x - ring.x;
                const dz = thing.z - ring.z;
                const far = @sqrt(dx * dx + dz * dz + thing.y * thing.y);
                if (far <= before or far > reach) continue;
                thing.lit = 1.0;
                if (!thing.sounds) continue;
                const rec = sound.recipe(thing.family);
                const kin = sympathy(garden_hz, thing.hz, rec.mult, rec.gain);
                if (kin < 0.08) continue;
                // quieter with distance, as sound is
                const level = 0.22 * kin / (1.0 + (far / thing.carry) * (far / thing.carry));
                thing.loud = @max(thing.loud, kin);
                self.answers += 1;
                if (level < quietest) continue;
                // its answer is heard when it has come back to where Hum is now
                const hx = thing.x - self.hum_x;
                const hz = thing.z - self.hum_z;
                const back = @sqrt(hx * hx + hz * hz + thing.y * thing.y) / sound_speed;
                const delay: u64 = @intFromFloat(back * sound.rate);
                self.later(now_sample + lead + delay, .{ .at = 0, .kind = .strike, .family = thing.family, .hz = thing.hz, .gain = level, .ring = thing.ring }, @intCast(index));
            }
        }

        // light and ringing fade
        var ringing: u32 = 0;
        for (self.things[0..self.thing_count]) |*thing| {
            if (thing.lit == 0.0 and thing.loud == 0.0) continue;
            thing.lit *= 0.975;
            if (thing.lit < 0.002) thing.lit = 0.0;
            thing.loud *= @exp(-dt * 2.3 / thing.ring);
            if (thing.loud < 0.002) thing.loud = 0.0;
            if (thing.loud > 0.1) ringing += 1;
        }
        if (ringing > 0 and self.still > 0) self.seen.hold(.evening_call);
        if (self.atTallFoot() and self.still > 0 and self.lean > 0.5) self.seen.hold(.garden_asters);

        // hand over what is due before the next step ends, soonest first
        const horizon = now_sample + samples_per_step + lead;
        var n: usize = 0;
        while (n < max_cues) {
            var best: ?usize = null;
            for (self.arrivals, 0..) |a, i| {
                if (!a.live or a.at >= horizon) continue;
                if (best == null or a.at < self.arrivals[best.?].at) best = i;
            }
            const i = best orelse break;
            cues[n] = self.arrivals[i].cue;
            self.arrivals[i].live = false;
            n += 1;
            if (self.arrivals[i].from != no_thing) self.heard(self.arrivals[i].from);
        }

        self.step += 1;
        return n;
    }

    /// The view of the place: the right stick turns and tilts it, and standing still at the foot
    /// of something tall leans it back to take the thing in (SPEC.md 8: "leaning in also happens
    /// by stopping").
    fn look(self: *World, hands: Hands) void {
        const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
        const ry = @as(f32, @floatFromInt(hands.ry)) * (1.0 / 127.0);
        if (@abs(rx) > 0.15) self.look_yaw += rx * 2.2 * dt;
        if (@abs(ry) > 0.15) self.look_tilt = std.math.clamp(self.look_tilt - ry * 1.4 * dt, -0.35, 0.9);

        self.near_tower = no_tower;
        self.near_far = 1e9;
        for (self.towers[0..self.tower_count], 0..) |tower, i| {
            const dx = tower.x - self.hum_x;
            const dz = tower.z - self.hum_z;
            const far = @sqrt(dx * dx + dz * dz);
            if (far < self.near_far) {
                self.near_far = far;
                self.near_tower = @intCast(i);
            }
        }
        const leaning = self.still >= 30 and self.near_tower != no_tower and self.near_far < lean_within;
        const want: f32 = if (leaning) 1.0 else 0.0;
        self.lean += (want - self.lean) * 0.035;
        if (leaning) {
            // turn to face it
            const tower = self.towers[self.near_tower];
            var turn = std.math.atan2(tower.x - self.hum_x, -(tower.z - self.hum_z)) - self.look_yaw;
            while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
            while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
            self.look_yaw += turn * 0.05;
        }
    }

    /// How far up the view looks, in radians: walking, a little; leaned back, far enough that
    /// the top of the thing is just inside the top of the wide frame.
    pub fn pitch(self: *const World) f32 {
        var leaned: f32 = walk_pitch;
        if (self.near_tower != no_tower) {
            const tower = self.towers[self.near_tower];
            const top = std.math.atan2(tower.tall - lean_up, self.near_far + lean_back);
            leaned = std.math.clamp(top - (lean_fov * 0.5 - 2.5) * (std.math.pi / 180.0), walk_pitch, 1.0);
        }
        return std.math.clamp(walk_pitch + self.look_tilt + self.lean * (leaned - walk_pitch), -0.35, 1.36);
    }

    /// How wide the view is, in degrees up and down.
    pub fn fov(self: *const World) f32 {
        return place_fov + self.lean * (lean_fov - place_fov);
    }

    fn atTallFoot(self: *const World) bool {
        if (self.near_tower == no_tower) return false;
        return self.near_far <= at_foot and self.towers[self.near_tower].tall >= 90.0;
    }

    /// An answer has reached Hum's ears: the moments that are made of being answered.
    fn heard(self: *World, from: u32) void {
        self.seen.meet(.evening_call, self.step);
        self.seen.meet(.whole_law1, self.step);
        self.seen.meet(.whole_law6, self.step);
        const thing = self.things[from];
        if (thing.tower == no_tower) return;
        const tower = self.towers[thing.tower];
        // called at the foot of an aster as tall as a cathedral, and still standing there when
        // the bells of its crown are heard
        const dx = tower.x - self.hum_x;
        const dz = tower.z - self.hum_z;
        const at_its_foot = @sqrt(dx * dx + dz * dz) <= at_foot;
        if (at_its_foot and tower.tall >= 90.0 and thing.y >= tower.tall * 0.7 and self.still >= 30) {
            self.seen.meet(.garden_asters, self.step);
        }
    }

    /// How brightly a thing shows: lit by a passing ring, or by its own ringing.
    pub fn light(thing: Thing) f32 {
        return @min(1.0, @max(thing.lit * 0.55, thing.loud * 1.3));
    }

    /// A sum over everything in the world, to compare two machines by.
    pub fn fingerprint(self: *const World) u64 {
        var h: u64 = 0xcbf29ce484222325;
        const mixIn = struct {
            fn f(x: *u64, v: u64) void {
                x.* ^= v;
                x.* *%= 0x100000001b3;
            }
        }.f;
        mixIn(&h, self.step);
        mixIn(&h, @as(u32, @bitCast(self.hum_x)));
        mixIn(&h, @as(u32, @bitCast(self.hum_z)));
        mixIn(&h, @as(u32, @bitCast(self.hum_face)));
        mixIn(&h, @as(u32, @bitCast(self.look_yaw)));
        mixIn(&h, @as(u32, @bitCast(self.look_tilt)));
        mixIn(&h, @as(u32, @bitCast(self.lean)));
        mixIn(&h, self.calls);
        mixIn(&h, self.answers);
        for (self.things[0..self.thing_count]) |thing| {
            mixIn(&h, @as(u32, @bitCast(thing.lit)));
            mixIn(&h, @as(u32, @bitCast(thing.loud)));
        }
        for (self.rings) |ring| {
            if (ring.live) mixIn(&h, ring.born);
        }
        for (self.arrivals) |a| {
            if (a.live) mixIn(&h, a.at);
        }
        return h;
    }
};

test "kin answer a call and strangers don't" {
    // C answers C fully, its octave half as much, its fifth less again; a half step up, nothing
    const same = sympathy(261.63, 261.63, bell_mult, bell_gain);
    const octave = sympathy(261.63, 523.26, bell_mult, bell_gain);
    const fifth = sympathy(261.63, 392.445, bell_mult, bell_gain);
    const half_step = sympathy(261.63, 277.19, bell_mult, bell_gain);
    try std.testing.expect(same > 0.9);
    try std.testing.expect(octave > 0.4 and octave < same);
    try std.testing.expect(fifth > 0.15 and fifth < octave);
    try std.testing.expect(half_step < 0.08);
}

test "an answer is heard when it has travelled there and back" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    w.things[0] = .{ .x = 30.0, .z = 0.0, .hz = garden_hz };
    w.thing_count = 1;
    var cues: [max_cues]sound.Cue = undefined;
    var got: ?u64 = null;
    var step: u32 = 0;
    while (step < 120) : (step += 1) {
        const hands = Hands{ .buttons = if (step == 0) Hands.call else 0 };
        const n = w.stepOnce(hands, &cues);
        for (cues[0..n]) |cue| {
            if (cue.kind == .strike and cue.family == .bell) got = cue.at;
        }
    }
    // 30 m out at 60 m a second is half a second, and half a second back
    const heard = got orelse return error.NoAnswer;
    const seconds = @as(f32, @floatFromInt(heard - lead)) / sound.rate;
    try std.testing.expect(@abs(seconds - 1.0) < 0.03);
    try std.testing.expectEqual(@as(u32, 1), w.answers);
}

test "the same hands make the same world" {
    const a = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(a);
    const b = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(b);
    a.* = World.init();
    b.* = World.init();
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    while (step < 600) : (step += 1) {
        const hands = Hands{
            .lx = if (step % 200 < 100) 90 else -40,
            .ly = if (step % 150 < 60) -110 else 20,
            .buttons = (if (step % 97 == 3) Hands.call else 0) | (if (step % 240 > 200) Hands.sing else 0),
        };
        _ = a.stepOnce(hands, &cues);
        _ = b.stepOnce(hands, &cues);
    }
    try std.testing.expectEqual(a.fingerprint(), b.fingerprint());
    try std.testing.expect(a.calls > 0 and a.answers > 0);
}

test "a thing answers by its own overtones, whatever its family" {
    // a bar whose second overtone (2.756 times its note) is the call's octave, and a bell on the
    // very same note, which shares nothing with the call
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    const hz = garden_hz * 2.0 / 2.756;
    w.things[0] = .{ .x = 20.0, .hz = hz, .family = .bar };
    w.things[1] = .{ .x = -20.0, .hz = hz, .family = .bell };
    w.thing_count = 2;
    var cues: [max_cues]sound.Cue = undefined;
    var bar: f32 = 0.0;
    var bell: f32 = 0.0;
    var step: u32 = 0;
    while (step < 60) : (step += 1) {
        _ = w.stepOnce(.{ .buttons = if (step == 0) Hands.call else 0 }, &cues);
        bar = @max(bar, w.things[0].loud);
        bell = @max(bell, w.things[1].loud);
    }
    try std.testing.expect(bar > 0.15);
    try std.testing.expectEqual(@as(f32, 0.0), bell);
}

test "what lights a thing by ringing is what sounds it" {
    // six things at one distance: some kin to the call and some not. Each one that rings is
    // sounded, as loud as it shines; each one that stays dark is silent.
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    const ratios = [6]f32{ 1.0, 1.5, 2.0, 1.0595, 1.8877, 0.5 };
    for (ratios, 0..) |ratio, i| {
        const a = @as(f32, @floatFromInt(i)) * 1.0472;
        w.things[i] = .{ .x = 30.0 * @cos(a), .z = 30.0 * @sin(a), .hz = garden_hz * ratio };
    }
    w.thing_count = 6;
    var cues: [max_cues]sound.Cue = undefined;
    var shone: [6]f32 = @splat(0.0);
    var sounded: [6]f32 = @splat(0.0);
    var step: u32 = 0;
    while (step < 150) : (step += 1) {
        const n = w.stepOnce(.{ .buttons = if (step == 0) Hands.call else 0 }, &cues);
        for (0..6) |i| shone[i] = @max(shone[i], w.things[i].loud);
        for (cues[0..n]) |cue| {
            if (cue.kind != .strike or cue.family != .bell) continue;
            for (0..6) |i| {
                if (cue.hz == w.things[i].hz) sounded[i] = cue.gain;
            }
        }
    }
    var rang: u32 = 0;
    for (0..6) |i| {
        try std.testing.expectEqual(shone[i] > 0.0, sounded[i] > 0.0);
        if (shone[i] == 0.0) continue;
        rang += 1;
        // at 30 m, with a carry of 30 m, the sound is 0.22 x kin / 2; the light is kin, one step faded
        const kin_from_sound = sounded[i] * 2.0 / 0.22;
        try std.testing.expect(@abs(kin_from_sound - shone[i]) < 0.03 * kin_from_sound);
    }
    try std.testing.expect(rang >= 3 and rang <= 5);
}

test "a call climbs a tower, and its bells are heard late by their height" {
    // one stalk part 60 m up and one bell 120 m up, straight above where Hum calls
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    w.ring_reach = 900.0;
    w.things[0] = .{ .y = 60.0, .sounds = false, .tower = 0 };
    w.things[1] = .{ .y = 120.0, .hz = garden_hz, .carry = 110.0, .tower = 0 };
    w.thing_count = 2;
    w.towers[0] = .{ .tall = 125.0, .first = 0, .count = 2 };
    w.tower_count = 1;
    var cues: [max_cues]sound.Cue = undefined;
    var part_lit: ?u32 = null;
    var bell_lit: ?u32 = null;
    var heard_at: ?u64 = null;
    var step: u32 = 0;
    while (step < 300) : (step += 1) {
        const n = w.stepOnce(.{ .buttons = if (step == 0) Hands.call else 0 }, &cues);
        if (part_lit == null and w.things[0].lit > 0.0) part_lit = step;
        if (bell_lit == null and w.things[1].lit > 0.0) bell_lit = step;
        for (cues[0..n]) |cue| {
            if (cue.kind == .strike and cue.family == .bell) heard_at = cue.at;
        }
    }
    // at 60 m a second the call is at 60 m after one second and at 120 m after two
    try std.testing.expect(@abs(@as(f32, @floatFromInt(part_lit.?)) / 60.0 - 1.0) < 0.04);
    try std.testing.expect(@abs(@as(f32, @floatFromInt(bell_lit.?)) / 60.0 - 2.0) < 0.04);
    // and the bell is heard two seconds after it is seen to light: four seconds after the call
    const seconds = @as(f32, @floatFromInt(heard_at.? - lead)) / sound.rate;
    try std.testing.expect(@abs(seconds - 4.0) < 0.05);
}
