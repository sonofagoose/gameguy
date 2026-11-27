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
pub const reeds = @import("reeds.zig");
pub const spigot = @import("spigot.zig");
pub const footing = @import("footing.zig");
pub const harmony = @import("harmony.zig");
pub const react_mod = @import("../law/react.zig");
pub const feel = @import("../feel.zig");
const eye_mod = @import("../body/eye.zig");
const garden_place = @import("../place/garden.zig");
pub const form = @import("../form/shape.zig");
pub const covers = @import("covers.zig");
pub const home = @import("home.zig");
pub const drip = @import("drip.zig");

/// The puddles on the ground at once (pools.zig).
pub const max_pools = pools.garden.len;
/// How loud standing water sings its note back, at full loudness, against a voice.
/// (Smoothed from 0.8 / ~4 dB to 0.62 / ~2 dB to eliminate the seasick disorientation: Clip 32).
pub const pool_voice: f32 = 0.62;
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

const QualityDef = enum { major, minor, diminished };
pub const Quality = QualityDef;

/// The chord quality on each lit wedge: major for F, C, G; diminished for B; minor for D, A, E.
fn homeQualityFn(k: i8) QualityDef {
    var folded: i8 = k;
    while (folded > 5) folded -= 12;
    while (folded < -6) folded += 12;
    return switch (folded) {
        -1, 0, 1 => .major,
        5 => .diminished,
        else => .minor,
    };
}
pub const homeQuality = homeQualityFn;

/// The three notes of home's chord, as pure ratios above home's own note (GameguyPage standard).
fn chordRatiosFn(q: QualityDef) [3]f32 {
    return switch (q) {
        .major => .{ 1.0, 1.25, 1.5 },
        .minor => .{ 1.0, 1.2, 1.5 },
        .diminished => .{ 1.0, 1.2, 1.4 },
    };
}
pub const chordRatios = chordRatiosFn;
/// Gentle widens every window of timing by one sum (SPEC.md 10: "Gentle widens the timing and the
/// ledges"): the strike's, the dodge's, a meeting's, the downbeat's and the breath's.
pub const gentle_widens: f64 = 1.5;
/// Hum's run, with the stick pushed all the way (Morgan: "probably faster movement overall", then
/// "I want more speed"): a fifth of the speed of sound.
pub const run_speed: f32 = sound_speed / 5.0;
/// One breath (SPEC.md 9): how many homes it holds at first and at most (the ferry makes one
/// more), what each thing costs of it, and how it comes back. A home is what one step home in the
/// swell costs; a bar is four of Drip's ticks.
pub const breath_first: u8 = 3;
pub const breath_grows_to: u8 = 7;
pub const bar_steps: f32 = 4.0 * @as(f32, @floatFromInt(tick_every));
pub const hold_free_bars: u8 = 2;
pub const hold_costs: f32 = 1.0 / 8.0;
pub const step_costs: f32 = 1.0;
pub const wheel_costs: f32 = 1.0 / 8.0;
pub const sprint_costs: f32 = 1.0;
pub const breath_in_after: u32 = tick_every / 2;
pub const breath_in: f32 = 1.0 / @as(f32, @floatFromInt(tick_every));
/// The sprint: the right face held while Hum walks, a third of the speed of sound.
pub const sprint_speed: f32 = sound_speed / 3.0;
/// The dash: the right face tapped with nothing threatening, this far in this many steps, through
/// the same move as walking, so whatever is solid stops it (Morgan: "dashes should actually cover
/// some ground").
pub const dash_far: f32 = 6.0;
/// Drip's hop over the coil, in steps.
pub const drip_hop_steps: f32 = 90.0;
/// A strike's note carries this far as a wave, striking each knot it reaches as it arrives, the
/// weaker the farther (Morgan: "is there supposed to be an attack with some range?").
pub const wave_reach: f32 = 25.0;
pub const dash_steps: u32 = 9;
/// A knot this near that is not home threatens, and the right face dodges instead.
pub const threat_reach: f32 = 60.0;

/// The jump: how high, and how long in the air, which set how hard the ground pulls (a game's pull,
/// snappier than a real one).
/// SM64 x TotK standard: crisp, punchy, responsive (Piece 2).
pub const jump_height: f32 = 3.0;
pub const jump_air_s: f32 = 0.68;
pub const fall_pull: f32 = 8.0 * jump_height / (jump_air_s * jump_air_s);
pub const jump_speed: f32 = 4.0 * jump_height / jump_air_s;

/// Live jump gravity and launch velocity derived from `feel.now.jump_height`, preserving exact
/// compile-time rounding when untouched so `same-take` stays bit-identical.
pub fn fallPullNow() f32 {
    if (feel.now.jump_height == jump_height) return fall_pull;
    return 8.0 * feel.now.jump_height / (jump_air_s * jump_air_s);
}

pub fn jumpSpeedNow() f32 {
    if (feel.now.jump_height == jump_height) return jump_speed;
    return 4.0 * feel.now.jump_height / jump_air_s;
}
/// A try-out of design/the-game.md, off unless the game is started with --chords: L1 and L2 step
/// the chord between the lift, home and the lean wherever Hum is, at once, and Hum's body follows
/// the chord. Its switch and its counts are kept out of the world itself, so the game's saves and
/// takes are as they were. Every number here is a first guess for Morgan's hands.
pub var chords_tryout: bool = false;
pub const Tryout = struct {
    /// The step the chord last came onto the lean, to know how long Hum has leaned.
    leaned_from: u64 = never,
    /// The step of the last change of chord, for the line of words.
    changed_at: u64 = never,
    steps: u32 = 0,
    timed: u32 = 0,
    knocks: u32 = 0,
    launches: u32 = 0,
    highest: f32 = 0.0,
    fastest: f32 = 0.0,
};
pub var tryout = Tryout{};
/// On the lift Hum is light: the ground pulls this much as hard, going up and coming down.
pub const lift_pull: f32 = 0.55;
/// On the lean Hum is drawn forward: this much faster on its legs.
pub const lean_speed: f32 = 1.3;
/// Stepping home off the lean throws Hum the way it is going: this far after a long lean, in this
/// many steps; a short lean throws it less, and never less than a third of it.
/// How long the chord's own strings ring, how far round Hum what is kin to the chord lights, how
/// much it must share to count as kin, and how many of the nearest sound.
pub const chord_rings: f32 = 0.9;
pub const chord_kin_reach: f32 = 90.0;
pub const chord_kin_least: f32 = 0.5;
pub const chord_kin_sound = 4;
pub const launch_far: f32 = 6.0;
pub const launch_steps: u32 = 9;
pub const launch_full_after: u32 = 90;
/// Target minimal jump height on a quick tap release: ~1.5 m (50% of full 3.0 m leap).
/// Releasing anytime within the first 100 ms (~6 steps) reliably produces this low hop without superhuman tap timing.
pub const jump_tap_height: f32 = 1.55;
/// Air steering: how much of the stick's ask the legs give in the air (generous, TotK style).
pub const air_ease: f32 = 0.20;
/// (Glide removed: DECISIONS.md row 146. Hum's movement is SM64 × TotK ambitious, not sailed.)
/// The wind (spec/sky.md, "The law"): its speed is the day's note folded into one octave, a fifth
/// higher half again as fast, slowest on C. The Garden after the storm is nearly still.
pub const wind_on_c: f32 = 1.5;
/// How strongly the wind takes hold of the sail, by how far home stands from the wind's note on the
/// wheel: on it, not at all (you sit still); a fifth off, wholly (you run); straight across, wholly
/// the other way (you are thrown back). Between, a cosine through those three.
pub fn sailDrive(wedges_off: i32) f32 {
    const d: f32 = @floatFromInt(@abs(wedges_off));
    if (d <= 1.0) return d;
    return @cos(std.math.pi * (d - 1.0) / 5.0);
}


/// How wide Hum is from its middle, and an aster's stalk at its foot (draw/aster_lines.zig, girth):
/// Hum goes round a stalk, never through it.
pub const hum_body: f32 = 0.36;
/// Hum's shape, drawn and felt alike: half its height, and how high its middle stands over its
/// feet. Its half-width is hum_body. Singing after the lock, it swells (World.humSwell).
pub const hum_half_high: f32 = 0.5;
pub const hum_middle: f32 = 0.52;
pub const stalk_foot: f32 = 0.54;
/// How wide the spigot's brass body is from its middle.
pub const spigot_body: f32 = spigot.riser;
/// What Hum steps up onto without a jump: a third of its height (on Gentle, half as much again).
pub const step_up: f32 = 0.3;
/// Going into a stalk faster than this rings it; at a full run it rings as hard as a brush can.
pub const bump_least: f32 = 1.5;
/// How much of an aster's bells' strength a brush at a full run gives them, and its knock.
pub const brush_rings: f32 = 0.4;

/// How much of the way to the speed the stick asks for Hum's legs go each step, pushed and let go:
/// nine tenths of the way in a sixth of a second, and a skid of about 0.4 m from a run.
pub const go_ease: f32 = 0.25;
pub const stop_ease: f32 = 0.28;
/// The legs' two stages: the first quick_speed comes at go_ease, nine tenths of it in 0.13 s; the
/// rest climbs at this many metres a second each second, to a run in another half second, and to a
/// sprint.
pub const quick_speed: f32 = 8.0;
pub const run_climb: f32 = 8.0;
pub const sprint_climb: f32 = 12.0;
/// Turning keeps Hum's speed and bends its way: at most this many radians a second while slow,
/// and a turn this wide at a run and at a sprint, so a body arcs where a cursor would slide.
pub const turn_slow: f32 = 12.0;
pub const turn_radius_run: f32 = 1.5;
pub const turn_radius_sprint: f32 = 5.0;
/// Pulled round further than skid_turn at more than skid_least, Hum skids round instead: it
/// brakes this hard, sounding the ground it skids on, and turns once it is slow.
pub const skid_turn: f32 = 1.92;
pub const skid_least: f32 = 5.0;
pub const skid_brake: f32 = 40.0;
pub const skid_done: f32 = 1.5;
/// The left stick: nothing inside its dead middle, a full run from stick_full out, and between,
/// the run's speed by the push past the middle raised to this power.
pub const stick_dead: f32 = 0.12;
pub const stick_full: f32 = 0.85;
pub const stick_power: f32 = 1.2;
/// Slopes pull: uphill the legs give this much less by the slope's sine, downhill this much more,
/// to at most downhill_most.
pub const uphill_pull: f32 = 1.2;
pub const downhill_push: f32 = 0.8;
pub const downhill_most: f32 = 12.0;
/// A press of the bottom face this many steps before landing still jumps, as Hum lands; one this
/// many steps after walking off an edge still jumps. Falling this low over the ground, a press is
/// that early jump.
pub const jump_early: u32 = 6;
pub const jump_late: u32 = 6;
pub const jump_early_height: f32 = 1.0;
/// The dodge is a burst through the same move as walking, so whatever is solid stops it: this far
/// in this many steps. A lunge that lands knocks Hum back the same way.
pub const dodge_steps: u32 = 6;
pub const knock_steps: u32 = 4;
/// How far Hum turns in a step at most: a turn about takes a quarter of a second.
pub const turn_most: f32 = 0.2;
/// The view swings in behind where Hum is going at this rate (a part of the gap a second, at a
/// run), once the right stick has rested this many steps, and only while Hum goes no more than
/// this far round from the way the view looks: running at the screen leaves the view where it is.
pub const follow_rate: f32 = 1.1;
pub const follow_after: u32 = 45;
pub const follow_within: f32 = 2.2;
/// At a run the view pulls back this far, rises this much and widens this many degrees, eased
/// by `view_run_ease` each step so stopping against a solid never snaps the camera forward.
pub const run_back: f32 = 3.0;
pub const run_up: f32 = 0.4;
pub const run_wider: f32 = 3.0;
pub const view_run_ease: f32 = 0.08;
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
/// How loud Hum's held hum is, and Drip humming along with it, as parts of the voice's level. Morgan,
/// 2026-11-21: "the sound that rings whilst holding R2 could be just a bit quieter": both 3 dB down
/// (from 1.0 and 0.7). The hands' own early start of the hum reads the same number.
pub const hum_strength: f32 = 0.7;
/// Hum's call and Hum's hum, as the world tells them: the one recipe for each, which the hands'
/// own early start on the sound's thread reads too (dark.zig), so the two can't drift apart.
pub fn callSound(home_hz: f32, cover: ground.Cover) cues_mod.Sound {
    return .{ .kind = .strike, .family = .string, .hz = home_hz, .strength = callStrength(cover), .ring = 0.35 };
}
pub fn humSound(home_hz: f32) cues_mod.Sound {
    return .{ .kind = .hum_on, .hz = home_hz, .strength = hum_strength, .ring = 0.0 };
}
/// A sound of the world's as the sound thread hears it, at the voice's level.
pub fn heardAs(s: cues_mod.Sound, own: u8) sound.Cue {
    return .{ .at = 0, .kind = s.kind, .family = s.family, .voice = s.voice, .own = own, .hz = s.hz, .gain = s.strength * voice_level, .ring = s.ring };
}
pub const drip_along: f32 = 0.5;
/// Drip's tick: mellow, a fork's nearly pure tone an octave over its note; and the one of each bar
/// told apart from the other three as a metronome does it (Morgan: "Ableton does their metronome
/// like the 1 is a higher note and the rest are lower and a bit out of the way"): the one an octave
/// higher and brighter, the other three lower and softer, all on Drip's own note. Morgan, 2026-11-21: "the metronome could be a bit more mellow and maybe
/// slightly easier to differentiate the 1 from the rest of beats" (it was a struck bar, the same
/// on all four).
pub const tick_strength: f32 = 0.3;
pub const tick_ring: f32 = 0.1;
pub const tick_one_strength: f32 = 0.45;
pub const tick_one_ring: f32 = 0.2;

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

/// Fold a circle of fifths index into [-6, 5].
pub fn foldWedge(k: i8) i8 {
    var f: i32 = k;
    while (f > 5) f -= 12;
    while (f < -6) f += 12;
    return @intCast(f);
}

