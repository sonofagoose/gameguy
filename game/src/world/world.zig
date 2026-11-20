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
pub const cues_mod = @import("cue.zig");
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
/// A thing rung more faintly than this at the ears neither sounds nor shines of itself.
pub const quietest: f32 = 0.004;
/// How loud a thing rung at full strength is at the ears, and how loud Hum's own voice is.
pub const answer_level: f32 = 0.22;
pub const voice_level: f32 = 0.35;

// ------------------------------------------------------------------ the sky (spec/sky.md)

/// Height is the octave, and an octave is 100 m.
pub const octave_m: f32 = 100.0;
/// The lake's middle, beyond the far edge of the proof field, and the radius of its shore.
pub const lake_x: f32 = 1100.0;
pub const lake_z: f32 = -2700.0;
pub const lake_r: f32 = 1850.0;
/// The sun holds the day's note, an octave under middle C.
pub const sun_hz: f32 = garden_hz * 0.5;
/// The rungs of the horn that are things of the world: one for each of the sun's first sixteen
/// overtones, standing in the air over the lake.
pub const rungs: u32 = 16;
/// Daylight is eighteen minutes of a day's twenty (an estimate, to tune). At noon the sun stands
/// 400 m up, on rung 16.
pub const daylight_s: f32 = 1080.0;
pub const noon_m: f32 = 400.0;
/// How long the sky takes to fill with the day once the sun is up, and how wide the edge between
/// night and day is as the dawn crosses the ground.
pub const sky_fills_s: f32 = 30.0;
pub const dawn_edge_m: f32 = 160.0;

/// How high rung `n` hangs: the octaves of its overtone.
pub fn rungHeight(n: u32) f32 {
    return octave_m * @log2(@as(f32, @floatFromInt(n)));
}

/// How wide rung `n` is: the shore's radius over its number, so the stack is a horn.
pub fn rungRadius(n: u32) f32 {
    return lake_r / @as(f32, @floatFromInt(n));
}

/// The sun rises a seventh of the way along the shore between yesterday's land and today's, and a
/// string struck a seventh of the way along has no seventh overtone, nor any multiple of it. So
/// those rungs never sound.
pub fn rungSounds(n: u32) bool {
    return n % 7 != 0;
}

/// A step that never comes.
pub const never: u64 = std.math.maxInt(u64);

/// Drip (spec/people.md): a drop that never finished falling. Where it waits in the dark, its
/// beat, and its note: a fifth above Hum, and a hair flat until they have breathed together.
pub const drip_x: f32 = asters.clear_x;
pub const drip_z: f32 = asters.clear_z;
/// Steps between its ticks: 72 a minute. Every other tick is a little late: its time is alive.
pub const tick_every: u32 = 50;
pub const tick_swing: u32 = 4;
/// How flat its fifth is at first, in hundredths of a semitone.
pub const drip_flat: f32 = -4.0;
/// Letting go within this many steps of a tick is breathing with it.
pub const breath_window: u32 = 8;
pub const breaths_to_lock: u32 = 4;
/// How near Hum must be for the two to breathe together.
pub const beside: f32 = 5.0;
/// Once locked, both notes hold by themselves for this many steps.
pub const lock_holds: u64 = 170;

/// The step the tick numbered `k` falls on.
pub fn tickStep(k: u64) u64 {
    return k * tick_every + (if (k % 2 == 1) @as(u64, tick_swing) else 0);
}

/// How many steps from `step` to the nearest tick, before or after.
pub fn fromTick(step: u64) u64 {
    const k = step / tick_every;
    var best: u64 = never;
    var i: u64 = if (k > 0) k - 1 else 0;
    while (i <= k + 1) : (i += 1) {
        const at = tickStep(i);
        best = @min(best, if (at > step) at - step else step - at);
    }
    return best;
}

/// How many steps until the next tick, counting this step.
pub fn untilTick(step: u64) u64 {
    var k = step / tick_every;
    while (tickStep(k) < step) k += 1;
    return tickStep(k) - step;
}

/// What a cue comes from.
pub const Source = union(enum) { hum, thing: u32 };

/// The view of the place. Walking: the eye sits far behind Hum and low, looking up a little, so
/// the horizon is low in the frame and Hum is small in it. Stopped at a tall thing's foot, the
/// view does not fit the thing to the screen: the gaze climbs it at the speed of sound, narrowing
/// as it goes, so the ground is lost and the height is paid for in time. A call made there is
/// ridden up: the gaze follows the band of light.
pub const cam_back: f32 = 22.0;
pub const cam_up: f32 = 2.2;
pub const walk_pitch: f32 = 0.24;
pub const place_fov: f32 = 55.0;
pub const lean_back: f32 = 14.0;
pub const lean_up: f32 = 1.0;
/// How many metres of the thing the leaned view frames, top to bottom, and how narrow it may go.
pub const lean_frame: f32 = 30.0;
pub const lean_fov_least: f32 = 13.0;

pub const Camera = struct { eye: [3]f32, at: [3]f32, fov: f32, stand: f32 };

