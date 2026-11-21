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
pub const ground = @import("ground.zig");
pub const flyers = @import("flyers.zig");
pub const pools = @import("pools.zig");
pub const knots = @import("knots.zig");
/// The land's tables, from its score (scores/garden.txt, through tools/score.py).
pub const land = @import("land.zig");
/// The hose's curve, worked out from the score when the game is built.
pub const hose = @import("hose.zig");

/// The puddles on the ground at once (pools.zig).
pub const max_pools = pools.garden.len;
/// How loud standing water sings its note back, at full loudness, against a voice.
pub const pool_voice: f32 = 0.8;
/// A call's overtones, for which shape of a puddle it strikes: the string's (sound.zig).
const call_overtones = [4]f32{ 1.0, 0.5, 0.33, 0.25 };
pub const witness = @import("witness.zig");

pub const steps_per_second = 60;
pub const samples_per_step = 800;
pub const dt: f32 = 1.0 / 60.0;
/// Metres a second. About ten times Hum's run, so a ring can be watched (to tune).
pub const sound_speed: f32 = 60.0;
/// The clap: Hum's own, sounded where the hands find it; how bright, how short, how many octaves
/// over home; and how many steps after a call a clap takes the call back (the clap's window,
/// plat/keys.zig, and a step).
pub const clap_strength: f32 = 0.7;
pub const clap_ring: f32 = 0.15;
pub const clap_over: f32 = 4.0;
pub const clap_takes_back: u64 = 7;
/// The hose as an instrument (spec/world.md, "Its great instrument: the Hose", and wonder 8): stopped
/// by its knot it is a pipe sounding two octaves under the garden's note, its odd overtones only,
/// hollow; sprung open, an octave up with every overtone back. It is heard from anywhere in the
/// garden, louder the nearer the hose: its least, how much more near it, and from how far.
pub const hose_stopped_hz: f32 = garden_hz / 4.0;
pub const hose_open_hz: f32 = garden_hz / 2.0;
pub const hose_voice: u8 = 15;
pub const hose_least: f32 = 0.05;
pub const hose_more: f32 = 0.18;
pub const hose_heard: f32 = 450.0;
pub const hose_open_more: f32 = 1.3;
/// Once the knot springs open the water runs down the hose to the pool, metres a second; a moment
/// after it pours in, a blue figure sits on the pool's edge, for a second (SPEC.md 6.1): on the north
/// edge a little west of where Hum woke, facing out over the water, so that from the knot's side of
/// the garden it is seen side-on.
pub const water_speed: f32 = 40.0;
pub const figure_after: u64 = 90;
pub const figure_for: u64 = 60;
pub const figure_at = [2]f32{ land.pool[0] - land.pool[2] * 0.2588, land.pool[1] - land.pool[2] * 0.9659 };
/// A strike pressed within an eighth of a beat of Hum's beat is timed: it lands at once and rings
/// fuller, its note with its octave and a brighter light, and takes more (law 7: a push within an
/// eighth of a cycle of the right moment adds its whole size). Off the beat the game places it on
/// the next beat, plain (SPEC.md 10).
/// Hum's strike: the fork, an octave over home, how hard and how long.
pub const strike_over: f32 = 2.0;
pub const strike_strength: f32 = 0.6;
pub const strike_ring: f32 = 0.5;
pub const strike_window: f64 = @as(f64, @floatFromInt(tick_every)) / 8.0;
pub const timed_takes: f32 = 1.25;
/// Gentle widens every window of timing by one sum (SPEC.md 10: "Gentle widens the timing and the
/// ledges"): the strike's, the dodge's, a meeting's, the downbeat's and the breath's.
pub const gentle_widens: f64 = 1.5;
/// Hum's run, with the stick pushed all the way (Morgan: "probably faster movement overall").
pub const run_speed: f32 = 9.0;
/// How wide Hum is from its middle, and an aster's stalk at its foot (draw/aster_lines.zig, girth):
/// Hum goes round a stalk, never through it.
pub const hum_body: f32 = 0.36;
pub const stalk_foot: f32 = 0.54;
/// Going into a stalk faster than this rings it; at a full run it rings as hard as a brush can.
pub const bump_least: f32 = 1.5;
/// How much of an aster's bells' strength a brush at a full run gives them, and its knock.
pub const brush_rings: f32 = 0.6;

/// How much of the way to the speed the stick asks for Hum's legs go each step, pushed and let go:
/// nine tenths of the way in a sixth of a second, and a skid of about 0.4 m from a run.
pub const go_ease: f32 = 0.2;
pub const stop_ease: f32 = 0.28;
/// How far Hum turns in a step at most: a turn about takes a quarter of a second.
pub const turn_most: f32 = 0.2;
/// The view swings in behind where Hum is going at this rate (a part of the gap a second, at a
/// run), once the right stick has rested this many steps, and only while Hum goes no more than
/// this far round from the way the view looks: running at the screen leaves the view where it is.
pub const follow_rate: f32 = 1.1;
pub const follow_after: u32 = 45;
pub const follow_within: f32 = 2.2;
/// At a run the view pulls back this far, rises this much and widens this many degrees.
pub const run_back: f32 = 3.0;
pub const run_up: f32 = 0.4;
pub const run_wider: f32 = 3.0;
/// The garden's note: middle C.
pub const garden_hz: f32 = land.note;
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
pub const lake_x: f32 = land.lake[0];
pub const lake_z: f32 = land.lake[1];
pub const lake_r: f32 = 1850.0;
/// The sun holds the day's note itself: middle C on the garden's morning (spec/sky.md).
pub const sun_hz: f32 = garden_hz;

/// The wheel (SPEC.md 9). Twelve wedges round by fifths; the day's seven notes are lit, and home is
/// one of them. Where home sits among the seven is the mood, brightest to darkest, and each mood is
/// one of the seven modes: wonder (Lift) a fifth below the day's note, sunny home (Bind) on it,
/// drive, cool soul, tenderness, fierceness and the darkest a fifth, two, three, four and five
/// above.
pub const Mood = enum(u3) { lift, bind, drive, flow, remember, strike, darkest };
/// A wedge is counted in fifths from the day's note: the lit seven are -1 to 5.
pub const lit_least: i8 = -1;
pub const lit_most: i8 = 5;
/// The Garden's tuning is pure (spec/laws.md, "Tuning"): the lit seven as ratios to the day's
/// note, in the order of the wedges: F, C, G, D, A, E, B for a day on C.
const pure_lit = [7]f32{ 4.0 / 3.0, 1.0, 3.0 / 2.0, 9.0 / 8.0, 5.0 / 3.0, 5.0 / 4.0, 15.0 / 8.0 };

/// The wedge a direction of the right stick points at. The day's note is at the top, the sharp
/// side to the right and the flat side to the left, a twelfth of a turn for each fifth; the five
/// dark wedges are under the horizon. Up on the stick is negative y.
pub fn wedgeAt(rx: f32, ry: f32) i8 {
    const turn = std.math.atan2(rx, -ry); // 0 at the top, clockwise
    var k: i32 = @intFromFloat(@round(turn / (std.math.pi / 6.0)));
    if (k > 5) k -= 12;
    if (k < -6) k += 12;
    return @intCast(k);
}

/// The lit wedge a note falls on, in fifths from the day's note, by its pitch class; a note off the
/// lit seven gives the nearest of them.
pub fn wedgeOfHz(day_hz: f32, hz: f32) i8 {
    var best: i8 = 0;
    var best_off: f32 = 1e9;
    var k: i8 = lit_least;
    while (k <= lit_most) : (k += 1) {
        const c = 1200.0 * @log2(hz / wedgeHz(day_hz, k));
        const off = @abs(c - 1200.0 * @round(c / 1200.0));
        if (off < best_off) {
            best_off = off;
            best = k;
        }
    }
    return best;
}

/// The mood of a lit wedge.
pub fn moodOf(k: i8) Mood {
    return @enumFromInt(@as(u3, @intCast(k - lit_least)));
}

/// A lit wedge's note, sung in Hum's own register: folded into the octave round the day's note.
pub fn wedgeHz(day_hz: f32, k: i8) f32 {
    const kk = std.math.clamp(k, lit_least, lit_most);
    var hz = day_hz * pure_lit[@intCast(kk - lit_least)];
    const high = day_hz * std.math.sqrt2;
    const low = day_hz / std.math.sqrt2;
    while (hz >= high) hz *= 0.5;
    while (hz < low) hz *= 2.0;
    return hz;
}
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

/// How hard Hum's call is, standing on a cover: moss takes half (spec/shape.md). The hands' early
/// start of the call (sound.zig, ownNow) uses the same sum.
pub fn callStrength(cover: ground.Cover) f32 {
    return 0.857 * (if (cover == .moss) moss_carries else 1.0);
}

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

/// A place in the world.
pub const Place = struct { x: f32, y: f32, z: f32 };

/// What a cue comes from: Hum, a thing, or a place where something small happens, a drop of dew
/// or a leaf, that is not a thing of its own.
pub const Source = union(enum) { hum, thing: u32, at: Place };

/// The light of something small that sounded at a place: seen where it is at once, fading as it
/// rings.
pub const Spark = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,
    hz: f32 = 0.0,
    bright: f32 = 0.0,
    fades: f32 = 0.2,
    born: u64 = 0,
    live: bool = false,
};
pub const max_sparks = 48;

/// How far the sound of something small, dew or a leaf, carries before it has fallen to half.
pub const small_carry: f32 = 40.0;

/// Moss swallows sound: a call made on it carries half as far (spec/shape.md, the Garden).
pub const moss_carries: f32 = 0.5;
/// Steps of walking between one drop of dew landing in your wake, and between leaves underfoot.
/// Underfoot, by how far Hum has walked: dew shed every 0.9 m of lawn, a leaf rung every 1.4 m.
pub const dew_every: f32 = 0.9;
pub const leaf_every: f32 = 1.4;

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
/// Out on standing water: the view this far behind Hum, this high, and looking this much lower.
pub const water_back: f32 = 30.0;
pub const water_up: f32 = 15.0;
pub const water_down: f32 = 0.55;
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
/// R1 held this long opens the wheel, once the place has stood up (SPEC.md 9; the wheel toy's
/// 0.17 s).
pub const wheel_after: u32 = 10;
/// While the wheel is open the world's beat runs at this part of its pace: time thickens, and what
/// is ringing stretches into a held chord (SPEC.md 9; the wheel toy's 0.25).
pub const thick: f32 = 0.25;

/// While the wheel is open the place lies back this far toward the page, and no further.
pub const wheel_stand: f32 = 0.7;
/// The swell (SPEC.md 9). A nudge of the right stick this far over, within this many steps of a
/// downbeat, walks home one wedge; most bands Hum takes. A downbeat is the first of Drip's four
/// ticks to a bar.
pub const nudge_least: f32 = 0.6;
pub const nudge_back: f32 = 0.3;
pub const downbeat_window: u64 = 8;
pub const swell_most: u8 = 8;
/// Where home is when R2 is let go on a downbeat, against where the swell began, decides the
/// cadence: a fifth down is the full close, a fifth up the amen, nowhere the turn, further the slide.
pub const Cadence = enum(u8) { none, full_close, amen, turn, slide };

/// While the wheel is open the view rises this high, this far behind Hum, and looks down at it.
pub const wheel_up: f32 = 78.0;
pub const wheel_back: f32 = 46.0;
/// How far the right stick must be pushed to point at a wedge.
pub const wheel_point_least: f32 = 0.55;
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
    /// Where in this step, in samples from its start, R1 or R2 last went down or up: Hum's own
    /// call and hum start on that very sample (spec/promises/workshop.md, hands.voice-in-a-buffer),
    /// and a breath is judged by it. Nought when nobody knows better than the step.
    stamp: u16 = 0,

    pub const call: u16 = 1 << 0; // R1
    pub const sing: u16 = 1 << 1; // R2
    pub const voice: u16 = 1 << 2; // L1
    pub const guard: u16 = 1 << 3; // L2
    pub const jump: u16 = 1 << 4; // bottom face
    pub const dodge: u16 = 1 << 5; // right face
    pub const strike: u16 = 1 << 6; // left face
    pub const grab: u16 = 1 << 7; // top face
    pub const select: u16 = 1 << 8;
    /// L1 and R1 together, for the one step the second of them came: found where the presses are
    /// stamped (plat/keys.zig, Clap), so the sound and the world agree on every clap.
    pub const clap: u16 = 1 << 10;
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
    /// How far it reaches from its middle over the ground, as a pool does: its sound comes from
    /// its nearest part.
    spread: f32 = 0.0,
    /// The step it last rang, so its kin can't ring it straight back.
    rung_at: u32 = 0,
    /// The ground's height under it (world/ground.zig), kept as it is placed and as it moves.
    ground: f32 = 0.0,
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
    /// How far it has run, in steps of the world's beat, and how far it had reached the step before.
    age: f32 = 0.0,
    last_reach: f32 = 0.0,
    live: bool = false,
    /// The note that is travelling.
    hz: f32 = garden_hz,
    /// Hum's own call, which rings what it passes; or someone else's, which is an answer.
    own: bool = true,
    /// How strong it set out: less from moss.
    strength: f32 = 1.0,
    /// The ground's height where it set out.
    ground: f32 = 0.0,
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
    /// Whether it is a thing answering Hum's call, rather than sounding of its own accord.
    answer: bool = false,
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

/// How much two things share: the strongest pair of their overtones that agree, each as loud as it
/// is in its own thing (law 1).
pub fn kinOf(a: Thing, b: Thing) f32 {
    const ra = sound.recipe(a.family);
    const rb = sound.recipe(b.family);
    var best: f32 = 0.0;
    for (ra.mult, ra.gain) |ma, ga| {
        if (ma <= 0.0 or ga <= 0.0) continue;
        for (rb.mult, rb.gain) |mb, gb| {
            if (mb <= 0.0 or gb <= 0.0) continue;
            best = @max(best, ga * gb * share(cents(a.hz * ma, b.hz * mb)));
        }
    }
    return @min(best, 1.0);
}

/// Law 1 flows between things, not only from Hum: a thing that rings rings its kin, and they ring
/// theirs, more faintly each time. Each sounding thing keeps its nearest strong kin, found when the
/// world is made.
pub const kin_most = 4;
pub const Kin = struct {
    index: u16 = 0,
    /// How much they share, out of 65535; nought for none.
    share: u16 = 0,
};
/// How near kin must be to be rung by a thing's sound, and how much they must share.
pub const kin_within: f32 = 60.0;
pub const kin_least: f32 = 0.3;
/// How much of a thing's ringing each passing-on keeps, and how hard a thing must ring to pass it
/// on at all.
pub const cascade_keeps: f32 = 0.45;
pub const cascade_floor: f32 = 0.08;
/// A thing that has rung rests this long before its kin can ring it again, so two kin never ring
/// each other back and forth.
pub const rests_for: u32 = 45;
/// A thing due to ring because its kin rang: when, how hard, and whether it is part of an answer to
/// Hum's call.
pub const Echo = struct { thing: u16 = 0, due: u64 = 0, strength: f32 = 0.0, answer: bool = false, live: bool = false };
pub const max_echoes = 512;

const bell_mult = [8]f32{ 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0 };
const bell_gain = [8]f32{ 0.30, 1.0, 0.45, 0.35, 0.55, 0.20, 0.22, 0.10 };