/// The wedge a direction of the right stick points at. The day's note is at the top, the sharp
/// side to the right and the flat side to the left, a twelfth of a turn for each fifth; the five
/// dark wedges are under the horizon. Up on the stick is negative y.
pub fn wedgeAt(rx: f32, ry: f32) i8 {
    const turn = std.math.atan2(rx, -ry); // 0 at the top, clockwise
    const k: i32 = @intFromFloat(@round(turn / (std.math.pi / 6.0)));
    return foldWedge(@intCast(k));
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
/// People let go of a note when they hear the tick, a reaction later (Morgan's first evening: 220 to
/// 360 ms after it). Each breath let go outside the window lets the next be this much later, up to
/// this much in all: a player with poor timing takes longer and still gets there, and is never told
/// of a miss.
pub const breath_slack_step: u64 = 2400;
pub const breath_slack_most: u64 = 9600;
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
/// Underfoot, by how far Hum has walked: dew shed every 0.9 m of lawn. A leaf rings as it is
/// stepped onto (World.newLeaf).
pub const dew_every: f32 = 0.9;

/// The view of the place. Walking: the eye sits far behind Hum and low, looking up a little, so
/// the horizon is low in the frame and Hum is small in it. Stopped at a tall thing's foot, the
/// view does not fit the thing to the screen: the gaze climbs it at the speed of sound, narrowing
/// as it goes, so the ground is lost and the height is paid for in time. A call made there is
/// ridden up: the gaze follows the band of light.
pub const cam_back: f32 = 11.0;
pub const cam_up: f32 = 2.2;
pub const walk_pitch: f32 = 0.24;
pub const place_fov: f32 = 55.0;
pub const lean_back: f32 = 14.0;
pub const lean_up: f32 = 1.0;
/// How many metres of the thing the leaned view frames, top to bottom, and how narrow it may go.
pub const lean_frame: f32 = 30.0;
pub const lean_fov_least: f32 = 13.0;

/// Hum's middle, above its feet: what the view goes round.
pub const hum_mid: f32 = 0.5;
/// The walking view's height round Hum's middle, as seen from it.
pub const walk_rise: f32 = std.math.atan2(cam_up - hum_mid, cam_back);
/// The view's dial, the right stick up and down (spec/engine.md, "The view goes round Hum"): from
/// low at Hum's feet looking up (-1), through the walking view (0, exactly the eye cam_back behind
/// and cam_up high, looking up walk_pitch), to high over Hum looking down on it (+1). At each key,
/// as seen from Hum's middle: how high round it the eye stands (radians), how far away it is, how
/// wide the view is (degrees, top to bottom), and how far above Hum the middle of the frame looks
/// (radians). Between keys the dial goes on one smooth curve that never turns back.
pub const orbit_keys = [_][5]f32{
    .{ -1.0, -0.01396, 9.5, 62.0, 0.4503 },
    .{ 0.0, walk_rise, @sqrt(cam_back * cam_back + (cam_up - hum_mid) * (cam_up - hum_mid)), place_fov, walk_pitch + walk_rise },
    .{ 0.4, 0.4712, 18.5, 53.0, 0.2321 },
    .{ 0.7, 1.1868, 33.0, 50.0, 0.0698 },
    .{ 1.0, std.math.pi / 2.0, 52.0, 45.0, 0.0 },
};
/// The curve's slope at each key, made so that it never overshoots a key (Fritsch and Carlson).
const orbit_slopes: [orbit_keys.len][5]f32 = blk: {
    const k = orbit_keys;
    const n = k.len;
    var out: [n][5]f32 = @splat(@splat(0.0));
    for (1..5) |col| {
        var sec: [n - 1]f32 = undefined;
        for (0..n - 1) |i| sec[i] = (k[i + 1][col] - k[i][col]) / (k[i + 1][0] - k[i][0]);
        out[0][col] = sec[0];
        out[n - 1][col] = sec[n - 2];
        for (1..n - 1) |i| out[i][col] = if (sec[i - 1] * sec[i] <= 0.0) 0.0 else (sec[i - 1] + sec[i]) * 0.5;
        for (0..n - 1) |i| {
            const a = out[i][col] / sec[i];
            const b = out[i + 1][col] / sec[i];
            const r = a * a + b * b;
            if (r > 9.0) {
                const tau = 3.0 / @sqrt(r);
                out[i][col] = tau * a * sec[i];
                out[i + 1][col] = tau * b * sec[i];
            }
        }
    }
    break :blk out;
};

/// One of the dial's columns (1 height round, 2 distance, 3 width, 4 the frame's middle above Hum)
/// at a place on the dial.
pub fn orbitAt(u: f32, col: usize) f32 {
    const k = orbit_keys;
    var i: usize = 0;
    while (i + 2 < k.len and u > k[i + 1][0]) i += 1;
    const h = k[i + 1][0] - k[i][0];
    const s = std.math.clamp((u - k[i][0]) / h, 0.0, 1.0);
    const s2 = s * s;
    const s3 = s2 * s;
    return (2.0 * s3 - 3.0 * s2 + 1.0) * k[i][col] + (s3 - 2.0 * s2 + s) * h * orbit_slopes[i][col] + (3.0 * s2 - 2.0 * s3) * k[i + 1][col] + (s3 - s2) * h * orbit_slopes[i + 1][col];
}

/// The right stick turns the view this fast at most (radians a second), and moves the dial
/// across its whole length in 1.2 s; the stick's push is felt as its part past the dead middle,
/// raised to this power, so a small push is fine and a full one fast. The rate eases to what the
/// stick asks in about 60 ms, and the dial slows over its last part toward either end.
pub const yaw_most: f32 = 2.4;
pub const orbit_most: f32 = 2.0 / 1.2;
pub const look_dead: f32 = 0.15;
pub const look_power: f32 = 1.8;
pub const look_ease: f32 = 0.24;
pub const orbit_soft: f32 = 0.15;

/// How fast the stick asks the view to go, from nought to one, for a push from -1 to 1.
pub fn lookRate(push: f32) f32 {
    const t = std.math.clamp((@abs(push) - look_dead) / (1.0 - look_dead), 0.0, 1.0);
    if (t <= 0.0) return 0.0;
    const r = std.math.pow(f32, t, look_power);
    return if (push < 0.0) -r else r;
}

/// The push that asks for a rate (from nought to one): the scripted player's way of turning.
pub fn pushFor(rate: f32) f32 {
    const r = std.math.clamp(@abs(rate), 0.0, 1.0);
    const push = look_dead + (1.0 - look_dead) * std.math.pow(f32, r, 1.0 / look_power);
    return if (rate < 0.0) -push else push;
}

/// The stick's directions are the view's, taken when the stick is set at least this far and held
/// while it stays within this angle of where it was set: a straight run stays straight while the
/// view swings in behind it. A change, a let-go or a look takes the view's directions again.
pub const latch_least: f32 = 0.5;
pub const latch_within: f32 = 0.26;
/// The follow eases in over this many steps after it starts, and turns this fast at a sprint and
/// while sprinting.
pub const follow_ease_in: f32 = 30.0;
pub const follow_sprint: f32 = 1.6;
/// The view is anchored to the ground under Hum, and to Hum's height only past this much, so a
/// jump never moves it; it follows the ground at this part a step.
pub const base_past: f32 = 6.0;
pub const base_ease: f32 = 0.25;
/// What stands between the eye and Hum (spec/engine.md): the eye keeps this far over its own
/// ground (more over water), and the line from Hum to it clears the ground by this much. It rises
/// to clear the ground quickly and comes down slowly; past this rise round Hum it comes in
/// instead, through these parts of its distance, and goes back out at this many metres a second.
pub const eye_over_ground: f32 = 0.6;
pub const eye_over_water: f32 = 1.5;
pub const line_over_ground: f32 = 0.3;
pub const lift_rise: f32 = 0.25;
pub const lift_fall: f32 = 0.04;
pub const lift_most_rise: f32 = 0.87;
pub const pull_parts = [_]f32{ 1.0, 0.85, 0.7, 0.55, 0.4, 0.25 };
pub const pull_back_speed: f32 = 3.0;
/// In a fight the dial is held at least this high, so the ground round Hum is seen; it rises over
/// a second, and comes down two seconds after the threat has gone, over a second. Out on standing
/// water it is held this high and this much further back; falling faster than a jump ever lands
/// (fall_past_jump of its speed), this high, within 0.4 s, so the landing is seen.
pub const fight_orbit: f32 = 0.4;
pub const fight_linger: u32 = 120;
pub const water_orbit: f32 = 0.4;
pub const water_further: f32 = 3.0;
pub const fall_orbit: f32 = 0.5;
pub const fall_past_jump: f32 = 1.05;
/// L2 tapped with nothing threatening: the view swings in behind Hum in this many steps, the dial
/// back to walking; past recentre_cut away, it cuts on the next eighth of Drip's tick instead.
pub const recentre_steps: u8 = 18;
/// The view's own lifts wait this many steps after the player's hand leaves the right stick.
pub const lifts_after: u32 = 120;
pub const recentre_cut: f32 = 1.745;

pub const Camera = struct { eye: [3]f32, at: [3]f32, up: [3]f32, fov: f32, stand: f32 };

/// The page: the same world seen from above, lying flat. The eye is this high, this far behind.
pub const page_up: f32 = 105.0;
pub const page_back: f32 = 26.0;
pub const page_fov: f32 = 50.0;
/// How fast the page rises when it stands, and how fast it lies down again.
pub const rise_rate: f32 = 0.0045;
pub const fold_rate: f32 = 0.03;
/// R1 held this many steps folds the place back to the page for as long as it is held.
pub const fold_after: u32 = 15;
/// R1 held this long opens the wheel, once the place has stood up (SPEC.md 9): 0.4 s, longer than
/// the longest of Morgan's calls (19 steps), so a call never flicks it open.
pub const wheel_after: u32 = 24;
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
pub const wheel_up: f32 = 32.0;
pub const wheel_back: f32 = 30.0;
/// The pointed wedge is kept until the stick is this far into the next (radians), so a wedge snaps
/// and holds; resting on an awake wedge this many steps, Hum hums its note under its breath, on a
/// voice of its own, a part of its hum's strength, spending no breath: the preview.
pub const wheel_hold: f32 = 0.14;
pub const preview_after: u64 = 9;
pub const preview_voice: u8 = 3;
pub const preview_strength: f32 = 0.3;
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
    y: f32 = 0.0,
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
    /// Whether this ring is an answer to Hum's call returning to Hum
    is_answer: bool = false,
    /// A strike's note carrying (SPEC.md 10): how much more than a placed strike it takes from
    /// each knot it reaches past the fork's own reach, or nought if it is a call.
    wave_more: f32 = 0.0,
    /// Which knots this wave has struck already, one bit each.
    wave_hit: u8 = 0,
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
    /// Hum's breath, in homes (SPEC.md 9): what it holds now, and the most it can hold.
    breath: f32 = @floatFromInt(breath_first),
    breath_most: u8 = breath_first,
    /// Out of breath: nothing that spends it starts again until it is full.
    winded: bool = false,
    /// Steps since anything last spent breath; and the homes walked in the swell now sung.
    quiet_for: u32 = 0,
    walk_homes: u8 = 0,
    /// Hum's height above its ground and how fast it is rising, in the air; and how many
    /// jumps, and when it last landed. Whether the jump button is still held (for variable height).
    hum_y: f32 = 0.0,
    hum_vy: f32 = 0.0,
    /// How the world is answering the chord (law/react.zig), and where on the day's ring the
    /// chord stood when it last answered, so that a change is known for what it was.
    react: react_mod.State = .{},
    react_k: i8 = 0,
    /// How high above the ground whatever Hum stands on is: nought on the ground itself, more on
    /// a leaf, a crumb or the hose. And how high it was when its jump began.
    hum_floor: f32 = 0.0,
    jump_from: f32 = 0.0,
    airborne: bool = false,
    jump_held: bool = false,
    jump_steps: u32 = 0,
    jump_cooldown: u8 = 0,
    jump_can_retrigger: bool = true,
    jumps: u32 = 0,
    landed_at: u64 = 0,
    wheel_minor: bool = false,
    wheel_minor_was: bool = false,
    strike_anim: f32 = 0.0,
    strike_count: u32 = 0,
    /// Hum is against the hose (the scripted player jumps it), and was the step before: a touch
    /// sounds only as it begins.
    at_hose: bool = false,
    /// Sprinting now, how many sprints, how many times the breath ran out and grew.
    sprinting: bool = false,
    sprints: u32 = 0,
    breath_outs: u32 = 0,
    breath_grew: u32 = 0,
    /// How many times Hum has brushed a stalk hard enough to ring it, and the step and aster of the
    /// last, so one brush rings once.
    bumps: u32 = 0,
    bumped_at: u64 = 0,
    bumped_tower: u16 = no_tower,
    /// Drip breathing on its own beside a silent Hum, to show how (it hums from a downbeat for three
    /// beats and lets go on the fourth tick), and how many times it has.
    drip_showing: bool = false,
    drip_shows: u32 = 0,
    /// After showing, Drip rests a bar before it shows again.
    drip_rest_until: u64 = 0,
    drip_state: drip.DripState = .{},
    /// How much later than the window a breath may be let go and still count: grown by misses.
    breath_slack: u64 = 0,
    /// Where a player was held up, for the session's log: when Hum first came beside Drip, when the
    /// view leaned in, when Hum first hummed there; how many breaths were tried and how far the
    /// first sixteen were let go from the tick, in milliseconds (after it is above nought); presses
    /// with no verb yet; knocks before the place stood.
    beside_first_at: u64 = never,
    leaned_first_at: u64 = never,
    hummed_beside_at: u64 = never,
    breaths_tried: u32 = 0,
    breath_offsets: [16]i16 = @splat(0),
    dark_presses: u32 = 0,
    knocked_in_dark: u32 = 0,
    first_jump_at: u64 = never,
    first_sprint_at: u64 = never,
    first_strike_at: u64 = never,
    first_wheel_at: u64 = never,
    /// The step of Drip's last upbeat.
    upbeat_at: u64 = never,
    /// The stalk Hum is against now, if any: a brush rings only as it begins.
    touching: u16 = no_tower,
    /// The reeds, from the reed rule (reeds.zig), each a thing; and what Hum is touching now among
    /// the reeds, the cover's bodies (by their own number), the fallen flower head, Drip and the rim,
    /// so each answers only as the touch begins.
    reed_first: u32 = 0,
    reed_count: u32 = 0,
    /// Whatever solid things Hum is against now (footing.zig), so each answers only as the touch
    /// begins.
    touches: [footing.most_touches]footing.Touch = @splat(.{}),
    touching_rim: bool = false,
    /// The wheel: when the pointed wedge was entered, and the wedge being hummed under Hum's breath.
    wheel_point_since: u64 = 0,
    previewing: ?i8 = null,
    /// Skidding round: braking before it turns.
    skidding: bool = false,
    skids: u32 = 0,
    /// A jump pressed early, steps left for it to land in; and steps since Hum last stood.
    jump_wanted: u32 = 0,
    stood_ago: u32 = 0,
    /// A burst (the dodge, a knock-back): metres a second, and steps left of it.
    burst_x: f32 = 0.0,
    burst_z: f32 = 0.0,
    burst_left: u32 = 0,
    dashes: u32 = 0,
    /// Drip out showing the way: 0 on Hum's head, 1 hopping over the coil, 2 waiting beyond it.
    drip_out: u8 = 0,
    /// Drip's lead: how many of the next things Hum has found, and the last lead's moment and place.
    found: u8 = 0,
    /// The first meeting with the knots: until when time is thick by itself.
    first_meet_until: u64 = 0,
    hint_at: u64 = 0,
    knots_met: bool = false,
    lead_at: u64 = 0,
    lead_step: u64 = 0,
    lead_x: f32 = 0.0,
    lead_z: f32 = 0.0,
    drip_shown: bool = false,
    drip_out_from: u64 = 0,
    drip_from_x: f32 = 0.0,
    drip_from_z: f32 = 0.0,
    wave_hits: u32 = 0,
    /// The sideways pull of Hum's turning, eased: it leans into a turn.
    lean_x: f32 = 0.0,
    lean_z: f32 = 0.0,
    was: u16 = 0,
    singing: bool = false,
    view: View = .page,
    /// Which way the view looks round Hum.
    look_yaw: f32 = 0.0,
    /// The view's dial (orbit_keys): -1 low at Hum's feet, 0 walking, 1 high over Hum.
    orbit: f32 = 0.0,
    /// How fast the right stick is turning the view and moving the dial, eased.
    yaw_v: f32 = 0.0,
    orbit_v: f32 = 0.0,
    /// The height the view is anchored at (base_past), eased.
    view_base: f32 = 0.0,
    view_based: bool = false,
    /// How far the eye has risen over the ground between it and Hum, and how far in it has come
    /// (1 is not at all).
    eye_lift: f32 = 0.0,
    eye_pull: f32 = 1.0,
    /// Eased run factor (0 at rest, 1 at run_speed, up to sprint_speed/run_speed) for camera
    /// pullback and FOV so bumping a solid never jolts the camera.
    view_run: f32 = 0.0,
    /// The view lifted over a fight and over a long fall, 0 to 1; steps left before the fight's
    /// lift comes down.
    fight_view: f32 = 0.0,
    fight_after: u32 = 0,
    fall_view: f32 = 0.0,
    /// The stick's directions (latch_within): the view's way when the stick was set, and where
    /// the stick was set.
    stick_yaw: f32 = 0.0,
    stick_set: f32 = 0.0,
    stick_latched: bool = false,
    /// How far the view's own lifts (a fight, standing water, a fall) are on: off while the player
    /// holds the right stick, back on after it has rested lifts_after steps.
    lifts_on: f32 = 1.0,
    /// The follow, eased in from its start, 0 to 1.
    follow_in: f32 = 0.0,
    /// L2's recentre: steps left of its swing, from where and by how much; or a cut waiting for
    /// the eighth of Drip's tick after this one.
    recentre_left: u8 = 0,
    recentre_from: f32 = 0.0,
    recentre_by: f32 = 0.0,
    recentre_orbit: f32 = 0.0,
    recentre_eighth: u64 = 0,
    recentre_cutting: bool = false,
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
    /// The fallen leaf Hum last stood on, by its square.
    leaf_cell: [2]i32 = .{ std.math.maxInt(i32), std.math.maxInt(i32) },
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
    spigot_thing: u32 = no_thing,
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
        // the two locked before the morning began, and the place has been met: Drip has shown
        // the way out and led to what is near
        self.locked_at = 0;
        self.hold_until = 0;
        self.drip_shown = true;
        self.found = 2;
        self.knots_met = true;
    }

    /// The first evening, from its first second: the same field, in the dark, as a page. Drip
    /// is out there ticking, and nothing stands up until the two have breathed together.
    pub fn initEvening(self: *World) void {
        self.initField();
        self.stand = 0.0;
        self.dawn = 0.0;
        self.knot_count = 0; // Peaceful garden: knots delayed until explored!
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
        self.things[at] = .{ .x = garden_place.fallen_x, .y = garden_place.fallen_y, .z = garden_place.fallen_z, .tall = garden_place.fallen_tall, .hz = garden_hz * 0.5, .ring = 5.5 };
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
        // the bee: 1.3 m long, humming the garden's note an octave up, as a small thing does. There
        // it is over the speaker's floor and heard whole: under it, the speaker would add its twelfth,
        // the G of Drip's tick, and every time the bee flew past, its bent twelfth would rub against
        // the tick for seconds (spec/laws.md, For the ears)
        const bee_thing = at;
        self.things[at] = .{ .y = flyers.Bee.over_clover, .tall = 0.65, .hz = garden_hz * 2.0, .family = .skin, .ring = 0.4, .carry = flyers.Bee.carry };
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
        // the spigot: a brass tap at the hose's head, a small bell of a thing, two octaves over the
        // garden's note; it answers what is kin to it, and rings when it is touched
        self.spigot_thing = at;
        self.things[at] = .{ .x = land.spigot[0], .y = land.spigot[2] * 0.5, .z = land.spigot[1], .tall = land.spigot[2], .hz = garden_hz * 4.0, .family = .bell, .ring = 3.0, .carry = 110.0 };
        at += 1;
        // the reeds round the pool: each an open pipe as long as it is tall (reeds.zig)
        self.reed_first = at;
        for (0..reeds.groups) |rg| {
            for (0..reeds.each) |rk| {
                const reed = reeds.at(rg, rk) orelse continue;
                self.things[at] = .{ .x = reed.x, .y = reed.tall * 0.5, .z = reed.z, .tall = reed.tall, .hz = reeds.note(reed.tall, garden_hz), .family = .open_pipe, .ring = 0.45, .carry = 90.0 };
                at += 1;
            }
        }
        self.reed_count = at - self.reed_first;
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
                    .ring_on_the_ground => _ = self.startRing(self.hum_x, self.hum_z, what.sound.hz, true, if (self.cover == .moss) moss_carries else 1.0),
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
                if (what.light.shape == .ring_on_the_ground) {
                    const r_idx = self.startRing(thing.x, thing.z, what.sound.hz, false, 1.0);
                    self.rings[r_idx].is_answer = true;
                }
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
    fn startRing(self: *World, x: f32, z: f32, hz: f32, own: bool, strength: f32) usize {
        var oldest: usize = 0;
        for (self.rings, 0..) |r, i| {
            if (!r.live) {
                oldest = i;
                break;
            }
            if (r.born < self.rings[oldest].born) oldest = i;
        }
        const y = if (own) self.hum_y else 0.0;
        self.rings[oldest] = .{ .x = x, .y = y, .z = z, .born = self.step, .live = true, .hz = hz, .own = own, .strength = strength, .ground = self.groundAt(x, z) };
        return oldest;
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

    /// How brightly the figure between Hum and Drip is drawn: it is their two notes beating (law 5),
    /// so it is there only while both sound, and still once they have locked.
    pub fn figureLight(self: *const World) f32 {
        if (self.locked_at != never) return 1.0;
        if (self.drip_humming or self.step < self.hold_until) return 0.85;
        return 0.0;
    }

    pub fn besideDrip(self: *const World) bool {
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

        // the world answers the chord as it stands (harmony.zig): before anything moves, so that
        // what has risen is where Hum's feet find it
        harmony.step(self);

        // Hum walks. Stood in as a place, "up" on the stick is away from the eye.
        const mx = @as(f32, @floatFromInt(hands.lx)) * (1.0 / 127.0);
        const mz = @as(f32, @floatFromInt(hands.ly)) * (1.0 / 127.0);
        const size = @sqrt(mx * mx + mz * mz);
        // on the page the face buttons have no verb yet; a press is still answered, softly, so a
        // hand finding its buttons in the dark is never met with nothing
        if (self.stand < 1.0 and self.view == .place and pressed & (Hands.jump | Hands.dodge | Hands.strike | Hands.grab) != 0) {
            self.dark_presses +|= 1;
            const at = Place{ .x = self.hum_x, .y = self.hum_y + 0.3, .z = self.hum_z };
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = self.home_hz * 2.0, .strength = 0.05, .ring = 0.12 }, .glow));
            self.hum_light = @max(self.hum_light, 0.35);
        }
        if (self.jump_cooldown > 0) self.jump_cooldown -= 1;
        if (hands.buttons & Hands.jump == 0) self.jump_can_retrigger = true;
        self.strike_anim = @max(0.0, self.strike_anim - dt * 5.0);

        // Opening cinematic beats (Section 1.2: rhythm as first musical concept)
        if (self.in_garden and !self.drip_met and self.stand == 0.0) {
            // Beat 2: Step 120 (2.0s): First teal drop falls with G4 (392 Hz = garden_hz * 1.5).
            if (self.step == 120) {
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = garden_hz * 1.5, .strength = 0.55, .ring = 1.0 }, .glow));
                _ = self.startRing(drip_x, drip_z, garden_hz * 1.5, false, 0.9);
            }
            // Beat 4: Step 240 (4.0s): Second teal drop falls, interval established.
            if (self.step == 240) {
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = garden_hz * 1.5, .strength = 0.55, .ring = 1.0 }, .glow));
                _ = self.startRing(drip_x, drip_z, garden_hz * 1.5, false, 0.9);
            }
        }

        // Knots: off by default until Piece 8 designs when they appear (SPEC.md 6.1: "knots do not arrive until after a peaceful stretch... knots hear Hum only once both are found")
        // self.knot_count = 0; // Peaceful garden: knots delayed until explored!

        // the bottom face: on the ground a jump (SM64 x TotK standard: snappy, weighty, non-floaty)
        if (self.jump_wanted > 0) self.jump_wanted -= 1;
        const landing_soon = self.airborne and self.hum_vy < 0.0 and self.hum_y - self.hum_floor < jump_early_height;
        const can_coyote = self.stood_ago > 0 and self.stood_ago <= jump_late and self.hum_vy <= 0.0;
        const wants_jump = (pressed & Hands.jump != 0 and self.jump_can_retrigger) or (self.jump_wanted > 0 and !self.airborne);
        if (pressed & Hands.jump != 0 and self.jump_can_retrigger and self.view == .place and self.stand >= 1.0 and landing_soon) {
            // falling, just over the ground: buffer the next jump on landing
            self.jump_wanted = jump_early;
            self.jump_can_retrigger = false;
        } else if (wants_jump and self.view == .place and self.stand >= 1.0 and (!self.airborne or can_coyote) and (self.jump_cooldown == 0 or self.jump_wanted > 0)) {
            self.jump_wanted = 0;
            self.jump_can_retrigger = false;
            self.airborne = true;
            self.jump_held = true;
            self.jump_steps = 0;
            self.hum_vy = jumpSpeedNow();
            self.jump_from = self.hum_y;
            self.jumps += 1;
            self.stood_ago = jump_late + 1;
            if (self.first_jump_at == never) self.first_jump_at = self.step;
            // the push off: a short note a fifth over home, and Hum flares
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = self.home_hz * 1.5, .strength = 0.12, .ring = 0.2 }, .glow));
        }
        // variable jump: if jump button is released early while still rising, cut upward speed for a low hop (SM64 × TotK standard)
        if (self.jump_held) {
            if (hands.buttons & Hands.jump == 0) {
                self.jump_held = false;
                const rem = jump_tap_height - (self.hum_y - self.jump_from);
                if (rem > 0.0) {
                    const v_needed = @sqrt(2.0 * fallPullNow() * rem);
                    if (self.hum_vy > v_needed) self.hum_vy = v_needed;
                } else if (self.hum_vy > 0.0) {
                    self.hum_vy = 0.0;
                }
            } else if (self.hum_vy <= 0.0) {
                self.jump_held = false;
            }
        }

        // Hum's legs: the stick says where and how fast, and the body gets there quickly but not at
        // once, turns at a rate, and skids a little when let go
        var want_x: f32 = 0.0;
        var want_z: f32 = 0.0;
        // the sprint: the right face held while walking, if nothing threatens and there is breath
        const sprint_now = hands.held(Hands.dodge) and size > 0.12 and !self.winded and !self.airborne and self.view == .place and self.stand >= 1.0 and !self.threatened();
        if (sprint_now and !self.sprinting) {
            self.sprints += 1;
            if (self.first_sprint_at == never) self.first_sprint_at = self.step;
        }
        self.sprinting = sprint_now;
        // the stick's directions: the view's, taken when the stick is set and held while it stays
        // where it was set (latch_within)
        {
            const stick_at = std.math.atan2(mx, -mz);
            var off = stick_at - self.stick_set;
            if (off > std.math.pi) off -= 2.0 * std.math.pi;
            if (off < -std.math.pi) off += 2.0 * std.math.pi;
            const steady = self.stick_latched and size >= latch_least and @abs(off) < latch_within and self.looked_ago > 0;
            if (!steady) {
                self.stick_yaw = self.look_yaw;
                self.stick_set = stick_at;
                self.stick_latched = size >= latch_least;
            }
        }
        if (size > stick_dead) {
            const push = std.math.clamp((size - stick_dead) / (stick_full - stick_dead), 0.0, 1.0);
            var top: f32 = if (self.sprinting) feel.now.sprint_speed else feel.now.run_speed;
            if (chords_tryout and self.home_k == 1) top *= feel.now.lean_speed;
            var wx = mx;
            var wz = mz;
            if (self.view == .place) {
                const cy = @cos(self.stick_yaw);
                const sy = @sin(self.stick_yaw);
                wx = cy * mx - sy * mz;
                wz = sy * mx + cy * mz;
            }
            // slopes pull: the ground a metre ahead along the way the stick asks
            if (self.view == .place and self.in_garden and !self.airborne) {
                const ux = wx / size;
                const uz = wz / size;
                const rise = self.groundAt(self.hum_x + ux, self.hum_z + uz) - self.groundAt(self.hum_x, self.hum_z);
                const sine = rise / @sqrt(1.0 + rise * rise);
                top = if (sine > 0.0) top * @max(0.0, 1.0 - uphill_pull * sine) else @min(@max(top, downhill_most), top * (1.0 - downhill_push * sine));
            }
            const scale = std.math.pow(f32, push, stick_power) / size * top;
            want_x = wx * scale;
            want_z = wz * scale;
            // the wheel open: time thickens, and Hum's legs with it
            if (self.wheel_open) {
                want_x *= thick;
                want_z *= thick;
            }
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
        var ease: f32 = if (size > 0.12) go_ease else stop_ease;
        if (self.airborne) {
            // generous air steering (SM64 × TotK): the stick steers Hum's velocity in the air
            if (size <= 0.12) {
                want_x = self.hum_vx;
                want_z = self.hum_vz;
            }
            ease = air_ease;
        }
        const leg_sp = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
        const want_sp = @sqrt(want_x * want_x + want_z * want_z);
        if (!self.airborne and size > stick_dead and leg_sp > 0.5 and want_sp > 0.01) {
            // on its legs, Hum's speed and way are apart: a turn bends the way and keeps the speed,
            // and the speed comes in two stages
            var leg_gap = std.math.atan2(want_x, -want_z) - std.math.atan2(self.hum_vx, -self.hum_vz);
            if (leg_gap > std.math.pi) leg_gap -= 2.0 * std.math.pi;
            if (leg_gap < -std.math.pi) leg_gap += 2.0 * std.math.pi;
            if (!self.skidding and @abs(leg_gap) > skid_turn and leg_sp > skid_least) {
                // pulled right round at speed: a skid, sounded by the ground it is on
                self.skidding = true;
                self.skids += 1;
                const skid_at = Place{ .x = self.hum_x, .y = 0.1, .z = self.hum_z };
                const skid_family: sound.Family = if (self.cover == .leaves) .bar else .skin;
                const skid_strength: f32 = if (self.cover == .moss) 0.03 else 0.08;
                self.tell(.{ .at = skid_at }, cues_mod.Cue.of(.{ .kind = .strike, .family = skid_family, .hz = self.home_hz * 0.5, .strength = skid_strength, .ring = 0.12 }, .glow));
            }
            var new_sp = leg_sp;
            var leg_by: f32 = 0.0;
            if (self.skidding) {
                new_sp = @max(0.0, leg_sp - skid_brake * dt);
                if (new_sp < skid_done) {
                    self.skidding = false;
                    leg_by = leg_gap;
                }
            } else {
                const over = std.math.clamp((leg_sp - run_speed) / (sprint_speed - run_speed), 0.0, 1.0);
                const radius = turn_radius_run + (turn_radius_sprint - turn_radius_run) * over;
                const leg_rate = @min(turn_slow, leg_sp / radius);
                leg_by = std.math.clamp(leg_gap, -leg_rate * dt, leg_rate * dt);
                const climb: f32 = if (self.sprinting) sprint_climb else run_climb;
                if (want_sp <= leg_sp) {
                    new_sp = leg_sp + (want_sp - leg_sp) * go_ease;
                } else if (leg_sp < quick_speed) {
                    new_sp = @min(want_sp, leg_sp + (@min(want_sp, quick_speed + 0.3) - leg_sp) * go_ease);
                } else {
                    new_sp = @min(want_sp, leg_sp + climb * dt);
                }
            }
            const ux = self.hum_vx / leg_sp;
            const uz = self.hum_vz / leg_sp;
            const c_ = @cos(leg_by);
            const s_ = @sin(leg_by);
            self.hum_vx = (ux * c_ - uz * s_) * new_sp;
            self.hum_vz = (ux * s_ + uz * c_) * new_sp;
        } else {
            if (!self.airborne) self.skidding = false;
            // from rest, the way at once and the first stage of the speed
            if (!self.airborne and size > stick_dead and want_sp > quick_speed + 0.3) {
                const k = (quick_speed + 0.3) / want_sp;
                want_x *= k;
                want_z *= k;
            }
            self.hum_vx += (want_x - self.hum_vx) * ease;
            self.hum_vz += (want_z - self.hum_vz) * ease;
        }
        if (!self.airborne and size <= 0.12 and self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz < 0.0025) {
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
        // a burst (the dodge, a knock-back) goes through the same move, so what is solid stops it
        if (self.burst_left > 0) {
            self.burst_left -= 1;
            go_x += self.burst_x * dt;
            go_z += self.burst_z * dt;
        }
        // on the water, the water has its say in where a step goes
        if (self.view == .place and self.pool_count > 0) self.onWater(&go_x, &go_z);
        if (self.view == .place) self.atShore(&go_x, &go_z);
        if (self.view == .place) self.atRim(&go_x, &go_z);
        // whatever is solid stops the step, whatever kind of thing it is (footing.zig)
        if (self.view == .place) footing.against(self, &go_x, &go_z);
        const height_was = self.hum_ground + self.hum_y;
        self.hum_x += go_x;
        self.hum_z += go_z;
        self.hum_ground = self.groundAt(self.hum_x, self.hum_z);
        // what is under its feet here and over its head: the ground, or something solid on it
        const footed: footing.Stand = if (self.view == .place) footing.under(self, height_was) else .{ .floor = self.hum_ground, .roof = footing.no_roof };
        self.hum_floor = @max(0.0, footed.floor - self.hum_ground);
        if (!self.airborne and height_was - (self.hum_ground + self.hum_floor) > step_up) {
            // walked off an edge: begin falling with coyote time
            self.airborne = true;
            self.hum_y = height_was - self.hum_ground;
            self.hum_vy = 0.0;
            self.stood_ago = 1;
        } else if (!self.airborne) {
            // on its feet it follows what it stands on, up a step or down one
            self.hum_y = self.hum_floor;
            self.stood_ago = 0;
        } else if (self.stood_ago > 0) {
            self.stood_ago += 1;
        }
        if (self.airborne) self.flyStep(height_was, footed.roof);
        const moved = if (self.airborne) 0.0 else @sqrt(go_x * go_x + go_z * go_z);
        if (moved > 0.0005 and self.view == .place and self.stand >= 1.0) self.underfoot(moved);
        if (self.view == .place and self.pool_count > 0) self.crossings();
        if (self.view == .place) self.cover = ground.underfootAt(self.hum_x, self.hum_z);
        if (self.view == .place) {
            // the hinge: the world is a page until it stands, and holding R1 lays it down again
            self.call_held = if (hands.held(Hands.call)) self.call_held +| 1 else 0;
            self.wheelStep(hands);
            // the first time the knots come close, time thickens by itself for a bar, so there is
            // a moment to see them and their pulses before anything is asked
            const meeting = self.step < self.first_meet_until;
            const pace: f32 = if (self.wheel_open or meeting) thick else if (self.step < self.pocket_until) knots.pocket else 1.0;
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
            // the try-out: L1 steps the chord flatward and L2 sharpward, wherever Hum is
            if (chords_tryout and self.stand >= 1.0 and !self.wheel_open and !self.swelling()) {
                var dir: i8 = 0;
                if (pressed & Hands.voice != 0) dir = -1;
                if (pressed & Hands.guard != 0) dir = 1;
                if (dir != 0) self.chordStep(dir, hands.stamp);
                tryout.highest = @max(tryout.highest, self.hum_y);
                tryout.fastest = @max(tryout.fastest, @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz));
            }
            self.look(hands, pressed);
        }

        // L1 and R1 together: the clap (SPEC.md 8). Wherever Hum is and whatever it is doing, as the
        // hands have already sounded it
        if (pressed & Hands.clap != 0) self.clap();

        // the right face dodges: a quick step aside, and on the beat a lunge lands on, the pocket
        if (self.view == .place and self.stand >= 1.0 and pressed & Hands.dodge != 0) {
            if (self.threatened()) self.dodge() else self.dash();
        }

        // the left face strikes with Hum's fork (SPEC.md 10):
        // fires at once on press with zero input delay. Timed strikes near the beat ring fuller
        // with fork_octave and bonus drain; untimed strikes ring plain fork immediately.
        if (self.canStrike() and pressed & Hands.strike != 0) {
            const at = self.beatAt(hands.stamp);
            const in_pocket = self.step < self.pocket_until;
            const timed = in_pocket or at.from_beat <= self.widen(strike_window);
            self.strike_due = never;
            self.strike(at.pos, timed);
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
            self.tell(.hum, cues_mod.Cue.of(callSound(self.home_hz, self.cover), .ring_on_the_ground));
            self.own_now = sound.own_world;
        }

        // singing: Hum's one note for as long as R2 is held, and Hum swelling for as long. Beside
        // Drip, it hums with you. While a lock holds, both notes hold by themselves.
        const holding = self.step < self.hold_until;
        if (pressed & Hands.sing != 0 and !holding and self.winded) {
            // winded: no note. The hands may already have started one on the sound's own thread
            self.own_now = sound.own_hands;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = self.home_hz, .strength = 0.0, .ring = 0.0 }, .dims));
            self.own_now = sound.own_world;
        }
        if (pressed & Hands.sing != 0 and !holding and !self.winded) {
            self.walk_homes = 0;
            self.swell_from = self.home_k;
            self.swell_bars = 0;
            self.swell_steered = false;
            self.swell_leaned = false;
            self.drip_state.wake();
            self.own_now = sound.own_hands;
            self.tell(.hum, cues_mod.Cue.of(humSound(self.home_hz), .swell));
            self.own_now = sound.own_world;
            if (self.besideDrip()) {
                if (self.hummed_beside_at == never) self.hummed_beside_at = self.step;
                self.drip_humming = true;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = drip_along, .ring = 0.0 }, .swell));
            }
        }
        if (released & Hands.sing != 0 and !holding and self.singing) {
            var locking = false;
            if (self.drip_humming) {
                // letting go on its tick is a breath together, and each one brings its note truer.
                // Letting go off the tick is nothing: no penalty, and nobody says so.
                const off = self.afterHeardTick(self.own_at);
                const early = self.widen(@floatFromInt(breath_window * samples_per_step));
                const late = early + @as(f64, @floatFromInt(self.breath_slack));
                const on_it = @as(f64, @floatFromInt(off)) >= -early and @as(f64, @floatFromInt(off)) <= late;
                if (self.breaths_tried < self.breath_offsets.len) self.breath_offsets[self.breaths_tried] = @intCast(std.math.clamp(@divTrunc(off, 48), -32000, 32000));
                self.breaths_tried +|= 1;
                if (on_it and self.breaths < breaths_to_lock) {
                    self.breaths += 1;
                    locking = self.breaths == breaths_to_lock;
                } else if (!on_it) {
                    self.breath_slack = @min(self.breath_slack + breath_slack_step, breath_slack_most);
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
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = drip_along, .ring = 0.0 }, .swell));
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
        if (self.swelling()) self.swellStep(hands, pressed);
        self.breathStep();
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
        self.guideStep();
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
            // a strike's note carrying: each knot it reaches past the fork's reach is struck as it
            // arrives, late by its distance and the weaker for it, drained by where its pulse is then
            if (ring.wave_more > 0.0) {
                const bar: f64 = @floatFromInt(4 * tick_every);
                for (self.knots[0..self.knot_count], 0..) |*kn, ki| {
                    if (kn.home) continue;
                    const bit = @as(u8, 1) << @intCast(ki);
                    if (ring.wave_hit & bit != 0) continue;
                    const kx = kn.x - ring.x;
                    const kz = kn.z - ring.z;
                    const d = @sqrt(kx * kx + kz * kz);
                    if (d > reach) continue;
                    ring.wave_hit |= bit;
                    if (d <= knots.strike_reach) continue;
                    const weaker = 1.0 - 0.6 * std.math.clamp((d - knots.strike_reach) / (wave_reach - knots.strike_reach), 0.0, 1.0);
                    const cycle = knots.cycleSteps(bar, self.home_hz, kn.root_hz);
                    const at = @as(f64, @floatFromInt(self.clock)) + @as(f64, self.clock_part);
                    const take = ring.wave_more * weaker * knots.drainAt(kn, @max(0.0, at - @as(f64, @floatFromInt(kn.phase_from))), cycle, self.widen(knots.meet_window));
                    kn.colour = @max(0.0, kn.colour - take);
                    self.wave_hits += 1;
                    for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.25 + take, .ring = 0.6 }, .glow));
                }
            }
            if (!ring.own) {
                // an answer on its way: it lights what it passes, and it reaches Hum
                const hx = self.hum_x - ring.x;
                const hz = self.hum_z - ring.z;
                const to_hum = @sqrt(hx * hx + hz * hz);
                if (ring.is_answer and to_hum > before and to_hum <= reach and !self.answered and self.calls >= 2) {
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
            self.tell(.hum, cues_mod.Cue.of(humSound(self.home_hz), .swell));
        }
        if (self.drip != no_thing and (self.drip_humming or holding)) {
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = drip_along, .ring = 0.0 }, .swell));
        }
        // standing water sings again at its next turn
        for (self.pools[0..self.pool_count]) |*p| p.sent = .{ 0.0, 0.0 };
    }

    /// Home moves to a lit wedge: Hum's note, and so what everything is to Hum, changes at once
    /// (spec/laws.md, law 2). Only a wedge whose mood is awake can be home.
    pub fn moveHome(self: *World, k: i8) bool {
        if (k < lit_least or k > lit_most) return false;
        if (!self.isAwake(k)) return false;
        const was = self.home_k;
        self.home_k = k;
        self.home_hz = wedgeHz(self.day_hz, k);
        // home moving is told, whichever hand moved it: Hum sings the new note, and its light
        if (k != was) self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork_octave, .hz = self.home_hz, .strength = 0.16, .ring = 0.6 }, .glow));
        return true;
    }

    /// The try-out's step of the chord (design/the-game.md, "The hands"): one cell flatward or
    /// sharpward among the lift, home and the lean, at once. The chord sounds as its root and fifth
    /// under Hum, what is kin to it near Hum lights and the nearest few answer (law 1), and a step
    /// made on Drip's tick is fuller. Stepping home off the lean throws Hum the way it is going.
    pub fn chordStep(self: *World, dir: i8, stamp: u16) void {
        const from = self.home_k;
        const to: i8 = std.math.clamp(from + dir, @as(i8, -1), @as(i8, 1));
        if (to == from or !self.isAwake(to)) {
            // the end of what is awake: a dull knock with no pitch, as the wheel gives
            tryout.knocks += 1;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = garden_hz * 0.5, .strength = 0.04, .ring = 0.04 }, .dims));
            return;
        }
        const timed = self.beatAt(stamp).from_beat <= self.widen(strike_window);
        if (!self.moveHome(to)) return;
        tryout.steps += 1;
        if (timed) tryout.timed += 1;
        tryout.changed_at = self.step;
        self.drip_state.wake();
        // the chord under Hum: its root an octave below the wedge's note and the fifth over that,
        // struck and dying away; on the tick the octave too, and all of it fuller
        const full: f32 = if (timed) 1.0 else 0.7;
        const low = self.home_hz * 0.5;
        const parts = [3]f32{ 1.0, 1.5, 2.0 };
        const n: usize = if (timed) 3 else 2;
        for (parts[0..n], 0..) |ratio, i| {
            const at = Place{ .x = self.hum_x, .y = self.hum_y + 0.6 + 0.4 * @as(f32, @floatFromInt(i)), .z = self.hum_z };
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = low * ratio, .strength = (0.22 - 0.04 * @as(f32, @floatFromInt(i))) * full, .ring = chord_rings }, .glow));
        }
        self.wakeKin(full);
        self.hum_light = @max(self.hum_light, 0.6 * full);
        if (to == 1) tryout.leaned_from = self.step;
        if (from == 1 and to == 0) {
            // the full close: what the lean wound up lets go, the way Hum is going (or faces)
            const leaned: f32 = if (tryout.leaned_from == never) 0.0 else @floatFromInt(@min(self.step - tryout.leaned_from, launch_full_after));
            const wound = @max(leaned / @as(f32, @floatFromInt(launch_full_after)), 1.0 / 3.0);
            const going = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
            const dx = if (going > 1.0) self.hum_vx / going else @sin(self.hum_face);
            const dz = if (going > 1.0) self.hum_vz / going else -@cos(self.hum_face);
            const speed = feel.now.launch_far * wound * (if (timed) @as(f32, 1.25) else 1.0) / (@as(f32, @floatFromInt(launch_steps)) * dt);
            self.burst_x = dx * speed;
            self.burst_z = dz * speed;
            self.burst_left = launch_steps;
            tryout.launches += 1;
        }
    }

    /// What is in the chord wakes (design/the-game.md, rule 2), as the try-out shows it: every
    /// thing near Hum that is kin to the chord's note lights, and the nearest few of them sound,
    /// softly and briefly. A call's ring on the ground would do the same for the whole garden, and
    /// stepping chord after chord that piles up into roughness (measured with the ears, 2026-11-25:
    /// rough for 47% of a scripted run against 12% without it), so this is a small answer.
    fn wakeKin(self: *World, full: f32) void {
        var nearest: [chord_kin_sound]u32 = @splat(no_thing);
        var nearest_far: [chord_kin_sound]f32 = @splat(std.math.floatMax(f32));
        var nearest_kin: [chord_kin_sound]f32 = @splat(0.0);
        for (self.things[0..self.thing_count], 0..) |*thing, index| {
            if (!thing.sounds) continue;
            if (index == self.bee.thing or index == self.drip) continue;
            if (self.pool_first != no_thing and index >= self.pool_first and index < self.pool_first + self.pool_count) continue;
            const dx = thing.x - self.hum_x;
            const dz = thing.z - self.hum_z;
            const far = @sqrt(dx * dx + dz * dz);
            if (far > chord_kin_reach) continue;
            const rec = sound.recipe(thing.family);
            const kin = sympathy(self.home_hz, thing.hz, rec.mult, rec.gain);
            if (kin < chord_kin_least) continue;
            // keep the nearest few, nearest first
            var at: usize = chord_kin_sound;
            while (at > 0 and far < nearest_far[at - 1]) at -= 1;
            if (at == chord_kin_sound) continue;
            var j: usize = chord_kin_sound - 1;
            while (j > at) : (j -= 1) {
                nearest[j] = nearest[j - 1];
                nearest_far[j] = nearest_far[j - 1];
                nearest_kin[j] = nearest_kin[j - 1];
            }
            nearest[at] = @intCast(index);
            nearest_far[at] = far;
            nearest_kin[at] = kin;
        }
        for (nearest, nearest_far, nearest_kin) |index, far, kin| {
            if (index == no_thing) continue;
            const thing = &self.things[index];
            const strength = 0.12 * full * kin / (1.0 + (far / 40.0) * (far / 40.0));
            self.tell(.{ .thing = @intCast(index) }, cues_mod.Cue.of(.{ .kind = .strike, .family = thing.family, .hz = thing.hz, .strength = strength, .ring = @min(thing.ring, 0.6) }, .glow));
            thing.rung_at = @truncate(self.step);
        }
    }

    /// Whether a lit wedge's mood is awake.
    pub fn isAwake(self: *const World, k: i8) bool {
        if (k < lit_least or k > lit_most) return false;
        return self.awake & (@as(u8, 1) << @intFromEnum(moodOf(k))) != 0;
    }

    /// The door a grey creature leans toward: the nearer awake of a fifth up (the amen) and a fifth
    /// down (the full close), the amen first.
    pub fn doorSide(self: *const World) i8 {
        if (self.isAwake(self.home_k + 1)) return 1;
        if (self.isAwake(self.home_k - 1)) return -1;
        return 1;
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

    /// How much bigger than itself Hum is drawn: a little while it sings, and a little more each
    /// bar of the swell (SPEC.md 9).
    pub fn humSwell(self: *const World) f32 {
        return if (self.singing) 1.2 + 0.05 * @as(f32, @floatFromInt(self.swell_bars)) else 1.0;
    }

    /// R2 held after the lock: the swell, when the right stick nudges home and does not look.
    pub fn swelling(self: *const World) bool {
        return self.singing and self.locked_at != never and self.step >= self.hold_until;
    }

    /// While R2 is held after the lock: a bar grown at each downbeat, and a tap of L1/L2 (or nudge
    /// of the right stick) near one walks home a wedge flatward or sharpward, if that mood is awake.
    fn swellStep(self: *World, hands: Hands, pressed: u16) void {
        const k = self.clock / tick_every;
        if (k % 4 == 0 and tickStep(k) == self.clock and self.downbeat_beat != self.clock) {
            self.downbeat_beat = self.clock;
            self.downbeat_at = self.step;
            if (self.swell_bars < swell_most) {
                self.swell_bars += 1;
                // Continuous feedback while R2 is held (GameguyPage standard):
                // Entering chord voices each bar: root, fifth, third, seventh, ninth
                const chord_ratios = [_]f32{ 1.0, 1.5, 1.25, 1.75, 2.25 };
                if (self.swell_bars <= chord_ratios.len) {
                    const r = chord_ratios[self.swell_bars - 1];
                    const at = Place{ .x = self.hum_x, .y = 1.0 + 0.15 * @as(f32, @floatFromInt(self.swell_bars)), .z = self.hum_z };
                    self.tell(.{ .at = at }, cues_mod.Cue.of(.{
                        .kind = .strike,
                        .family = .string,
                        .hz = self.home_hz * r,
                        .strength = 0.10 + 0.03 * @as(f32, @floatFromInt(self.swell_bars)),
                        .ring = 1.4,
                    }, .glow));
                    self.hum_light = @max(self.hum_light, 0.4 + 0.1 * @as(f32, @floatFromInt(self.swell_bars)));
                }
            }
            // Gentle leans for you: a swell held a bar without steering, and home drifts beside the
            // nearest grey creature on its amen side (design/the-wheel.md, "Gentle and fierce")
            if (!self.fierce and !self.swell_steered and !self.swell_leaned and self.swell_bars >= 2) {
                if (self.nearestGrey()) |g| {
                    const amen_side: i8 = wedgeOfHz(self.day_hz, self.knots[g].root_hz) + 1;
                    self.swell_leaned = true;
                    if (self.home_k != amen_side and self.moveHome(amen_side)) {
                        self.leans_for_you += 1;
                        self.own_now = sound.own_only;
                        self.tell(.hum, cues_mod.Cue.of(humSound(self.home_hz), .swell));
                        self.own_now = sound.own_world;
                    }
                }
            }
        }
        var step_dir: i8 = 0;
        // Swell stepping via bumper buttons: L1 (voice) = flatward (-1), L2 (guard) = sharpward (+1)
        if (pressed & Hands.voice != 0) step_dir = -1;
        if (pressed & Hands.guard != 0) step_dir = 1;
        const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
        if (step_dir == 0 and !self.nudge_out and @abs(rx) >= nudge_least) {
            self.nudge_out = true;
            step_dir = if (rx > 0.0) @as(i8, 1) else -1;
        }
        if (self.nudge_out and @abs(rx) < nudge_back) self.nudge_out = false;
        if (step_dir != 0) {
            if (self.nearDownbeat(self.clock)) {
                self.swell_steered = true;
                const from = self.home_k;
                const to: i8 = self.home_k + step_dir;
                if (self.moveHome(to)) {
                    self.walk_homes +|= 1;
                    self.spend(step_costs);
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
                    self.tell(.hum, cues_mod.Cue.of(humSound(self.home_hz), .swell));
                    self.own_now = sound.own_world;
                }
            }
        }
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
        _ = self.startRing(self.hum_x, self.hum_z, self.home_hz, true, fullness);
        self.swell_bars = 0;
        // a walk home that took the whole breath, landed: the breath grows by one (SPEC.md 9),
        // and a new line lights on Hum with a high clear note
        if (self.walk_homes >= self.breath_most and self.breath_most < breath_grows_to) {
            self.breath_most += 1;
            self.breath_grew += 1;
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .bell, .hz = self.home_hz * 2.0, .strength = 0.35, .ring = 2.0 }, .glow));
        }
        self.walk_homes = 0;
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
        if (self.step % 6 == 0) {
            const near = hose.nearest(self.hum_x, self.hum_z);
            const th = &self.things[self.hose_thing];
            th.x = near.p[0];
            th.z = near.p[1];
            th.ground = self.groundAt(th.x, th.z);

            // Breathing envelope tied to the bar phase: rises and ebbs with the musical bar
            const bar_phase = @as(f32, @floatFromInt(self.clock % (4 * tick_every))) / @as(f32, @floatFromInt(4 * tick_every));
            const breath = 0.88 + 0.12 * @cos(bar_phase * 2.0 * std.math.pi);

            const dist_factor = @max(0.0, 1.0 - near.d / hose_heard);
            const more = hose_more * dist_factor;
            // Ambient stopped-pipe drone is scaled to sit tastefully in the background rather than overpower
            const stopped_scale: f32 = 0.65;
            const level = (hose_least * 0.7 + more * stopped_scale) * breath * (if (self.hose_open) hose_open_more else 1.0);
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

    /// Whether Hum can strike now: standing, active in the world, and wheel is not open.
    pub fn canStrike(self: *const World) bool {
        return self.stand >= 1.0 and !self.wheel_open;
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
    /// Wholesale port of GameguyPage strike: cycling triad chord progression, auto-facing,
    /// forward 138-degree cone targeting, and ground arc animation.
    fn strike(self: *World, at: f64, timed: bool) void {
        self.strikes += 1;
        self.strike_count += 1;
        if (timed) self.timed_strikes += 1 else self.placed_strikes += 1;
        const landed: u64 = @intFromFloat(@round(at));
        if (self.bar_strike_n < knots.strikes_in_a_bar) {
            self.bar_strikes[self.bar_strike_n] = @intCast(landed % (4 * tick_every));
            self.bar_strike_n += 1;
        }
        // Hum turns to face whatever creature is nearest within reach (GameguyPage standard)
        var nearest_k: ?usize = null;
        var nearest_d2: f32 = (knots.strike_reach * 1.5) * (knots.strike_reach * 1.5);
        for (self.knots[0..self.knot_count], 0..) |kn, i| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            const d2 = dx * dx + dz * dz;
            if (d2 < nearest_d2) {
                nearest_d2 = d2;
                nearest_k = i;
            }
        }
        if (nearest_k) |k| {
            const kn = self.knots[k];
            self.hum_face = std.math.atan2(kn.x - self.hum_x, -(kn.z - self.hum_z));
        }
        self.strike_anim = 1.0;

        // The fork's own note: home's chord, one note after another (GameguyPage standard)
        // Strike 1 = root, Strike 2 = third, Strike 3 = fifth, cycling
        const turn = (self.strike_count - 1) % 3;
        const ratios = chordRatios(homeQuality(self.home_k));
        const fork = self.home_hz * strike_over * ratios[turn % 3];

        // timed: its note with its octave and a brighter light, which the hands may already have
        // started; untimed: its note alone, plain, both starting at once on press
        self.own_now = sound.own_strike;
        self.tell(.hum, cues_mod.Cue.of(.{
            .kind = .strike,
            .family = if (timed) .fork_octave else .fork,
            .hz = fork,
            .strength = strike_strength,
            .ring = strike_ring,
        }, .glow));
        self.own_now = sound.own_world;
        if (timed) self.hum_light = 1.0;
        const more: f32 = if (timed) timed_takes else 1.0;
        const bar: f64 = @floatFromInt(4 * tick_every);
        const in_pocket = self.step < self.pocket_until;
        for (self.knots[0..self.knot_count]) |*kn| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            const d2 = dx * dx + dz * dz;
            if (d2 > knots.strike_reach * knots.strike_reach) continue;
            const d = @sqrt(d2);
            // only what is in front: an arc a little wider than the one drawn (GameguyPage standard: cos(69°) ~ 0.36)
            if (d > 1.5) {
                const dot = (dx * @sin(self.hum_face) - dz * @cos(self.hum_face)) / d;
                if (dot < 0.36) continue;
            }
            const cycle = knots.cycleSteps(bar, self.home_hz, kn.root_hz);
            const take = more * knots.drainAt(kn, @max(0.0, at - @as(f64, @floatFromInt(kn.phase_from))), cycle, self.widen(knots.meet_window)) + (if (in_pocket) knots.pocket_drain else 0.0);
            kn.colour = @max(0.0, kn.colour - take);
            // it rings at its own notes, as hard as the strike met it
            for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.4 + take, .ring = 0.8 }, .glow));
        }
        // and its note carries: a ring that strikes what it reaches out to wave_reach
        const r = self.startRing(self.hum_x, self.hum_z, fork, true, wave_reach / self.ring_reach);
        self.rings[r].wave_more = more;
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
    /// The right face tapped with nothing near: a dash the way Hum goes (or faces), and a soft rush
    /// of air in its own light.
    fn dash(self: *World) void {
        const going = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
        const dx = if (going > 1.0) self.hum_vx / going else @sin(self.hum_face);
        const dz = if (going > 1.0) self.hum_vz / going else -@cos(self.hum_face);
        const speed = dash_far / (@as(f32, @floatFromInt(dash_steps)) * dt);
        self.burst_x = dx * speed;
        self.burst_z = dz * speed;
        self.burst_left = dash_steps;
        self.dashes += 1;
        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .open_pipe, .hz = self.home_hz * 2.0, .strength = 0.06, .ring = 0.15 }, .glow));
    }

    fn dodge(self: *World) void {
        self.dodged_at = self.clock;
        // toward where Hum is going, or else to the side, by turns; 2.2 m in a tenth of a second
        const side: f32 = if (self.strikes % 2 == 0) 1.0 else -1.0;
        const going = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
        const dx = if (going > 1.0) self.hum_vx / going else @cos(self.look_yaw) * side;
        const dz = if (going > 1.0) self.hum_vz / going else @sin(self.look_yaw) * side;
        const speed = 2.2 / (@as(f32, @floatFromInt(dodge_steps)) * dt);
        self.burst_x = dx * speed;
        self.burst_z = dz * speed;
        self.burst_left = dodge_steps;
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
        const speed = knots.knock_back / (@as(f32, @floatFromInt(knock_steps)) * dt);
        self.burst_x = dx / far * speed;
        self.burst_z = dz / far * speed;
        self.burst_left = knock_steps;
        self.hum_light = 0.0;
        self.knocked += 1;
        if (self.stand < 1.0) self.knocked_in_dark += 1;
        for (kn.thing, 0..) |th, s| self.tell(.{ .thing = th }, cues_mod.Cue.of(.{ .kind = .strike, .family = .string, .hz = kn.strands[s].hz, .strength = 0.6, .ring = 0.4 }, .glow));
    }

    /// Knots near Hum come and keep a circle round it, and each strand pulses on its own count of
    /// the knot's cycle, which is a bar stretched by home's pitch against the knot's root. Their
    /// pulses are heard and seen once for each step of the world's beat.
    fn knotStep(self: *World) void {
        // while the world is a page the knots lie still: nothing comes at Hum before it can answer
        if (self.stand < 1.0) return;
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
            // it turns once for each beat between its cycle and Hum's bar: on its root, still
            {
                const cyc: f32 = @floatCast(knots.cycleSteps(@floatFromInt(4 * tick_every), self.home_hz, kn.root_hz));
                const beats = @abs(1.0 / cyc - 1.0 / @as(f32, @floatFromInt(4 * tick_every)));
                kn.spin += 2.0 * std.math.pi * beats * self.tempo;
                if (kn.spin > 2.0 * std.math.pi) kn.spin -= 2.0 * std.math.pi;
            }
            // Hum's own call, once it has reached the knot, is heard: it comes to where it came from
            // they hear Hum only once it has found its way about a little (Drip's lead): nothing
            // hostile comes before the place has been met
            if (!kn.heard and (self.found >= 2 or !self.in_garden)) {
                for (self.rings) |ring| {
                    if (!ring.live or !ring.own) continue;
                    const rx_ = kn.x - ring.x;
                    const rz_ = kn.z - ring.z;
                    const reach = ring.age * dt * sound_speed;
                    if (rx_ * rx_ + rz_ * rz_ <= reach * reach) kn.heard = true;
                }
            }
            // Safe haven: knots do not notice Hum while Hum is exploring the initial clearing/coil area
            if (self.in_garden and self.found < 2 and far > 60.0 and !kn.heard) continue;
            if (far > knots.notices_within and !kn.heard) continue;
            // the first time one is near: a bar of thick time, and Drip on the one, to see them by
            if (!self.knots_met and far < knots.come_near) {
                self.knots_met = true;
                self.first_meet_until = self.step + 4 * tick_every * 4;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork_octave, .hz = self.dripHz() * 2.0, .strength = 0.3, .ring = 0.8 }, .glow));
            }
            if (far > knots.come_near and kn.heard) {
                // coming: straight toward Hum, fast while far
                const stride_far = knots.come_speed * dt * self.tempo;
                kn.x += dx / far * stride_far;
                kn.z += dz / far * stride_far;
                const g_far = self.groundAt(kn.x, kn.z);
                for (kn.thing) |th| {
                    self.things[th].x = kn.x;
                    self.things[th].z = kn.z;
                    self.things[th].ground = g_far;
                }
                continue;
            }
            // Hum singing: a near creature holds still and listens
            if (self.singing and far < 20.0) continue;
            // to its place on a circle round Hum, as near as its root stands to home on the wheel
            const keep = home.keepsOff(home.fifthsApart(self, kn.root_hz));
            const tx = self.hum_x + keep * @cos(kn.around);
            const tz = self.hum_z + keep * @sin(kn.around);
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
    /// How far a sample is from the nearest of Drip's ticks as Hum hears it, in samples: after it
    /// above nought, before it below.
    pub fn afterHeardTick(self: *const World, sample: u64) i64 {
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
        var best: i64 = std.math.maxInt(i64);
        var i: u64 = if (k > 0) k - 1 else 0;
        while (i <= k + 1) : (i += 1) {
            const heard_at: i64 = @intCast(tickStep(i) * samples_per_step + delay);
            const off = @as(i64, @intCast(sample)) - heard_at;
            if (@abs(off) < @abs(best)) best = off;
        }
        return best;
    }

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

    /// In the air: the ground pulls, and the ground is met.
    fn flyStep(self: *World, height_was: f32, roof: f32) void {
        var pull = fallPullNow();
        if (chords_tryout and self.home_k == -1) pull *= feel.now.lift_pull;
        if (@abs(self.hum_vy) < 2.5) {
            pull *= 0.75; // TotK apex float at peak of arc
        } else if (self.hum_vy < 0.0) {
            pull *= 1.25; // weighted, crisp fall
        }
        self.hum_vy -= pull * dt;
        // its height over the ground under it now, which may have risen or fallen beneath it
        self.hum_y = height_was + self.hum_vy * dt - self.hum_ground;
        if (self.hum_vy > 0.0 and self.hum_ground + self.hum_y + hum_tall > roof) {
            // its head has met the underside of something: it rises no further, and the knock is told
            self.hum_y = roof - hum_tall - self.hum_ground;
            const knock = Place{ .x = self.hum_x, .y = self.hum_y + hum_tall, .z = self.hum_z };
            self.tell(.{ .at = knock }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = self.home_hz, .strength = std.math.clamp(self.hum_vy / 40.0, 0.03, 0.3), .ring = 0.08 }, .glow));
            self.hum_vy = 0.0;
        }
        if (self.hum_y > self.hum_floor) return;
        // landed: a thud as hard as the fall, where Hum came down, and its light there
        const fall = -self.hum_vy;
        self.hum_y = self.hum_floor;
        self.hum_vy = 0.0;
        self.airborne = false;
        self.jump_held = false;
        self.jump_steps = 0;
        self.jump_cooldown = 4;
        self.landed_at = self.step;
        const at = Place{ .x = self.hum_x, .y = self.hum_floor + 0.1, .z = self.hum_z };
        self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = self.home_hz, .strength = std.math.clamp(fall / 30.0, 0.04, 0.4), .ring = 0.15 }, .glow));
    }

    /// The wind where Hum is, in metres a second (spec/sky.md, "The law"): it blows from the day's
    /// land out over the water, as fast as the day's note folded into one octave says.
    pub fn windNow(self: *const World) [2]f32 {
        var f = self.day_hz;
        while (f >= garden_hz * 2.0) f *= 0.5;
        while (f < garden_hz) f *= 2.0;
        const speed = wind_on_c * f / garden_hz;
        const dx = lake_x - land.pool[0];
        const dz = lake_z - land.pool[1];
        const far = @sqrt(dx * dx + dz * dz);
        return .{ dx / far * speed, dz / far * speed };
    }

    /// The wedge the wind's note stands on: the day's own.
    pub fn windWedge(self: *const World) i8 {
        return wedgeOfHz(self.day_hz, self.day_hz);
    }

    /// Whether something threatens Hum: a knot near that is not home. Then the right face dodges;
    /// otherwise, held while walking, it sprints.
    pub fn threatened(self: *const World) bool {
        for (self.knots[0..self.knot_count]) |kn| {
            if (kn.home) continue;
            const dx = kn.x - self.hum_x;
            const dz = kn.z - self.hum_z;
            if (dx * dx + dz * dz <= threat_reach * threat_reach) return true;
        }
        return false;
    }

    /// Spend breath. Run out, and what was spending it stops.
    fn spend(self: *World, homes: f32) void {
        self.breath -= homes;
        self.quiet_for = 0;
        if (self.breath < -0.0001) self.outOfBreath();
    }

    /// One step of breath: singing (past its free bars), the wheel and the sprint spend it; silence
    /// gives it back.
    fn breathStep(self: *World) void {
        var spending = false;
        if (self.singing and self.step >= self.hold_until) {
            spending = true;
            if (self.walk_homes == 0 and self.swell_bars >= hold_free_bars) self.spend(hold_costs / bar_steps);
        }
        if (self.wheel_open) {
            spending = true;
            self.spend(wheel_costs / bar_steps);
        }
        if (self.sprinting) {
            spending = true;
            // a body that runs breathes: on every half beat of Drip's tick, a soft breath an octave
            // over home, plain, and Hum's lines flare with it
            if (self.clock % (tick_every / 2) == 0) {
                self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.home_hz * 2.0, .strength = 0.05, .ring = 0.18 }, .glow));
            }
            self.spend(sprint_costs / bar_steps);
        }
        if (spending) {
            self.quiet_for = 0;
            return;
        }
        self.quiet_for +|= 1;
        if (self.quiet_for <= breath_in_after) return;
        const most: f32 = @floatFromInt(self.breath_most);
        if (self.breath < most) {
            self.breath = @min(most, self.breath + breath_in);
            if (self.breath >= most and self.winded) {
                // full again: a small breath in, Hum's lines lit
                self.winded = false;
                self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.home_hz * 2.0, .strength = 0.08, .ring = 0.3 }, .glow));
            }
        }
    }

    /// Out of breath: the note thins away, the sprint drops to a run, the wheel closes where it was,
    /// and a soft sigh. Hum is winded until its breath is full.
    fn outOfBreath(self: *World) void {
        self.breath = 0.0;
        self.winded = true;
        self.breath_outs += 1;
        self.sprinting = false;
        if (self.wheel_open) {
            self.wheel_open = false;
            self.wheel_point = null;
        }
        if (self.singing) {
            self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .hz = self.home_hz, .strength = 0.0, .ring = 0.0 }, .dims));
            if (self.drip_humming) {
                self.drip_humming = false;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
            }
            self.swell_bars = 0;
            self.walk_homes = 0;
        }
        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .stopped_pipe, .hz = self.home_hz, .strength = 0.12, .ring = 0.5 }, .dims));
    }

    /// Whether Hum standing at (x, z) on the ground would be inside something solid, whatever kind
    /// of thing it is (footing.zig).
    pub fn solidAt(self: *const World, x: f32, z: f32) bool {
        return footing.solidAt(self, x, z);
    }

    /// Touching a thing strikes it (SPEC.md 7: every thing has a tune, and what you do to the thing
    /// you do to the tune): a short knock where Hum touched it, at the thing's own note brought into
    /// what the speaker says; the thing struck in its own voice, harder the faster Hum came; and law
    /// 1 carries it on, so whatever shares its overtones answers when the sound reaches it.
    pub fn touch(self: *World, index: u32, speed: f32, at: Place) void {
        self.bumps += 1;
        self.bumped_at = self.step;
        const th = &self.things[index];
        const hard = std.math.clamp((speed - bump_least) / (run_speed - bump_least), 0.0, 1.0);
        const strength = brush_rings * (0.25 + 0.75 * hard);
        var knock = th.hz;
        while (knock > 600.0) knock *= 0.5;
        while (knock < 300.0) knock *= 2.0;
        self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = knock, .strength = strength * 0.6, .ring = 0.25 }, .glow));
        self.tell(.{ .thing = index }, cues_mod.Cue.of(.{ .kind = .strike, .family = th.family, .hz = th.hz, .strength = strength, .ring = th.ring }, .glow));
        th.rung_at = @truncate(self.step);
        th.lit = @max(th.lit, strength);
        if (self.cascades(index)) self.passOn(@intCast(index), strength, false);
    }

    /// Brushing a stalk (spec/shape.md, "Brushing a stalk rings its bells"): the shake runs up it,
    /// lit from the foot, to its crown, and the touch is the crown's bell's: its kin answer by law 1.
    pub fn brushStalk(self: *World, t: u16, speed: f32) void {
        self.bumped_tower = t;
        const tw = self.towers[t];
        const hard = std.math.clamp((speed - bump_least) / (run_speed - bump_least), 0.0, 1.0);
        var part: u32 = 0;
        var crown: ?u32 = null;
        for (tw.first..tw.first + tw.count) |i| {
            const th = &self.things[i];
            if (!th.sounds) {
                th.lit = @max(th.lit, brush_rings * (0.25 + 0.75 * hard) * (1.0 - 0.06 * @as(f32, @floatFromInt(part))));
                part += 1;
                continue;
            }
            if (crown == null or th.y > self.things[crown.?].y) crown = @intCast(i);
        }
        if (crown) |c| {
            // Immediate touch rings an overtone of the aster's bells, connecting foot to crown (Clip 39 fix)
            const at = Place{ .x = self.hum_x, .y = 0.5, .z = self.hum_z };
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bell, .hz = self.things[c].hz, .strength = brush_rings * 0.45 * (0.25 + 0.75 * hard), .ring = 0.5 }, .glow));
            self.touch(c, speed, at);
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
        if (r2 <= edge * edge) {
            self.touching_rim = false;
            return;
        }
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
        // brick: a dull knock where Hum met it, and its light, as the touch begins
        if (v_out > bump_least and !self.touching_rim) {
            const hard = std.math.clamp((v_out - bump_least) / (run_speed - bump_least), 0.0, 1.0);
            self.tell(.{ .at = .{ .x = self.hum_x, .y = 1.0, .z = self.hum_z } }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = garden_hz * 0.25, .strength = 0.05 + 0.1 * hard, .ring = 0.08 }, .glow));
        }
        self.touching_rim = true;
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

    /// Whether Hum has just stepped onto a fallen leaf, the one drawn there (covers.leafAt), each
    /// with its own note, so crossing the leaf fall plays a tune, a note a leaf. Off every leaf, the
    /// next leaf stepped onto rings again, even the same one.
    fn newLeaf(self: *World) bool {
        const under = covers.leafUnder(self.hum_x, self.hum_z) orelse {
            self.leaf_cell = .{ std.math.maxInt(i32), std.math.maxInt(i32) };
            return false;
        };
        if (under[0] == self.leaf_cell[0] and under[1] == self.leaf_cell[1]) return false;
        self.leaf_cell = under;
        return true;
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
                const at = Place{ .x = self.hum_x - fx * 2.0, .y = 0.1, .z = self.hum_z - fz * 2.0 };
                const which = ground.hash32(@intFromFloat(@floor(at.x)), @intFromFloat(@floor(at.z)), 11) % 5;
                // Earthy, warm footstep sound on lawn without high-frequency string tinkle (Clip 34 fix)
                self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = garden_hz * ground.five[which], .strength = 0.035, .ring = 0.18 }, .glow));
            },
            else => {},
        }
        // a fallen leaf rings as it is stepped onto, wherever it lies: each its own note
        if (self.newLeaf()) {
            const at = Place{ .x = self.hum_x, .y = 0.2, .z = self.hum_z };
            const note = covers.leafNote(self.leaf_cell[0], self.leaf_cell[1]);
            self.tell(.{ .at = at }, cues_mod.Cue.of(.{ .kind = .strike, .family = .bar, .hz = garden_hz * ground.five[note], .strength = 0.3, .ring = 0.7 }, .glow));
        }
    }

    /// Drip shows the way out of the coil (SPEC.md 6.1, 4): once the place has stood up, it hops off
    /// Hum's head in an arc over the coil and waits beyond it, ticking, until Hum comes to it, then
    /// hops back on. The world shows the jump before anyone asks for it.
    fn dripShows(self: *World) void {
        const d = &self.things[self.drip];
        const wait = dripWait();
        switch (self.drip_out) {
            0 => {
                if (!self.drip_shown and self.in_garden and self.stand >= 1.0 and self.step >= self.stand_from + 120 and self.locked_at != never) {
                    self.drip_shown = true;
                    self.drip_out = 1;
                    self.drip_out_from = self.step;
                    self.drip_from_x = self.hum_x;
                    self.drip_from_z = self.hum_z;
                    // the push off: its own note, and its light
                    self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.dripHz() * 2.0, .strength = 0.2, .ring = 0.3 }, .glow));
                }
            },
            1 => {
                // the arc over the coil: a second and a half, eight metres up at its top
                const f = @min(1.0, @as(f32, @floatFromInt(self.step - self.drip_out_from)) / drip_hop_steps);
                d.x = self.drip_from_x + (wait[0] - self.drip_from_x) * f;
                d.z = self.drip_from_z + (wait[1] - self.drip_from_z) * f;
                d.ground = self.groundAt(d.x, d.z);
                d.y = 0.3 + (1.25 - 0.3) * (1.0 - f) + 8.0 * 4.0 * f * (1.0 - f);
                if (f >= 1.0) {
                    self.drip_out = 2;
                    self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.dripHz(), .strength = 0.15, .ring = 0.4 }, .glow));
                }
            },
            else => {
                // waiting beyond the coil until Hum comes, or a minute has gone
                d.y = 0.3;
                const dx = self.hum_x - wait[0];
                const dz = self.hum_z - wait[1];
                if (dx * dx + dz * dz < 4.0 * 4.0 or self.step > self.drip_out_from + 60 * 60) {
                    self.drip_out = 0;
                    self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork_octave, .hz = self.dripHz() * 2.0, .strength = 0.2, .ring = 0.5 }, .glow));
                }
            },
        }
    }

    /// The next thing Drip leads to, one at a time, in the order the place offers them: out of the
    /// coil (Drip shows that itself), the great aster, the bridge puddle. Each is found by going
    /// there; then the knots can hear Hum's call. None of it is a list on the screen: Drip, on
    /// Hum's head, hums toward the next one on each bar's one, and a ripple of light runs along the
    /// ground that way, as the second call's answer did.
    pub fn leadTo(self: *const World) ?[2]f32 {
        if (!self.in_garden or !self.drip_met or self.drip_out != 0) return null;
        return switch (self.found) {
            0 => .{ asters.great_x, asters.great_z },
            1 => if (self.pool_count > 0) .{ self.pools[0].x, self.pools[0].z } else null,
            else => null,
        };
    }

    fn guideStep(self: *World) void {
        if (!self.in_garden or !self.drip_met) return;
        // found by going there
        switch (self.found) {
            0 => {
                const dx = self.hum_x - asters.great_x;
                const dz = self.hum_z - asters.great_z;
                if (dx * dx + dz * dz < 40.0 * 40.0) self.found = 1;
            },
            1 => if (self.pool_count > 0) {
                const p = &self.pools[0];
                const dx = self.hum_x - p.x;
                const dz = self.hum_z - p.z;
                if (dx * dx + dz * dz < (p.r + 25.0) * (p.r + 25.0)) self.found = 2;
            } else {
                self.found = 2;
            },
            else => {},
        }
        // in the first fight, before the wheel has been used: on each bar's one Drip sings the
        // knots' root softly, so where home wants to go is heard before the wheel is opened; and
        // once a knot is grey, before any cadence, it sings home's amen side, where to let go
        if (self.threatened() and (self.wheel_opens == 0 or self.cadences == 0)) {
            const kb = self.clock / tick_every;
            if (kb % 4 == 0 and tickStep(kb) == self.clock and self.hint_at != self.clock) {
                self.hint_at = self.clock;
                var grey = false;
                for (self.knots[0..self.knot_count]) |kn| {
                    if (!kn.home and kn.colour <= 0.0) grey = true;
                }
                const hz: f32 = if (grey) wedgeHz(self.day_hz, self.home_k + self.doorSide()) else if (self.wheel_opens == 0 and self.knot_count > 0) self.knots[0].root_hz else 0.0;
                if (hz > 0.0) self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork_octave, .hz = hz * 2.0, .strength = 0.28, .ring = 1.6 }, .glow));
            }
        }
        // on each bar's one, while nothing threatens, Drip leads toward the next
        const to = self.leadTo() orelse return;
        if (self.threatened() or self.singing or self.wheel_open) return;
        const k = self.clock / tick_every;
        if (k % 4 == 0 and tickStep(k) == self.clock and self.lead_at != self.clock) {
            self.lead_at = self.clock;
            self.lead_x = to[0];
            self.lead_z = to[1];
            self.lead_step = self.step;
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.dripHz() * 3.0, .strength = 0.05, .ring = 0.25 }, .glow));
        }
    }

    /// Where Drip waits: beyond the coil round its clearing, on the way to the great aster.
    pub fn dripWait() [2]f32 {
        const ax = asters.great_x - drip_x;
        const az = asters.great_z - drip_z;
        const far = @max(@sqrt(ax * ax + az * az), 1.0);
        return .{ drip_x + ax / far * 17.0, drip_z + az / far * 17.0 };
    }

    /// Drip keeps its time, turns the figure, and once it has landed rides on Hum's head.
    fn dripStep(self: *World) void {
        const d = &self.things[self.drip];
        if (self.drip_met) {
            self.dripShows();
            if (self.drip_out == 0) {
                d.x = self.hum_x;
                d.z = self.hum_z;
                d.y = 1.25 + self.hum_y;
                d.ground = self.hum_ground;
            }
        }
        const dx = d.x - self.hum_x;
        const dz = d.z - self.hum_z;
        const far = @sqrt(dx * dx + dz * dz);
        // Step Drip's physical inertia, jump response, and spring dynamics (Piece 5)
        self.drip_state.stepPhysics(self);
        // close by, before the two have locked: the time to learn its breath
        const teaching = !self.drip_met and self.locked_at == never and far <= beside * 1.6;
        if (teaching and self.beside_first_at == never) self.beside_first_at = self.step;
        if (teaching and self.near_in > 0.9 and self.leaned_first_at == never) self.leaned_first_at = self.step;
        // its upbeat: half a beat before each tick a softer note an octave lower, and its light
        // gathering into the tick, so the moment to let go is seen and heard coming
        if (teaching and untilTick(self.clock) == tick_every / 2 and self.upbeat_at != self.clock) {
            self.upbeat_at = self.clock;
            self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = self.dripHz(), .strength = 0.12, .ring = 0.08 }, .glow));
        }
        if (teaching) {
            const coming = 1.0 - @as(f32, @floatFromInt(@min(untilTick(self.clock), tick_every / 2))) / @as(f32, @floatFromInt(tick_every / 2));
            d.loud = @max(d.loud, 0.5 * coming * coming);
        }
        // its tick: a soft tone and a flash, softer and dimmer the farther off it is; on the one of
        // each bar, an octave higher and brighter
        if (self.ticked_at != self.clock and fromTick(self.clock) == 0 and untilTick(self.clock) == 0) {
            self.ticked_at = self.clock;
            const k = self.clock / tick_every;
            const is_one = (k % 4 == 0);
            const peaceful = !teaching and far > beside * 1.8 and !self.singing and !self.wheel_open and !self.threatened() and self.step >= self.hold_until and self.drip_met and self.drip_out == 0;
            self.drip_state.onBeat(is_one, peaceful);
            const tick: cues_mod.Sound = if (is_one)
                .{ .kind = .strike, .family = .fork, .hz = self.dripHz() * 4.0, .strength = tick_one_strength, .ring = tick_one_ring }
            else
                .{ .kind = .strike, .family = .fork, .hz = self.dripHz() * 2.0, .strength = tick_strength, .ring = tick_ring };
            // Metronome balance: audible via drip_state single source of truth (Piece 5)
            const audible = (self.step >= 240 or self.drip_met) and self.drip_state.isAudible(self, far);
            if (audible) {
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(tick, .glow));
            } else {
                // Soft visual pulse on Hum's head cap without audio ear-fatigue while sleeping
                if (is_one) {
                    self.hum_light = @max(self.hum_light, 0.22);
                }
            }
            // beside a silent Hum, with the view leaned in, it breathes on its own to show how: it
            // hums from a downbeat for three beats and lets go on the fourth tick, then rests
            const showing = teaching and far <= beside and self.near_in > 0.6 and !self.singing and !self.drip_humming;
            if (showing and k % 4 == 0 and !self.drip_showing and self.clock >= self.drip_rest_until) {
                self.drip_showing = true;
                self.drip_shows += 1;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = 1, .hz = self.dripHz(), .strength = 0.6, .ring = 0.0 }, .swell));
            } else if (self.drip_showing and k % 4 == 3) {
                self.drip_showing = false;
                self.drip_rest_until = self.clock + 4 * tick_every;
                self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
            }
            // a silent Hum beside it answers its tick in light: Hum's own note is its kin (law 1)
            if (teaching and far <= beside and !self.singing) self.hum_light = @max(self.hum_light, 0.3);
        }
        // Hum began to hum, or went: Drip stops showing (if Hum hums, it hums with Hum instead)
        if (self.drip_showing and (self.singing or self.drip_humming or far > beside * 1.6)) {
            self.drip_showing = false;
            if (!self.drip_humming) self.tell(.{ .thing = self.drip }, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = 1, .hz = self.dripHz(), .strength = 0.0, .ring = 0.0 }, .dims));
        }
        // while it hums with Hum, or holds, it shines
        if (self.drip_humming or self.drip_showing or self.step < self.hold_until) d.loud = @max(d.loud, 0.85);
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
            if (stood and self.call_held >= wheel_after and !self.singing and !self.winded) {
                self.wheel_open = true;
                self.drip_state.wake();
                self.wheel_opens += 1;
                if (self.first_wheel_at == never) self.first_wheel_at = self.step;
                self.wheel_point = null;
            }
            return;
        }
        if (hands.held(Hands.call)) {
            const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
            const ry = @as(f32, @floatFromInt(hands.ry)) * (1.0 / 127.0);
            const r2 = rx * rx + ry * ry;
            if (r2 >= wheel_point_least * wheel_point_least) {
                const r = @sqrt(r2);
                self.wheel_minor = (r < 0.72);
                var k = wedgeAt(rx, ry);
                // snap and hold: the pointed wedge stays until the stick is well into the next
                if (self.wheel_point) |was| {
                    var off = std.math.atan2(rx, -ry) - @as(f32, @floatFromInt(was)) * (std.math.pi / 6.0);
                    while (off > std.math.pi) off -= 2.0 * std.math.pi;
                    while (off < -std.math.pi) off += 2.0 * std.math.pi;
                    if (@abs(off) < std.math.pi / 12.0 + wheel_hold) k = was;
                }
                const changed = (self.wheel_point == null or self.wheel_point.? != k or self.wheel_minor_was != self.wheel_minor);
                if (changed) {
                    self.wheel_point = k;
                    self.wheel_minor_was = self.wheel_minor;
                    self.wheel_point_since = self.step;
                    self.stopPreview();
                    const eff_k = if (self.wheel_minor) foldWedge(k + 3) else k;
                    // entering a wedge: a soft click in its note if its mood is awake, a dull knock
                    // with no pitch if it sleeps
                    if (self.isAwake(eff_k)) {
                        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = wedgeHz(self.day_hz, eff_k) * 2.0, .strength = 0.05, .ring = 0.12 }, .glow));
                    } else {
                        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = garden_hz * 0.5, .strength = 0.04, .ring = 0.04 }, .dims));
                    }
                }
                // resting on an awake wedge that is not home: Hum hums it under its breath
                const eff_k = if (self.wheel_minor) foldWedge(k + 3) else k;
                if (self.previewing == null and eff_k != self.home_k and self.isAwake(eff_k) and self.step >= self.wheel_point_since + preview_after) {
                    self.previewing = eff_k;
                    self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_on, .voice = preview_voice, .hz = wedgeHz(self.day_hz, eff_k), .strength = preview_strength * hum_strength, .ring = 0.0 }, .swell));
                }
            } else {
                if (self.wheel_point != null) {
                    self.wheel_point = null;
                    self.wheel_minor = false;
                    self.wheel_minor_was = false;
                    self.stopPreview();
                }
            }
            return;
        }
        self.stopPreview();
        // let go: home goes where the stick pointed, if that mood is awake
        // Committing on the inner ring moves home to the relative minor's root wedge, k+3 (Piece 4)
        if (self.wheel_point) |k| {
            const eff_k = if (self.wheel_minor) foldWedge(k + 3) else k;
            const was = self.home_k;
            if (self.moveHome(eff_k) and eff_k != was) self.spend(step_costs);
        }
        self.wheel_open = false;
        self.wheel_point = null;
        self.wheel_minor = false;
        self.wheel_minor_was = false;
    }

    /// The preview's breath ends.
    fn stopPreview(self: *World) void {
        if (self.previewing == null) return;
        self.previewing = null;
        self.tell(.hum, cues_mod.Cue.of(.{ .kind = .hum_off, .voice = preview_voice, .hz = self.home_hz, .strength = 0.0, .ring = 0.0 }, .dims));
    }

    fn look(self: *World, hands: Hands, pressed: u16) void {
        const rx = @as(f32, @floatFromInt(hands.rx)) * (1.0 / 127.0);
        const ry = @as(f32, @floatFromInt(hands.ry)) * (1.0 / 127.0);
        // the right stick goes round Hum and up and down the dial; while the wheel is open it
        // points at wedges: then it does not look (in the swell, the right stick does not look)
        const stick_looks = !self.wheel_open and !self.swelling() and !hands.held(Hands.sing);
        const looking = stick_looks and (@abs(rx) > look_dead or @abs(ry) > look_dead);
        const want_yaw: f32 = if (stick_looks) lookRate(rx) * yaw_most else 0.0;
        const want_orbit: f32 = if (stick_looks) lookRate(ry) * orbit_most else 0.0;
        self.yaw_v += (want_yaw - self.yaw_v) * look_ease;
        self.orbit_v += (want_orbit - self.orbit_v) * look_ease;
        // the stick taken for something else lets go of the view at once
        if (!stick_looks) {
            self.yaw_v = 0.0;
            self.orbit_v = 0.0;
        }
        if (want_yaw == 0.0 and @abs(self.yaw_v) < 0.001) self.yaw_v = 0.0;
        if (want_orbit == 0.0 and @abs(self.orbit_v) < 0.001) self.orbit_v = 0.0;
        self.look_yaw += self.yaw_v * dt;
        var ov = self.orbit_v;
        const room = 1.0 - @abs(self.orbit);
        if ((ov > 0.0) == (self.orbit > 0.0) and room < orbit_soft) ov *= @max(room / orbit_soft, 0.1);
        self.orbit = std.math.clamp(self.orbit + ov * dt, -1.0, 1.0);
        // the player's hand wins (Nesky): taking the stick, the dial starts from where the view is,
        // and the lifts of a fight, standing water or a fall stay off until it has rested two seconds
        if (looking and self.lifts_on > 0.0) {
            self.orbit = self.orbitNow();
            self.lifts_on = 0.0;
        }
        self.looked_ago = if (looking) 0 else self.looked_ago +| 1;
        if (self.looked_ago > lifts_after) self.lifts_on = @min(1.0, self.lifts_on + dt / 0.6);
        // L2 tapped with nothing threatening: the view swings in behind Hum, the dial back to
        // walking; a look stops it
        if (!chords_tryout and pressed & Hands.guard != 0 and self.view == .place and self.stand >= 1.0 and !self.wheel_open and !self.threatened()) {
            var by = self.hum_face - self.look_yaw;
            while (by > std.math.pi) by -= 2.0 * std.math.pi;
            while (by < -std.math.pi) by += 2.0 * std.math.pi;
            self.recentre_from = self.look_yaw;
            self.recentre_by = by;
            self.recentre_orbit = self.orbit;
            if (@abs(by) < recentre_cut) {
                self.recentre_left = recentre_steps;
                self.recentre_cutting = false;
            } else {
                self.recentre_left = 0;
                self.recentre_cutting = true;
                self.recentre_eighth = (self.clock * 8) / tick_every;
            }
        }
        if (looking) {
            self.recentre_left = 0;
            self.recentre_cutting = false;
        }
        if (self.recentre_left > 0) {
            self.recentre_left -= 1;
            const f = 1.0 - @as(f32, @floatFromInt(self.recentre_left)) / @as(f32, @floatFromInt(recentre_steps));
            const e = f * f * (3.0 - 2.0 * f);
            self.look_yaw = self.recentre_from + self.recentre_by * e;
            self.orbit = self.recentre_orbit * (1.0 - e);
        }
        if (self.recentre_cutting and (self.clock * 8) / tick_every > self.recentre_eighth) {
            self.recentre_cutting = false;
            self.look_yaw = self.hum_face;
            self.orbit = 0.0;
        }
        // once the right stick has rested, the view swings in behind where Hum is going, faster
        // the faster it goes, so one thumb steers (SPEC.md 8, the thumb audit); it eases in
        const going = @sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz);
        // (never on the page: a page lies still under Hum, as a page does)
        const following = !self.wheel_open and self.stand >= 1.0 and self.looked_ago > follow_after and going > 0.5 and self.lean < 0.01 and self.water_view < 0.01 and self.recentre_left == 0 and !self.recentre_cutting;
        self.follow_in = if (following) @min(1.0, self.follow_in + 1.0 / follow_ease_in) else 0.0;
        if (following) {
            var gap = std.math.atan2(self.hum_vx, -self.hum_vz) - self.look_yaw;
            while (gap > std.math.pi) gap -= 2.0 * std.math.pi;
            while (gap < -std.math.pi) gap += 2.0 * std.math.pi;
            const rate: f32 = if (self.sprinting) follow_sprint else follow_rate * @min(going / run_speed, 1.0);
            const e = self.follow_in * self.follow_in * (3.0 - 2.0 * self.follow_in);
            if (@abs(gap) < follow_within) self.look_yaw += gap * rate * dt * e;
        }
        // the dial's floors: a fight, and a long fall
        if (self.threatened()) {
            self.fight_after = fight_linger;
            self.fight_view = @min(1.0, self.fight_view + dt);
        } else if (self.fight_after > 0) {
            self.fight_after -= 1;
        } else {
            self.fight_view = @max(0.0, self.fight_view - dt);
        }
        const falling = self.airborne and self.hum_vy < -jump_speed * fall_past_jump;
        self.fall_view = if (falling) @min(1.0, self.fall_view + dt / 0.4) else @max(0.0, self.fall_view - dt);
        // the anchor: the ground under Hum, and Hum's height only past a jump's
        const base_want = self.hum_ground + @max(0.0, self.hum_y - base_past);
        if (!self.view_based or @abs(base_want - self.view_base) > 20.0) {
            self.view_base = base_want;
            self.view_based = true;
        } else {
            self.view_base += (base_want - self.view_base) * base_ease;
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
        // not while the wheel is open, nor in a fight: the view stays on what threatens
        if (self.wheel_open or self.threatened()) over_pool = 0.0;
        self.pool_view += (over_pool - self.pool_view) * 0.012;
        if (self.pool_view < 0.0005) self.pool_view = 0.0;
        // out on standing water the view lifts behind Hum and looks down, so the line ahead and
        // the water heaving either side of it are both in sight
        const on_standing = self.on_pool != 0 and self.pools[self.on_pool - 1].standing();
        self.water_view += ((if (on_standing) @as(f32, 1.0) else 0.0) - self.water_view) * 0.02;
        if (self.water_view < 0.0005) self.water_view = 0.0;
        const leaning = self.still >= 30 and self.looked_ago > 60 and self.near_tower != no_tower and self.near_far < lean_within and self.stand > 0.98 and over_pool == 0.0;
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
        // ease the camera's speed pullback so hitting a solid head-on never snaps the camera forward
        const run_now = @max(feel.now.run_speed, 1.0);
        const sprint_now = @max(feel.now.sprint_speed, run_now);
        const want_run = std.math.clamp(@sqrt(self.hum_vx * self.hum_vx + self.hum_vz * self.hum_vz) / run_now, 0.0, sprint_now / run_now);
        self.view_run += (want_run - self.view_run) * feel.now.view_run_ease;
        if (want_run == 0.0 and self.view_run < 1e-4) self.view_run = 0.0;
        // what stands between the eye and Hum: the eye moves in along its line and up over
        // whatever solid or steep ground lies between them (docs/engine.md, "The eye")
        if (self.stand > 0.0 and self.view == .place) {
            const clear = self.clearance();
            const rise_rate_eye: f32 = if (clear.solid_blocked) 0.35 else lift_rise;
            self.eye_lift += (clear.lift - self.eye_lift) * (if (clear.lift > self.eye_lift) rise_rate_eye else lift_fall);
            if (clear.pull < self.eye_pull) {
                self.eye_pull += (clear.pull - self.eye_pull) * rise_rate_eye;
            } else {
                const o = self.orbitView();
                const step_part = pull_back_speed * dt / @max(o.back, 1.0);
                self.eye_pull = @min(clear.pull, self.eye_pull + step_part);
            }
        } else {
            self.eye_lift = 0.0;
            self.eye_pull = 1.0;
        }
    }

    pub const OrbitView = struct { back: f32, up: f32, pitch: f32, fov: f32 };

    /// The dial as it is now, with its floors: a fight, standing water, a long fall.
    pub fn orbitNow(self: *const World) f32 {
        const sm = struct {
            fn f(x: f32) f32 {
                return x * x * (3.0 - 2.0 * x);
            }
        }.f;
        var u = self.orbit;
        const on = sm(self.lifts_on);
        u = @max(u, fight_orbit * sm(self.fight_view) * on + u * (1.0 - on));
        u = @max(u, water_orbit * sm(self.water_view) * on + u * (1.0 - on));
        u = @max(u, fall_orbit * sm(self.fall_view) * on + u * (1.0 - on));
        return u;
    }

    /// The walking view from the dial, before what stands between: the eye's distance behind
    /// Hum's middle and its height over it, the pitch the view looks at, and how wide it is. At a
    /// run it pulls back, rises a little and widens; at a tall thing's foot it comes in and down.
    pub fn orbitView(self: *const World) OrbitView {
        const u = self.orbitNow();
        const phi = orbitAt(u, 1);
        const wv = self.water_view * self.water_view * (3.0 - 2.0 * self.water_view);
        const d = orbitAt(u, 2) + wv * water_further;
        const run = self.view_run;
        var back = d * @cos(phi) + run * run_back;
        var up = d * @sin(phi) + run * run_up;
        back += self.lean * (lean_back - back);
        up += self.lean * ((lean_up - hum_mid) - up);
        return .{ .back = back, .up = up, .pitch = orbitAt(u, 4) - phi, .fov = orbitAt(u, 3) + run * run_wider };
    }

    pub const Daylight = enum(u8) { dark, dawn, full_day };

    /// Dev arena warp: place Hum cleanly at `(x, z)` facing `face` radians (0 = north / -z),
    /// standing on the ground with camera and motion settled.
    pub fn warpTo(self: *World, x: f32, z: f32, face: f32) void {
        self.hum_x = x;
        self.hum_z = z;
        self.hum_face = face;
        self.look_yaw = face;
        self.hum_vx = 0.0;
        self.hum_vz = 0.0;
        self.hum_vy = 0.0;
        self.burst_x = 0.0;
        self.burst_z = 0.0;
        self.burst_left = 0;
        self.airborne = false;
        self.skidding = false;
        self.jump_held = false;
        self.jump_wanted = 0;
        self.view_run = 0.0;
        self.eye_lift = 0.0;
        self.eye_pull = 1.0;
        self.orbit = 0.0;
        self.yaw_v = 0.0;
        self.orbit_v = 0.0;
        self.lean = 0.0;
        self.gaze = 0.0;
        self.view = .place;
        self.stand = 1.0;
        if (self.stand_from == never) self.stand_from = 0;
        self.drip_met = true;
        self.hum_ground = self.groundAt(x, z);
        self.hum_floor = 0.0;
        self.hum_y = 0.0;
        self.view_base = self.hum_ground;
        self.view_based = true;
        self.cover = ground.underfootAt(x, z);
    }

    /// Dev arena lighting switch: dark opening, rising dawn, or full morning light.
    pub fn setDaylight(self: *World, mode: Daylight) void {
        switch (mode) {
            .dark => {
                self.dawn_from = never;
                self.dawn_age0 = 0.0;
                self.dawn = 0.0;
            },
            .dawn => {
                self.dawn_from = self.step;
                self.dawn_age0 = 12.0;
                self.sun_x = self.hum_x;
                self.sun_z = self.hum_z;
                self.dawn = self.dayAt(self.hum_x, self.hum_z);
            },
            .full_day => {
                self.dawn_from = 0;
                self.dawn_age0 = 180.0;
                self.dawn = 1.0;
                self.view = .place;
                self.stand = 1.0;
                if (self.stand_from == never) self.stand_from = 0;
            },
        }
    }

    /// Dev arena chord switch: jumps directly to lift (-1), home (0) or lean (+1) and steps reactions.
    pub fn setChordDirect(self: *World, k: i8) void {
        const clamped = std.math.clamp(k, @as(i8, -1), @as(i8, 1));
        self.awake |= (@as(u8, 1) << @intFromEnum(Mood.lift)) |
            (@as(u8, 1) << @intFromEnum(Mood.bind)) |
            (@as(u8, 1) << @intFromEnum(Mood.drive));
        self.home_k = clamped;
        self.home_hz = wedgeHz(self.day_hz, clamped);
        harmony.step(self);
    }

    /// Reset camera orbit and eye pull cleanly behind Hum.
    pub fn resetCamera(self: *World) void {
        self.look_yaw = self.hum_face;
        self.orbit = 0.0;
        self.yaw_v = 0.0;
        self.orbit_v = 0.0;
        self.eye_lift = 0.0;
        self.eye_pull = 1.0;
        self.view_run = 0.0;
        self.lean = 0.0;
        self.gaze = 0.0;
        self.view_base = self.hum_ground;
        self.view_based = true;
    }

    const EyeClear = struct { lift: f32, pull: f32, solid_blocked: bool };

    /// How far the eye must rise over the ground and solids between it and Hum, and how far in
    /// it must come (docs/engine.md, "The eye").
    fn clearance(self: *const World) EyeClear {
        const o = self.orbitView();
        const fx = @sin(self.look_yaw);
        const fz = -@cos(self.look_yaw);
        const tx = self.hum_x;
        const ty = self.view_base + hum_mid;
        const tz = self.hum_z;

        var solid_pull: f32 = 1.0;
        var solid_lift: f32 = 0.0;
        var solid_blocked = false;
        if (self.in_garden and self.stand > 0.0 and self.orbitNow() < 0.85 and o.back > 0.5) {
            const desired = [3]f32{ tx - fx * o.back, ty + o.up, tz - fz * o.back };
            var near: footing.Near = undefined;
            footing.gatherForEye(self, tx, tz, desired[0], desired[2], &near);
            const min_pull = pull_parts[pull_parts.len - 1];
            const res = eye_mod.clearEye(near.slice(), .{ tx, ty, tz }, desired, min_pull);
            solid_pull = res.pull;
            solid_lift = res.lift;
            solid_blocked = res.blocked;
        }

        var best = EyeClear{ .lift = solid_lift, .pull = solid_pull, .solid_blocked = solid_blocked };
        for (pull_parts) |cand| {
            const p = @min(cand, solid_pull);
            const bx = -fx * o.back * p;
            const by = o.up * p;
            const bz = -fz * o.back * p;
            const ex = tx + bx;
            const ez = tz + bz;
            const over: f32 = if (self.in_garden and ground.wet(ex, ez)) eye_over_water else eye_over_ground;
            var lift = @max(solid_lift, self.groundAt(ex, ez) + over - (ty + by));
            for ([4]f32{ 0.2, 0.4, 0.6, 0.8 }) |f| {
                const need = self.groundAt(tx + bx * f, tz + bz * f) + line_over_ground - (ty + by * f);
                lift = @max(lift, need / f);
            }
            best = .{ .lift = lift, .pull = p, .solid_blocked = solid_blocked };
            if (lift <= solid_lift + 1e-4) break;
            const rise = std.math.atan2(by + lift, o.back * p);
            if (rise <= @max(lift_most_rise, std.math.atan2(by, o.back * p))) break;
            if (p <= pull_parts[pull_parts.len - 1]) break;
        }
        return best;
    }

    /// Where the eye is, what it looks at and how wide. The place: behind Hum and a little up,
    /// or leaned back with the gaze part-way up a tall thing. The page: high above, looking down.
    /// Between them, one hinge.
    pub fn camera(self: *const World) Camera {
        const u = self.orbitNow();
        const fx = @sin(self.look_yaw);
        const fz = -@cos(self.look_yaw);
        const o = self.orbitView();
        // what stands between: the eye in, and up over the ground between; risen, the view looks
        // down as much more, so Hum stays where it was in the frame
        const back = o.back * self.eye_pull;
        const up_before = o.up * self.eye_pull;
        const up = up_before + self.eye_lift;
        var eye = [3]f32{ self.hum_x - fx * back, hum_mid + up, self.hum_z - fz * back };
        const pitch = o.pitch - (std.math.atan2(up, back) - std.math.atan2(up_before, back));
        const walking = [3]f32{ fx * @cos(pitch), @sin(pitch), fz * @cos(pitch) };
        var dir = walking;
        var fov = o.fov;
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
        if (self.wheel_view > 0.0) {
            // the wheel open: the view rises behind Hum and looks down on it, over any other view, the wheel spread on
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
        const len = @sqrt(dir[0] * dir[0] + dir[1] * dir[1] + dir[2] * dir[2]);
        var at = [3]f32{ eye[0] + dir[0] / len * 10.0, eye[1] + dir[1] / len * 10.0, eye[2] + dir[2] / len * 10.0 };
        // the hinge: the dial fold smoothly lays the world down to the page as u approaches 1.0
        const dial_fold: f32 = blk: {
            if (u <= 0.5) break :blk 0.0;
            const t = (u - 0.5) / 0.5;
            break :blk t * t * (3.0 - 2.0 * t);
        };
        const stand_smooth = self.stand * self.stand * (3.0 - 2.0 * self.stand);
        var s = stand_smooth * (1.0 - dial_fold);
        if (self.wheel_open) s = @min(s, wheel_stand);

        if (self.stand < 1.0) {
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
        // the place stands on the ground: the eye rides with the view's anchor (base_past), as far
        // as the place stands up
        eye[1] += self.view_base * stand_smooth;
        at[1] += self.view_base * stand_smooth;
        // camera up vector: smoothly rotates from {0, 1, 0} at horizon to {fx, 0, fz} when looking straight down
        const cp = @cos(pitch);
        const sp = @sin(pitch);
        const up_vec = [3]f32{ -fx * sp, cp, -fz * sp };
        return .{ .eye = eye, .at = at, .up = up_vec, .fov = fov, .stand = s };
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
        mixIn(&h, @as(u32, @bitCast(self.orbit)));
        mixIn(&h, @as(u32, @bitCast(self.view_base)));
        mixIn(&h, @as(u32, @bitCast(self.eye_lift)));
        mixIn(&h, @as(u32, @bitCast(self.eye_pull)));
        mixIn(&h, @as(u32, @bitCast(self.view_run)));
        mixIn(&h, @as(u32, @bitCast(self.stick_yaw)));
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
        mixIn(&h, @as(u32, @bitCast(self.breath)));
        mixIn(&h, self.breath_most);
        mixIn(&h, @as(u32, @bitCast(self.hum_y)));
        mixIn(&h, @as(u32, @bitCast(self.react.rise)));
        mixIn(&h, @as(u32, @bitCast(self.react.tilt)));
        mixIn(&h, @as(u32, @bitCast(self.react.wound)));
        for (self.react.awake) |a| mixIn(&h, @as(u32, @bitCast(a)));
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
    // (walking against it at a full paddle, it takes most of a minute)
    while (step < 60 * 90 and w.pools[0].holds(w.hum_x, w.hum_z)) : (step += 1) _ = w.stepOnce(.{ .ly = 110 }, &cues);
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

test "a strike timed within an eighth of a beat lands at once with its octave; off the beat it lands at once, plain" {
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
    // a quarter of a beat after a beat: off it, so it lands at once without delay, plain
    while (w.clock % tick_every != tick_every / 4) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.placed_strikes);
    try std.testing.expectEqual(never, w.strike_due);
    var plain = false;
    for (cues[0..n]) |cue| {
        if (cue.own == sound.own_strike and cue.family == .fork) plain = true;
    }
    try std.testing.expect(plain);
}

test "the strike is a wholesale port from GameguyPage: available anytime standing, cycles home chord triad" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.knot_count = 0; // knots not required (GameguyPage standard)
    w.stand = 1.0;
    try std.testing.expect(w.canStrike());

    var cues: [max_cues]sound.Cue = undefined;
    for (0..10) |_| _ = w.stepOnce(.{}, &cues);

    // Strike 1: Root note (ratios[0] = 1.0)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    var n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.strike_count);
    try std.testing.expect(w.strike_anim > 0.9);
    var fork1: f32 = 0.0;
    for (cues[0..n]) |c| {
        if (c.kind == .strike and c.family == .fork_octave) fork1 = c.hz;
    }
    // Root octave: home_hz * 2.0 * 1.0
    try std.testing.expectApproxEqAbs(w.home_hz * 2.0 * 1.0, fork1, 0.1);

    // Strike 2: Third note (ratios[1] = 1.25 for major key)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 2), w.strike_count);
    var fork2: f32 = 0.0;
    for (cues[0..n]) |c| {
        if (c.kind == .strike and c.family == .fork_octave) fork2 = c.hz;
    }
    try std.testing.expectApproxEqAbs(w.home_hz * 2.0 * 1.25, fork2, 0.1);

    // Strike 3: Fifth note (ratios[2] = 1.5 for major key)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 3), w.strike_count);
    var fork3: f32 = 0.0;
    for (cues[0..n]) |c| {
        if (c.kind == .strike and c.family == .fork_octave) fork3 = c.hz;
    }
    try std.testing.expectApproxEqAbs(w.home_hz * 2.0 * 1.5, fork3, 0.1);

    // Strike 4: cycles back to Root note (ratios[0] = 1.0)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 4), w.strike_count);
    var fork4: f32 = 0.0;
    for (cues[0..n]) |c| {
        if (c.kind == .strike and c.family == .fork_octave) fork4 = c.hz;
    }
    try std.testing.expectApproxEqAbs(w.home_hz * 2.0 * 1.0, fork4, 0.1);
}

test "the strike pitch and chord triad are tied to the R1-selected circle of fifths" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.awake = 0xff; // all moods awake for testing circle of fifths
    var cues: [max_cues]sound.Cue = undefined;
    for (0..100) |_| _ = w.stepOnce(.{}, &cues);
    w.stand = 1.0;
    w.hold_until = 0;
    w.locked_at = 1;

    // Initial home: C (k = 0, Major quality)
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    try std.testing.expectEqual(Quality.major, homeQuality(w.home_k));
    const c_hz = w.home_hz;

    // 1. Hold R1 (Hands.call) to open the circle of fifths wheel
    for (0..25) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    // While wheel is open, Hum cannot strike
    try std.testing.expect(!w.canStrike());

    // 2. Point right stick at wedge -1 (F, wonder)
    for (0..10) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = -63, .ry = -110 }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.wheel_point.?);

    // 3. Release R1: home moves to F (k = -1, fourth up / fifth down on circle of fifths)
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expectEqual(Quality.major, homeQuality(w.home_k));
    const f_hz = w.home_hz;
    try std.testing.expectApproxEqAbs(c_hz * (4.0 / 3.0), f_hz, 0.1);

    // Strike 1 on R1-selected key F: Root of F (f_hz * 2.0 * 1.0)
    w.stand = 1.0;
    try std.testing.expect(w.canStrike());
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    var n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    var f_fork1: f32 = 0.0;
    for (cues[0..n]) |c| if (c.kind == .strike) { f_fork1 = c.hz; };
    try std.testing.expectApproxEqAbs(f_hz * 2.0 * 1.0, f_fork1, 0.1);

    // Strike 2 on R1-selected key F: Major Third of F (f_hz * 2.0 * 1.25)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    var f_fork2: f32 = 0.0;
    for (cues[0..n]) |c| if (c.kind == .strike) { f_fork2 = c.hz; };
    try std.testing.expectApproxEqAbs(f_hz * 2.0 * 1.25, f_fork2, 0.1);

    // 4. Now move home via the wheel to D (k = 2, Minor quality)
    try std.testing.expect(w.moveHome(2));
    try std.testing.expectEqual(@as(i8, 2), w.home_k);
    try std.testing.expectEqual(Quality.minor, homeQuality(w.home_k));
    const d_hz = w.home_hz;
    try std.testing.expectApproxEqAbs(c_hz * (9.0 / 8.0), d_hz, 0.1);

    // Strike 3 on D (turn 2): Fifth of D (d_hz * 2.0 * 1.5)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    var d_fork3: f32 = 0.0;
    for (cues[0..n]) |c| if (c.kind == .strike) { d_fork3 = c.hz; };
    try std.testing.expectApproxEqAbs(d_hz * 2.0 * 1.5, d_fork3, 0.1);

    // Strike 4 on D (turn 0): Root of D (d_hz * 2.0 * 1.0)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    var d_fork4: f32 = 0.0;
    for (cues[0..n]) |c| if (c.kind == .strike) { d_fork4 = c.hz; };
    try std.testing.expectApproxEqAbs(d_hz * 2.0 * 1.0, d_fork4, 0.1);

    // Strike 5 on D (turn 1): MINOR Third of D (d_hz * 2.0 * 1.2 - minor 3rd for minor key!)
    while (w.clock % tick_every != 2) _ = w.stepOnce(.{}, &cues);
    n = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    var d_fork5: f32 = 0.0;
    for (cues[0..n]) |c| if (c.kind == .strike) { d_fork5 = c.hz; };
    try std.testing.expectApproxEqAbs(d_hz * 2.0 * 1.2, d_fork5, 0.1);
}

