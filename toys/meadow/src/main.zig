//! meadow: a test of how much world this handheld can draw and how moving through it feels.
//! A seed-sized creature in a patch of meadow: run, jump, glide, bounce off mushroom caps.
//!
//! At start it times each layer of the picture on the GPU (a few seconds), then lets you play.
//! Everything it measures, and what the player did, goes to a session log.
const std = @import("std");
const common = @import("common");
const math = @import("math.zig");
const land = @import("land.zig");
const scene_mod = @import("scene.zig");
const player_mod = @import("player.zig");
const platform = common.platform;
const hud = common.hud;
const png = common.png;
const c = platform.c;
const sdl = platform.sdl;
const gl = platform.gl;
const log = platform.log;
const Vec3 = math.Vec3;
const Player = player_mod.Player;
const Camera = player_mod.Camera;

const Options = struct {
    headless: bool = false,
    windowed: bool = false,
    frames: u32 = 0,
    demo: u8 = 0,
    dump_dir: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    out_dir: [*:0]const u8 = "results",
    bench: bool = true,
    /// Multisampling for the whole screen (0 off, 4 typical).
    msaa: u8 = 0,
    /// Percent of full resolution for the 3D view; 0 lets the benchmark decide.
    scale: u8 = 0,
    /// Distance between grass blades in units; smaller is denser.
    spacing: f32 = 0.62,
    night: bool = false,
};

fn parseOptions(argc: c_int, argv: [*][*:0]u8) ?Options {
    var options = Options{};
    const count: usize = @intCast(argc);
    var i: usize = 1;
    while (i < count) : (i += 1) {
        const arg = std.mem.span(argv[i]);
        const value: ?[]const u8 = if (i + 1 < count) std.mem.span(argv[i + 1]) else null;
        if (std.mem.eql(u8, arg, "--headless")) {
            options.headless = true;
        } else if (std.mem.eql(u8, arg, "--windowed")) {
            options.windowed = true;
        } else if (std.mem.eql(u8, arg, "--no-bench")) {
            options.bench = false;
        } else if (std.mem.eql(u8, arg, "--night")) {
            options.night = true;
        } else if (value == null) {
            return null;
        } else {
            const text = value.?;
            if (std.mem.eql(u8, arg, "--frames")) {
                options.frames = std.fmt.parseInt(u32, text, 10) catch return null;
            } else if (std.mem.eql(u8, arg, "--demo")) {
                options.demo = std.fmt.parseInt(u8, text, 10) catch return null;
            } else if (std.mem.eql(u8, arg, "--msaa")) {
                options.msaa = std.fmt.parseInt(u8, text, 10) catch return null;
            } else if (std.mem.eql(u8, arg, "--scale")) {
                options.scale = std.fmt.parseInt(u8, text, 10) catch return null;
            } else if (std.mem.eql(u8, arg, "--spacing")) {
                options.spacing = std.fmt.parseFloat(f32, text) catch return null;
            } else if (std.mem.eql(u8, arg, "--dump-every")) {
                options.dump_every = std.fmt.parseInt(u32, text, 10) catch return null;
            } else if (std.mem.eql(u8, arg, "--dump")) {
                options.dump_dir = argv[i + 1];
            } else if (std.mem.eql(u8, arg, "--out")) {
                options.out_dir = argv[i + 1];
            } else {
                return null;
            }
            i += 1;
        }
    }
    return options;
}

const usage =
    \\meadow [options]
    \\  --out DIR        where the session log goes (default ./results)
    \\  --msaa N         multisample the screen N times (default 0)
    \\  --scale N        draw the 3D view at N percent of full resolution (default: decided by the benchmark)
    \\  --spacing X      distance between grass blades in units (default 0.62; smaller is denser)
    \\  --night          start at two in the morning
    \\  --no-bench       skip the benchmark at start
    \\  --windowed       a 640x480 window instead of full screen
    \\  --headless       scripted demo, fixed time step, no controller (for checks on the laptop)
    \\  --demo N         which scripted demo to play when headless
    \\  --frames N       stop after N frames
    \\  --dump DIR       save a PNG every --dump-every frames (default 30)
    \\
