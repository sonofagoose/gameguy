//! wheel: a toy built to answer one question before any game is designed around the answer.
//! Does the wheel earn a place in a fight: in the hands, through this speaker, on this screen?
//!
//! Besides running the toy, this file writes what the player did (every strike, every close,
//! every walk, with how far each was from the beat) and how the device kept up to a session log.
const std = @import("std");
const platform = @import("common").platform;
const png = @import("common").png;
const world_mod = @import("world.zig");
const synth = @import("synth.zig");
const music = @import("music.zig");
const gfx = @import("gfx.zig");
const draw = @import("draw.zig");
const c = platform.c;
const sdl = platform.sdl;
const log = platform.log;
const World = world_mod.World;

const Options = struct {
    /// No controller, no real-time pacing: a scripted player at a fixed 60 steps a second.
    headless: bool = false,
    windowed: bool = false,
    /// The scripted player, but in real time with real sound: for measuring on the handheld.
    bot: bool = false,
    /// Stop after this many frames (0: run until asked to quit).
    frames: u32 = 0,
    /// Scenes to skip at the start (1 starts at dawn, 2 after the knots, 3 after the run).
    skip: u8 = 0,
    gentle: bool = false,
    dump_dir: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav_path: ?[*:0]const u8 = null,
    out_dir: [*:0]const u8 = "results",
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
        } else if (std.mem.eql(u8, arg, "--bot")) {
            options.bot = true;
        } else if (std.mem.eql(u8, arg, "--gentle")) {
            options.gentle = true;
        } else if (value == null) {
            return null;
        } else if (std.mem.eql(u8, arg, "--frames")) {
            options.frames = std.fmt.parseInt(u32, std.mem.span(value.?), 10) catch return null;
            i += 1;
        } else if (std.mem.eql(u8, arg, "--skip")) {
            options.skip = std.fmt.parseInt(u8, std.mem.span(value.?), 10) catch return null;
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
    \\wheel [options]
    \\  --out DIR         where the session log goes (default ./results)
    \\  --gentle          start in gentle: wider timing, and the wheel leans for you
    \\  --skip N          skip the first N scenes (1: start at dawn)
    \\  --windowed        a 640x480 window instead of full screen (keyboard: see the README)
    \\  --headless        a scripted player, fixed time step, no controller (for checks on the laptop)
    \\  --bot             the scripted player in real time, with sound (for measuring on the handheld)
    \\  --frames N        stop after N frames
    \\  --dump DIR        save a PNG of the frame every --dump-every frames (default 30)
    \\  --wav FILE        write the sound of a headless run to a WAV file
    \\
;

// ---------------------------------------------------------------- sound

var shared: synth.Shared = .{};
var engine: synth.Engine = .{};
var audio_channels: usize = 2;
var audio_period_us: u32 = 2667;
var audio_last: f64 = 0.0;
// written by the audio thread, read by the game thread
var audio_callbacks: u32 = 0;
var audio_gaps: u32 = 0;
var audio_worst_us: u32 = 0;
/// The longest the synth took to fill one buffer, and when and how long each gap was (the last
/// 32), so a gap can be told apart: the synth ran long, or the thread was kept waiting.
var audio_render_worst_us: u32 = 0;
/// -1 not asked yet, 0 refused, 1 granted: whether the sound thread runs ahead of everything
/// that is not real-time (the launcher has to raise the limit for it to be allowed).
var audio_realtime: i32 = -1;
var audio_realtime_said: bool = false;
var gap_clock: [32]f64 = @splat(0.0);
var gap_us_log: [32]u32 = @splat(0);
var gap_render_us_log: [32]u32 = @splat(0);

fn audioCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * audio_channels);
    const out: [*]f32 = @ptrCast(@alignCast(stream));
    if (@atomicLoad(i32, &audio_realtime, .monotonic) < 0) {
        // 0 means "this thread"
        var param = std.mem.zeroes(c.struct_sched_param);
        param.sched_priority = 30;
        const granted = c.sched_setscheduler(0, c.SCHED_FIFO, &param) == 0;
        @atomicStore(i32, &audio_realtime, if (granted) 1 else 0, .monotonic);
    }
    const began = platform.now();
    engine.render(&shared, out[0 .. frames * audio_channels], frames, audio_channels);

    // A callback arriving more than two periods after the last one means the device ran dry.
    const t = platform.now();
    const render_us: u32 = @intFromFloat(@min((t - began) * 1e6, 4e9));
    const count = @atomicLoad(u32, &audio_callbacks, .monotonic);
    if (count > 50) {
        if (render_us > @atomicLoad(u32, &audio_render_worst_us, .monotonic)) @atomicStore(u32, &audio_render_worst_us, render_us, .monotonic);
        const gap_us: u32 = @intFromFloat(@min((t - audio_last) * 1e6, 4e9));
        if (gap_us > audio_period_us * 2) {
            const n = @atomicLoad(u32, &audio_gaps, .monotonic);
            var wall: c.struct_timespec = undefined;
            _ = c.clock_gettime(c.CLOCK_REALTIME, &wall);
            gap_clock[n % 32] = @as(f64, @floatFromInt(wall.tv_sec)) + @as(f64, @floatFromInt(wall.tv_nsec)) * 1e-9;
            gap_us_log[n % 32] = gap_us;
            gap_render_us_log[n % 32] = render_us;
            @atomicStore(u32, &audio_gaps, n + 1, .monotonic);
        }
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
    engine.rate = @floatFromInt(have.freq);
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
/// Thumb audit: the left thumb moves. The right thumb strikes and dodges on the face buttons,
/// and goes to the right stick only while an index finger is holding R1 (time is thick) or R2
/// (the swell, during which there is nothing to strike). Nothing needs a stick and a face
/// button under the same thumb at once, and R1 and R2 are never held together.
const Pad = struct {
    handle: ?*c.SDL_GameController = null,
    held: [button_count]bool = @splat(false),
    quit_held_s: f32 = 0.0,
    skip_held_s: f32 = 0.0,
    skipped: bool = false,

    const button_count = 5;

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
        if (pad.handle == null) log("controls: no game controller found ({d} joysticks); keyboard only", .{count});
        return pad;
    }

    fn button(handle: *c.SDL_GameController, which: c_int) bool {
        return sdl.GameControllerGetButton(handle, which) != 0;
    }

    fn axis(handle: *c.SDL_GameController, which: c_int) f32 {
        return @as(f32, @floatFromInt(sdl.GameControllerGetAxis(handle, which))) / 32767.0;
    }

    /// Remove the slack around a stick's centre and rescale the rest to -1..1.
    fn stick(raw: f32) f32 {
        const dead = 0.12;
        const size = @abs(raw);
        if (size <= dead) return 0.0;
        const scaled = @min((size - dead) / (1.0 - dead), 1.0);
        return if (raw < 0.0) -scaled else scaled;
    }

    fn read(self: *Pad, dt: f32) Hands {
        const handle = self.handle orelse return .{};
        const down = [button_count]bool{
            button(handle, c.SDL_CONTROLLER_BUTTON_X), // left face button: strike
            button(handle, c.SDL_CONTROLLER_BUTTON_B), // right face button: dodge
            button(handle, c.SDL_CONTROLLER_BUTTON_Y), // top face button: numbers
            button(handle, c.SDL_CONTROLLER_BUTTON_BACK), // Select: gentle / plain
            button(handle, c.SDL_CONTROLLER_BUTTON_START), // held: skip the scene
        };
        var pressed: [button_count]bool = undefined;
        for (0..button_count) |i| pressed[i] = down[i] and !self.held[i];
        self.held = down;

        const leaving = down[3] and down[4];
        self.quit_held_s = if (leaving) self.quit_held_s + dt else 0.0;
        self.skip_held_s = if (down[4] and !down[3]) self.skip_held_s + dt else 0.0;
        var skip = false;
        if (self.skip_held_s > 1.0 and !self.skipped) {
            skip = true;
            self.skipped = true;
        }
        if (!down[4]) self.skipped = false;

        return .{
            .input = .{
                .move_x = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTX)),
                .move_y = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTY)),
                .aim_x = stick(axis(handle, c.SDL_CONTROLLER_AXIS_RIGHTX)),
                .aim_y = stick(axis(handle, c.SDL_CONTROLLER_AXIS_RIGHTY)),
                .r1 = button(handle, c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER),
                .r2 = axis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 0.5,
                .strike = pressed[0],
                .dodge = pressed[1],
                .gentle = pressed[3] and !down[4],
                .skip = skip,
            },
            .toggle_numbers = pressed[2],
            .quit = self.quit_held_s > 0.6,
        };
    }
};