test "Piece 4: circle of fifths wheel cursor deflection, inner relative minor (k+3) and outer major (k) commit" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.awake = 0xff; // all moods awake
    var cues: [max_cues]sound.Cue = undefined;
    for (0..100) |_| _ = w.stepOnce(.{}, &cues);
    w.stand = 1.0;
    w.hold_until = 0;
    w.locked_at = 1;

    // 1. Open wheel with R1
    for (0..25) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);

    // 2. Half deflection (r ~ 0.63, 0.55 <= r < 0.72) pointing north (k = 0, C / Am):
    // selects inner relative minor ring!
    for (0..5) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = 0, .ry = -80 }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.wheel_point.?);
    try std.testing.expect(w.wheel_minor);

    // Wait for preview to start
    for (0..15) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = 0, .ry = -80 }, &cues);
    // Relative minor of C (k=0) is A minor (k=3)
    try std.testing.expectEqual(@as(i8, 3), w.previewing.?);

    // 3. Release R1: commits to relative minor root wedge k+3 = 3 (A minor)
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    try std.testing.expectEqual(@as(i8, 3), w.home_k);
    try std.testing.expectEqual(Quality.minor, homeQuality(w.home_k));
    try std.testing.expectApproxEqAbs(wedgeHz(w.day_hz, 3), w.home_hz, 0.1);

    // 4. Open wheel again and use FULL deflection (r ~ 0.94, r >= 0.72) pointing north (k = 0, C):
    // selects outer major ring!
    for (0..25) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    for (0..5) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = 0, .ry = -120 }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.wheel_point.?);
    try std.testing.expect(!w.wheel_minor);

    // Wait for preview
    for (0..15) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = 0, .ry = -120 }, &cues);
    // Major key preview is C (k=0)
    try std.testing.expectEqual(@as(i8, 0), w.previewing.?);

    // 5. Release R1: commits to major key k = 0 (C major)
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    try std.testing.expectEqual(Quality.major, homeQuality(w.home_k));
    try std.testing.expectApproxEqAbs(wedgeHz(w.day_hz, 0), w.home_hz, 0.1);

    // 6. Test flatward wedge: point at F (k = -1), half deflection (relative minor D minor k = 2):
    for (0..25) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    // rx = -40, ry = -70 gives r = sqrt(1600+4900)/127 ~ 80.6/127 ~ 0.63 (half deflection)
    for (0..5) |_| _ = w.stepOnce(.{ .buttons = Hands.call, .rx = -40, .ry = -70 }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.wheel_point.?);
    try std.testing.expect(w.wheel_minor);

    // Release R1: commits to D minor (k = foldWedge(-1 + 3) = 2)
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.wheel_open);
    try std.testing.expectEqual(@as(i8, 2), w.home_k);
    try std.testing.expectEqual(Quality.minor, homeQuality(w.home_k));
    try std.testing.expectApproxEqAbs(wedgeHz(w.day_hz, 2), w.home_hz, 0.1);
}

