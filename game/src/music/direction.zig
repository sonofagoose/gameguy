//! The arithmetic of the three design documents, as tests. Each test is named for the document and
//! the line of its "The arithmetic" it checks, so a change to either the design or the code that
//! breaks the other is caught when the game is built.
const std = @import("std");
const note_mod = @import("note.zig");
const Note = note_mod.Note;
const wheel = @import("wheel.zig");
const chord_mod = @import("chord.zig");
const Chord = chord_mod.Chord;
const Voice = chord_mod.Voice;
const key = @import("key.zig");
const Day = key.Day;
const Ring = key.Ring;
const change = @import("change.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const approx = std.testing.expectApproxEqAbs;

/// The letters' cells, for reading the tests against the documents.
const C: u4 = 0;
const G: u4 = 1;
const D: u4 = 2;
const A: u4 = 3;
const E: u4 = 4;
const B: u4 = 5;
const Fs: u4 = 6;
const Db: u4 = 7;
const Ab: u4 = 8;
const Eb: u4 = 9;
const Bb: u4 = 10;
const F: u4 = 11;

fn set(cells: []const u4) wheel.Colours {
    var s: wheel.Colours = 0;
    for (cells) |c| s |= wheel.colour(c);
    return s;
}

/// The seven steps of a day's key counted in half steps up from one of its notes: a mode.
fn mode(day: Day, from: u4) [7]u4 {
    var steps: [7]u4 = undefined;
    var n: usize = 0;
    var half: u4 = 0;
    while (half < 12) : (half += 1) {
        const cell = wheel.cellOf(@intCast((@as(u32, wheel.semitoneOf(from)) + half) % 12));
        if (day.colours() & wheel.colour(cell) != 0) {
            steps[n] = half;
            n += 1;
        }
    }
    std.debug.assert(n == 7);
    return steps;
}

const lydian = [7]u4{ 0, 2, 4, 6, 7, 9, 11 };
const ionian = [7]u4{ 0, 2, 4, 5, 7, 9, 11 };
const mixolydian = [7]u4{ 0, 2, 4, 5, 7, 9, 10 };
const dorian = [7]u4{ 0, 2, 3, 5, 7, 9, 10 };
const aeolian = [7]u4{ 0, 2, 3, 5, 7, 8, 10 };
const phrygian = [7]u4{ 0, 1, 3, 5, 7, 8, 10 };
const locrian = [7]u4{ 0, 1, 3, 5, 6, 8, 10 };

const c_day = Day{};
const outer = wheel.Ring.outer;
const inner = wheel.Ring.inner;

fn land(at: u4) wheel.Cell {
    return .{ .ring = outer, .at = at };
}

fn cave(under: u4) wheel.Cell {
    return .{ .ring = inner, .at = under };
}

// ---------------------------------------------------------------- design/the-game.md

test "the-game: the six places of a key, and their modes" {
    const kinds = [7]chord_mod.Kind{ .major, .major, .major, .minor, .minor, .minor, .seam };
    const roots = [7]u4{ F, C, G, D, A, E, B };
    const modes = [7][7]u4{ lydian, ionian, mixolydian, dorian, aeolian, phrygian, locrian };
    var pos: i8 = Ring.least;
    while (pos <= Ring.most) : (pos += 1) {
        const i: usize = @intCast(pos - Ring.least);
        const ch = c_day.ringChord(pos);
        try expectEqual(kinds[i], ch.kind);
        try expectEqual(roots[i], ch.root.cell());
        try expectEqual(modes[i], mode(c_day, roots[i]));
    }
}

test "the-game: Hum's note over each chord of the day" {
    const want = [7]Note{ Note.r(3, 2), Note.r(1, 1), Note.r(4, 3), Note.r(9, 5), Note.r(6, 5), Note.r(8, 5), Note.r(16, 15) };
    var pos: i8 = Ring.least;
    while (pos <= Ring.most) : (pos += 1) {
        const i: usize = @intCast(pos - Ring.least);
        try expectEqual(want[i], c_day.ringChord(pos).hears(c_day.note()));
    }
}

test "the-game: three days each" {
    try expectEqual(lydian, mode(Day{ .home = 1 }, C));
    try expectEqual(ionian, mode(Day{ .home = 0 }, C));
    try expectEqual(mixolydian, mode(Day{ .home = -1 }, C));
    try expectEqual(dorian, mode(Day{ .home = 1 }, A));
    try expectEqual(aeolian, mode(Day{ .home = 0 }, A));
    try expectEqual(phrygian, mode(Day{ .home = -1 }, A));
}

test "the-game: shared notes between keys" {
    const want = [6]u8{ 6, 5, 4, 3, 2, 2 };
    for (want, 1..) |shared, apart| {
        const other = Day{ .home = @intCast(apart) };
        try expectEqual(shared, wheel.count(c_day.colours() & other.colours()));
    }
}

test "the-game: the three ways down from C" {
    const home = c_day.chordOn(land(C)).triad();
    const ways = [3]struct { wheel.Cell, Note, f64 }{
        .{ cave(C), Note.r(10, 9), 182.404 },
        .{ cave(G), Note.r(16, 15), 111.731 },
        .{ cave(Eb), Note.r(25, 24), 70.672 },
    };
    for (ways) |w| {
        const ch = change.between(home, c_day.chordOn(w[0]).triad());
        try expectEqual(@as(u8, 2), ch.stayed());
        var moved: u8 = 0;
        for (ch.slice()) |m| {
            if (m.fate == .stayed) continue;
            moved += 1;
            try expectEqual(w[1], m.by());
            try approx(w[2], m.by().cents(), 0.001);
        }
        try expectEqual(@as(u8, 1), moved);
    }
    // and the cave with the land's own name is C minor, under E flat, a quarter of the way round
    try expectEqual(C, cave(Eb).root());
    try expectEqual(@as(u4, 3), wheel.apart(C, Eb));
}

test "the-game: chords from outside the key, under C" {
    const flatward = [4]struct { u4, Note, key.Floor }{
        .{ Bb, Note.r(9, 8), .nine },
        .{ Eb, Note.r(5, 3), .thirteen },
        .{ Ab, Note.r(5, 4), .three },
        .{ Db, Note.r(15, 8), .seven },
    };
    const sharpward = [4]struct { u4, Note, key.Floor }{
        .{ D, Note.r(16, 9), .low_seven },
        .{ A, Note.r(6, 5), .low_three },
        .{ E, Note.r(8, 5), .low_thirteen },
        .{ B, Note.r(16, 15), .low_nine },
    };
    for (flatward ++ sharpward) |w| {
        const ch = c_day.chordOn(land(w[0]));
        try expectEqual(chord_mod.Kind.major, ch.kind);
        try expectEqual(w[1], ch.hears(c_day.note()));
        try expectEqual(w[2], c_day.floorOn(land(w[0])));
    }
}

test "the-game: the restless pair" {
    const g7 = c_day.chordOn(land(G)).members(Voice.whole, 4);
    const db7 = c_day.chordOn(land(Db)).members(Voice.whole, 4);
    try expectEqual(set(&.{ G, B, D, F }), g7.colours());
    try expectEqual(set(&.{ Db, F, Ab, B }), db7.colours());
    try expectEqual(set(&.{ B, F }), g7.colours() & db7.colours());
}

test "the-game: the gaps" {
    // twelve fifths against seven octaves
    try approx(@as(f64, 23.460), (Note{ .fifths = 12, .octaves = -19 }).cents(), 0.001);
    // four fifths against a pure third, which is also the two Ds
    try approx(@as(f64, 21.506), Note.r(81, 64).minus(Note.r(5, 4)).cents(), 0.001);
    try approx(@as(f64, 21.506), Note.r(9, 8).minus(Note.r(10, 9)).cents(), 0.001);
    // three pure major thirds against an octave
    try approx(@as(f64, 41.059), note_mod.octave_cents - (Note{ .thirds = 3 }).inOctave().cents(), 0.001);
    // the fifth from the lean's D up to A
    const narrow = Note.r(5, 3).minus(Note.r(9, 8));
    try expectEqual(Note.r(40, 27), narrow);
    try approx(@as(f64, 680.449), narrow.cents(), 0.001);
    try approx(@as(f64, 701.955), Note.fifth.cents(), 0.001);
    // the wolf of the tuning whose thirds are sweet: eleven fifths each a quarter of a comma
    // narrow, and what is left of seven octaves for the twelfth
    const sweet_fifth = note_mod.octave_cents * @log2(std.math.pow(f64, 5.0, 0.25));
    const wolf = 7.0 * note_mod.octave_cents - 11.0 * sweet_fifth;
    try approx(@as(f64, 737.637), wolf, 0.001);
    try approx(@as(f64, 35.682), wolf - Note.fifth.cents(), 0.001);
    try approx(@as(f64, 5.377), Note.fifth.cents() - sweet_fifth, 0.001);
}

test "the-game: the first knot" {
    // C and the A over it are the third and fifth overtones of the F a twelfth below C
    const f = Note.r(1, 3);
    try expectEqual(Note.r(1, 1), f.plus(Note.r(3, 1)));
    try expectEqual(Note.r(5, 3), f.plus(Note.r(5, 1)));
    try expectEqual(F, f.cell());
}

// ---------------------------------------------------------------- design/the-depths.md

test "the-depths: the two thirds" {
    try approx(@as(f64, 386.314), Note.r(5, 4).cents(), 0.001);
    try approx(@as(f64, 407.820), Note.r(81, 64).cents(), 0.001);
    try approx(@as(f64, 21.506), Note.r(81, 80).cents(), 0.001);
    try approx(@as(f64, 13.686), -Note.r(5, 4).offTreaty(), 0.001);
}

test "the-depths: Hum's overtones" {
    const c_hz: f32 = 261.63;
    try approx(@as(f32, 784.9), Note.r(3, 1).hz(c_hz), 0.05);
    try approx(@as(f32, 1308.1), Note.r(5, 1).hz(c_hz), 0.06);
    try approx(@as(f32, 1831.4), Note.r(7, 1).hz(c_hz), 0.05);
    try approx(@as(f32, 2354.6), Note.r(9, 1).hz(c_hz), 0.1);
    // 4 to 5 to 6 to 7 is a root, its major third, its fifth and its low seventh
    const full = (Chord{}).members(Voice.whole, 4);
    try expectEqual(Note.r(5, 4), full.noteOf(E).?);
    try expectEqual(Note.r(6, 4), full.noteOf(G).?);
    try expectEqual(Note.r(7, 4), full.noteOf(Bb).?);
}

test "the-depths: the cave with two mouths" {
    const home = c_day.ringChord(Ring.home).triad();
    const lean = c_day.ringChord(Ring.lean).triad();
    const aches = c_day.ringChord(Ring.aches).triad();
    try expectEqual(set(&.{ E, G, B }), aches.colours());
    try expectEqual(set(&.{ E, G }), aches.colours() & home.colours());
    try expectEqual(set(&.{ G, B }), aches.colours() & lean.colours());
    // from home, C moves down to B; from the lean, D moves up to E
    const from_home = change.between(home, aches);
    try expectEqual(change.Fate.fell, from_home.of(C).?.fate);
    try expectEqual(B, from_home.of(C).?.to.cell());
    const from_lean = change.between(lean, aches);
    try expectEqual(change.Fate.rose, from_lean.of(D).?.fate);
    try expectEqual(E, from_lean.of(D).?.to.cell());
    // with Hum's note it is home's own seventh chord, standing on its third
    try expectEqual(set(&.{ C, E, G, B }), aches.colours() | wheel.colour(c_day.note().cell()));
    try expectEqual(chord_mod.Sits.slides, chord_mod.sits(c_day.ringChord(Ring.home), c_day.ringChord(Ring.aches).root));
    // its twin: the cave that remembers shares two with home and two with the lift
    const lift = c_day.ringChord(Ring.lift).triad();
    const remembers = c_day.ringChord(Ring.remembers).triad();
    try expectEqual(@as(u8, 2), wheel.count(remembers.colours() & home.colours()));
    try expectEqual(@as(u8, 2), wheel.count(remembers.colours() & lift.colours()));
}

test "the-depths: the axes" {
    const hold = [4]u4{ C, A, Fs, Eb };
    const lean = [4]u4{ G, E, Db, Bb };
    const lift = [4]u4{ F, D, B, Ab };
    for (hold) |c| try expectEqual(wheel.Axis.hold, wheel.axis(C, c));
    for (lean) |c| try expectEqual(wheel.Axis.lean, wheel.axis(C, c));
    for (lift) |c| try expectEqual(wheel.Axis.lift, wheel.axis(C, c));
    // a cave does the job of the land over it
    try expectEqual(wheel.Axis.lift, c_day.axis(cave(F)));
    try expectEqual(wheel.Axis.hold, c_day.axis(cave(C)));
    try expectEqual(wheel.Axis.lean, c_day.axis(cave(G)));
    // A is three cells clockwise, a quarter turn, and keys three cells apart share four notes
    try expectEqual(@as(u4, 3), wheel.clockwise(C, A));
    try expectEqual(@as(u8, 4), wheel.count(c_day.colours() & (Day{ .home = 3 }).colours()));
}

test "the-depths: the eight places under the four winds" {
    const ring = [9]wheel.Cell{ land(C), cave(C), land(A), cave(A), land(Fs), cave(Fs), land(Eb), cave(Eb), land(C) };
    const names = [9][]const u8{ "C", "Am", "A", "F#m", "F#", "D#m", "Eb", "Cm", "C" };
    for (ring, names) |cell, name| try std.testing.expectEqualStrings(name, cell.name());
    // each step moves one note
    for (ring[0..8], ring[1..9]) |a, b| {
        const one = c_day.chordOn(a).triad().colours();
        const two = c_day.chordOn(b).triad().colours();
        try expectEqual(@as(u8, 2), wheel.count(one & two));
    }
}

test "the-depths: the day's ring" {
    // in fifths: F, C, G, D, A, E, B, with six true fifths and one bent
    const roots = [7]u4{ F, C, G, D, A, E, B };
    var bent: u8 = 0;
    for (0..7) |i| {
        const here = wheel.semitoneOf(roots[i]);
        const next = wheel.semitoneOf(roots[(i + 1) % 7]);
        const up = (@as(u32, next) + 12 - here) % 12;
        if (up == 7) continue;
        try expectEqual(@as(u32, 6), up);
        bent += 1;
    }
    try expectEqual(@as(u8, 1), bent);
    // falling fifths from F: F, B, E, A, D, G, C, which is IV, vii, iii, vi, ii, V, I
    const want = [7]u3{ 3, 6, 2, 5, 1, 4, 0 };
    var pos: i8 = Ring.lift;
    for (want) |degree| {
        try expectEqual(degree, c_day.degreeOf(c_day.ringChord(pos).root.cell()).?);
        pos = Ring.step(pos, -1);
    }
    try expectEqual(Ring.lift, pos);
}

test "the-depths: home's chord over each ground" {
    const home = c_day.ringChord(Ring.home);
    // over the leaning land's G it hangs; over the aching cave's E it slides
    try expectEqual(chord_mod.Sits.hangs, chord_mod.sits(home, c_day.ringChord(Ring.lean).root));
    try expectEqual(chord_mod.Sits.slides, chord_mod.sits(home, c_day.ringChord(Ring.aches).root));
    try expectEqual(chord_mod.Sits.stands, chord_mod.sits(home, c_day.note()));
    // over the remembering cave's A it is A minor with a seventh
    const a_minor_seven = c_day.ringChord(Ring.remembers).members(Voice.whole, 4);
    try expectEqual(home.triad().colours() | wheel.colour(A), a_minor_seven.colours());
}

test "the-depths: shared notes inside a key" {
    var pos: i8 = Ring.least;
    while (pos < Ring.seam) : (pos += 1) {
        var other: i8 = Ring.least;
        while (other < Ring.seam) : (other += 1) {
            if (other == pos) continue;
            const a = c_day.ringChord(pos);
            const b = c_day.ringChord(other);
            const shared = wheel.count(a.triad().colours() & b.triad().colours());
            const d_a: i32 = c_day.degreeOf(a.root.cell()).?;
            const d_b: i32 = c_day.degreeOf(b.root.cell()).?;
            const steps: u32 = @intCast(@mod(d_b - d_a, 7));
            const want: u8 = switch (steps) {
                2, 5 => 2, // a third apart
                3, 4 => 1, // a fifth apart
                else => 0, // a step apart
            };
            try expectEqual(want, shared);
        }
    }
}

test "the-depths: the ring of thirds" {
    const ring = [8]i8{ Ring.home, Ring.remembers, Ring.lift, Ring.runs, Ring.seam, Ring.lean, Ring.aches, Ring.home };
    for (ring[0..7], ring[1..8]) |a, b| {
        const one = c_day.ringChord(a).triad().colours();
        const two = c_day.ringChord(b).triad().colours();
        try expectEqual(@as(u8, 2), wheel.count(one & two));
    }
}

test "the-depths: the restless pair resolves two ways" {
    const g7 = c_day.chordOn(land(G)).members(Voice.whole, 4);
    // home: B rises to C and F falls to E
    const home = change.between(g7, c_day.chordOn(land(C)).triad());
    try expectEqual(change.Fate.rose, home.of(B).?.fate);
    try expectEqual(C, home.of(B).?.to.cell());
    try expectEqual(change.Fate.fell, home.of(F).?.fate);
    try expectEqual(E, home.of(F).?.to.cell());
    // across the lake: B falls to B flat and F rises to G flat
    const across = change.between(g7, c_day.chordOn(land(Fs)).triad());
    try expectEqual(change.Fate.fell, across.of(B).?.fate);
    try expectEqual(Bb, across.of(B).?.to.cell());
    try expectEqual(change.Fate.rose, across.of(F).?.fate);
    try expectEqual(Fs, across.of(F).?.to.cell());
}

test "the-depths: loops that miss" {
    try approx(@as(f64, 23.460), (Note{ .fifths = 12 }).inOctave().cents(), 0.001);
    // four pure minor thirds overshoot an octave, so four descents arrive that much low
    const four = Note.minor_third.plus(Note.minor_third).plus(Note.minor_third).plus(Note.minor_third);
    try approx(@as(f64, 62.565), four.cents() - note_mod.octave_cents, 0.001);
    const three = Note.major_third.plus(Note.major_third).plus(Note.major_third);
    try approx(@as(f64, 41.059), note_mod.octave_cents - three.cents(), 0.001);
}

// ---------------------------------------------------------------- design/the-wormhole.md

test "the-wormhole: his six places and the wheel" {
    const cells = [6]u4{ 5, 2, 3, 4, 1, 6 };
    for (cells, 1..) |want, half_steps| {
        try expectEqual(want, wheel.apart(C, wheel.cellOf(@intCast(half_steps))));
    }
}

/// A minor eleventh chord's six colours: from three cells flatward of its root to two sharpward.
fn minorEleven(root: u4) wheel.Colours {
    var s: wheel.Colours = 0;
    var by: i32 = -3;
    while (by <= 2) : (by += 1) s |= wheel.colour(wheel.turned(root, by));
    return s;
}

test "the-wormhole: minor eleventh chords" {
    try expectEqual(set(&.{ C, Eb, G, Bb, D, F }), minorEleven(C));
    // two of them n cells apart share six less n
    var n: u4 = 1;
    while (n <= 6) : (n += 1) {
        try expectEqual(@as(u8, 6 - n), wheel.count(minorEleven(C) & minorEleven(wheel.turned(C, -@as(i32, n)))));
    }
    // his four examples
    try expectEqual(set(&.{ C, Eb, F, Bb }), minorEleven(C) & minorEleven(Bb));
    try expectEqual(set(&.{ Eb, F, Bb }), minorEleven(C) & minorEleven(Eb));
    try expectEqual(set(&.{ Eb, Bb }), minorEleven(C) & minorEleven(Ab));
    try expectEqual(set(&.{Eb}), minorEleven(C) & minorEleven(Db));
}

test "the-wormhole: Hum's C over each root, a floor at a time" {
    const flatward = [7]key.Floor{ .one, .five, .nine, .thirteen, .three, .seven, .raised_eleven };
    for (flatward, 0..) |floor, n| {
        try expectEqual(floor, c_day.floorOn(land(wheel.turned(C, -@as(i32, @intCast(n))))));
    }
    const sharpward = [5]key.Floor{ .eleven, .low_seven, .low_three, .low_thirteen, .low_nine };
    for (sharpward, 1..) |floor, n| {
        try expectEqual(floor, c_day.floorOn(land(wheel.turned(C, @intCast(n)))));
    }
    // each chord is tuned so that his note sits exactly on that floor
    try expectEqual(Note.r(45, 32), c_day.chordOn(land(Fs)).hears(c_day.note()));
    try expectEqual(Note.r(4, 3), c_day.chordOn(land(G)).hears(c_day.note()));
}

test "the-wormhole: the twins" {
    const g7 = c_day.chordOn(land(G)).members(Voice.whole, 4);
    const db7 = c_day.chordOn(land(Db)).members(Voice.whole, 4);
    try expectEqual(chord_mod.Role.third, g7.roleOf(B).?);
    try expectEqual(chord_mod.Role.seventh, g7.roleOf(F).?);
    try expectEqual(chord_mod.Role.third, db7.roleOf(F).?);
    try expectEqual(chord_mod.Role.seventh, db7.roleOf(B).?);
}

test "the-wormhole: the six safe notes" {
    // G's natural minor without its sixth note, E flat
    const g_minor = (Day{ .home = -2 }).colours();
    try expectEqual(set(&.{ G, A, Bb, C, D, Eb, F }), g_minor);
    try expectEqual(minorEleven(G), g_minor & ~wheel.colour(Eb));
}

test "the-wormhole: the third under home" {
    const cave_chord = c_day.ringChord(Ring.remembers);
    try expectEqual(Note.r(5, 6), cave_chord.root);
    try expectEqual(Note.r(5, 4), cave_chord.note(.fifth));
    // the ground plays the root and the fifth; Hum's own note is the third between them
    const ground = cave_chord.plain(Voice.open_fifths);
    try expectEqual(@as(u8, 2), ground.n);
    try expectEqual(Note.r(6, 5), cave_chord.hears(c_day.note()));
    try expectEqual(cave_chord.note(.third), c_day.note());
}