/// The page: the same world seen from above, lying flat. The eye is this high, this far behind.
pub const page_up: f32 = 105.0;
pub const page_back: f32 = 26.0;
pub const page_fov: f32 = 50.0;
/// How fast the page rises when it stands, and how fast it lies down again.
pub const rise_rate: f32 = 0.0045;
pub const fold_rate: f32 = 0.03;
/// R1 held this many steps folds the place back to the page for as long as it is held.
pub const fold_after: u32 = 15;
/// Standing still within this of a tall thing's foot, the view leans back to take it in.
pub const lean_within: f32 = 18.0;
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
    /// How loud it stays for as long as something holds it sounding: a rung of the horn while
    /// the sun stands at or above it.
    held: f32 = 0.0,
};

/// A tall thing with a foot: the view leans back at it, and a call climbs it.
pub const Tower = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    tall: f32 = 0.0,
    /// How far its top has bowed from over its foot.
    bow_x: f32 = 0.0,
    bow_z: f32 = 0.0,
    first: u32 = 0,
    count: u32 = 0,
};

pub const Ring = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    born: u64 = 0,
    live: bool = false,
    /// The note that is travelling.
    hz: f32 = garden_hz,
    /// Hum's own call, which rings what it passes; or someone else's, which is an answer.
    own: bool = true,
};

/// A sound on its way to Hum's ears.
const Arrival = struct {
    at: u64 = 0,
    cue: sound.Cue = .{ .at = 0, .kind = .strike },
    live: bool = false,
    /// The thing whose answer this is, if it is one.
    from: u32 = no_thing,
    /// How bright the light was that this sound was told with.
    light: f32 = 0.0,
};

