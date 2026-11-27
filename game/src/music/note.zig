//! A note: where it stands from the Garden's C, as four small whole numbers (docs/engine.md, "The
//! note").
//!
//! Its ratio is 3 to the fifths, times 5 to the thirds, times 7 to the sevenths, times 2 to the
//! octaves. An interval is the same four numbers: the note it would be over C. Nothing here is
//! hertz until the speaker asks, so tuning is exact and the same on every machine.
//!
//! No world in it and no platform.
const std = @import("std");

/// The cents in an octave, and in one of the treaty's twelve equal steps.
pub const octave_cents: f64 = 1200.0;
pub const step_cents: f64 = 100.0;

pub const Note = struct {
    fifths: i8 = 0,
    thirds: i8 = 0,
    sevenths: i8 = 0,
    octaves: i8 = 0,

    /// The Garden's C; as an interval, the unison.
    pub const c = Note{};
    /// The intervals everything else is made of, each within one octave.
    pub const octave = Note{ .octaves = 1 };
    pub const fifth = r(3, 2);
    pub const fourth = r(4, 3);
    pub const major_third = r(5, 4);
    pub const minor_third = r(6, 5);
    pub const low_seventh = r(7, 4);

    /// A ratio of two whole numbers as a note. Null unless its only factors are 2, 3, 5 and 7.
    pub fn fromRatio(num: u32, den: u32) ?Note {
        if (num == 0 or den == 0) return null;
        var n = Note{};
        var top = num;
        var bottom = den;
        const primes = [4]u32{ 2, 3, 5, 7 };
        var count: [4]i32 = @splat(0);
        for (primes, 0..) |p, i| {
            while (top % p == 0) : (top /= p) count[i] += 1;
            while (bottom % p == 0) : (bottom /= p) count[i] -= 1;
        }
        if (top != 1 or bottom != 1) return null;
        for (count) |k| if (k < std.math.minInt(i8) or k > std.math.maxInt(i8)) return null;
        n.octaves = @intCast(count[0]);
        n.fifths = @intCast(count[1]);
        n.thirds = @intCast(count[2]);
        n.sevenths = @intCast(count[3]);
        return n;
    }

    /// A ratio known when the game is built. It will not build if the ratio is off the lattice.
    pub fn r(comptime num: u32, comptime den: u32) Note {
        return comptime fromRatio(num, den) orelse @compileError("not a ratio of 2, 3, 5 and 7");
    }

    /// The ratio as two whole numbers, in lowest terms.
    pub fn frac(self: Note) struct { num: u64, den: u64 } {
        var num: u64 = 1;
        var den: u64 = 1;
        const primes = [4]u64{ 2, 3, 5, 7 };
        const powers = [4]i8{ self.octaves, self.fifths, self.thirds, self.sevenths };
        for (primes, powers) |p, k| {
            var i: i8 = 0;
            while (i < k) : (i += 1) num *= p;
            while (i > k) : (i -= 1) den *= p;
        }
        return .{ .num = num, .den = den };
    }

    /// The ratio as one number. Both whole numbers are exact, so this is the nearest there is.
    pub fn value(self: Note) f64 {
        const f = self.frac();
        return @as(f64, @floatFromInt(f.num)) / @as(f64, @floatFromInt(f.den));
    }

    /// How far above the Garden's C, in cents.
    pub fn cents(self: Note) f64 {
        return octave_cents * @log2(self.value());
    }

    /// What the speaker is asked for, given the Garden's C in hertz.
    pub fn hz(self: Note, c_hz: f32) f32 {
        return @floatCast(@as(f64, c_hz) * self.value());
    }

    /// This note moved up by an interval.
    pub fn plus(self: Note, interval: Note) Note {
        return .{
            .fifths = self.fifths + interval.fifths,
            .thirds = self.thirds + interval.thirds,
            .sevenths = self.sevenths + interval.sevenths,
            .octaves = self.octaves + interval.octaves,
        };
    }

    /// The interval from `other` up to this note.
    pub fn minus(self: Note, other: Note) Note {
        return .{
            .fifths = self.fifths - other.fifths,
            .thirds = self.thirds - other.thirds,
            .sevenths = self.sevenths - other.sevenths,
            .octaves = self.octaves - other.octaves,
        };
    }

    /// The same interval turned upside down: what is left of an octave.
    pub fn under(self: Note) Note {
        return octave.minus(self).inOctave();
    }

    /// Its colour: which of the wheel's twelve cells it is, counted clockwise from C. A fifth is
    /// one cell, a sweet third four, a low seventh ten.
    pub fn cell(self: Note) u4 {
        const k: i32 = @as(i32, self.fifths) + 4 * @as(i32, self.thirds) + 10 * @as(i32, self.sevenths);
        return @intCast(@mod(k, 12));
    }

    /// Which of the treaty's twelve equal steps it is, counted up from C.
    pub fn semitone(self: Note) u4 {
        const k: i32 = 7 * @as(i32, self.fifths) + 4 * @as(i32, self.thirds) + 10 * @as(i32, self.sevenths);
        return @intCast(@mod(k, 12));
    }

    /// The same colour and tuning, moved by octaves until its ratio is at least 1 and under 2.
    pub fn inOctave(self: Note) Note {
        var n = self;
        n.octaves = 0;
        const f = n.frac();
        var num = f.num;
        var den = f.den;
        while (num >= 2 * den) : (den *= 2) n.octaves -= 1;
        while (num < den) : (num *= 2) n.octaves += 1;
        return n;
    }

    /// The same colour and tuning, in the octave that puts it nearest `centre`.
    pub fn near(self: Note, centre: Note) Note {
        const apart = (centre.cents() - self.cents()) / octave_cents;
        var n = self;
        n.octaves += @as(i8, @intFromFloat(@round(apart)));
        return n;
    }

    /// The treaty's version of this note, in cents above C: its own step of the twelve, in the
    /// octave nearest where the note truly is.
    pub fn treatyCents(self: Note) f64 {
        const base = step_cents * @as(f64, @floatFromInt(self.semitone()));
        const octaves_up = @round((self.cents() - base) / octave_cents);
        return base + octave_cents * octaves_up;
    }

    /// How far the note truly is above the treaty's version of it, in cents.
    pub fn offTreaty(self: Note) f64 {
        return self.cents() - self.treatyCents();
    }

    pub fn eql(a: Note, b: Note) bool {
        return a.fifths == b.fifths and a.thirds == b.thirds and a.sevenths == b.sevenths and a.octaves == b.octaves;
    }

    /// The same place on the wheel, whatever the octave and whatever the tuning.
    pub fn sameColour(a: Note, b: Note) bool {
        return a.cell() == b.cell();
    }

    /// The same tuning, whatever the octave.
    pub fn sameTuning(a: Note, b: Note) bool {
        return a.fifths == b.fifths and a.thirds == b.thirds and a.sevenths == b.sevenths;
    }
};

