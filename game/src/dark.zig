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
const colour = @import("draw/colour.zig");
const m = @import("m.zig");
const world_mod = @import("world/world.zig");
const sound_mod = @import("sound/sound.zig");
const Script = @import("bot/script.zig").Script;
const Walker = @import("bot/walker.zig").Walker;
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

const Pad = struct {
    handle: ?*c.SDL_GameController = null,

    fn open() Pad {
        var pad = Pad{};
        const count = sdl.NumJoysticks();
        var i: c_int = 0;
        while (i < count) : (i += 1) {
            if (sdl.IsGameController(i) == c.SDL_FALSE) continue;
            pad.handle = sdl.GameControllerOpen(i);
            if (pad.handle != null) {
                log("controls: {s}", .{std.mem.span(sdl.GameControllerName(pad.handle))});
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
        // Face buttons are named by position: SDL's A is the bottom one, whatever is printed on it.
        const map = [_]struct { sdl_button: c_int, bit: u16 }{
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER, .bit = Hands.call },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER, .bit = Hands.voice },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_A, .bit = Hands.jump },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_B, .bit = Hands.dodge },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_X, .bit = Hands.strike },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_Y, .bit = Hands.grab },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_BACK, .bit = Hands.select },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_START, .bit = Hands.start },
        };
        for (map) |entry| {
            if (sdl.GameControllerGetButton(handle, entry.sdl_button) != 0) h.buttons |= entry.bit;
        }
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 16000) h.buttons |= Hands.sing;
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 16000) h.buttons |= Hands.guard;
        return h;
    }
};

fn noteColour(hz: f32) [3]f32 {
    return colour.ofNote(world_mod.garden_hz, hz);
}

