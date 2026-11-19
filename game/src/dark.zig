//! The dark and the call: the first minute of the first evening, as far as the workshop goes.
//!
//! Black. You call (R1) and a ring of light runs out over the ground. It lights what it passes,
//! and whatever is kin to your note answers, late by its distance. Hold R2 and Hum hums.
//!
//! The loop here is the game's loop (spec/engine.md): the sound card's sample count is the only
//! clock, a step of the world is 800 samples, and each frame runs the steps that are due. With no
//! sound card (a run with no screen) the loop renders the sound itself, one step at a time.
const std = @import("std");
const plat = @import("plat/plat.zig");
const png = @import("plat/png.zig");
const lines = @import("draw/lines.zig");
const m = @import("m.zig");
const world_mod = @import("world/world.zig");
const sound_mod = @import("sound/sound.zig");
const Script = @import("bot/script.zig").Script;
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

/// A note's colour: by fifths round the wheel, green at the garden's own note, sharps warming
/// and flats cooling, purple straight across (design/look.md).
fn noteColour(hz: f32) [3]f32 {
    const steps = 12.0 * @log2(hz / world_mod.garden_hz);
    const pc: i32 = @mod(@as(i32, @intFromFloat(@round(steps))), 12);
    const fifths: usize = @intCast(@mod(pc * 7, 12));
    const hues = [12]f32{ 120.0, 90.0, 60.0, 30.0, 0.0, 330.0, 285.0, 265.0, 235.0, 205.0, 180.0, 150.0 };
    const h = hues[fifths] / 60.0;
    const x = 1.0 - @abs(@mod(h, 2.0) - 1.0);
    const sector: i32 = @intFromFloat(h);
    const rgb: [3]f32 = switch (sector) {
        0 => .{ 1.0, x, 0.0 },
        1 => .{ x, 1.0, 0.0 },
        2 => .{ 0.0, 1.0, x },
        3 => .{ 0.0, x, 1.0 },
        4 => .{ x, 0.0, 1.0 },
        else => .{ 1.0, 0.0, x },
    };
    // a quarter of the way to white, so no colour is harsh
    return .{ 0.25 + 0.75 * rgb[0], 0.25 + 0.75 * rgb[1], 0.25 + 0.75 * rgb[2] };
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

/// Every thing as a stalk, a ring for a head and three spokes. Its body number is its place in
/// the world's list plus one; body nought is always fully lit.
fn thingLines(w: *const World, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.things[0..w.thing_count], 0..) |thing, index| {
        const body: f32 = @floatFromInt(index + 1);
        const colour = col8(noteColour(thing.hz), 1.0);
        const r = 0.5 + 60.0 / thing.hz * 2.0; // lower notes have bigger heads
        const top = thing.tall;
        out[n] = .{ .a = .{ thing.x, 0.0, thing.z }, .b = .{ thing.x, top, thing.z }, .half_width = 1.3, .body = body, .col = colour };
        n += 1;
        for (0..8) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
            out[n] = .{
                .a = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z },
                .b = .{ thing.x + r * @cos(a1), top + r * @sin(a1), thing.z },
                .half_width = 1.4,
                .body = body,
                .col = colour,
            };
            n += 1;
        }
        for (0..3) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 3.0) + 0.5;
            out[n] = .{ .a = .{ thing.x, top, thing.z }, .b = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z }, .half_width = 1.1, .body = body, .col = colour };
            n += 1;
        }
    }
    return n;
}

/// What changes every frame: the rings, and Hum.
fn movingLines(w: *const World, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.rings) |ring| {
        if (!ring.live) continue;
        const age: f32 = @floatFromInt(w.step - ring.born);
        const reach = age * world_mod.dt * world_mod.sound_speed;
        const fade = std.math.clamp(1.0 - reach / 140.0, 0.0, 1.0);
        const colour = col8(bone, 0.85 * fade * fade);
        const parts = 64;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ ring.x + reach * @cos(a0), 0.05, ring.z + reach * @sin(a0) },
                .b = .{ ring.x + reach * @cos(a1), 0.05, ring.z + reach * @sin(a1) },
                .half_width = 1.5,
                .body = 0.0,
                .col = colour,
            };
            n += 1;
        }
    }
    // Hum: a small bone-white shape. Its outline swells while it sings.
    const size: f32 = if (w.singing) 0.75 else 0.5;
    const hum_colour = col8(bone, 1.0);
    for (0..10) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
        out[n] = .{
            .a = .{ w.hum_x + size * @cos(a0), 0.5 + size * @sin(a0), w.hum_z },
            .b = .{ w.hum_x + size * @cos(a1), 0.5 + size * @sin(a1), w.hum_z },
            .half_width = 1.8,
            .body = 0.0,
            .col = hum_colour,
        };
        n += 1;
    }
    // two dark eyes would need a solid body; for now, a line for which way it faces
    out[n] = .{
        .a = .{ w.hum_x, 0.5, w.hum_z },
        .b = .{ w.hum_x + 0.9 * @sin(w.hum_face), 0.5, w.hum_z - 0.9 * @cos(w.hum_face) },
        .half_width = 1.2,
        .body = 0.0,
        .col = hum_colour,
    };
    n += 1;
    return n;
}

const backlight_path = "/sys/class/backlight/backlight/brightness";