pub const World = struct {
    step: u64 = 0,
    /// The day's note, the wheel's lit seven round it, and where home is among them: Hum always
    /// sings home's note (SPEC.md 5, "you never choose a note"). Which moods are awake: on the first
    /// days in the Garden, wonder and sunny home (design/the-wheel.md).
    day_hz: f32 = garden_hz,
    home_k: i8 = 0,
    home_hz: f32 = garden_hz,
    awake: u8 = (1 << @intFromEnum(Mood.lift)) | (1 << @intFromEnum(Mood.bind)),
    hum_x: f32 = 0.0,
    hum_z: f32 = 0.0,
    /// Which way Hum faces, in radians: 0 is toward -z.
    hum_face: f32 = 0.0,
    /// Hum's own going, in metres a second: what its legs do, before the water has its say.
    hum_vx: f32 = 0.0,
    hum_vz: f32 = 0.0,
    /// Steps since the right stick last moved the view: the view follows Hum only after a rest.
    looked_ago: u32 = 1000,
    /// How far Hum has walked, in metres: its stride, and what the ground does underfoot.
    stride: f32 = 0.0,
    /// How many times Hum has brushed a stalk hard enough to ring it, and the step and aster of the
    /// last, so one brush rings once.
    bumps: u32 = 0,
    bumped_at: u64 = 0,
    bumped_tower: u16 = no_tower,
    /// The stalk Hum is against now, if any: a brush rings only as it begins.
    touching: u16 = no_tower,
    /// The sideways pull of Hum's turning, eased: it leans into a turn.
    lean_x: f32 = 0.0,
    lean_z: f32 = 0.0,
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
    /// The wheel: open while R1 is held after the place has stood up; the wedge the right stick
    /// points at, in fifths from the day's note (none while the stick is at rest).
    wheel_open: bool = false,
    wheel_point: ?i8 = null,
    wheel_opens: u32 = 0,
    /// How far the view has risen to look down on the open wheel, 0 to 1.
    wheel_view: f32 = 0.0,
    /// The world's beat: its pace (one, or thick while the wheel is open), and its clock in steps,
    /// the same as the step count until time first thickens. Drip's ticks, the downbeats, the bee,
    /// rings on the ground and the water keep it; the sky keeps the sun's.
    tempo: f32 = 1.0,
    clock: u64 = 0,
    clock_part: f32 = 0.0,
    ticked_at: u64 = never,
    /// The swell: where home was when it began, how many bars it has grown, whether the right stick
    /// is still out from a nudge, the last cadence that landed and when, and the last downbeat.
    swell_from: i8 = 0,
    swell_bars: u8 = 0,
    nudge_out: bool = false,
    cadence: Cadence = .none,
    cadence_at: u64 = never,
    cadences: u32 = 0,
    downbeat_at: u64 = never,
    downbeat_beat: u64 = never,
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
    /// What the ground under Hum wears, and how many steps it has walked.
    cover: ground.Cover = .soil,
    walked: u32 = 0,
    sparks: [max_sparks]Spark = @splat(.{}),
    next_spark: u32 = 0,
    /// Who lives in the sky (flyers.zig).
    bee: flyers.Bee = .{},
    /// Set while a thing is being told to answer Hum's call, so its arrival is known as one.
    answering: bool = false,
    /// Set while Hum's own call or hum is told for a press or a let-go of this step: it is sent on
    /// the stamped sample, and marked as Hum's own, since the hands may have started it already.
    own_now: u8 = sound.own_world,
    own_at: u64 = 0,
    /// Puddles from the storm (pools.zig), and where Hum stepped onto one.
    pools: [max_pools]pools.Pool = undefined,
    pool_count: u32 = 0,
    pool_first: u32 = no_thing,
    on_pool: u8 = 0,
    pool_in_x: f32 = 0.0,
    pool_in_z: f32 = 0.0,
    crossed: u32 = 0,
    /// How far the view has risen over a standing pool, 0 to 1, and over which.
    pool_view: f32 = 0.0,
    pool_seen: u8 = 0,
    /// How far the view has lifted behind Hum while it walks standing water, 0 to 1.
    water_view: f32 = 0.0,
    /// Knots (knots.zig): the first three, which come at Hum near the puddle sized for wonder.
    knots: [knots.max_knots]knots.Knot = @splat(.{}),
    knot_count: u32 = 0,
    knots_home: u32 = 0,
    strikes: u32 = 0,
    /// The dodge and the pocket (SPEC.md 10): when the last dodge was, in steps of the world's
    /// beat; until when the pocket is open, in steps; how many pockets and how many lunges landed.
    dodged_at: u64 = never,
    pocket_until: u64 = 0,
    pockets: u32 = 0,
    knocked: u32 = 0,
    /// The afterimage (SPEC.md 10): this bar's strikes, where in the bar each fell; whether a
    /// pocket opened in it; the layers kept from bars in the pocket, each a bar's strikes landing
    /// again beside Hum; the claps that spent them.
    bar_strikes: [knots.strikes_in_a_bar]u16 = @splat(0),
    bar_strike_n: u8 = 0,
    bar_pocketed: bool = false,
    layers: [knots.layers_most][knots.strikes_in_a_bar]u16 = @splat(@splat(0)),
    layer_strikes: [knots.layers_most]u8 = @splat(0),
    layer_level: [knots.layers_most]f32 = @splat(0.0),
    layer_n: u8 = 0,
    ghost_strikes: u32 = 0,
    ghost_at: u64 = never,
    claps: u32 = 0,
    clap_at: u64 = never,
    /// Built from the Garden's score (scores/garden.txt), with its Mirror Pool; a world made for a
    /// test of one thing has none.
    in_garden: bool = false,
    /// The ground's height where Hum stands (world/ground.zig): a thing's y is its height above its
    /// own ground, and the ground's height is added where height is seen or heard.
    hum_ground: f32 = 0.0,
    /// The hose (world/hose.zig): its thing, which sounds and shines as the drone from its nearest
    /// stretch; whether its knot has sprung open; when the water set out from the knot and when it
    /// reached the pool; when the figure sat on the pool's edge.
    hose_thing: u32 = no_thing,
    hose_open: bool = false,
    hose_opened_at: u64 = never,
    water_from: u64 = never,
    water_at: u64 = never,
    figure_from: u64 = never,
    /// Gentle or Fierce (SPEC.md 10), chosen any night; the first evening is Gentle. Gentle widens
    /// the timing, leans home for you and lets fights end by comfort; Fierce asks for the full close.
    fierce: bool = false,
    /// This swell: whether the thumb has steered it, and whether Gentle has leaned home for you.
    swell_steered: bool = false,
    swell_leaned: bool = false,
    leans_for_you: u32 = 0,
    /// The doors met: rung open, settled, turned kin, slid home, and plain endings.
    doors: [5]u32 = @splat(0),
    /// A strike pressed off the beat waits for the beat the game places it on: that beat, in steps
    /// of the world's beat. And how many strikes were timed and how many placed.
    strike_due: u64 = never,
    timed_strikes: u32 = 0,
    placed_strikes: u32 = 0,
    /// When Hum last called, in steps, so a clap just after can take the call back; and how many
    /// it has.
    called_at: u64 = never,
    calls_taken_back: u32 = 0,
    looped_at: u64 = never,
    /// Each thing's kin, and the things due to ring because their kin rang (law 1).
    kin: [max_things][kin_most]Kin = @splat(@splat(.{})),
    echoes: [max_echoes]Echo = @splat(.{}),
    echoed: u32 = 0,
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
        // the two locked before the morning began
        self.locked_at = 0;
        self.hold_until = 0;
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
        self.in_garden = true;
        self.hum_x = land.wake[0];
        self.hum_z = land.wake[1];
        self.hum_ground = ground.heightAt(self.hum_x, self.hum_z);
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
        self.things[at] = .{ .x = drip_x, .y = 0.3, .z = drip_z, .tall = 0.4, .hz = garden_hz * 1.5, .family = .bar, .ring = 0.2, .carry = 50.0 };
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
        // the bee: 1.3 m long, humming the garden's note
        const bee_thing = at;
        self.things[at] = .{ .y = flyers.Bee.over_clover, .tall = 0.65, .hz = garden_hz, .family = .skin, .ring = 0.4, .carry = flyers.Bee.carry };
        at += 1;
        // the puddles from the storm (pools.zig), each a skin of water sized so the garden's note
        // stands in it as a figure of its own
        self.pool_first = at;
        for (pools.garden, 0..) |pd, i| {
            const r = pools.radiusFor(pd.shape, garden_hz * pd.note);
            self.things[at] = .{ .x = pd.x, .y = 0.0, .z = pd.z, .tall = r, .spread = r, .hz = pools.skin_k / r, .family = .skin, .ring = 2.5, .carry = 120.0 };
            self.pools[i] = pools.Pool.init(pd.x, pd.z, r, at, 0x9e37_79b9 +% @as(u32, @intCast(i)) *% 0x85eb_ca6b);
            at += 1;
        }
        self.pool_count = pools.garden.len;
        // the first knots: two strands each, C and the A above it, over the F below that both are
        // overtones of (design/the-wheel.md); three of them south of the puddle sized for wonder
        // where each waits about the hose's knot
        const knot_at = land.knots;
        const st = land.knot_strands;
        for (knot_at, 0..) |off, i| {
            const p = [2]f32{ hose.knot[0] + off[0], hose.knot[1] + off[1] };
            var kn = knots.Knot{
                .x = p[0],
                .z = p[1],
                .root_hz = garden_hz * land.knot_root[0] / land.knot_root[1],
                .strands = .{ .{ .hz = garden_hz * st[0].num / st[0].den, .over = st[0].over }, .{ .hz = garden_hz * st[1].num / st[1].den, .over = st[1].over } },
                .around = @as(f32, @floatFromInt(i)) * (2.0 * std.math.pi / 3.0),
            };
            for (0..2) |s| {
                self.things[at] = .{ .x = p[0], .y = 1.5, .z = p[1], .tall = 1.2, .hz = kn.strands[s].hz, .family = .string, .ring = 0.6, .carry = 60.0 };
                kn.thing[s] = at;
                at += 1;
            }
            self.knots[i] = kn;
        }
        self.knot_count = knot_at.len;
        // the hose, sounding from its stretch nearest Hum
        self.hose_thing = at;
        self.things[at] = .{ .x = hose.knot[0], .y = 1.0, .z = hose.knot[1], .tall = 1.0, .hz = hose_stopped_hz, .family = .stopped_pipe, .ring = 0.0, .carry = 1e9, .sounds = false };
        at += 1;
        // the sun rises on the shore, at the first rung's place
        self.sun_x = self.things[self.rung_first].x;
        self.sun_z = self.things[self.rung_first].z;
        self.thing_count = at;
        self.bee.place(self, bee_thing, .{ (drip_x + asters.great_x) * 0.5, (drip_z + asters.great_z) * 0.5 }, 0);
        self.thing_count = at;
        self.findKin();
        self.settleGrounds();
    }

    /// Tell the player something. This is the only way anything in the world makes a sound, and
    /// it takes a cue, which always has its light. The light is put on the thing here and now;
    /// the sound is sent on its way and reaches Hum's ears when it has travelled there.
    pub fn tell(self: *World, from: Source, what: cues_mod.Cue) void {
        const now_sample = self.step * samples_per_step;
        self.told += 1;
        switch (from) {
            .hum => {
                switch (what.light.shape) {
                    .ring_on_the_ground => self.startRing(self.hum_x, self.hum_z, what.sound.hz, true, if (self.cover == .moss) moss_carries else 1.0),
                    .swell => self.singing = true,
                    .dims => self.singing = false,
                    .glow => {},
                }
                self.hum_light = @max(self.hum_light, what.light.brightness);
                const at = if (self.own_now != sound.own_world) self.own_at else now_sample + lead;
                self.send(at, .{ .at = 0, .kind = what.sound.kind, .family = what.sound.family, .voice = what.sound.voice, .own = self.own_now, .hz = what.sound.hz, .gain = what.sound.strength * voice_level, .ring = what.sound.ring }, no_thing, what.light);
            },
            .thing => |index| {
                const thing = &self.things[index];
                thing.loud = @max(thing.loud, what.light.brightness);
                if (what.light.shape == .ring_on_the_ground) self.startRing(thing.x, thing.z, what.sound.hz, false, 1.0);
                // heard when it has come back to where Hum is now, softer and duller for the
                // way it has come; its light is where it is, as bright as it sounds there
                const hx = thing.x - self.hum_x;
                const hz = thing.z - self.hum_z;
                const flat = @max(0.0, @sqrt(hx * hx + hz * hz) - thing.spread);
                const up = thing.y + thing.ground - self.hum_ground;
                const far = @sqrt(flat * flat + up * up);
                const delay: u64 = @intFromFloat(far / sound_speed * sound.rate);
                const level: f32 = if (what.sound.kind == .strike) answer_level else voice_level;
                const kept = 1.0 / (1.0 + (far / thing.carry) * (far / thing.carry));
                self.send(now_sample + lead + delay, .{ .at = 0, .kind = what.sound.kind, .family = what.sound.family, .voice = what.sound.voice, .hz = what.sound.hz, .gain = what.sound.strength * level * kept, .ring = what.sound.ring, .dull = far / (thing.carry * 4.0) }, index, what.light);
            },
            .at => |place| {
                // its light where it is, at once; its sound when it has come to Hum
                self.sparks[self.next_spark % max_sparks] = .{
                    .x = place.x,
                    .y = place.y,
                    .z = place.z,
                    .hz = what.light.hz,
                    .bright = what.light.brightness,
                    .fades = @max(what.light.fades, 0.15),
                    .born = self.step,
                    .live = true,
                };
                self.next_spark +%= 1;
                const hx = place.x - self.hum_x;
                const hz = place.z - self.hum_z;
                const up = place.y + self.groundAt(place.x, place.z) - self.hum_ground;
                const far = @sqrt(hx * hx + hz * hz + up * up);
                const delay: u64 = @intFromFloat(far / sound_speed * sound.rate);
                const kept = 1.0 / (1.0 + (far / small_carry) * (far / small_carry));
                self.send(now_sample + lead + delay, .{ .at = 0, .kind = what.sound.kind, .family = what.sound.family, .hz = what.sound.hz, .gain = what.sound.strength * answer_level * kept, .ring = what.sound.ring, .dull = far / (small_carry * 4.0) }, no_thing, what.light);
            },
        }
    }

    /// A ring of light begins to run out from a place: a call's, or an answer's.
    fn startRing(self: *World, x: f32, z: f32, hz: f32, own: bool, strength: f32) void {
        var oldest: usize = 0;
        for (self.rings, 0..) |r, i| {
            if (!r.live) {
                oldest = i;
                break;
            }
            if (r.born < self.rings[oldest].born) oldest = i;
        }
        self.rings[oldest] = .{ .x = x, .z = z, .born = self.step, .live = true, .hz = hz, .own = own, .strength = strength, .ground = self.groundAt(x, z) };
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
            slot.* = .{ .at = at, .cue = heard_as, .live = true, .from = from, .light = shown, .answer = self.answering };
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
        // Hum's legs: the stick says where and how fast, and the body gets there quickly but not at
        // once, turns at a rate, and skids a little when let go
        var want_x: f32 = 0.0;
        var want_z: f32 = 0.0;
        if (size > 0.12) {
            const scale = @min(size, 1.0) / size * run_speed;
            var wx = mx;
            var wz = mz;
            if (self.view == .place) {
                const cy = @cos(self.look_yaw);
                const sy = @sin(self.look_yaw);
                wx = cy * mx - sy * mz;
                wz = sy * mx + cy * mz;
            }
            want_x = wx * scale;
            want_z = wz * scale;
            var turn = std.math.atan2(wx, -wz) - self.hum_face;
            if (turn > std.math.pi) turn -= 2.0 * std.math.pi;
            if (turn < -std.math.pi) turn += 2.0 * std.math.pi;
            self.hum_face += std.math.clamp(turn, -turn_most, turn_most);
            if (self.hum_face > std.math.pi) self.hum_face -= 2.0 * std.math.pi;
            if (self.hum_face < -std.math.pi) self.hum_face += 2.0 * std.math.pi;
            self.still = 0;
        } else {
            self.still +|= 1;
        }
        const was_vx = self.hum_vx;
        const was_vz = self.hum_vz;
        const ease: f32 = if (size > 0.12) go_ease else stop_ease;
        self.hum_vx += (want_x - self.hum_vx) * ease;
        self.hum_vz += (want_z - self.hum_vz) * ease;
        if (size <= 0.12 and self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz < 0.0025) {
            self.hum_vx = 0.0;
            self.hum_vz = 0.0;
        }
        // it leans into a turn: the part of its change of going that is across its way
        const speed2 = self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz;
        var pull_x: f32 = 0.0;
        var pull_z: f32 = 0.0;
        if (speed2 > 0.25) {
            const sp = @sqrt(speed2);
            const ux = self.hum_vx / sp;
            const uz = self.hum_vz / sp;
            const ax = (self.hum_vx - was_vx) / dt;
            const az = (self.hum_vz - was_vz) / dt;
            const along = ax * ux + az * uz;
            pull_x = std.math.clamp((ax - along * ux) * 0.006, -0.2, 0.2);
            pull_z = std.math.clamp((az - along * uz) * 0.006, -0.2, 0.2);
        }
        self.lean_x += (pull_x - self.lean_x) * 0.15;
        self.lean_z += (pull_z - self.lean_z) * 0.15;
        var go_x = self.hum_vx * dt;
        var go_z = self.hum_vz * dt;
        // on the water, the water has its say in where a step goes
        if (self.view == .place and self.pool_count > 0) self.onWater(&go_x, &go_z);
        if (self.view == .place) self.atShore(&go_x, &go_z);
        if (self.view == .place) self.atRim(&go_x, &go_z);
        if (self.view == .place) self.atStalks(&go_x, &go_z);
        self.hum_x += go_x;
        self.hum_z += go_z;
        self.hum_ground = self.groundAt(self.hum_x, self.hum_z);
        const moved = @sqrt(go_x * go_x + go_z * go_z);
        if (moved > 0.0005 and self.view == .place and self.stand >= 1.0) self.underfoot(moved);
        if (self.view == .place and self.pool_count > 0) self.crossings();
        if (self.view == .place) self.cover = ground.underfootAt(self.hum_x, self.hum_z);
        if (self.view == .place) {
            // the hinge: the world is a page until it stands, and holding R1 lays it down again
            self.call_held = if (hands.held(Hands.call)) self.call_held +| 1 else 0;
            self.wheelStep(hands);
            const pace: f32 = if (self.wheel_open) thick else if (self.step < self.pocket_until) knots.pocket else 1.0;
            if (pace != self.tempo) {
                self.tempo = pace;
                // what is ringing stretches into a held chord while time is thick, and lets go after
                self.tell(.hum, cues_mod.Cue.of(.{ .kind = .tempo, .hz = self.home_hz, .strength = pace, .ring = 0.0 }, .glow));
            }
            const standing = self.step >= self.stand_from and self.call_held < fold_after;
            if (self.step == self.stand_from and self.dawn_from == never) self.dawn_from = self.step;
            if (self.wheel_open) {
                // the place lies back toward the page while home is chosen, and no further
                self.stand = if (self.stand > wheel_stand) @max(wheel_stand, self.stand - fold_rate) else @min(wheel_stand, self.stand + rise_rate);
            } else {
                self.stand = if (standing) @min(1.0, self.stand + rise_rate) else @max(0.0, self.stand - fold_rate);
            }
            self.look(hands);
        }

        // L1 and R1 together: the clap (SPEC.md 8). Wherever Hum is and whatever it is doing, as the
        // hands have already sounded it
        if (pressed & Hands.clap != 0) self.clap();

        // the right face dodges: a quick step aside, and on the beat a lunge lands on, the pocket
        if (self.view == .place and self.stand >= 1.0 and pressed & Hands.dodge != 0) self.dodge();

        // the left face strikes with Hum's fork (SPEC.md 10)
        // the left face strikes: timed by the hands near the beat, at once and fuller; otherwise the
        // game places it on the next beat
        if (self.canStrike() and pressed & Hands.strike != 0) {
            const at = self.beatAt(hands.stamp);
            if (at.from_beat <= self.widen(strike_window)) {
                self.strike_due = never;
                self.strike(at.pos, true);
            } else if (self.strike_due == never) {
                self.strike_due = at.next_beat;
            }
        }
        // a placed strike lands on its beat, on the sample the beat falls
        if (self.strike_due != never) self.placedStrike(now_sample);

        // Hum's own sounds start on the sample the hands were stamped with
        self.own_at = now_sample + @min(hands.stamp, samples_per_step - 1);

        // the call: a ring of light and Hum's own short note, as one cue
        if (pressed & Hands.call != 0 and pressed & Hands.clap == 0) {
            self.calls += 1;
            self.called_at = self.step;
            self.own_now = sound.own_hands;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.home_hz, .strength = callStrength(self.cover), .ring = 0.35 }, .ring_on_the_ground));
            self.own_now = sound.own_world;
        }

        // singing: Hum's one note for as long as R2 is held, and Hum swelling for as long. Beside
        // Drip, it hums with you. While a lock holds, both notes hold by themselves.
        const holding = self.step < self.hold_until;
        if (pressed & Hands.sing != 0 and !holding) {
            self.swell_from = self.home_k;
            self.swell_bars = 0;
            self.swell_steered = false;
            self.swell_leaned = false;
            self.own_now = sound.own_hands;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .hz = self.home_hz, .strength = 1.0, .ring = 0.0 }, .swell));
            self.own_now = sound.own_world;
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
                if (@as(f64, @floatFromInt(self.fromHeardTick(self.own_at))) <= self.widen(@floatFromInt(breath_window * samples_per_step)) and self.breaths < breaths_to_lock) {
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
                // let go on a downbeat: where home stands against where the swell began decides
                // the cadence (SPEC.md 9)
                if (self.locked_at != never and self.nearDownbeat(self.clock)) self.landCadence();
                // let go: Hum's hum ends on the sample it was let go
                self.own_now = sound.own_hands;
                self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = self.home_hz, .strength = 0.0, .ring = 0.0 }, .dims));
                self.own_now = sound.own_world;
                if (self.drip_humming) {
                    self.drip_humming = false;
                    self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
                }
            }
        }
        if (self.hold_until != 0 and self.step == self.hold_until) {
            // the hold ends: both let go, the drop lands on Hum's head, and the page begins to stand
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = self.home_hz, .strength = 0.0, .ring = 0.0 }, .dims));
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
            self.drip_humming = false;
            self.drip_met = true;
            self.stand_from = self.step + 40;
        }
        if (self.singing and self.locked_at != never and self.step >= self.hold_until) self.swellStep(hands);
        if (self.drip != no_thing) self.dripStep();
        if (self.rung_first != no_thing) self.skyStep();
        if (self.clock_part + self.tempo >= 1.0) {
            self.bee.step(self);
            if (self.bee.thing != no_thing) {
                const me = &self.things[self.bee.thing];
                me.ground = self.groundAt(me.x, me.z);
            }
        }
        if (self.pool_count > 0) self.poolStep();
        if (self.knot_count > 0) self.knotStep();
        if (self.in_garden and self.hose_thing != no_thing) self.hoseStep();
        if (self.clock_part + self.tempo >= 1.0) self.looperStep();
        self.dawn = self.dayAt(self.hum_x, self.hum_z);
        if (self.singing) self.hum_light = @max(self.hum_light, 0.8);
        self.hum_light *= 0.94;
        if (self.hum_light < 0.002) self.hum_light = 0.0;

        // rings travel, along the ground and up whatever stands on it; what they pass is lit, and
        // answers as much as its own overtones share with the call
        for (&self.rings) |*ring| {
            if (!ring.live) continue;
            // a ring runs on the world's beat: a quarter as far each step while time is thick
            const reach = ring.age * dt * sound_speed;
            const before = ring.last_reach;
            ring.last_reach = reach;
            ring.age += self.tempo;
            if (reach > self.ring_reach * ring.strength) {
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
                    const up = thing.y + thing.ground - ring.ground;
                    const far = @sqrt(dx * dx + dz * dz + up * up);
                    if (far > before and far <= reach) thing.lit = @max(thing.lit, 0.6);
                }
                continue;
            }
            for (self.things[0..self.thing_count], 0..) |*thing, index| {
                const dx = thing.x - ring.x;
                const dz = thing.z - ring.z;
                const up = thing.y + thing.ground - ring.ground;
                const far = @sqrt(dx * dx + dz * dz + up * up);
                if (far <= before or far > reach) continue;
                thing.lit = 1.0;
                if (!thing.sounds) continue;
                if (index == self.bee.thing) continue;
                if (self.pool_first != no_thing and index >= self.pool_first and index < self.pool_first + self.pool_count) continue;
                if (index == self.drip) {
                    // the second call is always answered: Drip's own ring comes back
                    if (self.calls >= 2 and !self.drip_met) {
                        self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = self.dripHz(), .strength = 0.9, .ring = 0.9 }, .ring_on_the_ground));
                    }
                    continue;
                }
                const rec = sound.recipe(thing.family);
                const kin = sympathy(self.home_hz, thing.hz, rec.mult, rec.gain);
                if (kin < 0.08) continue;
                // how hard the call rings it: less with distance, as sound is. One number, and it
                // is both how loud the thing is and how bright
                const strength = kin * ring.strength / (1.0 + (far / thing.carry) * (far / thing.carry));
                if (strength * answer_level < quietest) continue;
                self.answers += 1;
                self.answering = true;
                self.tell(.{ .thing = @intCast(index) }, cues_mod.Cue.of(.{ .kind = .strike, .family = thing.family, .hz = thing.hz, .strength = strength, .ring = thing.ring }, .glow));
                self.answering = false;
                thing.rung_at = @truncate(self.step);
                self.passOn(@intCast(index), strength, true);
            }
            // a puddle the call reaches stands for a moment in the shape the call's note stands in,
            // from the edge it reaches first, and sings it as it dies away
            for (self.pools[0..self.pool_count]) |*p| {
                const dx = p.x - ring.x;
                const dz = p.z - ring.z;
                const edge = @max(0.0, @sqrt(dx * dx + dz * dz) - p.r);
                if (edge < before or edge > reach) continue;
                self.things[p.thing].lit = 1.0;
                const strength = ring.strength / (1.0 + (edge / 120.0) * (edge / 120.0));
                p.struck(self.home_hz, &call_overtones, strength * 0.8, ring.x, ring.z);
            }
        }

        // things whose kin rang ring in their turn (law 1)
        self.echoStep();

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
        for (&self.sparks) |*spark| {
            if (spark.live and @as(f32, @floatFromInt(self.step - spark.born)) * dt > spark.fades * 3.0) spark.live = false;
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
            if (self.arrivals[i].from != no_thing) self.heard(self.arrivals[i].from, self.arrivals[i].answer);
        }

        self.clock_part += self.tempo;
        while (self.clock_part >= 1.0) {
            self.clock_part -= 1.0;
            self.clock += 1;
        }
        self.step += 1;
        return n;
    }

    /// After a world is opened from a save (keep/save.zig) the sound starts with nothing ringing:
    /// tell again whatever was being held, each with its light, so the voices go on where they
    /// were. Only for a person playing on; a save read back to prove it is whole is left alone.
    pub fn soundAgain(self: *World) void {
        const holding = self.step < self.hold_until;
        if (self.singing or holding) {
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .hz = self.home_hz, .strength = 1.0, .ring = 0.0 }, .swell));
        }
        if (self.drip != no_thing and (self.drip_humming or holding)) {
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = 0.7, .ring = 0.0 }, .swell));
        }
        // standing water sings again at its next turn
        for (self.pools[0..self.pool_count]) |*p| p.sent = .{ 0.0, 0.0 };
    }

    /// Home moves to a lit wedge: Hum's note, and so what everything is to Hum, changes at once
    /// (spec/laws.md, law 2). Only a wedge whose mood is awake can be home.
    pub fn moveHome(self: *World, k: i8) bool {
        if (k < lit_least or k > lit_most) return false;
        if (self.awake & (@as(u8, 1) << @intFromEnum(moodOf(k))) == 0) return false;
        self.home_k = k;
        self.home_hz = wedgeHz(self.day_hz, k);
        return true;
    }

    /// Whether a step is within the window of a downbeat: the first of every four of Drip's ticks.
    pub fn nearDownbeat(self: *const World, step: u64) bool {
        const k = step / tick_every;
        var i: u64 = if (k > 0) k - 1 else 0;
        while (i <= k + 1) : (i += 1) {
            if (i % 4 != 0) continue;
            const at = tickStep(i);
            const apart = if (at > step) at - step else step - at;
            if (@as(f64, @floatFromInt(apart)) <= self.widen(@floatFromInt(downbeat_window))) return true;
        }
        return false;
    }

    /// While R2 is held after the lock: a bar grown at each downbeat, and a nudge of the right stick
    /// near one walks home a wedge to the side it was pushed, if that mood is awake.
    fn swellStep(self: *World, hands: Hands) void {
        const k = self.clock / tick_every;
        if (k % 4 == 0 and tickStep(k) == self.clock and self.downbeat_beat != self.clock) {
            self.downbeat_beat = self.clock;
            self.downbeat_at = self.step;
            if (self.swell_bars < swell_most) self.swell_bars += 1;
            // Gentle leans for you: a swell held a bar without steering, and home drifts beside the
            // nearest grey creature on its amen side (design/the-wheel.md, "Gentle and fierce")
            if (!self.fierce and !self.swell_steered and !self.swell_leaned and self.swell_bars >= 2) {
                if (self.nearestGrey()) |g| {
                    const amen_side: i8 = wedgeOfHz(self.day_hz, self.knots[g].root_hz) + 1;
                    self.swell_leaned = true;
                    if (self.home_k != amen_side and self.moveHome(amen_side)) {
                        self.leans_for_you += 1;
                        self.own_now = sound.own_only;
                        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .hz = self.home_hz, .strength = 1.0, .ring = 0.0 }, .swell));
                        self.own_now = sound.own_world;
                    }
                }
            }
        }
        const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
        if (!self.nudge_out and @abs(rx) >= nudge_least) {
            self.nudge_out = true;
            if (self.nearDownbeat(self.clock)) {
                self.swell_steered = true;
                const from = self.home_k;
                const to: i8 = self.home_k + (if (rx > 0.0) @as(i8, 1) else -1);
                if (self.moveHome(to)) {
                    // walking home the long way: a grey creature whose full close home stood on comes
                    // home in passing as home walks on to the left (design/the-wheel.md, "A pack at dusk")
                    if (to < from) {
                        for (self.knots[0..self.knot_count]) |*kn| {
                            if (kn.home or kn.colour > 0.0 or !self.inReach(kn)) continue;
                            if (@as(i32, from) - @as(i32, wedgeOfHz(self.day_hz, kn.root_hz)) == -1) self.meetDoor(kn, .full_close);
                        }
                    }
                    // the hum moves with home, on this very step
                    self.own_now = sound.own_only;
                    self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .hz = self.home_hz, .strength = 1.0, .ring = 0.0 }, .swell));
                    self.own_now = sound.own_world;
                }
            }
        }
        if (self.nudge_out and @abs(rx) < nudge_back) self.nudge_out = false;
    }

    /// The cadence lands: home's chord rung from Hum, and a ring on the ground on home's note that
    /// everything kin to the new home answers (law 1).
    fn landCadence(self: *World) void {
        const d: i32 = @as(i32, self.home_k) - @as(i32, self.swell_from);
        self.cadence = if (d == -1) .full_close else if (d == 1) .amen else if (d == 0) .turn else .slide;
        self.cadence_at = self.step;
        self.cadences += 1;
        const fullness: f32 = 0.5 + 0.06 * @as(f32, @floatFromInt(self.swell_bars));
        // home's pure triad, sung by Hum and its voices
        const chord = [3]f32{ 1.0, 5.0 / 4.0, 3.0 / 2.0 };
        for (chord, 0..) |ratio, i| {
            const at = Place{ .x = self.hum_x, .y = 1.2 + 0.4 * @as(f32, @floatFromInt(i)), .z = self.hum_z };
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.home_hz * ratio, .strength = fullness * 0.6, .ring = 1.6 }, .glow));
        }
        self.startRing(self.hum_x, self.hum_z, self.home_hz, true, fullness);
        self.swell_bars = 0;
        // each grey creature near meets the door where home stands against its root; on Fierce only
        // the full close is a door, and the rest are plain endings
        for (self.knots[0..self.knot_count]) |*kn| {
            if (kn.home or kn.colour > 0.0 or kn.fate == .turn or !self.inReach(kn)) continue;
            const off: i32 = @as(i32, self.home_k) - @as(i32, wedgeOfHz(self.day_hz, kn.root_hz));
            const door = knots.doorOf(off);
            self.meetDoor(kn, if (self.fierce and door != .full_close) .none else door);
        }
    }

    fn inReach(self: *const World, kn: *const knots.Knot) bool {
        const dx = kn.x - self.hum_x;
        const dz = kn.z - self.hum_z;
        return dx * dx + dz * dz <= knots.home_reach * knots.home_reach;
    }

    /// The hose: its drone heard from where Hum stands; its knot springing open once every knot is
    /// home; the water running to the pool; the figure.
    fn hoseStep(self: *World) void {
        if (!self.hose_open and self.knot_count > 0 and self.knots_home >= self.knot_count) self.openHose();
        if (self.step % 15 == 0) {
            const near = hose.nearest(self.hum_x, self.hum_z);
            const th = &self.things[self.hose_thing];
            th.x = near.p[0];
            th.z = near.p[1];
            th.ground = self.groundAt(th.x, th.z);
            const more = hose_more * @max(0.0, 1.0 - near.d / hose_heard);
            const level = (hose_least + more) * (if (self.hose_open) hose_open_more else 1.0);
            self.tell(.{ .thing = self.hose_thing }, cues_mod.Cue.of(.{ .kind = .tone, .voice = hose_voice, .family = if (self.hose_open) .open_pipe else .stopped_pipe, .hz = if (self.hose_open) hose_open_hz else hose_stopped_hz, .strength = level, .ring = 0.0 }, .glow));
        }
        if (self.water_from != never and self.water_at == never) {
            const ran = @as(f32, @floatFromInt(self.step - self.water_from)) * dt * water_speed;
            if (ran >= land.hose_knot) {
                // it pours into the pool, and the pool rings low
                self.water_at = self.step;
                const m = hose.path[hose.count - 1];
                self.tell(.{ .at = .{ .x = m[0], .y = 0.5, .z = m[1] } }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = garden_hz * 0.5, .strength = 0.6, .ring = 3.5 }, .glow));
            }
        }
        if (self.water_at != never and self.figure_from == never and self.step >= self.water_at + figure_after) self.figure_from = self.step;
    }

    /// Every knot home: the hose springs open where it was knotted, and the water runs.
    fn openHose(self: *World) void {
        self.hose_open = true;
        self.hose_opened_at = self.step;
        self.water_from = self.step;
        const k = hose.knot;
        self.tell(.{ .at = .{ .x = k[0], .y = 1.0, .z = k[1] } }, cues_mod.Cue.of(.{ .kind = .strike, .family = .open_pipe, .hz = hose_open_hz * 2.0, .strength = 0.7, .ring = 2.5 }, .glow));
    }

    /// Whether the figure sits on the pool's edge now.
    pub fn figureNow(self: *const World) bool {
        return self.figure_from != never and self.step >= self.figure_from and self.step < self.figure_from + figure_for;
    }

    /// The nearest grey creature still out in the world, within reach of a cadence.
    fn nearestGrey(self: *const World) ?usize {
        var best: ?usize = null;
        var best_d: f32 = knots.home_reach * knots.home_reach;
        for (self.knots[0..self.knot_count], 0..) |kn, i| {
            if (kn.home or kn.colour > 0.0 or kn.fate == .turn) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            const d = dx * dx + dz * dz;
            if (d <= best_d) {
                best_d = d;
                best = i;
            }
        }
        return best;
    }

    /// A grey creature meets a door (knots.Fate), heard and seen.
    fn meetDoor(self: *World, kn: *knots.Knot, door: knots.Fate) void {
        const bar: u64 = 4 * tick_every;
        self.doors[@intFromEnum(door)] += 1;
        const mood: u8 = @intFromEnum(moodOf(self.home_k));
        switch (door) {
            .none => {
                // still grey, and calmer a while: one soft note from it, and no lunges
                kn.calm_until = self.clock + knots.calm_bars * bar;
                self.tell(.{ .thing = kn.thing[0] }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.root_hz * 2.0, .strength = 0.12, .ring = 0.6 }, .glow));
                return;
            },
            .full_close => {
                // it rings open at home's notes, and whatever has its root where home landed goes
                // grey and leans in turn
                for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.home_hz * (if (s == 0) @as(f32, 2.0) else 3.0), .strength = 0.5, .ring = 2.4 }, .glow));
                for (self.knots[0..self.knot_count]) |*other| {
                    if (other.home or other.colour <= 0.0 or !self.inReach(other)) continue;
                    if (wedgeOfHz(self.day_hz, other.root_hz) == self.home_k) other.colour = 0.0;
                }
            },
            .amen => {
                // it settles: one long soft sigh at its own root, and sleeps
                self.tell(.{ .thing = kn.thing[0] }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.root_hz * 2.0, .strength = 0.25, .ring = 3.0 }, .glow));
            },
            .turn => {
                // for a phrase it is kin: it sings home's notes and fights beside Hum, then comes home
                kn.kin_until = self.clock + knots.kin_bars * bar;
                kn.fate = .turn;
                kn.gift = mood;
                for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.home_hz * (if (s == 0) @as(f32, 2.0) else 2.5), .strength = 0.35, .ring = 1.2 }, .glow));
                return;
            },
            .slide => {
                // home by a half step, quietly: a pure half step under its root, then its root
                self.tell(.{ .thing = kn.thing[0] }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.root_hz * 2.0 * 15.0 / 16.0, .strength = 0.18, .ring = 0.5 }, .glow));
                self.tell(.{ .thing = kn.thing[1] }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.root_hz * 2.0, .strength = 0.2, .ring = 2.0 }, .glow));
            },
        }
        kn.fate = door;
        kn.home = true;
        kn.gift = mood;
        self.knots_home += 1;
    }

    /// The left face: Hum's fork rings at home's note, and every knot within reach is drained by how
    /// its strands meet the strike (knots.zig).
    /// A window of timing as this way of playing has it: wider on Gentle.
    pub fn widen(self: *const World, base: f64) f64 {
        return if (self.fierce) base else base * gentle_widens;
    }

    /// Whether Hum can strike now: standing, in the place. Told to the sound's thread too, so it
    /// never starts a strike the world would not make.
    pub fn canStrike(self: *const World) bool {
        return self.view == .place and self.stand >= 1.0;
    }

    pub const BeatAt = struct {
        /// Where in the world's beat, in its steps; how far from the nearest of Hum's beats; and
        /// the next beat after it.
        pos: f64,
        from_beat: f64,
        next_beat: u64,
    };

    /// Where a moment stamped this many samples into the step falls in the world's beat. Whole
    /// steps of the beat are counted as whole numbers, so a beat is found by a whole remainder and
    /// never a float one (spec/engine.md).
    pub fn beatAt(self: *const World, stamp: u16) BeatAt {
        return beatOf(self.clock, self.clock_part, self.tempo, stamp);
    }

    /// The beat's arithmetic, kept on its own so the sound's thread does exactly the same sum.
    pub fn beatOf(clock: u64, part: f32, tempo: f32, stamp: u16) BeatAt {
        var whole = clock;
        var frac: f64 = @as(f64, part) + @as(f64, tempo) * (@as(f64, @floatFromInt(@min(stamp, samples_per_step - 1))) / @as(f64, @floatFromInt(samples_per_step)));
        while (frac >= 1.0) {
            frac -= 1.0;
            whole += 1;
        }
        const into = whole % tick_every;
        const after: f64 = @as(f64, @floatFromInt(into)) + frac;
        const before: f64 = @as(f64, @floatFromInt(tick_every)) - after;
        return .{
            .pos = @as(f64, @floatFromInt(whole)) + frac,
            .from_beat = @min(after, before),
            .next_beat = whole - into + tick_every,
        };
    }

    /// A placed strike lands in the step its beat falls in, told on that very sample.
    fn placedStrike(self: *World, now_sample: u64) void {
        const ahead = @as(f64, @floatFromInt(self.strike_due)) - @as(f64, @floatFromInt(self.clock)) - @as(f64, self.clock_part);
        if (ahead > @as(f64, self.tempo)) return;
        const into: f64 = if (self.tempo > 0.0) @max(0.0, ahead) / @as(f64, self.tempo) else 0.0;
        const was = self.own_at;
        self.own_at = now_sample + lead + @as(u64, @intFromFloat(into * @as(f64, @floatFromInt(samples_per_step))));
        const due = self.strike_due;
        self.strike_due = never;
        self.strike(@floatFromInt(due), false);
        self.own_at = was;
    }

    /// A strike lands at a moment of the world's beat: timed by the hands, or placed by the game.
    fn strike(self: *World, at: f64, timed: bool) void {
        self.strikes += 1;
        if (timed) self.timed_strikes += 1 else self.placed_strikes += 1;
        const landed: u64 = @intFromFloat(@round(at));
        if (self.bar_strike_n < knots.strikes_in_a_bar) {
            self.bar_strikes[self.bar_strike_n] = @intCast(landed % (4 * tick_every));
            self.bar_strike_n += 1;
        }
        // timed: its note with its octave and a brighter light, which the hands may already have
        // started; placed: its note alone, on the beat
        self.own_now = if (timed) sound.own_strike else sound.own_only;
        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = if (timed) .fork_octave else .fork, .hz = self.home_hz * strike_over, .strength = strike_strength, .ring = strike_ring }, .glow));
        self.own_now = sound.own_world;
        if (timed) self.hum_light = 1.0;
        const more: f32 = if (timed) timed_takes else 1.0;
        const bar: f64 = @floatFromInt(4 * tick_every);
        for (self.knots[0..self.knot_count]) |*kn| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            if (dx * dx + dz * dz > knots.strike_reach * knots.strike_reach) continue;
            const cycle = knots.cycleSteps(bar, self.home_hz, kn.root_hz);
            const take = more * knots.drainAt(kn, @max(0.0, at - @as(f64, @floatFromInt(kn.phase_from))), cycle, self.widen(knots.meet_window)) + (if (self.step < self.pocket_until) knots.pocket_drain else 0.0);
            kn.colour = @max(0.0, kn.colour - take);
            // it rings at its own notes, as hard as the strike met it
            for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.4 + take, .ring = 0.8 }, .glow));
        }
    }

    /// The looper, once for each step of the world's beat. At each downbeat a bar in which the pocket
    /// opened keeps its strikes as a layer, up to four; and every layer's strikes land again where
    /// they fell in the bar, as ghost strikes from beside Hum, a part as hard (SPEC.md 10).
    fn looperStep(self: *World) void {
        const bar: u64 = 4 * tick_every;
        const into: u16 = @intCast(self.clock % bar);
        if (into == 0 and self.clock != self.looped_at) {
            self.looped_at = self.clock;
            if (self.bar_pocketed and self.bar_strike_n > 0) {
                if (self.layer_n == knots.layers_most) self.dropLayer(0); // the oldest goes
                self.layers[self.layer_n] = self.bar_strikes;
                self.layer_strikes[self.layer_n] = self.bar_strike_n;
                self.layer_level[self.layer_n] = 1.0;
                self.layer_n += 1;
            } else if (!self.bar_pocketed) {
                // a bar out of the pocket: every layer lands softer, and the faintest go
                var i: usize = 0;
                while (i < self.layer_n) {
                    self.layer_level[i] *= knots.layer_fades;
                    if (self.layer_level[i] < knots.layer_least) self.dropLayer(i) else i += 1;
                }
            }
            self.bar_strike_n = 0;
            self.bar_pocketed = false;
        }
        for (self.layers[0..self.layer_n], 0..) |layer, li| {
            for (layer[0..self.layer_strikes[li]]) |at| {
                if (at != into) continue;
                self.ghostStrike(li);
            }
        }
    }

    fn dropLayer(self: *World, at: usize) void {
        var i = at;
        while (i + 1 < self.layer_n) : (i += 1) {
            self.layers[i] = self.layers[i + 1];
            self.layer_strikes[i] = self.layer_strikes[i + 1];
            self.layer_level[i] = self.layer_level[i + 1];
        }
        self.layer_n -= 1;
    }

    /// A strike from the afterimage: from beside Hum, at home's note, softer, draining every knot
    /// in reach by a part of what a strike would, and as much less as the layer has faded.
    fn ghostStrike(self: *World, layer: usize) void {
        self.ghost_strikes += 1;
        self.ghost_at = self.clock;
        const side = @as(f32, @floatFromInt(layer + 1)) * 1.3;
        const at = Place{ .x = self.hum_x + @cos(self.look_yaw) * side, .y = 0.6, .z = self.hum_z + @sin(self.look_yaw) * side };
        const level = self.layer_level[layer];
        self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.home_hz * 2.0, .strength = 0.3 * level, .ring = 0.4 }, .glow));
        const bar: f64 = @floatFromInt(4 * tick_every);
        for (self.knots[0..self.knot_count]) |*kn| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            if (dx * dx + dz * dz > knots.strike_reach * knots.strike_reach) continue;
            const cycle = knots.cycleSteps(bar, self.home_hz, kn.root_hz);
            kn.colour = @max(0.0, kn.colour - level * knots.ghost_part * knots.drainAt(kn, @floatFromInt(self.clock - kn.phase_from), cycle, self.widen(knots.meet_window)));
        }
    }

    /// The clap (L1 and R1 together): the layers are spent, each taking a part from every knot
    /// near, and everything near is set to the start of its cycle (spec/laws.md, law 3: "The clap
    /// sets everything in reach to the start of its cycle").
    fn clap(self: *World) void {
        self.claps += 1;
        self.clap_at = self.clock;
        var spent: f32 = 0.0;
        for (self.layer_level[0..self.layer_n]) |level| spent += level * knots.clap_per_layer;
        for (self.knots[0..self.knot_count]) |*kn| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            if (dx * dx + dz * dz > knots.clap_reach * knots.clap_reach) continue;
            kn.phase_from = self.clock;
            kn.pulsed = .{ self.clock, self.clock };
            kn.colour = @max(0.0, kn.colour - spent);
            for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.3 + spent, .ring = 0.6 }, .glow));
        }
        self.layer_n = 0;
        // a call begun just before was the clap's first half: its ring is taken back, and the sound
        // chokes it (sound.own_clap)
        if (self.called_at != never and self.step - self.called_at <= clap_takes_back) {
            for (&self.rings) |*r| {
                if (r.live and r.own and r.born == self.called_at) r.live = false;
            }
            self.calls_taken_back += 1;
            self.called_at = never;
        }
        self.own_now = sound.own_clap;
        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = self.home_hz * clap_over, .strength = clap_strength, .ring = clap_ring }, .glow));
        self.own_now = sound.own_world;
    }

    /// The right face: Hum steps quickly aside; on the beat a lunge lands on, the pocket opens: time
    /// thickens, and the next strikes take more (SPEC.md 10).
    fn dodge(self: *World) void {
        self.dodged_at = self.clock;
        const side: f32 = if (self.strikes % 2 == 0) 1.0 else -1.0;
        self.hum_x += @cos(self.look_yaw) * 2.2 * side;
        self.hum_z += @sin(self.look_yaw) * 2.2 * side;
        self.hum_ground = self.groundAt(self.hum_x, self.hum_z);
        for (self.knots[0..self.knot_count]) |kn| {
            if (kn.lunge_from == knots.never_lunged) continue;
            const arrives = kn.lunge_from + knots.lunge_steps / 2;
            const apart = if (arrives > self.clock) arrives - self.clock else self.clock - arrives;
            if (@as(f64, @floatFromInt(apart)) > self.widen(@floatFromInt(knots.dodge_window))) continue;
            self.pocket_until = self.step + knots.pocket_steps;
            self.pockets += 1;
            self.bar_pocketed = true;
            // the pocket is heard: Hum's own note, soft and long, and Hum glows with it. Not a ring on
            // the ground: a dodge is not a call, and the field does not answer it
            self.own_now = sound.own_only;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.home_hz, .strength = 0.3, .ring = 1.5 }, .glow));
            self.own_now = sound.own_world;
            break;
        }
    }

    /// A lunge arrives. Dodged near its arrival, it misses; otherwise it lands: Hum is knocked back
    /// and dimmed, and the knot's strands ring hard. Nothing dies.
    fn lungeLands(self: *World, kn: *knots.Knot) void {
        if (self.dodged_at != never) {
            const apart = if (self.dodged_at > self.clock) self.dodged_at - self.clock else self.clock - self.dodged_at;
            if (@as(f64, @floatFromInt(apart)) <= self.widen(@floatFromInt(knots.dodge_window))) return;
        }
        const dx = self.hum_x - kn.x;
        const dz = self.hum_z - kn.z;
        const far = @max(@sqrt(dx * dx + dz * dz), 0.1);
        if (far > knots.keeps_off) return;
        self.hum_x += dx / far * knots.knock_back;
        self.hum_z += dz / far * knots.knock_back;
        self.hum_ground = self.groundAt(self.hum_x, self.hum_z);
        self.hum_light = 0.0;
        self.knocked += 1;
        for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.6, .ring = 0.4 }, .glow));
    }

    /// Knots near Hum come and keep a circle round it, and each strand pulses on its own count of
    /// the knot's cycle, which is a bar stretched by home's pitch against the knot's root. Their
    /// pulses are heard and seen once for each step of the world's beat.
    fn knotStep(self: *World) void {
        const bar: f64 = @floatFromInt(4 * tick_every);
        const beat_moves = self.clock_part + self.tempo >= 1.0;
        for (self.knots[0..self.knot_count], 0..) |*kn, ki| {
            if (kn.home) continue;
            // the turn's phrase is over: it comes home
            if (kn.fate == .turn and self.clock >= kn.kin_until) {
                kn.home = true;
                self.knots_home += 1;
                continue;
            }
            const kin = kn.fate == .turn;
            const dx = self.hum_x - kn.x;
            const dz = self.hum_z - kn.z;
            const far = @sqrt(dx * dx + dz * dz);
            if (far > knots.notices_within) continue;
            // to its place on a circle round Hum, at the world's pace
            const tx = self.hum_x + knots.keeps_off * @cos(kn.around);
            const tz = self.hum_z + knots.keeps_off * @sin(kn.around);
            const gx = tx - kn.x;
            const gz = tz - kn.z;
            const gap = @sqrt(gx * gx + gz * gz);
            const stride = knots.speed * dt * self.tempo;
            if (gap > stride) {
                kn.x += gx / gap * stride;
                kn.z += gz / gap * stride;
            }
            kn.around += 0.2 * dt * self.tempo;
            // a lunge: begun so it arrives on the knot's one, closing most of the way to Hum
            const cycle_now = knots.cycleSteps(@floatFromInt(4 * tick_every), self.home_hz, kn.root_hz);
            if (kn.lunge_from == knots.never_lunged and kn.colour > 0.0 and !kin and self.clock >= kn.calm_until and far < knots.keeps_off + 2.0) {
                const ahead = self.clock - kn.phase_from + knots.lunge_steps / 2;
                if (knots.nextOne(ahead, cycle_now) == ahead) kn.lunge_from = self.clock;
            }
            if (kn.lunge_from != knots.never_lunged) {
                const into = self.clock - kn.lunge_from;
                if (into >= knots.lunge_steps) {
                    kn.lunge_from = knots.never_lunged;
                } else {
                    const reach = knots.lunge_reach * @sin(std.math.pi * @as(f32, @floatFromInt(into)) / @as(f32, @floatFromInt(knots.lunge_steps)));
                    kn.x += (self.hum_x - kn.x) * reach * 0.25;
                    kn.z += (self.hum_z - kn.z) * reach * 0.25;
                    if (into == knots.lunge_steps / 2 and beat_moves) self.lungeLands(kn);
                }
            }
            const kn_ground = self.groundAt(kn.x, kn.z);
            for (kn.thing) |th| {
                self.things[th].x = kn.x;
                self.things[th].z = kn.z;
                self.things[th].ground = kn_ground;
            }
            if (!beat_moves) continue;
            // kin dances on Hum's one, a bar to its cycle, and each pulse lands on a creature still
            // coloured near it
            const cycle = if (kin) bar else knots.cycleSteps(bar, self.home_hz, kn.root_hz);
            for (kn.strands, 0..) |st, s| {
                if (!knots.pulsesAt(self.clock - kn.phase_from, cycle, st.over)) continue;
                kn.pulsed[s] = self.clock;
                const hz = if (kin) self.home_hz * (if (s == 0) @as(f32, 2.0) else 2.5) else st.hz;
                if (far < 80.0) self.tell(.{ .thing = kn.thing[s] }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = hz, .strength = 0.08 + 0.17 * (if (kin) 1.0 else kn.colour), .ring = 0.3 }, .glow));
                if (kin) {
                    for (self.knots[0..self.knot_count], 0..) |*other, oi| {
                        if (oi == ki or other.home or other.colour <= 0.0 or other.fate == .turn) continue;
                        const ox = other.x - kn.x;
                        const oz = other.z - kn.z;
                        if (ox * ox + oz * oz > knots.strike_reach * knots.strike_reach) continue;
                        other.colour = @max(0.0, other.colour - knots.kin_part * knots.drain_alone);
                    }
                }
            }
        }
    }

    /// Whether a thing rings its kin and is rung by them. The sky's rungs, the bee, Drip and the
    /// puddles keep rules of their own.
    fn cascades(self: *const World, i: usize) bool {
        const t = self.things[i];
        if (!t.sounds or t.family == .tone) return false;
        if (self.rung_first != no_thing and i >= self.rung_first and i < self.rung_first + rungs) return false;
        if (self.pool_first != no_thing and i >= self.pool_first and i < self.pool_first + self.pool_count) return false;
        if (i == self.bee.thing or i == self.drip) return false;
        return true;
    }

    /// Each sounding thing's nearest kin that share enough, strongest and nearest first. A land
    /// has few notes, so how much two notes share is worked out once for each pair of them.
    pub fn findKin(self: *World) void {
        const most_notes = 96;
        var notes: [most_notes]struct { family: sound.Family, hz: f32 } = undefined;
        var note_n: usize = 0;
        var note_of: [max_things]u8 = undefined;
        var shared: [most_notes][most_notes]f32 = @splat(@splat(-1.0));
        for (0..self.thing_count) |i| {
            const th = self.things[i];
            var found: ?usize = null;
            for (notes[0..note_n], 0..) |n, k| {
                if (n.family == th.family and n.hz == th.hz) {
                    found = k;
                    break;
                }
            }
            if (found == null and note_n < most_notes) {
                notes[note_n] = .{ .family = th.family, .hz = th.hz };
                found = note_n;
                note_n += 1;
            }
            note_of[i] = if (found) |k| @intCast(k) else 255;
        }
        for (0..self.thing_count) |i| {
            self.kin[i] = @splat(.{});
            if (!self.cascades(i)) continue;
            const a = self.things[i];
            var best: [kin_most]f32 = @splat(0.0);
            for (0..self.thing_count) |j| {
                if (j == i) continue;
                const b = self.things[j];
                const dx = b.x - a.x;
                const dy = b.y - a.y;
                const dz = b.z - a.z;
                const d2 = dx * dx + dy * dy + dz * dz;
                if (d2 > kin_within * kin_within) continue;
                if (!self.cascades(j)) continue;
                const na = note_of[i];
                const nb = note_of[j];
                var k: f32 = undefined;
                if (na != 255 and nb != 255) {
                    if (shared[na][nb] < 0.0) shared[na][nb] = kinOf(a, b);
                    k = shared[na][nb];
                } else k = kinOf(a, b);
                if (k < kin_least) continue;
                // stronger and nearer first
                const worth = k / (1.0 + d2 / (20.0 * 20.0));
                var slot: ?usize = null;
                for (best, 0..) |v, s| {
                    if (worth > v and (slot == null or v < best[slot.?])) slot = s;
                }
                if (slot) |s| {
                    best[s] = worth;
                    self.kin[i][s] = .{ .index = @intCast(j), .share = @intFromFloat(k * 65535.0) };
                }
            }
        }
    }

    /// A thing has rung this hard: its kin ring in their turn when its sound reaches them, more
    /// faintly by how much they share and how far it has come.
    pub fn passOn(self: *World, from: u16, strength: f32, answer: bool) void {
        if (strength < cascade_floor) return;
        const a = self.things[from];
        for (self.kin[from]) |k| {
            if (k.share == 0) continue;
            const b = self.things[k.index];
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            const dz = b.z - a.z;
            const far = @sqrt(dx * dx + dy * dy + dz * dz);
            const kin_share = @as(f32, @floatFromInt(k.share)) / 65535.0;
            const s = strength * kin_share * cascade_keeps / (1.0 + (far / a.carry) * (far / a.carry));
            if (s * answer_level < quietest) continue;
            const due = self.step + 1 + @as(u64, @intFromFloat(far / sound_speed * @as(f32, steps_per_second)));
            // one waiting at a time for each thing: the stronger
            var free: ?usize = null;
            var already = false;
            for (&self.echoes, 0..) |*e, i| {
                if (e.live and e.thing == k.index) {
                    already = true;
                    if (s > e.strength) {
                        e.strength = s;
                        e.due = @min(e.due, due);
                        e.answer = e.answer or answer;
                    }
                    break;
                }
                if (!e.live and free == null) free = i;
            }
            if (already) continue;
            if (free) |i| self.echoes[i] = .{ .thing = k.index, .due = due, .strength = s, .answer = answer, .live = true };
        }
    }

    /// Ring whatever is due, unless it rang a moment ago; each passes it on in turn.
    fn echoStep(self: *World) void {
        for (&self.echoes) |*e| {
            if (!e.live or e.due > self.step) continue;
            e.live = false;
            const thing = &self.things[e.thing];
            const now: u32 = @truncate(self.step);
            if (now -% thing.rung_at < rests_for and thing.rung_at != 0) continue;
            thing.rung_at = now;
            self.echoed += 1;
            self.answering = e.answer;
            self.tell(.{ .thing = e.thing }, cues_mod.Cue.of(.{ .kind = .strike, .family = thing.family, .hz = thing.hz, .strength = e.strength, .ring = thing.ring }, .glow));
            self.answering = false;
            self.passOn(e.thing, e.strength, e.answer);
        }
    }

    /// How many samples from `sample` to the nearest of Drip's ticks as Hum hears it: told on its
    /// step, a lead later, and late by the way from Drip to Hum. A breath is judged against what
    /// is heard, to the sample.
    pub fn fromHeardTick(self: *const World, sample: u64) u64 {
        var delay: u64 = lead;
        if (self.drip != no_thing) {
            const d = self.things[self.drip];
            const dx = d.x - self.hum_x;
            const dz = d.z - self.hum_z;
            const up = d.y + self.groundAt(d.x, d.z) - self.hum_ground;
            delay += @intFromFloat(@sqrt(dx * dx + dz * dz + up * up) / sound_speed * sound.rate);
        }
        const step = if (sample > delay) (sample - delay) / samples_per_step else 0;
        const k = step / tick_every;
        var best: u64 = never;
        var i: u64 = if (k > 0) k - 1 else 0;
        while (i <= k + 1) : (i += 1) {
            const heard_at = tickStep(i) * samples_per_step + delay;
            best = @min(best, if (heard_at > sample) heard_at - sample else sample - heard_at);
        }
        return best;
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

    /// The puddles (pools.zig): hummed at, whichever of their shapes has a note among Hum's
    /// overtones builds while the note is held (law 7) and dies away when it stops. Standing, a
    /// shape sings its note from the water (law 4), and throws the pollen onto its still lines.
    fn poolStep(self: *World) void {
        const note: f32 = if (self.singing) self.home_hz else 0.0;
        for (self.pools[0..self.pool_count], 0..) |*p, pi| {
            p.drive(note, self.hum_x, self.hum_z, self.tempo);
            p.stepMotes(dt * self.tempo, self.hum_x, self.hum_z);
            for (&p.figs, 0..) |*f, k| {
                const was = p.sent[k];
                const due = (self.step % 6 == 0 and @abs(f.loud - was) > 0.01) or (f.loud == 0.0 and was > 0.0);
                if (!due) continue;
                p.sent[k] = f.loud;
                // its end is told as the water settling: a light going down
                const shape: cues_mod.Light.Shape = if (f.loud == 0.0) .dims else .glow;
                self.tell(.{ .thing = p.thing }, cues_mod.Cue.of(.{ .kind = .tone, .voice = @intCast(pi * 2 + k), .hz = f.hz, .strength = pool_voice * f.loud, .ring = 1.0 / pools.build * dt }, shape));
            }
        }
    }

    /// Hum on the water (law 4). Standing water holds Hum on its still lines: walking along them,
    /// or down off a belly, is free; walking up into a belly is turned along the line, and a belly
    /// throws Hum back toward the line, harder the louder it is. Still water gives no grip: a step
    /// on it is a fifth of one, and it floats Hum back to the nearest shore.
    /// Every thing's ground, worked out afresh: when a scene is set up.
    pub fn settleGrounds(self: *World) void {
        for (self.things[0..self.thing_count]) |*th| th.ground = self.groundAt(th.x, th.z);
    }

    /// Whether every thing's kept ground is the ground under it now.
    pub fn groundsTrue(self: *const World) bool {
        if (self.hum_ground != self.groundAt(self.hum_x, self.hum_z)) return false;
        for (self.things[0..self.thing_count]) |th| {
            if (th.ground != self.groundAt(th.x, th.z)) return false;
        }
        for (self.rings) |r| {
            if (r.live and r.ground != self.groundAt(r.x, r.z)) return false;
        }
        return true;
    }

    /// The ground's height at a place, in the Garden; nought in a world made for a test.
    pub fn groundAt(self: *const World, x: f32, z: f32) f32 {
        return if (self.in_garden) ground.heightAt(x, z) else 0.0;
    }

    /// The Mirror Pool is still and deep: Hum stops at its edge, and a step that would go in slides
    /// along the shore instead.
    fn atShore(self: *World, go_x: *f32, go_z: *f32) void {
        if (!self.in_garden) return;
        const px = self.hum_x + go_x.* - land.pool[0];
        const pz = self.hum_z + go_z.* - land.pool[1];
        const edge = land.pool[2];
        const r2 = px * px + pz * pz;
        if (r2 >= edge * edge) return;
        const r = @max(@sqrt(r2), 0.01);
        const nx = px / r;
        const nz = pz / r;
        const inward = go_x.* * nx + go_z.* * nz;
        const v_in = self.hum_vx * nx + self.hum_vz * nz;
        if (v_in < 0.0) {
            self.hum_vx -= v_in * nx;
            self.hum_vz -= v_in * nz;
        }
        if (inward < 0.0) {
            go_x.* -= inward * nx;
            go_z.* -= inward * nz;
        }
    }

    /// An aster's stalk is solid: a step into it goes round it instead, and a step that comes at it
    /// fast enough brushes it, and it rings.
    fn atStalks(self: *World, go_x: *f32, go_z: *f32) void {
        const reach = stalk_foot + hum_body;
        var touched: u16 = no_tower;
        defer self.touching = touched;
        for (self.towers[0..self.tower_count], 0..) |tw, t| {
            const px = self.hum_x + go_x.* - tw.x;
            const pz = self.hum_z + go_z.* - tw.z;
            const d2 = px * px + pz * pz;
            if (d2 >= reach * reach) continue;
            const d = @max(@sqrt(d2), 0.01);
            const nx = px / d;
            const nz = pz / d;
            // where the step would have gone, moved out to the stalk's side: it slides round
            go_x.* = tw.x + nx * reach - self.hum_x;
            go_z.* = tw.z + nz * reach - self.hum_z;
            touched = @intCast(t);
            const v_in = self.hum_vx * nx + self.hum_vz * nz;
            if (v_in < 0.0) {
                self.hum_vx -= v_in * nx;
                self.hum_vz -= v_in * nz;
                if (-v_in > bump_least and self.touching != t) self.brushStalk(@intCast(t), -v_in);
            }
        }
    }

    /// Brushing a stalk rings its bells (spec/shape.md): a knock where Hum touched it, the stalk lit
    /// from its foot up, and every bell on it struck softly, each heard when its sound has come down
    /// to Hum. Harder the faster Hum came.
    fn brushStalk(self: *World, t: u16, speed: f32) void {
        self.bumps += 1;
        self.bumped_at = self.step;
        self.bumped_tower = t;
        const tw = self.towers[t];
        const hard = std.math.clamp((speed - bump_least) / (run_speed - bump_least), 0.0, 1.0);
        const strength = brush_rings * (0.25 + 0.75 * hard);
        var bells: u32 = 0;
        var lowest: f32 = 0.0;
        for (self.things[tw.first .. tw.first + tw.count]) |th| {
            if (!th.sounds) continue;
            bells += 1;
            if (lowest == 0.0 or th.hz < lowest) lowest = th.hz;
        }
        // a stalk's many bells share one brush: together as loud as a few
        const each = strength * 2.0 / @sqrt(@as(f32, @floatFromInt(@max(bells, 4))));
        var part: u32 = 0;
        for (tw.first..tw.first + tw.count) |i| {
            const th = &self.things[i];
            if (!th.sounds) {
                // the shake runs up it: the foot brightest
                th.lit = @max(th.lit, strength * (1.0 - 0.06 * @as(f32, @floatFromInt(part))));
                part += 1;
                continue;
            }
            self.tell(.{ .thing = @intCast(i) }, cues_mod.Cue.of(.{ .kind = .strike, .family = th.family, .hz = th.hz, .strength = each, .ring = th.ring }, .glow));
            th.rung_at = @truncate(self.step);
        }
        // the knock, where Hum touched it: the aster's lowest note, by octaves into what the
        // speaker can say (300 to 600 Hz), short and wooden
        if (lowest > 0.0) {
            var knock = lowest;
            while (knock > 600.0) knock *= 0.5;
            while (knock < 300.0) knock *= 2.0;
            const at = Place{ .x = self.hum_x, .y = 0.5, .z = self.hum_z };
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = knock, .strength = strength * 0.6, .ring = 0.25 }, .glow));
        }
    }

    /// The bowl's rim is a wall of brick, the raised beds behind it: Hum stops at its foot, and a step
    /// that would go through slides along it.
    fn atRim(self: *World, go_x: *f32, go_z: *f32) void {
        if (!self.in_garden) return;
        const px = self.hum_x + go_x.* - land.rim[0];
        const pz = self.hum_z + go_z.* - land.rim[1];
        const edge = land.rim[2] - 1.0;
        const r2 = px * px + pz * pz;
        if (r2 <= edge * edge) return;
        const r = @sqrt(r2);
        const nx = px / r;
        const nz = pz / r;
        const outward = go_x.* * nx + go_z.* * nz;
        const v_out = self.hum_vx * nx + self.hum_vz * nz;
        if (v_out > 0.0) {
            self.hum_vx -= v_out * nx;
            self.hum_vz -= v_out * nz;
        }
        if (outward > 0.0) {
            go_x.* -= outward * nx;
            go_z.* -= outward * nz;
        }
    }

    fn onWater(self: *World, go_x: *f32, go_z: *f32) void {
        const to_x = self.hum_x + go_x.*;
        const to_z = self.hum_z + go_z.*;
        for (self.pools[0..self.pool_count]) |*p| {
            const on = p.holds(self.hum_x, self.hum_z);
            if (!on and !p.holds(to_x, to_z)) continue;
            if (!p.standing()) {
                if (!on) continue;
                const dx = self.hum_x - p.x;
                const dz = self.hum_z - p.z;
                const far = @max(@sqrt(dx * dx + dz * dz), 0.01);
                go_x.* = go_x.* * (pools.paddle / run_speed) + dx / far * pools.float_speed * dt;
                go_z.* = go_z.* * (pools.paddle / run_speed) + dz / far * pools.float_speed * dt;
                continue;
            }
            const there = p.amp(to_x, to_z);
            if (there > pools.hold_band) {
                if (!on) {
                    // the water heaves there: it won't take a step
                    go_x.* = 0.0;
                    go_z.* = 0.0;
                    self.hum_vx = 0.0;
                    self.hum_vz = 0.0;
                    continue;
                }
                const s = p.ampSlope(self.hum_x, self.hum_z);
                const slope = @sqrt(s[1] * s[1] + s[2] * s[2]);
                if (there > s[0] and slope > 1e-6) {
                    const nx = s[1] / slope;
                    const nz = s[2] / slope;
                    const up = go_x.* * nx + go_z.* * nz;
                    if (up > 0.0) {
                        go_x.* -= up * nx;
                        go_z.* -= up * nz;
                    }
                    const v_up = self.hum_vx * nx + self.hum_vz * nz;
                    if (v_up > 0.0) {
                        self.hum_vx -= v_up * nx;
                        self.hum_vz -= v_up * nz;
                    }
                }
            }
            if (on) {
                const t_ = p.throw(self.hum_x, self.hum_z, dt);
                go_x.* += t_[0];
                go_z.* += t_[1];
            }
        }
    }

    /// Stepping on and stepping off: a crossing is coming off well across from where you came on.
    fn crossings(self: *World) void {
        var on: u8 = 0;
        for (self.pools[0..self.pool_count], 0..) |*p, i| {
            if (p.holds(self.hum_x, self.hum_z)) on = @intCast(i + 1);
        }
        if (on != 0 and self.on_pool == 0) {
            self.pool_in_x = self.hum_x;
            self.pool_in_z = self.hum_z;
        }
        if (on == 0 and self.on_pool != 0) {
            const p = self.pools[self.on_pool - 1];
            const dx = self.hum_x - self.pool_in_x;
            const dz = self.hum_z - self.pool_in_z;
            if (dx * dx + dz * dz > (1.5 * p.r) * (1.5 * p.r)) {
                self.crossed += 1;
                self.seen.meet(.garden_w04, self.step);
            }
        }
        self.on_pool = on;
    }

    /// What the ground does under Hum's feet as it walks (spec/shape.md, the Garden). Lawn bends
    /// away and springs back in its wake, shedding dew that lands behind it: your path is heard
    /// just after you. A fallen leaf is a bar with its own note, and rings when it is stepped on.
    fn underfoot(self: *World, moved: f32) void {
        if (ground.wet(self.hum_x, self.hum_z)) return;
        self.walked +%= 1;
        const before = self.stride;
        self.stride += moved;
        switch (self.cover) {
            .lawn => if (@floor(self.stride / dew_every) != @floor(before / dew_every)) {
                const fx = @sin(self.hum_face);
                const fz = -@cos(self.hum_face);
                const at = Place{ .x = self.hum_x - fx * 4.0, .y = 0.1, .z = self.hum_z - fz * 4.0 };
                const which = ground.hash32(@intFromFloat(@floor(at.x)), @intFromFloat(@floor(at.z)), 11) % 5;
                self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = garden_hz * 4.0 * ground.five[which], .strength = 0.05, .ring = 0.25 }, .glow));
            },
            .leaves => if (@floor(self.stride / leaf_every) != @floor(before / leaf_every)) {
                const at = Place{ .x = self.hum_x, .y = 0.2, .z = self.hum_z };
                const note = ground.leafNote(self.hum_x, self.hum_z);
                self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = garden_hz * ground.five[note], .strength = 0.3, .ring = 0.7 }, .glow));
            },
            else => {},
        }
    }

    /// Drip keeps its time, turns the figure, and once it has landed rides on Hum's head.
    fn dripStep(self: *World) void {
        const d = &self.things[self.drip];
        if (self.drip_met) {
            d.x = self.hum_x;
            d.z = self.hum_z;
            d.y = 1.25;
            d.ground = self.hum_ground;
        }
        const dx = d.x - self.hum_x;
        const dz = d.z - self.hum_z;
        const far = @sqrt(dx * dx + dz * dz);
        // its tick: a plink and a flash, softer and dimmer the farther off it is
        if (self.ticked_at != self.clock and fromTick(self.clock) == 0 and untilTick(self.clock) == 0) {
            self.ticked_at = self.clock;
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = self.dripHz() * 2.0, .strength = 0.55, .ring = 0.16 }, .glow));
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
    /// R1 held, once the place has stood up, opens the wheel: the right stick points at a wedge, and
    /// letting go puts home there if its mood is awake (SPEC.md 9). The call went out on the press.
    fn wheelStep(self: *World, hands: Hands) void {
        const stood = self.stand_from != never and self.step >= self.stand_from + 60 and self.locked_at != never and self.step >= self.hold_until;
        if (!self.wheel_open) {
            if (stood and self.call_held >= wheel_after and !self.singing) {
                self.wheel_open = true;
                self.wheel_opens += 1;
                self.wheel_point = null;
            }
            return;
        }
        if (hands.held(Hands.call)) {
            const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
            const ry = @as(f32, @floatFromInt(hands.ry)) * (1.0 / 127.0);
            if (rx * rx + ry * ry >= wheel_point_least * wheel_point_least) {
                self.wheel_point = wedgeAt(rx, ry);
            }
            return;
        }
        // let go: home goes where the stick pointed, if that mood is awake
        if (self.wheel_point) |k| _ = self.moveHome(k);
        self.wheel_open = false;
        self.wheel_point = null;
    }

    fn look(self: *World, hands: Hands) void {
        const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
        const ry = @as(f32, @floatFromInt(hands.ry)) * (1.0 / 127.0);
        // while the wheel is open the right stick points at wedges, and the view stays
        if (!self.wheel_open) {
            if (@abs(rx) > 0.15) self.look_yaw += rx * 2.2 * dt;
            if (@abs(ry) > 0.15) self.look_tilt = std.math.clamp(self.look_tilt - ry * 1.4 * dt, -0.35, 0.9);
        }
        self.looked_ago = if (@abs(rx) > 0.15 or @abs(ry) > 0.15) 0 else self.looked_ago +| 1;
        // once the right stick has rested, the view swings in behind where Hum is going, faster
        // the faster it goes, so one thumb steers (SPEC.md 8, the thumb audit)
        const going = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
        if (!self.wheel_open and self.looked_ago > follow_after and going > 0.5 and self.lean < 0.01 and self.water_view < 0.01) {
            var gap = std.math.atan2(self.hum_vx, -self.hum_vz) - self.look_yaw;
            while (gap > std.math.pi) gap -= 2.0 * std.math.pi;
            while (gap < -std.math.pi) gap += 2.0 * std.math.pi;
            if (@abs(gap) < follow_within) self.look_yaw += gap * follow_rate * dt * @min(going / run_speed, 1.0);
        }

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
        // standing still on the shore of a standing pool, the view rises over the water to see its
        // figure whole; a step, or the water stilling, brings it down
        var over_pool: f32 = 0.0;
        for (self.pools[0..self.pool_count], 0..) |*p, i| {
            const dx = self.hum_x - p.x;
            const dz = self.hum_z - p.z;
            const far = @sqrt(dx * dx + dz * dz);
            if (self.still >= 45 and far < p.r + 25.0 and !p.holds(self.hum_x, self.hum_z) and p.loud() > 0.3) {
                over_pool = 1.0;
                self.pool_seen = @intCast(i);
            }
        }
        self.wheel_view += ((if (self.wheel_open) @as(f32, 1.0) else 0.0) - self.wheel_view) * 0.08;
        if (self.wheel_view < 0.0005) self.wheel_view = 0.0;
        self.pool_view += (over_pool - self.pool_view) * 0.012;
        if (self.pool_view < 0.0005) self.pool_view = 0.0;
        // out on standing water the view lifts behind Hum and looks down, so the line ahead and
        // the water heaving either side of it are both in sight
        const on_standing = self.on_pool != 0 and self.pools[self.on_pool - 1].standing();
        self.water_view += ((if (on_standing) @as(f32, 1.0) else 0.0) - self.water_view) * 0.02;
        if (self.water_view < 0.0005) self.water_view = 0.0;
        const leaning = self.still >= 30 and self.near_tower != no_tower and self.near_far < lean_within and self.stand > 0.98 and over_pool == 0.0;
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
                const reach = ring.age * dt * sound_speed;
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
        const wv = self.water_view * self.water_view * (3.0 - 2.0 * self.water_view);
        const run = std.math.clamp(@sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz) / run_speed, 0.0, 1.0);
        const back = cam_back + self.lean * (lean_back - cam_back) + wv * (water_back - cam_back) + run * run_back;
        const up = cam_up + self.lean * (lean_up - cam_up) + wv * (water_up - cam_up) + run * run_up;
        var eye = [3]f32{ self.hum_x - fx * back, up, self.hum_z - fz * back };
        const pitch = std.math.clamp(walk_pitch + self.look_tilt - wv * water_down, -0.35 - wv * water_down, 1.2);
        const walking = [3]f32{ fx * @cos(pitch), @sin(pitch), fz * @cos(pitch) };
        var dir = walking;
        var fov = place_fov + run * run_wider;
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
        if (self.wheel_view > 0.0) {
            // the wheel open: the view rises behind Hum and looks down on it, the wheel spread on
            // the ground round it
            const k = self.wheel_view * self.wheel_view * (3.0 - 2.0 * self.wheel_view);
            const high = [3]f32{ self.hum_x - fx * wheel_back, wheel_up, self.hum_z - fz * wheel_back };
            const hx = self.hum_x - high[0];
            const hy = -high[1];
            const hz = self.hum_z - high[2];
            const hl = @sqrt(hx * hx + hy * hy + hz * hz);
            const dl = @sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
            const down = [3]f32{ hx / hl, hy / hl, hz / hl };
            for (0..3) |i| {
                eye[i] += (high[i] - eye[i]) * k;
                dir[i] = dir[i] / dl + (down[i] - dir[i] / dl) * k;
            }
        }
        if (self.pool_view > 0.0 and self.pool_seen < self.pool_count) {
            // above the shore behind Hum, looking down across the water at its middle
            const p = &self.pools[self.pool_seen];
            const k = self.pool_view * self.pool_view * (3.0 - 2.0 * self.pool_view);
            const ax = self.hum_x - p.x;
            const az = self.hum_z - p.z;
            const away = @max(@sqrt(ax * ax + az * az), 1.0);
            const high = [3]f32{ p.x + ax / away * p.r * 1.7, p.r * 1.1, p.z + az / away * p.r * 1.7 };
            const hx = p.x - high[0];
            const hy = -high[1];
            const hz = p.z - high[2];
            const hl = @sqrt(hx * hx + hy * hy + hz * hz);
            const dl = @sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
            const down = [3]f32{ hx / hl, hy / hl, hz / hl };
            for (0..3) |i| {
                eye[i] += (high[i] - eye[i]) * k;
                dir[i] = dir[i] / dl + (down[i] - dir[i] / dl) * k;
            }
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
        // the place stands on the ground: the eye rides with Hum's, as far as the place stands up
        eye[1] += self.hum_ground * s;
        at[1] += self.hum_ground * s;
        return .{ .eye = eye, .at = at, .fov = fov, .stand = s };
    }

    fn atTallFoot(self: *const World) bool {
        if (self.near_tower == no_tower) return false;
        return self.near_far <= at_foot and self.towers[self.near_tower].tall >= 90.0;
    }

    /// An answer has reached Hum's ears: the moments that are made of being answered.
    fn heard(self: *World, from: u32, answer: bool) void {
        if (self.rung_first != no_thing and from >= self.rung_first and from < self.rung_first + rungs) {
            const k = from - self.rung_first + 1;
            self.rung_heard = @max(self.rung_heard, k);
            if (k == 6) self.seen.meet(.sky_dawn, self.step);
            return;
        }
        if (from == self.drip) return;
        if (from == self.bee.thing) {
            const b = self.things[from];
            const dx = b.x - self.hum_x;
            const dz = b.z - self.hum_z;
            if (dx * dx + dz * dz < 60.0 * 60.0) self.seen.meet(.sky_bee, self.step);
            return;
        }
        // where there is no Drip to answer, any answer is being answered
        // the moments made of being answered are only met by answers to Hum's own call
        if (!answer) return;
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
        mixIn(&h, self.walked);
        mixIn(&h, self.bee.visits);
        for (self.pools[0..self.pool_count]) |*p| {
            for (p.figs) |f| {
                mixIn(&h, @as(u32, @bitCast(f.loud)));
                mixIn(&h, f.mode);
            }
            for (0..p.motes) |i| {
                mixIn(&h, @as(u32, @bitCast(p.mote_x[i])));
                mixIn(&h, @as(u32, @bitCast(p.mote_z[i])));
            }
        }
        mixIn(&h, self.crossed);
        mixIn(&h, self.echoed);
        mixIn(&h, @as(u32, @bitCast(@as(i32, self.home_k))));
        mixIn(&h, self.wheel_opens);
        mixIn(&h, self.cadences);
        mixIn(&h, self.knots_home);
        mixIn(&h, self.strikes);
        mixIn(&h, self.pockets);
        mixIn(&h, self.ghost_strikes);
        mixIn(&h, self.claps);
        mixIn(&h, self.calls_taken_back);
        mixIn(&h, self.timed_strikes);
        mixIn(&h, self.leans_for_you);
        mixIn(&h, @intFromBool(self.hose_open));
        mixIn(&h, @truncate(self.water_at));
        for (self.doors) |d| mixIn(&h, d);
        mixIn(&h, self.placed_strikes);
        mixIn(&h, self.knocked);
        for (self.knots[0..self.knot_count]) |kn| mixIn(&h, @as(u32, @bitCast(kn.colour)));
        mixIn(&h, self.swell_bars);
        mixIn(&h, @truncate(self.clock));
        if (self.bee.thing != no_thing) {
            mixIn(&h, @as(u32, @bitCast(self.things[self.bee.thing].x)));
            mixIn(&h, @as(u32, @bitCast(self.things[self.bee.thing].z)));
        }
        mixIn(&h, @intFromEnum(self.cover));
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
        // one number rings it. The sound at the ears is that number times answer_level, less
        // what the 30 m back took (a carry of 30 m keeps half); the light is its square root,
        // here seen one step faded
        const strength = sounded[i] / (answer_level * 0.5);
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

/// The first place on a grid where the ground wears `want`, with at least `clear` metres of it
/// to the east: for tests.
fn findCover(want: ground.Cover, clear: f32) ?[2]f32 {
    var z: f32 = -1000.0;
    while (z < 200.0) : (z += 7.0) {
        var x: f32 = -600.0;
        while (x < 600.0) : (x += 7.0) {
            var ok = true;
            var d: f32 = 0.0;
            while (d <= clear) : (d += 2.0) {
                if (ground.coverAt(x + d, z) != want) ok = false;
            }
            if (ok) return .{ x, z };
        }
    }
    return null;
}

test "on moss a call carries half as far" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    var cues: [max_cues]sound.Cue = undefined;
    var answered: [2][2]bool = undefined;
    const places = [2]ground.Cover{ .lawn, .moss };
    for (places, 0..) |want, p| {
        const at = findCover(want, 2.0) orelse return error.NoSuchGround;
        w.* = .{};
        w.view = .place;
        w.stand = 1.0;
        w.stand_from = 0;
        w.ring_reach = 900.0;
        w.hum_x = at[0];
        w.hum_z = at[1];
        // one bell near, and one far, both on the garden's own note
        w.things[0] = .{ .x = at[0] + 40.0, .z = at[1], .y = 0.0, .hz = garden_hz, .carry = 110.0 };
        w.things[1] = .{ .x = at[0] + 700.0, .z = at[1], .y = 0.0, .hz = garden_hz, .carry = 110.0 };
        w.thing_count = 2;
        var step: u32 = 0;
        while (step < 60 * 14) : (step += 1) _ = w.stepOnce(.{ .buttons = if (step == 1) Hands.call else 0 }, &cues);
        try std.testing.expectEqual(want, w.cover);
        answered[p] = .{ w.things[0].lit > 0.0 or w.answers > 0, w.answers >= 2 };
    }
    // from lawn both answer; from moss the near one does and the far one is never reached
    try std.testing.expect(answered[0][0] and answered[0][1]);
    try std.testing.expect(answered[1][0] and !answered[1][1]);
}

