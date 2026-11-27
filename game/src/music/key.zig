//! A day: the land called home, and what that makes of everything else (design/the-game.md, "A
//! day has a key"; design/the-depths.md, "Your third picture is the long way home").
//!
//! The day's note is Hum's, and it never moves. Every chord of the wheel's twenty-four is tuned
//! pure to its own root, with its root placed so that Hum's note sits exactly on a floor of it
//! (design/the-wormhole.md, "The elevator").
//!
//! No world in it and no platform.
const std = @import("std");
const Note = @import("note.zig").Note;
const wheel = @import("wheel.zig");
const chord_mod = @import("chord.zig");
const Chord = chord_mod.Chord;

/// The seven notes of a key, pure, over its own note.
pub const scale = [7]Note{
    Note.c,
    Note.r(9, 8),
    Note.r(5, 4),
    Note.r(4, 3),
    Note.r(3, 2),
    Note.r(5, 3),
    Note.r(15, 8),
};

/// The day's own ring of seven chords, counted in fifths from home. From home, falling a fifth is
/// the lift and rising one is the lean; past the lean are the three caves, and then the seam.
pub const Ring = struct {
    pub const lift: i8 = -1;
    pub const home: i8 = 0;
    pub const lean: i8 = 1;
    pub const runs: i8 = 2;
    pub const remembers: i8 = 3;
    pub const aches: i8 = 4;
    pub const seam: i8 = 5;
    pub const least: i8 = lift;
    pub const most: i8 = seam;
    pub const size = 7;

    /// A step round the ring: up a fifth inside the key, or down one.
    pub fn step(pos: i8, by: i32) i8 {
        return @intCast(@mod(@as(i32, pos) - least + by, size) + least);
    }

    /// The chord under a land's chord, or the land's chord over a cave's: a chord and its relative.
    /// The seam has neither.
    pub fn other(pos: i8) ?i8 {
        return switch (pos) {
            lift, home, lean => pos + 3,
            runs, remembers, aches => pos - 3,
            else => null,
        };
    }

    /// Whether a place on the ring is one of the three caves.
    pub fn below(pos: i8) bool {
        return pos >= runs and pos <= aches;
    }

    /// Whether the chord at a place on the ring holds, lifts or leans. A cave does the job of the
    /// land over it, and the seam leans, being the top of the lean.
    pub fn axis(pos: i8) wheel.Axis {
        return switch (pos) {
            lift, runs => .lift,
            lean, aches, seam => .lean,
            else => .hold,
        };
    }
};

/// What Hum's note is over a root that stands so many cells clockwise of home: the interval from
/// that root up to the day's note. Clockwise from home: the root itself, the eleventh, the low
/// seventh, the low third, the low thirteenth, the low ninth, the raised eleventh, the seventh,
/// the third, the thirteenth, the ninth, the fifth.
const hears = [12]Note{
    Note.r(1, 1),
    Note.r(4, 3),
    Note.r(16, 9),
    Note.r(6, 5),
    Note.r(8, 5),
    Note.r(16, 15),
    Note.r(45, 32),
    Note.r(15, 8),
    Note.r(5, 4),
    Note.r(5, 3),
    Note.r(9, 8),
    Note.r(3, 2),
};
/// One chord is placed otherwise. The cave that runs stands on the lower of the key's two seconds
/// (10/9, where the lean's is 9/8), so that it shares two notes exactly with the lift over it. Hum's
/// note is then 9/5 over its root.
const hears_from_the_cave_that_runs = Note.r(9, 5);

/// The floor Hum's note stands on in a chord, named as a player of chords would name it
/// (design/the-wormhole.md, "The elevator").
pub const Floor = enum {
    one,
    eleven,
    low_seven,
    low_three,
    low_thirteen,
    low_nine,
    raised_eleven,
    seven,
    three,
    thirteen,
    nine,
    five,

    /// By how many cells clockwise of home the chord's root stands.
    pub fn of(cells_clockwise: u4) Floor {
        return @enumFromInt(cells_clockwise % 12);
    }
};

/// What a place is like today (design/the-game.md, "Three faces above, three below").
pub const Face = enum {
    asleep,
    floats,
    home,
    leans,
    runs,
    remembers,
    aches,

    pub fn awake(self: Face) bool {
        return self != .asleep;
    }
};