test "strike forward cone only hits targets in front, not behind, and auto-aims nearest target" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.knot_count = 2;
    w.hum_x = 0.0;
    w.hum_z = 0.0;
    w.hum_face = 0.0; // facing -z (north)
    // Knot 0 is 4m in front (0.0, -4.0)
    w.knots[0].x = 0.0;
    w.knots[0].z = -4.0;
    w.knots[0].colour = 1.0;
    w.knots[0].root_hz = w.home_hz;
    // Knot 1 is 4m behind (0.0, 4.0)
    w.knots[1].x = 0.0;
    w.knots[1].z = 4.0;
    w.knots[1].colour = 1.0;
    w.knots[1].root_hz = w.home_hz;

    w.strike(@floatFromInt(w.clock), true);
    // Auto-aim picked knot 0 (closer in front) and faced it
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.hum_face, 0.01);
    // Knot 0 (in front) should have lost colour
    try std.testing.expect(w.knots[0].colour < 1.0);
    // Knot 1 (behind) should NOT have lost colour
    try std.testing.expectEqual(@as(f32, 1.0), w.knots[1].colour);
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
    // a way in from 12 m whose straight line to the stalk crosses no crumb or clover stalk
    var way: f32 = 0.0;
    while (way < 6.28) : (way += 0.39) {
        var clear = true;
        var d: f32 = 12.0;
        while (d > stalk_foot + hum_body + 0.2) : (d -= 0.25) {
            if (w.solidAt(tw.x + @sin(way) * d, tw.z - @cos(way) * d)) clear = false;
        }
        if (clear) break;
    }
    w.hum_x = tw.x + @sin(way) * 12.0;
    w.hum_z = tw.z - @cos(way) * 12.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    // the view looking at the stalk, so the stick's up runs straight at it
    w.look_yaw = way + std.math.pi;
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
    // one brush, rung once, and two of its bells heard, each when its sound had come down
    try std.testing.expectEqual(@as(u32, 1), w.bumps);
    try std.testing.expect(heard_bells >= 2);
    // a gentle walk into it rings nothing
    w.initAsters();
    w.hum_x = tw.x;
    w.hum_z = tw.z + 4.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    step = 0;
    while (step < 240) : (step += 1) _ = w.stepOnce(.{ .ly = -20 }, &cues);
    try std.testing.expectEqual(@as(u32, 0), w.bumps);
}