pub const no_thing: u32 = 0xffff_ffff;
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
    /// How high up the tall thing the leaned view is looking, in metres.
    gaze: f32 = 0.0,
    /// The hinge between the page and the place: 0 is the page, lying flat and seen from above,
    /// and 1 is the place, standing round Hum. Everything's height is multiplied by this.
    stand: f32 = 1.0,
    /// How many steps R1 has been held.
    call_held: u32 = 0,
    /// The step the page stands up from: when the drop lands on Hum's head.
    stand_from: u64 = never,
    /// The day coming up: 0 is the dark, where a thing is seen only when it sounds or a call
    /// passes it, and 1 is morning.
    dawn: f32 = 1.0,
    /// Drip: which thing it is, whether it rides on Hum's head yet, whether it is humming with
    /// Hum now, and how many breaths they have taken together.
    drip: u32 = no_thing,
    drip_met: bool = false,
    drip_humming: bool = false,
    breaths: u32 = 0,
    /// Whether the second call has been answered, and when.
    answered: bool = false,
    answered_at: u64 = 0,
    /// How far round the figure between the two voices has turned, in radians.
    figure_turn: f32 = 0.0,
    /// When the two locked, and until when both notes hold by themselves.
    locked_at: u64 = never,
    hold_until: u64 = 0,
    /// How far the page has leaned in beside Drip, 0 to 1.
    near_in: f32 = 0.0,
    /// The dawn: the step it began on, and how many seconds of it had already gone by then.
    dawn_from: u64 = never,
    dawn_age0: f32 = 0.0,
    /// Where the sun rose: the point of the shore nearest where Hum wakes.
    sun_x: f32 = 0.0,
    sun_z: f32 = 0.0,
    /// The first of the horn's rungs in the list of things, and which of them the sun is holding,
    /// one bit each.
    rung_first: u32 = no_thing,
    rung_lit: u32 = 0,
    /// The highest rung whose note has reached Hum's ears.
    rung_heard: u32 = 0,
    /// A flower head that has fallen by the great aster's foot: a bell at Hum's own size.
    fallen: u32 = no_thing,
    /// The tower Hum is nearest, and how far its foot is.
    near_tower: u16 = no_tower,
    near_far: f32 = 0.0,
    /// How many steps Hum has stood still.
    still: u32 = 0,
    /// Hum's own light: it flares when Hum calls and holds while it sings.
    hum_light: f32 = 0.0,
    /// How many cues have been told, how many sounds they sent on their way, and how many sounds
    /// reached the ears that had been told with no light. The last is always nought.
    told: u32 = 0,
    sent: u32 = 0,
    dark_sounds: u32 = 0,
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
        self.initField();
        self.stand = 1.0;
        self.stand_from = 0;
        self.dawn = 1.0;
        // the sun rose two minutes ago: the dawn has crossed the field, and two rungs are lit
        self.dawn_from = 0;
        self.dawn_age0 = 120.0;
        self.drip_met = true;
        self.breaths = breaths_to_lock;
        self.answered = true;
    }

    /// The first evening, from its first second: the same field, in the dark, as a page. Drip
    /// is out there ticking, and nothing stands up until the two have breathed together.
    pub fn initEvening(self: *World) void {
        self.initField();
        self.stand = 0.0;
        self.dawn = 0.0;
    }

    fn initField(self: *World) void {
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
            self.towers[t] = .{ .x = p.x, .z = p.z, .tall = p.tall, .bow_x = p.bow_x, .bow_z = p.bow_z, .first = first, .count = at - first };
        }
        self.tower_count = @intCast(n);
        // one flower head has fallen by the great aster's foot, so a bell is met at Hum's own
        // size before a crown of them is seen from a hundred and fifty metres below
        self.fallen = at;
        self.things[at] = .{ .x = asters.great_x + 7.5, .y = 1.5, .z = asters.great_z + 6.0, .tall = 2.2, .hz = garden_hz * 0.5, .ring = 5.5 };
        at += 1;
        // Drip: a drop 40 cm across
        self.drip = at;
        self.things[at] = .{ .x = drip_x, .y = 0.3, .z = drip_z, .tall = 0.4, .hz = garden_hz * 1.5, .family = .bar, .ring = 0.2 };
        at += 1;
        // the horn: a ring of light for each of the sun's first sixteen overtones, over the lake.
        // Each is a thing whose place is the point of its ring nearest where Hum wakes, since
        // that is where its sound comes from first.
        const to_x = -lake_x;
        const to_z = -lake_z;
        const away = @sqrt(to_x * to_x + to_z * to_z);
        self.rung_first = at;
        var k: u32 = 1;
        while (k <= rungs) : (k += 1) {
            const r = rungRadius(k);
            self.things[at] = .{
                .x = lake_x + to_x / away * r,
                .y = rungHeight(k),
                .z = lake_z + to_z / away * r,
                .tall = r,
                .hz = sun_hz * @as(f32, @floatFromInt(k)),
                .family = .string,
                .ring = 10.0,
                .carry = 1e9,
                .sounds = rungSounds(k),
            };
            at += 1;
        }
        // the sun rises on the shore, at the first rung's place
        self.sun_x = self.things[self.rung_first].x;
        self.sun_z = self.things[self.rung_first].z;
        self.thing_count = at;
    }

    /// Tell the player something. This is the only way anything in the world makes a sound, and
    /// it takes a cue, which always has its light. The light is put on the thing here and now;
    /// the sound is sent on its way and reaches Hum's ears when it has travelled there.
    fn tell(self: *World, from: Source, what: cues_mod.Cue) void {
        const now_sample = self.step * samples_per_step;
        self.told += 1;
        switch (from) {
            .hum => {
                switch (what.light.shape) {
                    .ring_on_the_ground => self.startRing(self.hum_x, self.hum_z, what.sound.hz, true),
                    .swell => self.singing = true,
                    .dims => self.singing = false,
                    .glow => {},
                }
                self.hum_light = @max(self.hum_light, what.light.brightness);
                self.send(now_sample + lead, .{ .at = 0, .kind = what.sound.kind, .family = what.sound.family, .voice = what.sound.voice, .hz = what.sound.hz, .gain = what.sound.strength * voice_level, .ring = what.sound.ring }, no_thing, what.light);
            },
            .thing => |index| {
                const thing = &self.things[index];
                thing.loud = @max(thing.loud, what.light.brightness);
                if (what.light.shape == .ring_on_the_ground) self.startRing(thing.x, thing.z, what.sound.hz, false);
                // heard when it has come back to where Hum is now
                const hx = thing.x - self.hum_x;
                const hz = thing.z - self.hum_z;
                const back = @sqrt(hx * hx + hz * hz + thing.y * thing.y) / sound_speed;
                const delay: u64 = @intFromFloat(back * sound.rate);
                const level: f32 = if (what.sound.kind == .strike) answer_level else voice_level;
                self.send(now_sample + lead + delay, .{ .at = 0, .kind = what.sound.kind, .family = what.sound.family, .voice = what.sound.voice, .hz = what.sound.hz, .gain = what.sound.strength * level, .ring = what.sound.ring }, index, what.light);
            },
        }
    }

    /// A ring of light begins to run out from a place: a call's, or an answer's.
    fn startRing(self: *World, x: f32, z: f32, hz: f32, own: bool) void {
        var oldest: usize = 0;
        for (self.rings, 0..) |r, i| {
            if (!r.live) {
                oldest = i;
                break;
            }
            if (r.born < self.rings[oldest].born) oldest = i;
        }
        self.rings[oldest] = .{ .x = x, .z = z, .born = self.step, .live = true, .hz = hz, .own = own };
    }

    /// Drip's note now: a fifth above Hum's, flat by less with every breath they have taken
    /// together, and true once they have locked.
    pub fn dripHz(self: *const World) f32 {
        const left = 1.0 - @as(f32, @floatFromInt(@min(self.breaths, breaths_to_lock))) / @as(f32, breaths_to_lock);
        return garden_hz * 1.5 * std.math.pow(f32, 2.0, drip_flat * left / 1200.0);
    }

    /// How many times a second the two notes beat: the third overtone of Hum's against the
    /// second of Drip's. The figure between them turns at this rate, and stops when it is nought.
    pub fn beat(self: *const World) f32 {
        return @abs(3.0 * garden_hz - 2.0 * self.dripHz());
    }

    fn besideDrip(self: *const World) bool {
        if (self.drip == no_thing or self.drip_met) return false;
        const d = self.things[self.drip];
        const dx = d.x - self.hum_x;
        const dz = d.z - self.hum_z;
        return dx * dx + dz * dz <= beside * beside;
    }

    /// The sound half of a cue, on its way. Only `tell` calls this.
    fn send(self: *World, at: u64, heard_as: sound.Cue, from: u32, its_light: cues_mod.Light) void {
        self.sent += 1;
        // a held voice ending is told by the singer settling, which is a light going down
        const shown: f32 = if (its_light.shape == .dims) 1.0 else its_light.brightness;
        for (&self.arrivals) |*slot| {
            if (slot.live) continue;
            slot.* = .{ .at = at, .cue = heard_as, .live = true, .from = from, .light = shown };
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
        if (self.view == .place) {
            // the hinge: the world is a page until it stands, and holding R1 lays it down again
            self.call_held = if (hands.held(Hands.call)) self.call_held +| 1 else 0;
            const standing = self.step >= self.stand_from and self.call_held < fold_after;
            if (self.step == self.stand_from and self.dawn_from == never) self.dawn_from = self.step;
            self.stand = if (standing) @min(1.0, self.stand + rise_rate) else @max(0.0, self.stand - fold_rate);
            self.look(hands);
        }

        // the call: a ring of light and Hum's own short note, as one cue
        if (pressed & Hands.call != 0) {
            self.calls += 1;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = garden_hz, .strength = 0.857, .ring = 0.35 }, .ring_on_the_ground));
        }

        // singing: Hum's one note for as long as R2 is held, and Hum swelling for as long. Beside
        // Drip, it hums with you. While a lock holds, both notes hold by themselves.
        const holding = self.step < self.hold_until;
        if (pressed & Hands.sing != 0 and !holding) {
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .hz = garden_hz, .strength = 1.0, .ring = 0.0 }, .swell));
            if (self.besideDrip()) {
                self.drip_humming = true;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = 0.7, .ring = 0.0 }, .swell));
            }
        }
        if (released & Hands.sing != 0 and !holding and self.singing) {
            var locking = false;
            if (self.drip_humming) {
                // letting go on its tick is a breath together, and each one brings its note truer.
                // Letting go off the tick is nothing: no penalty, and nobody says so.
                if (fromTick(self.step) <= breath_window and self.breaths < breaths_to_lock) {
                    self.breaths += 1;
                    locking = self.breaths == breaths_to_lock;
                }
            }
            if (locking) {
                // the fourth: the figure stops, and both notes hold by themselves
                self.locked_at = self.step;
                self.hold_until = self.step + lock_holds;
                // the day begins to come up as the two lock. On the first morning dawn is at your
                // feet (spec/sky.md): the sun rises where the two of you are, and the day runs out
                // over the ground from there at the speed of sound
                if (self.dawn_from == never) {
                    self.dawn_from = self.step;
                    self.sun_x = self.hum_x;
                    self.sun_z = self.hum_z;
                }
                self.seen.meet(.evening_breathe, self.step);
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = 0.7, .ring = 0.0 }, .swell));
            } else {
                self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = garden_hz, .strength = 0.0, .ring = 0.0 }, .dims));
                if (self.drip_humming) {
                    self.drip_humming = false;
                    self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
                }
            }
        }
        if (self.hold_until != 0 and self.step == self.hold_until) {
            // the hold ends: both let go, the drop lands on Hum's head, and the page begins to stand
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = garden_hz, .strength = 0.0, .ring = 0.0 }, .dims));
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
            self.drip_humming = false;
            self.drip_met = true;
            self.stand_from = self.step + 40;
        }
        if (self.drip != no_thing) self.dripStep();
        if (self.rung_first != no_thing) self.skyStep();
        self.dawn = self.dayAt(self.hum_x, self.hum_z);
        if (self.singing) self.hum_light = @max(self.hum_light, 0.8);
        self.hum_light *= 0.94;
        if (self.hum_light < 0.002) self.hum_light = 0.0;

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
            if (!ring.own) {
                // an answer on its way: it lights what it passes, and it reaches Hum
                const hx = self.hum_x - ring.x;
                const hz = self.hum_z - ring.z;
                const to_hum = @sqrt(hx * hx + hz * hz);
                if (to_hum > before and to_hum <= reach and !self.answered) {
                    self.answered = true;
                    self.answered_at = self.step;
                    self.seen.meet(.evening_call, self.step);
                }
                for (self.things[0..self.thing_count]) |*thing| {
                    const dx = thing.x - ring.x;
                    const dz = thing.z - ring.z;
                    const far = @sqrt(dx * dx + dz * dz + thing.y * thing.y);
                    if (far > before and far <= reach) thing.lit = @max(thing.lit, 0.6);
                }
                continue;
            }
            for (self.things[0..self.thing_count], 0..) |*thing, index| {
                const dx = thing.x - ring.x;
                const dz = thing.z - ring.z;
                const far = @sqrt(dx * dx + dz * dz + thing.y * thing.y);
                if (far <= before or far > reach) continue;
                thing.lit = 1.0;
                if (!thing.sounds) continue;
                if (index == self.drip) {
                    // the second call is always answered: Drip's own ring comes back
                    if (self.calls >= 2 and !self.drip_met) {
                        const loud = 0.9 / (1.0 + (far / 60.0) * (far / 60.0));
                        self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = self.dripHz(), .strength = loud, .ring = 0.9 }, .ring_on_the_ground));
                    }
                    continue;
                }
                const rec = sound.recipe(thing.family);
                const kin = sympathy(garden_hz, thing.hz, rec.mult, rec.gain);
                if (kin < 0.08) continue;
                // how hard the call rings it: less with distance, as sound is. One number, and it
                // is both how loud the thing is and how bright
                const strength = kin / (1.0 + (far / thing.carry) * (far / thing.carry));
                if (strength * answer_level < quietest) continue;
                self.answers += 1;
                self.tell(.{ .thing = @intCast(index) }, cues_mod.Cue.of(.{ .kind = .strike, .family = thing.family, .hz = thing.hz, .strength = strength, .ring = thing.ring }, .glow));
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
            thing.loud = @max(thing.loud, thing.held);
            if (thing.loud > 0.1 and thing.held == 0.0) ringing += 1;
        }
        if (ringing > 0 and self.still > 0) self.seen.hold(.evening_call);
        if (self.drip_humming and self.besideDrip()) self.seen.hold(.evening_breathe);
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
            if (self.arrivals[i].light <= 0.0) self.dark_sounds += 1;
            if (self.arrivals[i].from != no_thing) self.heard(self.arrivals[i].from);
        }

        self.step += 1;
        return n;
    }

    /// How many seconds since the sun rose; below nought before it has.
    pub fn dawnAge(self: *const World) f32 {
        if (self.dawn_from == never or self.step < self.dawn_from) return -1.0;
        return self.dawn_age0 + @as(f32, @floatFromInt(self.step - self.dawn_from)) * dt;
    }

    /// How much daylight has reached a place on the ground, 0 to 1. The dawn runs out over the
    /// ground from where the sun rose, at the speed of sound, like a call (spec/sky.md).
    pub fn dayAt(self: *const World, x: f32, z: f32) f32 {
        const age = self.dawnAge();
        if (age < 0.0) return 0.0;
        const dx = x - self.sun_x;
        const dz = z - self.sun_z;
        const ahead = age * sound_speed - @sqrt(dx * dx + dz * dz);
        const f = std.math.clamp(ahead / dawn_edge_m, 0.0, 1.0);
        return f * f * (3.0 - 2.0 * f);
    }

    /// How far the day has come up in the sky, 0 to 1: the sky fills before the land does.
    pub fn skyLevel(self: *const World) f32 {
        const age = self.dawnAge();
        if (age < 0.0) return 0.0;
        const f = std.math.clamp(age / sky_fills_s, 0.0, 1.0);
        return f * f * (3.0 - 2.0 * f);
    }

    /// Where the sun is: it rises on the shore and climbs the horn's wall toward the lake's middle,
    /// along the line from where it rose (spec/sky.md).
    pub fn sunPlace(self: *const World) [3]f32 {
        const h = self.sunHeight();
        const dx = self.sun_x - lake_x;
        const dz = self.sun_z - lake_z;
        const shrink = 1.0 / std.math.pow(f32, 2.0, h / octave_m);
        return .{ lake_x + dx * shrink, h, lake_z + dz * shrink };
    }

    /// How high the sun stands, in metres: up the horn's wall to noon, and down again.
    pub fn sunHeight(self: *const World) f32 {
        const age = self.dawnAge();
        if (age < 0.0 or age > daylight_s) return 0.0;
        return noon_m * @sin(std.math.pi * age / daylight_s);
    }

    /// The sun holds every rung at or below it. A rung it reaches lights at once where it stands
    /// and sounds its overtone, which is heard when it has crossed the distance to Hum; a rung it
    /// falls below goes dark (spec/sky.md, the horn).
    fn skyStep(self: *World) void {
        const age = self.dawnAge();
        if (age < 0.0) return;
        const h = self.sunHeight();
        var k: u32 = 1;
        while (k <= rungs) : (k += 1) {
            const index = self.rung_first + k - 1;
            const bit = @as(u32, 1) << @intCast(k);
            const holds = age <= daylight_s and h + 0.001 >= rungHeight(k) and rungSounds(k);
            if (holds and self.rung_lit & bit == 0) {
                self.rung_lit |= bit;
                // the sun's nth overtone is one nth as loud
                const part = 1.0 / @as(f32, @floatFromInt(k));
                self.things[index].held = 0.8 * @sqrt(part);
                self.tell(.{ .thing = index }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.things[index].hz, .strength = 0.6 * @sqrt(part), .ring = 10.0 }, .glow));
            } else if (!holds and self.rung_lit & bit != 0) {
                self.rung_lit &= ~bit;
                self.things[index].held = 0.0;
            }
        }
    }

    /// Drip keeps its time, turns the figure, and once it has landed rides on Hum's head.
    fn dripStep(self: *World) void {
        const d = &self.things[self.drip];
        if (self.drip_met) {
            d.x = self.hum_x;
            d.z = self.hum_z;
            d.y = 1.25;
        }
        const dx = d.x - self.hum_x;
        const dz = d.z - self.hum_z;
        const far = @sqrt(dx * dx + dz * dz);
        // its tick: a plink and a flash, softer and dimmer the farther off it is
        if (fromTick(self.step) == 0 and untilTick(self.step) == 0) {
            const loud = 0.55 / (1.0 + (far / 40.0) * (far / 40.0));
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = self.dripHz() * 2.0, .strength = loud, .ring = 0.16 }, .glow));
        }
        // while it hums with Hum, or holds, it shines
        if (self.drip_humming or self.step < self.hold_until) d.loud = @max(d.loud, 0.85);
        // the figure between the two voices turns as fast as they beat. Once they are true it
        // turns no more, and it falls into step (law 3): it settles on the nearer of the two
        // places where its three lobes and its two stand open and even.
        if (self.locked_at == never) {
            self.figure_turn += self.beat() * (2.0 * std.math.pi * dt);
            if (self.figure_turn > 2.0 * std.math.pi) self.figure_turn -= 2.0 * std.math.pi;
        } else {
            const open_at: f32 = if (self.figure_turn < std.math.pi) 0.5 * std.math.pi else 1.5 * std.math.pi;
            self.figure_turn += (open_at - self.figure_turn) * 0.07;
        }
        // stand still beside it and the page leans in
        const leaning_in = !self.drip_met and far <= beside * 1.6 and self.still >= 20;
        const want: f32 = if (leaning_in or self.step < self.hold_until) 1.0 else 0.0;
        self.near_in += (want - self.near_in) * 0.04;
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
        const leaning = self.still >= 30 and self.near_tower != no_tower and self.near_far < lean_within and self.stand > 0.98;
        const want: f32 = if (leaning) 1.0 else 0.0;
        self.lean += (want - self.lean) * 0.035;
        if (leaning) {
            // turn to face it
            const tower = self.towers[self.near_tower];
            var turn = std.math.atan2(tower.x - self.hum_x, -(tower.z - self.hum_z)) - self.look_yaw;
            while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
            while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
            self.look_yaw += turn * 0.05;
            // the gaze climbs it at the speed of sound; a call made here is ridden up instead
            const crown = tower.tall * 0.86;
            var want_gaze = @min(self.gaze + sound_speed * dt, crown);
            for (self.rings) |ring| {
                if (!ring.live) continue;
                const dx = tower.x - ring.x;
                const dz = tower.z - ring.z;
                const reach = @as(f32, @floatFromInt(self.step - ring.born)) * dt * sound_speed;
                const flat2 = dx * dx + dz * dz;
                if (reach * reach <= flat2 or flat2 > at_foot * at_foot * 4.0) continue;
                const band = @sqrt(reach * reach - flat2);
                if (band < crown) want_gaze = band;
            }
            // down fast, to catch a call as it starts; up no faster than sound
            self.gaze = if (want_gaze < self.gaze) @max(want_gaze, self.gaze - 6.0) else want_gaze;
        } else {
            self.gaze *= 0.90;
        }
    }

    /// Where the eye is, what it looks at and how wide. The place: behind Hum and a little up,
    /// or leaned back with the gaze part-way up a tall thing. The page: high above, looking down.
    /// Between them, one hinge.
    pub fn camera(self: *const World) Camera {
        const fx = @sin(self.look_yaw);
        const fz = -@cos(self.look_yaw);
        const back = cam_back + self.lean * (lean_back - cam_back);
        const up = cam_up + self.lean * (lean_up - cam_up);
        var eye = [3]f32{ self.hum_x - fx * back, up, self.hum_z - fz * back };
        const pitch = std.math.clamp(walk_pitch + self.look_tilt, -0.35, 1.2);
        const walking = [3]f32{ fx * @cos(pitch), @sin(pitch), fz * @cos(pitch) };
        var dir = walking;
        var fov = place_fov;
        if (self.near_tower != no_tower and self.lean > 0.001) {
            const tower = self.towers[self.near_tower];
            const f = self.gaze / tower.tall;
            const gx = tower.x + tower.bow_x * f * f - eye[0];
            const gy = self.gaze - eye[1];
            const gz = tower.z + tower.bow_z * f * f - eye[2];
            const far = @sqrt(gx * gx + gy * gy + gz * gz);
            const k = self.lean;
            dir = .{ walking[0] + (gx / far - walking[0]) * k, walking[1] + (gy / far - walking[1]) * k, walking[2] + (gz / far - walking[2]) * k };
            const narrow = std.math.clamp(2.0 * std.math.atan2(lean_frame * 0.5, far) * (180.0 / std.math.pi), lean_fov_least, place_fov);
            fov = place_fov + (narrow - place_fov) * k;
        }
        const len = @sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
        var at = [3]f32{ eye[0] + dir[0] / len * 10.0, eye[1] + dir[1] / len * 10.0, eye[2] + dir[2] / len * 10.0 };
        // the hinge, eased so that it starts and ends gently
        const s = self.stand * self.stand * (3.0 - 2.0 * self.stand);
        if (s < 1.0) {
            // beside Drip, standing still, the page comes closer
            const high = page_up + self.near_in * (12.0 - page_up);
            const behind = page_back + self.near_in * (5.0 - page_back);
            const page_eye = [3]f32{ self.hum_x - fx * behind, high, self.hum_z - fz * behind };
            const page_at = [3]f32{ self.hum_x + fx * 4.0, 0.0, self.hum_z + fz * 4.0 };
            // the gaze comes up to the horizon sooner than the eye comes down, so that what is
            // rising is in the frame while it rises, and its top leaves the frame before it stops
            const sooner = @min(1.0, self.stand * 2.0);
            const g = sooner * sooner * (3.0 - 2.0 * sooner);
            for (0..3) |i| {
                const ahead = eye[i] + (at[i] - eye[i]) * 12.0;
                at[i] = page_at[i] + (ahead - page_at[i]) * g;
                eye[i] = page_eye[i] + (eye[i] - page_eye[i]) * s;
            }
            fov = page_fov + (fov - page_fov) * s;
        }
        return .{ .eye = eye, .at = at, .fov = fov, .stand = s };
    }

    fn atTallFoot(self: *const World) bool {
        if (self.near_tower == no_tower) return false;
        return self.near_far <= at_foot and self.towers[self.near_tower].tall >= 90.0;
    }

    /// An answer has reached Hum's ears: the moments that are made of being answered.
    fn heard(self: *World, from: u32) void {
        if (self.rung_first != no_thing and from >= self.rung_first and from < self.rung_first + rungs) {
            const k = from - self.rung_first + 1;
            self.rung_heard = @max(self.rung_heard, k);
            if (k == 6) self.seen.meet(.sky_dawn, self.step);
            return;
        }
        if (from == self.drip) return;
        // where there is no Drip to answer, any answer is being answered
        if (self.drip == no_thing) self.seen.meet(.evening_call, self.step);
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
        mixIn(&h, @as(u32, @bitCast(self.gaze)));
        mixIn(&h, @as(u32, @bitCast(self.stand)));
        mixIn(&h, @as(u32, @bitCast(self.dawn)));
        mixIn(&h, @as(u32, @bitCast(self.figure_turn)));
        mixIn(&h, self.breaths);
        mixIn(&h, self.rung_lit);
        mixIn(&h, self.rung_heard);
        mixIn(&h, @intFromBool(self.drip_met));
        mixIn(&h, @as(u32, @bitCast(self.hum_light)));
        mixIn(&h, self.told);
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
        // one number rings it. The sound at the ears is that number times answer_level, and
        // the light is its square root, here seen one step faded
        const strength = sounded[i] / answer_level;
        try std.testing.expect(@abs(@sqrt(strength) - shone[i]) < 0.03 * @sqrt(strength));
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

test "nothing sounds without its light: every sound in a scripted take was told as a cue" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    var cues: [max_cues]sound.Cue = undefined;
    // the dark, from hands that walk, call and hum
    w.* = World.init();
    var handed: u32 = 0;
    var step: u32 = 0;
    while (step < 3000) : (step += 1) {
        const hands = Hands{
            .lx = if (step % 200 < 100) 90 else -40,
            .ly = if (step % 150 < 60) -110 else 20,
            .buttons = (if (step % 97 == 3) Hands.call else 0) | (if (step % 240 > 200) Hands.sing else 0),
        };
        handed += @intCast(w.stepOnce(hands, &cues));
    }
    try std.testing.expect(handed > 100);
    // every sound was sent by a cue, and none reached the ears that had no light
    try std.testing.expectEqual(w.told, w.sent);
    try std.testing.expectEqual(@as(u32, 0), w.dark_sounds);
    // the same in the field of asters, where one call rings hundreds of bells
    w.initAsters();
    step = 0;
    handed = 0;
    while (step < 1500) : (step += 1) {
        handed += @intCast(w.stepOnce(.{ .buttons = if (step == 5 or step == 600) Hands.call else 0 }, &cues));
    }
    try std.testing.expect(handed > 100 and w.answers > 100);
    try std.testing.expectEqual(w.told, w.sent);
    try std.testing.expectEqual(@as(u32, 0), w.dark_sounds);
}