;

// ---------------------------------------------------------------- controls

const Hands = struct {
    input: player_mod.Input = .{},
    look_x: f32 = 0.0,
    look_y: f32 = 0.0,
    toggle_hour: bool = false,
    toggle_numbers: bool = false,
    next_scale: bool = false,
    recentre: bool = false,
    quit: bool = false,
};

/// Thumb audit: the left thumb moves, the right thumb looks, and the two things done *while*
/// moving and looking (jump / glide, dash) are on the shoulder buttons under the index fingers.
/// The bottom and right face buttons do the same for anyone who prefers them. The remaining
/// buttons only flip settings.
const Pad = struct {
    handle: ?*c.SDL_GameController = null,
    held: [button_count]bool = @splat(false),
    quit_held_s: f32 = 0.0,

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
        const dead = 0.12;
        const size = @abs(raw);
        if (size <= dead) return 0.0;
        const scaled = @min((size - dead) / (1.0 - dead), 1.0);
        return if (raw < 0.0) -scaled else scaled;
    }

    fn read(self: *Pad, dt: f32) Hands {
        const handle = self.handle orelse return .{};
        const down = [button_count]bool{
            button(handle, c.SDL_CONTROLLER_BUTTON_X), // left face button: noon / small hours
            button(handle, c.SDL_CONTROLLER_BUTTON_Y), // top face button: numbers
            button(handle, c.SDL_CONTROLLER_BUTTON_BACK), // Select: next resolution
            button(handle, c.SDL_CONTROLLER_BUTTON_START), // Start: camera behind the creature
            button(handle, c.SDL_CONTROLLER_BUTTON_RIGHTSTICK), // right stick click: same
        };
        var pressed: [button_count]bool = undefined;
        for (0..button_count) |i| pressed[i] = down[i] and !self.held[i];
        self.held = down;
        const leaving = down[2] and down[3];
        self.quit_held_s = if (leaving) self.quit_held_s + dt else 0.0;

        const look = stick(axis(handle, c.SDL_CONTROLLER_AXIS_RIGHTX));
        return .{
            .input = .{
                .move_x = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTX)),
                .move_y = stick(axis(handle, c.SDL_CONTROLLER_AXIS_LEFTY)),
                .jump = button(handle, c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) or button(handle, c.SDL_CONTROLLER_BUTTON_A),
                .dash = button(handle, c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER) or button(handle, c.SDL_CONTROLLER_BUTTON_B),
            },
            // a little curve, so small turns are easy and big ones still quick
            .look_x = look * @abs(look),
            .look_y = stick(axis(handle, c.SDL_CONTROLLER_AXIS_RIGHTY)),
            .toggle_hour = pressed[0],
            .toggle_numbers = pressed[1],
            .next_scale = pressed[2] and !down[3],
            .recentre = (pressed[3] and !down[2]) or pressed[4],
            .quit = self.quit_held_s > 0.6,
        };
    }
};

/// Scripted hands for headless runs.
fn demoHands(demo: u8, frame: u32) Hands {
    const t = @as(f32, @floatFromInt(frame)) / 60.0;
    var hands = Hands{ .toggle_numbers = frame == 1 };
    switch (demo) {
        // run up the path and into the grass, turning; jump now and then
        0 => {
            hands.input.move_y = -1.0;
            hands.input.move_x = 0.35 * @sin(t * 0.7);
            hands.look_x = 0.25 * @sin(t * 0.5);
            hands.input.jump = @mod(t, 3.0) > 2.6;
        },
        // stand still and turn the camera all the way round
        1 => {
            hands.look_x = 0.6;
            hands.look_y = 0.15 * @sin(t);
        },
        // dash, jump and hold to glide
        else => {
            hands.input.move_y = -1.0;
            hands.input.dash = true;
            hands.input.jump = @mod(t, 4.0) > 1.0;
            hands.look_y = if (t < 1.5) 0.3 else 0.0;
        },
    }
    return hands;
}

