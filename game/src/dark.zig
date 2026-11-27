//! The scenes the workshop has: the dark and the call, and the proof field of asters.
//!
//! The dark: black. You call (R1) and a ring of light runs out over the ground. It lights what it
//! passes, and whatever is kin to your note answers, late by its distance. Hold R2 and Hum hums.
//!
//! The asters: the place, standing. Asters as tall as cathedrals (world/asters.zig), one to a
//! hundred. A call runs out over the ground and climbs every stalk it meets; the bells of a crown
//! are heard late by their height. Stand still at a foot and the view leans back.
//!
//! The loop here is the game's loop (spec/engine.md): the sound card's sample count is the only
//! clock, a step of the world is 800 samples, and each frame runs the steps that are due. With no
//! sound card (a run with no screen) the loop renders the sound itself, one step at a time.
const std = @import("std");
const plat = @import("plat/plat.zig");
const png = @import("plat/png.zig");
const lines = @import("draw/lines.zig");
const aster_lines = @import("draw/aster_lines.zig");
const garden_lines = @import("draw/garden_lines.zig");
const hum_figure = @import("draw/hum_figure.zig");
const black_shapes = @import("draw/black.zig");
const colour = @import("draw/colour.zig");
const drip_lines = @import("draw/drip_lines.zig");
const m = @import("m.zig");
const world_mod = @import("world/world.zig");
const sound_mod = @import("sound/sound.zig");
const Script = @import("bot/script.zig").Script;
const Walker = @import("bot/walker.zig").Walker;
const take = @import("keep/take.zig");
const save = @import("keep/save.zig");
const card_mod = @import("plat/card.zig");
const presses_mod = @import("plat/presses.zig");
const keys_mod = @import("plat/keys.zig");
const jack_mod = @import("plat/jack.zig");
const Type = @import("room.zig").Type;
const songbook = @import("draw/songbook.zig");
const c = plat.c;
const sdl = plat.sdl;
const gl = plat.gl;
const log = plat.log;

const World = world_mod.World;
const Hands = world_mod.Hands;

var snd: sound_mod.Sound = undefined;
var audio_channels: usize = 2;
var audio_realtime: i32 = -1;
var audio_slowest_us: u32 = 0;

// The sound's clock, for the picture: the samples counted when the latest buffer was asked for,
// and when. Written on the sound's thread, read on the picture's; `clock_seq` is odd while it is
// being written.
var clock_seq: u32 = 0;
var clock_sample: u64 = 0;
var clock_time: u64 = 0;

fn stampClock(sample: u64, time: f64) void {
    const s = @atomicLoad(u32, &clock_seq, .monotonic);
    @atomicStore(u32, &clock_seq, s +% 1, .release);
    @atomicStore(u64, &clock_sample, sample, .monotonic);
    @atomicStore(u64, &clock_time, @bitCast(time), .monotonic);
    @atomicStore(u32, &clock_seq, s +% 2, .release);
}

/// Where the sound's count is at `time`, in samples, carried on from the latest buffer at the
/// sound's own rate and no further than two buffers past it; null before the first.
fn soundClock(time: f64) ?f64 {
    var tries: u32 = 0;
    while (tries < 8) : (tries += 1) {
        const s1 = @atomicLoad(u32, &clock_seq, .acquire);
        if (s1 & 1 != 0) continue;
        const sample = @atomicLoad(u64, &clock_sample, .monotonic);
        const at: f64 = @bitCast(@atomicLoad(u64, &clock_time, .monotonic));
        const s2 = @atomicLoad(u32, &clock_seq, .acquire);
        if (s1 != s2) continue;
        if (s1 == 0) return null;
        const since = std.math.clamp((time - at) * sound_mod.rate, 0.0, 256.0);
        return @as(f64, @floatFromInt(sample)) + since;
    }
    return null;
}

/// What the picture needs of where Hum is: its place, its ground, which way it faces and which way
/// the view is turned and tilted.
const Pose = struct {
    x: f32,
    z: f32,
    ground: f32,
    height: f32,
    yaw: f32,
    orbit: f32,
    base: f32,
    lift: f32,
    face: f32,

    fn of(w: *const World) Pose {
        return .{ .x = w.hum_x, .z = w.hum_z, .ground = w.hum_ground, .height = w.hum_y, .yaw = w.look_yaw, .orbit = w.orbit, .base = w.view_base, .lift = w.eye_lift, .face = w.hum_face };
    }

    fn put(p: Pose, w: *World) void {
        w.hum_x = p.x;
        w.hum_z = p.z;
        w.hum_ground = p.ground;
        w.hum_y = p.height;
        w.look_yaw = p.yaw;
        w.orbit = p.orbit;
        w.view_base = p.base;
        w.eye_lift = p.lift;
        w.hum_face = p.face;
    }

    /// `a` steps on from `now`, at the pace from `before` to `now` (back toward `before` when `a` is
    /// below nought). A jump, as when the place is set somewhere new, is shown as it is.
    fn between(before: Pose, now: Pose, a: f32) Pose {
        const dx = now.x - before.x;
        const dz = now.z - before.z;
        if (dx * dx + dz * dz > 4.0 or @abs(now.yaw - before.yaw) > 0.5) return now;
        var turn = now.face - before.face;
        if (turn > std.math.pi) turn -= 2.0 * std.math.pi;
        if (turn < -std.math.pi) turn += 2.0 * std.math.pi;
        if (@abs(turn) > 0.5) turn = 0.0;
        return .{
            .x = now.x + dx * a,
            .z = now.z + dz * a,
            .ground = now.ground + (now.ground - before.ground) * a,
            .height = @max(0.0, now.height + (now.height - before.height) * a),
            .yaw = now.yaw + (now.yaw - before.yaw) * a,
            .orbit = now.orbit + (now.orbit - before.orbit) * a,
            .base = now.base + (now.base - before.base) * a,
            .lift = now.lift + (now.lift - before.lift) * a,
            .face = now.face + turn * a,
        };
    }
};

/// The shoulders and face buttons straight from the kernel, looked at before every buffer
/// (plat/presses.zig).
var presses = presses_mod.Presses{};
/// What the hands started, for the main thread: which edge, on which sample, how long after the
/// kernel saw it. One writer (the sound thread), one reader (the main thread).
const Started = struct { what: presses_mod.What, sample: u64, late_us: u32 };
var started: [128]Started = undefined;
var started_head: u32 = 0;
var started_tail: u32 = 0;
/// The cover under Hum, as the main thread last saw it, so the hands' call is as strong as the
/// world's will be.
var ready_cover: u8 = 0;
/// Home's note, as the main thread last saw it, for the hands' early start of Hum's own sounds.
var ready_home: u32 = @bitCast(world_mod.garden_hz);
/// Hum is out of breath: the hands start no note on the sound's thread.
var ready_winded: u8 = 0;
/// The songbook is open and the world waits: the hands start nothing on the sound's thread.
var ready_paused: u8 = 0;
/// Whether the world has Hum singing, as the main thread last saw it; and the sample on which the
/// hands began a hum the world has not yet taken up. A hum the world never takes up (a press it
/// did not hear) is ended by the sound thread within a tenth of a second: nothing can leave Hum's
/// voice ringing with no hand on R2.
var ready_singing: u8 = 0;
var own_hum_at: u64 = 0;
pub const own_hum_wait: u64 = 4800;
var sketch: songbook.Sketch = undefined;
var hands_most_us: u32 = 0;
/// The clap's rule, kept where the presses are stamped (keys_mod.Clap), and how many claps the
/// hands started.
var clap_rule = keys_mod.Clap{};
var hands_claps: u32 = 0;
var hands_strikes: u32 = 0;
/// The jack, looked at once a second: the sound is shaped for the speaker unless headphones are in.
var jack = jack_mod.Jack{};
var jack_path: jack_mod.Path = .unknown;
var jack_looked: u64 = 0;

fn followJack(step: u64) void {
    if (jack.fd < 0 or step < jack_looked + world_mod.steps_per_second) return;
    jack_looked = step;
    const now = jack.path();
    if (now == jack_path) return;
    jack_path = now;
    snd.setSpeaker(now != .headphones);
    log("the jack: the playback path is {s}, so the sound is {s}", .{ @tagName(now), if (now == .headphones) "its full range" else "shaped for the speaker" });
}

/// The world's beat as the main thread last left it, for the sound's thread to tell a timed strike
/// from one the game will place: two copies, the one not being written is the one to read.
const Beat = struct { clock: u64 = 0, part: f32 = 0.0, tempo: f32 = 1.0, at_sample: u64 = 0, can_strike: bool = false, window: f64 = world_mod.strike_window, home_k: i8 = 0, strike_count: u32 = 0 };
var beats: [2]Beat = .{ .{}, .{} };
var beat_now: u32 = 0;

fn publishBeat(w: *const World) void {
    const next = (@atomicLoad(u32, &beat_now, .monotonic) + 1) % 2;
    beats[next] = .{ .clock = w.clock, .part = w.clock_part, .tempo = w.tempo, .at_sample = w.step * world_mod.samples_per_step, .can_strike = w.canStrike(), .window = w.widen(world_mod.strike_window), .home_k = w.home_k, .strike_count = w.strike_count };
    @atomicStore(u32, &beat_now, next, .release);
}

/// The sound thread starts a strike itself only when it is well inside the window, so it never
/// starts one the world will place; a strike at the window's very edge is the world's to sound.
const strike_margin: f64 = 0.75;

/// Whether a press of the left face on this sample is a timed strike, by the world's own sum.
fn timedNow(sample: u64) bool {
    const b = beats[@atomicLoad(u32, &beat_now, .acquire)];
    if (!b.can_strike or sample < b.at_sample) return false;
    // whole steps from the world's last step to the press, then the stamp within the step
    const steps_on = (sample - b.at_sample) / world_mod.samples_per_step;
    const stamp: u16 = @intCast((sample - b.at_sample) % world_mod.samples_per_step);
    var clock = b.clock;
    var part: f64 = b.part;
    var k: u64 = 0;
    while (k < steps_on and k < 16) : (k += 1) {
        part += b.tempo;
        while (part >= 1.0) {
            part -= 1.0;
            clock += 1;
        }
    }
    const at = World.beatOf(clock, @floatCast(part), b.tempo, stamp);
    return at.from_beat <= b.window - strike_margin;
}

/// Each of Hum's strikes, timed or placed, with its sample and note, for the ears
/// (tools/ears.zig) to find in the evening's sound.
fn noteStrike(cue: sound_mod.Cue) void {
    if (cue.kind != .strike) return;
    if (cue.family == .fork_octave) {
        log("sound strike-timed at sample {d} hz {d:.2}", .{ cue.at, cue.hz });
    } else if (cue.family == .fork and cue.own == sound_mod.own_only and cue.hz >= world.home_hz * 1.5) {
        log("sound strike-placed at sample {d} hz {d:.2}", .{ cue.at, cue.hz });
    }
}

/// Hum's timed strike as the hands start it: the same sound the world tells for it.
fn strikeCue(home: f32, count: u32, home_k: i8, timed: bool) sound_mod.Cue {
    const ratios = world_mod.chordRatios(world_mod.homeQuality(home_k));
    const fork = home * world_mod.strike_over * ratios[count % 3];
    return .{
        .at = 0,
        .kind = .strike,
        .family = if (timed) .fork_octave else .fork,
        .own = sound_mod.own_strike,
        .hz = fork,
        .gain = world_mod.strike_strength * world_mod.voice_level,
        .ring = world_mod.strike_ring,
    };
}

/// Hum's clap as the hands start it: the same sound the world tells for it.
fn clapCue(home: f32) sound_mod.Cue {
    return .{ .at = 0, .kind = .strike, .family = .bar, .own = sound_mod.own_clap, .hz = home * world_mod.clap_over, .gain = world_mod.clap_strength * world_mod.voice_level, .ring = world_mod.clap_ring };
}
var hands_started: u32 = 0;

