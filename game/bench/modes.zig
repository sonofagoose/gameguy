//! How many sounding overtones can one core render?
//!
//! The game's sound is built from resonators: every overtone of every thing is one two-pole
//! filter, y[n] = a1*y[n-1] + a2*y[n-2] + g*x[n]. This times a bank of them the way the sound
//! thread would run it: 128 frames at a time (2.67 ms at 48,000 Hz), four overtones abreast in
//! one vector, multiplies and adds kept separate (never fused) so every machine gets the same
//! samples. It prints a fingerprint of the sound so builds can be compared.
//!
//!   ZIG=.tools/zig/zig
//!   $ZIG build-exe -O ReleaseFast game/bench/modes.zig -lc -femit-bin=game/build/modes-x86_64
//!   $ZIG build-exe -O ReleaseFast -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35 \
//!       game/bench/modes.zig -lc -femit-bin=game/build/modes-aarch64
//!
//! Run it pinned to one core with the clocks at full speed: `taskset -c 1 ./modes-aarch64`.
const std = @import("std");

const timespec = extern struct { tv_sec: i64, tv_nsec: i64 };
extern "c" fn clock_gettime(clk: c_int, ts: *timespec) c_int;

fn nowUs() f64 {
    var ts: timespec = undefined;
    _ = clock_gettime(1, &ts); // CLOCK_MONOTONIC
    return @as(f64, @floatFromInt(ts.tv_sec)) * 1e6 + @as(f64, @floatFromInt(ts.tv_nsec)) * 1e-3;
}

const rate: f32 = 48000.0;
const frames = 128;
const V = @Vector(4, f32);
const max_groups = 2048; // 8,192 overtones

var a1: [max_groups]V = undefined;
var a2: [max_groups]V = undefined;
var gain: [max_groups]V = undefined;
var y1: [max_groups]V = undefined;
var y2: [max_groups]V = undefined;
var s_a1: [max_groups * 4]f32 = undefined;
var s_a2: [max_groups * 4]f32 = undefined;
var s_gain: [max_groups * 4]f32 = undefined;
var s_y1: [max_groups * 4]f32 = undefined;
var s_y2: [max_groups * 4]f32 = undefined;

/// A small generator with no library behind it, so the excitation is the same everywhere.
const Noise = struct {
    s: u32 = 0x1234_5678,
    fn next(self: *Noise) f32 {
        self.s ^= self.s << 13;
        self.s ^= self.s >> 17;
        self.s ^= self.s << 5;
        return @as(f32, @floatFromInt(@as(i32, @bitCast(self.s)) >> 8)) * (1.0 / 8388608.0);
    }
};

fn setUp() void {
    // Overtones spread from 80 Hz to 9 kHz, ringing between a quarter of a second and two.
    var i: usize = 0;
    while (i < max_groups * 4) : (i += 1) {
        const t = @as(f32, @floatFromInt(i % 257)) / 256.0;
        const hz = 80.0 * std.math.pow(f32, 112.5, t);
        const ring = 0.25 + 1.75 * @as(f32, @floatFromInt((i * 7) % 64)) / 63.0;
        const r = @exp(-1.0 / (ring * rate / 6.91));
        const theta = 2.0 * std.math.pi * hz / rate;
        s_a1[i] = 2.0 * r * @cos(theta);
        s_a2[i] = -(r * r);
        s_gain[i] = (1.0 - r) * 0.05;
        s_y1[i] = 0.0;
        s_y2[i] = 0.0;
    }
    var g: usize = 0;
    while (g < max_groups) : (g += 1) {
        a1[g] = s_a1[g * 4 ..][0..4].*;
        a2[g] = s_a2[g * 4 ..][0..4].*;
        gain[g] = s_gain[g * 4 ..][0..4].*;
        y1[g] = @splat(0.0);
        y2[g] = @splat(0.0);
    }
}

