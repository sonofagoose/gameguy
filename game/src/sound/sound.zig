//! The sound: one bank of resonators that renders everything.
//!
//! Every overtone of every sounding thing is one two-pole filter, y = a1*y1 + a2*y2 + g*x, four
//! abreast in one vector (measured: about 2,100 fit in half a buffer on one core of the purple;
//! game/bench/modes.zig). A rung thing is a short burst into its overtones. A sung voice is a
//! stream of pulses through a few resonators that are its vowel.
//!
//! Nothing here touches the platform or keeps a beat of its own. The world sends cues stamped with
//! the sample they are due at, and `render` is a function of those cues alone, so the same cues
//! make the same samples on every machine. Multiplies and adds are never fused.
const std = @import("std");

pub const rate: f32 = 48000.0;
const V = @Vector(4, f32);

/// The shapes things come in, each with the overtones of that shape (spec/laws.md).
pub const Family = enum(u8) { bell, string, stopped_pipe, bar, skin };

pub const Recipe = struct { mult: [8]f32, gain: [8]f32 };

pub fn recipe(family: Family) Recipe {
    return switch (family) {
        // a made bell: its third is the land's own, pure here
        .bell => .{ .mult = .{ 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0 }, .gain = .{ 0.30, 1.0, 0.45, 0.35, 0.55, 0.20, 0.22, 0.10 } },
        .string => .{ .mult = .{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 }, .gain = .{ 1.0, 0.50, 0.33, 0.25, 0.20, 0.16, 0.14, 0.12 } },
        .stopped_pipe => .{ .mult = .{ 1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0 }, .gain = .{ 1.0, 0.33, 0.20, 0.14, 0.11, 0.09, 0.07, 0.06 } },
        .bar => .{ .mult = .{ 1.0, 2.756, 5.404, 8.933, 13.34, 18.64, 0.0, 0.0 }, .gain = .{ 1.0, 0.45, 0.25, 0.12, 0.06, 0.03, 0.0, 0.0 } },
        .skin => .{ .mult = .{ 1.0, 1.593, 2.136, 2.295, 2.653, 2.917, 3.156, 3.501 }, .gain = .{ 1.0, 0.55, 0.40, 0.30, 0.25, 0.18, 0.12, 0.10 } },
    };
}

/// What the world asks of the sound. `at` is the sample it is due.
pub const Cue = extern struct {
    at: u64,
    kind: Kind,
    family: Family = .bell,
    _pad: [2]u8 = .{ 0, 0 },
    /// The lowest note of the thing, in hertz.
    hz: f32 = 0.0,
    /// How hard, 0 to 1.
    gain: f32 = 0.0,
    /// How long its lowest note rings, in seconds.
    ring: f32 = 1.0,

    pub const Kind = enum(u8) { strike, hum_on, hum_off };
};

const max_things = 192; // 8 overtones each: 1,536 overtones, two groups a thing
const burst_len = 96; // 2 ms: what a strike is

const Thing = struct {
    left: u32 = 0, // samples of its burst still to come
    level: f32 = 0.0,
    /// Its own noise, so that what one thing sounds like never depends on what else is sounding.
    noise: u32 = 1,
    asleep: bool = true,
};

fn rnd(state: *u32) f32 {
    state.* ^= state.* << 13;
    state.* ^= state.* >> 17;
    state.* ^= state.* << 5;
    return @as(f32, @floatFromInt(@as(i32, @bitCast(state.*)) >> 8)) * (1.0 / 8388608.0);
}