/// On the sound's thread, before a buffer: whatever R1 and R2 did since the last one. A press
/// starts Hum's own call or hum on this buffer's first sample; a let-go is only noted, since the
/// world decides whether a let-go ends the hum or locks the breath.
fn handsNow() void {
    if (own_hum_at != 0) {
        if (@atomicLoad(u8, &ready_singing, .monotonic) != 0) {
            own_hum_at = 0;
        } else if (snd.sample > own_hum_at + own_hum_wait) {
            _ = snd.ownNow(.{ .at = 0, .kind = .hum_off, .own = sound_mod.own_hands, .hz = 0.0, .gain = 0.0 });
            own_hum_at = 0;
        }
    }
    var edges: [16]presses_mod.Edge = undefined;
    const n = presses.poll(&edges);
    if (n == 0) return;
    // the songbook open: the world waits, and what the hands press starts nothing
    if (@atomicLoad(u8, &ready_paused, .monotonic) != 0) return;
    const now_s = plat.now();
    const home: f32 = @bitCast(@atomicLoad(u32, &ready_home, .monotonic));
    for (edges[0..n], 0..) |e, i| {
        // L1 and R1 within the clap's window, whichever second, is the clap (SPEC.md 8)
        var clapped = false;
        const at: u64 = switch (e.what) {
            .call_down => blk: {
                if (clap_rule.press(false, e.at_s)) {
                    clapped = true;
                    break :blk snd.ownNow(clapCue(home));
                }
                // L1 in this same look, near enough to make this a clap: no call to start
                for (edges[i + 1 .. n]) |later| {
                    if (later.what == .voice_down and clap_rule.wouldClap(true, later.at_s)) break :blk snd.sample;
                }
                break :blk snd.ownNow(world_mod.heardAs(world_mod.callSound(home, @enumFromInt(@atomicLoad(u8, &ready_cover, .monotonic))), sound_mod.own_hands));
            },
            .voice_down => blk: {
                if (clap_rule.press(true, e.at_s)) {
                    clapped = true;
                    break :blk snd.ownNow(clapCue(home));
                }
                break :blk snd.sample;
            },
            .sing_down => blk: {
                if (@atomicLoad(u8, &ready_winded, .monotonic) != 0) break :blk snd.sample;
                const began = snd.ownNow(world_mod.heardAs(world_mod.humSound(home), sound_mod.own_hands));
                own_hum_at = began;
                break :blk began;
            },
            // the left face strikes with Hum's fork (SPEC.md 10):
            // fires at once on press with low kernel latency (~2 ms);
            // timed inside the beat's window plays fork_octave, outside plays plain fork.
            .strike_down => blk: {
                const b = beats[@atomicLoad(u32, &beat_now, .acquire)];
                if (!b.can_strike) break :blk snd.sample;
                const strike_idx = @atomicLoad(u32, &hands_strikes, .monotonic);
                @atomicStore(u32, &hands_strikes, strike_idx + 1, .monotonic);
                const timed = timedNow(snd.sample);
                break :blk snd.ownNow(strikeCue(home, strike_idx, b.home_k, timed));
            },
            else => snd.sample,
        };
        const late_us: u32 = @intFromFloat(std.math.clamp((now_s - e.at_s) * 1e6, 0.0, 4e9));
        if (e.what == .call_down or e.what == .sing_down or clapped) {
            @atomicStore(u32, &hands_started, hands_started + 1, .monotonic);
            if (late_us > hands_most_us) @atomicStore(u32, &hands_most_us, late_us, .monotonic);
        }
        if (clapped) @atomicStore(u32, &hands_claps, hands_claps + 1, .monotonic);
        queueStarted(.{ .what = e.what, .sample = at, .late_us = late_us });
        if (clapped) queueStarted(.{ .what = .clap, .sample = at, .late_us = late_us });
    }
}

fn queueStarted(s: Started) void {
    const head = @atomicLoad(u32, &started_head, .monotonic);
    const tail = @atomicLoad(u32, &started_tail, .acquire);
    if (head -% tail >= started.len) return;
    started[head % started.len] = s;
    @atomicStore(u32, &started_head, head +% 1, .release);
}

fn audioCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * audio_channels);
    const out: [*]f32 = @ptrCast(@alignCast(stream));
    if (@atomicLoad(i32, &audio_realtime, .monotonic) < 0) {
        // 0 means "this thread": ahead of everything that is not real-time
        var param = std.mem.zeroes(c.struct_sched_param);
        param.sched_priority = 30;
        const granted = c.sched_setscheduler(0, c.SCHED_FIFO, &param) == 0;
        @atomicStore(i32, &audio_realtime, if (granted) 1 else 0, .monotonic);
    }
    const began = plat.now();
    // the songbook open: the world waits, and so does the sound's count, which is the world's clock;
    // what the hands press meanwhile is read and let go, and the speaker is silent
    if (@atomicLoad(u8, &ready_paused, .monotonic) != 0) {
        handsNow();
        for (0..frames * audio_channels) |i| out[i] = 0.0;
        return;
    }
    stampClock(snd.played(), began);
    handsNow();
    var mono: [512]f32 = undefined;
    var done: usize = 0;
    while (done < frames) {
        const n = @min(mono.len, frames - done);
        snd.render(mono[0..n]);
        for (0..n) |i| {
            for (0..audio_channels) |ch| out[(done + i) * audio_channels + ch] = mono[i];
        }
        done += n;
    }
    const us: u32 = @intFromFloat(@min((plat.now() - began) * 1e6, 4e9));
    if (us > @atomicLoad(u32, &audio_slowest_us, .monotonic)) @atomicStore(u32, &audio_slowest_us, us, .monotonic);
}

fn openAudio() c.SDL_AudioDeviceID {
    var want = std.mem.zeroes(c.SDL_AudioSpec);
    want.freq = @intFromFloat(sound_mod.rate);
    want.format = c.AUDIO_F32SYS;
    want.channels = 2;
    want.samples = 128;
    want.callback = &audioCallback;
    var have = std.mem.zeroes(c.SDL_AudioSpec);
    const device = sdl.OpenAudioDevice(null, 0, &want, &have, c.SDL_AUDIO_ALLOW_SAMPLES_CHANGE | c.SDL_AUDIO_ALLOW_CHANNELS_CHANGE);
    if (device == 0) {
        log("sound: none ({s})", .{std.mem.span(sdl.GetError())});
        return 0;
    }
    audio_channels = have.channels;
    @atomicStore(i32, &audio_realtime, -1, .monotonic);
    @atomicStore(u32, &audio_slowest_us, 0, .monotonic);
    log("sound: {s}, {d} Hz, {d} channels, {d}-frame buffer ({d:.2} ms)", .{
        std.mem.span(sdl.GetCurrentAudioDriver()),
        have.freq,
        have.channels,
        have.samples,
        @as(f64, @floatFromInt(have.samples)) / @as(f64, @floatFromInt(have.freq)) * 1000.0,
    });
    sdl.PauseAudioDevice(device, 0);
    return device;
}

/// Mono 16-bit WAV, for listening to (or measuring) a run with no sound card.
const Wav = struct {
    file: *c.FILE,
    frames: u32 = 0,

    fn open(path: [*:0]const u8) ?Wav {
        const file = c.fopen(path, "wb") orelse return null;
        const blank: [44]u8 = @splat(0);
        _ = c.fwrite(&blank, 1, blank.len, file);
        return .{ .file = file };
    }

    fn write(self: *Wav, samples: []const f32) void {
        var block: [800]i16 = undefined;
        for (samples, 0..) |x, i| block[i] = @intFromFloat(std.math.clamp(x, -1.0, 1.0) * 32767.0);
        _ = c.fwrite(&block, 2, samples.len, self.file);
        self.frames += @intCast(samples.len);
    }

    fn close(self: *Wav) void {
        const data: u32 = self.frames * 2;
        var h: [44]u8 = undefined;
        @memcpy(h[0..4], "RIFF");
        std.mem.writeInt(u32, h[4..8], 36 + data, .little);
        @memcpy(h[8..16], "WAVEfmt ");
        std.mem.writeInt(u32, h[16..20], 16, .little);
        std.mem.writeInt(u16, h[20..22], 1, .little);
        std.mem.writeInt(u16, h[22..24], 1, .little);
        std.mem.writeInt(u32, h[24..28], 48000, .little);
        std.mem.writeInt(u32, h[28..32], 96000, .little);
        std.mem.writeInt(u16, h[32..34], 2, .little);
        std.mem.writeInt(u16, h[34..36], 16, .little);
        @memcpy(h[36..40], "data");
        std.mem.writeInt(u32, h[40..44], data, .little);
        _ = c.fseek(self.file, 0, c.SEEK_SET);
        _ = c.fwrite(&h, 1, h.len, self.file);
        _ = c.fclose(self.file);
    }
};

/// The edges the sound thread has passed on, waiting for the steps they fall in.
var edges_waiting: [128]Started = undefined;
var edges_n: usize = 0;
var r1_down = false;
var r2_down = false;
var l1_down = false;
var l2_down = false;
/// The face buttons as the kernel's edges left them: bottom, right, left, top.
var face_down: [4]bool = @splat(false);

/// A scene starts with no presses waiting and nothing held: edges stamped by the last scene's sound
/// clock would sit at the front of the queue and hold back every new one.
fn forgetPresses() void {
    @atomicStore(u32, &started_tail, @atomicLoad(u32, &started_head, .acquire), .release);
    edges_n = 0;
    r1_down = false;
    r2_down = false;
    l1_down = false;
    l2_down = false;
    face_down = @splat(false);
    // the counts are the scene's own
    @atomicStore(u32, &hands_started, 0, .monotonic);
    @atomicStore(u32, &hands_most_us, 0, .monotonic);
    @atomicStore(u32, &hands_claps, 0, .monotonic);
    @atomicStore(u32, &hands_strikes, 0, .monotonic);
    own_hum_at = 0;
}

fn takeEdges() void {
    var tail = @atomicLoad(u32, &started_tail, .monotonic);
    const head = @atomicLoad(u32, &started_head, .acquire);
    while (tail != head) : (tail +%= 1) {
        if (edges_n < edges_waiting.len) {
            edges_waiting[edges_n] = started[tail % started.len];
            edges_n += 1;
        }
    }
    @atomicStore(u32, &started_tail, tail, .release);
}

/// The shoulders for a step, from the edges the sound thread stamped: each edge on the step its
/// sample falls in, and the step's stamp where the first of them fell. A press and its let-go
/// inside one step keep the press for this step and leave the let-go for the next, so no tap is
/// lost. A clap the sound thread found is the clap for the one step its press is on.
fn kernelHands(hands: *Hands, step: u64) void {
    const begin = step * world_mod.samples_per_step;
    const end = begin + world_mod.samples_per_step;
    var stamp: ?u16 = null;
    var changed: [8]bool = @splat(false);
    var clap = false;
    var used: usize = 0;
    while (used < edges_n and edges_waiting[used].sample < end) : (used += 1) {
        const e = edges_waiting[used];
        const which: ?usize = switch (e.what) {
            .call_down, .call_up => 0,
            .sing_down, .sing_up => 1,
            .voice_down, .voice_up => 2,
            .guard_down, .guard_up => 3,
            .jump_down, .jump_up => 4,
            .dodge_down, .dodge_up => 5,
            .strike_down, .strike_up => 6,
            .grab_down, .grab_up => 7,
            .clap => null,
        };
        if (which) |w| {
            if (changed[w]) break;
            changed[w] = true;
        }
        switch (e.what) {
            .call_down => r1_down = true,
            .call_up => r1_down = false,
            .sing_down => r2_down = true,
            .sing_up => r2_down = false,
            .voice_down => l1_down = true,
            .voice_up => l1_down = false,
            .guard_down => l2_down = true,
            .guard_up => l2_down = false,
            .jump_down => face_down[0] = true,
            .jump_up => face_down[0] = false,
            .dodge_down => face_down[1] = true,
            .dodge_up => face_down[1] = false,
            .strike_down => face_down[2] = true,
            .strike_up => face_down[2] = false,
            .grab_down => face_down[3] = true,
            .grab_up => face_down[3] = false,
            .clap => clap = true,
        }
        if (stamp == null) stamp = @intCast(if (e.sample > begin) e.sample - begin else 0);
    }
    if (used > 0) {
        std.mem.copyForwards(Started, edges_waiting[0 .. edges_n - used], edges_waiting[used..edges_n]);
        edges_n -= used;
    }
    hands.buttons &= ~(Hands.call | Hands.sing | Hands.voice | Hands.guard | Hands.clap | Hands.jump | Hands.dodge | Hands.strike | Hands.grab);
    if (face_down[0]) hands.buttons |= Hands.jump;
    if (face_down[1]) hands.buttons |= Hands.dodge;
    if (face_down[2]) hands.buttons |= Hands.strike;
    if (face_down[3]) hands.buttons |= Hands.grab;
    if (r1_down) hands.buttons |= Hands.call;
    if (r2_down) hands.buttons |= Hands.sing;
    if (l1_down) hands.buttons |= Hands.voice;
    if (l2_down) hands.buttons |= Hands.guard;
    if (clap) hands.buttons |= Hands.clap;
    hands.stamp = stamp orelse 0;
}

/// With no shoulders read from the kernel (the laptop), the clap is found a step at a time by the
/// same rule, sixty steps to a second.
var steps_clap = keys_mod.Clap{};
var steps_before: u16 = 0;
fn clapOfSteps(hands: *Hands, step: u64) void {
    const pressed = hands.buttons & ~steps_before;
    steps_before = hands.buttons;
    const at = @as(f64, @floatFromInt(step)) / @as(f64, @floatFromInt(world_mod.steps_per_second));
    var clapped = false;
    if (pressed & Hands.call != 0 and steps_clap.press(false, at)) clapped = true;
    if (pressed & Hands.voice != 0 and steps_clap.press(true, at)) clapped = true;
    if (clapped) hands.buttons |= Hands.clap;
}