/// The cents between two notes, with whole octaves taken out: nought to six hundred.
pub fn centsApart(a: Note, b: Note) f64 {
    const d = @abs(a.cents() - b.cents());
    const within = d - octave_cents * @floor(d / octave_cents);
    return @min(within, octave_cents - within);
}

const expectEqual = std.testing.expectEqual;
const expectApprox = std.testing.expectApproxEqAbs;
const expect = std.testing.expect;

test "a ratio is a note, and back" {
    const g = Note.r(3, 2);
    try expectEqual(Note{ .fifths = 1, .octaves = -1 }, g);
    try expectEqual(@as(u64, 3), g.frac().num);
    try expectEqual(@as(u64, 2), g.frac().den);
    // the rows of docs/engine.md, "The note"
    try expectEqual(Note{ .fifths = -1, .octaves = 2 }, Note.r(4, 3));
    try expectEqual(Note{ .thirds = 1, .octaves = -2 }, Note.r(5, 4));
    try expectEqual(Note{ .fifths = 4, .octaves = -6 }, Note.r(81, 64));
    try expectEqual(Note{ .fifths = -1, .thirds = 1 }, Note.r(5, 3));
    try expectEqual(Note{ .fifths = 2, .octaves = -3 }, Note.r(9, 8));
    try expectEqual(Note{ .fifths = -2, .thirds = 1, .octaves = 1 }, Note.r(10, 9));
    try expectEqual(Note{ .sevenths = 1, .octaves = -2 }, Note.r(7, 4));
    // eleven and thirteen are not on it
    try expect(Note.fromRatio(11, 8) == null);
    try expect(Note.fromRatio(13, 8) == null);
    try expect(Note.fromRatio(0, 1) == null);
}