/// A keyboard, for trying the toy in a window on the laptop.
const Keys = struct {
    down: [key_count]bool = @splat(false),
    pressed: [key_count]bool = @splat(false),

    const key_count = 16;
    const map = [key_count]c_int{
        c.SDLK_w,  c.SDLK_s,    c.SDLK_a,    c.SDLK_d, // move
        c.SDLK_UP, c.SDLK_DOWN, c.SDLK_LEFT, c.SDLK_RIGHT, // aim
        c.SDLK_u, c.SDLK_i, // R1, R2
        c.SDLK_j, c.SDLK_k, // strike, dodge
        c.SDLK_g, c.SDLK_n, c.SDLK_TAB, c.SDLK_ESCAPE, // gentle, skip, numbers, leave
    };

    fn event(self: *Keys, e: *const c.SDL_Event) void {
        if (e.type != c.SDL_KEYDOWN and e.type != c.SDL_KEYUP) return;
        for (map, 0..) |sym, i| {
            if (e.key.keysym.sym != sym) continue;
            const is_down = e.type == c.SDL_KEYDOWN;
            if (is_down and !self.down[i]) self.pressed[i] = true;
            self.down[i] = is_down;
        }
    }

    fn read(self: *Keys, into: *Hands) void {
        const d = self.down;
        const p = self.pressed;
        const f = struct {
            fn v(on: bool) f32 {
                return if (on) 1.0 else 0.0;
            }
        };
        into.input.move_x += f.v(d[3]) - f.v(d[2]);
        into.input.move_y += f.v(d[1]) - f.v(d[0]);
        into.input.aim_x += f.v(d[7]) - f.v(d[6]);
        into.input.aim_y += f.v(d[5]) - f.v(d[4]);
        into.input.r1 = into.input.r1 or d[8];
        into.input.r2 = into.input.r2 or d[9];
        into.input.strike = into.input.strike or p[10];
        into.input.dodge = into.input.dodge or p[11];
        into.input.gentle = into.input.gentle or p[12];
        into.input.skip = into.input.skip or p[13];
        into.toggle_numbers = into.toggle_numbers or p[14];
        into.quit = into.quit or d[15];
        self.pressed = @splat(false);
    }
};