/// Four overtones abreast. `x` is what struck them; `acc` gathers their sound, four lanes wide.
fn renderVec(groups: usize, x: *const [frames]f32, out: *[frames]f32) void {
    @setRuntimeSafety(false);
    var acc: [frames]V = @splat(@splat(0.0));
    var g: usize = 0;
    while (g < groups) : (g += 1) {
        const ca1 = a1[g];
        const ca2 = a2[g];
        const cg = gain[g];
        var p1 = y1[g];
        var p2 = y2[g];
        var n: usize = 0;
        while (n < frames) : (n += 1) {
            const xin: V = @splat(x[n]);
            const y0 = ca1 * p1 + ca2 * p2 + cg * xin;
            acc[n] += y0;
            p2 = p1;
            p1 = y0;
        }
        y1[g] = p1;
        y2[g] = p2;
    }
    var n: usize = 0;
    while (n < frames) : (n += 1) out[n] = (acc[n][0] + acc[n][1]) + (acc[n][2] + acc[n][3]);
}

/// The same, one at a time, to compare with the probe's plain-code figures.
fn renderScalar(modes: usize, x: *const [frames]f32, out: *[frames]f32) void {
    @setRuntimeSafety(false);
    @memset(out, 0.0);
    var m: usize = 0;
    while (m < modes) : (m += 1) {
        const ca1 = s_a1[m];
        const ca2 = s_a2[m];
        const cg = s_gain[m];
        var p1 = s_y1[m];
        var p2 = s_y2[m];
        var n: usize = 0;
        while (n < frames) : (n += 1) {
            const y0 = ca1 * p1 + ca2 * p2 + cg * x[n];
            out[n] += y0;
            p2 = p1;
            p1 = y0;
        }
        s_y1[m] = p1;
        s_y2[m] = p2;
    }
}

fn hash(h: u64, out: *const [frames]f32) u64 {
    var x = h;
    for (out) |v| {
        x ^= @as(u32, @bitCast(v));
        x *%= 0x100000001b3;
    }
    return x;
}

const blocks = 3000;
var times: [blocks]f32 = undefined;

fn run(comptime vec: bool, modes: usize) void {
    setUp();
    var noise = Noise{};
    var x: [frames]f32 = undefined;
    var out: [frames]f32 = undefined;
    var h: u64 = 0xcbf29ce484222325;
    var loudest: f32 = 0.0;
    var b: usize = 0;
    while (b < blocks + 200) : (b += 1) {
        // Something is struck every block, so nothing ever rings down to nothing.
        for (&x, 0..) |*v, n| v.* = if (n < 24) noise.next() else 0.0;
        const t0 = nowUs();
        if (vec) renderVec(modes / 4, &x, &out) else renderScalar(modes, &x, &out);
        const t1 = nowUs();
        if (b >= 200) times[b - 200] = @floatCast(t1 - t0);
        h = hash(h, &out);
        for (out) |v| loudest = @max(loudest, @abs(v));
    }
    std.mem.sort(f32, &times, {}, std.sort.asc(f32));
    var sum: f64 = 0.0;
    for (times) |t| sum += t;
    const mean = sum / blocks;
    const p99 = times[blocks * 99 / 100];
    const worst = times[blocks - 1];
    const ns_per = mean * 1000.0 / @as(f64, @floatFromInt(modes * frames));
    // How many fit if the sound thread may use half of each 2,667 us buffer, by the 99th centile.
    const fit = @as(f64, @floatFromInt(modes)) * (2667.0 * 0.5) / p99;
    std.debug.print("{s} {d:>5} overtones: mean {d:>7.1} us, 99% {d:>7.1}, worst {d:>7.1}; {d:.2} ns each; {d:>5.0} fit in half a buffer; loudest {d:.3}; sound {x:0>16}\n", .{
        if (vec) "four abreast" else "one at a time",
        modes,
        mean,
        p99,
        worst,
        ns_per,
        fit,
        loudest,
        h,
    });
}

pub fn main() void {
    std.debug.print("overtone bank, {d} frames a buffer at {d:.0} Hz, {d} buffers timed each\n", .{ frames, rate, blocks });
    for ([_]usize{ 256, 1024, 2048, 4096 }) |m| run(false, m);
    for ([_]usize{ 256, 1024, 2048, 4096, 8192 }) |m| run(true, m);
}
