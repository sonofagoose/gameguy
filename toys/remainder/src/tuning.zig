//! Pitch arithmetic: cents, the generator (a pure fifth), octave folding, and which pair of
//! partials two tones nearly share. No platform code; everything here is unit-tested.
const std = @import("std");

/// A pure fifth (3:2) in cents.
pub const fifth_cents: f64 = 1200.0 * @log2(1.5);
/// Twelve pure fifths overshoot seven octaves by this much.
pub const comma_cents: f64 = 12.0 * fifth_cents - 7.0 * 1200.0;

pub fn ratioFromCents(cents: f64) f64 {
    return @exp2(cents / 1200.0);
}

pub fn centsFromRatio(ratio: f64) f64 {
    return 1200.0 * @log2(ratio);
}

/// Fold a pitch in cents into one octave, [0, 1200).
pub fn fold(cents: f64) f64 {
    return @mod(cents, 1200.0);
}

/// Highest partial of a tone that is considered when looking for agreement.
pub const max_partial = 8;

/// Two tones "nearly agree" when partial `m` of the first and partial `n` of the second are
/// close in frequency. That closeness is what the ear hears as beating.
pub const Pair = struct {
    m: u8,
    n: u8,
    /// m * f1 - n * f2, in Hz. Positive: the first tone is sharp of agreement.
    beat_hz: f64,
    /// How strongly the pair is felt: 1 for a unison, less for higher partials.
    weight: f64,
};

fn gcd(a: u8, b: u8) u8 {
    var x = a;
    var y = b;
    while (y != 0) {
        const t = x % y;
        x = y;
        y = t;
    }
    return x;
}

/// The strongest pair of partials of `f1` and `f2` that beat slower than `limit_hz`, or null
/// when the tones share nothing that slow. Pairs that are multiples of a lower pair (2:2 is 1:1
/// an octave up) are skipped: the lowest pair is the one that is heard and felt.
pub fn nearestPair(f1: f64, f2: f64, limit_hz: f64) ?Pair {
    var best: ?Pair = null;
    var m: u8 = 1;
    while (m <= max_partial) : (m += 1) {
        var n: u8 = 1;
        while (n <= max_partial) : (n += 1) {
            if (gcd(m, n) != 1) continue;
            const beat = @as(f64, @floatFromInt(m)) * f1 - @as(f64, @floatFromInt(n)) * f2;
            if (@abs(beat) >= limit_hz) continue;
            const weight = 1.0 / @sqrt(@as(f64, @floatFromInt(@as(u32, m) * @as(u32, n))));
            if (best == null or weight > best.?.weight) {
                best = .{ .m = m, .n = n, .beat_hz = beat, .weight = weight };
            }
        }
    }
    return best;
}

/// How far (in cents) a tone at `freq_hz` must move for its partial `m` to beat `beat_hz`
/// faster. Used to make the stick mean "this much beating" in every register.
pub fn centsForBeat(freq_hz: f64, m: u8, beat_hz: f64) f64 {
    const carrier = freq_hz * @as(f64, @floatFromInt(m));
    const ratio = 1.0 + beat_hz / carrier;
    if (ratio <= 0.0) return -1200.0;
    return centsFromRatio(ratio);
}

test "the comma is 23.46 cents" {
    try std.testing.expectApproxEqAbs(@as(f64, 23.460), comma_cents, 0.001);
    try std.testing.expectApproxEqAbs(@as(f64, 701.955), fifth_cents, 0.001);
}

test "twelve folded fifths come home one comma sharp" {
    var cents: f64 = 0.0;
    for (0..12) |_| cents = fold(cents + fifth_cents);
    try std.testing.expectApproxEqAbs(comma_cents, cents, 1e-9);
}

test "a pure fifth agrees on partials 2 and 3 with no beat" {
    const pair = nearestPair(330.0, 220.0, 12.0).?;
    try std.testing.expectEqual(@as(u8, 2), pair.m);
    try std.testing.expectEqual(@as(u8, 3), pair.n);
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), pair.beat_hz, 1e-9);
}

test "an equal-tempered fifth beats slowly flat" {
    const tempered = 220.0 * ratioFromCents(700.0);
    const pair = nearestPair(tempered, 220.0, 12.0).?;
    try std.testing.expectEqual(@as(u8, 2), pair.m);
    try std.testing.expectEqual(@as(u8, 3), pair.n);
    try std.testing.expectApproxEqAbs(@as(f64, -0.745), pair.beat_hz, 0.01);
}

test "a unison wins over higher pairs, and far-apart tones share nothing" {
    const near = nearestPair(221.0, 220.0, 12.0).?;
    try std.testing.expectEqual(@as(u8, 1), near.m);
    try std.testing.expectEqual(@as(u8, 1), near.n);
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), near.beat_hz, 1e-9);
    // a tritone-ish gap (ratio 1.41) has no slow pair below partial 8
    try std.testing.expect(nearestPair(220.0 * 1.4142, 220.0, 3.0) == null);
}

test "centsForBeat round-trips" {
    const cents = centsForBeat(220.0, 2, 3.0);
    const bent = 220.0 * ratioFromCents(cents);
    try std.testing.expectApproxEqAbs(@as(f64, 3.0), 2.0 * bent - 2.0 * 220.0, 1e-9);
}