test "fallen leaves ring underfoot and lawn sheds dew behind you, each seen at once and heard as late as it is far" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    var cues: [max_cues]sound.Cue = undefined;
    const kinds = [2]ground.Cover{ .leaves, .lawn };
    for (kinds) |want| {
        const at = findCover(want, 24.0) orelse return error.NoSuchGround;
        w.* = .{};
        w.view = .place;
        w.stand = 1.0;
        w.stand_from = 0;
        w.hum_x = at[0];
        w.hum_z = at[1];
        var strikes: u32 = 0;
        var step: u32 = 0;
        // walk east for three seconds
        while (step < 180) : (step += 1) {
            const n = w.stepOnce(.{ .lx = 110 }, &cues);
            for (cues[0..n]) |cue| {
                if (cue.kind == .strike) strikes += 1;
            }
        }
        var sparks: u32 = 0;
        for (w.sparks) |spark| {
            if (spark.born > 0) sparks += 1;
        }
        try std.testing.expect(strikes >= 4);
        try std.testing.expect(sparks >= 4);
        // every one was told as a cue, with its light
        try std.testing.expectEqual(w.told, w.sent);
        try std.testing.expectEqual(@as(u32, 0), w.dark_sounds);
    }
}

test "the bee's note falls a fifth as it passes" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    w.view = .place;
    w.stand = 1.0;
    w.stand_from = 0;
    w.dawn_from = 0;
    // a bee flying straight past Hum, ten metres off, from far away to far away
    w.things[0] = .{ .x = -300.0, .y = 0.5, .z = 10.0, .tall = 0.65, .hz = garden_hz, .family = .skin, .ring = 0.4, .carry = flyers.Bee.carry };
    w.thing_count = 1;
    w.bee = .{ .thing = 0 };
    w.bee.stops = @splat(.{ 300.0, 0.5, 10.0 });
    var cues: [max_cues]sound.Cue = undefined;
    var highest: f32 = 0.0;
    var lowest: f32 = 1e9;
    var step: u32 = 0;
    while (step < 60 * 48) : (step += 1) {
        const n = w.stepOnce(.{}, &cues);
        for (cues[0..n]) |cue| {
            if (cue.kind != .hum_on or cue.voice != 2) continue;
            highest = @max(highest, cue.hz);
            lowest = @min(lowest, cue.hz);
        }
    }
    // coming, a third high; going, a sixth low; between them a pure fifth
    try std.testing.expect(@abs(highest / garden_hz - 1.25) < 0.01);
    try std.testing.expect(@abs(lowest / garden_hz - 1.0 / 1.2) < 0.01);
    try std.testing.expect(@abs(highest / lowest - 1.5) < 0.02);
    // and every buzz was told with its light
    try std.testing.expectEqual(w.told, w.sent);
}

