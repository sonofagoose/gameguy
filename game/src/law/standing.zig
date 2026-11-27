//! What a note is to the harmony, right now: its standing (docs/engine.md, "What a thing is to
//! the harmony"). It is worked out for each of the wheel's twelve colours, not for each thing: a
//! thing asks by its colour. Everything in the world that reacts to the chord reads this and
//! nothing else.
//!
//! Awake is by colour. How cleanly a thing answers is by tuning, and is the sympathy law's.
//!
//! No world in it and no platform.
const std = @import("std");
const music = @import("../music/music.zig");
const wheel = music.wheel;
const chord_mod = music.chord;
const change_mod = music.change;

/// What the last change of chord did to a colour.
pub const Fate = enum {
    /// It was not in the chord and is not.
    apart,
    /// It was in the chord and still is.
    stayed,
    /// It has come into the chord.
    arrived,
    /// It has left the chord, and its light goes to the neighbour a step above it, or below.
    left_up,
    left_down,
};

pub const Standing = struct {
    /// In the chord, and as what; null when it is not.
    role: ?chord_mod.Role = null,
    /// In the day's key, and as which of its seven, nought to six; null when it is not.
    degree: ?u3 = null,
    /// How far round the wheel from the chord's root, the short way: sharpward is more than nought.
    from_root: i8 = 0,
    /// Which way it wants to go when home is under it: the key's seventh tips up toward home, and
    /// its fourth tips down toward the third.
    tips: i8 = 0,
    fate: Fate = .apart,

    pub fn awake(self: Standing) bool {
        return self.role != null;
    }
};

/// The standing of every colour. `was` is the chord before the last change, if there has been
/// one. `at_home` is whether the chord is the day's home.
pub fn all(day: music.Day, now: chord_mod.Members, root: music.Note, was: ?chord_mod.Members, at_home: bool) [12]Standing {
    var out: [12]Standing = @splat(.{});
    var moved: ?change_mod.Change = null;
    if (was) |before| moved = change_mod.between(before, now);
    for (&out, 0..) |*s, i| {
        const cell: u4 = @intCast(i);
        s.role = now.roleOf(cell);
        s.degree = day.degreeOf(cell);
        s.from_root = wheel.steps(root.cell(), cell);
        if (at_home) {
            if (s.degree) |d| {
                if (d == 6) s.tips = 1;
                if (d == 3) s.tips = -1;
            }
        }
        const is_in = s.role != null;
        if (moved) |m| {
            if (m.of(cell)) |move| {
                s.fate = switch (move.fate) {
                    .stayed => .stayed,
                    .rose => .left_up,
                    .fell => .left_down,
                };
            } else if (is_in) {
                s.fate = .arrived;
            }
        } else if (is_in) {
            s.fate = .stayed;
        }
    }
    return out;
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "home in C: two colours awake before the third is found, three after" {
    const day = music.Day{};
    const home = day.ringChord(music.Ring.home);
    const bare = all(day, home.plain(music.Voice.open_fifths), home.root, null, true);
    var awake: u8 = 0;
    for (bare) |s| {
        if (s.awake()) awake += 1;
    }
    try expectEqual(@as(u8, 2), awake);
    try expectEqual(chord_mod.Role.root, bare[0].role.?);
    try expectEqual(chord_mod.Role.fifth, bare[1].role.?);
    try expect(!bare[4].awake());
    const warm = all(day, home.plain(music.Voice.warm), home.root, null, true);
    try expectEqual(chord_mod.Role.third, warm[4].role.?);
    // F sharp is not in the day's key; B is its seventh and tips up; F is its fourth and tips down
    try expect(bare[6].degree == null);
    try expectEqual(@as(i8, 1), bare[5].tips);
    try expectEqual(@as(i8, -1), bare[11].tips);
    try expectEqual(@as(i8, 0), bare[2].tips);
}

test "home to the lean: G stays, D arrives, C leaves" {
    const day = music.Day{};
    const home = day.ringChord(music.Ring.home);
    const lean = day.ringChord(music.Ring.lean);
    const s = all(day, lean.plain(music.Voice.open_fifths), lean.root, home.plain(music.Voice.open_fifths), false);
    try expectEqual(Fate.stayed, s[1].fate);
    try expectEqual(Fate.arrived, s[2].fate);
    try expectEqual(Fate.left_up, s[0].fate);
    try expectEqual(Fate.apart, s[4].fate);
    // nothing tips unless home is under it
    try expectEqual(@as(i8, 0), s[5].tips);
    try expectEqual(@as(i8, -1), s[0].from_root);
}