const Pad = struct {
    handle: ?*c.SDL_GameController = null,
    faces: plat.Faces = .{},

    fn open() Pad {
        var pad = Pad{};
        const count = sdl.NumJoysticks();
        var i: c_int = 0;
        while (i < count) : (i += 1) {
            if (sdl.IsGameController(i) == c.SDL_FALSE) continue;
            pad.handle = sdl.GameControllerOpen(i);
            if (pad.handle) |handle| {
                pad.faces = plat.Faces.find(handle);
                var said: [128]u8 = undefined;
                log("controls: {s}; {s}", .{ std.mem.span(sdl.GameControllerName(handle)), pad.faces.describe(&said) });
                if (presses.fd < 0) {
                    if (sdl.GameControllerGetJoystick(handle)) |joystick| {
                        if (sdl.JoystickName(joystick)) |name| presses = presses_mod.Presses.open(std.mem.span(name));
                    }
                }
                if (presses.fd >= 0) {
                    log("controls: the shoulders and face buttons read from the kernel on the sound's own thread (/dev/input/event{d}); the clap and the timed strike found there", .{presses.event});
                } else {
                    log("controls: the shoulders and face buttons read with the rest of the hands, a step at a time; the clap found a step at a time", .{});
                }
                break;
            }
        }
        if (pad.handle == null) log("controls: no game controller found ({d} joysticks)", .{count});
        return pad;
    }

    fn stick(handle: *c.SDL_GameController, which: c_int) i8 {
        const raw: i32 = sdl.GameControllerGetAxis(handle, which);
        return @intCast(std.math.clamp(@divTrunc(raw, 258), -127, 127));
    }

    fn read(self: *const Pad) Hands {
        const handle = self.handle orelse return .{};
        var h = Hands{
            .lx = stick(handle, c.SDL_CONTROLLER_AXIS_LEFTX),
            .ly = stick(handle, c.SDL_CONTROLLER_AXIS_LEFTY),
            .rx = stick(handle, c.SDL_CONTROLLER_AXIS_RIGHTX),
            .ry = stick(handle, c.SDL_CONTROLLER_AXIS_RIGHTY),
        };
        const map = [_]struct { sdl_button: c_int, bit: u16 }{
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER, .bit = Hands.call },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER, .bit = Hands.voice },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_BACK, .bit = Hands.select },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_START, .bit = Hands.start },
        };
        for (map) |entry| {
            if (sdl.GameControllerGetButton(handle, entry.sdl_button) != 0) h.buttons |= entry.bit;
        }
        // face buttons by where they are (SPEC.md, 10), found by the kernel's codes (plat.Faces)
        const faces = [_]struct { face: plat.Face, bit: u16 }{
            .{ .face = .bottom, .bit = Hands.jump },
            .{ .face = .right, .bit = Hands.dodge },
            .{ .face = .left, .bit = Hands.strike },
            .{ .face = .top, .bit = Hands.grab },
        };
        for (faces) |entry| {
            if (self.faces.down(handle, entry.face)) h.buttons |= entry.bit;
        }
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 16000) h.buttons |= Hands.sing;
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 16000) h.buttons |= Hands.guard;
        return h;
    }
};

fn noteColour(hz: f32) [3]f32 {
    return colour.ofNote(world_mod.garden_hz, hz);
}

const col8 = colour.col8;

const per_thing = 12;
const bone = colour.bone;
const teal = colour.teal;

/// What the first evening adds to the picture: Drip, the ripple that shows which way its answer
/// came from, and the figure between its voice and Hum's (Piece 5: modularized to draw/drip_lines.zig).
fn eveningLines(w: *const World, out: []lines.Inst) usize {
    return drip_lines.dripLines(w, out);
}

/// The dark's things: each a stalk, a ring for a head and three spokes. Its body number is its
/// place in the world's list plus one; body nought is always fully lit.
fn thingLines(w: *const World, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.things[0..w.thing_count], 0..) |thing, index| {
        const body: f32 = @floatFromInt(index + 1);
        const tint = col8(noteColour(thing.hz), 1.0);
        const r = 0.5 + 60.0 / thing.hz * 2.0; // lower notes have bigger heads
        const top = thing.tall;
        out[n] = .{ .a = .{ thing.x, 0.0, thing.z }, .b = .{ thing.x, top, thing.z }, .half_width = 1.3, .body = body, .col = tint };
        n += 1;
        for (0..8) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
            out[n] = .{
                .a = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z },
                .b = .{ thing.x + r * @cos(a1), top + r * @sin(a1), thing.z },
                .half_width = 1.4,
                .body = body,
                .col = tint,
            };
            n += 1;
        }
        for (0..3) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 3.0) + 0.5;
            out[n] = .{ .a = .{ thing.x, top, thing.z }, .b = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z }, .half_width = 1.1, .body = body, .col = tint };
            n += 1;
        }
    }
    return n;
}

/// What changes every frame: the rings on the ground, the band of light a call sends up each
/// stalk, and Hum.
fn movingLines(w: *const World, cam_stand: f32, eye: m.V3, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.rings) |ring| {
        if (!ring.live) continue;
        if (ring.wave_more > 0.0) continue; // strikes do not draw call rings
        const reach = ring.age * world_mod.dt * world_mod.sound_speed;
        const fade = std.math.clamp(1.0 - reach / w.ring_reach, 0.0, 1.0);
        const tint = col8(if (ring.own) bone else teal, 0.85 * fade * fade);
        const is_air = ring.y > 0.0;
        const ring_y = if (is_air) ring.ground + ring.y + 0.2 else 0.05;
        const hw: f32 = if (is_air) -1.5 else 1.5;
        const parts = 64;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ ring.x + reach * @cos(a0), ring_y, ring.z + reach * @sin(a0) },
                .b = .{ ring.x + reach * @cos(a1), ring_y, ring.z + reach * @sin(a1) },
                .half_width = hw,
                .body = 0.0,
                .col = tint,
            };
            n += 1;
        }
        // the same call, climbing: where its sphere cuts each stalk
        for (w.towers[0..w.tower_count], 0..) |tower, t| {
            const dx = tower.x - ring.x;
            const dz = tower.z - ring.z;
            const flat2 = dx * dx + dz * dz;
            if (flat2 >= reach * reach) continue;
            const high = @sqrt(reach * reach - flat2);
            if (high > tower.tall) continue;
            const ex = tower.x - eye[0];
            const ez = tower.z - eye[2];
            if (ex * ex + ez * ez > aster_lines.mid_within * aster_lines.mid_within) continue;
            if (n + 8 > out.len) break;
            const at = aster_lines.mastAt(t, high);
            const band = col8(bone, 0.95 * @max(fade, 0.35));
            for (0..8) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
                out[n] = .{
                    .a = .{ at[0] + 1.9 * @cos(a0), high, at[2] + 1.9 * @sin(a0) },
                    .b = .{ at[0] + 1.9 * @cos(a1), high, at[2] + 1.9 * @sin(a1) },
                    .half_width = 1.6,
                    .body = 0.0,
                    .col = band,
                };
                n += 1;
            }
        }
    }

    // on moss Hum is dim: moss swallows light as it swallows sound (spec/shape.md)
    const hum_tint = col8(bone, if (w.cover == .moss) 0.55 else 1.0);
    const on_page = (w.view == .place and cam_stand < 0.5);
    if (on_page and !w.singing and w.hum_light > 0.01) {
        // silent on the page, Hum answers in light what reaches it: Drip's ticks, a press: a
        // second ring round it, in Drip's colour, as bright as Hum's own light
        const r = 1.05 + 0.25 * w.hum_light;
        for (0..14) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 14.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 14.0);
            out[n] = .{ .a = .{ w.hum_x + r * @cos(a0), 0.05, w.hum_z + r * @sin(a0) }, .b = .{ w.hum_x + r * @cos(a1), 0.05, w.hum_z + r * @sin(a1) }, .half_width = 1.3, .body = 0.0, .col = col8(teal, 0.8 * w.hum_light) };
            n += 1;
        }
    }
    if (on_page) {
        // on the page Hum is a mark like any other: a small ring, and a tick for where it faces
        for (0..10) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
            out[n] = .{
                .a = .{ w.hum_x + 0.9 * @cos(a0), 0.05, w.hum_z + 0.9 * @sin(a0) },
                .b = .{ w.hum_x + 0.9 * @cos(a1), 0.05, w.hum_z + 0.9 * @sin(a1) },
                .half_width = 2.2,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        out[n] = .{
            .a = .{ w.hum_x, 0.05, w.hum_z },
            .b = .{ w.hum_x + 1.6 * @sin(w.hum_face), 0.05, w.hum_z - 1.6 * @cos(w.hum_face) },
            .half_width = 1.6,
            .body = 0.0,
            .col = hum_tint,
        };
        n += 1;
    } else if (w.view == .page) {
        // seen from above: a small bone-white shape whose outline swells while it sings
        const size: f32 = if (w.singing) 0.75 else 0.5;
        for (0..10) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
            out[n] = .{
                .a = .{ w.hum_x + size * @cos(a0), 0.5 + size * @sin(a0), w.hum_z },
                .b = .{ w.hum_x + size * @cos(a1), 0.5 + size * @sin(a1), w.hum_z },
                .half_width = 1.8,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        out[n] = .{
            .a = .{ w.hum_x, 0.5, w.hum_z },
            .b = .{ w.hum_x + 0.9 * @sin(w.hum_face), 0.5, w.hum_z - 0.9 * @cos(w.hum_face) },
            .half_width = 1.2,
            .body = 0.0,
            .col = hum_tint,
        };
        n += 1;
    } else {
        // stood beside: one metre of bone-white, hatched so it reads as the one solid thing. Singing
        // after the lock it swells a little more each bar. Its outline is hum_figure's, which its
        // black shape is made from too.
        const oval = hum_figure.Oval.of(w, eye);
        const rim = oval.outline();
        for (rim, 0..) |a, k| {
            out[n] = .{ .a = a, .b = rim[(k + 1) % rim.len], .half_width = 1.9, .body = 0.0, .col = hum_tint };
            n += 1;
        }
        // home, always shown: a ring of light at Hum's feet in home's colour, faint while Hum is
        // silent, full while it sings, flaring as it calls (the page draws Hum as a ring too)
        {
            const home_col = noteColour(w.home_hz);
            const glow: f32 = if (w.singing) 0.9 else 0.22 + 0.6 * w.hum_light;
            const r: f32 = 0.9;
            for (0..20) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 20.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 20.0);
                out[n] = .{ .a = .{ w.hum_x + r * @cos(a0), 0.06, w.hum_z + r * @sin(a0) }, .b = .{ w.hum_x + r * @cos(a1), 0.06, w.hum_z + r * @sin(a1) }, .half_width = 1.5, .body = 0.0, .col = col8(home_col, std.math.clamp(glow, 0.0, 1.0)) };
                n += 1;
            }
        }
        // in the air, a faint ring on the ground under it, smaller the higher it is, so its height
        // can be judged
        if (w.airborne) {
            const r = 0.55 / (1.0 + w.hum_y * 0.15);
            for (0..12) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 12.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 12.0);
                out[n] = .{ .a = .{ w.hum_x + r * @cos(a0), 0.05, w.hum_z + r * @sin(a0) }, .b = .{ w.hum_x + r * @cos(a1), 0.05, w.hum_z + r * @sin(a1) }, .half_width = 1.2, .body = 0.0, .col = col8(bone, 0.35) };
                n += 1;
            }
        }
        // Hum's own light: it flares when Hum calls and holds while it sings. Its breath is its
        // lines: one for each home it holds, lit from the bottom as far as it has; winded, they
        // pant
        const most: usize = w.breath_most;
        const pant: f32 = if (w.winded) 0.6 + 0.4 * @abs(@sin(@as(f32, @floatFromInt(w.step)) * (std.math.pi / 40.0))) else 1.0;
        for (0..most) |k| {
            const f = (@as(f32, @floatFromInt(k)) + 0.5) / @as(f32, @floatFromInt(most)) * 1.7 - 0.85;
            const lit = std.math.clamp(w.breath - @as(f32, @floatFromInt(k)), 0.0, 1.0);
            const fill = col8(bone, (0.40 + 0.60 * w.hum_light) * (0.18 + 0.82 * lit) * pant);
            const breath = oval.across(f);
            out[n] = .{ .a = breath[0], .b = breath[1], .half_width = 2.2, .body = 0.0, .col = fill };
            n += 1;
        }
    }
    return n;
}

/// Part of a circle in front of Hum lying on the ground, sweeping out as the strike lands (GameguyPage exact groundArc)
pub fn strikeLines(w: *const World, out: []lines.Inst) usize {
    if (w.strike_anim <= 0.0) return 0;
    var n: usize = 0;
    const reach = world_mod.knots.strike_reach * (1.0 - 0.45 * w.strike_anim);
    const arc_parts = 16;
    const bone3 = [3]f32{ 0.88, 0.84, 0.78 };
    const home_hue = colour.ofNote(world_mod.garden_hz, w.home_hz);
    const arc_col = [3]f32{
        bone3[0] * 0.5 + home_hue[0] * 0.5,
        bone3[1] * 0.5 + home_hue[1] * 0.5,
        bone3[2] * 0.5 + home_hue[2] * 0.5,
    };
    const sweep_col = col8(arc_col, w.strike_anim);
    const arc_y = w.hum_ground + w.hum_y + 0.15;
    for (0..arc_parts) |k| {
        if (n >= out.len) break;
        const a0 = w.hum_face - 1.1 + @as(f32, @floatFromInt(k)) * (2.2 / @as(f32, arc_parts));
        const a1 = w.hum_face - 1.1 + @as(f32, @floatFromInt(k + 1)) * (2.2 / @as(f32, arc_parts));
        out[n] = .{
            .a = .{ w.hum_x + reach * @sin(a0), arc_y, w.hum_z - reach * @cos(a0) },
            .b = .{ w.hum_x + reach * @sin(a1), arc_y, w.hum_z - reach * @cos(a1) },
            .half_width = -3.5 * w.strike_anim,
            .body = 0.0,
            .col = sweep_col,
        };
        n += 1;
    }
    return n;
}