test "the page stands up slowly enough to be watched, and lies down while R1 is held" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    w.stand_from = 150;
    var cues: [max_cues]sound.Cue = undefined;
    // it begins as a page, flat
    try std.testing.expectEqual(@as(f32, 0.0), w.stand);
    var step: u32 = 0;
    var began: ?u32 = null;
    var stood: ?u32 = null;
    var last: f32 = 0.0;
    while (step < 600) : (step += 1) {
        _ = w.stepOnce(.{}, &cues);
        try std.testing.expect(w.stand >= last); // it only ever rises here
        last = w.stand;
        if (began == null and w.stand > 0.0) began = step;
        if (stood == null and w.stand >= 1.0) stood = step;
    }
    // more than three seconds from the first movement to standing
    try std.testing.expect(stood.? - began.? > 180);
    // seen from the page the eye is high above Hum; standing, it is near the ground
    try std.testing.expect(w.camera().eye[1] < 4.0);
    // hold R1 and the place lies down again, within a second; let go and it stands
    step = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.stand < 0.05);
    try std.testing.expect(w.camera().eye[1] > 90.0);
    step = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(f32, 1.0), w.stand);
}

test "four breaths on the tick bring the drip's fifth true, and the figure stops" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    var cues: [max_cues]sound.Cue = undefined;
    // stand beside it
    w.hum_x = drip_x + 2.0;
    w.hum_z = drip_z;
    // its fifth starts four hundredths of a semitone flat, and the two beat almost twice a second
    try std.testing.expect(@abs(1200.0 * @log2(w.dripHz() / (garden_hz * 1.5)) - drip_flat) < 0.01);
    try std.testing.expect(w.beat() > 1.5 and w.beat() < 2.2);
    var beats: [5]f32 = undefined;
    beats[0] = w.beat();
    // a breath off the tick is nothing: no penalty
    var step: u64 = 0;
    while (step < 400) : (step += 1) {
        const off = untilTick(w.step) > 15 and untilTick(w.step) < 35;
        _ = w.stepOnce(.{ .buttons = if (step > 200 and step < 320 and off) Hands.sing else 0 }, &cues);
    }
    try std.testing.expectEqual(@as(u32, 0), w.breaths);
    // four breaths, each let go on its tick
    var breath: u32 = 0;
    var guard: u32 = 0;
    while (w.breaths < breaths_to_lock and guard < 3000) : (guard += 1) {
        const until = untilTick(w.step);
        // hold from thirty steps before a tick, and let go on it
        const hold = until > 0 and until <= 30;
        _ = w.stepOnce(.{ .buttons = if (hold) Hands.sing else 0 }, &cues);
        if (w.breaths > breath) {
            breath = w.breaths;
            beats[breath] = w.beat();
        }
    }
    try std.testing.expectEqual(breaths_to_lock, w.breaths);
    // each breath slowed the beating, and at the fourth there is none
    for (1..5) |i| try std.testing.expect(beats[i] < beats[i - 1]);
    try std.testing.expect(beats[4] < 0.001);
    try std.testing.expect(w.seen.get(.evening_breathe).met);
    // the figure turns no further: within a second it has settled, open and even, and is still
    step = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{}, &cues);
    const still_at = w.figure_turn;
    const quarter = @abs(@mod(still_at, std.math.pi) - 0.5 * std.math.pi);
    try std.testing.expect(quarter < 0.05);
    step = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(@abs(w.figure_turn - still_at) < 0.02);
    // both notes hold; then the drop lands and the page stands up
    try std.testing.expect(!w.drip_met and w.stand == 0.0);
    step = 0;
    while (step < 700) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.drip_met);
    try std.testing.expectEqual(@as(f32, 1.0), w.stand);
    try std.testing.expect(w.dawnAge() > 5.0 and w.skyLevel() > 0.2);
    try std.testing.expectEqual(w.told, w.sent);
    try std.testing.expectEqual(@as(u32, 0), w.dark_sounds);
}