// ---------------------------------------------------------------- measuring

const Timing = struct {
    frames: u32 = 0,
    slow_frames: u32 = 0,
    interval_sum: f64 = 0.0,
    interval_max: f64 = 0.0,
    work_sum: f64 = 0.0,
    work_max: f64 = 0.0,
    triangles_sum: u64 = 0,
    draws_sum: u64 = 0,

    fn add(self: *Timing, interval: f64, work: f64, expected: f64, tally: scene_mod.Tally) void {
        self.frames += 1;
        self.interval_sum += interval;
        self.interval_max = @max(self.interval_max, interval);
        self.work_sum += work;
        self.work_max = @max(self.work_max, work);
        self.triangles_sum += tally.triangles;
        self.draws_sum += tally.draws;
        if (interval > expected * 1.5) self.slow_frames += 1;
    }

    fn report(self: *const Timing, label: []const u8) void {
        if (self.frames == 0) return;
        const n: f64 = @floatFromInt(self.frames);
        log("{s}: {d} frames, {d:.2} ms each (worst {d:.2}), {d} late; game and draw calls {d:.2} ms (worst {d:.2}); {d:.0} triangles in {d:.0} draws per frame", .{
            label,
            self.frames,
            self.interval_sum / n * 1000.0,
            self.interval_max * 1000.0,
            self.slow_frames,
            self.work_sum / n * 1000.0,
            self.work_max * 1000.0,
            @as(f64, @floatFromInt(self.triangles_sum)) / n,
            @as(f64, @floatFromInt(self.draws_sum)) / n,
        });
    }
};

const Cost = struct {
    ms: f64,
    tally: scene_mod.Tally,
};

/// Milliseconds per frame for one view, with every frame forced to finish on the GPU.
fn cost(scene: *scene_mod.Scene, view: *scene_mod.View) Cost {
    var tally = scene_mod.Tally{};
    for (0..3) |_| {
        view.time += 1.0 / 60.0;
        tally = scene.draw(view);
        gl.Finish();
    }
    const rounds = 24;
    const start = platform.now();
    for (0..rounds) |_| {
        view.time += 1.0 / 60.0;
        tally = scene.draw(view);
        gl.Finish();
    }
    return .{ .ms = (platform.now() - start) / rounds * 1000.0, .tally = tally };
}

fn poseView(things: *const land.Things, x: f32, z: f32, yaw: f32, pitch: f32, lift: f32, aspect: f32) scene_mod.View {
    var player = Player.init(things, x, z);
    player.pos.y += lift;
    player.yaw = yaw;
    var camera = Camera.init(&player);
    camera.pitch = pitch;
    if (lift > 1.0) camera.distance = 12.5;
    for (0..30) |_| camera.update(&player, things, 0.0, 0.0, 1.0 / 60.0);
    return .{
        .view = camera.view(),
        .proj = Camera.projection(aspect),
        .eye = camera.eye,
        .creature_pos = player.pos,
        .creature_model = player.model(),
        .time = 10.0,
    };
}

