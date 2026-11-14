//! The wheel's arithmetic: notes as places on the ring of fifths, the twelve wedges under the
//! thumb, what two notes are to each other, and how each one sounds. No platform code.
const std = @import("std");

/// A note, counted in fifths above the day's own note (C on the first morning): F is -1, G is
/// 1, D is 2, A is 3. Notes twelve fifths apart share a wedge.
pub const Note = i32;

pub const wedges = 12;

/// The seven lit wedges, by the mood that sits there. The moods never move; the notes behind
/// them turn a notch each morning (this toy stays on the first morning).
pub const Mood = enum { wonder, sunny, drive, cool, tender, fierce, darkest };

pub const mood_names = [_][]const u8{ "WONDER", "SUNNY HOME", "DRIVE", "COOL SOUL", "TENDERNESS", "FIERCENESS", "THE DARKEST" };

/// Fold any number of fifths onto the ring: -5 (five to the left of the day's note) to 6
/// (straight across from it).
pub fn fold(n: Note) Note {
    return @mod(n + 5, 12) - 5;
}

/// The note on wedge `k`, counted clockwise from twelve o'clock. Cool soul is at the top
/// (two fifths above the day's note), wonder at nine o'clock, the darkest at three.
pub fn wedgeNote(k: usize) Note {
    return fold(@as(Note, @intCast(k)) + 2);
}

pub fn noteWedge(n: Note) usize {
    return @intCast(@mod(n - 2, 12));
}

/// Lit wedges hold the seven notes of the day's key: one fifth below the day's note to five
/// above it.
pub fn isLit(n: Note) bool {
    const f = fold(n);
    return f >= -1 and f <= 5;
}

pub fn mood(n: Note) ?Mood {
    if (!isLit(n)) return null;
    return @enumFromInt(@as(u8, @intCast(fold(n) + 1)));
}

pub fn moodNote(m: Mood) Note {
    return @as(Note, @intFromEnum(m)) - 1;
}

/// Wedges from `home` round to `note`, the short way, with its direction: 1 means the note
/// sits one wedge clockwise of home (a fifth above it), -1 one wedge the other way.
pub fn stepsFrom(home: Note, note: Note) i32 {
    return fold(note - home);
}

pub fn apart(a: Note, b: Note) u8 {
    return @intCast(@abs(stepsFrom(a, b)));
}

/// What a note is to you, given where home is.
pub const Relation = enum {
    /// On your wedge: it keeps your time.
    kin,
    /// One wedge clockwise of home, a fifth above: it leans toward you, and a close brings it home.
    leans_in,
    /// One wedge the other way, a fifth below: you lean toward it, and a close sings it to sleep.
    lean_to,
    /// Two wedges round: you pass through each other.
    passing,
    /// Three or four round: warm.
    warm,
    /// Five round, at the far end of a string of the star: a half step.
    half_step,
    /// Straight across.
    far,
};

pub fn relation(home: Note, note: Note) Relation {
    return switch (stepsFrom(home, note)) {
        0 => .kin,
        1 => .leans_in,
        -1 => .lean_to,
        2, -2 => .passing,
        3, -3, 4, -4 => .warm,
        5, -5 => .half_step,
        else => .far,
    };
}

/// The pure interval of `note` above `home`, between 1 and 2.
pub fn ratio(home: Note, note: Note) f64 {
    return switch (stepsFrom(home, note)) {
        0 => 1.0,
        1 => 3.0 / 2.0,
        -1 => 4.0 / 3.0,
        2 => 9.0 / 8.0,
        -2 => 16.0 / 9.0,
        3 => 5.0 / 3.0,
        -3 => 6.0 / 5.0,
        4 => 5.0 / 4.0,
        -4 => 8.0 / 5.0,
        5 => 15.0 / 8.0,
        -5 => 16.0 / 15.0,
        else => 45.0 / 32.0,
    };
}

