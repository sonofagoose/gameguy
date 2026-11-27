//! gameguy: the game.
//!
//! So far: the dark and the call (dark.zig), which is the first minute of the first evening, and
//! the benchmark that says how many lines of light a frame holds (`--lines`). Either can run with
//! no screen and dump its frames.
const std = @import("std");
const plat = @import("plat/plat.zig");
const png = @import("plat/png.zig");
const lines = @import("draw/lines.zig");
const black = @import("draw/black.zig");
const feel = @import("feel.zig");
const react = @import("law/react.zig");
const dark = @import("dark.zig");
const room = @import("room.zig");
const m = @import("m.zig");
const c = plat.c;
const sdl = plat.sdl;
const gl = plat.gl;
const log = plat.log;

const Args = struct {
    headless: bool = false,
    windowed: bool = false,
    scale: u8 = 1,
    walk_starts: ?[*:0]const u8 = null,
    bench_lines: bool = false,
    frames: u32 = 0,
    dump: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    log_path: ?[*:0]const u8 = null,
    wav: ?[*:0]const u8 = null,
    bot: bool = false,
    scene: dark.Scene = .evening,
    replay: ?[*:0]const u8 = null,
    load: ?[*:0]const u8 = null,
    keep: bool = false,
    resume_only: bool = false,
    picture: bool = true,
    without_trail: bool = false,
    without_ground: bool = false,
    half_land: bool = false,
    songbook: ?[*:0]const u8 = null,
    check_take: ?[*:0]const u8 = null,
    room: ?[*:0]const u8 = null,
    /// The try-out of design/the-game.md: L1 and L2 step the chord among the lift, home and the lean.
    chords: bool = false,
    /// Play as a walk of this name: the person's own kept game is left alone, and the take is
    /// written into results/walks/ under the name.
    walk: ?[*:0]const u8 = null,
    /// Only report which controller is found and where its face buttons are, then stop: no
    /// window, no sound, so it can be run over a cable without touching the screen.
    controls: bool = false,
};

fn parseArgs(argc: c_int, argv: [*][*:0]u8) Args {
    var args = Args{};
    var i: usize = 1;
    const n: usize = @intCast(argc);
    while (i < n) : (i += 1) {
        const a = std.mem.span(argv[i]);
        if (std.mem.eql(u8, a, "--headless")) {
            args.headless = true;
        } else if (std.mem.eql(u8, a, "--windowed")) {
            args.windowed = true;
        } else if (std.mem.eql(u8, a, "--scale") and i + 1 < n) {
            // a window this many times the handheld's screen
            i += 1;
            args.scale = std.fmt.parseInt(u8, std.mem.span(argv[i]), 10) catch 1;
        } else if (std.mem.eql(u8, a, "--lines")) {
            args.bench_lines = true;
        } else if (std.mem.eql(u8, a, "--controls")) {
            args.controls = true;
        } else if (std.mem.eql(u8, a, "--bot")) {
            args.bot = true;
        } else if (std.mem.eql(u8, a, "--chords")) {
            args.chords = true;
        } else if (std.mem.eql(u8, a, "--walk") and i + 1 < n) {
            i += 1;
            args.walk = argv[i];
        } else if (std.mem.eql(u8, a, "--keep")) {
            args.keep = true;
        } else if (std.mem.eql(u8, a, "--resume-only")) {
            args.resume_only = true;
        } else if (std.mem.eql(u8, a, "--no-picture")) {
            // for a check of the world alone: the steps and the sound, and nothing drawn
            args.picture = false;
        } else if (std.mem.eql(u8, a, "--songbook") and i + 1 < n) {
            // draw every page of the songbook into a folder, to look at
            i += 1;
            args.songbook = argv[i];
        } else if (std.mem.eql(u8, a, "--without") and i + 1 < n) {
            // for measuring what a part of the picture costs on the handheld: draw it without
            i += 1;
            const what = std.mem.span(argv[i]);
            if (std.mem.eql(u8, what, "trail")) args.without_trail = true;
            if (std.mem.eql(u8, what, "ground")) args.without_ground = true;
            if (std.mem.eql(u8, what, "half-land")) args.half_land = true;
        } else if (std.mem.eql(u8, a, "--check-take") and i + 1 < n) {
            i += 1;
            args.check_take = argv[i];
        } else if (std.mem.eql(u8, a, "--walk-starts") and i + 1 < n) {
            i += 1;
            args.walk_starts = argv[i];
        } else if (std.mem.eql(u8, a, "--load") and i + 1 < n) {
            i += 1;
            args.load = argv[i];
        } else if (std.mem.eql(u8, a, "--replay") and i + 1 < n) {
            i += 1;
            args.replay = argv[i];
        } else if (std.mem.eql(u8, a, "--scene") and i + 1 < n) {
            i += 1;
            args.scene = std.meta.stringToEnum(dark.Scene, std.mem.span(argv[i])) orelse .dark;
        } else if (std.mem.eql(u8, a, "--frames") and i + 1 < n) {
            i += 1;
            args.frames = std.fmt.parseInt(u32, std.mem.span(argv[i]), 10) catch 0;
        } else if (std.mem.eql(u8, a, "--dump") and i + 1 < n) {
            i += 1;
            args.dump = argv[i];
        } else if (std.mem.eql(u8, a, "--dump-every") and i + 1 < n) {
            i += 1;
            args.dump_every = std.fmt.parseInt(u32, std.mem.span(argv[i]), 10) catch 30;
        } else if (std.mem.eql(u8, a, "--log") and i + 1 < n) {
            i += 1;
            args.log_path = argv[i];
        } else if (std.mem.eql(u8, a, "--room") and i + 1 < n) {
            i += 1;
            args.room = argv[i];
        } else if (std.mem.eql(u8, a, "--wav") and i + 1 < n) {
            i += 1;
            args.wav = argv[i];
        } else if (std.mem.eql(u8, a, "--help")) {
            log("gameguy [--controls] [--lines] [--room DIR] [--chords] [--walk NAME] [--load SAVE] [--replay TAKE] [--bot] [--headless] [--windowed] [--frames N] [--dump DIR] [--dump-every N] [--wav FILE] [--log FILE]", .{});
        }
    }
    return args;
}

