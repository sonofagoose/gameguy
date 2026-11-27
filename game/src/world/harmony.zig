//! The harmony the world stands in, and the world answering it (docs/engine.md, "The harmony" and
//! "One step, in order"; ROADMAP.md steps 1.4 & 1.5).
//!
//! This is the single bridge where the world's day and ring position become exact rational music
//! (`music/`), voice-led root+fifth voicings over the ground note, standings for all twelve
//! colours, and chord labels shared by the HUD, Pause Workbench, and logs.
//!
//! No platform.
const std = @import("std");
const world_mod = @import("world.zig");
const World = world_mod.World;
const music = @import("../music/music.zig");
const standing = @import("../law/standing.zig");
const react = @import("../law/react.zig");
const land = world_mod.land;

/// The day. Until a morning can be chosen on the island it is always the Garden's own (C).
pub fn day(w: *const World) music.Day {
    _ = w;
    return .{};
}

/// How far Hum's voice has opened. It has its fifth from Drip; the third is found underneath.
pub fn voice(w: *const World) music.Voice {
    _ = w;
    return music.Voice.open_fifths;
}

/// The chord under Hum: the world keeps it as a place on the day's ring of seven (-1..5).
pub fn chord(w: *const World) music.Chord {
    return day(w).ringChord(w.home_k);
}

/// The notes of it that are sounding.
pub fn members(w: *const World) music.chord.Members {
    return chord(w).plain(voice(w));
}

/// Where things lean toward: the middle of the Garden, which is its Mirror Pool.
pub fn home(w: *const World) [2]f32 {
    _ = w;
    return .{ land.pool[0], land.pool[1] };
}

/// Pure frequency of a ring chord's root folded into `[day_hz, 2 * day_hz)` so Hum's call, hum and
/// fork remain in the clear speaker-friendly register.
pub fn ringHz(day_hz: f32, pos: i8) f32 {
    const ch = (music.Day{}).ringChord(pos);
    var hz: f32 = @floatCast(ch.root.hz(day_hz));
    while (hz < day_hz * 0.999) hz *= 2.0;
    while (hz >= day_hz * 1.999) hz *= 0.5;
    return hz;
}

/// ASCII-safe full label for any of the seven chords on the day's ring (for HUD, Pause Menu, logs).
pub fn chordName(pos: i8) []const u8 {
    return switch (pos) {
        music.Ring.lift => "F  LIFT",
        music.Ring.home => "C  HOME",
        music.Ring.lean => "G  LEAN",
        music.Ring.runs => "Dm  RUNS",
        music.Ring.remembers => "Am  REMEMBERS",
        music.Ring.aches => "Em  ACHES",
        music.Ring.seam => "B  SEAM",
        else => "C  HOME",
    };
}

/// Compact label for the 1-line Corner Telemetry HUD.
pub fn chordShort(pos: i8) []const u8 {
    return switch (pos) {
        music.Ring.lift => "F LIFT",
        music.Ring.home => "C HOME",
        music.Ring.lean => "G LEAN",
        music.Ring.runs => "Dm RUN",
        music.Ring.remembers => "Am MEM",
        music.Ring.aches => "Em ACH",
        music.Ring.seam => "B SEAM",
        else => "C HOME",
    };
}

/// Voice-led root+fifth chord sound over the ground note (ROADMAP.md, step 1.5;
/// design/the-wormhole.md, "Melody is the main character"): never plays the third.
/// Notes whose colour stayed from the previous chord are marked `kept` so they continue ringing
/// rather than hard-restriking; moved notes land in the nearest warm mid-low octave.
pub const Voicing = struct {
    /// Struck ground note underneath (0 when the chord root already is the ground note).
    ground_hz: f32 = 0.0,
    notes: [2]f32 = .{ 0.0, 0.0 },
    kept: [2]bool = .{ false, false },
    n: u8 = 0,
};