/// Time the picture layer by layer from two places: down in the grass, and gliding above it.
/// Returns the cost of the whole picture from the heavier of the two, at full resolution.
fn bench(scene: *scene_mod.Scene, things: *const land.Things, aspect: f32) f64 {
    const Layers = scene_mod.Layers;
    const none = Layers{ .sky = false, .ground = false, .solids = false, .grass = false, .creature = false, .water = false };
    const poses = [_]struct { name: []const u8, x: f32, z: f32, yaw: f32, pitch: f32, lift: f32 }{
        .{ .name = "in the grass", .x = 168.0, .z = 150.0, .yaw = 0.9, .pitch = 0.20, .lift = 0.0 },
        .{ .name = "gliding above it", .x = 150.0, .z = 190.0, .yaw = 0.8, .pitch = 0.42, .lift = 20.0 },
    };
    var worst: f64 = 0.0;
    const keep_scale = scene.scale;
    for (poses) |pose| {
        var view = poseView(things, pose.x, pose.z, pose.yaw, pose.pitch, pose.lift, aspect);
        scene.scale = 100;

        view.layers = none;
        view.layers.sky = true;
        const sky = cost(scene, &view);
        view.layers.ground = true;
        const ground = cost(scene, &view);
        view.layers.solids = true;
        const solids = cost(scene, &view);
        view.layers.grass = true;
        const grass = cost(scene, &view);
        view.layers = .{};
        const all = cost(scene, &view);
        view.grass_passes = 2;
        const twice = cost(scene, &view);
        view.grass_passes = 4;
        const four = cost(scene, &view);
        view.grass_passes = 1;
        log("bench, {s}: sky {d:.2} | + ground {d:.2} | + stones, plants, tree {d:.2} | + grass {d:.2} | everything {d:.2} ms ({d} triangles, {d} draws)", .{
            pose.name, sky.ms, ground.ms, solids.ms, grass.ms, all.ms, all.tally.triangles, all.tally.draws,
        });
        log("bench, {s}: grass twice as dense {d:.2} ms ({d} triangles) | four times {d:.2} ms ({d} triangles)", .{
            pose.name, twice.ms, twice.tally.triangles, four.ms, four.tally.triangles,
        });
        worst = @max(worst, all.ms);

        var line: [160]u8 = undefined;
        var used: usize = 0;
        for ([_]u8{ 75, 50 }) |percent| {
            if (!scene.setScale(percent)) continue;
            const scaled = cost(scene, &view);
            const part = std.fmt.bufPrint(line[used..], " | at {d}% resolution {d:.2} ms", .{ percent, scaled.ms }) catch "";
            used += part.len;
        }
        log("bench, {s}: everything at 100% {d:.2} ms{s}", .{ pose.name, all.ms, line[0..used] });
    }

    // raw geometry: every blade in the meadow at once, seen from high above (small triangles)
    scene.scale = 100;
    const keep_far = scene.grass_far;
    scene.grass_far = 4000.0;
    const keep_thin = scene.grass_thin;
    scene.grass_thin = 8000.0;
    var high = poseView(things, 160.0, 160.0, 0.0, 1.2, 260.0, aspect);
    high.eye = Vec3.init(160.0, land.groundHeight(160.0, 160.0) + 330.0, 200.0);
    high.view = math.Mat4.lookAt(high.eye, Vec3.init(160.0, 0.0, 150.0), Vec3.init(0.0, 1.0, 0.0));
    high.layers = none;
    high.layers.grass = true;
    const field = cost(scene, &high);
    high.grass_passes = 3;
    const field3 = cost(scene, &high);
    scene.grass_far = keep_far;
    scene.grass_thin = keep_thin;
    const extra_ms = @max(field3.ms - field.ms, 0.001);
    const extra_tris: f64 = @floatFromInt(field3.tally.triangles - field.tally.triangles);
    log("bench, geometry: {d} small triangles {d:.2} ms; {d} triangles {d:.2} ms: about {d:.1} million triangles a second", .{
        field.tally.triangles, field.ms, field3.tally.triangles, field3.ms, extra_tris / extra_ms / 1000.0,
    });
    _ = scene.setScale(keep_scale);
    return worst;
}

// ---------------------------------------------------------------- labels