/// The Garden stood up after the lock, beside nothing, for the breath's tests.
fn afterTheLock(w: *World) void {
    w.initAsters();
    w.hum_x = 300.0;
    w.hum_z = -300.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.knot_count = 0;
}

test "one breath: holding a note is free at first, then slow; silence refills it; dodging costs nothing" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    try std.testing.expectEqual(@as(f32, 3.0), w.breath);
    // begun just after a downbeat: two bars of a held note cost nothing
    while (w.clock % (4 * tick_every) != 5) _ = w.stepOnce(.{}, &cues);
    var step: u32 = 0;
    while (step < 2 * 200 - 20) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expectEqual(@as(f32, 3.0), w.breath);
    // then an eighth of a home a bar: eight more bars, about one home
    step = 0;
    while (step < 8 * 200) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(w.breath < 2.2 and w.breath > 1.8);
    // nothing refills while the note is held
    const held = w.breath;
    step = 0;
    while (step < 100) : (step += 1) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(w.breath <= held);
    // silence: full again in a few beats
    step = 0;
    while (step < 4 * tick_every) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(f32, 3.0), w.breath);
    // with nothing threatening, the right face does not dodge, and standing it spends nothing
    const dodged_was = w.dodged_at;
    _ = w.stepOnce(.{ .buttons = Hands.dodge }, &cues);
    try std.testing.expectEqual(@as(f32, 3.0), w.breath);
    try std.testing.expectEqual(dodged_was, w.dodged_at);
}

