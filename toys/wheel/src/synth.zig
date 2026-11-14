//! The sound, and the clock.
//!
//! Two kinds of voice. Drones are sustained tones the game steers (Hum's hum, the chord under
//! everything, the swell). Shots are single notes with their own shape (a fork strike, Drip's
//! tick, a creature's pulse), which can be asked for ahead of time and start on an exact beat.
//!
//! The audio thread also keeps musical time. Beats are counted in samples here and read by the
//! game, so what is heard and what is seen cannot drift apart. Thick time (the wheel held
//! open) slows that count, and the game slows with it.
//!
//! `Shared` is written by the game thread and read by the audio thread (plain atomics and a
//! one-writer queue; no locks, no allocation). `Engine` belongs to the audio thread alone.
const std = @import("std");

/// The rate the toy asks the audio device for.
pub const sample_rate: f32 = 48000.0;
pub const table_len = 2048;

pub const Table = enum(u8) {
    /// Hum: a closed mouth, nearly all fundamental.
    hum,
    /// The chord under everything: warm.
    pad,
    /// Struck things: the fork, a creature's note.
    bell,
    /// Round and plain: Drip, third voices.
    soft,
    /// A click with a pitch.
    tick,
    /// Hollow, odd partials only: a creature that has gone grey.
    reed,
};
const table_count = 6;

pub const drones = 20;
pub const shots = 40;
const queue_len = 256;

/// One note with its own shape.
pub const Shot = struct {
    /// Musical time at which it starts, in beats. Zero or anything already past means now.
    at_beat: f64 = 0.0,
    table: Table = .bell,
    hz: f32 = 440.0,
    gain: f32 = 0.3,
    /// Seconds to reach full level.
    attack: f32 = 0.004,
    /// Seconds held at full level.
    hold: f32 = 0.0,
    /// Seconds for the level to fall to about a third, and again, and again.
    decay: f32 = 0.3,
    /// Starts this many times too high and falls to pitch at once (a drum). 1 is no bend.
    bend: f32 = 1.0,
};

pub const Shared = struct {
    freq: [drones]f32 = @splat(220.0),
    gain: [drones]f32 = @splat(0.0),
    /// Set before the audio starts and left alone.
    table: [drones]Table = @splat(.pad),
    /// Drones that drop in pitch when time goes thick.
    sinks: [drones]bool = @splat(false),
    /// How unsteady drone 0 (Hum) is, 0 to 1.
    waver: f32 = 0.0,
    master: f32 = 0.6,

    /// Beats a second at full speed.
    bps: f32 = 1.6,
    /// How fast musical time runs, 1 full speed. The engine eases toward it.
    scale: f32 = 1.0,
    /// Pitch of the sinking drones, 1 normal. The engine eases toward it.
    sink: f32 = 1.0,
    beat_bits: u64 = 0,

    queue: [queue_len]Shot = undefined,
    head: u32 = 0, // next slot the game writes
    tail: u32 = 0, // next slot the audio thread reads
    dropped: u32 = 0,

    pub fn set(self: *Shared, slot: usize, freq: f32, gain: f32) void {
        @atomicStore(f32, &self.freq[slot], freq, .monotonic);
        @atomicStore(f32, &self.gain[slot], gain, .monotonic);
    }

    pub fn setGain(self: *Shared, slot: usize, gain: f32) void {
        @atomicStore(f32, &self.gain[slot], gain, .monotonic);
    }

    pub fn play(self: *Shared, shot: Shot) void {
        const head = self.head;
        const next = (head + 1) % queue_len;
        if (next == @atomicLoad(u32, &self.tail, .acquire)) {
            self.dropped += 1;
            return;
        }
        self.queue[head] = shot;
        @atomicStore(u32, &self.head, next, .release);
    }

    /// Musical time now, in beats.
    pub fn beat(self: *const Shared) f64 {
        return @bitCast(@atomicLoad(u64, &self.beat_bits, .monotonic));
    }
};

const Voice = struct {
    state: enum { free, waiting, sounding } = .free,
    shot: Shot = .{},
    phase: f32 = 0.0,
    age: f32 = 0.0, // samples since it started
    level: f32 = 1.0, // the falling part of its shape
    fall: f32 = 1.0, // what `level` is multiplied by each sample
    bend: f32 = 0.0, // how far above pitch it still is
};

/// A small room: four feedback combs into two all-passes.
const Reverb = struct {
    const comb_len = [4]usize{ 1423, 1553, 1699, 1867 };
    const pass_len = [2]usize{ 241, 83 };
    comb: [4][2048]f32 = @splat(@splat(0.0)),
    damp: [4]f32 = @splat(0.0),
    pass: [2][256]f32 = @splat(@splat(0.0)),
    ci: [4]usize = @splat(0),
    pi: [2]usize = @splat(0),

    fn run(self: *Reverb, x: f32) f32 {
        var out: f32 = 0.0;
        for (0..4) |k| {
            const i = self.ci[k];
            const y = self.comb[k][i];
            self.damp[k] = y * 0.72 + self.damp[k] * 0.28;
            self.comb[k][i] = x + self.damp[k] * 0.80;
            self.ci[k] = if (i + 1 == comb_len[k]) 0 else i + 1;
            out += y;
        }
        out *= 0.25;
        for (0..2) |k| {
            const i = self.pi[k];
            const delayed = self.pass[k][i];
            const v = out + delayed * 0.6;
            self.pass[k][i] = v;
            self.pi[k] = if (i + 1 == pass_len[k]) 0 else i + 1;
            out = delayed - v * 0.6;
        }
        return out;
    }
};