/// A world with one puddle in it, sized so the garden's note stands as a ring and a cross.
fn onePool(w: *World) void {
    w.* = .{};
    w.view = .place;
    w.stand = 1.0;
    w.stand_from = 0;
    const r = pools.radiusFor(7, garden_hz);
    w.things[0] = .{ .x = 0.0, .z = 0.0, .tall = r, .spread = r, .hz = pools.skin_k / r, .family = .skin, .ring = 2.5, .carry = 120.0 };
    w.thing_count = 1;
    w.pool_first = 0;
    w.pools[0] = pools.Pool.init(0.0, 0.0, r, 0, 5);
    w.pool_count = 1;
}

test "a pool hummed at its note stands in that shape, and holds Hum on its still line across" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    onePool(w);
    const r = w.pools[0].r;
    var cues: [max_cues]sound.Cue = undefined;
    // stand at its west edge and hum: the ring and the cross build, a belly toward Hum
    w.hum_x = -r - 2.0;
    w.hum_z = 0.0;
    var step: u32 = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expectEqual(@as(u8, 7), w.pools[0].figs[0].mode);
    try std.testing.expect(w.pools[0].figs[0].loud > 0.9);
    // the spokes lie at forty-five degrees to Hum: one runs from south-west to north-east
    try std.testing.expect(w.pools[0].amp(-40.0, -40.0) < 0.01);
    // the water sings its note back, and every tone was told with its light
    try std.testing.expect(w.pools[0].sent[0] > 0.8);
    try std.testing.expectEqual(w.told, w.sent);
    // step on at its south-west end, humming, and walk straight across to the north-east
    w.hum_x = -(r + 1.0) * 0.7071;
    w.hum_z = -(r + 1.0) * 0.7071;
    step = 0;
    var widest: f32 = 0.0;
    while (step < 60 * 50 and w.crossed == 0) : (step += 1) {
        _ = w.stepOnce(.{ .lx = 78, .ly = 78, .buttons = Hands.sing }, &cues);
        if (w.on_pool != 0) widest = @max(widest, @abs(w.hum_x - w.hum_z) * 0.7071);
    }
    // held on the still line all the way over, and the crossing is witnessed
    try std.testing.expectEqual(@as(u32, 1), w.crossed);
    try std.testing.expect(widest < 3.0);
    try std.testing.expect(w.seen.get(.garden_w04).met);
    try std.testing.expect(@as(f32, @floatFromInt(step)) * dt < 45.0);
}