test "the second call is answered by the drip, late by the distance there and back" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    var cues: [max_cues]sound.Cue = undefined;
    const far = @sqrt(drip_x * drip_x + drip_z * drip_z);
    var step: u64 = 0;
    // the first call is not answered
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .buttons = if (step == 10) Hands.call else 0 }, &cues);
    try std.testing.expect(!w.answered);
    // the second is: its ring reaches Drip, and Drip's own ring comes back
    const called = w.step;
    while (step < 700) : (step += 1) _ = w.stepOnce(.{ .buttons = if (step == 300) Hands.call else 0 }, &cues);
    try std.testing.expect(w.answered);
    const took = @as(f32, @floatFromInt(w.answered_at - called)) * dt;
    try std.testing.expect(@abs(took - 2.0 * far / sound_speed) < 0.06);
    try std.testing.expect(w.seen.get(.evening_call).met);
}

test "the horn's rungs stand at the heights of the overtones, and the seventh never sounds" {
    // a hundred metres an octave, and each ring the shore's radius over its number
    try std.testing.expectEqual(@as(f32, 0.0), rungHeight(1));
    try std.testing.expect(@abs(rungHeight(2) - 100.0) < 0.01);
    try std.testing.expect(@abs(rungHeight(3) - 158.496) < 0.01);
    try std.testing.expect(@abs(rungHeight(16) - 400.0) < 0.01);
    try std.testing.expect(@abs(rungRadius(2) - 925.0) < 0.01);
    try std.testing.expect(@abs(rungRadius(16) - 115.625) < 0.01);
    // a belly throws you as high as its overtone is loud, 100 / ln 2 / n metres: always past the
    // gap to the next rung, and never as far as the one after (spec/sky.md)
    var k: u32 = 1;
    while (k < 256) : (k += 1) {
        const throw = octave_m / std.math.ln2 / @as(f32, @floatFromInt(k));
        try std.testing.expect(throw > rungHeight(k + 1) - rungHeight(k));
        try std.testing.expect(throw < rungHeight(k + 2) - rungHeight(k));
    }
    try std.testing.expect(!rungSounds(7) and !rungSounds(14) and !rungSounds(21));
    try std.testing.expect(rungSounds(6) and rungSounds(8) and rungSounds(16));
}

