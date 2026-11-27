//! How the world answers the chord (docs/engine.md, "Reactions"): the first of the reactions, each
//! written once and the same for every kind of thing. Wake and rest, by colour. Rise, on the lift.
//! Tilt and wind, on the lean. Land, on the full close. Settle, on the amen.
//!
//! The state is twelve numbers and four: one for how awake each colour is, and how far what rises
//! has risen, how far what tilts leans, how fast it is swinging, and what the lean has stored. No
//! thing keeps any of it. A thing's kind says only how much it rises and how much it tilts, and
//! its colour says the rest.
//!
//! `moved` is the one place where that becomes a thing's place. What stops Hum reads it here, and
//! the picture's shader copies it (draw/lines.zig, `react_glsl`), so a risen leaf is drawn where
//! it bears.
//!
//! No world in it and no platform. Only sums every machine agrees on.
const std = @import("std");
const music = @import("../music/music.zig");
const wheel = music.wheel;
const standing_mod = @import("standing.zig");
const Standing = standing_mod.Standing;
const feel = @import("../feel.zig");

/// A thing with no note has no colour, and nothing here moves or lights it.
pub const no_note: u8 = 255;

/// How much a kind of thing rises and how much it tilts, each from nought to fifteen.
pub const Reacts = packed struct(u8) {
    rise: u4 = 0,
    tilt: u4 = 0,

    pub const none = Reacts{};

    pub fn byte(self: Reacts) u8 {
        return @bitCast(self);
    }
};

pub const State = struct {
    /// How awake each colour is: nought at rest, one awake.
    awake: [12]f32 = @splat(0.0),
    /// How far what rises has risen: nought to one.
    rise: f32 = 0.0,
    /// How far what tilts leans toward home, sideways for each metre of height, and how fast that
    /// is changing. It is on a spring, so it can swing past upright.
    tilt: f32 = 0.0,
    tilt_v: f32 = 0.0,
    /// What the lean has stored: nought to one.
    wound: f32 = 0.0,
};

/// One step of the world. `standings` is what every colour is to the chord now; `axis` is whether
/// the chord holds, leans or lifts; `way` is which way home this step came, if it did.
pub fn step(s: *State, standings: *const [12]Standing, axis: wheel.Axis, way: music.change.Way) void {
    for (&s.awake, standings) |*a, st| {
        const want: f32 = if (st.awake()) 1.0 else 0.0;
        a.* += (want - a.*) * feel.wake_ease;
    }
    // the lift raises; coming home from it is the amen, and things come down softly
    const rise_to: f32 = if (axis == .lift) 1.0 else 0.0;
    const rise_ease: f32 = if (rise_to > s.rise) feel.rise_ease else feel.settle_ease;
    s.rise += (rise_to - s.rise) * rise_ease;
    // the lean tilts toward home and winds up
    if (axis == .lean) {
        s.wound = @min(1.0, s.wound + 1.0 / feel.wind_steps);
    } else if (way == .full_close) {
        // the full close: what leaned springs home, thrown the harder for what it had stored
        s.tilt_v -= feel.land_kick * (1.0 + s.wound);
        s.wound = 0.0;
    } else {
        s.wound = 0.0;
    }
    const tilt_to: f32 = if (axis == .lean) feel.tilt_full * (1.0 + feel.wind_more * s.wound) else 0.0;
    s.tilt_v += (tilt_to - s.tilt) * feel.tilt_spring;
    s.tilt_v -= s.tilt_v * feel.tilt_damp;
    s.tilt += s.tilt_v;
}

/// How far a point of a thing is moved from where it stands: east, up and south, in metres.
/// `up` is how high the point is above the ground under its own thing. `x` and `z` are where it
/// stands, and `home` is the place things lean toward.
pub fn moved(s: *const State, cell: u8, reacts: Reacts, up: f32, x: f32, z: f32, home: [2]f32) [3]f32 {
    if (cell >= 12) return .{ 0.0, 0.0, 0.0 };
    const awake = s.awake[cell];
    const dy = feel.rise_unit * @as(f32, @floatFromInt(reacts.rise)) * s.rise * awake;
    const lean = @as(f32, @floatFromInt(reacts.tilt)) * (1.0 / 15.0) * s.tilt * awake * up;
    const hx = home[0] - x;
    const hz = home[1] - z;
    const far = @sqrt(hx * hx + hz * hz);
    if (far < 1e-3) return .{ 0.0, dy, 0.0 };
    return .{ hx / far * lean, dy, hz / far * lean };
}

const expect = std.testing.expect;
const approx = std.testing.expectApproxEqAbs;

fn standingsOf(pos: i8) [12]Standing {
    const day = music.Day{};
    const ch = day.ringChord(pos);
    return standing_mod.all(day, ch.plain(music.Voice.open_fifths), ch.root, null, pos == music.Ring.home);
}