const backlight_path = "/sys/class/backlight/backlight/brightness";

/// The backlight is the sun: nearly off in the dark, up with whatever is shining.
const Backlight = struct {
    level: f32 = world_mod.first_dark_backlight,
    written: i32 = -1,

    fn follow(self: *Backlight, light: f32) void {
        const want = world_mod.first_dark_backlight + 150.0 * std.math.clamp(light, 0.0, 1.0);
        self.level += (want - self.level) * 0.12;
        const now: i32 = @intFromFloat(self.level);
        if (now == self.written) return;
        const file = c.fopen(backlight_path, "w") orelse return;
        var text: [8]u8 = undefined;
        const s = std.mem.printSentinel(&text, "{d}", .{now}, 0) catch return;
        _ = c.fputs(s.ptr, file);
        _ = c.fclose(file);
        self.written = now;
    }
};

// ------------------------------------------------------------------ the ground remembers
//
// One picture of the light that has been left on the ground (spec/size.md): wherever something
// sounds, it leaves its light beneath it in its note's colour. This is a first proof: one picture
// for the whole field, 62 cm to a dot, where the specification asks for one for each piece of
// land at 25 cm. It is kept in a file between sessions, so the ground still holds yesterday.
const ground_size = 2048;
const ground_from = [2]f32{ -760.0, -585.0 };
const ground_span: f32 = 1520.0;
const ground_block = 64;
const ground_blocks = ground_size / ground_block;
const ground_file = "keep/garden-ground.rgb";
const ground_most: f32 = 150.0;
var ground: [ground_size * ground_size * 3]u8 = undefined;
var ground_dirty: [ground_blocks * ground_blocks]bool = @splat(false);
var ground_cursor: usize = 0;

/// Leave light on the ground round a point: `amount` of `rgb` at the middle, falling away.
fn leaveLight(x: f32, z: f32, radius: f32, rgb: [3]f32, amount: f32) void {
    const scale = @as(f32, ground_size) / ground_span;
    const cx = (x - ground_from[0]) * scale;
    const cz = (z - ground_from[1]) * scale;
    const r = @max(radius * scale, 1.0);
    const x0: i32 = @intFromFloat(@floor(cx - r * 1.6));
    const x1: i32 = @intFromFloat(@ceil(cx + r * 1.6));
    const z0: i32 = @intFromFloat(@floor(cz - r * 1.6));
    const z1: i32 = @intFromFloat(@ceil(cz + r * 1.6));
    var iz = @max(z0, 0);
    while (iz <= @min(z1, ground_size - 1)) : (iz += 1) {
        var ix = @max(x0, 0);
        while (ix <= @min(x1, ground_size - 1)) : (ix += 1) {
            const dx = (@as(f32, @floatFromInt(ix)) + 0.5 - cx) / r;
            const dz = (@as(f32, @floatFromInt(iz)) + 0.5 - cz) / r;
            // a soft round edge with no exponential in it: this runs for every dot of every light
            const edge = 1.0 - (dx * dx + dz * dz) * (1.0 / 2.56);
            if (edge <= 0.0) continue;
            const fall = edge * edge;
            const at: usize = @intCast((iz * ground_size + ix) * 3);
            for (0..3) |k| {
                const more = amount * fall * rgb[k] * 255.0;
                const now = @as(f32, @floatFromInt(ground[at + k])) + more;
                // kept light never passes this: what the ground remembers is never brighter than
                // half (spec/texture.md)
                ground[at + k] = @intFromFloat(@min(now, ground_most));
            }
            ground_dirty[@intCast(@divTrunc(iz, ground_block) * ground_blocks + @divTrunc(ix, ground_block))] = true;
        }
    }
}

/// Send the GPU a few of the squares that have changed: never more than three a frame.
fn sendGround() void {
    var sent: u32 = 0;
    var looked: usize = 0;
    while (looked < ground_dirty.len and sent < 3) : (looked += 1) {
        const i = ground_cursor;
        ground_cursor = (ground_cursor + 1) % ground_dirty.len;
        if (!ground_dirty[i]) continue;
        ground_dirty[i] = false;
        const bx: i32 = @intCast(i % ground_blocks);
        const bz: i32 = @intCast(i / ground_blocks);
        renderer.updateGround(bx * ground_block, bz * ground_block, ground_block, ground_block, &ground);
        sent += 1;
        ground_cursor = i; // so that a square made dirty again at once is not a whole lap away
    }
}

fn loadGround() bool {
    const file = c.fopen(ground_file, "rb") orelse return false;
    defer _ = c.fclose(file);
    return c.fread(&ground, 1, ground.len, file) == ground.len;
}

fn saveGround() void {
    _ = c.mkdir("keep", 0o755);
    const file = c.fopen(ground_file ++ ".new", "wb") orelse return;
    const wrote = c.fwrite(&ground, 1, ground.len, file);
    _ = c.fclose(file);
    if (wrote == ground.len) _ = c.rename(ground_file ++ ".new", ground_file);
}

/// What sounded this step, and so what light it leaves: Hum where it walks, calls and hums, and
/// every bell that is ringing, on the ground beneath it.
fn groundStep(w: *const World, called: bool) void {
    const home = colour.ofNote(world_mod.garden_hz, world_mod.garden_hz);
    if (called) leaveLight(w.hum_x, w.hum_z, 4.5, home, 0.55);
    if (w.singing) leaveLight(w.hum_x, w.hum_z, 1.6, home, 0.0006);
    if (w.still == 0) leaveLight(w.hum_x, w.hum_z, 1.2, .{ 0.886, 0.839, 0.784 }, 0.016);
    // each ringing bell, one step in sixty-four, taken in turn: a crown of them ringing at once
    // must not cost a frame
    // the sky's rungs are last in the list, and their light is the day's, not left on the ground
    const land_end = if (w.rung_first == world_mod.no_thing) w.thing_count else w.rung_first;
    for (w.things[0..land_end], 0..) |thing, i| {
        if (!thing.sounds or thing.loud < 0.06 or (i + w.step) % 64 != 0) continue;
        // light falls wider the higher the thing that gives it
        leaveLight(thing.x, thing.z, 0.5 + 0.08 * thing.y + thing.tall, noteColour(thing.hz), thing.loud * 0.04);
    }
}

/// The dark: the first toy of a scene, kept for its long scripted take. The evening: the first
/// evening from its first second. The asters: the same place at dawn, already standing.
pub const Scene = enum { dark, evening, asters };

pub const Options = struct {
    scene: Scene = .dark,
    /// Draw each frame. A check of the world alone (a take played back, a save opened) needs no
    /// picture, and is twenty times quicker without one.
    picture: bool = true,
    /// To measure what a part of the picture costs: draw without the trail, without the ground's
    /// light, or with half the land's lines.
    without_trail: bool = false,
    /// Draw every page of the songbook into this folder and stop, to look at them.
    songbook_dump: ?[*:0]const u8 = null,
    without_ground: bool = false,
    half_land: bool = false,
    headless: bool = false,
    frames: u32 = 0,
    dump: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav: ?[*:0]const u8 = null,
    /// Real sound and the real clock, but the scripted hands: for measuring on the handheld.
    bot: bool = false,
    /// The promise a person was sent here to feel, from the room's walk.
    promise: ?[]const u8 = null,
    /// A take to play back in place of anyone's hands.
    replay: ?[*:0]const u8 = null,
    /// A save to open the world from (keep/save.zig): the scene goes on from where it was.
    load: ?[*:0]const u8 = null,
    /// A walk from the room: the person's own memory is left alone (no going on from a cut-off
    /// take, no dawns or ground kept), and the take is written into results/walks/ under its name.
    walk: ?[]const u8 = null,
    /// Keep the world at each of the scripted player's "start:" marks, into this folder, for the
    /// room's walks.
    walk_starts: ?[*:0]const u8 = null,
    /// Keep the take and the dawns' saves on the card even when the hands are scripted, as a
    /// person's session does: for the test that kills the game and starts it again.
    keep: bool = false,
    /// Start as a person would after a flat battery, go on from the take that was cut off, say
    /// where that is, and stop: for the same test.
    resume_only: bool = false,
    /// Play a take through from its first step with nothing drawn and nothing heard, say where it
    /// ends, and stop.
    check_take: ?[*:0]const u8 = null,
    /// The try-out of design/the-game.md: L1 and L2 step the chord among the lift, home and the lean
    /// wherever Hum is, and Hum's body follows the chord (world.zig, chords_tryout).
    chords: bool = false,
};

/// The take being written as it is played, and its dawns.
var card = card_mod.Card{};
var dawns_kept: u32 = 0;

/// What a person did on a visit from the room's walk.
pub const Visit = struct {
    /// Whether the world has a witness for the promise at all.
    witnessed: bool = false,
    met: bool = false,
    stayed_s: f32 = 0.0,
    calls: u32 = 0,
    seconds: f32 = 0.0,
};
pub var last_visit: Visit = .{};

var world: World = undefined;
var words: Type = undefined;
var renderer: lines.Renderer = undefined;
var renderer_ready = false;
var pixels: []u8 = &.{};
var static_lines: [42_000]lines.Inst = undefined;
/// Each body's share of its own light, by the total length of the lines it is drawn with.
var spread: [lines.max_bodies]f32 = @splat(1.0);
var body_len: [lines.max_bodies]f32 = @splat(0.0);
/// A thing whose lines add up to no more than this carries its whole light in each.
const spread_ref: f32 = 24.0;

/// A thing's own light is its loudness spread over all its lines (spec/texture.md).
fn spreadLight(insts: []const lines.Inst) void {
    @memset(&body_len, 0.0);
    for (insts) |inst| {
        const body: usize = @intFromFloat(inst.body);
        if (body < aster_lines.thing_body or body >= lines.max_bodies) continue;
        const dx = inst.b[0] - inst.a[0];
        const dy = inst.b[1] - inst.a[1];
        const dz = inst.b[2] - inst.a[2];
        body_len[body] += @sqrt(dx * dx + dy * dy + dz * dz);
    }
    for (&spread, body_len) |*s, len| s.* = if (len <= spread_ref) 1.0 else @max(0.06, spread_ref / len);
}

fn byte(v: f32) u8 {
    return @intFromFloat(std.math.clamp(v, 0.0, 1.0) * 255.0);
}

fn shine(sounding: f32, lit: f32, share: f32, gives: f32) lines.Shine {
    return .{ .sounding = byte(sounding), .lit = byte(lit), .spread = byte(share), .gives = byte(gives) };
}
/// The land's black shapes: twenty thousand triangles, which the purple draws in 2.2 ms.
var static_occ: [60_000][3]f32 = undefined;
/// And those of what moves, rebuilt each frame.
var moving_occ: [1_500][3]f32 = undefined;
/// Beside each corner of the land's black shapes, what it is to the chord (draw/black.zig).
var static_occ_tags: [60_000]lines.OccTag = @splat(lines.no_tag);
var moving: [16_000]lines.Inst = undefined;
/// A person's hands, as they play: room for an hour of a thumb that never rests.
var take_bytes: [take.header_size + 216_000 * take.change_size]u8 = undefined;

var save_bytes: [save.size]u8 = undefined;

/// Keep the world as it is now on the card: keep/dawns/SCENE-NUMBER.save, the first number not
/// used. Every dawn's save is kept (spec/size.md, "Nothing is forgotten").
fn keepSave(scene: Scene) void {
    _ = c.mkdir("keep", 0o755);
    _ = c.mkdir("keep/dawns", 0o755);
    var path: [96]u8 = undefined;
    // named after the take that is being written, so a take and its dawns are found together
    dawns_kept += 1;
    const p = card_mod.dawnPath(&path, sceneOfTake(scene), card.number, dawns_kept) orelse return;
    const n = save.write(&world, &save_bytes);
    // the card's own thread writes it, after the hands that led to it
    card.keepSave(save_bytes[0..n], p);
    log("the dawn: the world kept as {s}, {d} bytes, at step {d}", .{ p, n, world.step });
}