pub const Sound = struct {
    // the bank: two groups of four for each thing
    a1: [max_things * 2]V = @splat(@splat(0.0)),
    a2: [max_things * 2]V = @splat(@splat(0.0)),
    gain: [max_things * 2]V = @splat(@splat(0.0)),
    y1: [max_things * 2]V = @splat(@splat(0.0)),
    y2: [max_things * 2]V = @splat(@splat(0.0)),
    things: [max_things]Thing = @splat(.{}),
    next_thing: u32 = 0,

    // Hum's voice: pulses through three resonators that are a closed-mouth vowel
    hum_a1: V = @splat(0.0),
    hum_a2: V = @splat(0.0),
    hum_gain: V = @splat(0.0),
    hum_y1: V = @splat(0.0),
    hum_y2: V = @splat(0.0),
    hum_phase: f32 = 0.0,
    hum_step: f32 = 0.0,
    hum_level: f32 = 0.0,
    hum_target: f32 = 0.0,

    hum_noise: u32 = 0x1234_5678,
    /// Samples rendered so far: the only clock there is.
    sample: u64 = 0,
    /// Cues that arrived after their sample had passed. They sound at once, and are counted.
    late: u32 = 0,

    // cues from the world, one writer and one reader
    queue: [256]Cue = undefined,
    head: u32 = 0,
    tail: u32 = 0,

    pub fn init(self: *Sound) void {
        self.* = .{};
        // "mm": one strong low resonance, two faint higher ones
        const hz = [4]f32{ 280.0, 1050.0, 2300.0, 100.0 };
        const width = [4]f32{ 70.0, 110.0, 160.0, 100.0 };
        const level = [4]f32{ 1.0, 0.22, 0.08, 0.0 };
        var a1: [4]f32 = undefined;
        var a2: [4]f32 = undefined;
        var g: [4]f32 = undefined;
        for (0..4) |i| {
            const r = @exp(-std.math.pi * width[i] / rate);
            a1[i] = 2.0 * r * @cos(2.0 * std.math.pi * hz[i] / rate);
            a2[i] = -(r * r);
            g[i] = level[i] * (1.0 - r);
        }
        self.hum_a1 = a1;
        self.hum_a2 = a2;
        self.hum_gain = g;
    }

    /// The world's side: ask for a sound. False if the queue is full.
    pub fn push(self: *Sound, cue: Cue) bool {
        const head = @atomicLoad(u32, &self.head, .monotonic);
        const tail = @atomicLoad(u32, &self.tail, .acquire);
        if (head -% tail >= self.queue.len) return false;
        self.queue[head % self.queue.len] = cue;
        @atomicStore(u32, &self.head, head +% 1, .release);
        return true;
    }

    fn apply(self: *Sound, cue: Cue) void {
        switch (cue.kind) {
            .hum_on => {
                self.hum_step = cue.hz / rate;
                self.hum_target = cue.gain;
            },
            .hum_off => self.hum_target = 0.0,
            .strike => {
                const slot = self.next_thing % max_things;
                self.next_thing +%= 1;
                const rec = recipe(cue.family);
                var a1: [8]f32 = undefined;
                var a2: [8]f32 = undefined;
                var g: [8]f32 = undefined;
                for (0..8) |i| {
                    const hz = cue.hz * rec.mult[i];
                    if (rec.mult[i] <= 0.0 or hz > rate * 0.45) {
                        a1[i] = 0.0;
                        a2[i] = 0.0;
                        g[i] = 0.0;
                        continue;
                    }
                    // higher overtones die sooner
                    const ring = @max(0.05, cue.ring / @sqrt(@max(rec.mult[i], 0.5) * 2.0));
                    const r = @exp(-6.91 / (ring * rate));
                    a1[i] = 2.0 * r * @cos(2.0 * std.math.pi * hz / rate);
                    a2[i] = -(r * r);
                    g[i] = rec.gain[i] * @sin(2.0 * std.math.pi * hz / rate) * 0.5;
                }
                self.a1[slot * 2] = a1[0..4].*;
                self.a1[slot * 2 + 1] = a1[4..8].*;
                self.a2[slot * 2] = a2[0..4].*;
                self.a2[slot * 2 + 1] = a2[4..8].*;
                self.gain[slot * 2] = g[0..4].*;
                self.gain[slot * 2 + 1] = g[4..8].*;
                // a thing struck again keeps ringing; a slot taken from an old thing starts clean
                self.y1[slot * 2] = @splat(0.0);
                self.y1[slot * 2 + 1] = @splat(0.0);
                self.y2[slot * 2] = @splat(0.0);
                self.y2[slot * 2 + 1] = @splat(0.0);
                self.things[slot] = .{ .left = burst_len, .level = cue.gain, .noise = 0x9e3779b9 ^ (self.next_thing *% 2654435761), .asleep = false };
            },
        }
    }

    /// Render the next `out.len` samples (one channel). Cues due inside them start on their sample.
    pub fn render(self: *Sound, out: []f32) void {
        var done: usize = 0;
        while (done < out.len) {
            // take every cue that is due, and find how far we can go before the next one
            var until: usize = out.len;
            while (true) {
                const tail = @atomicLoad(u32, &self.tail, .monotonic);
                const head = @atomicLoad(u32, &self.head, .acquire);
                if (tail == head) break;
                const cue = self.queue[tail % self.queue.len];
                const now = self.sample + done;
                if (cue.at <= now) {
                    if (cue.at < now) self.late += 1;
                    self.apply(cue);
                    @atomicStore(u32, &self.tail, tail +% 1, .release);
                    continue;
                }
                const gap = cue.at - now;
                if (gap < out.len - done) until = done + @as(usize, @intCast(gap));
                break;
            }
            self.renderPart(out[done..until], self.sample + done);
            done = until;
        }
        @atomicStore(u64, &self.sample, self.sample + out.len, .release);
    }

    /// How many samples have been rendered, for the loop on another thread to count steps by.
    pub fn played(self: *const Sound) u64 {
        return @atomicLoad(u64, &self.sample, .acquire);
    }

    /// `from` is the sample `out` starts at. The work is cut at every 128th sample counted from the
    /// very first, never from wherever a buffer happens to begin, so the samples are the same
    /// whatever size of buffer asks for them.
    fn renderPart(self: *Sound, out: []f32, from: u64) void {
        @setRuntimeSafety(false);
        if (out.len == 0) return;
        var acc: [128]V = undefined;
        var at: usize = 0;
        while (at < out.len) {
            const into: usize = @intCast((from + at) % 128);
            const n = @min(128 - into, out.len - at);
            @memset(acc[0..n], @as(V, @splat(0.0)));

            // rung things
            for (&self.things, 0..) |*thing, slot| {
                if (thing.asleep) continue;
                var x: [128]f32 = undefined;
                for (0..n) |i| {
                    if (thing.left > 0) {
                        // a short burst that fades: the mallet
                        const fade = @as(f32, @floatFromInt(thing.left)) * (1.0 / @as(f32, burst_len));
                        x[i] = rnd(&thing.noise) * fade * thing.level;
                        thing.left -= 1;
                    } else x[i] = 0.0;
                }
                var still: f32 = 0.0;
                inline for (0..2) |half| {
                    const g = slot * 2 + half;
                    const ca1 = self.a1[g];
                    const ca2 = self.a2[g];
                    const cg = self.gain[g];
                    var p1 = self.y1[g];
                    var p2 = self.y2[g];
                    for (0..n) |i| {
                        const xin: V = @splat(x[i]);
                        const y0 = ca1 * p1 + ca2 * p2 + cg * xin;
                        acc[i] += y0;
                        p2 = p1;
                        p1 = y0;
                    }
                    still = @max(still, @reduce(.Max, @abs(p1)) + @reduce(.Max, @abs(p2)));
                    self.y1[g] = p1;
                    self.y2[g] = p2;
                }
                // A thing that has rung down to nothing is set to nothing, so no machine ever
                // computes with the very small numbers processors treat differently.
                if (thing.left == 0 and still < 1e-7) {
                    inline for (0..2) |half| {
                        self.y1[slot * 2 + half] = @splat(0.0);
                        self.y2[slot * 2 + half] = @splat(0.0);
                    }
                    thing.asleep = true;
                }
            }

            // Hum's voice
            var p1 = self.hum_y1;
            var p2 = self.hum_y2;
            for (0..n) |i| {
                self.hum_level += (self.hum_target - self.hum_level) * 0.0015;
                var x: f32 = 0.0;
                if (self.hum_step > 0.0) {
                    self.hum_phase += self.hum_step;
                    if (self.hum_phase >= 1.0) {
                        self.hum_phase -= 1.0;
                        x = 1.0;
                    }
                }
                const xin: V = @splat((x + rnd(&self.hum_noise) * 0.004) * self.hum_level);
                const y0 = self.hum_a1 * p1 + self.hum_a2 * p2 + self.hum_gain * xin;
                acc[i] += y0 * @as(V, @splat(6.0));
                p2 = p1;
                p1 = y0;
            }
            if (self.hum_level < 1e-6 and self.hum_target == 0.0) {
                const size = @reduce(.Max, @abs(p1)) + @reduce(.Max, @abs(p2));
                if (size < 1e-7) {
                    p1 = @splat(0.0);
                    p2 = @splat(0.0);
                    self.hum_level = 0.0;
                }
            }
            self.hum_y1 = p1;
            self.hum_y2 = p2;

            for (0..n) |i| {
                const s = (acc[i][0] + acc[i][1]) + (acc[i][2] + acc[i][3]);
                // a soft limit: straight up to 0.7, then bending toward 1
                const a = @abs(s);
                out[at + i] = if (a <= 0.7) s else std.math.copysign(0.7 + 0.3 * (1.0 - 1.0 / (1.0 + (a - 0.7) * 3.3333)), s);
            }
            at += n;
        }
    }
};

