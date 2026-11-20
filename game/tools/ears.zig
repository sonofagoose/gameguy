//! The ears (spec/engine.md: "`game/tools/ears` reads a sound file and reports roughness, loudness,
//! the balance across bands, what is left between 400 Hz and 8 kHz, and what is left when left and
//! right are summed"; spec/laws.md, "For the ears"). Claude cannot hear. This is what it measures
//! instead, before Morgan's ears in the room decide.
//!
//!   ears FILE.wav [LOG]
//!
//! Prints `fact ears.NAME VALUE` lines for build/facts.txt, then a line for every stretch of
//! roughness longer than half a second, with the two partials that made the most of it. With the
//! game's log beside it, it measures the moments the log names as well: each strike, timed by the
//! hands or placed by the game (`sound strike-timed at sample N hz F`).
//!
//! Roughness is Sethares's sum over every pair of partials in a frame: the two amplitudes, the
//! frame's loudest partial as one, times his curve of how two partials that far apart beat. A pair
//! well under the loudest counts as little as it sounds. A frame is rough when it is rougher than
//! two equal pure tones halfway between a whole tone and a half step apart at 440 Hz: a whole tone
//! is not rough, a half step is.
//!
//!   ears FILE.wav LOG --detail FROM TO
//!
//! prints every frame from FROM to TO seconds: how loud, how rough, the pair that made the most of
//! it, and the loudest partials.
const std = @import("std");

pub const rate: f64 = 48000.0;
pub const frame_len = 8192;
pub const hop = 4096;
/// Partials quieter than this under the frame's loudest take no part in its roughness.
const peak_range_db: f64 = 40.0;
const most_peaks = 48;
/// A frame quieter than this is a tail, or silence: never rough.
const quiet_db: f64 = -50.0;
/// More than two seconds of sustained roughness is an error (spec/laws.md, "For the ears").
pub const rough_most_s: f64 = 2.0;
/// Where the handheld's one small speaker speaks (spec/laws.md).
pub const speaker_low: f64 = 400.0;
pub const speaker_high: f64 = 8000.0;

/// How rough two partials are together (Sethares 1993): their amplitudes times his curve, which
/// is greatest about a quarter of a critical band apart and nothing for a unison.
pub fn pairRoughness(f1: f64, a1: f64, f2: f64, a2: f64) f64 {
    if (a1 <= 0.0 or a2 <= 0.0) return 0.0;
    const lo = @min(f1, f2);
    const df = @abs(f2 - f1);
    const s = 0.24 / (0.0207 * lo + 18.96);
    return a1 * a2 * (@exp(-3.5 * s * df) - @exp(-5.75 * s * df));
}

/// Rough: rougher than two equal pure tones halfway between a whole tone and a half step apart.
pub fn roughAbove() f64 {
    const whole = pairRoughness(440.0, 1.0, 440.0 * 9.0 / 8.0, 1.0);
    const half = pairRoughness(440.0, 1.0, 440.0 * 16.0 / 15.0, 1.0);
    return 0.5 * (whole + half);
}

pub const Peak = struct { hz: f64, amp: f64 };

/// One frame of sound, looked at: how loud, how rough and which two partials made most of it, and
/// how its energy falls across the bands.
pub const Frame = struct {
    rms_db: f64 = -200.0,
    rough: f64 = 0.0,
    worst: [2]f64 = .{ 0.0, 0.0 },
    low: f64 = 0.0,
    mid: f64 = 0.0,
    high: f64 = 0.0,
    bands: [band_count]f64 = @splat(0.0),
};

/// Octave bands by their middles, 31.5 Hz to 16 kHz: the balance across them.
pub const band_count = 10;
pub const band_names = [band_count][]const u8{ "31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k" };
fn bandOf(hz: f64) usize {
    var edge: f64 = 44.2;
    var b: usize = 0;
    while (b + 1 < band_count and hz >= edge) : (b += 1) edge *= 2.0;
    return b;
}