test "the sprint: the right face held while walking runs at a quarter of the speed of sound, a home a bar" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    // on the level by the Mirror Pool's north shore, running along it (slopes pull: Hum's legs)
    w.hum_x = land.pool[0];
    w.hum_z = land.pool[1] + land.pool[2] + 8.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    var cues: [max_cues]sound.Cue = undefined;
    var step: u32 = 0;
    var fastest: f32 = 0.0;
    while (step < 200) : (step += 1) {
        _ = w.stepOnce(.{ .lx = 127, .buttons = Hands.dodge }, &cues);
        fastest = @max(fastest, @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz));
    }
    try std.testing.expect(w.sprinting);
    try std.testing.expect(fastest > sprint_speed * 0.95 and fastest <= sprint_speed + 0.001);
    try std.testing.expect(w.breath < 2.05 and w.breath > 1.95);
    // held on, it runs out after three bars in all: the sprint drops to a run, and Hum is winded
    step = 0;
    while (step < 2 * 200 + 10) : (step += 1) _ = w.stepOnce(.{ .lx = 127, .buttons = Hands.dodge }, &cues);
    try std.testing.expect(!w.sprinting);
    try std.testing.expect(w.winded);
    try std.testing.expectEqual(@as(u32, 1), w.breath_outs);
    step = 0;
    while (step < 60) : (step += 1) _ = w.stepOnce(.{ .lx = 127, .buttons = Hands.dodge }, &cues);
    try std.testing.expect(@sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz) <= run_speed + 0.001);
    // winded, R2 sings nothing
    _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(!w.singing);
    // silent, the breath comes back; full, Hum is no longer winded
    step = 0;
    while (step < 5 * tick_every) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.winded);
}

test "a walk home that takes the whole breath, landed, grows it by one" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    w.awake = 0xff;
    var cues: [max_cues]sound.Cue = undefined;
    // start the swell just after a downbeat
    while (w.clock % (4 * tick_every) != 5) _ = w.stepOnce(.{}, &cues);
    w.home_k = -2;
    w.home_hz = wedgeHz(w.day_hz, -2);
    var walked: u32 = 0;
    var step: u32 = 0;
    var pushed = false;
    while (step < 5 * 200 and walked < 3) : (step += 1) {
        // a nudge to the right on each downbeat, let back between
        var h = Hands{ .buttons = Hands.sing };
        const at_one = w.clock % (4 * tick_every) == 0;
        if (at_one and !pushed) {
            h.rx = 127;
            pushed = true;
        } else if (!at_one) pushed = false;
        const was = w.home_k;
        _ = w.stepOnce(h, &cues);
        if (w.home_k != was) walked += 1;
    }
    try std.testing.expectEqual(@as(u32, 3), walked);
    try std.testing.expect(!w.winded);
    try std.testing.expect(w.breath < 0.01);
    // hold to the next downbeat and let go on it: the walk lands, and the breath grows
    while (w.clock % (4 * tick_every) != 0) _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(u8, 4), w.breath_most);
    try std.testing.expectEqual(@as(u32, 1), w.breath_grew);
}

test "the bottom face jumps: a held jump reaches three metres, a tap-jump about 1.9 m (variable height), and stepping off an edge has coyote time" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    // on level ground, so the flight is the jump's own
    w.in_garden = false;
    w.hum_ground = 0.0;
    var cues: [max_cues]sound.Cue = undefined;
    // a held jump: press and hold, up and down, its top three metres
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    try std.testing.expect(w.airborne);
    var top: f32 = 0.0;
    var steps: u32 = 1;
    while (w.airborne and steps < 120) : (steps += 1) {
        _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
        top = @max(top, w.hum_y);
    }
    try std.testing.expect(!w.airborne);
    try std.testing.expect(top >= jump_height * 0.95);
    try std.testing.expect(top <= jump_height * 1.15);
    // a tap-jump: press once and release immediately, its top lower but clearing obstacles
    for (0..30) |_| _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    try std.testing.expect(w.airborne);
    var tap_top: f32 = 0.0;
    steps = 0;
    while (w.airborne and steps < 120) : (steps += 1) {
        _ = w.stepOnce(.{}, &cues);
        tap_top = @max(tap_top, w.hum_y);
    }
    try std.testing.expect(!w.airborne);
    try std.testing.expect(tap_top < top * 0.60);
    try std.testing.expect(tap_top > 1.3);
    // a 4-step natural tap (66 ms) still reliably produces the low hop (~1.5 m)
    for (0..30) |_| _ = w.stepOnce(.{}, &cues);
    for (0..4) |_| _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    var tap4_top: f32 = 0.0;
    steps = 0;
    while (w.airborne and steps < 120) : (steps += 1) {
        _ = w.stepOnce(.{}, &cues);
        tap4_top = @max(tap4_top, w.hum_y);
    }
    try std.testing.expect(!w.airborne);
    try std.testing.expect(tap4_top < top * 0.60);
    try std.testing.expect(tap4_top > 1.3);
    // coyote time: stepping off an edge gives six steps where a jump still takes to the air
    for (0..10) |_| _ = w.stepOnce(.{}, &cues);
    w.airborne = true;
    w.hum_y = 2.0;
    w.hum_vy = -0.5;
    w.stood_ago = 3; // within jump_late (6)
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    try std.testing.expect(w.hum_vy > 10.0);
}

