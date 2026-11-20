//! remainder: a toy built to answer one question before any game is designed around it.
//! Does steering by being slightly out of tune feel good in the hands, through this speaker,
//! on this screen?
//!
//! Besides running the toy, this file measures what a play session cannot tell by feel alone
//! (frame cost, audio gaps) and writes it, with what the player did, to a session log.
const std = @import("std");
const platform = @import("common").platform;
const world_mod = @import("world.zig");
const synth = @import("synth.zig");
const tuning = @import("tuning.zig");
const gfx = @import("gfx.zig");
const png = @import("common").png;
const font = @import("common").font;
const c = platform.c;
const sdl = platform.sdl;
const gl = platform.gl;
const log = platform.log;
const World = world_mod.World;

const Options = struct {
    /// No controller, no real-time pacing: play a scripted demo at a fixed 60 steps per second.
    headless: bool = false,
    windowed: bool = false,
    /// Stop after this many frames (0: run until asked to quit).
    frames: u32 = 0,
    demo: u8 = 0,
    pool: u8 = 0,
    dump_dir: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav_path: ?[*:0]const u8 = null,
    out_dir: [*:0]const u8 = "results",
    bench: bool = true,
    /// Water resolution: 1 full, 2 half, 0 decide from the benchmark.
    scale: u8 = 0,
};