test "the same cues make the same samples" {
    var a: Sound = undefined;
    var b: Sound = undefined;
    a.init();
    b.init();
    const cues = [_]Cue{
        .{ .at = 100, .kind = .strike, .hz = 261.63, .gain = 0.8, .ring = 1.5 },
        .{ .at = 4000, .kind = .hum_on, .hz = 261.63, .gain = 0.5 },
        .{ .at = 9000, .kind = .strike, .family = .bar, .hz = 392.44, .gain = 0.6, .ring = 0.8 },
        .{ .at = 20000, .kind = .hum_off },
    };
    for (cues) |cue| {
        try std.testing.expect(a.push(cue));
        try std.testing.expect(b.push(cue));
    }
    var out_a: [48000]f32 = undefined;
    var out_b: [48000]f32 = undefined;
    // one renders in buffers of 128, the other in buffers of 800: the samples must not care
    var at: usize = 0;
    while (at < out_a.len) : (at += 128) a.render(out_a[at..@min(at + 128, out_a.len)]);
    at = 0;
    while (at < out_b.len) : (at += 800) b.render(out_b[at..@min(at + 800, out_b.len)]);
    var loudest: f32 = 0.0;
    for (out_a, out_b) |x, y| {
        try std.testing.expectEqual(x, y);
        loudest = @max(loudest, @abs(x));
    }
    try std.testing.expect(loudest > 0.05);
    try std.testing.expect(loudest <= 1.0);
    try std.testing.expectEqual(@as(u32, 0), a.late);
}