/// A small generator with no library behind it: the same land on every machine.
const Rand = struct {
    s: u32,
    fn next(self: *Rand) u32 {
        self.s ^= self.s << 13;
        self.s ^= self.s >> 17;
        self.s ^= self.s << 5;
        return self.s;
    }
    /// From 0 up to, not including, 1.
    fn unit(self: *Rand) f32 {
        return @as(f32, @floatFromInt(self.next() >> 8)) * (1.0 / 16777216.0);
    }
};

fn ground(x: f32, z: f32) f32 {
    return 6.0 * @sin(x * 0.021) * @cos(z * 0.017) + 3.0 * @sin(x * 0.05 + z * 0.043);
}

const half_field: f32 = 200.0;

/// A made-up piece of land for the benchmark: rolling ground drawn as lines both ways, bell-headed
/// stalks standing on it, and the ground itself as black triangles so that hills hide what is
/// behind them.
const Land = struct {
    sounding: []lines.Inst,
    lit: []lines.Inst,
    occ: [][3]f32,
    sounding_n: usize = 0,
    lit_n: usize = 0,
    occ_n: usize = 0,

    fn alloc(max_lines: usize, max_occ: usize) ?Land {
        const a: [*]lines.Inst = @ptrCast(@alignCast(c.malloc(max_lines * @sizeOf(lines.Inst)) orelse return null));
        const b: [*]lines.Inst = @ptrCast(@alignCast(c.malloc(max_lines * @sizeOf(lines.Inst)) orelse return null));
        const o: [*][3]f32 = @ptrCast(@alignCast(c.malloc(max_occ * 12) orelse return null));
        return .{ .sounding = a[0..max_lines], .lit = b[0..max_lines], .occ = o[0..max_occ] };
    }

    fn make(self: *Land, want_lines: usize, occ_cell: f32) void {
        self.sounding_n = 0;
        self.lit_n = 0;
        self.occ_n = 0;
        var rand = Rand{ .s = 0x9e3779b9 };

        // A third of the lines belong to things that sound: stalks with a ring for a head, tagged
        // for the chord so the shaders run their real path.
        const per_stalk = 12;
        const stalks = want_lines / 3 / per_stalk;
        const stalk_reacts = (react.Reacts{ .tilt = feel.blade_tilts }).byte();
        var body: usize = 1;
        for (0..stalks) |_| {
            const x = (rand.unit() * 2.0 - 1.0) * half_field * 0.95;
            const z = (rand.unit() * 2.0 - 1.0) * half_field * 0.95;
            const y0 = ground(x, z);
            const tall = 3.0 + rand.unit() * 9.0;
            const r = 0.6 + rand.unit() * 1.4;
            const hue = rand.unit();
            const col = [4]u8{
                @intFromFloat(120.0 + 135.0 * @abs(@sin(hue * 6.283))),
                @intFromFloat(120.0 + 135.0 * @abs(@sin(hue * 6.283 + 2.094))),
                @intFromFloat(120.0 + 135.0 * @abs(@sin(hue * 6.283 + 4.189))),
                255,
            };
            const b: f32 = @floatFromInt(body % lines.max_bodies);
            const cell: u8 = @intCast(body % 12);
            self.sounding[self.sounding_n] = .{ .a = .{ x, y0, z }, .b = .{ x, y0 + tall, z }, .half_width = 1.4, .body = b, .col = col, .up = .{ 0, lines.tenths(tall) }, .cell = cell, .reacts = stalk_reacts };
            self.sounding_n += 1;
            for (0..8) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
                self.sounding[self.sounding_n] = .{
                    .a = .{ x + r * @cos(a0), y0 + tall + r * @sin(a0), z },
                    .b = .{ x + r * @cos(a1), y0 + tall + r * @sin(a1), z },
                    .half_width = 1.4,
                    .body = b,
                    .col = col,
                    .up = .{ lines.tenths(tall + r * @sin(a0)), lines.tenths(tall + r * @sin(a1)) },
                    .cell = cell,
                    .reacts = stalk_reacts,
                };
                self.sounding_n += 1;
            }
            for (0..3) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 3.0);
                self.sounding[self.sounding_n] = .{
                    .a = .{ x, y0 + tall, z },
                    .b = .{ x + r * @cos(a0), y0 + tall + r * @sin(a0), z },
                    .half_width = 1.2,
                    .body = b,
                    .col = col,
                    .up = .{ lines.tenths(tall), lines.tenths(tall + r * @sin(a0)) },
                    .cell = cell,
                    .reacts = stalk_reacts,
                };
                self.sounding_n += 1;
            }
            body += 1;
        }

        // The rest are the ground's own lines, both ways, in 8 m pieces.
        const want_lit = want_lines - self.sounding_n;
        const piece: f32 = 8.0;
        const per_row: usize = @intFromFloat(2.0 * half_field / piece);
        const rows = @max(@as(usize, 2), want_lit / (2 * per_row));
        const gap = 2.0 * half_field / @as(f32, @floatFromInt(rows - 1));
        const ground_col = [4]u8{ 150, 170, 160, 110 };
        for (0..rows) |row| {
            const z = -half_field + gap * @as(f32, @floatFromInt(row));
            for (0..per_row) |k| {
                const x0 = -half_field + piece * @as(f32, @floatFromInt(k));
                const x1 = x0 + piece;
                const cell: u8 = @intCast((row + k) % 12);
                self.lit[self.lit_n] = .{ .a = .{ x0, ground(x0, z), z }, .b = .{ x1, ground(x1, z), z }, .half_width = 1.1, .body = 0.0, .col = ground_col, .cell = cell };
                self.lit_n += 1;
                self.lit[self.lit_n] = .{ .a = .{ z, ground(z, x0), x0 }, .b = .{ z, ground(z, x1), x1 }, .half_width = 1.1, .body = 0.0, .col = ground_col, .cell = cell };
                self.lit_n += 1;
            }
        }

        // The ground as black triangles, tagged with a colour so occ_vs runs the full chord path.
        if (occ_cell > 0.0) {
            const cells: usize = @intFromFloat(2.0 * half_field / occ_cell);
            for (0..cells) |iz| {
                for (0..cells) |ix| {
                    const x0 = -half_field + occ_cell * @as(f32, @floatFromInt(ix));
                    const z0 = -half_field + occ_cell * @as(f32, @floatFromInt(iz));
                    const x1 = x0 + occ_cell;
                    const z1 = z0 + occ_cell;
                    const p00 = [3]f32{ x0, ground(x0, z0), z0 };
                    const p10 = [3]f32{ x1, ground(x1, z0), z0 };
                    const p01 = [3]f32{ x0, ground(x0, z1), z1 };
                    const p11 = [3]f32{ x1, ground(x1, z1), z1 };
                    self.occ[self.occ_n..][0..6].* = .{ p00, p10, p11, p00, p11, p01 };
                    bench_tags[self.occ_n..][0..6].* = @splat(black.tagOf(0.0, @intCast((ix + iz) % 12), 0));
                    self.occ_n += 6;
                }
            }
        }
    }
};

