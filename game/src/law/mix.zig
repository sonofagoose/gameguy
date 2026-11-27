//! Streams and the roughness mix governor (docs/engine.md, step 0.10, "Sound: the bank, streams
//! and the mix").
//!
//! On one small mono speaker, too many things answering at once fuse into rough mud. The mix tracks
//! five streams and a compact table of currently ringing fundamentals/overtones:
//!   - `hum` and `beat` (Drip) are the two context axes and are NEVER thinned;
//!   - `ground` (the land/chord bed) and `band` (friends) are protected musical layers;
//!   - `answer` (sympathetic chimes, chord wake answers, cascades) is checked against the active
//!     tones using Sethares's critical-band roughness curve (matching `game/tools/ears.zig`). Over
//!     the roughness budget an answer is ducked or turned into light-only so "consonant by default"
//!     is enforced by the engine rather than by luck.
//!
//! Pure plain values (zero pointers, zero allocation) so it lives deterministically inside `World`.
const std = @import("std");

pub const Stream = enum(u8) {
    /// Hum's own voice, call, fork, clap, and direct chord step (context axis: never thinned).
    hum,
    /// Drip's tick and beat pulse (context axis: never thinned).
    beat,
    /// The land's ground note and chord bed.
    ground,
    /// Band friends' voices.
    band,
    /// Sympathetic chimes, cascades, and ambient answers (governed by stream cap + roughness).
    answer,
};

/// Active ringing tone tracked by the mix governor.
pub const Tone = struct {
    hz: f32 = 0.0,
    amp: f32 = 0.0,
    decay: f32 = 0.95,
    stream: Stream = .answer,
    live: bool = false,
};

pub const max_active = 24;
/// Maximum sympathetic answers admitted with sound in a single 60 Hz step (rest answer in light).
pub const max_answers_per_step: u8 = 8;

/// Sethares 1993 critical-band roughness between two partials (exact curve used by `tools/ears.zig`).
pub fn pairRoughness(f1: f32, a1: f32, f2: f32, a2: f32) f32 {
    if (a1 <= 0.0 or a2 <= 0.0 or f1 <= 1.0 or f2 <= 1.0) return 0.0;
    const lo = @min(f1, f2);
    const df = @abs(f2 - f1);
    const s = 0.24 / (0.0207 * lo + 18.96);
    return a1 * a2 * (@exp(-3.5 * s * df) - @exp(-5.75 * s * df));
}

/// Roughness threshold: halfway between a whole tone (9/8) and half step (16/15) at 440 Hz.
pub const rough_above: f32 = blk: {
    const whole = pairRoughness(440.0, 1.0, 440.0 * 9.0 / 8.0, 1.0);
    const half = pairRoughness(440.0, 1.0, 440.0 * 16.0 / 15.0, 1.0);
    break :blk 0.5 * (whole + half);
};

/// Roughness contribution of adding a candidate sound `(hz, amp)` (testing its fundamental,
/// octave, and twelfth partials) against all currently active tones in the mix.
fn candidateRoughness(tones: *const [max_active]Tone, hz: f32, amp: f32) f32 {
    if (amp <= 0.005 or hz < 20.0) return 0.0;
    var sum: f32 = 0.0;
    // Track loudest active tone so amplitudes normalize the way `ears.zig` normalizes frames
    var peak: f32 = amp;
    for (tones) |t| {
        if (t.live) peak = @max(peak, t.amp);
    }
    const inv = 1.0 / @max(peak, 0.05);
    const ca1 = amp * inv;
    const ca2 = ca1 * 0.45;
    const ca3 = ca1 * 0.25;
    for (tones) |t| {
        if (!t.live) continue;
        const ta1 = t.amp * inv;
        const ta2 = ta1 * 0.45;
        const ta3 = ta1 * 0.25;
        sum += pairRoughness(hz, ca1, t.hz, ta1);
        sum += pairRoughness(hz * 2.0, ca2, t.hz, ta1);
        sum += pairRoughness(hz, ca1, t.hz * 2.0, ta2);
        sum += pairRoughness(hz * 2.0, ca2, t.hz * 2.0, ta2);
        sum += pairRoughness(hz * 3.0, ca3, t.hz * 2.0, ta2);
        sum += pairRoughness(hz * 2.0, ca2, t.hz * 3.0, ta3);
        sum += pairRoughness(hz, ca1, t.hz * 3.0, ta3);
        sum += pairRoughness(hz * 3.0, ca3, t.hz, ta1);
    }
    return sum;
}