test "the hose is solid: walked at, Hum stops at its side; jumped, Hum goes over" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    // stand ten metres from the hose, facing it across, well inside the garden
    const p = hose.backFromEnd(450.0);
    const q = hose.backFromEnd(448.0);
    var ax = q[0] - p[0];
    var az = q[1] - p[1];
    const al = @sqrt(ax * ax + az * az);
    ax /= al;
    az /= al;
    // across the hose: a quarter turn from along it
    const cx = -az;
    const cz = ax;
    w.hum_x = p[0] + cx * 10.0;
    w.hum_z = p[1] + cz * 10.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.look_yaw = std.math.atan2(-cx, cz);
    var step: u32 = 0;
    while (step < 180) : (step += 1) _ = w.stepOnce(.{ .ly = -127 }, &cues);
    // walked at it, it is still on the near side
    const side = (w.hum_x - p[0]) * cx + (w.hum_z - p[1]) * cz;
    try std.testing.expect(side > 0.0);
    // and no nearer than their skins allow: the tube is roundest at half its height, above the
    // top of Hum's round middle, so Hum's feet come a little nearer than the two widths together.
    // The solid is the curve cut into short straight stretches, which is where the last few
    // centimetres go.
    const both = hose.reach + hum_body;
    const drop = hose.reach - (hum_tall - hum_body);
    try std.testing.expect(hose.distance(w.hum_x, w.hum_z) >= @sqrt(both * both - drop * drop) - 0.04);
    try std.testing.expect(!w.solidAt(w.hum_x, w.hum_z));
    // a run and a jump: over
    w.hum_x = p[0] + cx * 10.0;
    w.hum_z = p[1] + cz * 10.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_vx = 0.0;
    w.hum_vz = 0.0;
    w.look_yaw = std.math.atan2(-cx, cz);
    step = 0;
    var jumped = false;
    while (step < 180) : (step += 1) {
        var h = Hands{ .ly = -127 };
        if (!jumped and hose.distance(w.hum_x, w.hum_z) < 4.0) {
            h.buttons = Hands.jump;
            jumped = true;
        } else if (jumped and w.airborne) {
            h.buttons = Hands.jump;
        }
        _ = w.stepOnce(h, &cues);
    }
    const after = (w.hum_x - p[0]) * cx + (w.hum_z - p[1]) * cz;
    try std.testing.expect(after < 0.0);
}

test "everything solid has a top: Hum lands on the hose, stands a bore above the ground, jumps from there, and falls off its side" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    // over the hose's middle line, in the air
    const p = hose.backFromEnd(450.0);
    const q = hose.backFromEnd(448.0);
    var ax = q[0] - p[0];
    var az = q[1] - p[1];
    const al = @sqrt(ax * ax + az * az);
    ax /= al;
    az /= al;
    w.hum_x = p[0];
    w.hum_z = p[1];
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_y = 4.0;
    w.hum_vy = 0.0;
    w.airborne = true;
    for (0..80) |_| _ = w.stepOnce(.{}, &cues);
    // it came down onto the hose's top, not through it to the ground
    try std.testing.expect(!w.airborne);
    try std.testing.expectApproxEqAbs(land.hose_bore, w.hum_y, 0.1);
    try std.testing.expectApproxEqAbs(w.hum_y, w.hum_floor, 1e-4);
    // a jump from there goes as high over the hose as a jump from the ground goes over the ground
    var top: f32 = 0.0;
    for (0..50) |_| {
        _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
        top = @max(top, w.hum_y);
    }
    try std.testing.expectApproxEqAbs(land.hose_bore + jump_height, top, 0.25);
    for (0..60) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.airborne);
    try std.testing.expectApproxEqAbs(land.hose_bore, w.hum_y, 0.1);
    // walked across it, Hum comes off its shoulder, falls, and stands on the ground beyond
    w.look_yaw = std.math.atan2(az, ax);
    for (0..90) |_| _ = w.stepOnce(.{ .ly = -127 }, &cues);
    try std.testing.expect(!w.airborne);
    try std.testing.expectEqual(@as(f32, 0.0), w.hum_y);
    try std.testing.expect(hose.distance(w.hum_x, w.hum_z) > hose.reach + hum_body);
    try std.testing.expect(!w.solidAt(w.hum_x, w.hum_z));
}

test "the hose's coil round Drip's clearing: walked over on the page, a wall once stood, cleared by a jump" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    var cues: [max_cues]sound.Cue = undefined;
    const cx = land.clear[0];
    const cz = land.clear[1];
    // on the page: from outside the coil, west of it, Hum walks east into the clearing over its line
    w.initEvening();
    w.hum_x = cx - 25.0;
    w.hum_z = cz;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    var step: u32 = 0;
    while (step < 60 * 4 and @abs(w.hum_x - cx) > 3.0) : (step += 1) _ = w.stepOnce(.{ .lx = 127 }, &cues);
    try std.testing.expect(@abs(w.hum_x - cx) <= 3.0);
    // stood up, inside it: walked west, the coil holds Hum in
    w.initAsters();
    w.knot_count = 0;
    w.hum_x = cx - 4.0;
    w.hum_z = cz;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    // the view behind Hum, looking west, and the stick pushed forward
    w.look_yaw = -0.5 * std.math.pi;
    step = 0;
    while (step < 60 * 4) : (step += 1) _ = w.stepOnce(.{ .ly = -127 }, &cues);
    const inside = struct {
        fn far(world: *const World, x: f32, z: f32) f32 {
            return @sqrt((world.hum_x - x) * (world.hum_x - x) + (world.hum_z - z) * (world.hum_z - z));
        }
    }.far;
    try std.testing.expect(inside(w, cx, cz) < 10.5);
    // a held jump, walking on: over, and out of the ring
    for (0..20) |_| _ = w.stepOnce(.{ .ly = -127, .buttons = Hands.jump }, &cues);
    step = 0;
    while (step < 60 * 3) : (step += 1) _ = w.stepOnce(.{ .ly = -127 }, &cues);
    try std.testing.expect(inside(w, cx, cz) > 14.0);
}

/// Where a point falls on the screen, from -1 to 1 across and up, for a 4:3 frame.
fn onScreenForTest(cam: Camera, p: [3]f32) [2]f32 {
    var f = [3]f32{ cam.at[0] - cam.eye[0], cam.at[1] - cam.eye[1], cam.at[2] - cam.eye[2] };
    const fl = @sqrt(f[0] * f[0] + f[1] * f[1] + f[2] * f[2]);
    for (&f) |*v| v.* /= fl;
    const r = [3]f32{ f[1] * cam.up[2] - f[2] * cam.up[1], f[2] * cam.up[0] - f[0] * cam.up[2], f[0] * cam.up[1] - f[1] * cam.up[0] };
    const u = [3]f32{ r[1] * f[2] - r[2] * f[1], r[2] * f[0] - r[0] * f[2], r[0] * f[1] - r[1] * f[0] };
    const v = [3]f32{ p[0] - cam.eye[0], p[1] - cam.eye[1], p[2] - cam.eye[2] };
    const z = v[0] * f[0] + v[1] * f[1] + v[2] * f[2];
    const x = v[0] * r[0] + v[1] * r[1] + v[2] * r[2];
    const y = v[0] * u[0] + v[1] * u[1] + v[2] * u[2];
    const t = @tan(cam.fov * 0.5 * std.math.pi / 180.0);
    return .{ x / z / (t * 4.0 / 3.0), y / z / t };
}

test "the view's dial: walking is the old view; up it the eye rises over Hum and looks down; Hum is in the frame all the way; a jump never moves the eye" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    for (0..30) |_| _ = w.stepOnce(.{}, &cues);
    // the middle of the dial is the walking view as it was: 22 m back, 2.2 m up, looking up
    const o = w.orbitView();
    try std.testing.expectApproxEqAbs(cam_back, o.back, 0.001);
    try std.testing.expectApproxEqAbs(cam_up - hum_mid, o.up, 0.001);
    try std.testing.expectApproxEqAbs(walk_pitch, o.pitch, 0.0001);
    try std.testing.expectApproxEqAbs(place_fov, o.fov, 0.001);
    // the stick held down for two seconds takes the dial to the top: the eye high over Hum,
    // looking down on it
    for (0..120) |_| _ = w.stepOnce(.{ .ry = 127 }, &cues);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.orbit, 0.0001);
    const high = w.camera();
    const mid = [3]f32{ w.hum_x, w.hum_ground + hum_mid, w.hum_z };
    try std.testing.expect(high.eye[1] - mid[1] > 35.0);
    try std.testing.expect(high.at[1] < high.eye[1]);
    // all the way along the dial Hum is inside the frame, never at its edge
    var u: f32 = -1.0;
    while (u <= 1.0) : (u += 0.1) {
        w.orbit = u;
        for (0..40) |_| w.look(.{}, 0);
        const s = onScreenForTest(w.camera(), mid);
        try std.testing.expect(@abs(s[0]) < 0.9 and @abs(s[1]) < 0.9);
    }
    // the dial is smooth and never turns back: the eye only rises, step by step up it
    var was: f32 = -1e9;
    u = -1.0;
    while (u <= 1.0) : (u += 0.01) {
        const rise = orbitAt(u, 2) * @sin(orbitAt(u, 1));
        try std.testing.expect(rise > was);
        was = rise;
    }
    // a jump: the eye stays where it was, to the centimetre (once it has settled from the sweep)
    w.orbit = 0.0;
    for (0..600) |_| _ = w.stepOnce(.{}, &cues);
    const before = w.camera().eye;
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    var top: f32 = 0.0;
    var eye_moved: f32 = 0.0;
    for (0..40) |_| {
        _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
        top = @max(top, w.hum_y);
        const e = w.camera().eye;
        eye_moved = @max(eye_moved, @abs(e[1] - before[1]));
    }
    try std.testing.expect(top > 2.0);
    try std.testing.expect(eye_moved < 0.01);
}

test "what stands between: the eye keeps over its ground and the line to Hum clears it, on the steep rise and at the rim's wall" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    w.stand = 1.0;
    var worst_eye: f32 = 1e9;
    var worst_line: f32 = 1e9;
    // places on the spigot's rise, its foot, along the inside of the rim, and on the bowl's slope
    const places = [_][2]f32{
        .{ land.rise[0], land.rise[1] + 40.0 },  .{ land.rise[0] + 60.0, land.rise[1] + 30.0 },
        .{ land.rise[0], land.rise[1] + 100.0 }, .{ land.rise[0] - 90.0, land.rise[1] + 70.0 },
        .{ land.pool[0] + land.rim[2] - 6.0, land.pool[1] },
        .{ land.pool[0] - land.rim[2] + 6.0, land.pool[1] },
        .{ land.pool[0], land.pool[1] + land.rim[2] - 6.0 },
        .{ land.pool[0] + 300.0, land.pool[1] - 200.0 },
        .{ land.pool[0] - 420.0, land.pool[1] + 150.0 },
    };
    for (places) |pl| {
        var yaw: f32 = 0.0;
        while (yaw < 6.28) : (yaw += 0.785) {
            for ([_]f32{ -1.0, 0.0, 0.5, 1.0 }) |u| {
                w.hum_x = pl[0];
                w.hum_z = pl[1];
                w.hum_ground = w.groundAt(pl[0], pl[1]);
                w.look_yaw = yaw;
                w.orbit = u;
                w.view_based = false;
                w.eye_lift = 0.0;
                w.eye_pull = 1.0;
                for (0..90) |_| w.look(.{}, 0);
                const cam = w.camera();
                worst_eye = @min(worst_eye, cam.eye[1] - w.groundAt(cam.eye[0], cam.eye[2]));
                const mid = [3]f32{ w.hum_x, w.view_base + hum_mid, w.hum_z };
                for ([_]f32{ 0.2, 0.4, 0.6, 0.8 }) |f| {
                    const x = mid[0] + (cam.eye[0] - mid[0]) * f;
                    const y = mid[1] + (cam.eye[1] - mid[1]) * f;
                    const z = mid[2] + (cam.eye[2] - mid[2]) * f;
                    worst_line = @min(worst_line, y - w.groundAt(x, z));
                }
            }
        }
    }
    try std.testing.expect(worst_eye >= eye_over_ground - 0.05);
    try std.testing.expect(worst_line >= line_over_ground - 0.05);
}

test "a straight run stays straight while the view swings in behind it" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    for (0..10) |_| _ = w.stepOnce(.{}, &cues);
    // the stick held ten degrees off straight ahead
    const lx: i8 = @intFromFloat(127.0 * @sin(@as(f32, 0.1745)));
    const ly: i8 = @intFromFloat(-127.0 * @cos(@as(f32, 0.1745)));
    for (0..40) |_| _ = w.stepOnce(.{ .lx = lx, .ly = ly }, &cues);
    const heading = w.hum_face;
    for (0..600) |_| _ = w.stepOnce(.{ .lx = lx, .ly = ly }, &cues);
    var turned = w.hum_face - heading;
    if (turned > std.math.pi) turned -= 2.0 * std.math.pi;
    if (turned < -std.math.pi) turned += 2.0 * std.math.pi;
    try std.testing.expect(@abs(turned) < 0.087);
    // and the view has come round behind Hum
    var gap = w.hum_face - w.look_yaw;
    if (gap > std.math.pi) gap -= 2.0 * std.math.pi;
    if (gap < -std.math.pi) gap += 2.0 * std.math.pi;
    try std.testing.expect(@abs(gap) < 0.05);
}

test "L2 tapped with nothing near swings the view in behind Hum; far round, it cuts on the beat; the swell's nudge never turns the view" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    for (0..10) |_| _ = w.stepOnce(.{}, &cues);
    w.hum_face = 1.0;
    w.look_yaw = 0.0;
    w.orbit = 0.6;
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    for (0..recentre_steps + 2) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(@abs(w.look_yaw - w.hum_face) < 0.035);
    try std.testing.expect(@abs(w.orbit) < 0.001);
    // far round: no swing, a cut within an eighth of Drip's tick
    w.look_yaw = w.hum_face + 2.6;
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    var steps: u32 = 0;
    while (w.look_yaw != w.hum_face and steps < 20) : (steps += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(steps <= tick_every / 8 + 1);
    // R2 held after the lock, a push of the right stick nudges home and leaves the view
    const yaw = w.look_yaw;
    for (0..30) |_| _ = w.stepOnce(.{ .buttons = Hands.sing, .rx = 127 }, &cues);
    try std.testing.expect(w.swelling());
    try std.testing.expectEqual(yaw, w.look_yaw);
}

test "a fight lifts the view so the ground round Hum is seen, and lets it down after" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 30.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    try std.testing.expect(w.threatened());
    for (0..90) |_| w.look(.{}, 0);
    try std.testing.expect(w.orbitNow() >= fight_orbit - 0.001);
    try std.testing.expect(w.orbit == 0.0);
    // away from it, two seconds on and one more to come down
    w.hum_x += 400.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    for (0..fight_linger + 70) |_| w.look(.{}, 0);
    try std.testing.expect(w.orbitNow() < 0.001);
}

test "Hum's legs: the first six metres a second at once, a run in two thirds of a second; a turn arcs and keeps its speed; pulled right round, it skids" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    // on level ground with nothing standing on it: the legs' own sums
    w.in_garden = false;
    // on the flat of the Mirror Pool's shore, facing along it
    w.hum_x = land.pool[0] + land.pool[2] + 60.0;
    w.hum_z = land.pool[1];
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    var cues: [max_cues]sound.Cue = undefined;
    for (0..10) |_| _ = w.stepOnce(.{}, &cues);
    w.look_yaw = 0.0;
    var at_013: f32 = 0.0;
    var at_063: f32 = 0.0;
    for (0..60) |i| {
        _ = w.stepOnce(.{ .ly = -127 }, &cues);
        const sp = @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz);
        if (i == 7) at_013 = sp;
        if (i == 37) at_063 = sp;
    }
    try std.testing.expect(at_013 > quick_speed * 0.85 and at_013 < quick_speed * 1.1);
    try std.testing.expect(at_063 > run_speed * 0.9);
    // the stick swung a quarter round at a run: the way bends at the run's turn, the speed kept
    const sp0 = @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz);
    var least_sp: f32 = 1e9;
    var pts: [3][2]f32 = undefined;
    for (0..30) |i| {
        _ = w.stepOnce(.{ .lx = 127, .ly = 0 }, &cues);
        least_sp = @min(least_sp, @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz));
        if (i == 2) pts[0] = .{ w.hum_x, w.hum_z };
        if (i == 6) pts[1] = .{ w.hum_x, w.hum_z };
        if (i == 10) pts[2] = .{ w.hum_x, w.hum_z };
    }
    try std.testing.expect(least_sp > sp0 * 0.85);
    // the circle through three points of the arc
    const ax = pts[0][0];
    const az = pts[0][1];
    const bx = pts[1][0];
    const bz = pts[1][1];
    const cx = pts[2][0];
    const cz = pts[2][1];
    const d = 2.0 * (ax * (bz - cz) + bx * (cz - az) + cx * (az - bz));
    const ux = ((ax * ax + az * az) * (bz - cz) + (bx * bx + bz * bz) * (cz - az) + (cx * cx + cz * cz) * (az - bz)) / d;
    const uz = ((ax * ax + az * az) * (cx - bx) + (bx * bx + bz * bz) * (ax - cx) + (cx * cx + cz * cz) * (bx - ax)) / d;
    const radius = @sqrt((ax - ux) * (ax - ux) + (az - uz) * (az - uz));
    try std.testing.expect(radius > turn_radius_run * 0.8 and radius < turn_radius_run * 1.4);
    // running on, then the stick right round: a skid, sounded, and then the new way
    for (0..60) |_| _ = w.stepOnce(.{ .lx = 127 }, &cues);
    // the stick pushed straight against the way Hum goes, read through the view's directions
    const sp1 = @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz);
    const bx_ = -w.hum_vx / sp1;
    const bz_ = -w.hum_vz / sp1;
    const cy_ = @cos(w.look_yaw);
    const sy_ = @sin(w.look_yaw);
    const back = Hands{ .lx = @intFromFloat((cy_ * bx_ + sy_ * bz_) * 127.0), .ly = @intFromFloat((-sy_ * bx_ + cy_ * bz_) * 127.0) };
    const skids = w.skids;
    const was_vx = w.hum_vx;
    const was_vz = w.hum_vz;
    _ = w.stepOnce(back, &cues);
    try std.testing.expectEqual(skids + 1, w.skids);
    for (0..40) |_| _ = w.stepOnce(back, &cues);
    try std.testing.expect(!w.skidding);
    // going the other way now
    try std.testing.expect(w.hum_vx * was_vx + w.hum_vz * was_vz < 0.0);
}

test "the dodge is a burst that whatever is solid stops; a jump pressed just before landing jumps as Hum lands" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    // beside a stalk, moving toward it, a dodge: Hum is never inside it
    const tw = w.towers[0];
    w.hum_x = tw.x - 2.0;
    w.hum_z = tw.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_vx = 2.0;
    w.hum_vz = 0.0;
    w.dodge();
    var nearest: f32 = 1e9;
    for (0..dodge_steps + 4) |_| {
        _ = w.stepOnce(.{ .lx = 60 }, &cues);
        const dx = w.hum_x - tw.x;
        const dz = w.hum_z - tw.z;
        nearest = @min(nearest, @sqrt(dx * dx + dz * dz));
    }
    try std.testing.expect(nearest >= stalk_foot);
    // a jump, and a press on the way down just over the ground: the next jump goes as it lands
    w.hum_x += 30.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    for (0..20) |_| _ = w.stepOnce(.{}, &cues);
    const jumps = w.jumps;
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    var pressed_early = false;
    var steps: u32 = 0;
    while (steps < 90) : (steps += 1) {
        var h = Hands{};
        if (!pressed_early and w.airborne and w.hum_vy < 0.0 and w.hum_y < 0.6) {
            h.buttons = Hands.jump;
            pressed_early = true;
        }
        _ = w.stepOnce(h, &cues);
        if (w.jumps == jumps + 2) break;
    }
    try std.testing.expect(pressed_early);
    try std.testing.expectEqual(jumps + 2, w.jumps);
}

test "what stands on the ground is felt: a reed's stem stops Hum and sounds its pipe; a clover stalk stops Hum and its roof shivers; a crumb higher than a step stops Hum; the fallen flower head rings its C" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    try std.testing.expect(w.reed_count > reeds.most / 2);
    // run at a reed: Hum never ends inside its stem, and the reed rings
    const reed = w.things[w.reed_first];
    w.hum_x = reed.x - 6.0;
    w.hum_z = reed.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_vx = 0.0;
    w.hum_vz = 0.0;
    w.look_yaw = 0.0;
    var nearest: f32 = 1e9;
    for (0..90) |_| {
        _ = w.stepOnce(.{ .lx = 127 }, &cues);
        const dx = w.hum_x - reed.x;
        const dz = w.hum_z - reed.z;
        nearest = @min(nearest, @sqrt(dx * dx + dz * dz));
    }
    try std.testing.expect(nearest >= reed.tall / 300.0 + hum_body - 0.01);
    try std.testing.expect(w.things[w.reed_first].loud > 0.0 or w.things[w.reed_first].rung_at > 0);
    // a clover stalk and a crumb: found by the same rule the picture draws by
    var bodies: [covers.most_in_patch]covers.Body = undefined;
    var found_clover: ?covers.Body = null;
    var found_crumb: ?covers.Body = null;
    var iz: i32 = -60;
    while (iz < 60 and (found_clover == null or found_crumb == null)) : (iz += 1) {
        var ix: i32 = -60;
        while (ix < 60) : (ix += 1) {
            const n = covers.patch(ix, iz, covers.near_size, true, covers.near_salt, &bodies);
            for (bodies[0..n]) |b| {
                // well inside the garden's rim, so that Hum can come at it
                const from_pool_x = b.x - land.pool[0];
                const from_pool_z = b.z - land.pool[1];
                if (from_pool_x * from_pool_x + from_pool_z * from_pool_z > 600.0 * 600.0) continue;
                if (b.kind != .clover and b.kind != .crumb) continue;
                if (b.kind == .crumb and covers.crumb(b.s).high <= step_up + 0.2) continue;
                // with a clear run at it from the west: nothing else solid on the way
                const b_reach: f32 = if (b.kind == .clover) covers.clover_stalk + hum_body else covers.crumb(b.s).r * covers.crumb_reach + hum_body;
                var clear = true;
                var back: f32 = b_reach + 0.5;
                while (back <= b_reach + 5.5) : (back += 0.25) {
                    if (w.solidAt(b.x - back, b.z)) clear = false;
                }
                if (!clear) continue;
                if (b.kind == .clover and found_clover == null) found_clover = b;
                if (b.kind == .crumb and found_crumb == null) found_crumb = b;
            }
        }
    }
    for ([2]?covers.Body{ found_clover, found_crumb }) |maybe| {
        const b = maybe orelse return error.TestUnexpectedResult;
        const reach: f32 = if (b.kind == .clover) covers.clover_stalk + hum_body else covers.crumb(b.s).r * covers.crumb_reach + hum_body;
        w.hum_x = b.x - reach - 5.0;
        w.hum_z = b.z;
        w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
        w.hum_vx = 0.0;
        w.hum_vz = 0.0;
        w.airborne = false;
        w.hum_y = 0.0;
        const told = w.told;
        nearest = 1e9;
        for (0..60) |_| {
            _ = w.stepOnce(.{ .lx = 127 }, &cues);
            const dx = w.hum_x - b.x;
            const dz = w.hum_z - b.z;
            nearest = @min(nearest, @sqrt(dx * dx + dz * dz));
            // Hum never ends a step inside it
            try std.testing.expect(!w.solidAt(w.hum_x, w.hum_z));
        }
        // it came against it (a clover's stalk leans, so its foot is not quite where Hum met it)
        try std.testing.expect(nearest < reach + 0.5);
        try std.testing.expect(nearest >= reach - 0.12);
        try std.testing.expect(w.told > told);
    }
    // the fallen flower head: Hum stops at it, and it rings
    const fallen = w.things[w.fallen];
    w.hum_x = fallen.x - fallen.tall - 6.0;
    w.hum_z = fallen.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_vx = 0.0;
    w.hum_vz = 0.0;
    nearest = 1e9;
    for (0..90) |_| {
        _ = w.stepOnce(.{ .lx = 127 }, &cues);
        const dx = w.hum_x - fallen.x;
        const dz = w.hum_z - fallen.z;
        nearest = @min(nearest, @sqrt(dx * dx + dz * dz));
    }
    // it is round, and its widest is above Hum's head: Hum's feet come in under its bulge, and
    // no nearer than their two skins allow
    const both = fallen.tall * 0.9 + hum_body;
    const drop = fallen.y - (hum_tall - hum_body);
    try std.testing.expect(nearest >= @sqrt(both * both - drop * drop) - 0.02);
    try std.testing.expect(!w.solidAt(w.hum_x, w.hum_z));
    try std.testing.expect(w.things[w.fallen].rung_at > 0);
}