pub const Ears = struct {
    window: [frame_len]f64 = undefined,
    re: [frame_len]f64 = undefined,
    im: [frame_len]f64 = undefined,
    mag: [frame_len / 2]f64 = undefined,

    pub fn init(self: *Ears) void {
        for (&self.window, 0..) |*w, i| {
            w.* = 0.5 - 0.5 * @cos(2.0 * std.math.pi * @as(f64, @floatFromInt(i)) / @as(f64, frame_len));
        }
    }

    /// Look at a frame of samples, frame_len long.
    pub fn look(self: *Ears, samples: []const f64) Frame {
        var out = Frame{};
        var sq: f64 = 0.0;
        for (samples, 0..) |x, i| {
            sq += x * x;
            self.re[i] = x * self.window[i];
            self.im[i] = 0.0;
        }
        out.rms_db = 10.0 * std.math.log10(@max(sq / @as(f64, frame_len), 1e-20));
        fft(&self.re, &self.im);
        const bin = rate / @as(f64, frame_len);
        for (&self.mag, 0..) |*m, k| {
            m.* = @sqrt(self.re[k] * self.re[k] + self.im[k] * self.im[k]);
            const e = m.* * m.*;
            const hz = @as(f64, @floatFromInt(k)) * bin;
            if (hz < speaker_low) out.low += e else if (hz <= speaker_high) out.mid += e else out.high += e;
            if (k > 0) out.bands[bandOf(hz)] += e;
        }
        if (out.rms_db < quiet_db) return out;
        var peaks: [most_peaks]Peak = undefined;
        const n = self.peaksOf(&peaks);
        const r = roughnessOf(peaks[0..n]);
        out.rough = r.rough;
        out.worst = r.worst;
        return out;
    }

    /// The frame's partials: its local maxima within the range of the loudest, each placed between
    /// bins by a parabola through the three around it, as hertz and amplitude (a full-scale sine is
    /// one), the loudest first.
    fn peaksOf(self: *Ears, out: []Peak) usize {
        var loudest: f64 = 0.0;
        for (self.mag[1 .. self.mag.len - 1]) |m| loudest = @max(loudest, m);
        if (loudest <= 0.0) return 0;
        const least = loudest * std.math.pow(f64, 10.0, -peak_range_db / 20.0);
        const floor = 3e-5 * @as(f64, frame_len) / 4.0;
        var n: usize = 0;
        var k: usize = 2;
        while (k + 2 < self.mag.len) : (k += 1) {
            const b = self.mag[k];
            if (b < least or b < floor or b <= self.mag[k - 1] or b < self.mag[k + 1]) continue;
            const a = 20.0 * std.math.log10(self.mag[k - 1] + 1e-30);
            const bb = 20.0 * std.math.log10(b + 1e-30);
            const c = 20.0 * std.math.log10(self.mag[k + 1] + 1e-30);
            const den = a - 2.0 * bb + c;
            const p = if (den != 0.0) 0.5 * (a - c) / den else 0.0;
            const db = bb - 0.25 * (a - c) * p;
            const peak = Peak{ .hz = (@as(f64, @floatFromInt(k)) + p) * rate / @as(f64, frame_len), .amp = std.math.pow(f64, 10.0, db / 20.0) * 4.0 / @as(f64, frame_len) };
            if (n < out.len) {
                out[n] = peak;
                n += 1;
            } else {
                // keep the loudest: put it in place of the quietest kept
                var q: usize = 0;
                for (out, 0..) |o, i| {
                    if (o.amp < out[q].amp) q = i;
                }
                if (peak.amp > out[q].amp) out[q] = peak;
            }
        }
        return n;
    }
};

pub const Rough = struct { rough: f64, worst: [2]f64 };

/// The roughness of a frame's partials, the loudest as one, and the pair that made most of it.
pub fn roughnessOf(peaks: []const Peak) Rough {
    var loudest: f64 = 0.0;
    for (peaks) |p| loudest = @max(loudest, p.amp);
    var out = Rough{ .rough = 0.0, .worst = .{ 0.0, 0.0 } };
    if (loudest <= 0.0) return out;
    var most: f64 = 0.0;
    for (peaks, 0..) |p, i| {
        for (peaks[i + 1 ..]) |q| {
            const r = pairRoughness(p.hz, p.amp / loudest, q.hz, q.amp / loudest);
            out.rough += r;
            if (r > most) {
                most = r;
                out.worst = .{ @min(p.hz, q.hz), @max(p.hz, q.hz) };
            }
        }
    }
    return out;
}