fn dumpFrame(renderer: *lines.Renderer, dir: [*:0]const u8, name: []const u8, pixels: []u8) void {
    renderer.readFrame(pixels);
    var path: [512]u8 = undefined;
    const text = std.mem.printSentinel(&path, "{s}/{s}.png", .{ std.mem.span(dir), name }, 0) catch return;
    if (!png.writeFromGl(text.ptr, @intCast(renderer.fb_w), @intCast(renderer.fb_h), pixels)) {
        log("could not write {s}", .{text});
    }
}

const Bench = struct { lines: usize, occ_cell: f32 };
/// Beside each corner of the bench's black shapes, its chord tag (filled in Land.make).
var bench_tags: [90_000]lines.OccTag = @splat(lines.no_tag);

/// How many lines a frame holds: the same land at several sizes, a camera circling it, every
/// body's loudness changing every frame.
fn benchLines(window: plat.Window, args: Args) bool {
    var renderer: lines.Renderer = undefined;
    if (!renderer.init(window.width, window.height)) return false;
    var land = Land.alloc(100_000, 90_000) orelse return false;
    const pixels: []u8 = blk: {
        const n: usize = @intCast(window.width * window.height * 4);
        const p: [*]u8 = @ptrCast(c.malloc(n) orelse return false);
        break :blk p[0..n];
    };
    var loud: [lines.max_bodies]lines.Shine = @splat(.{ .sounding = 255 });

    const runs = [_]Bench{
        .{ .lines = 10_000, .occ_cell = 8.0 },
        .{ .lines = 20_000, .occ_cell = 8.0 },
        .{ .lines = 30_000, .occ_cell = 8.0 },
        .{ .lines = 40_000, .occ_cell = 8.0 },
        .{ .lines = 60_000, .occ_cell = 8.0 },
        .{ .lines = 80_000, .occ_cell = 8.0 },
        .{ .lines = 30_000, .occ_cell = 0.0 },
        .{ .lines = 30_000, .occ_cell = 4.0 },
    };
    const frames_each: u32 = if (args.frames > 0) args.frames else 240;
    const aspect = @as(f32, @floatFromInt(window.width)) / @as(f32, @floatFromInt(window.height));
    const proj = m.perspective(50.0, aspect, 0.3, 900.0);
    log("lines bench: {d} frames for each size; a third of the lines belong to things that sound, all tagged for the chord", .{frames_each});

    for (runs, 0..) |run, run_index| {
        land.make(run.lines, run.occ_cell);
        renderer.setLand(land.sounding[0..land.sounding_n], land.lit[0..land.lit_n], land.occ[0..land.occ_n], bench_tags[0..land.occ_n]);
        var work_sum: f64 = 0.0;
        var work_worst: f64 = 0.0;
        var gap_sum: f64 = 0.0;
        var gap_worst: f64 = 0.0;
        var late: u32 = 0;
        var last_swap = plat.now();
        var frame: u32 = 0;
        while (frame < frames_each + 20) : (frame += 1) {
            var event: c.SDL_Event = undefined;
            while (sdl.PollEvent(&event) != 0) {
                if (event.type == c.SDL_QUIT) return true;
            }
            const t: f32 = @as(f32, @floatFromInt(frame)) / 60.0;
            const angle = t * 0.35 + @as(f32, @floatFromInt(run_index));
            const ex = 150.0 * @cos(angle);
            const ez = 150.0 * @sin(angle);
            const eye = m.V3{ ex, ground(ex, ez) + 9.0, ez };
            const view = m.lookAt(eye, .{ 0.0, 4.0, 0.0 }, .{ 0.0, 1.0, 0.0 });
            const vp = m.mul(proj, view);
            for (&loud, 0..) |*v, i| {
                const phase = @as(f32, @floatFromInt(i % 97)) * 0.13 + t * (1.0 + @as(f32, @floatFromInt(i % 7)) * 0.4);
                v.* = .{ .sounding = @intFromFloat(140.0 + 115.0 * @sin(phase)), .lit = 0 };
            }
            loud[0] = .{ .lit = 255 };
            // a chord cycling round the wheel, lifting and leaning, so every line and black shape
            // runs the shaders' real chord path
            var awake: [12]f32 = @splat(0.0);
            const root: usize = @intFromFloat(@mod(t * 0.5, 12.0));
            awake[root] = 1.0;
            awake[(root + 1) % 12] = 1.0;
            awake[(root + 4) % 12] = 0.8;
            renderer.setReact(awake, 0.5 + 0.5 * @sin(t * 1.1), feel.tilt_full * @sin(t * 0.9), .{ 0.0, 0.0 });
            const hx = 138.0 * @cos(angle);
            const hz = 138.0 * @sin(angle);
            renderer.setParting(eye, .{ hx, ground(hx, hz) + 0.5, hz }, 1.0);

            const began = plat.now();
            renderer.frame(&vp, &loud);
            gl.Finish();
            const done = plat.now();
            if (args.dump) |dir| {
                if (frame == 20 + frames_each / 2) {
                    var name: [64]u8 = undefined;
                    const text: []const u8 = std.mem.printSentinel(&name, "lines-{d}-{d}", .{ run.lines, @as(u32, @intFromFloat(run.occ_cell)) }, 0) catch "lines";
                    dumpFrame(&renderer, dir, text, pixels);
                }
            }
            sdl.GL_SwapWindow(window.handle);
            const swapped = plat.now();
            if (frame >= 20) {
                const work = (done - began) * 1000.0;
                const gap = (swapped - last_swap) * 1000.0;
                work_sum += work;
                work_worst = @max(work_worst, work);
                gap_sum += gap;
                gap_worst = @max(gap_worst, gap);
                if (gap > 25.0) late += 1;
            }
            last_swap = swapped;
        }
        const n: f64 = @floatFromInt(frames_each);
        log("lines {d:>6} ({d:>5} sounding, {d:>5} lit), black triangles {d:>5}: frame {d:.2} ms (worst {d:.2}), {d} late; drawn in {d:.2} ms (worst {d:.2})", .{
            land.sounding_n + land.lit_n,
            land.sounding_n,
            land.lit_n,
            land.occ_n / 3,
            gap_sum / n,
            gap_worst,
            late,
            work_sum / n,
            work_worst,
        });
        if (!plat.checkGl("lines bench")) return false;
    }
    return true;
}