/// The backlight is the sun: nearly off in the dark, up with whatever is shining.
const Backlight = struct {
    level: f32 = 14.0,
    written: i32 = -1,

    fn follow(self: *Backlight, light: f32) void {
        const want = 14.0 + 150.0 * std.math.clamp(light, 0.0, 1.0);
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

pub const Options = struct {
    headless: bool = false,
    frames: u32 = 0,
    dump: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav: ?[*:0]const u8 = null,
    /// Real sound and the real clock, but the scripted hands: for measuring on the handheld.
    bot: bool = false,
};

var world: World = undefined;
var static_lines: [world_mod.max_things * per_thing]lines.Inst = undefined;
var moving: [world_mod.max_rings * 64 + 32]lines.Inst = undefined;

pub fn run(window: plat.Window, options: Options) bool {
    var renderer: lines.Renderer = undefined;
    if (!renderer.init(window.width, window.height)) return false;
    renderer.base = .{ 0.0, 0.0, 0.0 };
    renderer.keep = 0.82;
    renderer.fade = 70.0;

    world = World.init();
    snd.init();
    const static_n = thingLines(&world, &static_lines);
    renderer.setLand(static_lines[0..static_n], static_lines[0..0], &.{});

    const pixels: []u8 = blk: {
        const n: usize = @intCast(window.width * window.height * 4);
        const p: [*]u8 = @ptrCast(c.malloc(n) orelse return false);
        break :blk p[0..n];
    };
    var loud: [lines.max_bodies]u8 = @splat(0);
    loud[0] = 255;

    const device: c.SDL_AudioDeviceID = if (options.headless) 0 else openAudio();
    defer if (device != 0) sdl.CloseAudioDevice(device);
    var wav: ?Wav = if (options.wav) |path| Wav.open(path) else null;
    const pad = if (options.headless) Pad{} else Pad.open();
    var script = Script{};
    var backlight = Backlight{};
    var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
    var buf: [world_mod.samples_per_step]f32 = undefined;

    const aspect = @as(f32, @floatFromInt(window.width)) / @as(f32, @floatFromInt(window.height));
    const proj = m.perspective(50.0, aspect, 0.3, 400.0);
    var frame: u32 = 0;
    var late: u32 = 0;
    var steps_run: u64 = 0;
    var double_steps: u32 = 0;
    var refused: u32 = 0;
    var leaving: u32 = 0;
    var work_sum: f64 = 0.0;
    var last_swap = plat.now();
    var running = true;
    log("the dark: R1 calls, R2 hums, the left stick walks; Select and Start together leave", .{});

    while (running) : (frame += 1) {
        const began = plat.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
        }

        // the steps that are due
        if (device == 0) {
            const hands = script.hands(world.step);
            const n = world.stepOnce(hands, &cues);
            for (cues[0..n]) |cue| {
                if (!snd.push(cue)) refused += 1;
            }
            snd.render(&buf);
            if (wav) |*w| w.write(&buf);
            steps_run += 1;
        } else {
            const hands = if (options.bot) script.hands(world.step) else pad.read();
            if (hands.held(Hands.select) and hands.held(Hands.start)) leaving += 1 else leaving = 0;
            if (leaving > 30) running = false;
            const due = snd.played() / world_mod.samples_per_step;
            var ran: u32 = 0;
            while (world.step < due and ran < 3) : (ran += 1) {
                const n = world.stepOnce(hands, &cues);
                for (cues[0..n]) |cue| {
                    if (!snd.push(cue)) refused += 1;
                }
                steps_run += 1;
            }
            if (ran > 1) double_steps += 1;
        }

        // the picture
        var brightest: f32 = 0.0;
        for (world.things[0..world.thing_count], 0..) |thing, i| {
            const light = World.light(thing);
            brightest = @max(brightest, light);
            loud[i + 1] = @intFromFloat(light * 255.0);
        }
        for (world.rings) |ring| {
            if (ring.live) brightest = @max(brightest, 0.5);
        }
        const moving_n = movingLines(&world, &moving);
        renderer.setDynamic(moving[0..moving_n]);
        const eye = m.V3{ world.hum_x, 40.0, world.hum_z + 36.0 };
        const view = m.lookAt(eye, .{ world.hum_x, 0.0, world.hum_z - 3.0 }, .{ 0.0, 1.0, 0.0 });
        const vp = m.mul(proj, view);
        renderer.frame(&vp, &loud);
        if (!options.headless) backlight.follow(brightest);
        work_sum += (plat.now() - began) * 1000.0;

        if (options.dump) |dir| {
            if (frame % options.dump_every == 0) {
                renderer.readFrame(pixels);
                var path: [512]u8 = undefined;
                if (std.mem.printSentinel(&path, "{s}/dark-{d:0>5}.png", .{ std.mem.span(dir), frame }, 0)) |text| {
                    _ = png.writeFromGl(text.ptr, @intCast(renderer.fb_w), @intCast(renderer.fb_h), pixels);
                } else |_| {}
            }
        }
        sdl.GL_SwapWindow(window.handle);
        const swapped = plat.now();
        if (frame > 30 and (swapped - last_swap) * 1000.0 > 25.0) late += 1;
        last_swap = swapped;
        if (options.frames > 0 and frame + 1 >= options.frames) running = false;
    }

    if (wav) |*w| w.close();
    log("the dark: {d} frames, {d} late, {d:.2} ms of work a frame; {d} steps, {d} frames ran two; {d} calls, {d} answers; cues late {d}, refused {d}; slowest sound buffer {d:.2} ms; real-time sound {s}", .{
        frame,
        late,
        work_sum / @as(f64, @floatFromInt(@max(frame, 1))),
        steps_run,
        double_steps,
        world.calls,
        world.answers,
        snd.late,
        refused + world.dropped,
        @as(f64, @floatFromInt(@atomicLoad(u32, &audio_slowest_us, .monotonic))) / 1000.0,
        if (@atomicLoad(i32, &audio_realtime, .monotonic) == 1) "yes" else "no",
    });
    return plat.checkGl("the dark");
}