/// An iterative radix-2 Fourier transform, in place.
pub fn fft(re: []f64, im: []f64) void {
    const n = re.len;
    var j: usize = 0;
    var i: usize = 1;
    while (i < n) : (i += 1) {
        var bit = n >> 1;
        while (j & bit != 0) : (bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) {
            std.mem.swap(f64, &re[i], &re[j]);
            std.mem.swap(f64, &im[i], &im[j]);
        }
    }
    var len: usize = 2;
    while (len <= n) : (len <<= 1) {
        const half = len / 2;
        var start: usize = 0;
        while (start < n) : (start += len) {
            for (0..half) |k| {
                const ang = -2.0 * std.math.pi * @as(f64, @floatFromInt(k)) / @as(f64, @floatFromInt(len));
                const wr = @cos(ang);
                const wi = @sin(ang);
                const a = start + k;
                const b = a + half;
                const vr = re[b] * wr - im[b] * wi;
                const vi = re[b] * wi + im[b] * wr;
                re[b] = re[a] - vr;
                im[b] = im[a] - vi;
                re[a] += vr;
                im[a] += vi;
            }
        }
    }
}

/// How loud one note is in a stretch of sound, in decibels: a Hann-windowed sum at that note alone.
pub fn noteDb(samples: []const f64, hz: f64) f64 {
    var re: f64 = 0.0;
    var im: f64 = 0.0;
    const n: f64 = @floatFromInt(samples.len);
    for (samples, 0..) |x, i| {
        const t: f64 = @floatFromInt(i);
        const w = 0.5 - 0.5 * @cos(2.0 * std.math.pi * t / n);
        const a = 2.0 * std.math.pi * hz * t / rate;
        re += x * w * @cos(a);
        im -= x * w * @sin(a);
    }
    return 20.0 * std.math.log10(@max(@sqrt(re * re + im * im) * 4.0 / n, 1e-12));
}

const Sound = struct { left: []f64, right: ?[]f64, channels: u16 };

fn readWav(gpa: std.mem.Allocator, bytes: []const u8) !Sound {
    if (bytes.len < 44 or !std.mem.eql(u8, bytes[0..4], "RIFF") or !std.mem.eql(u8, bytes[8..12], "WAVE")) return error.NotWave;
    var at: usize = 12;
    var channels: u16 = 1;
    var bits: u16 = 16;
    var format: u16 = 1;
    while (at + 8 <= bytes.len) {
        const id = bytes[at .. at + 4];
        const size = std.mem.readInt(u32, bytes[at + 4 ..][0..4], .little);
        const body = bytes[at + 8 .. @min(bytes.len, at + 8 + size)];
        if (std.mem.eql(u8, id, "fmt ")) {
            format = std.mem.readInt(u16, body[0..2], .little);
            channels = std.mem.readInt(u16, body[2..4], .little);
            bits = std.mem.readInt(u16, body[14..16], .little);
        } else if (std.mem.eql(u8, id, "data")) {
            const width: usize = bits / 8;
            const frames = body.len / (width * channels);
            const left = try gpa.alloc(f64, frames);
            const right: ?[]f64 = if (channels > 1) try gpa.alloc(f64, frames) else null;
            for (0..frames) |f| {
                for (0..@min(channels, 2)) |ch| {
                    const off = (f * channels + ch) * width;
                    const v: f64 = if (format == 3 and bits == 32)
                        @floatCast(@as(f32, @bitCast(std.mem.readInt(u32, body[off..][0..4], .little))))
                    else
                        @as(f64, @floatFromInt(std.mem.readInt(i16, body[off..][0..2], .little))) / 32768.0;
                    if (ch == 0) left[f] = v else right.?[f] = v;
                }
            }
            return .{ .left = left, .right = right, .channels = channels };
        }
        at += 8 + size + (size & 1);
    }
    return error.NoData;
}