/// The two whole numbers of that interval (a fifth is 3 against 2). A creature's body is drawn
/// from them, and its pulse against yours is the same pair, slowed down.
pub fn pair(home: Note, note: Note) [2]u8 {
    return switch (stepsFrom(home, note)) {
        0 => .{ 1, 1 },
        1 => .{ 3, 2 },
        -1 => .{ 4, 3 },
        2 => .{ 9, 8 },
        -2 => .{ 16, 9 },
        3 => .{ 5, 3 },
        -3 => .{ 6, 5 },
        4 => .{ 5, 4 },
        -4 => .{ 8, 5 },
        5 => .{ 15, 8 },
        -5 => .{ 16, 15 },
        else => .{ 45, 32 },
    };
}

/// How many of your beats pass between the moments a creature's pulse meets yours: the second
/// number of its interval, held to a power of two so that the meeting sits in the bar. Near on
/// the wheel is simple: kin meets you on every beat, a neighbour on every second one, a third
/// once a bar.
pub fn meetBeats(home: Note, note: Note) u8 {
    return switch (apart(home, note)) {
        0 => 1,
        1 => 2,
        3, 4 => 4,
        2, 5 => 8,
        else => 16,
    };
}

/// Where home itself is pitched inside the day's key: the pure major scale, with the second
/// degree taken low (10/9) so that it is in tune with the fourth and sixth.
pub fn degree(home: Note) f64 {
    return switch (fold(home)) {
        0 => 1.0,
        1 => 3.0 / 2.0,
        -1 => 4.0 / 3.0,
        2 => 10.0 / 9.0,
        -2 => 16.0 / 9.0,
        3 => 5.0 / 3.0,
        -3 => 6.0 / 5.0,
        4 => 5.0 / 4.0,
        -4 => 8.0 / 5.0,
        5 => 15.0 / 8.0,
        -5 => 16.0 / 15.0,
        else => 45.0 / 32.0,
    };
}

/// Move a frequency by octaves into the octave that starts at `floor`.
pub fn into(f: f64, floor: f64) f64 {
    var x = f;
    while (x >= floor * 2.0) x /= 2.0;
    while (x < floor) x *= 2.0;
    return x;
}

/// The frequency of `note` while `home` is home, in the octave above `floor`. Every sound in
/// the toy comes from here, so everything is in tune with home.
pub fn hz(day_hz: f64, home: Note, note: Note, floor: f64) f64 {
    return into(day_hz * degree(home) * ratio(home, note), floor);
}

pub const Quality = enum { major, minor, diminished };

/// The chord that stands on each lit wedge, made only of the day's seven notes.
pub fn quality(home: Note) Quality {
    return switch (fold(home)) {
        -1, 0, 1 => .major,
        5 => .diminished,
        else => .minor,
    };
}

/// The three notes of home's chord, as pure ratios above home's own note.
pub fn chordRatios(q: Quality) [3]f64 {
    return switch (q) {
        .major => .{ 1.0, 5.0 / 4.0, 3.0 / 2.0 },
        .minor => .{ 1.0, 6.0 / 5.0, 3.0 / 2.0 },
        .diminished => .{ 1.0, 6.0 / 5.0, 7.0 / 5.0 },
    };
}

/// The note two others are both overtones of, when there is one close by: the wedge where
/// their threads cross. C and A (a sixth apart, five against three) are the third and fifth
/// overtones of F.
pub fn generator(a: Note, b: Note) ?Note {
    return switch (stepsFrom(a, b)) {
        3 => fold(a - 1), // a is the root's fifth, b its third
        -3 => fold(b - 1),
        1 => fold(a), // a fifth: the lower note is the root
        -1 => fold(b),
        4 => fold(a), // a third: the lower note is the root
        -4 => fold(b),
        0 => fold(a),
        else => null,
    };
}

/// Hue by fifths, as in the look: C green, the sharp side warm, the flat side cool, purple at
/// the seam.
pub fn hue(n: Note) [3]f32 {
    const table = [12][3]f32{
        .{ 0.36, 0.86, 0.42 }, // C: green
        .{ 0.66, 0.88, 0.30 }, // G: yellow-green
        .{ 0.96, 0.84, 0.26 }, // D: yellow
        .{ 0.98, 0.60, 0.22 }, // A: orange
        .{ 0.95, 0.34, 0.26 }, // E: red
        .{ 0.95, 0.42, 0.62 }, // B: rose
        .{ 0.70, 0.40, 0.86 }, // F sharp: purple, the seam
        .{ 0.52, 0.40, 0.92 }, // D flat: violet
        .{ 0.34, 0.46, 0.95 }, // A flat: blue
        .{ 0.30, 0.62, 0.96 }, // E flat: azure
        .{ 0.28, 0.80, 0.92 }, // B flat: cyan
        .{ 0.26, 0.84, 0.72 }, // F: teal
    };
    return table[@intCast(@mod(n, 12))];
}