/// A scripted player for headless runs: it reads the world and plays the toy through, so the
/// laptop can check what the handheld will show and sound like. It walks to Drip, breathes
/// with it, stands where the knots meet, strikes on the one, lets go on the one, and walks
/// three creatures home in one breath.
const Bot = struct {
    r1_frames: u32 = 0,
    aim_x: f32 = 0.0,
    aim_y: f32 = 0.0,
    wait: u32 = 0,
    struck_for: i64 = -100,
    stepped_at: f64 = -100.0,

    fn point(self: *Bot, note: music.Note) void {
        const a = @as(f32, @floatFromInt(music.noteWedge(note))) * std.math.pi / 6.0;
        self.aim_x = @sin(a);
        self.aim_y = -@cos(a);
        self.r1_frames = 40;
        self.wait = 70;
    }

    fn walkTo(w: *const World, in: *world_mod.Input, x: f32, y: f32, near: f32) bool {
        const dx = x - w.x;
        const dy = y - w.y;
        const d = @sqrt(dx * dx + dy * dy);
        if (d <= near) return true;
        in.move_x = dx / d;
        in.move_y = dy / d;
        return false;
    }

    fn strikeOn(self: *Bot, w: *const World, in: *world_mod.Input, target: *const world_mod.Creature) void {
        const frac = w.beat - @floor(w.beat);
        const next: i64 = @as(i64, @intFromFloat(@floor(w.beat))) + 1;
        if (frac > 0.72 and frac < 0.93 and self.struck_for != next and w.meets(target, next)) {
            in.strike = true;
            self.struck_for = next;
        }
    }

    fn play(self: *Bot, w: *const World, frame: u32) world_mod.Input {
        var in = world_mod.Input{};
        if (self.r1_frames > 0) {
            self.r1_frames -= 1;
            in.r1 = true;
            in.aim_x = self.aim_x;
            in.aim_y = self.aim_y;
            return in;
        }
        if (self.wait > 0) self.wait -= 1;
        const in_bar = @mod(w.beat, 4.0);
        const frac = w.beat - @floor(w.beat);

        switch (w.stage) {
            .dark_call => in.r1 = (frame >= 90 and frame < 94) or (frame >= 240 and frame < 244),
            .dark_find => _ = walkTo(w, &in, world_mod.drip_x - 34.0, world_mod.drip_y + 62.0, 8.0),
            .phase => in.r2 = frac > 0.3,
            .dawn, .waking => {},
            .knots, .run, .garden => {
                // the walk of three, when it is there to be made
                var a: ?*const world_mod.Creature = null;
                var others: usize = 0;
                var grey: ?*const world_mod.Creature = null;
                var nearest: ?*const world_mod.Creature = null;
                var best: f32 = 1e12;
                for (&w.creatures) |*cr| {
                    if (!cr.live()) continue;
                    if (cr.state == .grey) {
                        grey = cr;
                        continue;
                    }
                    if (!cr.knot and cr.note == 3) a = cr;
                    if (!cr.knot and (cr.note == 2 or cr.note == 1)) others += 1;
                    const dx = cr.x - w.x;
                    const dy = cr.y - w.y;
                    if (dx * dx + dy * dy < best) {
                        best = dx * dx + dy * dy;
                        nearest = cr;
                    }
                }
                if (w.stage == .run and w.swell and w.walk < 2 and (w.home == 2 or w.home == 1)) {
                    // in the swell: nudge left on the one
                    in.r2 = true;
                    if (in_bar > 3.95 or in_bar < 0.04) {
                        in.aim_x = -1.0;
                        self.stepped_at = w.beat;
                    }
                    return in;
                }
                if (w.swell) {
                    // let go on the one, but not the one it has only just stepped on
                    in.r2 = !(in_bar < 0.5 and w.swell_beats > 0.8 and w.beat - self.stepped_at > 2.0);
                    return in;
                }
                if (grey) |g| {
                    var want: music.Note = if (g.knot) World.meetingPlace(g) else music.fold(g.note - 1);
                    if (!w.isAwake(want)) want = music.fold(g.note + 1);
                    if (w.home != want) {
                        if (self.wait == 0 and w.pending == null) self.point(want);
                        return in;
                    }
                    _ = walkTo(w, &in, g.x, g.y, 120.0);
                    in.r2 = in_bar >= 3.0; // breathe in just before the one
                    return in;
                }
                const target = (if (w.stage == .run and others == 2) a else null) orelse nearest orelse return in;
                const want: music.Note = if (target.knot) World.meetingPlace(target) else if (w.stage == .run and others == 2 and a != null) 2 else target.note;
                if (w.home != want) {
                    if (self.wait == 0 and w.pending == null) self.point(want);
                    return in;
                }
                if (walkTo(w, &in, target.x, target.y, 52.0)) self.strikeOn(w, &in, target);
            },
        }
        return in;
    }
};

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
        log("{s}: {d} frames, {d:.2} ms each (worst {d:.2}), {d} late; game work {d:.2} ms (worst {d:.2}); audio {d} callbacks, {d} gaps, worst gap {d:.2} ms, slowest fill {d:.2} ms", .{
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
            @as(f64, @floatFromInt(@atomicLoad(u32, &audio_render_worst_us, .monotonic))) / 1000.0,
        });
    }
};