/// The world kept at a walk's start, for the room: DIR/NAME.save.
fn keepStart(dir: [*:0]const u8, name: []const u8) void {
    _ = c.mkdir(dir, 0o755);
    var path: [512]u8 = undefined;
    const p = std.mem.printSentinel(&path, "{s}/{s}.save", .{ std.mem.span(dir), name }, 0) catch return;
    const n = save.write(&world, &save_bytes);
    const file = c.fopen(p.ptr, "wb") orelse return;
    _ = c.fwrite(&save_bytes, 1, n, file);
    _ = c.fclose(file);
    log("start {s} at step {d}: the world kept as {s}, {d} bytes; at rest {s}", .{ name, world.step, p, n, if (world.hum_vx * world.hum_vx + world.hum_vz * world.hum_vz < 0.01 and !world.airborne) "yes" else "no" });
}

/// Open the world from a save. False, with the reason in the log, if it can't be.
fn openSave(path: [*:0]const u8) bool {
    const file = c.fopen(path, "rb") orelse {
        log("no save at {s}", .{std.mem.span(path)});
        return false;
    };
    const n = c.fread(&save_bytes, 1, save_bytes.len, file);
    _ = c.fclose(file);
    save.read(save_bytes[0..n], &world) catch |why| {
        log("that save can't be opened ({s}): {s}", .{ @errorName(why), std.mem.span(path) });
        return false;
    };
    log("opened from a save at step {d}: {s}", .{ world.step, std.mem.span(path) });
    return true;
}

fn sceneOfTake(scene: Scene) take.Scene {
    return switch (scene) {
        .dark => .dark,
        .evening => .evening,
        .asters => .asters,
    };
}

/// Play a take on from wherever the world is now, with nothing drawn and nothing heard: what a
/// flat battery cut off, or a take being checked. The ground's light is painted as it goes.
fn playOn(player: *take.Player, scene: Scene) void {
    var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
    while (!player.done(world.step)) {
        const calls_before = world.calls;
        _ = world.stepOnce(player.hands(world.step), &cues);
        if (scene != .dark) groundStep(&world, world.calls != calls_before);
    }
}

/// How steady the picture's travel is while Hum walks: frame to frame, how far the ground under the
/// eye moved as shown and as it would have by whole steps. A steady walk moves the same each frame.
const Steady = struct {
    n: u32 = 0,
    sum: f64 = 0.0,
    shown_sq: f64 = 0.0,
    shown_sum: f64 = 0.0,
    stepped_sq: f64 = 0.0,
    stepped_sum: f64 = 0.0,

    fn add(self: *Steady, shown: [2]f32, stepped: [2]f32, gap_ms: f64) void {
        const s: f64 = @sqrt(shown[0] * shown[0] + shown[1] * shown[1]);
        const w: f64 = @sqrt(stepped[0] * stepped[0] + stepped[1] * stepped[1]);
        // only a frame shown on time, while Hum walks at a steady pace
        if (gap_ms < 14.0 or gap_ms > 20.0 or s < 0.05 or s > 0.3) return;
        self.n += 1;
        self.sum += s;
        self.shown_sum += s;
        self.shown_sq += s * s;
        self.stepped_sum += w;
        self.stepped_sq += w * w;
    }

    fn mean(self: *const Steady) f64 {
        return self.sum / @as(f64, @floatFromInt(@max(self.n, 1)));
    }

    fn spread(self: *const Steady, which: enum { shown, stepped }) f64 {
        const n: f64 = @floatFromInt(@max(self.n, 1));
        const s = if (which == .shown) self.shown_sum else self.stepped_sum;
        const q = if (which == .shown) self.shown_sq else self.stepped_sq;
        const m_ = s / n;
        return @sqrt(@max(q / n - m_ * m_, 0.0));
    }
};

/// Where a player was held up in the first evening (the plan: the game teaches itself): read from
/// any session's log, a fresh player's above all.
fn logTeaching(w: *const World) void {
    const s = struct {
        fn at(step: u64) f64 {
            return if (step == world_mod.never) -1.0 else @as(f64, @floatFromInt(step)) / 60.0;
        }
    };
    log("teaching: beside Drip first at {d:.0} s, the view leaned in at {d:.0} s, first hummed beside it at {d:.0} s, Drip showed its breath {d} times; breaths tried {d}, on the tick {d}, locked at {d:.0} s; presses with no verb yet {d}; knocked before the place stood {d} (-1 s: never)", .{ s.at(w.beside_first_at), s.at(w.leaned_first_at), s.at(w.hummed_beside_at), w.drip_shows, w.breaths_tried, w.breaths, s.at(w.locked_at), w.dark_presses, w.knocked_in_dark });
    var buf: [256]u8 = undefined;
    var len: usize = 0;
    for (w.breath_offsets[0..@min(w.breaths_tried, w.breath_offsets.len)]) |off| {
        const piece = std.fmt.bufPrint(buf[len..], " {d}", .{off}) catch break;
        len += piece.len;
    }
    log("teaching: each breath let go from the tick, in ms (after it above nought):{s}", .{buf[0..len]});
    log("teaching: first jump at {d:.0} s, first sprint at {d:.0} s, the wheel first opened at {d:.0} s, the place stood at {d:.0} s", .{ s.at(w.first_jump_at), s.at(w.first_sprint_at), s.at(w.first_wheel_at), s.at(w.stand_from) });
}

/// The page the songbook opens on when the moment asks for none: the last thing learned.
fn lastLearned(w: *const World) songbook.Page {
    var last: songbook.Page = .call;
    for (songbook.pages) |p| {
        if (songbook.learned(w, p)) last = p;
    }
    return last;
}

/// The next page to turn to, forward or back: the pages learned, and the one the moment asks for.
fn nextPage(w: *const World, from: songbook.Page, forward: bool) songbook.Page {
    const n = songbook.pages.len;
    var i: usize = @intFromEnum(from);
    for (0..n) |_| {
        i = if (forward) (i + 1) % n else (i + n - 1) % n;
        const p: songbook.Page = @enumFromInt(i);
        if (songbook.learned(w, p) or songbook.needed(w) == p) return p;
    }
    return from;
}

/// Every page of the songbook drawn into `dir`, whole and half drawn, to be looked at.
fn dumpSongbook(dir: [*:0]const u8) void {
    for (songbook.pages) |p| {
        for ([2]f32{ 1.0, 0.55 }) |whole| {
            gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
            gl.Viewport(0, 0, renderer.fb_w, renderer.fb_h);
            gl.ClearColor(0.0, 0.0, 0.0, 1.0);
            gl.Clear(c.GL_COLOR_BUFFER_BIT);
            songbook.draw(&sketch, p, 1.3, whole);
            sketch.flush();
            dumpNamed(dir, "songbook-{s}-{s}", .{ @tagName(p), if (whole >= 1.0) "learned" else "asked" });
        }
    }
}

/// The keyboard as a handheld, for playing on a laptop: the left stick on W A S D (Ctrl held, half
/// way), the right stick on the arrows; R1 E, R2 R, L1 Q, L2 Z; the bottom face Space, the right face
/// Shift, the left face F, the top face G; Start Tab, Select Backspace; Esc held is Select and Start
/// together, which leaves. A pad's own hands come through as they are.
fn withKeys(pad_hands: Hands) Hands {
    var numkeys: c_int = 0;
    const raw = sdl.GetKeyboardState(&numkeys) orelse return pad_hands;
    const keys = raw[0..@intCast(numkeys)];
    const down = struct {
        fn f(k: []const u8, code: c_int) bool {
            const i: usize = @intCast(code);
            return i < k.len and k[i] != 0;
        }
    }.f;
    var h = pad_hands;
    const ax = @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_D)))) - @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_A))));
    const az = @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_S)))) - @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_W))));
    if (ax != 0.0 or az != 0.0) {
        const len = @sqrt(ax * ax + az * az);
        const push: f32 = if (down(keys, c.SDL_SCANCODE_LCTRL) or down(keys, c.SDL_SCANCODE_RCTRL)) 63.0 else 127.0;
        h.lx = @intFromFloat(ax / len * push);
        h.ly = @intFromFloat(az / len * push);
    }
    const lx = @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_RIGHT)))) - @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_LEFT))));
    const lz = @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_DOWN)))) - @as(f32, @floatFromInt(@intFromBool(down(keys, c.SDL_SCANCODE_UP))));
    if (lx != 0.0) h.rx = @intFromFloat(lx * 110.0);
    if (lz != 0.0) h.ry = @intFromFloat(lz * 110.0);
    const map = [_]struct { code: c_int, bit: u16 }{
        .{ .code = c.SDL_SCANCODE_E, .bit = Hands.call },
        .{ .code = c.SDL_SCANCODE_R, .bit = Hands.sing },
        .{ .code = c.SDL_SCANCODE_Q, .bit = Hands.voice },
        .{ .code = c.SDL_SCANCODE_Z, .bit = Hands.guard },
        .{ .code = c.SDL_SCANCODE_SPACE, .bit = Hands.jump },
        .{ .code = c.SDL_SCANCODE_LSHIFT, .bit = Hands.dodge },
        .{ .code = c.SDL_SCANCODE_RSHIFT, .bit = Hands.dodge },
        .{ .code = c.SDL_SCANCODE_F, .bit = Hands.strike },
        .{ .code = c.SDL_SCANCODE_G, .bit = Hands.grab },
        .{ .code = c.SDL_SCANCODE_TAB, .bit = Hands.start },
        .{ .code = c.SDL_SCANCODE_BACKSPACE, .bit = Hands.select },
        .{ .code = c.SDL_SCANCODE_ESCAPE, .bit = Hands.select | Hands.start },
    };
    for (map) |m_| {
        if (down(keys, m_.code)) h.buttons |= m_.bit;
    }
    return h;
}

fn flatGround(x: f32, z: f32) f32 {
    _ = x;
    _ = z;
    return 0.0;
}

fn loadTake(path: [*:0]const u8) ?take.Player {
    const file = c.fopen(path, "rb") orelse return null;
    defer _ = c.fclose(file);
    const n = c.fread(&take_bytes, 1, take_bytes.len, file);
    return take.Player.open(take_bytes[0..n]);
}

fn dumpNamed(dir: [*:0]const u8, comptime fmt: []const u8, args: anytype) void {
    renderer.readFrame(pixels);
    var path: [512]u8 = undefined;
    var name: [128]u8 = undefined;
    const leaf = std.fmt.bufPrint(&name, fmt, args) catch return;
    if (std.mem.printSentinel(&path, "{s}/{s}.png", .{ std.mem.span(dir), leaf }, 0)) |text| {
        _ = png.writeFromGl(text.ptr, @intCast(renderer.fb_w), @intCast(renderer.fb_h), pixels);
    } else |_| {}
    // A frame a promise names is measured as it is kept (spec/texture.md, what makes a frame
    // beautiful): how much of it is black, and how much is brighter than half.
    if (std.mem.startsWith(u8, leaf, "promise-")) {
        var black: usize = 0;
        var bright: usize = 0;
        const dots = pixels.len / 4;
        for (0..dots) |i| {
            const r: u32 = pixels[i * 4];
            const g: u32 = pixels[i * 4 + 1];
            const b: u32 = pixels[i * 4 + 2];
            if (@max(r, @max(g, b)) < 16) black += 1;
            if (r * 2126 + g * 7152 + b * 722 > 128 * 10000) bright += 1;
        }
        const n: f64 = @floatFromInt(@max(dots, 1));
        log("fact beauty.{s}.black {d:.4}", .{ leaf["promise-".len..], @as(f64, @floatFromInt(black)) / n });
        log("fact beauty.{s}.bright {d:.4}", .{ leaf["promise-".len..], @as(f64, @floatFromInt(bright)) / n });
    }
}

