//! The harmony the world stands in, and the world answering it (docs/engine.md, "The harmony" and
//! "One step, in order"). This is where the world's own numbers (which chord, whose day) become
//! the music's, and where the reactions are stepped. The rest of the rules ask here and never work
//! a chord out for themselves.
//!
//! No platform.
const std = @import("std");
const world_mod = @import("world.zig");
const World = world_mod.World;
const music = @import("../music/music.zig");
const standing = @import("../law/standing.zig");
const react = @import("../law/react.zig");
const land = world_mod.land;

/// The day. Until a morning can be chosen on the island it is always the Garden's own.
pub fn day(w: *const World) music.Day {
    _ = w;
    return .{};
}

/// How far Hum's voice has opened. It has its fifth from Drip; the third is found underneath.
pub fn voice(w: *const World) music.Voice {
    _ = w;
    return music.Voice.open_fifths;
}

/// The chord under Hum: the world keeps it as a place on the day's ring of seven.
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