pub const Day = struct {
    /// The land called home, in fifths from the Garden: sharpward up to 6, flatward down to -6.
    /// The Seam has a bank at each end.
    home: i8 = 0,

    /// Home's cell on the wheel.
    pub fn land(self: Day) u4 {
        return @intCast(@mod(@as(i32, self.home), 12));
    }

    /// The day's note: the land's own, reached from the Garden by pure fifths, in the octave
    /// nearest the Garden's C. It is Hum's note all day.
    pub fn note(self: Day) Note {
        return (Note{ .fifths = self.home }).near(Note.c);
    }

    /// One of the key's seven notes, nought to six, at or above the day's note.
    pub fn degree(self: Day, d: u3) Note {
        return self.note().plus(scale[d]);
    }

    /// The seven colours of the day's key.
    pub fn colours(self: Day) wheel.Colours {
        var set: wheel.Colours = 0;
        for (scale) |interval| set |= wheel.colour(self.note().plus(interval).cell());
        return set;
    }

    /// Which of the key's seven a colour is, if it is one of them.
    pub fn degreeOf(self: Day, cell: u4) ?u3 {
        for (scale, 0..) |interval, d| {
            if (self.note().plus(interval).cell() == cell) return @intCast(d);
        }
        return null;
    }

    /// The chord of any of the wheel's twenty-four cells, as it is tuned today.
    pub fn chordOn(self: Day, cell: wheel.Cell) Chord {
        const runs = cell.ring == .inner and wheel.steps(self.land(), cell.at) == -1;
        const up = if (runs) hears_from_the_cave_that_runs else hears[wheel.clockwise(self.land(), cell.root())];
        return .{
            .root = self.note().minus(up),
            .kind = if (cell.ring == .outer) .major else .minor,
        };
    }

    /// The cell a place on the ring is, if it has one. The seam has none.
    pub fn ringCell(self: Day, pos: i8) ?wheel.Cell {
        return switch (pos) {
            Ring.lift, Ring.home, Ring.lean => .{ .ring = .outer, .at = wheel.turned(self.land(), pos) },
            Ring.runs, Ring.remembers, Ring.aches => .{ .ring = .inner, .at = wheel.turned(self.land(), pos - 3) },
            else => null,
        };
    }

    /// Where on the day's ring a cell is, if it is one of the lit six.
    pub fn ringOf(self: Day, cell: wheel.Cell) ?i8 {
        const d = wheel.steps(self.land(), cell.at);
        if (d < -1 or d > 1) return null;
        return if (cell.ring == .outer) d else d + 3;
    }

    /// The chord at a place on the day's ring of seven.
    pub fn ringChord(self: Day, pos: i8) Chord {
        if (self.ringCell(pos)) |cell| return self.chordOn(cell);
        // the seam: the chord on the key's seventh note, a half step under the day's note
        return .{ .root = self.note().minus(hears[5]), .kind = .seam };
    }

    /// The floor Hum's note stands on over a cell's chord.
    pub fn floorOn(self: Day, cell: wheel.Cell) Floor {
        return Floor.of(wheel.clockwise(self.land(), cell.root()));
    }

    /// What a place is like today: one of the six that are awake, or asleep.
    pub fn face(self: Day, place: wheel.Cell) Face {
        const d = wheel.steps(self.land(), place.at);
        const above = place.ring == .outer;
        return switch (d) {
            -1 => if (above) .floats else .runs,
            0 => if (above) .home else .remembers,
            1 => if (above) .leans else .aches,
            else => .asleep,
        };
    }

    /// Whether a cell holds, leans or lifts today. A cave does the job of the land over it.
    pub fn axis(self: Day, cell: wheel.Cell) wheel.Axis {
        return wheel.axis(self.land(), cell.at);
    }
};

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "the ring of seven, on one finger" {
    // rising a fifth from home: the lean, the three caves, the seam, the lift, home
    var pos: i8 = Ring.home;
    const up = [7]i8{ Ring.lean, Ring.runs, Ring.remembers, Ring.aches, Ring.seam, Ring.lift, Ring.home };
    for (up) |want| {
        pos = Ring.step(pos, 1);
        try expectEqual(want, pos);
    }
    // falling a fifth from home: the lift, across the seam, and down through the caves
    const down = [7]i8{ Ring.lift, Ring.seam, Ring.aches, Ring.remembers, Ring.runs, Ring.lean, Ring.home };
    for (down) |want| {
        pos = Ring.step(pos, -1);
        try expectEqual(want, pos);
    }
    // a chord and the one under it
    try expectEqual(@as(?i8, Ring.remembers), Ring.other(Ring.home));
    try expectEqual(@as(?i8, Ring.lift), Ring.other(Ring.runs));
    try expect(Ring.other(Ring.seam) == null);
    // each place's job: and it agrees with counting cells in threes round the wheel
    const day = Day{};
    var p: i8 = Ring.least;
    while (p < Ring.seam) : (p += 1) try expectEqual(day.axis(day.ringCell(p).?), Ring.axis(p));
    try expectEqual(wheel.Axis.lean, Ring.axis(Ring.seam));
}

