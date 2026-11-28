//! The harmony the world stands in, and the world answering it (docs/engine.md, "The harmony" and
//! "One step, in order"; True 24-Cell Concentric Circle of Fifths).
//!
//! This is the single bridge where the world's day and 2D Circle-of-Fifths coordinate
//! `(home_k, home_minor)` become exact rational music (`music/`), voice-led pure major/minor
//! triads or open fifths, standings for all twelve colours, and chord labels shared by the live
//! Circle Compass, 3D R1 Wheel, Pause Workbench, and logs.
//!
//! No platform.
const std = @import("std");
const world_mod = @import("world.zig");
const World = world_mod.World;
const music = @import("../music/music.zig");
const standing = @import("../law/standing.zig");
const react = @import("../law/react.zig");
const land = world_mod.land;

/// How Hum voices chords (cycled with D-pad Left / Right).
pub const VoicingMode = enum(u8) {
    open_5th = 0,
    triad = 1,
    low_bass = 2,

    pub fn fromU8(v: u8) VoicingMode {
        return switch (v) {
            0 => .open_5th,
            2 => .low_bass,
            else => .triad,
        };
    }

    pub fn label(self: VoicingMode) []const u8 {
        return switch (self) {
            .open_5th => "5TH",
            .triad => "TRIAD",
            .low_bass => "BASS",
        };
    }
};

/// The day. Until a morning can be chosen on the island it is always the Garden's own (C).
pub fn day(w: *const World) music.Day {
    _ = w;
    return .{};
}

/// The active cell on the true 24-cell concentric Circle of Fifths.
pub fn cell(w: *const World) music.wheel.Cell {
    return w.homeCell();
}

/// How far Hum's chord voicing opens: bare fifths in `open_5th`, pure just triad in `triad`/`low_bass`.
pub fn voice(w: *const World) music.Voice {
    return if (VoicingMode.fromU8(w.voicing) == .open_5th) music.Voice.open_fifths else music.Voice.warm;
}

/// The exact just-intoned major or minor chord at `(home_k, home_minor)`.
pub fn chord(w: *const World) music.Chord {
    return day(w).chordOn(cell(w));
}

/// The notes of the active chord that are sounding.
pub fn members(w: *const World) music.chord.Members {
    return chord(w).plain(voice(w));
}

/// Where things lean toward: the middle of the Garden, which is its Mirror Pool.
pub fn home(w: *const World) [2]f32 {
    _ = w;
    return .{ land.pool[0], land.pool[1] };
}

/// Pure frequency of any of the 24 Circle-of-Fifths cells folded into `[day_hz, 2 * day_hz)` so
/// Hum's call, hum, and fork remain in the clear speaker-friendly register.
pub fn cellHz(day_hz: f32, c: music.wheel.Cell) f32 {
    const ch = (music.Day{}).chordOn(c);
    var hz: f32 = @floatCast(ch.root.hz(day_hz));
    while (hz < day_hz * 0.999) hz *= 2.0;
    while (hz >= day_hz * 1.999) hz *= 0.5;
    return hz;
}

/// Pure ASCII chord letter for any of the 24 cells (`"C"`, `"Am"`, `"F#"`, `"D#m"`, ...).
pub fn cellShort(c: music.wheel.Cell) []const u8 {
    return c.name();
}

/// ASCII face label for a cell on the given day (today's sunlit 6 faces vs outside/far).
pub fn cellFace(d: music.Day, c: music.wheel.Cell) []const u8 {
    return switch (d.face(c)) {
        .home => "HOME",
        .floats => "LIFT",
        .leans => "LEAN",
        .runs => "RUNS",
        .remembers => "REMEMBERS",
        .aches => "ACHES",
        .asleep => blk: {
            const dist = music.wheel.steps(d.land(), c.at);
            break :blk if (dist == 6 or dist == -6) "FAR" else "OUTSIDE";
        },
    };
}

const full_names_c = [2][12][]const u8{
    .{
        "C  HOME",
        "G  LEAN",
        "D  OUTSIDE",
        "A  OUTSIDE",
        "E  OUTSIDE",
        "B  OUTSIDE",
        "F#  FAR",
        "Db  OUTSIDE",
        "Ab  OUTSIDE",
        "Eb  OUTSIDE",
        "Bb  OUTSIDE",
        "F  LIFT",
    },
    .{
        "Am  REMEMBERS",
        "Em  ACHES",
        "Bm  OUTSIDE",
        "F#m  OUTSIDE",
        "C#m  OUTSIDE",
        "G#m  OUTSIDE",
        "D#m  FAR",
        "Bbm  OUTSIDE",
        "Fm  OUTSIDE",
        "Cm  OUTSIDE",
        "Gm  OUTSIDE",
        "Dm  RUNS",
    },
};