fn parseOptions(argc: c_int, argv: [*][*:0]u8) ?Options {
    var options = Options{};
    const count: usize = @intCast(argc);
    var i: usize = 1;
    while (i < count) : (i += 1) {
        const arg = std.mem.span(argv[i]);
        const value: ?[*:0]u8 = if (i + 1 < count) argv[i + 1] else null;
        if (std.mem.eql(u8, arg, "--headless")) {
            options.headless = true;
        } else if (std.mem.eql(u8, arg, "--windowed")) {
            options.windowed = true;
        } else if (std.mem.eql(u8, arg, "--no-bench")) {
            options.bench = false;
        } else if (value == null) {
            return null;
        } else if (std.mem.eql(u8, arg, "--frames")) {
            options.frames = std.fmt.parseInt(u32, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--demo")) {
            options.demo = std.fmt.parseInt(u8, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--pool")) {
            options.pool = std.fmt.parseInt(u8, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--scale")) {
            options.scale = std.fmt.parseInt(u8, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--dump-every")) {
            options.dump_every = std.fmt.parseInt(u32, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--dump")) {
            options.dump_dir = value.?;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--wav")) {
            options.wav_path = value.?;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--out")) {
            options.out_dir = value.?;
            i += 1;
        } else {
            return null;
        }
    }
    return options;
}

const usage =
    \\remainder [options]
    \\  --out DIR         where the session log goes (default ./results)
    \\  --pool N          start in pool N (0 one place, 1 three places, 2 the wheel of twelve)
    \\  --scale N         water resolution: 1 full, 2 half (default: decided by the benchmark)
    \\  --no-bench        skip the two-second shader benchmark at start
    \\  --windowed        a 640x480 window instead of full screen
    \\  --headless        scripted demo, fixed time step, no controller (for checks on the laptop)
    \\  --demo N          which scripted demo to play when headless
    \\  --frames N        stop after N frames
    \\  --dump DIR        save a PNG of the frame every --dump-every frames (default 30)
    \\  --wav FILE        write the sound of a headless run to a WAV file
    \\
;

// ---------------------------------------------------------------- sound

var shared: synth.Shared = .{};
var voices: synth.Voices = .{};
var audio_channels: usize = 2;
var audio_period_us: u32 = 2667;
var audio_last: f64 = 0.0;
// written by the audio thread, read by the game thread
var audio_callbacks: u32 = 0;
var audio_gaps: u32 = 0;
var audio_worst_us: u32 = 0;

fn audioCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * audio_channels);
    const out: [*]f32 = @ptrCast(@alignCast(stream));
    voices.render(&shared, out[0 .. frames * audio_channels], frames, audio_channels);

    // A callback arriving more than two periods after the last one means the device ran dry.
    const t = platform.now();
    const count = @atomicLoad(u32, &audio_callbacks, .monotonic);
    if (count > 50) {
        const gap_us: u32 = @intFromFloat(@min((t - audio_last) * 1e6, 4e9));
        if (gap_us > audio_period_us * 2) @atomicStore(u32, &audio_gaps, @atomicLoad(u32, &audio_gaps, .monotonic) + 1, .monotonic);
        if (gap_us > @atomicLoad(u32, &audio_worst_us, .monotonic)) @atomicStore(u32, &audio_worst_us, gap_us, .monotonic);
    }
    audio_last = t;
    @atomicStore(u32, &audio_callbacks, count + 1, .monotonic);
}

fn openAudio() c.SDL_AudioDeviceID {
    var want = std.mem.zeroes(c.SDL_AudioSpec);
    want.freq = @intFromFloat(synth.sample_rate);
    want.format = c.AUDIO_F32SYS;
    want.channels = 2;
    want.samples = 128;
    want.callback = &audioCallback;
    var have = std.mem.zeroes(c.SDL_AudioSpec);
    const allowed = c.SDL_AUDIO_ALLOW_FREQUENCY_CHANGE | c.SDL_AUDIO_ALLOW_SAMPLES_CHANGE | c.SDL_AUDIO_ALLOW_CHANNELS_CHANGE;
    const device = sdl.OpenAudioDevice(null, 0, &want, &have, allowed);
    if (device == 0) {
        log("audio: none ({s})", .{std.mem.span(sdl.GetError())});
        return 0;
    }
    audio_channels = have.channels;
    voices.rate = @floatFromInt(have.freq);
    audio_period_us = @intFromFloat(@as(f64, @floatFromInt(have.samples)) / @as(f64, @floatFromInt(have.freq)) * 1e6);
    log("audio: {s}, {d} Hz, {d} channels, {d}-frame buffer ({d:.2} ms)", .{
        std.mem.span(sdl.GetCurrentAudioDriver()),
        have.freq,
        have.channels,
        have.samples,
        @as(f64, @floatFromInt(audio_period_us)) / 1000.0,
    });
    sdl.PauseAudioDevice(device, 0);
    return device;
}

/// What the player and each place should sound like right now.
fn publishSound(world: *const World) void {
    shared.set(0, @floatCast(world.playerHz()), 0.45);
    for (0..world_mod.max_places) |i| {
        if (i < world.count) {
            shared.set(1 + i, @floatCast(world.placeHz(i)), 0.55 * world.places[i].near);
        } else {
            shared.set(1 + i, 220.0, 0.0);
        }
    }
}

/// Mono 16-bit WAV, for listening to (or measuring) a headless run.
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
        var block: [1024]i16 = undefined;
        var done: usize = 0;
        while (done < samples.len) {
            const n: usize = @min(block.len, samples.len - done);
            for (0..n) |i| block[i] = @intFromFloat(std.math.clamp(samples[done + i], -1.0, 1.0) * 32767.0);
            _ = c.fwrite(&block, 2, n, self.file);
            done += n;
        }
        self.frames += @intCast(samples.len);
    }

    fn close(self: *Wav) void {
        const rate: u32 = @intFromFloat(synth.sample_rate);
        const bytes = self.frames * 2;
        var head: [44]u8 = undefined;
        @memcpy(head[0..4], "RIFF");
        std.mem.writeInt(u32, head[4..8], 36 + bytes, .little);
        @memcpy(head[8..16], "WAVEfmt ");
        std.mem.writeInt(u32, head[16..20], 16, .little);
        std.mem.writeInt(u16, head[20..22], 1, .little); // PCM
        std.mem.writeInt(u16, head[22..24], 1, .little); // mono
        std.mem.writeInt(u32, head[24..28], rate, .little);
        std.mem.writeInt(u32, head[28..32], rate * 2, .little);
        std.mem.writeInt(u16, head[32..34], 2, .little);
        std.mem.writeInt(u16, head[34..36], 16, .little);
        @memcpy(head[36..40], "data");
        std.mem.writeInt(u32, head[40..44], bytes, .little);
        _ = c.fseek(self.file, 0, c.SEEK_SET);
        _ = c.fwrite(&head, 1, head.len, self.file);
        _ = c.fclose(self.file);
    }
};

// ---------------------------------------------------------------- controls

/// One frame of what the hands did.
const Hands = struct {
    input: world_mod.Input = .{},
    toggle_numbers: bool = false,
    quit: bool = false,
};

/// The handheld's built-in controls, read through SDL's game-controller layer.
///
/// Thumb audit: the left thumb owns the left stick, the right thumb owns the right stick, and
/// everything that may be needed *while* steering is on the four shoulder buttons (index
/// fingers). The face buttons and Select only flip settings, never mid-steer.
const Pad = struct {
    handle: ?*c.SDL_GameController = null,
    held: [button_count]bool = @splat(false),
    quit_held_s: f32 = 0.0,

    const button_count = 12;

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

    fn button(handle: *c.SDL_GameController, which: c_int) bool {
        // face buttons by where they are, whatever the controller database calls them
        return platform.padButton(handle, which);
    }

    fn axis(handle: *c.SDL_GameController, which: c_int) f32 {
        return @as(f32, @floatFromInt(sdl.GameControllerGetAxis(handle, which))) / 32767.0;
    }

    /// Remove the slack around a stick's centre and rescale the rest to -1..1.
    fn stick(raw: f32) f32 {
        const dead = 0.10;
        const size = @abs(raw);
        if (size <= dead) return 0.0;
        const scaled = @min((size - dead) / (1.0 - dead), 1.0);
        return if (raw < 0.0) -scaled else scaled;
    }

    fn read(self: *Pad, dt: f32) Hands {
        const handle = self.handle orelse return .{};
        const down = [button_count]bool{
            button(handle, c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER), // R1: a fifth up
            button(handle, c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER), // L1: a fifth down
            axis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 0.5, // R2: an octave up
            axis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 0.5, // L2: an octave down
            button(handle, c.SDL_CONTROLLER_BUTTON_A), // bottom face button: home
            button(handle, c.SDL_CONTROLLER_BUTTON_B), // right face button: lean / peg
            button(handle, c.SDL_CONTROLLER_BUTTON_Y), // top face button: numbers
            button(handle, c.SDL_CONTROLLER_BUTTON_X), // left face button: paddle on / off
            button(handle, c.SDL_CONTROLLER_BUTTON_BACK), // Select: next pool
            button(handle, c.SDL_CONTROLLER_BUTTON_START),
            button(handle, c.SDL_CONTROLLER_BUTTON_DPAD_UP), // the whole pool an octave up
            button(handle, c.SDL_CONTROLLER_BUTTON_DPAD_DOWN), // the whole pool an octave down
        };
        var pressed: [button_count]bool = undefined;
        for (0..button_count) |i| pressed[i] = down[i] and !self.held[i];
        self.held = down;

        // Select + Start held together leaves; Select alone (on release of neither) changes pool.
        const leaving = down[8] and down[9];
        self.quit_held_s = if (leaving) self.quit_held_s + dt else 0.0;

        return .{
            .input = .{
                .lean = -stick(axis(handle, c.SDL_CONTROLLER_AXIS_RIGHTY)), // up is sharp
                .paddle_x = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTX)),
                .paddle_y = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTY)),
                .fifth_up = pressed[0],
                .fifth_down = pressed[1],
                .octave_up = pressed[2],
                .octave_down = pressed[3],
                .home = pressed[4],
                .toggle_mode = pressed[5],
                .toggle_paddle = pressed[7],
                .next_pool = pressed[8] and !down[9],
                .pool_up = pressed[10],
                .pool_down = pressed[11],
            },
            .toggle_numbers = pressed[6],
            .quit = self.quit_held_s > 0.6,
        };
    }
};