fn noteName(n: i32) []const u8 {
    const names = [12][]const u8{ "C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F" };
    return names[@intCast(@mod(n, 12))];
}

fn logEvents(world: *World) void {
    var events: [64]world_mod.Event = undefined;
    const n = world.drainEvents(&events);
    for (events[0..n]) |e| {
        switch (e.kind) {
            .stage => log("t={d:.1} scene: {s}", .{ e.time, @tagName(@as(world_mod.Stage, @enumFromInt(e.a))) }),
            .call => log("t={d:.1} call {d}", .{ e.time, e.a }),
            .in_phase => log("t={d:.1} in with Drip (last breath {d:.0} ms from its tick)", .{ e.time, e.b * 1000.0 }),
            .wheel => if (e.a == 1) log("t={d:.1} wheel opened", .{e.time}) else log("t={d:.1} wheel closed after {d:.2} s", .{ e.time, e.b }),
            .home => log("t={d:.1} home {s} (was {s})", .{ e.time, noteName(e.a), noteName(@intFromFloat(e.b)) }),
            .strike => log("t={d:.1} strike: rang {d}, on a meeting {d}{s}", .{ e.time, @divTrunc(e.a, 10), @mod(e.a, 10), if (e.b > 0.5) ", timed true" else "" }),
            .lash => log("t={d:.1} lashed by {s}; steadiness {d:.2}", .{ e.time, noteName(e.a), e.b }),
            .pocket => log("t={d:.1} pocket ({d:.0} ms from the beat)", .{ e.time, e.b * 1000.0 }),
            .grey => log("t={d:.1} {s} went grey", .{ e.time, noteName(e.a) }),
            .close => log("t={d:.1} {s} came home", .{ e.time, noteName(e.a) }),
            .amen => log("t={d:.1} {s} sung to sleep", .{ e.time, noteName(e.a) }),
            .plain => log("t={d:.1} let go with nothing beside home ({d} grey), {d:.0} ms from the one", .{ e.time, e.a, e.b * 1000.0 }),
            .soft => log("t={d:.1} let go off the one ({d:.0} ms): {s} landed softly", .{ e.time, e.b * 1000.0, noteName(e.a) }),
            .step => log("t={d:.1} stepped on the one past {s}; walk so far {d:.0}", .{ e.time, noteName(e.a), e.b }),
            .walk => log("t={d:.1} a walk of {d} landed, {d:.0} ms from the one", .{ e.time, e.a, e.b * 1000.0 }),
            .breath => {},
            .gentle => log("t={d:.1} {s}", .{ e.time, if (e.a == 1) "gentle" else "plain" }),
            .dusk => log("t={d:.1} shaken apart; they drew off", .{e.time}),
        }
    }
}

