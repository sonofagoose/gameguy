//! What the speaker's shaping costs the sound thread (sound.zig, "The speaker is the floor").
//!
//! The sound at its fullest: every one of the bank's 192 things struck and ringing, all four voices
//! humming and all eight held tones sounding, every note under the speaker's floor so the shaping
//! has the most to do. It renders the same cues twice, once shaped for the speaker and once with the
//! full range for headphones, in buffers of 128 frames as the sound thread does, and prints the
//! microseconds a buffer takes for each: the median, and the slowest of all. A buffer lasts
//! 2,667 microseconds.
//!
//!   ZIG=.tools/zig/zig
//!   $ZIG build-exe -O ReleaseSafe --dep rules -Mroot=game/bench/speaker.zig -Mrules=game/src/rules.zig \
//!       -lc -femit-bin=game/build/speaker-x86_64
//!
//! Run it pinned to one core: `taskset -c 1 ./speaker-aarch64`.
const std = @import("std");
const rules = @import("rules");
const sound = rules.sound;

const timespec = extern struct { tv_sec: i64, tv_nsec: i64 };
extern "c" fn clock_gettime(clk: c_int, ts: *timespec) c_int;

fn nowUs() f64 {
    var ts: timespec = undefined;
    _ = clock_gettime(1, &ts); // CLOCK_MONOTONIC
    return @as(f64, @floatFromInt(ts.tv_sec)) * 1e6 + @as(f64, @floatFromInt(ts.tv_nsec)) * 1e-3;
}

const buffers = 1500; // four seconds of sound, all of it still ringing
var times: [buffers]f64 = undefined;

fn fill(s: *sound.Sound) void {
    // the garden's scale an octave and two down, so every note is under the floor
    const notes = [_]f32{ 130.81, 146.83, 163.51, 174.61, 196.22, 218.02, 245.27, 261.63 };
    const families = [_]sound.Family{ .string, .bell, .bar, .skin, .fork, .stopped_pipe };
    var k: u32 = 0;
    while (k < 192) : (k += 1) {
        _ = s.push(.{ .at = k * 7, .kind = .strike, .family = families[k % families.len], .hz = notes[k % notes.len], .gain = 0.02, .ring = 6.0 });
    }
    var v: u8 = 0;
    while (v < sound.max_voices) : (v += 1) {
        _ = s.push(.{ .at = 0, .kind = .hum_on, .voice = v, .hz = notes[v * 2], .gain = 0.05 });
    }
    var t: u8 = 0;
    while (t < sound.max_tones) : (t += 1) {
        _ = s.push(.{ .at = 0, .kind = .tone, .voice = t, .hz = notes[t], .gain = 0.03 });
    }
}

fn run(s: *sound.Sound, speaker: bool) [2]f64 {
    s.init();
    s.setSpeaker(speaker);
    fill(s);
    var out: [128]f32 = undefined;
    // let every cue in, and the voices and tones ease up to their levels
    var warm: u32 = 0;
    while (warm < 400) : (warm += 1) s.render(&out);
    var slowest: f64 = 0.0;
    for (&times) |*t| {
        const began = nowUs();
        s.render(&out);
        t.* = nowUs() - began;
        slowest = @max(slowest, t.*);
    }
    std.mem.sort(f64, &times, {}, std.sort.asc(f64));
    return .{ times[buffers / 2], slowest };
}

pub fn main() void {
    const s = std.heap.page_allocator.create(sound.Sound) catch return;
    // twice each, alternating, so neither is favoured by the clocks settling
    var shaped: [2]f64 = .{ 1e9, 1e9 };
    var full: [2]f64 = .{ 1e9, 1e9 };
    var round: u32 = 0;
    while (round < 2) : (round += 1) {
        const a = run(s, true);
        const b = run(s, false);
        shaped = .{ @min(shaped[0], a[0]), @min(shaped[1], a[1]) };
        full = .{ @min(full[0], b[0]), @min(full[1], b[1]) };
    }
    std.debug.print("the sound at its fullest (192 things, 4 voices, 8 tones), a buffer of 128 frames (2667 us):\n", .{});
    std.debug.print("  shaped for the speaker: median {d:.1} us, slowest {d:.1} us\n", .{ shaped[0], shaped[1] });
    std.debug.print("  full range, headphones: median {d:.1} us, slowest {d:.1} us\n", .{ full[0], full[1] });
    std.debug.print("  the shaping costs {d:.1} us a buffer at the median, {d:.2}% of the buffer\n", .{ shaped[0] - full[0], 100.0 * (shaped[0] - full[0]) / 2667.0 });
}