fn axisOf(pos: i8) wheel.Axis {
    return switch (pos) {
        music.Ring.lift => .lift,
        music.Ring.lean => .lean,
        else => .hold,
    };
}

test "what is in the chord wakes and what is not rests" {
    var s = State{};
    const home = standingsOf(music.Ring.home);
    for (0..120) |_| step(&s, &home, .hold, .none);
    try approx(@as(f32, 1.0), s.awake[0], 0.001);
    try approx(@as(f32, 1.0), s.awake[1], 0.001);
    try approx(@as(f32, 0.0), s.awake[2], 0.001);
    // to the lean: C rests, D wakes, G stays awake all the way through
    const lean = standingsOf(music.Ring.lean);
    var g_least: f32 = 1.0;
    for (0..120) |_| {
        step(&s, &lean, .lean, .none);
        g_least = @min(g_least, s.awake[1]);
    }
    try approx(@as(f32, 0.0), s.awake[0], 0.001);
    try approx(@as(f32, 1.0), s.awake[2], 0.001);
    try expect(g_least > 0.99);
}

test "the lift raises what rises, and the amen sets it down more slowly than it rose" {
    var s = State{};
    const lift = standingsOf(music.Ring.lift);
    var up_steps: u32 = 0;
    while (s.rise < 0.9) : (up_steps += 1) step(&s, &lift, .lift, .none);
    // a fallen leaf in C is in the lift's chord, as its fifth: it is nearly two and a half metres up
    const leaf = Reacts{ .rise = feel.leaf_rises };
    for (0..200) |_| step(&s, &lift, .lift, .none);
    const high = moved(&s, 0, leaf, 0.0, 10.0, 10.0, .{ 0.0, 0.0 });
    try approx(@as(f32, 2.4), high[1], 0.01);
    try approx(@as(f32, 0.0), high[0], 1e-6);
    // one in D is not in the chord, and stays where it lies
    try approx(@as(f32, 0.0), moved(&s, 2, leaf, 0.0, 10.0, 10.0, .{ 0.0, 0.0 })[1], 0.01);
    // home again by the amen: down, and slower
    const home = standingsOf(music.Ring.home);
    var down_steps: u32 = 0;
    step(&s, &home, .hold, .amen);
    while (s.rise > 0.1) : (down_steps += 1) step(&s, &home, .hold, .none);
    try expect(down_steps > up_steps);
    for (0..400) |_| step(&s, &home, .hold, .none);
    try approx(@as(f32, 0.0), s.rise, 0.001);
}

test "the lean tilts what tilts toward home and winds up, and the full close throws it back past upright" {
    var s = State{};
    const lean = standingsOf(music.Ring.lean);
    for (0..40) |_| step(&s, &lean, .lean, .none);
    const early = s.tilt;
    try expect(early > 0.0);
    for (0..300) |_| step(&s, &lean, .lean, .none);
    // held, it has wound up and leans further
    try approx(@as(f32, 1.0), s.wound, 0.001);
    try expect(s.tilt > early);
    try approx(feel.tilt_full * (1.0 + feel.wind_more), s.tilt, 0.002);
    // a blade in G, east of home, four metres up: its tip leans west, toward home
    const blade = Reacts{ .tilt = feel.blade_tilts };
    const tip = moved(&s, 1, blade, 4.0, 50.0, 0.0, .{ 0.0, 0.0 });
    try expect(tip[0] < -1.0);
    try approx(@as(f32, 0.0), tip[1], 1e-6);
    try approx(@as(f32, 0.0), tip[2], 1e-6);
    // its foot does not move
    try approx(@as(f32, 0.0), moved(&s, 1, blade, 0.0, 50.0, 0.0, .{ 0.0, 0.0 })[0], 1e-6);
    // the full close: it swings back through upright before it comes to rest
    const home = standingsOf(music.Ring.home);
    step(&s, &home, .hold, .full_close);
    var least: f32 = s.tilt;
    for (0..400) |_| {
        step(&s, &home, .hold, .none);
        least = @min(least, s.tilt);
    }
    try expect(least < -0.01);
    try approx(@as(f32, 0.0), s.tilt, 0.001);
    try approx(@as(f32, 0.0), s.wound, 1e-6);
}

test "a thing with no note is never moved" {
    var s = State{};
    const lift = standingsOf(music.Ring.lift);
    for (0..200) |_| step(&s, &lift, .lift, .none);
    const d = moved(&s, no_note, .{ .rise = 15, .tilt = 15 }, 5.0, 3.0, 4.0, .{ 0.0, 0.0 });
    try approx(@as(f32, 0.0), d[0], 1e-9);
    try approx(@as(f32, 0.0), d[1], 1e-9);
    try approx(@as(f32, 0.0), d[2], 1e-9);
    _ = axisOf(0);
}