pub const Mix = struct {
    tones: [max_active]Tone = @splat(.{}),
    step_answers: u8 = 0,
    active_count: u8 = 0,
    /// Rolling instantaneous roughness estimate of the active tone bed (for Pause STATUS telemetry).
    rough_now: f32 = 0.0,
    /// Temporary roughness allowance multiplier (1.0 normally; raised on the seam / knots / wolf).
    allow_rough: f32 = 1.0,
    /// Lifetime telemetry counters.
    admitted: u32 = 0,
    ducked: u32 = 0,
    silenced: u32 = 0,

    /// Decay active tones by one 60 Hz step and reset the per-step answer cap.
    pub fn step(self: *Mix, dt: f32) void {
        self.step_answers = 0;
        var live_n: u8 = 0;
        for (&self.tones) |*t| {
            if (!t.live) continue;
            t.amp *= t.decay;
            if (t.amp < 0.015) {
                t.live = false;
                t.amp = 0.0;
            } else {
                live_n += 1;
            }
        }
        self.active_count = live_n;
        // Recompute lightweight active-bed roughness estimate
        var r: f32 = 0.0;
        var peak: f32 = 0.05;
        for (self.tones) |t| {
            if (t.live) peak = @max(peak, t.amp);
        }
        const inv = 1.0 / peak;
        for (0..max_active) |i| {
            if (!self.tones[i].live) continue;
            for (i + 1..max_active) |j| {
                if (!self.tones[j].live) continue;
                r += pairRoughness(self.tones[i].hz, self.tones[i].amp * inv, self.tones[j].hz, self.tones[j].amp * inv);
            }
        }
        self.rough_now = r;
        _ = dt;
    }

    /// Evaluate a sound cue for admission. Returns a gain multiplier in `[0, 1]`:
    ///   - `1.0`: admitted at full strength;
    ///   - `(0, 1)`: ducked to keep the mono speaker clear;
    ///   - `0.0`: silenced (light-only!) because stream cap or roughness ceiling was exceeded.
    /// Context axes (`.hum`, `.beat`) and musical beds (`.ground`, `.band`) are always `1.0`.
    pub fn admit(self: *Mix, stream: Stream, hz: f32, amp: f32, ring: f32) f32 {
        if (amp <= 0.001 or hz < 16.0) return 1.0;
        switch (stream) {
            .hum, .beat, .ground, .band => {
                self.record(stream, hz, amp, ring);
                self.admitted += 1;
                return 1.0;
            },
            .answer => {
                if (self.step_answers >= max_answers_per_step) {
                    self.silenced += 1;
                    return 0.0;
                }
                const budget = rough_above * 1.15 * @max(self.allow_rough, 1.0);
                const r = candidateRoughness(&self.tones, hz, amp);
                if (r > budget * 2.0) {
                    self.silenced += 1;
                    return 0.0;
                }
                self.step_answers += 1;
                if (r > budget) {
                    const over = (r - budget) / budget; // 0..1
                    const scale = std.math.clamp(1.0 - 0.65 * over, 0.35, 1.0);
                    self.record(stream, hz, amp * scale, ring);
                    self.ducked += 1;
                    self.admitted += 1;
                    return scale;
                }
                self.record(stream, hz, amp, ring);
                self.admitted += 1;
                return 1.0;
            },
        }
    }

    /// Register an already-sounding continuous bed (such as the hose drone or standing puddles) so
    /// incoming `.answer` cues are governed against what is actually in the room, without changing
    /// the bed itself or inflating cue admission counters.
    pub fn observe(self: *Mix, stream: Stream, hz: f32, amp: f32, ring: f32) void {
        if (amp <= 0.008 or hz < 16.0) return;
        self.record(stream, hz, amp, ring);
    }

    fn record(self: *Mix, stream: Stream, hz: f32, amp: f32, ring: f32) void {
        const eff_ring = std.math.clamp(ring, 0.08, 4.0);
        const decay = @exp(-(1.0 / 60.0) * 2.3 / eff_ring);
        // Merge into an existing close-pitch slot if present, else take free or quietest slot
        var pick: usize = 0;
        var quietest: f32 = std.math.floatMax(f32);
        for (&self.tones, 0..) |*t, i| {
            if (!t.live) {
                pick = i;
                break;
            }
            if (@abs(t.hz - hz) < hz * 0.01) {
                t.amp = @max(t.amp, amp);
                t.decay = @max(t.decay, decay);
                t.stream = stream;
                return;
            }
            if (t.amp < quietest) {
                quietest = t.amp;
                pick = i;
            }
        }
        self.tones[pick] = .{ .hz = hz, .amp = amp, .decay = decay, .stream = stream, .live = true };
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "mix protects context axes (hum & beat) and admits consonant pure fifths at full strength" {
    var mix = Mix{};
    // Hum C and Drip G are never thinned
    try expectEqual(@as(f32, 1.0), mix.admit(.hum, 261.63, 0.7, 1.0));
    try expectEqual(@as(f32, 1.0), mix.admit(.beat, 392.45, 0.5, 0.3));
    // Pure fifth and octave answers pass cleanly at full strength
    try expectEqual(@as(f32, 1.0), mix.admit(.answer, 523.26, 0.4, 0.8));
    try expectEqual(@as(f32, 1.0), mix.admit(.answer, 784.89, 0.4, 0.8));
    try expectEqual(@as(u32, 0), mix.silenced);
}

test "mix ducks or silences harsh semitone answer clashes while keeping hum & beat untouched" {
    var mix = Mix{};
    // Loud C + G chord bed ringing
    try expectEqual(@as(f32, 1.0), mix.admit(.ground, 261.63, 0.9, 1.5));
    try expectEqual(@as(f32, 1.0), mix.admit(.ground, 392.45, 0.8, 1.5));
    // An answer a harsh half-step above C (Db, 277.18 Hz) and F# against G (370 Hz) clashes strongly
    const clash = mix.admit(.answer, 277.18, 0.85, 1.0);
    try expect(clash < 1.0);
    // Hum itself is still admitted at full strength even on a semitone (the seam!)
    try expectEqual(@as(f32, 1.0), mix.admit(.hum, 245.28, 0.8, 0.8));
    // Stepping decays the active bed cleanly
    for (0..240) |_| mix.step(1.0 / 60.0);
    try expectEqual(@as(u8, 0), mix.active_count);
}

test "mix enforces per-step answer cap so cascades never flood the mono speaker" {
    var mix = Mix{};
    var sounded: u32 = 0;
    for (0..16) |i| {
        const hz: f32 = 261.63 * @as(f32, if (i % 2 == 0) 2.0 else 3.0);
        if (mix.admit(.answer, hz, 0.3, 0.6) > 0.0) sounded += 1;
    }
    try expectEqual(@as(u32, max_answers_per_step), sounded);
    try expectEqual(@as(u32, 16 - max_answers_per_step), mix.silenced);
}