test "a belly throws Hum back onto the still line, and still water floats Hum to the shore" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    onePool(w);
    const r = w.pools[0].r;
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = -r - 2.0;
    w.hum_z = 0.0;
    var step: u32 = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    // out on the spoke, a third of the way in, then pushing hard to the side for five seconds
    w.hum_x = -r * 0.5 * 0.7071;
    w.hum_z = -r * 0.5 * 0.7071;
    step = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .lx = 110, .ly = -110, .buttons = Hands.sing }, &cues);
    try std.testing.expect(w.pools[0].holds(w.hum_x, w.hum_z));
    try std.testing.expect(w.pools[0].amp(w.hum_x, w.hum_z) <= pools.hold_band + 0.02);
    // let go of the note: the figure dies away, the water stills, and floats Hum ashore
    step = 0;
    while (step < 60 * 40 and w.pools[0].holds(w.hum_x, w.hum_z)) : (step += 1) _ = w.stepOnce(.{ .ly = 110 }, &cues);
    try std.testing.expect(!w.pools[0].holds(w.hum_x, w.hum_z));
    try std.testing.expect(!w.pools[0].standing());
}

test "a call makes a puddle stand for a moment in the shape of the call's note" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    onePool(w);
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = -w.pools[0].r - 30.0;
    w.hum_z = 0.0;
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    var most: f32 = 0.0;
    var step: u32 = 0;
    while (step < 120) : (step += 1) {
        _ = w.stepOnce(.{}, &cues);
        most = @max(most, w.pools[0].figs[0].loud);
    }
    try std.testing.expectEqual(@as(u8, 7), w.pools[0].figs[0].mode);
    try std.testing.expect(most > 0.4);
    // and dies away by itself
    step = 0;
    while (step < 60 * 20) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.pools[0].loud() < 0.01);
}