test "the sun climbs the horn: each rung lights where it stands at once, and is heard late by its distance" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    w.dawn_from = 0; // the sun rises now
    var cues: [max_cues]sound.Cue = undefined;
    var lit_at: [rungs + 1]?u64 = @splat(null);
    var heard_at: [rungs + 1]?u64 = @splat(null);
    var step: u64 = 0;
    while (step < 60 * 330) : (step += 1) {
        const n = w.stepOnce(.{}, &cues);
        var k: u32 = 1;
        while (k <= rungs) : (k += 1) {
            if (lit_at[k] == null and w.rung_lit & (@as(u32, 1) << @intCast(k)) != 0) lit_at[k] = step;
        }
        for (cues[0..n]) |cue| {
            if (cue.kind != .strike or cue.family != .string) continue;
            var j: u32 = 1;
            while (j <= rungs) : (j += 1) {
                if (heard_at[j] == null and @abs(cue.hz - sun_hz * @as(f32, @floatFromInt(j))) < 0.01) heard_at[j] = cue.at;
            }
        }
    }
    // dawn is an arpeggio: rungs one to six light in order, and the seventh never does
    var k: u32 = 2;
    while (k <= 6) : (k += 1) try std.testing.expect(lit_at[k].? > lit_at[k - 1].?);
    try std.testing.expect(lit_at[7] == null);
    try std.testing.expectEqual(@as(u32, 6), w.rung_heard);
    // rung two is 100 m up: the sun reaches it a minute and a half after it rises
    const two = @as(f32, @floatFromInt(lit_at[2].?)) * dt;
    try std.testing.expect(@abs(two - daylight_s * std.math.asin(@as(f32, 0.25)) / std.math.pi) < 0.1);
    // its light is there at once, and its note is heard as late as it is far from Hum
    const r = w.things[w.rung_first + 1];
    const far = @sqrt(r.x * r.x + r.z * r.z + r.y * r.y);
    const late = @as(f32, @floatFromInt(heard_at[2].? - lead)) / sound.rate - two;
    try std.testing.expect(@abs(late - far / sound_speed) < 0.1);
    // and the day reached Hum when the dawn had crossed the ground from the shore
    try std.testing.expectEqual(@as(f32, 1.0), w.dayAt(0.0, 0.0));
}