fn col8(rgb: [3]f32, alpha: f32) [4]u8 {
    return .{
        @intFromFloat(std.math.clamp(rgb[0], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[1], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[2], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(alpha, 0.0, 1.0) * 255.0),
    };
}

const per_thing = 12;
const bone = [3]f32{ 0.886, 0.839, 0.784 };

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
fn movingLines(w: *const World, eye: m.V3, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.rings) |ring| {
        if (!ring.live) continue;
        const age: f32 = @floatFromInt(w.step - ring.born);
        const reach = age * world_mod.dt * world_mod.sound_speed;
        const fade = std.math.clamp(1.0 - reach / w.ring_reach, 0.0, 1.0);
        const tint = col8(bone, 0.85 * fade * fade);
        const parts = 64;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ ring.x + reach * @cos(a0), 0.05, ring.z + reach * @sin(a0) },
                .b = .{ ring.x + reach * @cos(a1), 0.05, ring.z + reach * @sin(a1) },
                .half_width = 1.5,
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

    const hum_tint = col8(bone, 1.0);
    if (w.view == .page) {
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
        // stood beside: one metre of bone-white, hatched so it reads as the one solid thing
        const swell: f32 = if (w.singing) 1.2 else 1.0;
        const rx = @cos(w.look_yaw);
        const rz = @sin(w.look_yaw);
        const wide = 0.36 * swell;
        const high = 0.5 * swell;
        const parts = 14;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ w.hum_x + rx * wide * @cos(a0), 0.52 + high * @sin(a0), w.hum_z + rz * wide * @cos(a0) },
                .b = .{ w.hum_x + rx * wide * @cos(a1), 0.52 + high * @sin(a1), w.hum_z + rz * wide * @cos(a1) },
                .half_width = 1.9,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        const fill = col8(bone, 0.5);
        for (1..8) |k| {
            const f = @as(f32, @floatFromInt(k)) / 8.0 * 2.0 - 1.0;
            const across = wide * @sqrt(1.0 - f * f);
            out[n] = .{
                .a = .{ w.hum_x - rx * across, 0.52 + high * f, w.hum_z - rz * across },
                .b = .{ w.hum_x + rx * across, 0.52 + high * f, w.hum_z + rz * across },
                .half_width = 2.2,
                .body = 0.0,
                .col = fill,
            };
            n += 1;
        }
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

pub const Scene = enum { dark, asters };

pub const Options = struct {
    scene: Scene = .dark,
    headless: bool = false,
    frames: u32 = 0,
    dump: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav: ?[*:0]const u8 = null,
    /// Real sound and the real clock, but the scripted hands: for measuring on the handheld.
    bot: bool = false,
    /// The promise a person was sent here to feel, from the room's walk.
    promise: ?[]const u8 = null,
};

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
var renderer: lines.Renderer = undefined;
var renderer_ready = false;
var pixels: []u8 = &.{};
var static_lines: [36_000]lines.Inst = undefined;
var static_occ: [40_000][3]f32 = undefined;
var moving: [6_000]lines.Inst = undefined;

fn dumpNamed(dir: [*:0]const u8, comptime fmt: []const u8, args: anytype) void {
    renderer.readFrame(pixels);
    var path: [512]u8 = undefined;
    var name: [128]u8 = undefined;
    const leaf = std.fmt.bufPrint(&name, fmt, args) catch return;
    if (std.mem.printSentinel(&path, "{s}/{s}.png", .{ std.mem.span(dir), leaf }, 0)) |text| {
        _ = png.writeFromGl(text.ptr, @intCast(renderer.fb_w), @intCast(renderer.fb_h), pixels);
    } else |_| {}
}

pub fn run(window: plat.Window, options: Options) bool {
    if (!renderer_ready) {
        if (!renderer.init(window.width, window.height)) return false;
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
            renderer.fade = 70.0;
            proj = m.perspective(50.0, aspect, 0.3, 400.0);
            const static_n = thingLines(&world, &static_lines);
            renderer.setLand(static_lines[0..static_n], static_lines[0..0], &.{});
            log("the dark: R1 calls, R2 hums, the left stick walks; Select and Start together leave", .{});
        },
        .asters => {
            world.initAsters();
            aster_lines.build(&world);
            renderer.keep = 0.55;
            renderer.fade = 300.0;
            proj = m.perspective(world_mod.place_fov, aspect, 0.4, 5000.0);
            log("the asters: {d} of them, {d} things; R1 calls, the left stick walks, the right stick looks; stand still at a foot and the view leans back; Select and Start together leave", .{ world.tower_count, world.thing_count });
        },
    }
    snd.init();
    var loud: [lines.max_bodies]u8 = @splat(0);
    loud[0] = 255;

    const device: c.SDL_AudioDeviceID = if (options.headless) 0 else openAudio();
    defer if (device != 0) sdl.CloseAudioDevice(device);
    var wav: ?Wav = if (options.wav) |path| Wav.open(path) else null;
    const pad = if (options.headless) Pad{} else Pad.open();
    const scripted = options.headless or options.bot;
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
    var running = true;
    var picked_x: f32 = 1e9;
    var picked_z: f32 = 1e9;
    var picked = aster_lines.Picked{ .lines = 0, .occ = 0, .near = 0, .mid = 0, .far = 0 };
    var most_lines: usize = 0;
    var ring_dumped = false;
    var done_at: ?u32 = null;

    while (running) : (frame += 1) {
        const began = plat.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
        }

        // the steps that are due
        var mark: ?[]const u8 = null;
        if (device == 0) {
            const hands = if (options.scene == .asters) walker.hands(&world) else script.hands(world.step);
            mark = walker.mark;
            const n = world.stepOnce(hands, &cues);
            for (cues[0..n]) |cue| {
                if (!snd.push(cue)) refused += 1;
            }
            snd.render(&buf);
            if (wav) |*w| w.write(&buf);
            steps_run += 1;
        } else {
            const held = pad.read();
            if (held.held(Hands.select) and held.held(Hands.start)) leaving += 1 else leaving = 0;
            if (leaving > 30) running = false;
            const due = snd.played() / world_mod.samples_per_step;
            var ran: u32 = 0;
            while (world.step < due and ran < 3) : (ran += 1) {
                const hands = if (!scripted) held else if (options.scene == .asters) walker.hands(&world) else script.hands(world.step);
                const n = world.stepOnce(hands, &cues);
                for (cues[0..n]) |cue| {
                    if (!snd.push(cue)) refused += 1;
                }
                steps_run += 1;
            }
            if (ran > 1) double_steps += 1;
        }
        if (scripted and options.scene == .asters and walker.done and done_at == null) done_at = frame;
        if (done_at) |at| {
            if (options.frames == 0 and frame > at + 30) running = false;
        }

        // the picture
        var eye: m.V3 = undefined;
        var view: m.M4 = undefined;
        var brightest: f32 = 0.0;
        if (options.scene == .dark) {
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                const light = World.light(thing);
                brightest = @max(brightest, light);
                loud[i + 1] = @intFromFloat(light * 255.0);
            }
            for (world.rings) |ring| {
                if (ring.live) brightest = @max(brightest, 0.5);
            }
            eye = .{ world.hum_x, 40.0, world.hum_z + 36.0 };
            view = m.lookAt(eye, .{ world.hum_x, 0.0, world.hum_z - 3.0 }, .{ 0.0, 1.0, 0.0 });
        } else {
            // dawn: everything can just be seen, and what a call lights or rings stands out of it
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                const light = World.light(thing);
                const floor: f32 = if (thing.sounds) 0.26 else 0.20;
                if (thing.sounds) brightest = @max(brightest, light);
                loud[i + 1] = @intFromFloat(@max(floor, light) * 255.0);
            }
            const yaw = world.look_yaw;
            const pitch = world.pitch();
            const fx = @sin(yaw);
            const fz = -@cos(yaw);
            const back = world_mod.cam_back - 2.5 * world.lean;
            eye = .{ world.hum_x - fx * back, world_mod.cam_up - 0.9 * world.lean, world.hum_z - fz * back };
            const at = m.V3{ eye[0] + fx * @cos(pitch) * 10.0, eye[1] + @sin(pitch) * 10.0, eye[2] + fz * @cos(pitch) * 10.0 };
            view = m.lookAt(eye, at, .{ 0.0, 1.0, 0.0 });
            // each aster at the detail its distance asks for, picked again every twenty metres
            const moved_x = eye[0] - picked_x;
            const moved_z = eye[2] - picked_z;
            if (moved_x * moved_x + moved_z * moved_z > 20.0 * 20.0) {
                picked = aster_lines.pick(eye[0], eye[2], static_lines[0..30_000], &static_occ);
                picked.lines += aster_lines.grass(eye[0], eye[2], static_lines[picked.lines..]);
                renderer.setLand(static_lines[0..picked.lines], static_lines[0..0], static_occ[0..picked.occ]);
                picked_x = eye[0];
                picked_z = eye[2];
            }
        }
        var moving_n: usize = 0;
        if (options.scene == .asters) moving_n = aster_lines.sky(eye, &moving);
        moving_n += movingLines(&world, eye, moving[moving_n..]);
        most_lines = @max(most_lines, picked.lines + moving_n);
        renderer.setDynamic(moving[0..moving_n]);
        const vp = m.mul(proj, view);
        renderer.frame(&vp, &loud);
        if (!options.headless) backlight.follow(if (options.scene == .dark) brightest else 0.38 + 0.62 * brightest);
        const work = (plat.now() - began) * 1000.0;
        work_sum += work;
        if (frame > 30) work_worst = @max(work_worst, work);

        if (options.dump) |dir| {
            if (options.promise == null) {
                if (options.dump_every > 0 and frame % options.dump_every == 0) dumpNamed(dir, "{s}-{d:0>5}", .{ name, frame });
                if (mark) |what| dumpNamed(dir, "promise-{s}-{s}", .{ name, what });
                if (options.scene == .dark and !ring_dumped) {
                    for (world.rings) |ring| {
                        // a ring a second and a quarter old: 75 m out, with what it passed still lit
                        if (ring.live and world.step - ring.born == 75 and world.calls >= 2) {
                            dumpNamed(dir, "promise-dark-ring", .{});
                            ring_dumped = true;
                        }
                    }
                }
            }
        }
        sdl.GL_SwapWindow(window.handle);
        const swapped = plat.now();
        if (frame > 30 and (swapped - last_swap) * 1000.0 > 25.0) late += 1;
        last_swap = swapped;
        if (options.frames > 0 and frame + 1 >= options.frames) running = false;
    }

    if (wav) |*w| w.close();
    last_visit = .{ .calls = world.calls, .seconds = @as(f32, @floatFromInt(world.step)) / 60.0 };
    if (options.promise) |promise| {
        if (world_mod.witness.Table.find(promise)) |id| {
            const seen = world.seen.get(id);
            last_visit.witnessed = true;
            last_visit.met = seen.met;
            last_visit.stayed_s = @as(f32, @floatFromInt(seen.held)) / 60.0;
        }
    }
    log("the {s}: {d} frames, {d} late, {d:.2} ms of work a frame (worst {d:.2}); {d} steps, {d} frames ran two; {d} calls, {d} answers; cues late {d}, refused {d}; slowest sound buffer {d:.2} ms; real-time sound {s}; most lines in a frame {d}", .{
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
    });
    for (world_mod.witness.names, 0..) |promise, i| {
        const seen = world.seen.marks[i];
        if (seen.met) log("witness {s} first={d} held={d}", .{ promise, seen.first, seen.held });
    }
    return plat.checkGl("the scene");
}