test "Hum's own call starts on the sample the hands were stamped with, and is not sounded twice" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = World.init();
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    while (step < 10) : (step += 1) _ = w.stepOnce(.{}, &cues);
    // R1 went down 300 samples into this step
    const began = w.step * samples_per_step;
    const n = w.stepOnce(.{ .buttons = Hands.call, .stamp = 300 }, &cues);
    var call: ?sound.Cue = null;
    for (cues[0..n]) |cue| {
        if (cue.own == 1 and cue.kind == .strike) call = cue;
    }
    try std.testing.expect(call != null);
    try std.testing.expectEqual(began + 300, call.?.at);
    // the hands started it already, on the sound's own thread, on that sample: the world's telling
    // of it is then neither sounded again nor counted late
    var snd: sound.Sound = undefined;
    snd.init();
    var out: [256]f32 = undefined;
    var played: u64 = 0;
    while (played + out.len <= began + 300) : (played += out.len) snd.render(&out);
    var rest: [300]f32 = undefined;
    snd.render(rest[0 .. began + 300 - played]);
    const started = snd.ownNow(.{ .at = 0, .kind = .strike, .family = .string, .hz = garden_hz, .gain = callStrength(.soil) * voice_level, .ring = 0.35 });
    try std.testing.expectEqual(began + 300, started);
    snd.render(&out);
    _ = snd.push(call.?);
    snd.render(&out);
    try std.testing.expectEqual(@as(u32, 1), snd.own_met);
    try std.testing.expectEqual(@as(u32, 0), snd.late);
}

