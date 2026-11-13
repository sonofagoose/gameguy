//! The sound: one sustained tone per place plus the player's own tone. Each tone is a fixed
//! recipe of partials read from a wavetable, so beating between tones is not an effect: it is
//! what summing them does.
//!
//! `Shared` is written by the game thread and read by the audio thread (plain atomics, no
//! locks, no allocation). `Voices` belongs to the audio thread alone.
const std = @import("std");
const tuning = @import("tuning.zig");

/// The rate the toy asks the audio device for.
pub const sample_rate: f32 = 48000.0;
pub const max_voices = 13; // the player + up to twelve places
pub const table_len = 2048;

pub const Shared = struct {
    freq: [max_voices]f32 = @splat(220.0),
    gain: [max_voices]f32 = @splat(0.0),
    master: f32 = 0.5,

    pub fn set(self: *Shared, voice: usize, freq: f32, gain: f32) void {
        @atomicStore(f32, &self.freq[voice], freq, .monotonic);
        @atomicStore(f32, &self.gain[voice], gain, .monotonic);
    }
};

pub const Voices = struct {
    phase: [max_voices]f32 = @splat(0.0),
    freq: [max_voices]f32 = @splat(220.0),
    gain: [max_voices]f32 = @splat(0.0),
    master: f32 = 0.0,
    /// Output rate in Hz; set to what the audio device actually gave before the first render.
    rate: f32 = sample_rate,
    player_table: [table_len + 1]f32 = undefined,
    place_table: [table_len + 1]f32 = undefined,

    pub fn init(self: *Voices) void {
        // The player: a hum with a strong body. Places: a brighter, bell-like recipe.
        // Both keep every partial up to the eighth, because agreement lives in the partials.
        // The fundamental leads, so the slowest beat (the one the water shows) is the one heard.
        buildTable(&self.player_table, &[_]f32{ 1.0, 0.45, 0.30, 0.16, 0.12, 0.07, 0.05, 0.03 });
        buildTable(&self.place_table, &[_]f32{ 1.0, 0.50, 0.40, 0.25, 0.20, 0.14, 0.09, 0.07 });
        for (&self.phase, 0..) |*p, i| {
            // start the voices at different points of their cycle so they do not all peak at once
            p.* = @as(f32, @floatFromInt((i * 397) % table_len));
        }
    }

    /// Fill `out` (interleaved, `channels` per frame) with the next `frames` frames.
    pub fn render(self: *Voices, shared: *const Shared, out: []f32, frames: usize, channels: usize) void {
        if (frames == 0) return;
        var freq_step: [max_voices]f32 = undefined;
        var gain_step: [max_voices]f32 = undefined;
        const inv_frames = 1.0 / @as(f32, @floatFromInt(frames));
        for (0..max_voices) |v| {
            const target_freq = @atomicLoad(f32, &shared.freq[v], .monotonic);
            const target_gain = @atomicLoad(f32, &shared.gain[v], .monotonic);
            freq_step[v] = (target_freq - self.freq[v]) * inv_frames;
            gain_step[v] = (target_gain - self.gain[v]) * inv_frames;
        }
        const target_master = @atomicLoad(f32, &shared.master, .monotonic);
        const master_step = (target_master - self.master) * inv_frames;
        const phase_per_hz = @as(f32, table_len) / self.rate;

        for (0..frames) |i| {
            var sum: f32 = 0.0;
            for (0..max_voices) |v| {
                self.freq[v] += freq_step[v];
                self.gain[v] += gain_step[v];
                var phase = self.phase[v] + self.freq[v] * phase_per_hz;
                if (phase >= table_len) phase -= table_len;
                self.phase[v] = phase;
                if (self.gain[v] <= 0.00001) continue;
                const table = if (v == 0) &self.player_table else &self.place_table;
                const index: usize = @intFromFloat(phase);
                const frac = phase - @as(f32, @floatFromInt(index));
                const a = table[index];
                const b = table[index + 1];
                sum += (a + (b - a) * frac) * self.gain[v];
            }
            self.master += master_step;
            const sample = softClip(sum * self.master);
            for (0..channels) |ch| out[i * channels + ch] = sample;
        }
    }
};

fn buildTable(table: *[table_len + 1]f32, partials: []const f32) void {
    var peak: f32 = 0.0;
    for (0..table_len) |i| {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, table_len);
        var sum: f32 = 0.0;
        for (partials, 1..) |amp, k| {
            sum += amp * @sin(2.0 * std.math.pi * t * @as(f32, @floatFromInt(k)));
        }
        table[i] = sum;
        peak = @max(peak, @abs(sum));
    }
    for (0..table_len) |i| table[i] /= peak;
    table[table_len] = table[0];
}

/// Gentle limiter: transparent while quiet, rounds off instead of clipping when loud.
fn softClip(x: f32) f32 {
    const limit = 0.9;
    if (x > limit) return limit + (1.0 - limit) * std.math.tanh((x - limit) / (1.0 - limit));
    if (x < -limit) return -limit - (1.0 - limit) * std.math.tanh((-x - limit) / (1.0 - limit));
    return x;
}

test "two tones 3 Hz apart beat 3 times a second" {
    const voices = try std.testing.allocator.create(Voices);
    defer std.testing.allocator.destroy(voices);
    voices.* = .{};
    voices.init();
    var shared = Shared{};
    shared.set(0, 220.0, 0.5);
    shared.set(1, 223.0, 0.5);

    const seconds = 4;
    const total = @as(usize, @intFromFloat(sample_rate)) * seconds;
    const out = try std.testing.allocator.alloc(f32, total);
    defer std.testing.allocator.free(out);
    const block = 128;
    var done: usize = 0;
    while (done < total) : (done += block) {
        const n = @min(block, total - done);
        voices.render(&shared, out[done .. done + n], n, 1);
    }

    // Loudness over 20 ms windows; count the dips after the first second (gains have settled).
    const window = 960;
    var dips: usize = 0;
    var previous: f32 = 0.0;
    var falling = false;
    var start: usize = @intFromFloat(sample_rate);
    while (start + window <= total) : (start += window) {
        var energy: f32 = 0.0;
        for (out[start .. start + window]) |s| energy += s * s;
        if (energy < previous) {
            falling = true;
        } else if (falling and energy > previous) {
            dips += 1;
            falling = false;
        }
        previous = energy;
    }
    // 3 seconds measured at 3 beats per second
    try std.testing.expect(dips >= 8 and dips <= 10);
}

test "output stays inside full scale even when every voice is loud" {
    const voices = try std.testing.allocator.create(Voices);
    defer std.testing.allocator.destroy(voices);
    voices.* = .{};
    voices.init();
    var shared = Shared{ .master = 1.0 };
    for (0..max_voices) |v| shared.set(v, 220.0 * @as(f32, @floatFromInt(v + 1)), 1.0);
    var out: [4096]f32 = undefined;
    voices.render(&shared, &out, 2048, 2);
    for (out) |s| try std.testing.expect(@abs(s) <= 1.0);
}
