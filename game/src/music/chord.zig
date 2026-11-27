//! A chord: a root, a kind, and how far Hum's voice and breath have opened it
//! (design/the-game.md, "What grows"; design/the-depths.md, "The third").
//!
//! A chord is tuned pure to its own root. Its notes come in the order a voice opens them: the root,
//! the fifth, the third, the low seventh, the ninth.
//!
//! No world in it and no platform.
const std = @import("std");
const Note = @import("note.zig").Note;
const wheel = @import("wheel.zig");

/// Major on the outer ring, minor on the inner, and the seam's: the chord on a key's seventh note,
/// which cannot stand by itself.
pub const Kind = enum { major, minor, seam };

/// What a note is in a chord, in the order Hum's voice opens them.
pub const Role = enum(u3) { root, fifth, third, seventh, ninth };

pub const most = 5;

/// How far Hum's voice has opened: which overtones it has found. The fifth comes with Drip, the
/// third singing with someone, the seventh later. The octave is the voices, and adds no note.
pub const Voice = struct {
    fifth: bool = true,
    third: bool = false,
    seventh: bool = false,

    pub const closed = Voice{ .fifth = false };
    pub const open_fifths = Voice{};
    pub const warm = Voice{ .third = true };
    pub const whole = Voice{ .third = true, .seventh = true };

    /// Whether this voice can sound a role at all.
    pub fn has(self: Voice, role: Role) bool {
        return switch (role) {
            .root => true,
            .fifth => self.fifth,
            .third => self.third,
            .seventh, .ninth => self.seventh,
        };
    }
};

/// The notes of a chord that are sounding, each with what it is.
pub const Members = struct {
    notes: [most]Note = @splat(Note.c),
    roles: [most]Role = @splat(.root),
    n: u8 = 0,

    pub fn slice(self: *const Members) []const Note {
        return self.notes[0..self.n];
    }

    pub fn colours(self: *const Members) wheel.Colours {
        return wheel.coloursOf(self.slice());
    }

    /// What a colour is in this chord, if it is in it.
    pub fn roleOf(self: *const Members, cell: u4) ?Role {
        for (self.slice(), self.roles[0..self.n]) |note, role| {
            if (note.cell() == cell) return role;
        }
        return null;
    }

    /// This chord's own note of a colour, if it has one.
    pub fn noteOf(self: *const Members, cell: u4) ?Note {
        for (self.slice()) |note| {
            if (note.cell() == cell) return note;
        }
        return null;
    }
};

pub const Chord = struct {
    root: Note = Note.c,
    kind: Kind = .major,

    /// A role's interval above the root. The seam's fifth is the bent one, and it has nothing
    /// above that.
    pub fn interval(self: Chord, role: Role) Note {
        return switch (role) {
            .root => Note.c,
            .fifth => if (self.kind == .seam) Note.r(64, 45) else Note.fifth,
            .third => if (self.kind == .major) Note.major_third else Note.minor_third,
            .seventh => if (self.kind == .major) Note.low_seventh else Note.r(9, 5),
            .ninth => Note.r(9, 4),
        };
    }

    pub fn note(self: Chord, role: Role) Note {
        return self.root.plus(self.interval(role));
    }

    /// The notes that sound: as many as the breath has opened (`floors`, one to five), and only
    /// those the voice has found. The seam's chord stops at three.
    pub fn members(self: Chord, voice: Voice, floors: u8) Members {
        var m = Members{};
        const order = [most]Role{ .root, .fifth, .third, .seventh, .ninth };
        const top: usize = if (self.kind == .seam) 3 else most;
        for (order[0..top]) |role| {
            if (m.n >= floors) break;
            if (!voice.has(role)) continue;
            m.notes[m.n] = self.note(role);
            m.roles[m.n] = role;
            m.n += 1;
        }
        return m;
    }

    /// The chord as it sounds with no breath behind it: a root and a fifth, and a third once the
    /// voice has found one.
    pub fn plain(self: Chord, voice: Voice) Members {
        return self.members(voice, 3);
    }

    /// All three notes, whatever the voice: what theory calls the triad.
    pub fn triad(self: Chord) Members {
        return self.members(Voice.warm, 3);
    }

    /// What `held` is over this chord's root: the interval from the root up to it, inside an
    /// octave. Hum's note on a chord is this (design/the-wormhole.md, "The elevator").
    pub fn hears(self: Chord, held: Note) Note {
        return held.minus(self.root).inOctave();
    }
};

/// What is lowest decides what a chord does (design/the-depths.md, "What is underneath"): on its
/// root it stands, on its third it slides, on its fifth it hangs. Over any other note it rides.
pub const Sits = enum { stands, slides, hangs, rides };

pub fn sits(chord: Chord, lowest: Note) Sits {
    const triad = chord.triad();
    const role = triad.roleOf(lowest.cell()) orelse return .rides;
    return switch (role) {
        .root => .stands,
        .third => .slides,
        .fifth => .hangs,
        else => .rides,
    };
}

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "a chord opens in the order of the overtones" {
    const c = Chord{};
    // open fifths before the third is found
    const bare = c.plain(Voice.open_fifths);
    try expectEqual(@as(u8, 2), bare.n);
    try expectEqual(Note.r(3, 2), bare.notes[1]);
    // warm once it is
    const warm = c.plain(Voice.warm);
    try expectEqual(@as(u8, 3), warm.n);
    try expectEqual(Role.third, warm.roles[2]);
    try expectEqual(Note.r(5, 4), warm.notes[2]);
    // the whole breath: 1, 3/2, 5/4, 7/4, 9/4, as the swell has always added them
    const full = c.members(Voice.whole, 5);
    try expectEqual(@as(u8, 5), full.n);
    try expectEqual(Note.r(7, 4), full.notes[3]);
    try expectEqual(Note.r(9, 4), full.notes[4]);
    // a closed hum is one note
    try expectEqual(@as(u8, 1), c.plain(Voice.closed).n);
    // the breath opens it a floor at a time
    try expectEqual(@as(u8, 2), c.members(Voice.whole, 2).n);
}

test "major, minor and the seam's" {
    const a_minor = Chord{ .root = Note.r(5, 6), .kind = .minor };
    try expectEqual(Note.r(1, 1), a_minor.note(.third));
    try expectEqual(Note.r(5, 4), a_minor.note(.fifth));
    // the seam on B: B, D and the F a bent fifth over it
    const seam = Chord{ .root = Note.r(15, 16), .kind = .seam };
    try expectEqual(Note.r(9, 8), seam.note(.third));
    try expectEqual(Note.r(4, 3), seam.note(.fifth));
    try expectEqual(@as(u8, 3), seam.members(Voice.whole, 5).n);
}

test "what a colour is in a chord" {
    const g = (Chord{ .root = Note.r(3, 4) }).triad();
    try expectEqual(Role.root, g.roleOf(1).?);
    try expectEqual(Role.third, g.roleOf(5).?);
    try expectEqual(Role.fifth, g.roleOf(2).?);
    try expect(g.roleOf(0) == null);
    // its own D is the lean's, 9/8
    try expect(g.noteOf(2).?.sameTuning(Note.r(9, 8)));
}

test "on its root it stands, on its third it slides, on its fifth it hangs" {
    const c = Chord{};
    try expectEqual(Sits.stands, sits(c, Note.c));
    try expectEqual(Sits.slides, sits(c, Note.r(5, 8)));
    try expectEqual(Sits.hangs, sits(c, Note.r(3, 4)));
    try expectEqual(Sits.rides, sits(c, Note.r(2, 3)));
}