pub fn run(window: plat.Window, options: Options) bool {
    if (!renderer_ready) {
        if (!renderer.init(window.width, window.height)) return false;
        if (!words.init(window.width, window.height)) return false;
        if (!sketch.init(window.width, window.height)) return false;
        if (options.songbook_dump) |dir| {
            const n0: usize = @intCast(window.width * window.height * 4);
            const p0: [*]u8 = @ptrCast(c.malloc(n0) orelse return false);
            pixels = p0[0..n0];
            dumpSongbook(dir);
            return true;
        }
        const n: usize = @intCast(window.width * window.height * 4);
        const p: [*]u8 = @ptrCast(c.malloc(n) orelse return false);
        pixels = p[0..n];
        renderer_ready = true;
    }
    renderer.base = .{ 0.0, 0.0, 0.0 };
    const aspect = @as(f32, @floatFromInt(window.width)) / @as(f32, @floatFromInt(window.height));
    const name: []const u8 = @tagName(options.scene);
    var proj: m.M4 = undefined;
    switch (options.scene) {
        .dark => {
            world = World.init();
            renderer.keep = 0.82;
            renderer.stand = 1.0;
            renderer.fade = 70.0;
            renderer.far_floor = 0.12;
            renderer.heft = 0.0;
            renderer.sky = .{ 0.0, 0.0, 0.0 };
            proj = m.perspective(50.0, aspect, 0.3, 400.0);
            const static_n = thingLines(&world, &static_lines);
            renderer.setLand(static_lines[0..static_n], static_lines[0..0], &.{}, &.{});
            renderer.setGround(0, .{ 0.0, 0.0 }, .{ 0.0, 0.0 }, null);
            log("the dark: R1 calls, R2 hums, the left stick walks; Select and Start together leave", .{});
        },
        .evening, .asters => {
            if (options.scene == .evening) world.initEvening() else world.initAsters();
            aster_lines.build(&world);
            garden_lines.build();
            if (world.in_garden) {
                aster_lines.liftModels(&world_mod.ground.heightAt);
                garden_lines.liftModels(&world_mod.ground.heightAt);
            }
            renderer.keep = 0.55;
            renderer.fade = 70.0;
            renderer.far_floor = 0.05;
            renderer.heft = 0.55;
            renderer.sky = .{ 0.0, 0.0, 0.0 };
            proj = m.perspective(world_mod.place_fov, aspect, 0.4, 5000.0);
            // the ground starts black, or as it was left: a run with no screen always starts black,
            // so its frames are the same every time
            @memset(&ground, 0);
            // the first evening has no yesterday: it starts black, and only what is sung lights it
            const remembered = !options.headless and options.scene != .evening and loadGround();
            @memset(&ground_dirty, false);
            // the square under Hum is sent again in the first frames, so the first real change
            // to the picture is not the first time this GPU is asked to change one
            ground_dirty[((0 - @as(i32, @intFromFloat(ground_from[1]))) * ground_size / @as(i32, @intFromFloat(ground_span)) / ground_block) * ground_blocks + ((0 - @as(i32, @intFromFloat(ground_from[0]))) * ground_size / @as(i32, @intFromFloat(ground_span)) / ground_block)] = true;
            renderer.setGround(ground_size, ground_from, .{ ground_from[0] + ground_span, ground_from[1] + ground_span }, &ground);
            // the ground's light lies on the ground
            renderer.setGroundShape(if (world.in_garden) &world_mod.ground.heightAt else &flatGround, !world.in_garden);
            log("the ground: {s}", .{if (remembered) "as it was left" else "black: nothing has been sung on it yet"});
            log("the {s}: {d} asters, {d} things; R1 calls (held, the wheel: point with the right stick, let go to move home), R2 hums, the left stick walks, the right stick looks; stand still at a foot and the gaze climbs; Select and Start together leave", .{ name, world.tower_count, world.thing_count });
        },
    }
    if (options.load) |path| {
        if (!openSave(path)) return false;
    }
    world_mod.chords_tryout = options.chords;
    world_mod.tryout = .{};
    if (options.chords) {
        // the lean wakes beside the lift and home; nothing else in the world is changed
        world.awake |= @as(u8, 1) << @intFromEnum(world_mod.Mood.drive);
        log("the chords try-out (design/the-game.md): L1 steps the chord flatward and L2 sharpward among the lift (F), home (C) and the lean (G); on the lift Hum is light, on the lean it is fast, and stepping home off the lean throws it forward", .{});
    }
    if (options.check_take) |path| {
        var player = loadTake(path) orelse {
            log("that is not a take: {s}", .{std.mem.span(path)});
            return false;
        };
        playOn(&player, options.scene);
        log("the take ends: step {d}, world {x:0>16}", .{ world.step, world.fingerprint() });
        return true;
    }
    // a person's session writes its take as it is played; after a flat battery, it goes on from
    // where the take was cut off
    const keeping = options.keep or !(options.headless or options.bot or options.replay != null);
    if (keeping and options.walk != null) _ = card.beginIn(sceneOfTake(options.scene), "results/walks", options.walk.?);
    var resumed = false;
    dawns_kept = 0;
    if (keeping and options.load == null and options.replay == null) {
        const scene_t = sceneOfTake(options.scene);
        if (options.scene == .evening) {
            if (card_mod.lastCut(scene_t, &take_bytes)) |cut| {
                if (take.Player.open(cut.bytes)) |opened| {
                    var player = opened;
                    dawns_kept = card_mod.dawnsOf(scene_t, cut.number);
                    if (dawns_kept > 0) {
                        var path: [96]u8 = undefined;
                        if (card_mod.dawnPath(&path, scene_t, cut.number, dawns_kept)) |p| _ = openSave(p.ptr);
                    }
                    playOn(&player, options.scene);
                    const last = if (player.count > 0) player.now else Hands{};
                    _ = card.reopen(scene_t, cut.number, player.count, last, if (player.steps > 0) player.steps - 1 else 0);
                    resumed = true;
                    log("resumed where you were: the take cut off at step {d} ({d} s into the evening), from its dawn {d}; world {x:0>16}", .{ world.step, world.step / world_mod.steps_per_second, dawns_kept, world.fingerprint() });
                    if (options.resume_only) {
                        card.finish(world.step);
                        return true;
                    }
                }
            }
        }
        if (options.resume_only and !resumed) {
            log("nothing to go on from", .{});
            return true;
        }
        if (!resumed) _ = card.begin(scene_t);
    }
    snd.init();
    forgetPresses();
    @atomicStore(u8, &ready_paused, 0, .monotonic);
    if (options.load != null or resumed) {
        // the sound's count is the clock: it starts where the world was, and what was being held
        // is told again
        snd.sample = world.step * world_mod.samples_per_step;
        world.soundAgain();
    }
    var loud: [lines.max_bodies]lines.Shine = @splat(.{});
    loud[0] = .{ .lit = 255 };

    const device: c.SDL_AudioDeviceID = if (options.headless) 0 else openAudio();
    defer if (device != 0) sdl.CloseAudioDevice(device);
    var wav: ?Wav = if (options.wav) |path| Wav.open(path) else null;
    var pad = if (options.headless) Pad{} else Pad.open();
    var replay: ?take.Player = null;
    if (options.replay) |path| {
        replay = loadTake(path);
        if (replay) |r| {
            log("playing back a take: {d} steps, {d} changes of the hands", .{ r.steps, r.count });
        } else {
            log("that is not a take: {s}", .{std.mem.span(path)});
            return false;
        }
    }
    const scripted = options.headless or options.bot or replay != null;
    var script = Script{};
    var walker = Walker{};
    var backlight = Backlight{};
    var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
    var buf: [world_mod.samples_per_step]f32 = undefined;

    var frame: u32 = 0;
    var late: u32 = 0;
    var steps_run: u64 = 0;
    var double_steps: u32 = 0;
    var refused: u32 = 0;
    var leaving: u32 = 0;
    var work_sum: f64 = 0.0;
    var work_worst: f64 = 0.0;
    var last_swap = plat.now();
    var first_swap: f64 = 0.0;
    var running = true;
    var picked_x: f32 = 1e9;
    var picked_z: f32 = 1e9;
    var picked = aster_lines.Picked{ .lines = 0, .occ = 0, .near = 0, .mid = 0, .far = 0 };
    var cover_grid = [2]i32{ 0, 0 };
    var most_lines: usize = 0;
    var most_black: usize = 0;
    var worst_at: u32 = 0;
    var worst_step: u64 = 0;
    var worst_why: []const u8 = "";
    var repicked = false;
    var parts: [5]f64 = @splat(0.0);
    // each part of a frame summed over the run, and the wait for the screen, for their averages
    var part_sums: [6]f64 = @splat(0.0);
    var part_frames: u32 = 0;
    // how the work of a frame is spread: under 8, 12, 16 ms and over; and in frames over 14 ms,
    // which part took the most
    var maker_ms: [8]f64 = @splat(0.0);
    var moving_most: usize = 0;
    var work_spread: [4]u32 = @splat(0);
    var long_by: [5]u32 = @splat(0);
    var worst_parts: [6]f64 = @splat(0.0);
    var ring_dumped = false;
    var done_at: ?u32 = null;
    // the picture between steps: the pose before the latest step, the frame's moment in steps by
    // the sound's clock, and how steady the eye's travel was while Hum walked
    var pose_before = Pose.of(&world);
    var view_t: f64 = -1.0;
    var view_from: f64 = 0.0;
    var shown_last: ?[2]f32 = null;
    var stepped_last: ?[2]f32 = null;
    var steady = Steady{};
    // the songbook (SPEC.md 8): open, which page, since when; Start's edge; the world's wait
    var book_open = false;
    var book_page: songbook.Page = .call;
    var book_from: f64 = 0.0;
    var start_was = false;
    var select_seen = false;
    var flip_ready = true;

    while (running) : (frame += 1) {
        const began = plat.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
            // a pad plugged in while playing (on a laptop) is taken up; one pulled out is let go
            if (event.type == c.SDL_CONTROLLERDEVICEADDED and pad.handle == null and !options.headless) pad = Pad.open();
            if (event.type == c.SDL_CONTROLLERDEVICEREMOVED) {
                if (pad.handle) |handle| {
                    if (sdl.GameControllerGetAttached(handle) == c.SDL_FALSE) {
                        sdl.GameControllerClose(handle);
                        pad = .{};
                        log("controls: the controller was unplugged; the keyboard plays", .{});
                    }
                }
            }
        }

        // the steps that are due
        var mark: ?[]const u8 = null;
        if (device == 0) {
            const hands = if (replay) |*r| r.hands(world.step) else if (options.scene != .dark) walker.hands(&world) else script.hands(world.step);
            if (replay == null) mark = walker.mark;
            // the scripted player's marks, for the clips cut from the evening's sound (tools/clips.py)
            if (mark) |what| log("mark {s} at step {d}", .{ what, world.step });
            // a moment a person takes over in the room: the world kept there, so every walk starts
            // from this build's own evening (game/room/README.md)
            if (mark) |what| {
                if (options.walk_starts) |dir| {
                    if (std.mem.startsWith(u8, what, "start:")) keepStart(dir, what["start:".len..]);
                }
            }
            if (replay) |*r| {
                if (r.done(world.step + 1)) running = false;
            }
            // debug: GG_ORBIT holds the view's dial at a place
            if (c.getenv("GG_ORBIT")) |env| {
                const env_str = std.mem.span(env);
                if (std.fmt.parseFloat(f32, env_str)) |o| {
                    world.orbit = std.math.clamp(o, -1.0, 1.0);
                } else |_| {}
            }
            if (keeping) card.note(world.step, hands);
            const calls_before = world.calls;
            const n = world.stepOnce(hands, &cues);
            if (keeping and options.walk == null and world.dawn_from != world_mod.never and world.dawn_from + 1 == world.step) keepSave(options.scene);
            if (options.keep and world.step % 60 == 0) log("at step {d}", .{world.step});
            if (options.scene != .dark) groundStep(&world, world.calls != calls_before);
            for (cues[0..n]) |cue| {
                noteStrike(cue);
                if (!snd.push(cue)) refused += 1;
            }
            snd.render(&buf);
            if (wav) |*w| w.write(&buf);
            steps_run += 1;
        } else {
            const held = withKeys(pad.read());
            if (held.held(Hands.select) and held.held(Hands.start)) leaving += 1 else leaving = 0;
            if (leaving > 30) running = false;
            // Start let go, Select not pressed with it: the songbook opens, and the world waits; Start
            // again closes it, and the world goes on from where it waited
            const start_now = held.held(Hands.start);
            if (start_now and held.held(Hands.select)) select_seen = true;
            if (start_was and !start_now) {
                if (!select_seen and !scripted and replay == null) {
                    if (!book_open and !world.singing) {
                        book_open = true;
                        book_from = plat.now();
                        book_page = songbook.needed(&world) orelse lastLearned(&world);
                        @atomicStore(u8, &ready_paused, 1, .monotonic);
                        log("the songbook opened at step {d} on its page for {s}", .{ world.step, @tagName(book_page) });
                    } else if (book_open) {
                        book_open = false;
                        // the book closed: nothing is held that was let go while it was open
                        forgetPresses();
                        @atomicStore(u8, &ready_paused, 0, .monotonic);
                    }
                }
                select_seen = false;
            }
            start_was = start_now;
            if (book_open) {
                // the left stick turns the pages: those learned, and the one the moment asks for
                if (flip_ready and (held.lx > 80 or held.lx < -80)) {
                    book_page = nextPage(&world, book_page, held.lx > 0);
                    flip_ready = false;
                }
                if (held.lx < 30 and held.lx > -30) flip_ready = true;
            }
            const due = if (book_open) world.step else snd.played() / world_mod.samples_per_step;
            // what the hands started, read after the count: every edge before it is here
            takeEdges();
            @atomicStore(u8, &ready_cover, @intFromEnum(world.cover), .monotonic);
            @atomicStore(u32, &ready_home, @bitCast(world.home_hz), .monotonic);
            @atomicStore(u8, &ready_winded, @intFromBool(world.winded), .monotonic);
            @atomicStore(u8, &ready_singing, @intFromBool(world.singing), .monotonic);
            var ran: u32 = 0;
            while (world.step < due and ran < 3) : (ran += 1) {
                pose_before = Pose.of(&world);
                var hands = if (replay) |*r| r.hands(world.step) else if (!scripted) held else if (options.scene != .dark) walker.hands(&world) else script.hands(world.step);
                if (!scripted and replay == null and presses.fd >= 0) kernelHands(&hands, world.step);
                if (!scripted and replay == null and presses.fd < 0) clapOfSteps(&hands, world.step);
                if (keeping) card.note(world.step, hands);
                if (replay) |*r| {
                    if (r.done(world.step + 1)) running = false;
                }
                const calls_before = world.calls;
                const n = world.stepOnce(hands, &cues);
                // debug: GG_ORBIT holds the view's dial at a place
                if (c.getenv("GG_ORBIT")) |env| {
                    const env_str = std.mem.span(env);
                    if (std.fmt.parseFloat(f32, env_str)) |o| {
                        world.orbit = std.math.clamp(o, -1.0, 1.0);
                    } else |_| {}
                }
                // the day has just begun: keep the world as it is at its dawn
                if (keeping and options.walk == null and world.dawn_from != world_mod.never and world.dawn_from + 1 == world.step) keepSave(options.scene);
                if (options.scene != .dark) groundStep(&world, world.calls != calls_before);
                for (cues[0..n]) |cue| {
                    noteStrike(cue);
                    if (!snd.push(cue)) refused += 1;
                }
                steps_run += 1;
            }
            publishBeat(&world);
            if (!scripted and replay == null) followJack(world.step);
            if (ran > 1) double_steps += 1;
        }
        if (scripted and options.scene != .dark and walker.done and done_at == null) done_at = frame;
        if (done_at) |at| {
            // five seconds more, so what the last thing done sets ringing is heard and seen to its end
            if (options.frames == 0 and frame > at + 300) running = false;
        }
        if (!options.picture) {
            if (options.frames > 0 and frame + 1 >= options.frames) running = false;
            continue;
        }

        // the picture, drawn where Hum is at this frame's own moment: on the handheld, by the
        // sound's clock between the last two steps; with no sound, at the step itself
        var pose_real: ?Pose = null;
        if (device != 0) {
            if (soundClock(began)) |samples| {
                const measured = samples / @as(f64, @floatFromInt(world_mod.samples_per_step));
                if (view_t < 0.0 or @abs(measured - view_t) > 3.0) {
                    view_t = measured;
                } else {
                    view_t += (began - view_from) * 60.0;
                    view_t += (measured - view_t) * 0.2;
                }
                const gap_ms = (began - view_from) * 1000.0;
                view_from = began;
                const a: f32 = @floatCast(std.math.clamp(view_t - @as(f64, @floatFromInt(world.step)), -1.0, 1.25));
                const real = Pose.of(&world);
                pose_real = real;
                const shown = Pose.between(pose_before, real, a);
                shown.put(&world);
                // how far the eye's ground moved since the last frame, shown and by whole steps
                if (shown_last) |was| {
                    if (stepped_last) |was_step| steady.add(.{ shown.x - was[0], shown.z - was[1] }, .{ real.x - was_step[0], real.z - was_step[1] }, gap_ms);
                }
                shown_last = .{ shown.x, shown.z };
                stepped_last = .{ real.x, real.z };
            }
        }
        defer if (pose_real) |real| real.put(&world);
        parts[0] = (plat.now() - began) * 1000.0;
        repicked = false;
        var eye: m.V3 = undefined;
        var view: m.M4 = undefined;
        var cam: world_mod.Camera = undefined;
        var brightest: f32 = 0.0;
        if (options.scene == .dark) {
            renderer.setReact(@splat(0.0), 0.0, 0.0, .{ 0.0, 0.0 });
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                brightest = @max(brightest, World.light(thing));
                loud[i + 1] = shine(thing.loud, thing.lit * 0.55, 1.0, 1.0);
            }
            for (world.rings) |ring| {
                if (ring.live) brightest = @max(brightest, 0.5);
            }
            eye = .{ world.hum_x, 40.0, world.hum_z + 36.0 };
            view = m.lookAt(eye, .{ world.hum_x, 0.0, world.hum_z - 3.0 }, .{ 0.0, 1.0, 0.0 });
            cam = .{ .eye = eye, .at = .{ world.hum_x, 0.0, world.hum_z - 3.0 }, .up = .{ 0.0, 1.0, 0.0 }, .fov = 50.0, .stand = 1.0 };
        } else {
            // A thing shines with its own sound, spread over its lines, and gives back the light
            // that falls on it: the day, once the dawn has reached it, or a passing call. In the
            // dark a silent thing is seen only when a call passes it (spec/texture.md).
            const sky_level = world.skyLevel();
            loud[1] = shine(0.0, sky_level, 1.0, 1.0);
            // before the dawn's edge reaches a place, the sky's own light falls on it faintly
            const twilight = 0.4 * sky_level;
            const wheel_dim: f32 = if (world.wheel_open) 0.68 else 1.0;
            const rung_end = if (world.rung_first == world_mod.no_thing) 0 else world.rung_first + world_mod.rungs;
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                const body = aster_lines.thing_body + i;
                if (i >= world.rung_first and i < rung_end) {
                    // the sky's rungs shine only with the sun's held overtones
                    loud[body] = shine(thing.loud, 0.0, 1.0, 0.0);
                    continue;
                }
                const day = @max(world.dayAt(thing.x, thing.z), twilight);
                const dim: f32 = if (thing.sounds) 0.30 else 0.26;
                const own: f32 = if (thing.sounds) thing.loud else 0.0;
                if (thing.sounds) brightest = @max(brightest, World.light(thing));
                loud[body] = shine(own * wheel_dim, @max(dim * day, thing.lit * 0.55) * wheel_dim, spread[body], 0.9);
            }
            // the ground's cover, a square at a time: the day where the dawn has reached it, and
            // the edge of any ring crossing it, given back as its cover gives
            for (0..@as(usize, @intCast(aster_lines.cover_side * aster_lines.cover_side))) |cell| {
                const gx: f32 = @floatFromInt(@as(i32, @intCast(cell % @as(usize, @intCast(aster_lines.cover_side)))) + cover_grid[0]);
                const gz: f32 = @floatFromInt(@as(i32, @intCast(cell / @as(usize, @intCast(aster_lines.cover_side)))) + cover_grid[1]);
                const cx = (gx + 0.5) * 16.0;
                const cz = (gz + 0.5) * 16.0;
                var band: f32 = 0.0;
                for (world.rings) |ring| {
                    if (!ring.live) continue;
                    if (ring.wave_more > 0.0) continue; // strikes do not illuminate call bands
                    const dx = cx - ring.x;
                    const dz = cz - ring.z;
                    const behind = ring.age * world_mod.dt * world_mod.sound_speed - @sqrt(dx * dx + dz * dz);
                    if (behind < 0.0 or behind > 110.0) continue;
                    const fall = 1.0 - behind / 110.0;
                    band = @max(band, fall * fall);
                }
                loud[aster_lines.cover_body + cell] = shine(0.0, (@max(world.dayAt(cx, cz), twilight) + band * 1.6) * wheel_dim, 1.0, aster_lines.coverGives(aster_lines.coverAt(cx, cz)));
            }
            // debug: GG_ORBIT holds the view's dial at a place
            if (c.getenv("GG_ORBIT")) |env| {
                const env_str = std.mem.span(env);
                if (std.fmt.parseFloat(f32, env_str)) |o| {
                    world.orbit = std.math.clamp(o, -1.0, 1.0);
                } else |_| {}
            }
            cam = world.camera();
            renderer.stand = cam.stand;
            eye = cam.eye;
            // what stands between the eye and Hum is see-through: a cone round the line from the
            // eye to Hum's middle (spec/engine.md, "What stands between the eye and Hum")
            const hum_at = [3]f32{ world.hum_x, (world.hum_ground + world.hum_y + world_mod.hum_mid) * cam.stand, world.hum_z };
            renderer.setCone(cam.eye, hum_at, cam.stand);
            renderer.setReact(world.react.awake, world.react.rise, world.react.tilt, world_mod.harmony.home(&world));
            const fx = @sin(world.look_yaw);
            const fz = -@cos(world.look_yaw);
            view = m.lookAt(cam.eye, cam.at, cam.up);
            proj = m.perspective(cam.fov, aspect, 0.4, 9000.0);
            renderer.ground_eye = .{ eye[0], eye[2] };
            renderer.ground_look = .{ fx, fz };
            // where on the screen the horizon is, and where the sun will come up
            const dy = (cam.at[1] - cam.eye[1]) / 10.0;
            const pitch = std.math.asin(std.math.clamp(dy, -1.0, 1.0));
            const half = cam.fov * 0.5 * std.math.pi / 180.0;
            const sun_at = world.sunPlace();
            var turn: f32 = std.math.atan2(sun_at[0] - eye[0], -(sun_at[2] - eye[2])) - world.look_yaw;
            while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
            while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
            const across: f32 = if (@abs(turn) < 1.3) 0.5 + @tan(turn) / (2.0 * @tan(half) * aspect) else 9.0;
            const tan_pitch = if (pitch > -1.45) @tan(pitch) else -10.0;
            renderer.dawn = .{ across, 0.5 - tan_pitch / (2.0 * @tan(half)) };
            // Dawn sky glow: warm amber/rose horizon over the lake, clearly noticeable
            const glow = [3]f32{ 0.32, 0.22, 0.16 };
            if (cam.stand < 0.5 or pitch < -1.2) {
                renderer.sky = .{ 0.0, 0.0, 0.0 };
            } else {
                renderer.sky = .{ glow[0] * sky_level * wheel_dim, glow[1] * sky_level * wheel_dim, glow[2] * sky_level * wheel_dim };
            }
            // each aster at the detail its distance asks for, picked again every twenty metres
            const moved_x = eye[0] - picked_x;
            const moved_z = eye[2] - picked_z;
            if (moved_x * moved_x + moved_z * moved_z > 20.0 * 20.0) {
                picked = aster_lines.pick(world.hum_x, world.hum_z, static_lines[0..26_000], static_occ[0..24_000], static_occ_tags[0..24_000]);
                // the hose, the spigot, the reeds and the pool's edge, each square of ground round
                // Hum lending its body to what stands in it (garden_lines.zig)
                const half_side: i32 = @divTrunc(aster_lines.cover_side, 2);
                const grid_now = [2]i32{ @as(i32, @intFromFloat(@floor(world.hum_x / 16.0))) - half_side, @as(i32, @intFromFloat(@floor(world.hum_z / 16.0))) - half_side };
                var garden_occ = black_shapes.Tris{ .out = static_occ[picked.occ..], .tags = static_occ_tags[picked.occ..] };
                picked.lines += garden_lines.pick(world.hum_x, world.hum_z, grid_now, static_lines[picked.lines..], &garden_occ);
                picked.occ += garden_occ.n;
                // what is made afresh for where Hum is stands on the ground as it is made
                const made_from = picked.lines;
                const occ_from = picked.occ;
                picked.lines += aster_lines.fallen(&world, static_lines[picked.lines..]);
                var ground_occ = black_shapes.Tris{ .out = static_occ[picked.occ..], .tags = static_occ_tags[picked.occ..] };
                picked.lines += aster_lines.ground(world.hum_x, world.hum_z, static_lines[picked.lines..], &ground_occ, &cover_grid);
                picked.occ += ground_occ.n;
                picked.lines += aster_lines.horn(&world, static_lines[picked.lines..]);
                if (world.in_garden) {
                    lines.lift(static_lines[made_from..picked.lines], &world_mod.ground.heightAt);
                    lines.liftPoints(static_occ[occ_from..picked.occ], &world_mod.ground.heightAt);
                }
                spreadLight(static_lines[0..picked.lines]);
                renderer.setLand(static_lines[0..if (options.half_land) picked.lines / 2 else picked.lines], static_lines[0..0], static_occ[0..picked.occ], static_occ_tags[0..picked.occ]);
                picked_x = eye[0];
                picked_z = eye[2];
                repicked = true;
            }
        }
        parts[1] = (plat.now() - began) * 1000.0;
        var moving_n: usize = 0;
        var pools_from: usize = 0;
        var pools_to: usize = 0;
        if (options.scene != .dark) {
            // each maker of moving lines, timed, so the one that runs long can be named
            const makers = .{ "the sun", "the stars", "the dawn's edge", "halos", "the evening", "sparks", "the bee", "pools", "the wheel", "the swell", "knots", "ghosts", "the clap", "the hose's hum", "water", "the figure" };
            _ = makers;
            var t0 = plat.now();
            moving_n = aster_lines.sun(&world, eye, &moving);
            moving_n += aster_lines.stars(&world, eye, moving[moving_n..]);
            moving_n += aster_lines.dawnEdge(&world, moving[moving_n..]);
            maker_ms[0] += plat.now() - t0;
            t0 = plat.now();
            if (world.stand > 0.6) moving_n += aster_lines.halos(&world, eye, moving[moving_n..]);
            maker_ms[1] += plat.now() - t0;
            t0 = plat.now();
            moving_n += eveningLines(&world, moving[moving_n..]);
            moving_n += strikeLines(&world, moving[moving_n..]);
            moving_n += aster_lines.sparks(&world, moving[moving_n..]);
            moving_n += aster_lines.beeLines(&world, moving[moving_n..]);
            maker_ms[2] += plat.now() - t0;
            t0 = plat.now();
            pools_from = moving_n;
            moving_n += aster_lines.poolLines(&world, eye, moving[moving_n..]);
            pools_to = moving_n;
            maker_ms[3] += plat.now() - t0;
            t0 = plat.now();
            moving_n += aster_lines.knotLines(&world, eye, moving[moving_n..]);
            moving_n += aster_lines.ghostLines(&world, moving[moving_n..]);
            moving_n += aster_lines.clapLines(&world, moving[moving_n..]);
            maker_ms[4] += plat.now() - t0;
            t0 = plat.now();
            moving_n += garden_lines.humLines(&world, moving[moving_n..]);
            moving_n += garden_lines.waterLines(&world, moving[moving_n..]);
            moving_n += garden_lines.figureLines(&world, moving[moving_n..]);
            maker_ms[5] += plat.now() - t0;
        }
        var t1 = plat.now();
        moving_n += movingLines(&world, cam.stand, eye, moving[moving_n..]);
        maker_ms[6] += plat.now() - t1;
        t1 = plat.now();
        // the puddles' lines stand at their own water's level already
        if (world.in_garden) {
            lines.lift(moving[0..pools_from], &world_mod.ground.heightAt);
            lines.lift(moving[pools_to..moving_n], &world_mod.ground.heightAt);
        }
        maker_ms[7] += plat.now() - t1;

        // Top-level pass: circle of fifths (wheel) & swell lines are always drawn on top of
        // all world geometry and foliage so they are never occluded or buried
        var top_from: u32 = 0;
        var top_count: u32 = 0;
        if (options.scene != .dark and (world.wheel_open or world.singing)) {
            top_from = @intCast(moving_n);
            moving_n += aster_lines.wheelLines(&world, moving[moving_n..]);
            moving_n += aster_lines.swellLines(&world, moving[moving_n..]);
            top_count = @intCast(moving_n - top_from);
        }
        renderer.setTop(top_from, top_count);
        moving_most = @max(moving_most, moving_n);
        most_lines = @max(most_lines, picked.lines + moving_n);
        parts[2] = (plat.now() - began) * 1000.0;
        renderer.setDynamic(moving[0..moving_n]);
        // what moves hides too: Hum's own figure, from the outline its lines are drawn on
        var moving_tris = black_shapes.Tris{ .out = &moving_occ };
        if (options.scene != .dark and world.view == .place and cam.stand >= 0.5) {
            const oval = hum_figure.Oval.of(&world, cam.eye);
            const rim = oval.outline();
            black_shapes.facing(oval.middle(), &rim, &moving_tris);
        }
        if (world.in_garden) lines.liftPoints(moving_occ[0..moving_tris.n], &world_mod.ground.heightAt);
        renderer.setMovingOcc(moving_tris.slice());
        most_black = @max(most_black, picked.occ / 3 + moving_tris.count());
        if (options.scene != .dark) sendGround();
        const vp = m.mul(proj, view);
        parts[3] = (plat.now() - began) * 1000.0;
        renderer.without_trail = options.without_trail;
        renderer.without_ground = options.without_ground;
        renderer.frame(&vp, &loud);
        if (options.scene == .evening and world.step >= world.stand_from and world.step < world.stand_from + 330) {
            // the first words anyone says in it, as the page stands up: the one line of text
            const since: f32 = @floatFromInt(world.step - world.stand_from);
            const shown = std.math.clamp(@min(since / 40.0, (330.0 - since) / 70.0), 0.0, 1.0);
            const line = "Oh. You're in.";
            const scale: f32 = 2.6;
            const wide = @as(f32, @floatFromInt(line.len)) * 9.6 * scale;
            words.line((@as(f32, @floatFromInt(window.width)) - wide) * 0.5, @as(f32, @floatFromInt(window.height)) * 0.17, scale, .{ 0.886 * shown, 0.839 * shown, 0.784 * shown, shown }, line);
            words.flush();
        }
        if (options.chords and world.stand >= 1.0 and !world.wheel_open) {
            // the try-out's one line of words: what the two triggers are until they have been found,
            // and for two seconds after each change the chord's letter and what it is
            const t = world_mod.tryout;
            const since: f32 = if (t.changed_at == world_mod.never) 1.0e9 else @floatFromInt(world.step - t.changed_at);
            const line: []const u8 = if (since < 120.0) (switch (world.home_k) {
                -1 => "F  LIFT",
                1 => "G  LEAN",
                else => "C  HOME",
            }) else if (t.steps < 4) "L1 LIFT    L2 LEAN" else "";
            if (line.len > 0) {
                const shown: f32 = if (since < 120.0) std.math.clamp((120.0 - since) / 40.0, 0.0, 1.0) else 0.7;
                const scale: f32 = 2.2;
                const wide = @as(f32, @floatFromInt(line.len)) * 9.6 * scale;
                // at the top: Hum stands in the lower third
                words.line((@as(f32, @floatFromInt(window.width)) - wide) * 0.5, @as(f32, @floatFromInt(window.height)) * 0.06, scale, .{ 0.886 * shown, 0.839 * shown, 0.784 * shown, shown }, line);
                words.flush();
            }
        }
        if (book_open) {
            const whole: f32 = if (songbook.learned(&world, book_page)) 1.0 else 0.55;
            songbook.draw(&sketch, book_page, @floatCast(plat.now() - book_from), whole);
            sketch.flush();
        }
        parts[4] = (plat.now() - began) * 1000.0;
        // the backlight is the sun: down in the dark, where only what sounds is lit, and up with the day
        if (!options.headless) backlight.follow(if (options.scene == .dark) brightest else world.dawn * 0.38 + (0.25 + 0.37 * world.dawn) * brightest);
        const work = (plat.now() - began) * 1000.0;
        work_sum += work;
        if (frame > 30) {
            part_sums[0] += parts[0];
            for (1..5) |i| part_sums[i] += parts[i] - parts[i - 1];
            part_frames += 1;
            work_spread[if (work < 8.0) 0 else if (work < 12.0) 1 else if (work < 16.0) 2 else 3] += 1;
            if (work > 14.0) {
                var most: usize = 0;
                var most_ms: f64 = parts[0];
                for (1..5) |i| {
                    if (parts[i] - parts[i - 1] > most_ms) {
                        most_ms = parts[i] - parts[i - 1];
                        most = i;
                    }
                }
                long_by[most] += 1;
            }
        }
        if (frame > 30 and work > work_worst) {
            work_worst = work;
            worst_at = frame;
            worst_step = world.step;
            worst_why = if (repicked) "the land was picked again" else "nothing was picked";
            worst_parts = .{ parts[0], parts[1], parts[2], parts[3], parts[4], work };
        }

        if (options.dump) |dir| {
            if (options.promise == null) {
                if (options.dump_every > 0 and frame % options.dump_every == 0) dumpNamed(dir, "{s}-{d:0>5}", .{ name, frame });
                if (mark) |what| dumpNamed(dir, "promise-{s}-{s}", .{ name, what });
                if (options.scene == .dark and !ring_dumped) {
                    for (world.rings) |ring| {
                        // a ring just over half a second old: 36 m out, with what it passed lit and the rest dark
                        if (ring.live and world.step - ring.born == 36 and world.calls >= 2) {
                            dumpNamed(dir, "promise-dark-ring", .{});
                            ring_dumped = true;
                        }
                    }
                }
            }
        }
        const swap_from = plat.now();
        sdl.GL_SwapWindow(window.handle);
        const swapped = plat.now();
        if (frame > 30) part_sums[5] += (swapped - swap_from) * 1000.0;
        if (frame > 30 and (swapped - last_swap) * 1000.0 > 25.0) late += 1;
        if (frame == 30) first_swap = swapped;
        last_swap = swapped;
        if (options.frames > 0 and frame + 1 >= options.frames) running = false;
    }

    if (wav) |*w| w.close();
    if (options.scene != .dark and !options.headless and !scripted and options.walk == null) saveGround();
    if (keeping) card.finish(world.step);
    last_visit = .{ .calls = world.calls, .seconds = @as(f32, @floatFromInt(world.step)) / 60.0 };
    if (options.promise) |promise| {
        if (world_mod.witness.Table.find(promise)) |id| {
            const seen = world.seen.get(id);
            last_visit.witnessed = true;
            last_visit.met = seen.met;
            last_visit.stayed_s = @as(f32, @floatFromInt(seen.held)) / 60.0;
        }
    }
    log("the {s}: {d} frames, {d} late, {d:.2} ms of work a frame (worst {d:.2}); {d} steps, {d} frames ran two; {d} calls, {d} answers; cues late {d}, refused {d}; slowest sound buffer {d:.2} ms; real-time sound {s}; most lines in a frame {d}, most black triangles {d}", .{
        name,
        frame,
        late,
        work_sum / @as(f64, @floatFromInt(@max(frame, 1))),
        work_worst,
        steps_run,
        double_steps,
        world.calls,
        world.answers,
        snd.late,
        refused + world.dropped,
        @as(f64, @floatFromInt(@atomicLoad(u32, &audio_slowest_us, .monotonic))) / 1000.0,
        if (@atomicLoad(i32, &audio_realtime, .monotonic) == 1) "yes" else "no",
        most_lines,
        most_black,
    });
    if (garden_lines.lost_black > 0) log("the garden's models lost {d} black triangles for want of room", .{garden_lines.lost_black});
    if (options.chords) {
        const t = world_mod.tryout;
        log("the chords try-out: {d} steps of the chord, {d} of them on the tick, {d} knocks at the end of what is awake, {d} throws home off the lean; highest {d:.1} m, fastest {d:.1} m/s; ended on {s}", .{ t.steps, t.timed, t.knocks, t.launches, t.highest, t.fastest, switch (world.home_k) {
            -1 => "the lift",
            1 => "the lean",
            else => "home",
        } });
    }
    if (presses.fd >= 0) {
        // how soon Hum answered the hands: from the kernel seeing a press to the buffer that began
        // the sound, the most of any press this scene
        log("the hands: {d} presses of R1 and R2 and claps ({d} of them claps) started Hum's own sound on the buffer after them, the latest {d:.2} ms after the kernel saw the press; {d} strikes timed by the hands started there too; the world found {d} of them already sounding; {d} calls choked by a clap just after; {d} strikes timed and {d} placed in all", .{ @atomicLoad(u32, &hands_started, .monotonic), @atomicLoad(u32, &hands_claps, .monotonic), @as(f64, @floatFromInt(@atomicLoad(u32, &hands_most_us, .monotonic))) / 1000.0, @atomicLoad(u32, &hands_strikes, .monotonic), snd.own_met, snd.choked, world.timed_strikes, world.placed_strikes });
    }
    if (frame > 90 and !options.headless) log("the screen: a frame shown every {d:.2} ms on average", .{(last_swap - first_swap) * 1000.0 / @as(f64, @floatFromInt(frame - 31))});
    if (options.scene == .evening) logTeaching(&world);
    if (part_frames > 0) {
        const pf: f64 = @floatFromInt(part_frames);
        log("a frame's work: under 8 ms {d}, under 12 {d}, under 16 {d}, over 16 {d}; of those over 14 ms the most was the steps in {d}, the land {d}, the moving lines {d}, sending {d}, drawing {d}", .{ work_spread[0], work_spread[1], work_spread[2], work_spread[3], long_by[0], long_by[1], long_by[2], long_by[3], long_by[4] });
        log("the moving lines on average: the sky {d:.2} ms, halos {d:.2}, Drip and sparks and the bee {d:.2}, pools {d:.2}, the wheel and the fight {d:.2}, the hose's water {d:.2}, rings and Hum {d:.2}, lifting them onto the ground {d:.2}; at most {d} lines", .{ maker_ms[0] * 1000.0 / pf, maker_ms[1] * 1000.0 / pf, maker_ms[2] * 1000.0 / pf, maker_ms[3] * 1000.0 / pf, maker_ms[4] * 1000.0 / pf, maker_ms[5] * 1000.0 / pf, maker_ms[6] * 1000.0 / pf, maker_ms[7] * 1000.0 / pf, moving_most });
        log("a frame's parts on average: the steps {d:.2} ms, the land {d:.2}, the moving lines {d:.2}, sent to the GPU {d:.2}, drawn {d:.2}, waiting for the screen {d:.2}", .{ part_sums[0] / pf, part_sums[1] / pf, part_sums[2] / pf, part_sums[3] / pf, part_sums[4] / pf, part_sums[5] / pf });
    }
    if (steady.n > 0) log("the picture between steps: while Hum walked it moved {d:.1} cm a frame, varying by {d:.1} cm as shown, and by {d:.1} cm as it would have been by whole steps ({d} frames)", .{ steady.mean() * 100.0, steady.spread(.shown) * 100.0, steady.spread(.stepped) * 100.0, steady.n });
    log("the slowest frame was {d} (step {d}): steps done by {d:.2} ms, the land by {d:.2}, the moving lines by {d:.2}, sent to the GPU by {d:.2}, drawn by {d:.2}, the backlight set by {d:.2}; {s}", .{ worst_at, worst_step, worst_parts[0], worst_parts[1], worst_parts[2], worst_parts[3], worst_parts[4], worst_parts[5], worst_why });
    for (world_mod.witness.names, 0..) |promise, i| {
        const seen = world.seen.marks[i];
        if (seen.met) log("witness {s} first={d} held={d}", .{ promise, seen.first, seen.held });
    }
    return plat.checkGl("the scene");
}