test "the six chords of a day in C, and its seam" {
    const day = Day{};
    const want = [7]struct { i8, Note, chord_mod.Kind }{
        .{ Ring.lift, Note.r(4, 3), .major },
        .{ Ring.home, Note.r(1, 1), .major },
        .{ Ring.lean, Note.r(3, 2), .major },
        .{ Ring.runs, Note.r(10, 9), .minor },
        .{ Ring.remembers, Note.r(5, 3), .minor },
        .{ Ring.aches, Note.r(5, 4), .minor },
        .{ Ring.seam, Note.r(15, 8), .seam },
    };
    for (want) |w| {
        const ch = day.ringChord(w[0]);
        try expect(ch.root.sameTuning(w[1]));
        try expectEqual(w[2], ch.kind);
        // every root is at or under Hum's note, within an octave of it
        try expect(ch.root.value() <= 1.0 and ch.root.value() > 0.5);
    }
    // every note of every chord is one of the key's own, to the comma, but for the lean's D
    for (want[0..6]) |w| {
        const triad = day.ringChord(w[0]).triad();
        for (triad.slice()) |n| {
            const d = day.degreeOf(n.cell()).?;
            const own = day.degree(d);
            if (w[0] == Ring.runs and d == 1) {
                try expect(n.sameTuning(Note.r(10, 9)));
            } else try expect(n.sameTuning(own));
        }
    }
}

test "a day in G: its note, its colours, its six" {
    const day = Day{ .home = 1 };
    try expectEqual(Note.r(3, 4), day.note());
    // one sharp: F is out and F sharp is in
    try expect(day.degreeOf(11) == null);
    try expectEqual(@as(?u3, 6), day.degreeOf(6));
    try expectEqual(@as(u8, 7), wheel.count(day.colours()));
    try expectEqual(@as(u4, 0), day.ringCell(Ring.lift).?.at);
    try expectEqual(@as(?i8, Ring.runs), day.ringOf(.{ .ring = .inner, .at = 0 }));
    try expect(day.ringOf(.{ .at = 11 }) == null);
    try expect(day.ringCell(Ring.seam) == null);
}

test "one land, three days" {
    const garden = wheel.Cell{};
    const cave = garden.other();
    try expectEqual(Face.floats, (Day{ .home = 1 }).face(garden));
    try expectEqual(Face.home, (Day{ .home = 0 }).face(garden));
    try expectEqual(Face.leans, (Day{ .home = -1 }).face(garden));
    try expectEqual(Face.runs, (Day{ .home = 1 }).face(cave));
    try expectEqual(Face.remembers, (Day{ .home = 0 }).face(cave));
    try expectEqual(Face.aches, (Day{ .home = -1 }).face(cave));
    // on the other nine it sleeps
    var asleep: u8 = 0;
    var h: i8 = -5;
    while (h <= 6) : (h += 1) {
        if (!(Day{ .home = h }).face(garden).awake()) asleep += 1;
    }
    try expectEqual(@as(u8, 9), asleep);
}

test "the Seam has two banks, a comma apart" {
    const sharp = (Day{ .home = 6 }).note();
    const flat = (Day{ .home = -6 }).note();
    try expect(sharp.sameColour(flat));
    try std.testing.expectApproxEqAbs(@as(f64, 23.460), @import("note.zig").centsApart(sharp, flat), 0.001);
}