/// Scripted hands for headless runs, so the laptop can check what the handheld will show.
fn demoHands(demo: u8, frame: u32) Hands {
    const t = @as(f32, @floatFromInt(frame)) / 60.0;
    var input = world_mod.Input{};
    switch (demo) {
        // One place: lean sharp (carried out), let go (rest), lean flat (drawn in), let go.
        0 => {
            if (t >= 1.0 and t < 4.0) input.lean = 0.75;
            if (t >= 6.0 and t < 10.0) input.lean = -0.8;
        },
        // Three places: lean, walk a fifth, lean the other way, go up an octave.
        1 => {
            if (t >= 1.0 and t < 4.0) input.lean = 0.7;
            if (frame == 300) input.fifth_up = true;
            if (t >= 6.0 and t < 9.0) input.lean = -0.7;
            if (frame == 600) input.octave_up = true;
            if (t >= 11.0 and t < 13.0) input.lean = 0.6;
        },
        // The wheel: walk twelve fifths, one every three quarters of a second, then wait.
        // The comma is left over, and it carries the player.
        2 => {
            if (frame >= 60 and frame < 60 + 12 * 45 and (frame - 60) % 45 == 0) input.fifth_up = true;
        },
        // Peg mode: retune by hand until the first place stands still again.
        else => {
            if (frame == 30) input.toggle_mode = true;
            if (t >= 1.0 and t < 2.0) input.lean = 0.9;
            if (t >= 4.0 and t < 5.0) input.lean = -0.9;
        },
    }
    return .{ .input = input, .toggle_numbers = frame == 1 };
}