pub const Engine = struct {
    /// Output rate in Hz; set to what the audio device actually gave before the first render.
    rate: f32 = sample_rate,
    tables: [table_count][table_len + 1]f32 = undefined,

    phase: [drones]f32 = @splat(0.0),
    freq: [drones]f32 = @splat(220.0),
    gain: [drones]f32 = @splat(0.0),
    master: f32 = 0.0,
    waver: f32 = 0.0,
    waver_phase: f32 = 0.0,
    scale: f32 = 1.0,
    sink: f32 = 1.0,
    beat: f64 = 0.0,

    voices: [shots]Voice = @splat(.{}),
    reverb: Reverb = .{},
    /// How much of the room is mixed in.
    wet: f32 = 0.20,

    pub fn init(self: *Engine) void {
        buildTable(&self.tables[@intFromEnum(Table.hum)], &[_]f32{ 1.0, 0.30, 0.10, 0.05, 0.02 });
        buildTable(&self.tables[@intFromEnum(Table.pad)], &[_]f32{ 1.0, 0.45, 0.25, 0.14, 0.08, 0.05, 0.03 });
        buildTable(&self.tables[@intFromEnum(Table.bell)], &[_]f32{ 1.0, 0.50, 0.30, 0.15, 0.08, 0.04 });
        buildTable(&self.tables[@intFromEnum(Table.soft)], &[_]f32{ 1.0, 0.22, 0.07 });
        buildTable(&self.tables[@intFromEnum(Table.tick)], &[_]f32{ 1.0, 0.0, 0.5, 0.0, 0.35, 0.0, 0.2 });
        buildTable(&self.tables[@intFromEnum(Table.reed)], &[_]f32{ 1.0, 0.0, 0.40, 0.0, 0.20, 0.0, 0.10 });
        for (&self.phase, 0..) |*p, i| p.* = @floatFromInt((i * 397) % table_len);
    }

    fn take(self: *Engine, shot: Shot) void {
        // a free voice, or else the one that has been sounding longest
        var pick: usize = 0;
        var oldest: f32 = -1.0;
        for (self.voices, 0..) |v, i| {
            if (v.state == .free) {
                pick = i;
                break;
            }
            if (v.state == .sounding and v.age > oldest) {
                oldest = v.age;
                pick = i;
            }
        }
        const v = &self.voices[pick];
        v.* = .{ .shot = shot, .state = if (shot.at_beat > self.beat) .waiting else .sounding };
        v.fall = @exp(-1.0 / (@max(shot.decay, 0.005) * self.rate));
        v.bend = shot.bend - 1.0;
    }

    /// Fill `out` (interleaved, `channels` per frame) with the next `frames` frames.
    pub fn render(self: *Engine, shared: *Shared, out: []f32, frames: usize, channels: usize) void {
        if (frames == 0) return;

        var tail = shared.tail;
        const head = @atomicLoad(u32, &shared.head, .acquire);
        while (tail != head) : (tail = (tail + 1) % queue_len) self.take(shared.queue[tail]);
        @atomicStore(u32, &shared.tail, tail, .release);

        var freq_step: [drones]f32 = undefined;
        var gain_step: [drones]f32 = undefined;
        const inv_frames = 1.0 / @as(f32, @floatFromInt(frames));
        for (0..drones) |d| {
            freq_step[d] = (@atomicLoad(f32, &shared.freq[d], .monotonic) - self.freq[d]) * inv_frames;
            gain_step[d] = (@atomicLoad(f32, &shared.gain[d], .monotonic) - self.gain[d]) * inv_frames;
        }
        const master_step = (@atomicLoad(f32, &shared.master, .monotonic) - self.master) * inv_frames;
        const waver_step = (@atomicLoad(f32, &shared.waver, .monotonic) - self.waver) * inv_frames;
        const scale_target = @atomicLoad(f32, &shared.scale, .monotonic);
        const sink_target = @atomicLoad(f32, &shared.sink, .monotonic);
        const bps = @atomicLoad(f32, &shared.bps, .monotonic);
        const ease = 1.0 - @exp(-1.0 / (0.07 * self.rate));
        const phase_per_hz = @as(f32, table_len) / self.rate;
        const bend_fall = @exp(-1.0 / (0.03 * self.rate));

        for (0..frames) |i| {
            self.scale += (scale_target - self.scale) * ease;
            self.sink += (sink_target - self.sink) * ease;
            self.beat += @as(f64, bps * self.scale / self.rate);
            self.waver += waver_step;
            self.waver_phase += 5.3 / self.rate;
            if (self.waver_phase >= 1.0) self.waver_phase -= 1.0;
            const shake = 1.0 + self.waver * 0.012 * @sin(self.waver_phase * 2.0 * std.math.pi);

            var sum: f32 = 0.0;
            for (0..drones) |d| {
                self.freq[d] += freq_step[d];
                self.gain[d] += gain_step[d];
                var f = self.freq[d];
                if (shared.sinks[d]) f *= self.sink;
                if (d == 0) f *= shake;
                var phase = self.phase[d] + f * phase_per_hz;
                if (phase >= table_len) phase -= table_len;
                self.phase[d] = phase;
                if (self.gain[d] <= 0.00001) continue;
                sum += lookup(&self.tables[@intFromEnum(shared.table[d])], phase) * self.gain[d];
            }

            for (&self.voices) |*v| {
                if (v.state == .waiting) {
                    if (self.beat < v.shot.at_beat) continue;
                    v.state = .sounding;
                }
                if (v.state != .sounding) continue;
                const seconds = v.age / self.rate;
                var level: f32 = 1.0;
                if (seconds < v.shot.attack) {
                    level = seconds / v.shot.attack;
                } else if (seconds > v.shot.attack + v.shot.hold) {
                    v.level *= v.fall;
                    level = v.level;
                    if (level < 0.0004) {
                        v.state = .free;
                        continue;
                    }
                }
                v.bend *= bend_fall;
                var phase = v.phase + v.shot.hz * (1.0 + v.bend) * phase_per_hz;
                while (phase >= table_len) phase -= table_len;
                v.phase = phase;
                v.age += 1.0;
                sum += lookup(&self.tables[@intFromEnum(v.shot.table)], phase) * v.shot.gain * level;
            }

            self.master += master_step;
            const dry = sum * self.master;
            const sample = softClip(dry + self.reverb.run(dry) * self.wet);
            for (0..channels) |ch| out[i * channels + ch] = sample;
        }
        @atomicStore(u64, &shared.beat_bits, @bitCast(self.beat), .monotonic);
    }
};

