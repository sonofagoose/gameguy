//! The world: the rules.
//!
//! No platform, no clock, no allocation. A step takes the hands and gives back cues for the
//! sound; everything else is in `World`, which is plain values all the way down. The same hands
//! make the same world on every machine (spec/engine.md).
//!
//! So far it holds the first evening's first minute: the dark, Hum, the call, and things that
//! answer. Two laws are in it. Travel: a call's ring moves at the speed of sound, lights what it
//! passes, and an answer is heard when it has travelled back. Sympathy: a thing answers as much
//! as its overtones share with the note that called.
const std = @import("std");
const sound = @import("../sound/sound.zig");

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

pub const Thing = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    tall: f32 = 4.0,
    hz: f32 = 261.63,
    family: sound.Family = .bell,
    /// How long its lowest note rings, in seconds.
    ring: f32 = 3.0,
    /// Light left on it by a ring that passed.
    lit: f32 = 0.0,
    /// How loud it is ringing.
    loud: f32 = 0.0,
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
};

pub const max_things = 256;
pub const max_rings = 6;
const max_arrivals = 128;
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

    fn later(self: *World, at: u64, cue: sound.Cue) void {
        for (&self.arrivals) |*slot| {
            if (slot.live) continue;
            slot.* = .{ .at = at, .cue = cue, .live = true };
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

        // Hum walks
        const mx = @as(f32, @floatFromInt(hands.lx)) * (1.0 / 127.0);
        const mz = @as(f32, @floatFromInt(hands.ly)) * (1.0 / 127.0);
        const size = @sqrt(mx * mx + mz * mz);
        if (size > 0.12) {
            const scale = @min(size, 1.0) / size * run_speed * dt;
            self.hum_x += mx * scale;
            self.hum_z += mz * scale;
            self.hum_face = std.math.atan2(mx, -mz);
        }

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
            self.later(now_sample + lead, .{ .at = 0, .kind = .strike, .family = .string, .hz = garden_hz, .gain = 0.3, .ring = 0.35 });
        }

        // singing: Hum's one note, for as long as R2 is held
        if (pressed & Hands.sing != 0) {
            self.singing = true;
            self.later(now_sample + lead, .{ .at = 0, .kind = .hum_on, .hz = garden_hz, .gain = 0.35 });
        }
        if (released & Hands.sing != 0) {
            self.singing = false;
            self.later(now_sample + lead, .{ .at = 0, .kind = .hum_off });
        }

        // rings travel; what they pass is lit, and answers as much as it shares with the call
        for (&self.rings) |*ring| {
            if (!ring.live) continue;
            const age: f32 = @floatFromInt(self.step - ring.born);
            const reach = age * dt * sound_speed;
            const before = @max(0.0, reach - dt * sound_speed);
            if (reach > 140.0) {
                ring.live = false;
                continue;
            }
            for (self.things[0..self.thing_count]) |*thing| {
                const dx = thing.x - ring.x;
                const dz = thing.z - ring.z;
                const far = @sqrt(dx * dx + dz * dz);
                if (far <= before or far > reach) continue;
                thing.lit = 1.0;
                const kin = sympathy(garden_hz, thing.hz, bell_mult, bell_gain);
                if (kin < 0.08) continue;
                // quieter with distance, as sound is
                const level = 0.22 * kin / (1.0 + (far / 30.0) * (far / 30.0));
                thing.loud = @max(thing.loud, kin);
                self.answers += 1;
                // its answer is heard when it has come back to where Hum is now
                const hx = thing.x - self.hum_x;
                const hz = thing.z - self.hum_z;
                const back = @sqrt(hx * hx + hz * hz) / sound_speed;
                const delay: u64 = @intFromFloat(back * sound.rate);
                self.later(now_sample + lead + delay, .{ .at = 0, .kind = .strike, .family = thing.family, .hz = thing.hz, .gain = level, .ring = thing.ring });
            }
        }

        // light and ringing fade
        for (self.things[0..self.thing_count]) |*thing| {
            thing.lit *= 0.975;
            if (thing.lit < 0.002) thing.lit = 0.0;
            thing.loud *= @exp(-dt * 2.3 / thing.ring);
            if (thing.loud < 0.002) thing.loud = 0.0;
        }

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
        }

        self.step += 1;
        return n;
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
    var w = World{};
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
    var a = World.init();
    var b = World.init();
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