// ---------------------------------------------------------------- main

var the_renderer: gfx.Renderer = undefined;
var scratch: [4096]f32 = undefined;

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
    if (std.mem.printSentinel(&path_buf, "{s}/wheel-{s}.txt", .{ std.mem.span(options.out_dir), std.mem.sliceTo(&stamp, 0) }, 0)) |path| {
        platform.log_file = c.fopen(path.ptr, "w");
    } else |_| {}
    log("# wheel toy, session {s}", .{std.mem.sliceTo(&stamp, 0)});

    if (!platform.loadSdl()) return 1;
    if (sdl.Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_JOYSTICK | c.SDL_INIT_GAMECONTROLLER) != 0) {
        log("SDL video: {s}", .{std.mem.span(sdl.GetError())});
        return 1;
    }
    defer sdl.Quit();
    const window = platform.openWindow(.{ .windowed = options.windowed or options.headless }) orelse return 1;
    const renderer = &the_renderer;
    if (!renderer.init(window.width, window.height)) return 1;

    // sound
    engine.init();
    var world = World.init(&shared);
    world.gentle = options.gentle;
    var device: c.SDL_AudioDeviceID = 0;
    var wav: ?Wav = null;
    if (options.wav_path) |path| {
        wav = Wav.open(path);
    } else if (!options.headless) {
        if (sdl.Init(c.SDL_INIT_AUDIO) == 0) device = openAudio() else log("audio: none ({s})", .{std.mem.span(sdl.GetError())});
    }
    // With no audio device the clock still has to run: the game renders the sound itself and
    // throws it away.
    const clock_by_frame = options.headless or device == 0;

    var pad = if (options.headless) Pad{} else Pad.open();
    var keys = Keys{};
    var bot = Bot{};
    var view = draw.View{};
    var show_numbers = false;
    var skips_left = options.skip;
    var frame: u32 = 0;
    var timing = Timing{};
    var window_timing = Timing{};
    var last_swap = platform.now();
    var last_report = last_swap;
    var gaps_logged: u32 = 0;
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

    running: while (true) {
        const frame_start = platform.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) break :running;
            keys.event(&event);
        }

        // Fixed steps when headless; real elapsed time (within reason) on the handheld.
        const dt: f32 = if (options.headless) 1.0 / 60.0 else @floatCast(std.math.clamp(frame_dt, 1.0 / 240.0, 1.0 / 20.0));
        var hands: Hands = if (options.headless) .{ .input = bot.play(&world, frame) } else pad.read(dt);
        if (!options.headless) keys.read(&hands);
        if (options.bot) hands.input = bot.play(&world, frame); // the pad can still leave
        if (hands.quit) break;
        if (hands.toggle_numbers) show_numbers = !show_numbers;
        if (skips_left > 0 and frame % 20 == 10) {
            hands.input.skip = true;
            if (world.stage != .dawn and world.stage != .waking) skips_left -= 1;
        }

        world.step(hands.input, dt, shared.beat());
        logEvents(&world);
        if (!audio_realtime_said and @atomicLoad(i32, &audio_realtime, .monotonic) >= 0) {
            audio_realtime_said = true;
            if (@atomicLoad(i32, &audio_realtime, .monotonic) == 1) {
                log("sound thread: real-time priority", .{});
            } else {
                log("sound thread: ordinary priority (real-time was refused; the launcher raises the limit)", .{});
            }
        }
        // each gap in the sound, with the wall clock, so it can be matched against the device
        const gaps_now = @atomicLoad(u32, &audio_gaps, .monotonic);
        while (gaps_logged < gaps_now) : (gaps_logged += 1) {
            log("t={d:.1} sound gap of {d:.1} ms (that buffer took {d:.2} ms to fill) at clock {d:.3}", .{
                world.time,
                @as(f64, @floatFromInt(gap_us_log[gaps_logged % 32])) / 1000.0,
                @as(f64, @floatFromInt(gap_render_us_log[gaps_logged % 32])) / 1000.0,
                gap_clock[gaps_logged % 32],
            });
        }
        if (clock_by_frame) {
            var left: usize = @intFromFloat(@round(dt * synth.sample_rate));
            while (left > 0) {
                const n = @min(left, scratch.len);
                engine.render(&shared, scratch[0..n], n, 1);
                if (wav) |*file| file.write(scratch[0..n]);
                left -= n;
            }
        }

        draw.draw(renderer, &world, &view, dt);
        if (show_numbers) draw.numbers(renderer, &world, frame_ms, @atomicLoad(u32, &audio_gaps, .monotonic));
        renderer.flush();

        if (dump_pixels) |pixels| {
            if (frame % options.dump_every == 0) {
                const size: usize = @intCast(window.width * window.height * 4);
                renderer.readFrame(pixels[0..size]);
                var name: [512]u8 = undefined;
                if (std.mem.printSentinel(&name, "{s}/frame-{d:0>5}.png", .{ std.mem.span(options.dump_dir.?), frame }, 0)) |path| {
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

    if (!platform.checkGl("end of session")) log("OpenGL reported errors during the session", .{});
    timing.report("whole session");
    log("played {d:.1} s; ended in scene {s}; home {s}; wheel opened {d} times; {d} strikes; best walk {d}; breath holds {d:.0}", .{
        world.time,
        @tagName(world.stage),
        noteName(world.home),
        world.wheel_opens,
        world.strike_count,
        world.best_walk,
        world.breath_cap,
    });
    if (renderer.dropped > 0) log("{d} quads did not fit in a frame's batch", .{renderer.dropped});
    if (shared.dropped > 0) log("{d} notes did not fit in the sound queue", .{shared.dropped});
    if (device != 0) sdl.CloseAudioDevice(device);
    if (wav) |*file| file.close();
    if (platform.log_file) |file| _ = c.fclose(file);
    return 0;
}