test "a rung bell rings its kin, and they ring theirs, more faintly each time (law 1)" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = .{};
    w.view = .place;
    w.stand = 1.0;
    // three bells in a row, twenty metres apart: C, the G above it, and the D above that. C and G
    // share a fifth; G and D share one; C and D share little
    w.things[0] = .{ .x = 0.0, .z = -200.0, .y = 10.0, .tall = 2.0, .hz = garden_hz, .ring = 3.0, .carry = 110.0 };
    w.things[1] = .{ .x = 20.0, .z = -200.0, .y = 10.0, .tall = 2.0, .hz = garden_hz * 1.5, .ring = 3.0, .carry = 110.0 };
    w.things[2] = .{ .x = 40.0, .z = -200.0, .y = 10.0, .tall = 2.0, .hz = garden_hz * 2.25, .ring = 3.0, .carry = 110.0 };
    w.thing_count = 3;
    w.findKin();
    try std.testing.expect(kinOf(w.things[0], w.things[1]) > kin_least);
    try std.testing.expect(kinOf(w.things[1], w.things[2]) > kin_least);
    // ring C hard, as a call's answer would
    w.step = 100;
    w.things[0].rung_at = 100;
    w.passOn(0, 0.9, true);
    var cues: [max_cues]sound.Cue = undefined;
    var rang: [3]u32 = .{ 100, 0, 0 };
    var hard: [3]f32 = .{ 0.9, 0.0, 0.0 };
    var step: u32 = 0;
    while (step < 120) : (step += 1) {
        const before = [3]u32{ w.things[0].rung_at, w.things[1].rung_at, w.things[2].rung_at };
        var waiting: [3]f32 = .{ 0.0, 0.0, 0.0 };
        for (w.echoes) |e| {
            if (e.live and e.due <= w.step) waiting[e.thing] = e.strength;
        }
        _ = w.stepOnce(.{}, &cues);
        for (1..3) |i| {
            if (w.things[i].rung_at != before[i] and rang[i] == 0) {
                rang[i] = w.things[i].rung_at;
                hard[i] = waiting[i];
            }
        }
    }
    // G rang after C, late by the way between them; D after G; each more faintly
    try std.testing.expect(rang[1] > rang[0] and rang[2] > rang[1]);
    try std.testing.expect(rang[1] - rang[0] >= 20);
    try std.testing.expect(hard[1] < hard[0] and hard[2] < hard[1] and hard[2] > 0.0);
    // and C, which rang first, was not rung straight back by G
    try std.testing.expectEqual(@as(u32, 100), w.things[0].rung_at);
}

test "home moves on the wheel, Hum's note with it, and what answers a call changes" {
    // the lit seven on a day of C: F C G D A E B, each in Hum's own register
    try std.testing.expect(@abs(wedgeHz(garden_hz, -1) / garden_hz - 4.0 / 3.0) < 1e-4);
    try std.testing.expect(@abs(wedgeHz(garden_hz, 1) / garden_hz - 0.75) < 1e-4);
    try std.testing.expect(@abs(wedgeHz(garden_hz, 4) / garden_hz - 1.25) < 1e-4);
    try std.testing.expectEqual(Mood.lift, moodOf(-1));
    try std.testing.expectEqual(Mood.darkest, moodOf(5));
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.* = World.init();
    // two moods are awake on the first days: wonder and sunny home; drive is asleep
    try std.testing.expect(!w.moveHome(1));
    try std.testing.expect(w.moveHome(-1));
    try std.testing.expect(@abs(w.home_hz - garden_hz * 4.0 / 3.0) < 0.01);
    // a bell on F: a stranger to C at a semitone's grind is kin to the new home
    w.things[0] = .{ .x = 20.0, .z = 0.0, .hz = garden_hz * 4.0 / 3.0 * 2.0, .ring = 2.0 };
    w.thing_count = 1;
    var cues: [max_cues]sound.Cue = undefined;
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    var call: ?sound.Cue = null;
    for (cues) |c| {
        if (c.own == 1 and c.kind == .strike) call = c;
    }
    // Hum calls on home's note
    try std.testing.expect(call != null and @abs(call.?.hz - garden_hz * 4.0 / 3.0) < 0.01);
    var step: u32 = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.answers >= 1);
}

test "a puddle silent to the garden's note stands when home is moved to wonder" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    const f_pool = pools.garden.len - 1;
    const p = &w.pools[f_pool];
    var cues: [max_cues]sound.Cue = undefined;
    // stand at its edge and hum the garden's own note: hardly anything
    w.hum_x = p.x - p.r - 3.0;
    w.hum_z = p.z;
    var step: u32 = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(!p.standing());
    _ = w.stepOnce(.{}, &cues);
    // home on wonder, the F below: it stands as a ring and a cross
    try std.testing.expect(w.moveHome(-1));
    step = 0;
    while (step < 300) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(p.standing());
    const loudest = if (p.figs[0].loud >= p.figs[1].loud) p.figs[0] else p.figs[1];
    try std.testing.expectEqual(@as(u8, 7), loudest.mode);
    try std.testing.expect(loudest.loud > 0.9);
}

test "R1 held opens the wheel; the right stick points at a wedge; letting go puts home there" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.locked_at = 0;
    w.hold_until = 0;
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    while (step < 70) : (step += 1) _ = w.stepOnce(.{}, &cues);
    // the right stick's directions are the wedges: up is the day's note, a twelfth of a turn left
    // is the fifth below
    try std.testing.expectEqual(@as(i8, 0), wedgeAt(0.0, -1.0));
    try std.testing.expectEqual(@as(i8, -1), wedgeAt(-0.5, -0.866));
    try std.testing.expectEqual(@as(i8, 3), wedgeAt(1.0, 0.0));
    try std.testing.expectEqual(@as(i8, -6), wedgeAt(0.0, 1.0));
    // a tap is a call and opens nothing
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    // held, it opens, and the place lies back part of the way, no further
    step = 0;
    while (step < 40) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    try std.testing.expect(w.stand <= wheel_stand + 0.01 and w.stand > 0.3);
    // point a twelfth of a turn left, at wonder, and the view does not turn
    const yaw = w.look_yaw;
    step = 0;
    while (step < 10) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.call, .rx = -63, .ry = -110 }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.wheel_point.?);
    try std.testing.expectEqual(yaw, w.look_yaw);
    // let go: home is wonder, the F below, and Hum's note with it
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expect(@abs(w.home_hz - garden_hz * 4.0 / 3.0) < 0.01);
    // pointed at an asleep mood (drive, to the right), letting go leaves home where it is
    step = 0;
    while (step < 30) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.call, .rx = 63, .ry = -110 }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
}

test "the swell: a nudge on a downbeat walks home one wedge, and the let-go on the one lands the cadence" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // just before a downbeat: tick 8 is the first of a bar
    while (w.step < tickStep(8) - 30) _ = w.stepOnce(.{}, &cues);
    // hold R2: the swell begins at home, sunny home
    while (w.step < tickStep(8) - 20) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(w.singing);
    // a nudge off the beat does nothing
    _ = w.stepOnce(.{ .buttons = Hands.sing, .rx = -110 }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    // on the downbeat, a nudge left walks home to wonder, and the swell has grown a bar
    while (w.step < tickStep(8)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.sing, .rx = -110 }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expectEqual(@as(u8, 1), w.swell_bars);
    // held on to the next bar's downbeat, let go on the one: home went down a fifth, the full close
    while (w.step < tickStep(12)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    const answers = w.answers;
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(Cadence.full_close, w.cadence);
    // and the land answers the new home: its ring climbs to the crowns, ninety metres up and more
    var step: u32 = 0;
    while (step < 360) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.answers > answers);
    // a swell from wonder walked back up a fifth and let go on the one is the amen
    const bar = (w.step / tick_every / 4 + 1) * 4;
    while (w.step < tickStep(bar) - 10) _ = w.stepOnce(.{}, &cues);
    while (w.step < tickStep(bar)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.sing, .rx = 110 }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    while (w.step < tickStep(bar + 4)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(Cadence.amen, w.cadence);
}

test "R1 held thickens time: the beat runs at a quarter, and lets go when the wheel closes" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    while (w.step < 100) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(w.step, w.clock);
    // a call, and the wheel held open for two seconds: the call's ring runs a quarter as fast
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    var step: u32 = 0;
    while (step < 120) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    try std.testing.expectEqual(thick, w.tempo);
    const lost = w.step - w.clock;
    try std.testing.expect(lost > 70 and lost < 100);
    // let go: the pace comes back, and the beat runs with the steps again
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(f32, 1.0), w.tempo);
    const after = w.step - w.clock;
    step = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(after, w.step - w.clock);
}

test "a knot struck on the one with home on its root greys, and a cadence beside its root brings it home" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // stand near the first knots: they come and keep a circle round Hum
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 40.0;
    var step: u32 = 0;
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    for (w.knots[0..w.knot_count]) |kn| {
        const dx = kn.x - w.hum_x;
        const dz = kn.z - w.hum_z;
        try std.testing.expect(dx * dx + dz * dz < 8.0 * 8.0);
    }
    // home on wonder, the knots' root: strikes on Hum's downbeats are meetings
    try std.testing.expect(w.moveHome(-1));
    var struck: u32 = 0;
    while (struck < 3) {
        if (w.clock % (4 * tick_every) == 0 and w.clock > 0) {
            _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
            struck += 1;
        } else _ = w.stepOnce(.{}, &cues);
    }
    _ = w.stepOnce(.{}, &cues);
    for (w.knots[0..w.knot_count]) |k| try std.testing.expectEqual(@as(f32, 0.0), k.colour);
    // the swell, a nudge up to sunny home beside the root on a downbeat, and let go on the one
    const bar = (w.clock / tick_every / 4 + 1) * 4;
    while (w.clock < tickStep(bar) - 10) _ = w.stepOnce(.{}, &cues);
    while (w.clock < tickStep(bar)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.sing, .rx = 110 }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    while (w.clock < tickStep(bar + 4)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(Cadence.amen, w.cadence);
    try std.testing.expectEqual(@as(u32, 3), w.knots_home);
    // each keeps the mood it was brought home in: sunny home
    try std.testing.expectEqual(@as(u8, @intFromEnum(Mood.bind)), w.knots[0].gift);
}

test "struck with home elsewhere, a knot drains slower: the dance's one is not Hum's" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 40.0;
    var step: u32 = 0;
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    const dx = w.knots[0].x - w.hum_x;
    const dz = w.knots[0].z - w.hum_z;
    try std.testing.expect(dx * dx + dz * dz < knots.strike_reach * knots.strike_reach);
    // home on sunny home, the windows as Fierce keeps them: three strikes timed on the downbeat,
    // which greyed it with home on its root, leave it coloured
    w.fierce = true;
    var struck: u32 = 0;
    while (struck < 3) {
        if (w.clock % (4 * tick_every) == 0 and w.clock > 0) {
            _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
            struck += 1;
        } else _ = w.stepOnce(.{}, &cues);
    }
    try std.testing.expectEqual(@as(u32, 3), w.timed_strikes);
    try std.testing.expect(w.knots[0].colour > 0.05 and w.knots[0].colour < 1.0);
}

