//! The wheel: twelve cells round by fifths, on two rings (design/the-game.md, "The wheel is the
//! map"). The outer ring is the twelve lands and their major chords. The inner ring is the twelve
//! caves and their minor chords, each under the land whose notes it shares.
//!
//! No world in it and no platform.
const std = @import("std");
const Note = @import("note.zig").Note;

pub const Ring = enum(u1) { outer, inner };

/// One of the wheel's twenty-four cells. `at` counts cells clockwise from C at the top, a fifth to
/// a cell. An inner cell is counted by the land it lies under: A minor is at nought, under C.
pub const Cell = struct {
    ring: Ring = .outer,
    at: u4 = 0,

    /// The colour of its chord's root. A cave's root is three cells on from its land's.
    pub fn root(self: Cell) u4 {
        return if (self.ring == .outer) self.at else turned(self.at, 3);
    }

    /// The cell above or below this one: a land's cave, or a cave's land.
    pub fn other(self: Cell) Cell {
        return .{ .ring = if (self.ring == .outer) .inner else .outer, .at = self.at };
    }

    /// Its letters, as the wheel is drawn.
    pub fn name(self: Cell) []const u8 {
        return names[@intFromEnum(self.ring)][self.at];
    }

    /// Nought to twenty-three: the outer ring, then the inner.
    pub fn index(self: Cell) u5 {
        return @as(u5, @intFromEnum(self.ring)) * 12 + self.at;
    }

    pub fn fromIndex(i: u5) Cell {
        return .{ .ring = if (i < 12) .outer else .inner, .at = @intCast(i % 12) };
    }
};

/// The letters of the twenty-four cells, clockwise from the top: the outer ring, then the inner.
pub const names = [2][12][]const u8{
    .{ "C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F" },
    .{ "Am", "Em", "Bm", "F#m", "C#m", "G#m", "D#m", "Bbm", "Fm", "Cm", "Gm", "Dm" },
};

/// How many cells clockwise from `from` round to `to`: nought to eleven.
pub fn clockwise(from: u4, to: u4) u4 {
    return @intCast(@mod(@as(i32, to) - @as(i32, from), 12));
}

/// The same, the short way round: sharpward counts up and flatward down, from -5 to 6.
pub fn steps(from: u4, to: u4) i8 {
    const k: i8 = clockwise(from, to);
    return if (k > 6) k - 12 else k;
}

/// How far apart two cells are, the short way round: nought to six.
pub fn apart(a: u4, b: u4) u4 {
    const k = clockwise(a, b);
    return if (k > 6) 12 - k else k;
}

/// The cell `by` cells clockwise of `cell`.
pub fn turned(cell: u4, by: i32) u4 {
    return @intCast(@mod(@as(i32, cell) + by, 12));
}

/// A cell as one of the treaty's twelve half steps up from C, and back. A fifth is seven half
/// steps, and seven sevens are one more than four dozen, so the same sum goes both ways.
pub fn semitoneOf(cell: u4) u4 {
    return @intCast((@as(u32, cell) * 7) % 12);
}
pub fn cellOf(semitone: u4) u4 {
    return @intCast((@as(u32, semitone) * 7) % 12);
}

/// What a cell does, by how far clockwise it stands from home, counted in threes
/// (design/the-depths.md, "Your second picture is a compass"): every third cell holds, the ones
/// after them lean, and the ones after those lift.
pub const Axis = enum { hold, lean, lift };

pub fn axis(home: u4, at: u4) Axis {
    return switch (clockwise(home, at) % 3) {
        0 => .hold,
        1 => .lean,
        else => .lift,
    };
}

/// A set of colours, a bit to a cell.
pub const Colours = u12;

pub fn colour(cell: u4) Colours {
    return @as(Colours, 1) << cell;
}

pub fn coloursOf(notes: []const Note) Colours {
    var set: Colours = 0;
    for (notes) |n| set |= colour(n.cell());
    return set;
}

pub fn count(set: Colours) u8 {
    return @popCount(set);
}

const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "round the wheel" {
    try expectEqual(@as(u4, 1), clockwise(0, 1));
    try expectEqual(@as(u4, 11), clockwise(0, 11));
    try expectEqual(@as(i8, -1), steps(0, 11));
    try expectEqual(@as(i8, 6), steps(0, 6));
    try expectEqual(@as(i8, -5), steps(0, 7));
    try expectEqual(@as(u4, 6), apart(0, 6));
    try expectEqual(@as(u4, 1), apart(11, 0));
    try expectEqual(@as(u4, 11), turned(0, -1));
    try expectEqual(@as(u4, 2), turned(11, 3));
}

test "a cell's letters, and the cave under a land" {
    const c = Cell{};
    try expectEqualStrings("C", c.name());
    try expectEqualStrings("Am", c.other().name());
    // A minor's root is A, three cells on from C
    try expectEqual(@as(u4, 3), c.other().root());
    try expectEqualStrings("Em", (Cell{ .at = 1 }).other().name());
    try expectEqualStrings("Dm", (Cell{ .at = 11 }).other().name());
    for (0..24) |i| try expectEqual(@as(u5, @intCast(i)), Cell.fromIndex(@intCast(i)).index());
}

test "cells and half steps" {
    // C, G, D: nought, seven and two half steps up
    try expectEqual(@as(u4, 0), semitoneOf(0));
    try expectEqual(@as(u4, 7), semitoneOf(1));
    try expectEqual(@as(u4, 2), semitoneOf(2));
    for (0..12) |c| try expectEqual(@as(u4, @intCast(c)), cellOf(semitoneOf(@intCast(c))));
}

test "every third cell holds, the next leans, the next lifts" {
    try expectEqual(Axis.hold, axis(0, 0));
    try expectEqual(Axis.lean, axis(0, 1));
    try expectEqual(Axis.lift, axis(0, 11));
    // A flat lifts, D flat leans, E flat holds (design/the-depths.md)
    try expectEqual(Axis.lift, axis(0, 8));
    try expectEqual(Axis.lean, axis(0, 7));
    try expectEqual(Axis.hold, axis(0, 9));
}