fn lookup(table: *const [table_len + 1]f32, phase: f32) f32 {
    const index: usize = @intFromFloat(phase);
    const frac = phase - @as(f32, @floatFromInt(index));
    const a = table[index];
    return a + (table[index + 1] - a) * frac;
}

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

const Bench = struct {
    engine: *Engine,
    shared: *Shared,

    fn make() !Bench {
        const engine = try std.testing.allocator.create(Engine);
        const shared = try std.testing.allocator.create(Shared);
        engine.* = .{};
        engine.init();
        shared.* = .{};
        return .{ .engine = engine, .shared = shared };
    }

    fn free(self: Bench) void {
        std.testing.allocator.destroy(self.engine);
        std.testing.allocator.destroy(self.shared);
    }

    /// Render `n` mono frames in device-sized blocks and return them.
    fn run(self: Bench, n: usize) ![]f32 {
        const out = try std.testing.allocator.alloc(f32, n);
        var done: usize = 0;
        while (done < n) : (done += 128) {
            const count = @min(128, n - done);
            self.engine.render(self.shared, out[done .. done + count], count, 1);
        }
        return out;
    }
};

test "the clock counts beats, and thick time slows it" {
    const b = try Bench.make();
    defer b.free();
    const one = try b.run(48000);
    defer std.testing.allocator.free(one);
    try std.testing.expectApproxEqAbs(@as(f64, 1.6), b.shared.beat(), 1e-3);

    b.shared.scale = 0.25;
    const settle = try b.run(24000);
    defer std.testing.allocator.free(settle);
    const before = b.shared.beat();
    const thick = try b.run(48000);
    defer std.testing.allocator.free(thick);
    try std.testing.expectApproxEqAbs(@as(f64, 0.4), b.shared.beat() - before, 2e-3);
}

test "a note asked for ahead of time starts on its beat" {
    const b = try Bench.make();
    defer b.free();
    b.shared.master = 1.0;
    b.shared.play(.{ .at_beat = 0.8, .hz = 440.0, .gain = 0.5 });
    const out = try b.run(48000);
    defer std.testing.allocator.free(out);
    var first: usize = 0;
    while (first < out.len and @abs(out[first]) < 1e-6) first += 1;
    // 0.8 beats at 1.6 beats a second is half a second
    try std.testing.expect(first >= 23998 and first <= 24004);
}

test "output stays inside full scale even when everything is loud" {
    const b = try Bench.make();
    defer b.free();
    b.shared.master = 1.0;
    for (0..drones) |d| b.shared.set(d, 110.0 * @as(f32, @floatFromInt(d + 1)), 1.0);
    for (0..shots) |k| b.shared.play(.{ .hz = 200.0 + 37.0 * @as(f32, @floatFromInt(k)), .gain = 1.0, .decay = 2.0 });
    const out = try b.run(8192);
    defer std.testing.allocator.free(out);
    for (out) |s| try std.testing.expect(@abs(s) <= 1.0);
}