test "the wheel told: a call of up to nineteen steps never opens it; entering a wedge clicks; resting on one hums it under Hum's breath; home moving is sung" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.locked_at = 0;
    w.hold_until = 0;
    w.knot_count = 0;
    var cues: [max_cues]sound.Cue = undefined;
    for (0..70) |_| _ = w.stepOnce(.{}, &cues);
    // Morgan's calls last 5 to 19 steps: none of them opens the wheel
    for ([_]u32{ 5, 10, 19 }) |held| {
        for (0..held) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
        try std.testing.expect(!w.wheel_open);
        for (0..40) |_| _ = w.stepOnce(.{}, &cues);
    }
    for (0..wheel_after + 2) |_| _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    try std.testing.expect(w.wheel_open);
    // pointing at wonder: a click as the wedge is entered, then its note hummed under Hum's breath
    var clicked = false;
    var previewed = false;
    for (0..30) |_| {
        const n = w.stepOnce(.{ .buttons = Hands.call, .rx = -63, .ry = -110 }, &cues);
        for (cues[0..n]) |c| {
            if (c.kind == .strike and c.family == .fork) clicked = true;
            if (c.kind == .hum_on and c.voice == preview_voice) previewed = true;
        }
    }
    try std.testing.expect(clicked);
    try std.testing.expect(previewed);
    try std.testing.expect(w.previewing.? == -1);
    // let go: the preview's breath ends, home moves, and Hum sings the new home
    var sung = false;
    var ended = false;
    for (0..3) |_| {
        const n = w.stepOnce(.{}, &cues);
        for (cues[0..n]) |c| {
            if (c.kind == .strike and c.family == .fork_octave and @abs(c.hz - w.home_hz) < 0.5) sung = true;
            if (c.kind == .hum_off and c.voice == preview_voice) ended = true;
        }
    }
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expect(sung);
    try std.testing.expect(ended);
}

test "the knots come to Hum's call once the place has stood, and on their own root they stand still" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    // Hum far from them, over 300 m off
    const kn0 = w.knots[0];
    w.hum_x = kn0.x + 320.0;
    w.hum_z = kn0.z;
    while (w.solidAt(w.hum_x, w.hum_z)) w.hum_z += 2.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    for (0..60) |_| _ = w.stepOnce(.{}, &cues);
    const far_before = @abs(w.knots[0].x - w.hum_x);
    for (0..300) |_| _ = w.stepOnce(.{}, &cues);
    // unheard, they stay
    try std.testing.expect(@abs(@abs(w.knots[0].x - w.hum_x) - far_before) < 1.0);
    // a call: heard as it reaches them, and they come, within ninety seconds
    _ = w.stepOnce(.{ .buttons = Hands.call }, &cues);
    var came = false;
    for (0..90 * steps_per_second) |_| {
        _ = w.stepOnce(.{}, &cues);
        const dx = w.knots[0].x - w.hum_x;
        const dz = w.knots[0].z - w.hum_z;
        if (dx * dx + dz * dz < knots.come_near * knots.come_near) {
            came = true;
            break;
        }
    }
    try std.testing.expect(came);
    // home on their root: they stand still; elsewhere they turn
    const spin = w.knots[0].spin;
    for (0..60) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.knots[0].spin != spin);
    w.awake = 0xff;
    _ = w.moveHome(wedgeOfHz(w.day_hz, w.knots[0].root_hz));
    const still = w.knots[0].spin;
    for (0..60) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(@abs(w.knots[0].spin - still) < 0.01);
}

test "the player's hand wins: in a fight, the stick takes the view below the fight's lift" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    w.hum_x = w.knots[0].x;
    w.hum_z = w.knots[0].z - 30.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    for (0..200) |_| w.look(.{}, 0);
    try std.testing.expect(w.orbitNow() >= fight_orbit - 0.01);
    // the stick held up: looking up, low, within half a second
    for (0..30) |_| w.look(.{ .ry = -127 }, 0);
    try std.testing.expect(w.orbitNow() < 0.0);
}

test "a strike's note carries: a knot twenty metres off is struck as the wave reaches it, late by its distance" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var cues: [max_cues]sound.Cue = undefined;
    w.hum_x = w.knots[0].x - 20.0;
    w.hum_z = w.knots[0].z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.knot_count = 1;
    w.strike(@floatFromInt(w.clock), true);
    // the fork's own reach is nine metres: nothing yet
    try std.testing.expectEqual(@as(u32, 0), w.wave_hits);
    // twenty metres at the speed of sound is a third of a second
    var steps: u32 = 0;
    while (w.wave_hits == 0 and steps < 60) : (steps += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.wave_hits);
    try std.testing.expect(steps >= 15 and steps <= 25);
}

test "the chords try-out: off, L1 and L2 leave home alone; on, they step among the lift, home and the lean and no further" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    chords_tryout = false;
    for ([_]u16{ Hands.voice, 0, Hands.guard, 0 }) |b| _ = w.stepOnce(.{ .buttons = b }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    chords_tryout = true;
    defer chords_tryout = false;
    tryout = .{};
    w.awake |= @as(u8, 1) << @intFromEnum(Mood.drive);
    // L1: the lift, and its note is the wedge a fifth below the day's
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expectApproxEqAbs(wedgeHz(w.day_hz, -1), w.home_hz, 0.001);
    _ = w.stepOnce(.{}, &cues);
    // L1 again: the end of what is awake, a knock, and home stays
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expectEqual(@as(u32, 1), tryout.knocks);
    _ = w.stepOnce(.{}, &cues);
    // L2, L2: home, then the lean; L2 again knocks
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    try std.testing.expectEqual(@as(i8, 1), w.home_k);
    _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    try std.testing.expectEqual(@as(i8, 1), w.home_k);
    try std.testing.expectEqual(@as(u32, 3), tryout.steps);
    try std.testing.expectEqual(@as(u32, 2), tryout.knocks);
    try std.testing.expectEqual(@as(u32, 0), tryout.launches);
    _ = w.stepOnce(.{}, &cues);
    // home off the lean: Hum is thrown the way it faces
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    try std.testing.expectEqual(@as(u32, 1), tryout.launches);
    try std.testing.expect(w.burst_left > 0);
}

test "the chords try-out: on the lift a held jump goes higher; on the lean Hum runs faster" {
    var cues: [max_cues]sound.Cue = undefined;
    chords_tryout = true;
    defer chords_tryout = false;
    tryout = .{};
    var tops = [2]f32{ 0.0, 0.0 };
    for (&tops, 0..) |*top, lifted| {
        const w = try std.testing.allocator.create(World);
        defer std.testing.allocator.destroy(w);
        afterTheLock(w);
        w.in_garden = false;
        w.hum_ground = 0.0;
        if (lifted == 1) {
            _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
            _ = w.stepOnce(.{}, &cues);
            try std.testing.expectEqual(@as(i8, -1), w.home_k);
        }
        _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
        var steps: u32 = 1;
        while (w.airborne and steps < 300) : (steps += 1) {
            _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
            top.* = @max(top.*, w.hum_y);
        }
        try std.testing.expect(!w.airborne);
    }
    try std.testing.expect(tops[0] >= jump_height * 0.95 and tops[0] <= jump_height * 1.15);
    try std.testing.expect(tops[1] > tops[0] * 1.6 and tops[1] < tops[0] * 2.0);
    var fastest = [2]f32{ 0.0, 0.0 };
    for (&fastest, 0..) |*f, leaning| {
        const w = try std.testing.allocator.create(World);
        defer std.testing.allocator.destroy(w);
        afterTheLock(w);
        w.awake |= @as(u8, 1) << @intFromEnum(Mood.drive);
        // on the level by the Mirror Pool's north shore, as the sprint's test runs
        w.hum_x = land.pool[0];
        w.hum_z = land.pool[1] + land.pool[2] + 8.0;
        w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
        if (leaning == 1) {
            _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
            try std.testing.expectEqual(@as(i8, 1), w.home_k);
        }
        var step: u32 = 0;
        while (step < 200) : (step += 1) {
            _ = w.stepOnce(.{ .lx = 127 }, &cues);
            f.* = @max(f.*, @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz));
        }
    }
    try std.testing.expect(fastest[0] <= run_speed + 0.001);
    try std.testing.expect(fastest[1] > fastest[0] * 1.2 and fastest[1] <= run_speed * lean_speed + 0.001);
}

test "the world answers the chord: colours wake and rest, the lift raises and the amen settles, the lean tilts and the full close kicks back" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    w.in_garden = false;
    w.hum_ground = 0.0;
    chords_tryout = true;
    defer chords_tryout = false;
    tryout = .{};
    w.awake |= @as(u8, 1) << @intFromEnum(Mood.drive);
    var cues: [max_cues]sound.Cue = undefined;
    // at home in C: C (0) and G (1) wake; D (2) and F (11) rest
    for (0..120) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[0], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[1], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.react.awake[2], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.react.awake[11], 0.01);
    // L1: lift (F) wakes F (11) and keeps C (0), rests G (1), and raises rise toward 1
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    var up_steps: u32 = 0;
    while (w.react.rise < 0.9 and up_steps < 200) : (up_steps += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(w.react.rise >= 0.9);
    for (0..120) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[11], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[0], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.react.awake[1], 0.01);
    // L2: amen back to home settles slower than it rose
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    var down_steps: u32 = 0;
    while (w.react.rise > 0.1 and down_steps < 400) : (down_steps += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(down_steps > up_steps);
    // L2 again: lean (G) wakes G (1) and D (2), tilts and winds up
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    try std.testing.expectEqual(@as(i8, 1), w.home_k);
    for (0..240) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[1], 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), w.react.awake[2], 0.01);
    try std.testing.expect(w.react.tilt > 0.3 and w.react.wound > 0.99);
    // L1: full close back to home kicks tilt past upright before settling to zero
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    try std.testing.expectEqual(@as(i8, 0), w.home_k);
    var least_tilt: f32 = w.react.tilt;
    for (0..400) |_| {
        _ = w.stepOnce(.{}, &cues);
        least_tilt = @min(least_tilt, w.react.tilt);
    }
    try std.testing.expect(least_tilt < -0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.react.tilt, 0.005);
}

test "a fallen leaf in the chord rises on the lift as a plate: Hum rides it up, hits its underside from below, and comes softly down on the amen; a leaf out of the chord stays flat" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    chords_tryout = true;
    defer chords_tryout = false;
    tryout = .{};
    var cues: [max_cues]sound.Cue = undefined;
    // find one fallen leaf in C (cell 0, awake in F's open-fifth lift) and one in D (cell 2, asleep)
    var c_leaf: ?covers.Leaf = null;
    var d_leaf: ?covers.Leaf = null;
    var cz: i32 = -80;
    while (cz <= 80 and (c_leaf == null or d_leaf == null)) : (cz += 1) {
        var cx: i32 = -80;
        while (cx <= 80) : (cx += 1) {
            const lf = covers.leafAt(cx, cz) orelse continue;
            const dx = lf.x - land.pool[0];
            const dz = lf.z - land.pool[1];
            if (dx * dx + dz * dz > 600.0 * 600.0) continue;
            if (w.solidAt(lf.x, lf.z)) continue;
            const cell = covers.leafCell(cx, cz);
            if (cell == 0 and c_leaf == null) c_leaf = lf;
            if (cell == 2 and d_leaf == null) d_leaf = lf;
        }
    }
    const lf_c = c_leaf orelse return error.TestUnexpectedResult;
    const lf_d = d_leaf orelse return error.TestUnexpectedResult;
    // settle awake colours at home on the C leaf
    w.hum_x = lf_c.x;
    w.hum_z = lf_c.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_y = 0.0;
    w.hum_vy = 0.0;
    w.airborne = false;
    for (0..120) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(f32, 0.0), w.hum_y);
    // L1 to lift: Hum rides the C leaf smoothly up to ~2.45 m
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    for (0..160) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.airborne);
    try std.testing.expectApproxEqAbs(@as(f32, 2.45), w.hum_y, 0.12);
    try std.testing.expectApproxEqAbs(w.hum_y, w.hum_floor, 1e-4);
    // standing on the ground underneath the risen leaf and jumping: Hum hits its underside
    w.hum_y = 0.0;
    w.hum_vy = 0.0;
    w.airborne = false;
    w.hum_floor = 0.0;
    var under_top: f32 = 0.0;
    _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
    for (0..40) |_| {
        _ = w.stepOnce(.{ .buttons = Hands.jump }, &cues);
        under_top = @max(under_top, w.hum_y);
    }
    try std.testing.expect(under_top > 0.5 and under_top < 1.6);
    // back on top, then L2 (amen): Hum rides the settling leaf softly all the way back to the ground
    w.hum_y = 2.45;
    w.hum_vy = 0.0;
    w.airborne = false;
    _ = w.stepOnce(.{ .buttons = Hands.guard }, &cues);
    var fell = false;
    for (0..300) |_| {
        _ = w.stepOnce(.{}, &cues);
        if (w.airborne) fell = true;
    }
    try std.testing.expect(!fell);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.hum_y, 1e-4);
    // on the D leaf (asleep in F's chord): stepping to lift leaves Hum on the ground
    w.hum_x = lf_d.x;
    w.hum_z = lf_d.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_y = 0.0;
    w.hum_vy = 0.0;
    w.airborne = false;
    _ = w.stepOnce(.{ .buttons = Hands.voice }, &cues);
    for (0..160) |_| _ = w.stepOnce(.{}, &cues);
    try std.testing.expect(!w.airborne);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), w.hum_y, 1e-4);
}

test "the eye stays clear of the great aster stalk and the hose (step 0.7)" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    w.stand = 1.0;
    // Place Hum 5 m north of the great aster, facing north so the stalk stands directly behind Hum
    // between Hum and the camera eye (at z = great_z + 6 m when unpulled).
    w.hum_x = asters.great_x;
    w.hum_z = asters.great_z - 5.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.look_yaw = 0.0;
    w.orbit = 0.0;
    w.view_based = false;
    w.eye_lift = 0.0;
    w.eye_pull = 1.0;
    for (0..30) |_| w.look(.{}, 0);
    try std.testing.expect(w.eye_pull < 0.55);
    const cam_aster = w.camera();
    var near_aster: footing.Near = undefined;
    footing.gatherForEye(w, w.hum_x, w.hum_z, cam_aster.eye[0], cam_aster.eye[2], &near_aster);
    for (near_aster.slice()) |s| {
        if (s.kind == .tower) try std.testing.expect(eye_mod.distPoint(s, cam_aster.eye) >= eye_mod.eye_reach - 0.05);
    }
    // Place Hum beside a straight stretch of the hose, with the camera looking across the hose.
    const hp = hose.at(hose.length * 0.5);
    const hp_next = hose.at(hose.length * 0.5 + 2.0);
    const tx = hp_next[0] - hp[0];
    const tz = hp_next[1] - hp[1];
    const tl = @sqrt(tx * tx + tz * tz);
    const nx = -tz / tl;
    const nz = tx / tl;
    w.hum_x = hp[0] + nx * 3.0;
    w.hum_z = hp[1] + nz * 3.0;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    // look away from the hose so the camera sits across the hose behind Hum
    w.look_yaw = std.math.atan2(nx, -nz);
    w.orbit = -0.3;
    w.view_based = false;
    w.eye_lift = 0.0;
    w.eye_pull = 1.0;
    for (0..30) |_| w.look(.{}, 0);
    const cam_hose = w.camera();
    var near_hose: footing.Near = undefined;
    footing.gatherForEye(w, w.hum_x, w.hum_z, cam_hose.eye[0], cam_hose.eye[2], &near_hose);
    for (near_hose.slice()) |s| {
        if (s.kind == .hose) try std.testing.expect(eye_mod.distPoint(s, cam_hose.eye) >= eye_mod.eye_reach - 0.05);
    }
}

test "running into a tall rock never jolts the camera, and low rocks step smoothly underfoot" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    afterTheLock(w);
    var cues: [max_cues]sound.Cue = undefined;
    var bodies: [covers.most_in_patch]covers.Body = undefined;
    var tall_crumb: ?covers.Body = null;
    var low_crumb: ?covers.Body = null;
    var iz: i32 = -60;
    while (iz < 60 and (tall_crumb == null or low_crumb == null)) : (iz += 1) {
        var ix: i32 = -60;
        while (ix < 60) : (ix += 1) {
            const n = covers.patch(ix, iz, covers.near_size, true, covers.near_salt, &bodies);
            for (bodies[0..n]) |b| {
                if (b.kind != .crumb) continue;
                const from_pool_x = b.x - land.pool[0];
                const from_pool_z = b.z - land.pool[1];
                if (from_pool_x * from_pool_x + from_pool_z * from_pool_z > 600.0 * 600.0) continue;
                const c_ = covers.crumb(b.s);
                const reach = c_.r * covers.crumb_reach + hum_body;
                var clear = true;
                var back: f32 = reach + 0.5;
                while (back <= reach + 10.0) : (back += 0.5) {
                    if (w.solidAt(b.x - back, b.z)) clear = false;
                }
                if (!clear) continue;
                if (c_.high > step_up + 0.4 and tall_crumb == null) tall_crumb = b;
                if (c_.high >= 0.12 and c_.high <= step_up - 0.02 and low_crumb == null) low_crumb = b;
            }
        }
    }
    // 1. Running head-on into a tall rock at speed: camera eye and FOV must glide smoothly, never snap
    const tc = tall_crumb orelse return error.TestUnexpectedResult;
    const t_reach = covers.crumb(tc.s).r * covers.crumb_reach + hum_body;
    w.hum_x = tc.x - t_reach - 8.0;
    w.hum_z = tc.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_y = 0.0;
    w.hum_vx = 0.0;
    w.hum_vz = 0.0;
    w.airborne = false;
    w.look_yaw = std.math.pi * 0.5;
    w.orbit = 0.0;
    w.view_based = false;
    w.eye_lift = 0.0;
    w.eye_pull = 1.0;
    w.view_run = 0.0;
    for (0..5) |_| _ = w.stepOnce(.{}, &cues);
    var prev_cam = w.camera();
    var worst_jump: f32 = 0.0;
    var worst_fov: f32 = 0.0;
    var hit_rock = false;
    for (0..90) |_| {
        _ = w.stepOnce(.{ .ly = -127 }, &cues);
        const cam = w.camera();
        const dx = cam.eye[0] - prev_cam.eye[0];
        const dy = cam.eye[1] - prev_cam.eye[1];
        const dz = cam.eye[2] - prev_cam.eye[2];
        worst_jump = @max(worst_jump, @sqrt(dx * dx + dy * dy + dz * dz));
        worst_fov = @max(worst_fov, @abs(cam.fov - prev_cam.fov));
        prev_cam = cam;
        const rx = w.hum_x - tc.x;
        const rz = w.hum_z - tc.z;
        if (@sqrt(rx * rx + rz * rz) < t_reach + 0.15) hit_rock = true;
    }
    try std.testing.expect(hit_rock);
    try std.testing.expect(worst_jump < 0.6);
    try std.testing.expect(worst_fov < 0.4);

    // 2. Walking across a low rock (<= step_up): steps cleanly up onto its top without blocking
    const lc = low_crumb orelse return error.TestUnexpectedResult;
    const l_high = covers.crumb(lc.s).high;
    const l_reach = covers.crumb(lc.s).r * covers.crumb_reach + hum_body;
    w.hum_x = lc.x - l_reach - 3.0;
    w.hum_z = lc.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    w.hum_y = 0.0;
    w.hum_vx = 0.0;
    w.hum_vz = 0.0;
    w.airborne = false;
    w.look_yaw = std.math.pi * 0.5;
    var stood_on_low = false;
    for (0..60) |_| {
        _ = w.stepOnce(.{ .ly = -127 }, &cues);
        if (w.hum_y >= l_high - 0.05) stood_on_low = true;
    }
    try std.testing.expect(stood_on_low);
    try std.testing.expect(w.hum_x > lc.x);
}

test "dev arena warp, daylight, chord switch, and live feel bench changes work cleanly" {
    const a = std.testing.allocator;
    const w = try a.create(World);
    defer a.destroy(w);
    defer feel.reset();

    w.initEvening();
    w.warpTo(land.great[0], land.great[1] + 18.0, 0.0);
    try std.testing.expectEqual(View.place, w.view);
    try std.testing.expectEqual(@as(f32, 1.0), w.stand);
    try std.testing.expectApproxEqAbs(land.great[0], w.hum_x, 1e-4);
    try std.testing.expectApproxEqAbs(land.great[1] + 18.0, w.hum_z, 1e-4);
    try std.testing.expectEqual(@as(f32, 0.0), w.hum_vx);
    try std.testing.expectEqual(@as(f32, 1.0), w.eye_pull);

    w.setDaylight(.full_day);
    try std.testing.expectEqual(@as(f32, 1.0), w.dawn);
    w.setDaylight(.dark);
    try std.testing.expectEqual(@as(f32, 0.0), w.dawn);

    w.setChordDirect(-1);
    try std.testing.expectEqual(@as(i8, -1), w.home_k);
    try std.testing.expect(w.react.rise > 0.0);

    // Live bench knob changes jump launch velocity and resets cleanly
    const base_v = jumpSpeedNow();
    feel.now.jump_height = 4.5;
    try std.testing.expect(jumpSpeedNow() > base_v * 1.4);
    feel.reset();
    try std.testing.expectEqual(jump_speed, jumpSpeedNow());
    try std.testing.expectEqual(fall_pull, fallPullNow());
}
