//! A change of chord: what stays, what leaves, and where it goes (design/the-depths.md, "What
//! moves least"). And which way home a step was (design/the-game.md, "Coming home, four ways").
//!
//! The rule: what is in both chords stays where it is, and what leaves moves to the nearest note
//! of the new chord.
//!
//! No world in it and no platform.
const std = @import("std");
const Note = @import("note.zig").Note;
const wheel = @import("wheel.zig");
const chord_mod = @import("chord.zig");
const Members = chord_mod.Members;
const Ring = @import("key.zig").Ring;

/// What became of one note of the chord that was.
pub const Fate = enum { stayed, rose, fell };

pub const Move = struct {
    /// The note as it was, and the note of the new chord it became, in the octave nearest it.
    from: Note = Note.c,
    to: Note = Note.c,
    fate: Fate = .stayed,
    /// How far it went, in the treaty's half steps: up is more than nought.
    half_steps: i8 = 0,

    /// The interval it moved by: nothing at all, or a comma, for a note that stayed.
    pub fn by(self: Move) Note {
        return if (self.fate == .fell) self.from.minus(self.to) else self.to.minus(self.from);
    }
};

pub const Change = struct {
    moves: [chord_mod.most]Move = @splat(.{}),
    n: u8 = 0,
    /// The colours the two chords share.
    shared: wheel.Colours = 0,
    /// The colours of the new chord that no note of the old one stayed on or moved to.
    arrived: wheel.Colours = 0,

    pub fn slice(self: *const Change) []const Move {
        return self.moves[0..self.n];
    }

    /// What became of the old chord's note of a colour, if it had one.
    pub fn of(self: *const Change, cell: u4) ?Move {
        for (self.slice()) |m| {
            if (m.from.cell() == cell) return m;
        }
        return null;
    }

    pub fn stayed(self: *const Change) u8 {
        return wheel.count(self.shared);
    }
};

/// How many half steps from one note up to the nearest note of another's colour: -6 to 6.
fn halfSteps(from: Note, to: Note) i8 {
    const d: i8 = @intCast(@mod(@as(i32, to.semitone()) - @as(i32, from.semitone()), 12));
    return if (d > 6) d - 12 else d;
}

fn moveOf(from: Note, to: Note) Move {
    const steps = halfSteps(from, to);
    return .{
        .from = from,
        .to = to.near(from),
        .fate = if (steps == 0) .stayed else if (steps > 0) .rose else .fell,
        .half_steps = steps,
    };
}

/// The change from one chord's sounding notes to another's. When both have as many notes, each old
/// note goes to a new one of its own, and of all such ways the one that moves least in all is
/// taken. When they differ, each old note goes to its nearest.
pub fn between(from: Members, to: Members) Change {
    var change = Change{ .n = from.n, .shared = from.colours() & to.colours() };
    if (from.n == to.n and from.n > 0) {
        var order: [chord_mod.most]u8 = .{ 0, 1, 2, 3, 4 };
        var best: [chord_mod.most]u8 = order;
        var best_cost: u32 = std.math.maxInt(u32);
        const n: usize = from.n;
        // every order of the new notes, in a fixed sequence, so a tie always falls the same way
        var done = false;
        while (!done) {
            var cost: u32 = 0;
            for (0..n) |i| cost += @abs(halfSteps(from.notes[i], to.notes[order[i]]));
            if (cost < best_cost) {
                best_cost = cost;
                best = order;
            }
            done = !nextOrder(order[0..n]);
        }
        for (0..n) |i| change.moves[i] = moveOf(from.notes[i], to.notes[best[i]]);
    } else {
        for (0..from.n) |i| {
            var nearest: usize = 0;
            var least: u8 = std.math.maxInt(u8);
            for (0..to.n) |j| {
                const far = @abs(halfSteps(from.notes[i], to.notes[j]));
                if (far < least) {
                    least = far;
                    nearest = j;
                }
            }
            if (to.n > 0) change.moves[i] = moveOf(from.notes[i], to.notes[nearest]) else change.moves[i] = moveOf(from.notes[i], from.notes[i]);
        }
    }
    var reached: wheel.Colours = 0;
    for (change.slice()) |m| reached |= wheel.colour(m.to.cell());
    change.arrived = to.colours() & ~reached;
    return change;
}