test "a knot lunges to arrive on its one; a dodge on that beat opens the pocket, and a lunge not dodged knocks Hum back" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 40.0;
    _ = w.moveHome(-1);
    var step: u32 = 0;
    // they come; with home on their root, their one is Hum's downbeat, and they lunge to arrive on it
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.knocked > 0);
    const knocked = w.knocked;
    // dodge just as the next lunge arrives: the pocket opens, and the lunge misses
    var dodged = false;
    step = 0;
    while (step < 60 * 10 and !dodged) : (step += 1) {
        var lunging = false;
        for (w.knots[0..w.knot_count]) |kn| {
            if (kn.lunge_from != knots.never_lunged and w.clock == kn.lunge_from + knots.lunge_steps / 2 - 2) lunging = true;
        }
        if (lunging) {
            _ = w.stepOnce(.{ .buttons = Hands.dodge }, &cues);
            dodged = true;
        } else _ = w.stepOnce(.{}, &cues);
    }
    try std.testing.expect(dodged);
    try std.testing.expectEqual(@as(u32, 1), w.pockets);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(knots.pocket, w.tempo);
    // the pocket's strike takes more than a strike out of it
    const before = w.knots[0].colour + w.knots[1].colour + w.knots[2].colour;
    _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    const after = w.knots[0].colour + w.knots[1].colour + w.knots[2].colour;
    try std.testing.expect(before - after > knots.drain_alone + knots.pocket_drain * 0.9);
    // and the lunge that was dodged landed nothing more
    try std.testing.expect(w.knocked <= knocked + 1);
}

test "each bar in the pocket keeps its strikes as an afterimage that lands again; the clap spends them and sets the knots' one" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 40.0;
    _ = w.moveHome(-1);
    var step: u32 = 0;
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    // two bars: dodge each lunge on its beat, strike on each downbeat
    var bars: u32 = 0;
    while (bars < 3) {
        var lunge_due = false;
        for (w.knots[0..w.knot_count]) |kn| {
            if (kn.lunge_from != knots.never_lunged and w.clock + 2 == kn.lunge_from + knots.lunge_steps / 2) lunge_due = true;
        }
        var hands = Hands{};
        if (lunge_due) hands.buttons |= Hands.dodge;
        if (w.clock % (4 * tick_every) == 0 and w.clock > 0) {
            hands.buttons |= Hands.strike;
            bars += 1;
        }
        _ = w.stepOnce(hands, &cues);
    }
    // the bars in the pocket became layers, and their strikes land again from beside Hum
    try std.testing.expect(w.layer_n >= 1);
    step = 0;
    while (step < 4 * tick_every * 2) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.ghost_strikes >= 1);
    // the clap: the layers are spent, and every knot near starts its cycle now
    for (w.knots[0..w.knot_count]) |*kn| kn.colour = 1.0;
    _ = w.stepOnce(.{ .buttons = Hands.voice | Hands.call | Hands.clap }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.claps);
    try std.testing.expectEqual(@as(u8, 0), w.layer_n);
    var reset: u32 = 0;
    for (w.knots[0..w.knot_count]) |kn| {
        if (kn.phase_from == w.clap_at) reset += 1;
    }
    try std.testing.expect(reset >= 1);
}

test "a clap takes back a call begun just before it, and leaves a call made long before" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    while (step < 30) : (step += 1) _ = w.stepOnce(.{}, &cues);
    const live = struct {
        fn own(world: *const World) u32 {
            var n: u32 = 0;
            for (world.rings) |r| {
                if (r.live and r.own) n += 1;
            }
            return n;
        }
    };
    // R1, and L1 three steps later: one gesture, a clap, and the call's ring is taken back
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expectEqual(@as(u32, 1), live.own(w));
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    const n = w.stepOnce(.{ .buttons = Hands.call | Hands.voice | Hands.clap }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.claps);
    try std.testing.expectEqual(@as(u32, 0), live.own(w));
    // the clap is Hum's own, on the hands' stamp, for the sound to match with what it started
    var clap_told = false;
    for (cues[0..n]) |cue| {
        if (cue.own == sound.own_clap) clap_told = true;
    }
    try std.testing.expect(clap_told);
    // R1 and L1 pressed on one step: a clap and no call at all
    step = 0;
    while (step < 10) : (step += 1) _ = w.stepOnce(.{}, &cues);
    const calls = w.calls;
    _ = w.stepOnce(.{ .buttons = Hands.call | Hands.voice | Hands.clap }, &cues);
    try std.testing.expectEqual(calls, w.calls);
    try std.testing.expectEqual(@as(u32, 0), live.own(w));
    // a call, and a clap a third of a second later: two things, and the call stands
    step = 0;
    while (step < 10) : (step += 1) _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    step = 0;
    while (step < 20) : (step += 1) _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.voice | Hands.call | Hands.clap }, &cues);
    try std.testing.expectEqual(@as(u32, 3), w.claps);
    try std.testing.expectEqual(@as(u32, 1), live.own(w));
}

test "out of the pocket the afterimage lands softer each bar, and is gone" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // into the first bar, two layers kept, each striking on the downbeat
    const bar: u64 = 4 * tick_every;
    while (w.clock < 10) _ = w.stepOnce(.{}, &cues);
    w.layer_n = 2;
    w.layer_strikes = .{ 1, 1, 0, 0 };
    w.layer_level = .{ 1.0, 1.0, 0.0, 0.0 };
    while (w.clock % bar != bar - 2) _ = w.stepOnce(.{}, &cues);
    // a bar with no pocket ends: both land at half
    while (w.clock % bar != 2) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(u8, 2), w.layer_n);
    try std.testing.expectEqual(@as(f32, 0.5), w.layer_level[0]);
    const struck = w.ghost_strikes;
    try std.testing.expect(struck >= 2);
    // two more bars out of the pocket, and they are gone
    var bars: u32 = 0;
    while (bars < 2) : (bars += 1) {
        _ = w.stepOnce(.{}, &cues);
        while (w.clock % bar != 2) _ = w.stepOnce(.{}, &cues);
    }
    try std.testing.expectEqual(@as(u8, 0), w.layer_n);
}

test "a strike timed within an eighth of a beat lands at once with its octave; off the beat the game places it on the next beat, plain" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.canStrike());
    // two steps after a beat: within the window, so it is the hands' own, and lands at once, fuller
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    var n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.timed_strikes);
    var fuller = false;
    for (cues[0..n]) |cue| {
        if (cue.own == sound.own_strike and cue.family == .fork_octave) fuller = true;
    }
    try std.testing.expect(fuller);
    // a quarter of a beat after a beat: off it, so the game places it on the next beat
    while (w.clock % tick_every != tick_every / 4) _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 0), w.placed_strikes);
    const due = w.strike_due;
    try std.testing.expectEqual(@as(u64, 0), due % tick_every);
    // it lands in the step its beat falls in, its note alone, sent for the sample the beat falls on
    var landed = false;
    step = 0;
    while (!landed and step < 2 * tick_every) : (step += 1) {
        const was = w.clock;
        n = w.stepOnce(.{}, &cues);
        if (w.placed_strikes == 1) {
            landed = true;
            try std.testing.expect(was <= due and w.clock >= due);
        }
    }
    try std.testing.expect(landed);
    var plain = false;
    step = 0;
    while (step < 4) : (step += 1) {
        for (cues[0..n]) |cue| {
            if (cue.own == sound.own_only and cue.family == .fork) plain = true;
        }
        n = w.stepOnce(.{}, &cues);
    }
    try std.testing.expect(plain);
    try std.testing.expectEqual(never, w.strike_due);
}

test "the four doors: rung open and the next grey, settled, kin for a phrase, slid home, and a plain ending" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.awake = 0xff;
    const bar: u64 = 4 * tick_every;
    var cues: [max_cues]sound.Cue = undefined;
    const Case = struct { root: i8, home: i8, fate: knots.Fate, home_now: bool };
    const cases = [_]Case{
        .{ .root = 0, .home = -1, .fate = .full_close, .home_now = true },
        .{ .root = -1, .home = 0, .fate = .amen, .home_now = true },
        .{ .root = 0, .home = 2, .fate = .turn, .home_now = false },
        .{ .root = 0, .home = 5, .fate = .slide, .home_now = true },
        .{ .root = 0, .home = 0, .fate = .none, .home_now = false },
        .{ .root = 0, .home = 3, .fate = .none, .home_now = false },
    };
    for (cases) |cs| {
        // one grey knot beside Hum, the others far off
        for (w.knots[0..w.knot_count], 0..) |*kn, i| {
            kn.home = false;
            kn.fate = .none;
            kn.colour = 1.0;
            kn.calm_until = 0;
            kn.kin_until = 0;
            kn.x = w.hum_x + 500.0;
            kn.z = w.hum_z + 500.0 + @as(f32, @floatFromInt(i));
        }
        const kn = &w.knots[0];
        kn.x = w.hum_x + 3.0;
        kn.z = w.hum_z;
        kn.root_hz = wedgeHz(w.day_hz, cs.root);
        kn.colour = 0.0;
        w.home_k = cs.home;
        w.home_hz = wedgeHz(w.day_hz, cs.home);
        w.landCadence();
        try std.testing.expectEqual(cs.fate, kn.fate);
        try std.testing.expectEqual(cs.home_now, kn.home);
        if (cs.fate == .none) try std.testing.expect(kn.calm_until > w.clock);
        // the turn: kin for a phrase, and then home
        if (cs.fate == .turn) {
            var step: u64 = 0;
            while (step < (knots.kin_bars + 1) * bar + 10) : (step += 1) _ = w.stepOnce(.{}, &cues);
            try std.testing.expect(kn.home);
        }
    }
    // the full close's chain: a coloured knot with its root where home landed goes grey and leans
    for (w.knots[0..w.knot_count]) |*kn| {
        kn.home = false;
        kn.fate = .none;
        kn.x = w.hum_x + 500.0;
    }
    w.knots[0] = .{ .x = w.hum_x + 3.0, .z = w.hum_z, .root_hz = wedgeHz(w.day_hz, 0), .colour = 0.0, .thing = w.knots[0].thing };
    w.knots[1] = .{ .x = w.hum_x - 3.0, .z = w.hum_z, .root_hz = wedgeHz(w.day_hz, -1), .colour = 1.0, .thing = w.knots[1].thing };
    w.home_k = -1;
    w.home_hz = wedgeHz(w.day_hz, -1);
    w.landCadence();
    try std.testing.expectEqual(knots.Fate.full_close, w.knots[0].fate);
    try std.testing.expectEqual(@as(f32, 0.0), w.knots[1].colour);
    try std.testing.expect(!w.knots[1].home);
}

test "Gentle widens each window of timing by half again, and Fierce keeps them" {
    var cues: [max_cues]sound.Cue = undefined;
    var timed: [2]u32 = undefined;
    for ([2]bool{ false, true }, 0..) |fierce, k| {
        const w = try std.testing.allocator.create(World);
        defer std.testing.allocator.destroy(w);
        w.initAsters();
        w.fierce = fierce;
        var step: u32 = 0;
        while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
        // a strike eight steps after a beat: outside an eighth of a beat, inside half again of it
        while (w.clock % tick_every != 8) _ = w.stepOnce(.{}, &cues);
        _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
        timed[k] = w.timed_strikes;
    }
    try std.testing.expectEqual(@as(u32, 1), timed[0]);
    try std.testing.expectEqual(@as(u32, 0), timed[1]);
}

test "on Gentle a swell held a bar unsteered leans home beside the grey knot on its amen side; on Fierce the amen is a plain ending" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 40.0;
    var step: u32 = 0;
    while (step < 60 * 25) : (step += 1) _ = w.stepOnce(.{}, &cues);
    _ = w.moveHome(-1);
    for (w.knots[0..w.knot_count]) |*kn| kn.colour = 0.0;
    // hold the swell from just before a downbeat, and never touch the stick
    const bar = (w.clock / tick_every / 4 + 1) * 4;
    while (w.clock < tickStep(bar) - 10) _ = w.stepOnce(.{}, &cues);
    while (w.clock < tickStep(bar + 4) + 2) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    // after a bar, home has drifted to sunny home, one to the right of the knots' root
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    try std.testing.expectEqual(@as(u32, 1), w.leans_for_you);
    // let go on the next downbeat: the amen, and they settle and sleep
    while (w.clock < tickStep(bar + 8)) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(Cadence.amen, w.cadence);
    try std.testing.expectEqual(@as(u32, 3), w.knots_home);
    for (w.knots[0..w.knot_count]) |kn| try std.testing.expectEqual(knots.Fate.amen, kn.fate);

    // the same on Fierce: nothing leans for you, and a nudge to the amen side is a plain ending
    const f = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(f);
    f.initAsters();
    f.fierce = true;
    f.hum_x = f.knots[0].x;
    f.hum_z = f.knots[0].z - 40.0;
    step = 0;
    while (step < 60 * 25) : (step += 1) _ = f.stepOnce(.{}, &cues);
    _ = f.moveHome(-1);
    for (f.knots[0..f.knot_count]) |*kn| kn.colour = 0.0;
    const fbar = (f.clock / tick_every / 4 + 1) * 4;
    while (f.clock < tickStep(fbar) - 10) _ = f.stepOnce(.{}, &cues);
    while (f.clock < tickStep(fbar + 4) + 2) _ = f.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expectEqual(@as(i8, -1), f.home_k);
    _ = f.stepOnce(.{ .buttons = Hands.sing, .rx = 110 }, &cues);
    while (f.clock < tickStep(fbar + 8)) _ = f.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = f.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(u32, 0), f.knots_home);
    try std.testing.expect(f.doors[0] >= 3);
}

test "every knot home, the hose springs open an octave up, the water runs to the pool, and for a second a figure sits on its edge" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // stopped: the drone is the hollow pipe two octaves under the garden's note, heard when it has
    // come from the hose's nearest stretch
    var heard_stopped = false;
    var step: u32 = 0;
    while (step < 150) : (step += 1) {
        const n = w.stepOnce(.{}, &cues);
        for (cues[0..n]) |cue| {
            if (cue.kind == .tone and cue.voice == hose_voice and cue.family == .stopped_pipe and cue.hz == hose_stopped_hz) heard_stopped = true;
        }
    }
    try std.testing.expect(heard_stopped);
    try std.testing.expect(!w.hose_open);
    // the knots come home
    for (w.knots[0..w.knot_count]) |*kn| {
        kn.home = true;
        kn.fate = .amen;
    }
    w.knots_home = w.knot_count;
    var heard_open = false;
    var opened_at: u64 = 0;
    step = 0;
    while (step < 60 * 12 and w.figure_from == never) : (step += 1) {
        const n = w.stepOnce(.{}, &cues);
        if (w.hose_open and opened_at == 0) opened_at = w.step;
        for (cues[0..n]) |cue| {
            if (cue.kind == .tone and cue.voice == hose_voice and cue.family == .open_pipe and cue.hz == hose_open_hz) heard_open = true;
        }
    }
    try std.testing.expect(w.hose_open);
    try std.testing.expect(heard_open);
    // the water took as long as the run from the knot to the mouth at its speed
    const took = @as(f32, @floatFromInt(w.water_at - w.water_from)) * dt;
    try std.testing.expect(@abs(took - land.hose_knot / water_speed) < 0.1);
    // and the figure sits for one second, then is gone
    step = 0;
    var seen_for: u32 = 0;
    while (step < 200) : (step += 1) {
        _ = w.stepOnce(.{}, &cues);
        if (w.figureNow()) seen_for += 1;
    }
    try std.testing.expect(seen_for + 2 >= figure_for and seen_for <= figure_for);
}

test "an aster's stalk is solid: Hum goes round it, and a brush at a run rings its bells" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // stand a little south of an aster's foot, facing it, the view behind
    const tw = w.towers[3];
    w.hum_x = tw.x;
    w.hum_z = tw.z + 12.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.look_yaw = 0.0;
    var nearest: f32 = 1e9;
    var heard_bells: u32 = 0;
    var step: u32 = 0;
    while (step < 240) : (step += 1) {
        const n = w.stepOnce(.{ .ly = -127 }, &cues);
        for (cues[0..n]) |cue| {
            if (cue.kind == .strike and cue.family == .bell) heard_bells += 1;
        }
        const dx = w.hum_x - tw.x;
        const dz = w.hum_z - tw.z;
        nearest = @min(nearest, @sqrt(dx * dx + dz * dz));
    }
    // never inside the stalk
    try std.testing.expect(nearest >= stalk_foot + hum_body - 0.001);
    // one brush, rung once, and its bells heard, each when its sound had come down
    try std.testing.expectEqual(@as(u32, 1), w.bumps);
    try std.testing.expect(heard_bells >= 3);
    // a gentle walk into it rings nothing
    w.initAsters();
    w.hum_x = tw.x;
    w.hum_z = tw.z + 4.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    step = 0;
    while (step < 240) : (step += 1) _ = w.stepOnce(.{ .ly = -20 }, &cues);
    try std.testing.expectEqual(@as(u32, 0), w.bumps);
}