/// ASCII full label for any of the 24 cells on Day C (HUD, Pause Menu, Arena, logs).
pub fn cellName(c: music.wheel.Cell) []const u8 {
    return full_names_c[@intFromEnum(c.ring)][c.at];
}

/// Voice-led pure major/minor chord voicing (open fifths, pure just triad, or low-bass triad).
/// Notes whose pitch colour stayed from the previous cell are marked `kept` so they continue
/// floating undisturbed rather than hard-restriking; moved notes land in the clear speaker octave.
pub const Voicing = struct {
    /// Optional bass/ground anchor underneath (0 when omitted so outside keys stay pure).
    ground_hz: f32 = 0.0,
    notes: [3]f32 = .{ 0.0, 0.0, 0.0 },
    kept: [3]bool = .{ false, false, false },
    roles: [3]music.chord.Role = .{ .root, .fifth, .third },
    n: u8 = 0,
};

/// Fold chord tones into the clear speaker-friendly mid octave `[E4 .. E5]` (`[1.25, 2.55] * day_hz`)
/// so adjacent steps around the Circle AND vertical Major <-> Relative Minor drops keep shared
/// common tones at the exact same pitch in hertz.
fn foldChordTone(day_hz: f32, hz0: f32) f32 {
    var hz = hz0;
    const lo = day_hz * 1.25;
    const hi = day_hz * 2.55;
    while (hz < lo) hz *= 2.0;
    while (hz > hi) hz *= 0.5;
    return hz;
}

pub fn chordVoicing(day_hz: f32, from: music.wheel.Cell, to: music.wheel.Cell, mode: VoicingMode) Voicing {
    const d = music.Day{};
    const v_voice = if (mode == .open_5th) music.Voice.open_fifths else music.Voice.warm;
    const prev_ch = d.chordOn(from);
    const next_ch = d.chordOn(to);
    const prev = prev_ch.plain(v_voice);
    const next = next_ch.plain(v_voice);
    const chg = music.change.between(prev, next);

    var out = Voicing{ .n = next.n };
    if (mode == .low_bass) {
        // Low-bass voicing anchors the chord's own root an octave underneath
        out.ground_hz = cellHz(day_hz, to) * 0.5;
    } else if (d.face(to).awake() and next.n > 0 and next.notes[0].cell() != d.land()) {
        // Inside today's 6 sunlit cells, keep a soft Garden ground anchor underneath non-C chords
        out.ground_hz = day_hz * 0.5;
    }

    const same_cell = from.ring == to.ring and from.at == to.at;
    for (0..next.n) |i| {
        const note = next.notes[i];
        const stayed = !same_cell and (chg.shared & music.wheel.colour(note.cell())) != 0;
        out.kept[i] = stayed;
        out.roles[i] = next.roles[i];
        var hz: f32 = @floatCast(note.hz(day_hz));
        for (chg.slice()) |mv| {
            if (mv.to.cell() == note.cell()) {
                hz = @floatCast(mv.to.hz(day_hz));
                break;
            }
        }
        out.notes[i] = foldChordTone(day_hz, hz);
    }
    return out;
}

/// Classify a transition between any two cells on the 24-cell Circle of Fifths.
pub fn changeWay(d: music.Day, from: music.wheel.Cell, to: music.wheel.Cell) music.change.Way {
    if (from.ring == to.ring and from.at == to.at) return .none;
    if (from.at == to.at and from.ring != to.ring) return .turn;
    const df = music.wheel.steps(d.land(), from.at);
    const dt_step = music.wheel.steps(d.land(), to.at);
    if (from.ring == to.ring) {
        if (df == 1 and dt_step == 0) return .full_close;
        if (df == -1 and dt_step == 0) return .amen;
        if (music.wheel.steps(to.at, from.at) == 1) return .long_way;
    }
    return .none;
}

/// What every colour is to the active chord now. `was` is the previous cell if it just changed.
pub fn standings(w: *const World, was: ?music.wheel.Cell) [12]standing.Standing {
    const d = day(w);
    const cur = cell(w);
    const v = voice(w);
    const before: ?music.chord.Members = if (was) |prev| d.chordOn(prev).plain(v) else null;
    const is_home = cur.ring == .outer and cur.at == d.land();
    return standing.all(d, d.chordOn(cur).plain(v), d.chordOn(cur).root, before, is_home);
}

/// One step of the world answering the chord: what is in it wakes, what lifts rises,
/// what leans tilts and winds, and a step home lands or settles it.
pub fn step(w: *World) void {
    const d = day(w);
    const cur = cell(w);
    const prev = music.wheel.Cell{
        .ring = if (w.react_minor) .inner else .outer,
        .at = @intCast(@mod(@as(i32, w.react_k), 12)),
    };
    const changed = w.react_k != w.home_k or w.react_minor != w.home_minor;
    const way = if (changed) changeWay(d, prev, cur) else .none;
    const all = standings(w, if (changed) prev else null);
    react.step(&w.react, &all, d.axis(cur), way);
    w.react_k = w.home_k;
    w.react_minor = w.home_minor;
}