/// The next order of a list in the dictionary's sequence; false when the last has been given.
fn nextOrder(order: []u8) bool {
    if (order.len < 2) return false;
    var i: usize = order.len - 1;
    while (i > 0 and order[i - 1] >= order[i]) i -= 1;
    if (i == 0) return false;
    var j: usize = order.len - 1;
    while (order[j] <= order[i - 1]) j -= 1;
    std.mem.swap(u8, &order[i - 1], &order[j]);
    std.mem.reverse(u8, order[i..]);
    return true;
}

/// How a step on the day's ring came home, or toward it.
pub const Way = enum {
    none,
    /// From the lean, home: what leaned springs home.
    full_close,
    /// From the lift, home: what rose settles.
    amen,
    /// From the lean to the cave under home: things land on their other side.
    turn,
    /// A fifth falling anywhere else on the ring: one step of the long way home.
    long_way,
};

pub fn way(from: i8, to: i8) Way {
    if (from == to) return .none;
    if (to == Ring.home and from == Ring.lean) return .full_close;
    if (to == Ring.home and from == Ring.lift) return .amen;
    if (from == Ring.lean and to == Ring.remembers) return .turn;
    if (Ring.step(from, -1) == to) return .long_way;
    return .none;
}

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;
const Chord = chord_mod.Chord;

test "home to the cave under it: one note moves, G up to A" {
    const home = (Chord{}).triad();
    const cave = (Chord{ .root = Note.r(5, 6), .kind = .minor }).triad();
    const c = between(home, cave);
    try expectEqual(@as(u8, 2), c.stayed());
    try expectEqual(Fate.stayed, c.of(0).?.fate);
    try expectEqual(Fate.stayed, c.of(4).?.fate);
    const g = c.of(1).?;
    try expectEqual(Fate.rose, g.fate);
    try expectEqual(@as(i8, 2), g.half_steps);
    try expectEqual(Note.r(10, 9), g.by());
    try expectEqual(@as(wheel.Colours, 0), c.arrived);
}

test "the lift to the lean: nothing stays, and everything moves the same way" {
    const lift = (Chord{ .root = Note.r(2, 3) }).triad();
    const lean = (Chord{ .root = Note.r(3, 4) }).triad();
    const c = between(lift, lean);
    try expectEqual(@as(u8, 0), c.stayed());
    for (c.slice()) |m| {
        try expectEqual(Fate.rose, m.fate);
        try expectEqual(@as(i8, 2), m.half_steps);
    }
}

test "home to the lift: one stays, and each of the others goes to a note of its own" {
    const home = (Chord{}).triad();
    const lift = (Chord{ .root = Note.r(2, 3) }).triad();
    const c = between(home, lift);
    try expectEqual(@as(u8, 1), c.stayed());
    try expectEqual(@as(i8, 1), c.of(4).?.half_steps);
    try expectEqual(@as(i8, 2), c.of(1).?.half_steps);
    try expectEqual(@as(wheel.Colours, 0), c.arrived);
}

test "open fifths gaining a third: the third arrives" {
    const bare = (Chord{}).plain(chord_mod.Voice.open_fifths);
    const warm = (Chord{}).plain(chord_mod.Voice.warm);
    const c = between(bare, warm);
    try expectEqual(@as(u8, 2), c.stayed());
    try expectEqual(wheel.colour(4), c.arrived);
}

test "four ways home" {
    try expectEqual(Way.full_close, way(Ring.lean, Ring.home));
    try expectEqual(Way.amen, way(Ring.lift, Ring.home));
    try expectEqual(Way.turn, way(Ring.lean, Ring.remembers));
    // the long way: every other fifth falling, the seam's crossing among them
    try expectEqual(Way.long_way, way(Ring.aches, Ring.remembers));
    try expectEqual(Way.long_way, way(Ring.remembers, Ring.runs));
    try expectEqual(Way.long_way, way(Ring.runs, Ring.lean));
    try expectEqual(Way.long_way, way(Ring.lift, Ring.seam));
    try expectEqual(Way.long_way, way(Ring.seam, Ring.aches));
    try expectEqual(Way.none, way(Ring.home, Ring.lean));
    try expectEqual(Way.none, way(Ring.home, Ring.home));
}