// ---------------------------------------------------------------- measuring

const Timing = struct {
    frames: u32 = 0,
    slow_frames: u32 = 0,
    interval_sum: f64 = 0.0,
    interval_max: f64 = 0.0,
    work_sum: f64 = 0.0,
    work_max: f64 = 0.0,

    fn add(self: *Timing, interval: f64, work: f64, expected: f64) void {
        self.frames += 1;
        self.interval_sum += interval;
        self.interval_max = @max(self.interval_max, interval);
        self.work_sum += work;
        self.work_max = @max(self.work_max, work);
        if (interval > expected * 1.5) self.slow_frames += 1;
    }

    fn report(self: *const Timing, label: []const u8) void {
        if (self.frames == 0) return;
        const n: f64 = @floatFromInt(self.frames);
        log("{s}: {d} frames, {d:.2} ms each (worst {d:.2}), {d} late; game work {d:.2} ms (worst {d:.2}); audio {d} callbacks, {d} gaps, worst gap {d:.2} ms", .{
            label,
            self.frames,
            self.interval_sum / n * 1000.0,
            self.interval_max * 1000.0,
            self.slow_frames,
            self.work_sum / n * 1000.0,
            self.work_max * 1000.0,
            @atomicLoad(u32, &audio_callbacks, .monotonic),
            @atomicLoad(u32, &audio_gaps, .monotonic),
            @as(f64, @floatFromInt(@atomicLoad(u32, &audio_worst_us, .monotonic))) / 1000.0,
        });
    }
};

/// Cost of the water shader in milliseconds per frame, at full and at half resolution, with
/// four patterns on screen (the most it ever draws).
fn benchWater(renderer: *gfx.Renderer) [2]f64 {
    var world = World.init(2);
    for (0..40) |_| world.step(.{ .lean = 0.5 }, 1.0 / 60.0);
    var result: [2]f64 = undefined;
    for ([_]u8{ 1, 2 }, 0..) |scale, slot| {
        renderer.scale = scale;
        for (0..4) |_| {
            renderer.drawWater(&world, 0.0);
            gl.Finish();
        }
        const rounds = 30;
        const start = platform.now();
        for (0..rounds) |i| {
            world.step(.{ .lean = 0.5 }, 1.0 / 60.0);
            renderer.drawWater(&world, @floatFromInt(i));
            gl.Finish();
        }
        result[slot] = (platform.now() - start) / rounds * 1000.0;
    }
    return result;
}

fn logEvents(world: *World) void {
    var events: [64]world_mod.Event = undefined;
    const n = world.drainEvents(&events);
    for (events[0..n]) |event| {
        switch (event.kind) {
            .pool => log("t={d:.1} pool {s}", .{ event.time, world_mod.pool_names[@intCast(event.value)] }),
            .mode => log("t={d:.1} mode {s}", .{ event.time, if (event.value == 0) "lean" else "peg" }),
            .paddle => log("t={d:.1} paddle {s}", .{ event.time, if (event.value != 0) "on" else "off" }),
            .home => log("t={d:.1} home", .{event.time}),
            .fifth => log("t={d:.1} fifths walked {d}", .{ event.time, event.value }),
            .octave => log("t={d:.1} player register {d}", .{ event.time, event.value }),
            .register => log("t={d:.1} pool register {d} ({d:.0} Hz)", .{ event.time, event.value, world.placeHz(0) }),
            .bloom => log("t={d:.1} place {d} came to rest (peg at {d:.2} cents, {s} mode)", .{
                event.time,
                event.value,
                event.cents,
                if (world.mode == .lean) "lean" else "peg",
            }),
        }
    }
}

// ---------------------------------------------------------------- labels