/// How far a point of a thing has been moved by the chord (law/react.zig).
pub fn moved(w: *const World, col_cell: u8, reacts: react.Reacts, up: f32, x: f32, z: f32) [3]f32 {
    return react.moved(&w.react, col_cell, reacts, up, x, z, home(w));
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const approx = std.testing.expectApproxEqAbs;

test "24-cell Circle of Fifths: pure tuning, triad voice-leading (C<->Am keeps 2 tones), and voicing modes" {
    const c_hz: f32 = 261.63;
    const c_maj = music.wheel.Cell{ .ring = .outer, .at = 0 };
    const g_maj = music.wheel.Cell{ .ring = .outer, .at = 1 };
    const f_maj = music.wheel.Cell{ .ring = .outer, .at = 11 };
    const a_min = music.wheel.Cell{ .ring = .inner, .at = 0 };
    const d_min = music.wheel.Cell{ .ring = .inner, .at = 11 };
    const e_min = music.wheel.Cell{ .ring = .inner, .at = 1 };
    const a_maj = music.wheel.Cell{ .ring = .outer, .at = 3 };
    const fs_maj = music.wheel.Cell{ .ring = .outer, .at = 6 };

    // A major (3 o'clock outer) and A minor (12 o'clock inner) are distinct cells with the same root colour
    try expect(a_maj.index() != a_min.index());
    try expectEqual(music.wheel.Ring.outer, a_maj.ring);
    try expectEqual(music.wheel.Ring.inner, a_min.ring);

    // Pure tuning of sunlit six
    try approx(c_hz, cellHz(c_hz, c_maj), 0.01);
    try approx(c_hz * 4.0 / 3.0, cellHz(c_hz, f_maj), 0.01);
    try approx(c_hz * 3.0 / 2.0, cellHz(c_hz, g_maj), 0.01);
    try approx(c_hz * 10.0 / 9.0, cellHz(c_hz, d_min), 0.01);
    try approx(c_hz * 5.0 / 3.0, cellHz(c_hz, a_min), 0.01);
    try approx(c_hz * 5.0 / 4.0, cellHz(c_hz, e_min), 0.01);

    // C -> Am in pure triad mode shares TWO common tones (C and E) and moves only ONE voice (G -> A)!
    const v_rel = chordVoicing(c_hz, c_maj, a_min, .triad);
    try expectEqual(@as(u8, 3), v_rel.n);
    const kept_rel: u8 = @as(u8, @intFromBool(v_rel.kept[0])) + @as(u8, @intFromBool(v_rel.kept[1])) + @as(u8, @intFromBool(v_rel.kept[2]));
    try expectEqual(@as(u8, 2), kept_rel);
    try expect(!v_rel.kept[0]); // A is new
    try expect(v_rel.kept[1]); // E stayed!
    try expect(v_rel.kept[2]); // C stayed!

    // C -> G and C -> F in triad mode each keep 1 common tone (G and C respectively)
    const v_g = chordVoicing(c_hz, c_maj, g_maj, .triad);
    try expectEqual(@as(u8, 1), @as(u8, @intFromBool(v_g.kept[0])) + @as(u8, @intFromBool(v_g.kept[1])) + @as(u8, @intFromBool(v_g.kept[2])));
    const v_f = chordVoicing(c_hz, c_maj, f_maj, .triad);
    try expectEqual(@as(u8, 1), @as(u8, @intFromBool(v_f.kept[0])) + @as(u8, @intFromBool(v_f.kept[1])) + @as(u8, @intFromBool(v_f.kept[2])));

    // Open-fifth mode has 2 tones; Low-bass mode adds chord's own sub-octave root even outside the key
    const v_open = chordVoicing(c_hz, c_maj, g_maj, .open_5th);
    try expectEqual(@as(u8, 2), v_open.n);
    const v_far = chordVoicing(c_hz, c_maj, fs_maj, .triad);
    try expectEqual(@as(f32, 0.0), v_far.ground_hz); // no clashing C ground under F#
    const v_far_bass = chordVoicing(c_hz, c_maj, fs_maj, .low_bass);
    try approx(cellHz(c_hz, fs_maj) * 0.5, v_far_bass.ground_hz, 0.01);

    // Every one of all 24 cells has valid pitch, label, and voicing
    for (0..24) |idx| {
        const c = music.wheel.Cell.fromIndex(@intCast(idx));
        const hz = cellHz(c_hz, c);
        try expect(hz >= c_hz * 0.99 and hz <= c_hz * 2.01);
        try expect(cellName(c).len >= 5);
        const v = chordVoicing(c_hz, c_maj, c, .triad);
        try expectEqual(@as(u8, 3), v.n);
    }
}
