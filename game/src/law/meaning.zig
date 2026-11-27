//! Touches and the one table of meaning (docs/engine.md, step 0.10, "The world is an instrument").
//!
//! Every sound in the world is some thing answering one of five touches — never a disconnected UI
//! signal laid on top. Every physical quantity (distance, strength, tuning accuracy) maps through
//! one consistent acoustic/visual law so a listener can always infer what happened from what they
//! hear and see (Scaletti's inference test).
//!
//! No world in it and no platform.
const std = @import("std");

/// The five ways the world is touched (docs/engine.md, section 12).
pub const Touch = enum(u8) {
    /// A call: a ring runs out at the speed of sound and asks everything it passes.
    wave,
    /// A fork strike, footfall, landing, or bump: asks one thing, hard.
    knock,
    /// The swell or a held hum: asks slowly and builds up.
    bow,
    /// Drip, a creature, or a knot: asks again and again, drawing others into step.
    pulse,
    /// A step of the chord: asks nothing, changes what everything stands as.
    change,
};

pub const sound_speed: f32 = 60.0;
pub const sample_rate: f32 = 48000.0;

/// Travel delay in samples from a source `dist_m` metres away.
pub fn delaySamples(dist_m: f32) u64 {
    if (dist_m <= 0.0) return 0;
    return @intFromFloat(dist_m / sound_speed * sample_rate);
}

/// Inverse-square loudness falloff over `carry` metres: 1 at the source, 0.5 at `carry`.
pub fn distanceGain(dist_m: f32, carry: f32) f32 {
    if (dist_m <= 0.0 or carry <= 0.0) return 1.0;
    const r = dist_m / carry;
    return 1.0 / (1.0 + r * r);
}

/// High-frequency air dullness with distance: 0 at the source, rising smoothly farther off.
pub fn distanceDull(dist_m: f32, carry: f32) f32 {
    if (dist_m <= 0.0 or carry <= 0.0) return 0.0;
    return dist_m / (carry * 4.0);
}

/// Perceived brightness from acoustic strength (both follow the square root).
pub fn lightBrightness(strength: f32) f32 {
    return @sqrt(@max(strength, 0.0));
}

/// Acoustic beat rate (Hz) between two nearby frequencies: shimmer rate on screen matches beats.
pub fn beatHz(hz_a: f32, hz_b: f32) f32 {
    return @abs(hz_a - hz_b);
}

/// How many times the faster of two whole-number pulses (p:q) passes the slower in one cycle
/// (TRAPPIST-1 / docs/engine.md: |p - q|).
pub fn pulsePasses(p: u16, q: u16) u16 {
    return if (p >= q) p - q else q - p;
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const approx = std.testing.expectApproxEqAbs;

test "the table of meaning preserves inference: monotonic with distance, strength, and ratio" {
    // 60 m at 60 m/s is exactly one second (48,000 samples)
    try expectEqual(@as(u64, 0), delaySamples(0.0));
    try expectEqual(@as(u64, 48000), delaySamples(60.0));
    try expect(delaySamples(120.0) > delaySamples(60.0));

    // loudness falls monotonically and halves at `carry`; dullness rises monotonically
    try approx(@as(f32, 1.0), distanceGain(0.0, 30.0), 1e-6);
    try approx(@as(f32, 0.5), distanceGain(30.0, 30.0), 1e-6);
    try expect(distanceGain(60.0, 30.0) < distanceGain(30.0, 30.0));
    try expect(distanceDull(60.0, 30.0) > distanceDull(30.0, 30.0));

    // brightness matches perceptual root of strength
    try approx(@as(f32, 0.5), lightBrightness(0.25), 1e-6);
    try approx(@as(f32, 0.0), lightBrightness(-1.0), 1e-6);

    // 3:2 passes once per cycle; 5:3 (the Garden's first knots) passes twice
    try expectEqual(@as(u16, 1), pulsePasses(3, 2));
    try expectEqual(@as(u16, 2), pulsePasses(5, 3));
}