fn drawLabels(scene: *const scene_mod.Scene, night: f32, numbers: bool, frame_ms: f64, tally: scene_mod.Tally, samples: c.GLint) void {
    var buf: [160]u8 = undefined;
    const ink = hud.Color{ 0.886, 0.839, 0.784, 0.85 };
    const panel = hud.Color{ 0.04, 0.04, 0.04, 0.45 };
    const label: []const u8 = if (night > 0.5) "2AM" else "NOON";
    const bottom = hud.height - 14.0 - hud.line;
    hud.rect(10.0, bottom - 2.0, hud.textWidth(label) + 10.0, hud.line + 2.0, panel);
    hud.text(16.0, bottom, ink, label);
    if (!numbers) return;
    const first = std.fmt.bufPrint(&buf, "{d:.1} MS  {d} TRIANGLES  {d} DRAWS", .{ frame_ms, tally.triangles, tally.draws }) catch "";
    const second = std.fmt.bufPrint(buf[80..], "VIEW {d}%  MSAA {d}", .{ scene.scale, samples }) catch "";
    hud.rect(10.0, 8.0, @max(hud.textWidth(first), hud.textWidth(second)) + 12.0, 2.0 * hud.line + 6.0, panel);
    hud.text(16.0, 12.0, ink, first);
    hud.text(16.0, 12.0 + hud.line, ink, second);
}

// ---------------------------------------------------------------- main

var the_scene: scene_mod.Scene = .{};