extern "c" fn fopen(path: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
extern "c" fn fread(ptr: [*]u8, size: usize, count: usize, file: *anyopaque) usize;
extern "c" fn fseek(file: *anyopaque, offset: c_long, whence: c_int) c_int;
extern "c" fn ftell(file: *anyopaque) c_long;
extern "c" fn fclose(file: *anyopaque) c_int;
extern "c" fn write(fd: c_int, buf: [*]const u8, n: usize) isize;

fn readAll(gpa: std.mem.Allocator, path: [*:0]const u8) ![]u8 {
    const file = fopen(path, "rb") orelse return error.CannotOpen;
    defer _ = fclose(file);
    _ = fseek(file, 0, 2);
    const size: usize = @intCast(ftell(file));
    _ = fseek(file, 0, 0);
    const bytes = try gpa.alloc(u8, size);
    if (fread(bytes.ptr, 1, size, file) != size) return error.ShortRead;
    return bytes;
}

fn say(comptime fmt: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    const line = std.fmt.bufPrint(&buf, fmt, args) catch return;
    _ = write(1, line.ptr, line.len);
}

// C's main, exported here and named for Zig's start code to leave alone; not under the test runner,
// which has a main of its own
pub const main = cMain;
comptime {
    if (!@import("builtin").is_test) @export(&cMain, .{ .name = "main" });
}

fn cMain(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    if (argc < 2) {
        say("ears FILE.wav [LOG]\n", .{});
        return 2;
    }
    var detail: ?[2]f64 = null;
    if (argc > 5 and std.mem.eql(u8, std.mem.span(argv[3]), "--detail")) {
        detail = .{ std.fmt.parseFloat(f64, std.mem.span(argv[4])) catch 0.0, std.fmt.parseFloat(f64, std.mem.span(argv[5])) catch 0.0 };
    }
    run(argv[1], if (argc > 2) argv[2] else null, detail) catch |err| {
        say("ears: {s}\n", .{@errorName(err)});
        return 1;
    };
    return 0;
}

fn run(wav_path: [*:0]const u8, log_path: ?[*:0]const u8, detail: ?[2]f64) !void {
    const gpa = std.heap.c_allocator;
    const bytes = try readAll(gpa, wav_path);
    const sound = try readWav(gpa, bytes);
    var mono = sound.left;
    var summed: f64 = 1.0;
    if (sound.right) |right| {
        // what is left when left and right are summed: the mono sum's energy against the two
        var each: f64 = 0.0;
        var sum: f64 = 0.0;
        mono = try gpa.alloc(f64, sound.left.len);
        for (sound.left, right, 0..) |l, r, i| {
            each += 0.5 * (l * l + r * r);
            mono[i] = 0.5 * (l + r);
            sum += mono[i] * mono[i];
        }
        summed = if (each > 0.0) sum / each else 1.0;
    }

    const ears = try gpa.create(Ears);
    ears.init();
    const above = roughAbove();

    var peak: f64 = 0.0;
    for (mono) |x| peak = @max(peak, @abs(x));
    var loudest_db: f64 = -200.0;
    var low: f64 = 0.0;
    var mid: f64 = 0.0;
    var high: f64 = 0.0;
    var bands: [band_count]f64 = @splat(0.0);
    var frames: usize = 0;
    var rough_frames: usize = 0;
    var run_len: usize = 0;
    var run_from: usize = 0;
    var longest: usize = 0;
    var run_worst: [2]f64 = .{ 0.0, 0.0 };
    var run_most: f64 = 0.0;
    var stretches: [64][4]f64 = undefined;
    var stretch_n: usize = 0;
    const hop_s = @as(f64, hop) / rate;
    var start: usize = 0;
    while (start + frame_len <= mono.len) : (start += hop) {
        const f = ears.look(mono[start .. start + frame_len]);
        frames += 1;
        loudest_db = @max(loudest_db, f.rms_db);
        low += f.low;
        mid += f.mid;
        high += f.high;
        for (&bands, f.bands) |*b, e| b.* += e;
        if (detail) |span| {
            const at = @as(f64, @floatFromInt(start)) / rate;
            if (at >= span[0] and at <= span[1]) {
                say("{d:7.2} s  {d:6.1} dB  rough {d:.3}{s}  most {d:.1} Hz against {d:.1} Hz  |", .{ at, f.rms_db, f.rough / above, if (f.rough > above) "*" else " ", f.worst[0], f.worst[1] });
                var peaks: [most_peaks]Peak = undefined;
                const n = ears.peaksOf(&peaks);
                std.mem.sort(Peak, peaks[0..n], {}, struct {
                    fn louder(_: void, a: Peak, b: Peak) bool {
                        return a.amp > b.amp;
                    }
                }.louder);
                for (peaks[0..@min(n, 8)]) |pk| say(" {d:.0}:{d:.0}", .{ pk.hz, 20.0 * std.math.log10(pk.amp) });
                say("\n", .{});
            }
        }
        const rough = f.rough > above;
        if (rough) {
            rough_frames += 1;
            if (run_len == 0) {
                run_from = start;
                run_most = 0.0;
            }
            run_len += 1;
            if (f.rough > run_most) {
                run_most = f.rough;
                run_worst = f.worst;
            }
        }
        if (!rough or start + hop + frame_len > mono.len) {
            if (run_len > 0) {
                longest = @max(longest, run_len);
                const secs = @as(f64, @floatFromInt(run_len)) * hop_s;
                if (secs >= 0.5 and stretch_n < stretches.len) {
                    stretches[stretch_n] = .{ @as(f64, @floatFromInt(run_from)) / rate, secs, run_worst[0], run_worst[1] };
                    stretch_n += 1;
                }
            }
            run_len = 0;
        }
    }
    const all = low + mid + high;
    say("fact ears.seconds {d:.1}\n", .{@as(f64, @floatFromInt(mono.len)) / rate});
    say("fact ears.peak {d:.3}\n", .{peak});
    say("fact ears.loudest_db {d:.1}\n", .{loudest_db});
    say("fact ears.rough_share {d:.4}\n", .{if (frames > 0) @as(f64, @floatFromInt(rough_frames)) / @as(f64, @floatFromInt(frames)) else 0.0});
    say("fact ears.rough_longest_s {d:.2}\n", .{@as(f64, @floatFromInt(longest)) * hop_s});
    say("fact ears.speaker_share {d:.4}\n", .{if (all > 0.0) mid / all else 0.0});
    say("fact ears.low_share {d:.4}\n", .{if (all > 0.0) low / all else 0.0});
    say("fact ears.high_share {d:.4}\n", .{if (all > 0.0) high / all else 0.0});
    say("fact ears.summed {d:.4}\n", .{summed});
    for (bands, band_names) |b, name| say("fact ears.band_{s} {d:.4}\n", .{ name, if (all > 0.0) b / all else 0.0 });

    // the moments the game's log names
    if (log_path) |path| {
        const log = try readAll(gpa, path);
        var timed: [256]f64 = undefined;
        var placed: [256]f64 = undefined;
        var timed_n: usize = 0;
        var placed_n: usize = 0;
        var lines = std.mem.splitScalar(u8, log, '\n');
        while (lines.next()) |line| {
            const is_timed = std.mem.startsWith(u8, line, "sound strike-timed at sample ");
            const is_placed = std.mem.startsWith(u8, line, "sound strike-placed at sample ");
            if (!is_timed and !is_placed) continue;
            var words = std.mem.tokenizeScalar(u8, line, ' ');
            var sample: ?usize = null;
            var hz: ?f64 = null;
            var prev: []const u8 = "";
            while (words.next()) |word| {
                if (std.mem.eql(u8, prev, "sample")) sample = std.fmt.parseInt(usize, word, 10) catch null;
                if (std.mem.eql(u8, prev, "hz")) hz = std.fmt.parseFloat(f64, word) catch null;
                prev = word;
            }
            const s = sample orelse continue;
            const f = hz orelse continue;
            // a tenth of a second from just after the burst
            const from = s + 96;
            if (from + 4800 > mono.len) continue;
            const span = mono[from .. from + 4800];
            const octave = noteDb(span, 2.0 * f) - noteDb(span, f);
            if (is_timed and timed_n < timed.len) {
                timed[timed_n] = octave;
                timed_n += 1;
            }
            if (is_placed and placed_n < placed.len) {
                placed[placed_n] = octave;
                placed_n += 1;
            }
        }
        if (timed_n > 0) say("fact ears.strike_timed_octave_db {d:.1}\n", .{median(timed[0..timed_n])});
        if (placed_n > 0) say("fact ears.strike_placed_octave_db {d:.1}\n", .{median(placed[0..placed_n])});
        say("fact ears.strikes_timed {d}\nfact ears.strikes_placed {d}\n", .{ timed_n, placed_n });
    }
    for (stretches[0..stretch_n]) |st| {
        say("rough: {d:.1} s to {d:.1} s ({d:.2} s), most from {d:.1} Hz against {d:.1} Hz\n", .{ st[0], st[0] + st[1], st[1], st[2], st[3] });
    }
}

fn median(xs: []f64) f64 {
    std.mem.sort(f64, xs, {}, std.sort.asc(f64));
    return xs[xs.len / 2];
}

fn tone(out: []f64, hz: f64, amp: f64, partials: usize) void {
    for (out, 0..) |*x, i| {
        const t = @as(f64, @floatFromInt(i)) / rate;
        for (1..partials + 1) |p| {
            const n: f64 = @floatFromInt(p);
            x.* += amp / n * @sin(2.0 * std.math.pi * hz * n * t);
        }
    }
}

test "a sine is found at its note and its size" {
    const e = try std.testing.allocator.create(Ears);
    defer std.testing.allocator.destroy(e);
    e.init();
    var x: [frame_len]f64 = @splat(0.0);
    tone(&x, 440.0, 0.25, 1);
    _ = e.look(&x);
    var peaks: [most_peaks]Peak = undefined;
    const n = e.peaksOf(&peaks);
    try std.testing.expect(n >= 1);
    try std.testing.expect(@abs(peaks[0].hz - 440.0) < 0.5);
    try std.testing.expect(@abs(20.0 * std.math.log10(peaks[0].amp / 0.25)) < 0.5);
}

test "a half step is rough, a whole tone and a pure fifth are not, one note alone is nothing" {
    const e = try std.testing.allocator.create(Ears);
    defer std.testing.allocator.destroy(e);
    e.init();
    const above = roughAbove();
    var x: [frame_len]f64 = @splat(0.0);
    tone(&x, 440.0, 0.2, 1);
    tone(&x, 440.0 * 16.0 / 15.0, 0.2, 1);
    try std.testing.expect(e.look(&x).rough > above);
    x = @splat(0.0);
    tone(&x, 440.0, 0.2, 1);
    tone(&x, 440.0 * 9.0 / 8.0, 0.2, 1);
    try std.testing.expect(e.look(&x).rough < above);
    x = @splat(0.0);
    tone(&x, 261.63, 0.15, 6);
    tone(&x, 261.63 * 1.5, 0.15, 6);
    try std.testing.expect(e.look(&x).rough < above);
    x = @splat(0.0);
    tone(&x, 261.63, 0.3, 6);
    try std.testing.expect(e.look(&x).rough < 0.25 * above);
}

test "a note's octave is measured against the note" {
    var x: [4800]f64 = @splat(0.0);
    tone(&x, 698.46, 0.3, 1);
    for (&x, 0..) |*v, i| v.* += 0.15 * @sin(2.0 * std.math.pi * 1396.9 * @as(f64, @floatFromInt(i)) / rate);
    const d = noteDb(&x, 1396.9) - noteDb(&x, 698.46);
    try std.testing.expect(@abs(d - (-6.02)) < 0.3);
}
