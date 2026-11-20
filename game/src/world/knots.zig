//! Knots (SPEC.md 10; design/the-wheel.md, "The first knot: stand where they meet";
//! spec/promises/fights.md, fight.kinds).
//!
//! A knot is fear: two strands tangled, each singing a note and pulsing at its note slowed down, so
//! they stumble against each other and against Hum. The first knots' strands sing C and A, the
//! third and fifth overtones of the F below, and that F is their root: in one cycle of it, slowed,
//! one strand pulses three times and the other five. Rhythm is pitch slowed down (spec/laws.md,
//! "Sound and light"), so everything here is a sum from the world's one beat clock and home's note:
//! a knot's cycle lasts one of Hum's bars stretched by home's pitch against the root, folded into
//! the octave round a bar. With home on the root the cycle is Hum's bar exactly, and both strands
//! land on Hum's one, three and five to a bar: they were never stumbling, they were dancing over a
//! one nobody was singing. Anywhere else the cycle is another length and they fall between Hum's
//! beats.
//!
//! A strike always drains a knot a little; more when one strand pulses with it, most on a meeting,
//! when both do (DECISIONS.md: every hit works wherever home is). Drained to grey it leans, and a
//! cadence landed with home on its root or beside it brings it home: it springs open into a loop,
//! still, and keeps the mood home was in.
//!
//! No platform: only sums every machine agrees on.
const std = @import("std");

pub const max_knots = 8;
/// A strand: its note, and which overtone of the knot's root it is.
pub const Strand = struct { hz: f32, over: u8 };

/// How near a strand's pulse must fall to a strike to meet it, in steps of the world's beat.
pub const meet_window: f32 = 8.0;
/// How much colour a strike takes: a little alone, more with one strand, most on a meeting.
pub const drain_alone: f32 = 0.08;
pub const drain_strand: f32 = 0.16;
pub const drain_meeting: f32 = 0.34;
/// How near Hum a knot must be to be struck, and to come home on a cadence.
pub const strike_reach: f32 = 9.0;
pub const home_reach: f32 = 60.0;
/// How near a knot comes to Hum, and how fast it moves, metres a second.
pub const keeps_off: f32 = 6.0;
pub const speed: f32 = 3.0;
pub const notices_within: f32 = 180.0;

pub const Knot = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    root_hz: f32 = 0.0,
    strands: [2]Strand = .{ .{ .hz = 0.0, .over = 1 }, .{ .hz = 0.0, .over = 1 } },
    /// Its colour, drained by strikes to nought: grey.
    colour: f32 = 1.0,
    /// Brought home: a loop, still, keeping the mood it was brought home in.
    home: bool = false,
    gift: u8 = 0,
    /// Where on the circle round Hum it keeps.
    around: f32 = 0.0,
    /// The world's thing for each strand, so each shines as loud as it sounds.
    thing: [2]u32 = .{ 0, 0 },
    /// When each strand last pulsed, in steps of the world's beat (for the drawing's jerk).
    pulsed: [2]u64 = .{ 0, 0 },
    /// A lunge: the step of the world's beat it began, so that it arrives on the knot's one.
    lunge_from: u64 = never_lunged,
};

pub const never_lunged: u64 = std.math.maxInt(u64);
/// A lunge lasts this many steps of the world's beat and arrives halfway, on the knot's one; it
/// closes this part of the way to Hum.
pub const lunge_steps: u64 = 24;
pub const lunge_reach: f32 = 0.8;
/// A dodge this near a lunge's arrival, in steps of the world's beat, opens the pocket: time
/// thickens to this pace for this many steps, and a strike in it takes this much more.
pub const dodge_window: u64 = 8;
pub const pocket: f32 = 0.4;
pub const pocket_steps: u64 = 100;
pub const pocket_drain: f32 = 0.15;
/// A lunge that lands knocks Hum back this far, and dims it.
pub const knock_back: f32 = 1.6;

/// The next step of the world's beat at which both a knot's strands pulse together: its one.
pub fn nextOne(clock: u64, cycle: f32) u64 {
    const c = @as(f32, @floatFromInt(clock));
    return @intFromFloat(@ceil(c / cycle) * cycle);
}

/// A knot's cycle, in steps of the world's beat: a bar stretched by home's pitch against its root,
/// folded by octaves into the range round a bar.
pub fn cycleSteps(bar_steps: f32, home_hz: f32, root_hz: f32) f32 {
    var ratio = home_hz / root_hz;
    while (ratio >= std.math.sqrt2) ratio *= 0.5;
    while (ratio < 1.0 / std.math.sqrt2) ratio *= 2.0;
    return bar_steps * ratio;
}

/// How far a moment of the world's beat is from the nearest pulse of a strand, in steps.
pub fn fromPulse(clock: f32, cycle: f32, over: u8) f32 {
    const period = cycle / @as(f32, @floatFromInt(over));
    const into = @mod(clock, period);
    return @min(into, period - into);
}

/// Whether a strand pulses on this step of the world's beat.
pub fn pulsesAt(clock: u64, cycle: f32, over: u8) bool {
    const period = cycle / @as(f32, @floatFromInt(over));
    const a = @floor(@as(f32, @floatFromInt(clock)) / period);
    const b = @floor(@as(f32, @floatFromInt(clock + 1)) / period);
    return b > a;
}

/// What a strike at a moment of the beat takes from a knot: alone, with one strand, or a meeting.
pub fn drainAt(k: *const Knot, clock: f32, cycle: f32) f32 {
    var met: u32 = 0;
    for (k.strands) |s| {
        if (fromPulse(clock, cycle, s.over) <= meet_window) met += 1;
    }
    return switch (met) {
        0 => drain_alone,
        1 => drain_strand,
        else => drain_meeting,
    };
}

test "a knot dances on Hum's one with home on its root, and stumbles anywhere else" {
    const c: f32 = 261.63;
    const f = c * 2.0 / 3.0; // the F below, as the root
    const bar: f32 = 200.0;
    // with home on the root, the cycle is Hum's bar, and both strands pulse on the one
    const at_root = cycleSteps(bar, f, f);
    try std.testing.expectEqual(bar, at_root);
    var k = Knot{ .root_hz = f, .strands = .{ .{ .hz = c, .over = 3 }, .{ .hz = c * 5.0 / 3.0, .over = 5 } } };
    try std.testing.expectEqual(drain_meeting, drainAt(&k, 400.0, at_root));
    // on Hum's other beats only... nothing meets: three and five fall between them
    try std.testing.expectEqual(drain_alone, drainAt(&k, 450.0, at_root));
    // with home on C the cycle is three quarters of a bar: C meets every beat, A only some
    const at_c = cycleSteps(bar, c, f);
    try std.testing.expect(@abs(at_c - 150.0) < 0.01);
    try std.testing.expectEqual(drain_strand, drainAt(&k, 50.0, at_c));
    // and the downbeat is no meeting: the dance's one is not Hum's
    try std.testing.expect(drainAt(&k, 200.0, at_c) < drain_meeting);
}