/// Fold chord tones into the clear speaker-friendly mid octave `[E4 .. E5]` (`[1.25, 2.55] * day_hz`)
/// so every adjacent step around the 7-chord ring keeps its common tone at the exact same pitch
/// and stays cleanly above the ground note (`day_hz * 0.5`).
fn foldChordTone(day_hz: f32, hz0: f32) f32 {
    var hz = hz0;
    const lo = day_hz * 1.25;
    const hi = day_hz * 2.55;
    while (hz < lo) hz *= 2.0;
    while (hz > hi) hz *= 0.5;
    return hz;
}

pub fn chordVoicing(day_hz: f32, from_k: i8, to_k: i8) Voicing {
    const d = music.Day{};
    const prev = d.ringChord(from_k).members(music.Voice.open_fifths, 2);
    const next = d.ringChord(to_k).members(music.Voice.open_fifths, 2);
    const chg = music.change.between(prev, next);
    var out = Voicing{ .n = next.n };
    // The ground's own note sits underneath when the chord root is not already home's cell
    if (next.n > 0 and next.notes[0].cell() != d.land()) {
        out.ground_hz = day_hz * 0.5;
    }
    for (0..next.n) |i| {
        const note = next.notes[i];
        const stayed = (chg.shared & music.wheel.colour(note.cell())) != 0;
        out.kept[i] = stayed;
        // Prefer the voice-led octave from `chg` when a note moved into this colour
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

/// What every colour is to the chord now. `was` is the place on the ring the chord stood at
/// before, if it has just moved.
pub fn standings(w: *const World, was: ?i8) [12]standing.Standing {
    const d = day(w);
    const before: ?music.chord.Members = if (was) |k| d.ringChord(k).plain(voice(w)) else null;
    return standing.all(d, members(w), chord(w).root, before, w.home_k == music.Ring.home);
}

/// One step of the world answering the chord: what is in it wakes, what the lift raises rises,
/// what the lean tilts leans and winds, and a step home lands or settles it.
pub fn step(w: *World) void {
    const changed = w.react_k != w.home_k;
    const way: music.change.Way = if (changed) music.change.way(w.react_k, w.home_k) else .none;
    const all = standings(w, if (changed) w.react_k else null);
    react.step(&w.react, &all, music.Ring.axis(w.home_k), way);
    w.react_k = w.home_k;
}

/// How far a point of a thing has been moved by the chord (law/react.zig).
pub fn moved(w: *const World, cell: u8, reacts: react.Reacts, up: f32, x: f32, z: f32) [3]f32 {
    return react.moved(&w.react, cell, reacts, up, x, z, home(w));
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const approx = std.testing.expectApproxEqAbs;

test "every adjacent step on the 7-chord ring keeps one common tone and moves one voice, with no third" {
    const c_hz: f32 = 261.63;
    try approx(c_hz, ringHz(c_hz, music.Ring.home), 0.01);
    try approx(c_hz * 4.0 / 3.0, ringHz(c_hz, music.Ring.lift), 0.01);
    try approx(c_hz * 3.0 / 2.0, ringHz(c_hz, music.Ring.lean), 0.01);
    try approx(c_hz * 10.0 / 9.0, ringHz(c_hz, music.Ring.runs), 0.01);
    try approx(c_hz * 5.0 / 3.0, ringHz(c_hz, music.Ring.remembers), 0.01);
    try approx(c_hz * 5.0 / 4.0, ringHz(c_hz, music.Ring.aches), 0.01);
    try approx(c_hz * 15.0 / 8.0, ringHz(c_hz, music.Ring.seam), 0.01);

    // Every single step around the ring of seven in open fifths shares exactly 1 common tone
    var pos: i8 = music.Ring.home;
    for (0..music.Ring.size) |_| {
        const next = music.Ring.step(pos, 1);
        const v = chordVoicing(c_hz, pos, next);
        try expectEqual(@as(u8, 2), v.n);
        const kept_count: u8 = @as(u8, @intFromBool(v.kept[0])) + @as(u8, @intFromBool(v.kept[1]));
        try expectEqual(@as(u8, 1), kept_count);
        if (next == music.Ring.home) {
            try expectEqual(@as(f32, 0.0), v.ground_hz);
        } else {
            try approx(c_hz * 0.5, v.ground_hz, 0.01);
        }
        pos = next;
    }
    try expectEqual(music.Ring.home, pos);
}