pub export fn main(argc: c_int, argv: [*][*:0]u8) c_int {
    const options = parseOptions(argc, argv) orelse {
        _ = c.fputs(usage, c.stderr);
        return 2;
    };
    const gpa = std.heap.c_allocator;

    // session log
    _ = c.mkdir(options.out_dir, 0o755);
    var stamp: [32]u8 = @splat(0);
    var clock = c.time(null);
    _ = c.strftime(&stamp, stamp.len, "%Y%m%d-%H%M%S", c.localtime(&clock));
    var path_buf: [512]u8 = undefined;
    if (std.mem.printSentinel(&path_buf, "{s}/meadow-{s}.txt", .{ std.mem.span(options.out_dir), std.mem.sliceTo(&stamp, 0) }, 0)) |path| {
        platform.log_file = c.fopen(path.ptr, "w");
    } else |_| {}
    log("# meadow toy, session {s}", .{std.mem.sliceTo(&stamp, 0)});

    if (!platform.loadSdl()) return 1;
    if (sdl.Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS | c.SDL_INIT_JOYSTICK | c.SDL_INIT_GAMECONTROLLER) != 0) {
        log("SDL video: {s}", .{std.mem.span(sdl.GetError())});
        return 1;
    }
    defer sdl.Quit();
    const window = platform.openWindow(.{
        .windowed = options.windowed or options.headless,
        .depth_bits = 24,
        .samples = options.msaa,
    }) orelse return 1;
    var samples: c.GLint = 0;
    var depth_bits: c.GLint = 0;
    gl.GetIntegerv(c.GL_SAMPLES, &samples);
    gl.GetIntegerv(c.GL_DEPTH_BITS, &depth_bits);
    log("screen: {d}x{d}, depth {d} bits, {d} samples per pixel", .{ window.width, window.height, depth_bits, samples });

    const things = land.Things.generate(1);
    const scene = &the_scene;
    const build_start = platform.now();
    if (!scene.init(gpa, window.width, window.height, &things, options.spacing)) return 1;
    if (!hud.init()) return 1;
    log("meadow: {d} blades of grass, {d} stones, {d} plants, {d} triangles in all; built in {d:.2} s", .{
        scene.blade_count, things.stone_count, things.plant_count, scene.world_triangles, platform.now() - build_start,
    });
    const aspect = @as(f32, @floatFromInt(window.width)) / @as(f32, @floatFromInt(window.height));

    if (options.bench) {
        const full_ms = bench(scene, &things, aspect);
        // a 58.5 Hz frame is 17.1 ms; leave room for the game itself and for a hot day
        _ = scene.setScale(if (full_ms > 13.0) 75 else 100);
    }
    if (options.scale != 0) _ = scene.setScale(options.scale);
    log("3D view drawn at {d}% resolution", .{scene.scale});

    var pad = if (options.headless) Pad{} else Pad.open();
    var player = Player.init(&things, 152.0, 176.0);
    player.yaw = 0.9;
    if (options.headless and options.demo == 2) player = Player.init(&things, 150.0, 190.0);
    var camera = Camera.init(&player);
    var night_target: f32 = if (options.night) 1.0 else 0.0;
    var night: f32 = night_target;
    var numbers = false;
    var frame: u32 = 0;
    var time: f32 = 0.0;
    var timing = Timing{};
    var window_timing = Timing{};
    var last_swap = platform.now();
    var last_report = last_swap;
    // The time one frame takes, measured from one buffer swap to the next. (The swap is where
    // the wait for the display happens, so the time from a swap to the top of the loop is
    // almost nothing.)
    var frame_dt: f64 = 1.0 / 58.5;
    var frame_ms: f64 = 17.1;
    var expected_interval: f64 = 1.0 / 58.5;
    var tally = scene_mod.Tally{};
    // what the player did, for the log
    var jumps: u32 = 0;
    var glides: u32 = 0;
    var bounces: u32 = 0;
    var air_s: f32 = 0.0;
    var glide_s: f32 = 0.0;
    var travelled: f32 = 0.0;
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
        }

        const dt: f32 = if (options.headless) 1.0 / 60.0 else @floatCast(std.math.clamp(frame_dt, 1.0 / 240.0, 1.0 / 20.0));
        const hands = if (options.headless) demoHands(options.demo, frame) else pad.read(dt);
        if (hands.quit) break;
        if (hands.toggle_numbers) numbers = !numbers;
        if (hands.toggle_hour) {
            night_target = 1.0 - night_target;
            log("t={d:.1} hour: {s}", .{ time, if (night_target > 0.5) "2am" else "noon" });
        }
        if (hands.next_scale) {
            _ = scene.setScale(switch (scene.scale) {
                100 => 75,
                75 => 50,
                else => 100,
            });
            log("t={d:.1} 3D view at {d}%", .{ time, scene.scale });
        }
        if (hands.recentre) camera.yaw = player.yaw;

        const before = player.pos;
        player.step(&things, hands.input, camera.yaw, dt);
        camera.update(&player, &things, hands.look_x, hands.look_y, dt);
        time += dt;
        night = math.approach(night, night_target, 0.5, dt);
        travelled += @sqrt((player.pos.x - before.x) * (player.pos.x - before.x) + (player.pos.z - before.z) * (player.pos.z - before.z));
        if (!player.grounded) air_s += dt;
        if (player.gliding) glide_s += dt;
        var events: [16]player_mod.Event = undefined;
        for (events[0..player.drainEvents(&events)]) |happening| {
            switch (happening.kind) {
                .jump => jumps += 1,
                .glide => glides += 1,
                .bounce => bounces += 1,
                else => {},
            }
        }

        var lag = player.vel.scale(-0.035);
        const lag_size = lag.length();
        if (lag_size > 0.55) lag = lag.scale(0.55 / lag_size);
        var view = scene_mod.View{
            .view = camera.view(),
            .proj = Camera.projection(aspect),
            .eye = camera.eye,
            .creature_pos = player.pos,
            .creature_model = player.model(),
            .creature_lag = lag,
            .time = time,
            .night = night,
        };
        tally = scene.draw(&view);
        drawLabels(scene, night, numbers, frame_ms, tally, samples);
        hud.flush(window.width, window.height);

        if (dump_pixels) |pixels| {
            if (frame % options.dump_every == 0) {
                const size: usize = @intCast(window.width * window.height * 4);
                scene.readFrame(pixels[0..size]);
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
            if (frame < 90) expected_interval += (interval - expected_interval) * 0.1;
            timing.add(interval, work, expected_interval, tally);
            window_timing.add(interval, work, expected_interval, tally);
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
    log("played {d:.1} s: ran {d:.0} units, {d} jumps, {d} glides ({d:.1} s gliding), {d} mushroom bounces, {d:.1} s in the air", .{
        time, travelled, jumps, glides, glide_s, bounces, air_s,
    });
    if (platform.log_file) |file| _ = c.fclose(file);
    return 0;
}