test "the wedges: cool soul on top, wonder at nine, the darkest at three" {
    try std.testing.expectEqual(@as(Note, 2), wedgeNote(0));
    try std.testing.expectEqual(@as(Note, -1), wedgeNote(9));
    try std.testing.expectEqual(@as(Note, 0), wedgeNote(10));
    try std.testing.expectEqual(@as(Note, 5), wedgeNote(3));
    try std.testing.expectEqual(@as(Note, 6), wedgeNote(4));
    try std.testing.expectEqual(@as(Note, -2), wedgeNote(8));
    for (0..wedges) |k| try std.testing.expectEqual(k, noteWedge(wedgeNote(k)));
    try std.testing.expectEqual(Mood.wonder, mood(-1).?);
    try std.testing.expectEqual(Mood.cool, mood(2).?);
    try std.testing.expect(mood(6) == null);
}

test "seven lit, five dark, and the lit arc's two ends are straight across from each other" {
    var lit: usize = 0;
    for (0..wedges) |k| {
        if (isLit(wedgeNote(k))) lit += 1;
    }
    try std.testing.expectEqual(@as(usize, 7), lit);
    try std.testing.expectEqual(@as(u8, 6), apart(moodNote(.wonder), moodNote(.darkest)));
}

test "what a note is to you" {
    // home on C: G leans in, F is leaned toward, A and E are warm, F sharp is far
    try std.testing.expectEqual(Relation.leans_in, relation(0, 1));
    try std.testing.expectEqual(Relation.lean_to, relation(0, -1));
    try std.testing.expectEqual(Relation.warm, relation(0, 3));
    try std.testing.expectEqual(Relation.warm, relation(0, 4));
    try std.testing.expectEqual(Relation.far, relation(0, 6));
    try std.testing.expectEqual(Relation.kin, relation(3, 3));
    // the star's strings are half steps: B is five round from C
    try std.testing.expectEqual(Relation.half_step, relation(0, 5));
    try std.testing.expectApproxEqAbs(@as(f64, 15.0 / 8.0), ratio(0, 5), 1e-12);
}

test "near on the wheel is simple in time" {
    try std.testing.expectEqual(@as(u8, 1), meetBeats(2, 2));
    try std.testing.expectEqual(@as(u8, 2), meetBeats(2, 3));
    try std.testing.expectEqual(@as(u8, 2), meetBeats(2, 1));
    try std.testing.expectEqual(@as(u8, 4), meetBeats(0, 3));
    try std.testing.expectEqual(@as(u8, 16), meetBeats(0, 6));
}

test "the first knot: C and A meet on F" {
    try std.testing.expectEqual(@as(Note, -1), generator(0, 3).?);
    try std.testing.expectEqual(@as(Note, -1), generator(3, 0).?);
    // with home on F, C is its fifth (three against two) and A its third (five against four)
    try std.testing.expectEqual([2]u8{ 3, 2 }, pair(-1, 0));
    try std.testing.expectEqual([2]u8{ 5, 4 }, pair(-1, 3));
    // with home on C, A is five against three
    try std.testing.expectEqual([2]u8{ 5, 3 }, pair(0, 3));
}

test "everything is in tune with home" {
    const c = 261.6256;
    // home on C: A sounds a pure sixth above it
    try std.testing.expectApproxEqRel(c * 5.0 / 3.0, hz(c, 0, 3, c), 1e-9);
    // home on D: A is its fifth, and it is the same A
    try std.testing.expectApproxEqRel(c * 5.0 / 3.0, hz(c, 2, 3, c), 1e-9);
    // home on F: C is its fifth, and it is the day's own note
    try std.testing.expectApproxEqRel(c, hz(c, -1, 0, c), 1e-9);
    try std.testing.expectEqual(Quality.minor, quality(2));
    try std.testing.expectEqual(Quality.major, quality(-1));
    try std.testing.expectEqual(Quality.diminished, quality(5));
}