/// Which controllers there are and where each one's face buttons are found (plat.Faces).
fn controls() c_int {
    if (sdl.Init(c.SDL_INIT_GAMECONTROLLER) != 0) {
        log("SDL did not start: {s}", .{std.mem.span(sdl.GetError())});
        return 1;
    }
    defer sdl.Quit();
    const count = sdl.NumJoysticks();
    log("controls: {d} joysticks", .{count});
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        if (sdl.IsGameController(i) == c.SDL_FALSE) {
            log("controls: joystick {d} is not a game controller here", .{i});
            continue;
        }
        const handle = sdl.GameControllerOpen(i) orelse continue;
        defer sdl.GameControllerClose(handle);
        const faces = plat.Faces.find(handle);
        var said: [128]u8 = undefined;
        log("controls: {s}; {s}", .{ std.mem.span(sdl.GameControllerName(handle)), faces.describe(&said) });
    }
    return 0;
}

pub export fn main(argc: c_int, argv: [*][*:0]u8) c_int {
    const args = parseArgs(argc, argv);
    if (args.log_path) |path| plat.log_file = c.fopen(path, "w");
    if (!plat.loadSdl()) return 1;
    // which build this is, if the pack says (room/build.txt beside the game)
    {
        var said: [128]u8 = undefined;
        if (c.fopen("room/build.txt", "rb")) |file| {
            const got = c.fread(&said, 1, said.len, file);
            _ = c.fclose(file);
            log("{s}", .{std.mem.trim(u8, said[0..got], " \n")});
        } else log("build: not said (no room/build.txt here)", .{});
    }
    // a pad's face buttons are read by where they are, never by the letters printed on them
    // (SPEC.md, 10): a Nintendo-style pad otherwise swaps them by label
    _ = sdl.SetHint("SDL_GAMECONTROLLER_USE_BUTTON_LABELS", "0");
    if (args.controls) return controls();
    if (sdl.Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO | c.SDL_INIT_GAMECONTROLLER) != 0) {
        log("SDL did not start: {s}", .{std.mem.span(sdl.GetError())});
        return 1;
    }
    defer sdl.Quit();
    const window = plat.openWindow(.{ .windowed = args.windowed or args.headless, .scale = if (args.headless) 1 else @max(args.scale, 1), .depth_bits = 24 }) orelse return 1;

    var ok = true;
    if (args.room) |dir| {
        ok = room.run(window, dir, args.frames, args.dump);
    } else if (args.bench_lines) {
        ok = benchLines(window, args);
    } else {
        ok = dark.run(window, .{ .scene = args.scene, .replay = args.replay, .load = args.load, .keep = args.keep, .resume_only = args.resume_only, .picture = args.picture, .without_trail = args.without_trail, .without_ground = args.without_ground, .half_land = args.half_land, .songbook_dump = args.songbook, .check_take = args.check_take, .headless = args.headless, .frames = args.frames, .dump = args.dump, .dump_every = args.dump_every, .wav = args.wav, .bot = args.bot, .walk_starts = args.walk_starts, .chords = args.chords, .walk = if (args.walk) |w| std.mem.span(w) else null });
    }
    if (plat.log_file) |file| _ = c.fclose(file);
    return if (ok) 0 else 1;
}