/// One line, bottom left. With numbers on, three more lines top left for whoever is tuning
/// the toy rather than playing it.
fn drawLabels(renderer: *gfx.Renderer, world: *const World, numbers: bool, frame_ms: f64) void {
    var buf: [160]u8 = undefined;
    const quiet = gfx.faded(gfx.verbena, 0.75);
    const line = std.fmt.bufPrint(&buf, "{s}  {s}{s}", .{
        if (world.mode == .lean) "LEAN" else "PEG",
        world_mod.pool_names[world.pool],
        if (world.paddle) "" else "  ADRIFT",
    }) catch "";
    const panel = gfx.faded(gfx.void_black, 0.62);
    const bottom = world_mod.pool_h - 14.0 - font.ch;
    renderer.rect(10.0, bottom - 2.0, gfx.Renderer.textWidth(line) + 10.0, font.ch + 2.0, panel);
    renderer.text(16.0, bottom, quiet, line);
    if (!numbers) return;
    renderer.rect(10.0, 8.0, 46.0 * (font.cw + 3.0), 3 * font.ch + 6.0, panel);

    var tone = tuning.fold(world.base_cents + world.peg_cents + world.lean_cents);
    if (tone > 600.0) tone -= 1200.0;
    const first = std.fmt.bufPrint(&buf, "TONE {s}{d:.1} C  FIFTHS {d}  {d:.0} HZ", .{
        if (tone < 0.0) "-" else "+",
        @abs(tone),
        world.fifths,
        world.playerHz(),
    }) catch "";
    renderer.text(16.0, 12.0, quiet, first);

    if (world.anchor) |index| {
        if (world.places[index].pair) |pair| {
            const second = std.fmt.bufPrint(&buf, "PLACE {d}  {d}:{d}  BEAT {s}{d:.2} HZ", .{
                index,
                pair.m,
                pair.n,
                if (pair.beat_hz < 0.0) "-" else "+",
                @abs(pair.beat_hz),
            }) catch "";
            renderer.text(16.0, 12.0 + font.ch, quiet, second);
        }
    } else {
        renderer.text(16.0, 12.0 + font.ch, quiet, "NO AGREEMENT");
    }

    const third = std.fmt.bufPrint(&buf, "{d:.1} MS  WATER 1/{d}  AUDIO GAPS {d}", .{
        frame_ms,
        renderer.scale,
        @atomicLoad(u32, &audio_gaps, .monotonic),
    }) catch "";
    renderer.text(16.0, 12.0 + 2 * font.ch, quiet, third);
}

// ---------------------------------------------------------------- main

var the_renderer: gfx.Renderer = undefined;