test "a note's colour is its place on the wheel" {
    try expectEqual(@as(u4, 0), Note.c.cell());
    try expectEqual(@as(u4, 1), Note.r(3, 2).cell());
    try expectEqual(@as(u4, 11), Note.r(4, 3).cell());
    try expectEqual(@as(u4, 4), Note.r(5, 4).cell());
    try expectEqual(@as(u4, 3), Note.r(5, 3).cell());
    // the low seventh is the colour of B flat
    try expectEqual(@as(u4, 10), Note.r(7, 4).cell());
    // an octave is the same colour
    try expect(Note.r(3, 2).sameColour(Note.r(3, 1)));
    // a cell is seven of the treaty's steps
    for ([_]Note{ Note.r(3, 2), Note.r(5, 4), Note.r(7, 4), Note.r(16, 15), Note.r(45, 32) }) |n| {
        try expectEqual(@as(u4, @intCast((@as(u32, n.cell()) * 7) % 12)), n.semitone());
    }
}

test "the two Ds are one colour and a comma apart" {
    const leans = Note.r(9, 8);
    const cave = Note.r(10, 9);
    try expect(leans.sameColour(cave));
    try expect(!leans.sameTuning(cave));
    try expectApprox(@as(f64, 21.506), leans.cents() - cave.cents(), 0.001);
    try expectEqual(Note.r(81, 80), leans.minus(cave));
}

test "intervals add, turn over and fold" {
    try expectEqual(Note.r(15, 8), Note.r(3, 2).plus(Note.r(5, 4)));
    try expectEqual(Note.r(6, 5), Note.r(3, 2).minus(Note.r(5, 4)));
    try expectEqual(Note.r(4, 3), Note.fifth.under());
    try expectEqual(Note.r(8, 5), Note.major_third.under());
    try expectEqual(Note.r(3, 2), Note.r(3, 1).inOctave());
    try expectEqual(Note.r(3, 2), Note.r(3, 8).inOctave());
    // G nearest C is the one below it
    try expectEqual(Note.r(3, 4), Note.r(3, 2).near(Note.c));
    try expectEqual(Note.r(4, 3), Note.r(2, 3).near(Note.c));
}

test "hertz are worked out only at the end" {
    try expectApprox(@as(f32, 392.445), Note.r(3, 2).hz(261.63), 0.001);
    try expectApprox(@as(f32, 261.63), Note.c.hz(261.63), 0.0001);
}

test "the treaty's notes" {
    // its fifth is 700: 1.955 narrow of pure
    try expectApprox(@as(f64, 700.0), Note.fifth.treatyCents(), 1e-9);
    try expectApprox(@as(f64, 1.955), Note.fifth.offTreaty(), 0.001);
    // its third is 400: 13.686 wide of the sweet one
    try expectApprox(@as(f64, -13.686), Note.major_third.offTreaty(), 0.001);
    // and it keeps the octave the note is in
    try expectApprox(@as(f64, 1900.0), Note.r(3, 1).treatyCents(), 1e-9);
    try expectApprox(@as(f64, -500.0), Note.r(3, 4).treatyCents(), 1e-9);
}

test "cents apart, with octaves taken out" {
    try expectApprox(@as(f64, 498.045), centsApart(Note.c, Note.r(3, 2)), 0.001);
    try expectApprox(@as(f64, 21.506), centsApart(Note.r(9, 8), Note.r(20, 9)), 0.001);
}