pub export fn main(argc: c_int, argv: [*][*:0]u8) c_int {
    const options = parseOptions(argc, argv) orelse {
        _ = c.fputs(usage, c.stderr);
        return 2;
    };

    // session log
    _ = c.mkdir(options.out_dir, 0o755);
    var stamp: [32]u8 = @splat(0);
    var clock = c.time(null);
    _ = c.strftime(&stamp, stamp.len, "%Y%m%d-%H%M%S", c.localtime(&clock));
    var path_buf: [512]u8 = undefined;
    if (std.mem.printSentinel(&path_buf, "{s}/remainder-{s}.txt", .{ std.mem.span(options.out_dir), std.mem.sliceTo(&stamp, 0) }, 0)) |path| {
        platform.log_file = c.fopen(path.ptr, "w");
    } else |_| {}
    log("# remainder toy, session {s}", .{std.mem.sliceTo(&stamp, 0)});

    if (!platform.loadSdl()) return 1;
    if (sdl.Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_JOYSTICK | c.SDL_INIT_GAMECONTROLLER) != 0) {
        log("SDL video: {s}", .{std.mem.span(sdl.GetError())});
        return 1;
    }
    defer sdl.Quit();
    const window = platform.openWindow(.{ .windowed = options.windowed or options.headless }) orelse return 1;
    const renderer = &the_renderer;
    if (!renderer.init(window.width, window.height)) return 1;

    // how much the water costs on this GPU, and whether to draw it at half resolution
    if (options.bench) {
        const ms = benchWater(renderer);
        log("water shader: {d:.2} ms at full resolution, {d:.2} ms at half", .{ ms[0], ms[1] });
        renderer.scale = if (ms[0] > 10.5) 2 else 1;
    }
    if (options.scale == 1 or options.scale == 2) renderer.scale = options.scale;
    log("water drawn at 1/{d} resolution", .{renderer.scale});

    // sound
    voices.init();
    var device: c.SDL_AudioDeviceID = 0;
    var wav: ?Wav = null;
    if (options.wav_path) |path| {
        wav = Wav.open(path);
    } else if (!options.headless) {
        if (sdl.Init(c.SDL_INIT_AUDIO) == 0) device = openAudio() else log("audio: none ({s})", .{std.mem.span(sdl.GetError())});
    }

    var pad = if (options.headless) Pad{} else Pad.open();
    var world = World.init(options.pool);
    var numbers = false;
    var frame: u32 = 0;
    var timing = Timing{};
    var window_timing = Timing{};
    var last_swap = platform.now();
    var last_report = last_swap;
    // The time one frame takes, measured from one buffer swap to the next. (The swap is where
    // the wait for the display happens, so the time from a swap to the top of the loop is
    // almost nothing.)
    var frame_dt: f64 = 1.0 / 58.5;
    var frame_ms: f64 = 16.7;
    var expected_interval: f64 = 1.0 / 58.5;
    var dump_pixels: ?[*]u8 = null;
    if (options.dump_dir) |dir| {
        _ = c.mkdir(dir, 0o755);
        dump_pixels = @ptrCast(c.malloc(@intCast(window.width * window.height * 4)));
    }
    var wav_block: [800]f32 = undefined;

    running: while (true) {
        const frame_start = platform.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) break :running;
        }

        // Fixed steps when headless; real elapsed time (within reason) on the handheld.
        const dt: f32 = if (options.headless) 1.0 / 60.0 else @floatCast(std.math.clamp(frame_dt, 1.0 / 240.0, 1.0 / 20.0));
        const hands = if (options.headless) demoHands(options.demo, frame) else pad.read(dt);
        if (hands.quit) break;
        if (hands.toggle_numbers) numbers = !numbers;

        world.step(hands.input, dt);
        publishSound(&world);
        logEvents(&world);
        if (wav) |*file| {
            voices.render(&shared, &wav_block, wav_block.len, 1);
            file.write(&wav_block);
        }

        renderer.drawWater(&world, @floatFromInt(frame % 977));
        renderer.drawMarks(&world);
        drawLabels(renderer, &world, numbers, frame_ms);
        renderer.flush();

        if (dump_pixels) |pixels| {
            if (frame % options.dump_every == 0) {
                const size: usize = @intCast(window.width * window.height * 4);
                renderer.readFrame(pixels[0..size]);
                var name: [512]u8 = undefined;
                if (std.mem.printSentinel(&name, "{s}/frame-{d:0>4}.png", .{ std.mem.span(options.dump_dir.?), frame }, 0)) |path| {
                    _ = png.writeFromGl(path.ptr, @intCast(window.width), @intCast(window.height), pixels[0..size]);
                } else |_| {}
            }
        }

        const work = platform.now() - frame_start;
        sdl.GL_SwapWindow(window.handle);
        const swapped = platform.now();
        const interval = swapped - last_swap;
        frame_dt = interval;
        last_swap = swapped;
        frame += 1;

        if (!options.headless and frame > 30) {
            // the display's own pace, learned from the first steady frames
            if (frame < 90) expected_interval += (interval - expected_interval) * 0.1;
            timing.add(interval, work, expected_interval);
            window_timing.add(interval, work, expected_interval);
            frame_ms += (interval * 1000.0 - frame_ms) * 0.05;
            if (swapped - last_report > 20.0) {
                window_timing.report("last 20 s");
                window_timing = .{};
                last_report = swapped;
            }
        }
        if (options.frames != 0 and frame >= options.frames) break;
    }

    if (!gfx.checkGl("end of session")) log("OpenGL reported errors during the session", .{});
    timing.report("whole session");
    log("played {d:.1} s; ended in pool {s}, {s} mode", .{
        world.time,
        world_mod.pool_names[world.pool],
        if (world.mode == .lean) "lean" else "peg",
    });
    if (device != 0) sdl.CloseAudioDevice(device);
    if (wav) |*file| file.close();
    if (platform.log_file) |file| _ = c.fclose(file);
    return 0;
}
