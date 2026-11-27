//! The Start/Pause Menu & Development Workbench (ROADMAP.md, step 1.2).
//!
//! Opens cleanly over the frozen simulation when Start is pressed (`ready_paused = 1`), giving
//! instant access to:
//!   1. SONGBOOK — the wordless player manual (`draw/songbook.zig`);
//!   2. STATUS   — live Mali-G31 frame/line/tri/audio budgets, harmony state, and Hum/camera readout;
//!   3. BENCH    — live tuning sliders for `feel.now` (including 1.8 A/B candidates), HUD toggle,
//!                 and durable save/reset;
//!   4. ARENA    — landmark warps, direct chord/daylight switches, camera reset, GPU toggles, PNG snap.
//!
//! Draws exclusively through existing `songbook.Sketch` and `room.Type`, adding zero GL programs
//! and zero overhead during normal play (except when the optional 1-line Corner HUD is enabled).
const std = @import("std");
const colour = @import("colour.zig");
const songbook = @import("songbook.zig");
const room = @import("../room.zig");
const feel = @import("../feel.zig");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const music = @import("../music/music.zig");

const bone = colour.bone;
const teal = colour.teal;
const amber = [3]f32{ 1.0, 0.78, 0.40 };
const lit_col = [3]f32{ 1.0, 0.95, 0.70 };
const green = [3]f32{ 0.45, 0.92, 0.55 };
const warn_col = [3]f32{ 1.0, 0.48, 0.36 };
const dim_bg = [3]f32{ 0.07, 0.08, 0.10 };
const bar_bg = [3]f32{ 0.16, 0.18, 0.22 };

pub const Tab = enum(u8) {
    songbook,
    status,
    bench,
    arena,

    pub const count = 4;
    pub fn label(self: Tab) []const u8 {
        return switch (self) {
            .songbook => "SONGBOOK",
            .status => "STATUS",
            .bench => "BENCH",
            .arena => "ARENA",
        };
    }
};

/// Live performance and rendering counters handed in from `dark.zig` each frame.
pub const Telemetry = struct {
    fps: f32 = 60.0,
    avg_ms: f32 = 0.0,
    worst_ms: f32 = 0.0,
    late: u32 = 0,
    lines_now: usize = 0,
    lines_peak: usize = 0,
    black_now: usize = 0,
    black_peak: usize = 0,
    audio_worst_ms: f32 = 0.0,
    refused: u32 = 0,
    dropped: u32 = 0,
    hud_on: bool = false,
    without_trail: bool = false,
    without_ground: bool = false,
};

/// Menu-only navigation buttons read by `dark.zig` while paused (never alters `Hands` or `.take`).
pub const Input = struct {
    up: bool = false,
    down: bool = false,
    left: bool = false,
    right: bool = false,
    tab_prev: bool = false,
    tab_next: bool = false,
    confirm: bool = false,
    reset: bool = false,
    close: bool = false,
};

pub const Action = enum {
    none,
    close,
    warped,
    save_bench,
    capture_png,
};

const Landmark = struct {
    name: []const u8,
    x: f32,
    z: f32,
    face: f32,
};

const landmarks = [_]Landmark{
    .{ .name = "Wake Clearing", .x = world_mod.land.wake[0], .z = world_mod.land.wake[1], .face = 0.0 },
    .{ .name = "Drip / Hose Coil", .x = world_mod.land.clear[0], .z = world_mod.land.clear[1], .face = -std.math.pi * 0.5 },
    .{ .name = "Great Aster Foot", .x = world_mod.land.great[0], .z = world_mod.land.great[1] + 18.0, .face = 0.0 },
    .{ .name = "Mirror Pool Shore", .x = 0.0, .z = 20.0, .face = std.math.pi },
    .{ .name = "Bridge Puddle", .x = world_mod.land.puddles[0].x, .z = world_mod.land.puddles[0].z + 18.0, .face = 0.0 },
    .{ .name = "Hose Knot", .x = 92.0, .z = -48.0, .face = -std.math.pi * 0.3 },
    .{ .name = "Spigot Rise", .x = world_mod.land.spigot[0], .z = world_mod.land.spigot[1] + 22.0, .face = 0.0 },
    .{ .name = "Bowl Rim Vista", .x = 0.0, .z = -520.0, .face = std.math.pi },
};

const Knob = struct {
    name: []const u8,
    unit: []const u8,
    min: f32,
    max: f32,
    step: f32,
    alt_a: ?f32 = null,
    alt_b: ?f32 = null,
};

const bench_knobs = [_]Knob{
    .{ .name = "Lift gravity (A/B)", .unit = "x", .min = 0.25, .max = 1.00, .step = 0.02, .alt_a = 0.55, .alt_b = 2.0 / 3.0 },
    .{ .name = "Lean speed (A/B)", .unit = "x", .min = 1.00, .max = 2.00, .step = 0.02, .alt_a = 1.3, .alt_b = 4.0 / 3.0 },
    .{ .name = "Full-close launch", .unit = "m", .min = 2.0, .max = 14.0, .step = 0.5 },
    .{ .name = "Run speed", .unit = "m/s", .min = 6.0, .max = 24.0, .step = 0.5 },
    .{ .name = "Sprint speed", .unit = "m/s", .min = 10.0, .max = 32.0, .step = 0.5 },
    .{ .name = "Jump height", .unit = "m", .min = 1.5, .max = 6.0, .step = 0.2 },
    .{ .name = "Cam run ease", .unit = "", .min = 0.02, .max = 0.30, .step = 0.01 },
    .{ .name = "Wake ease", .unit = "", .min = 0.02, .max = 0.40, .step = 0.01 },
    .{ .name = "Rise ease", .unit = "", .min = 0.02, .max = 0.40, .step = 0.01 },
    .{ .name = "Settle ease", .unit = "", .min = 0.01, .max = 0.25, .step = 0.005 },
    .{ .name = "Lean tilt", .unit = "", .min = 0.05, .max = 0.60, .step = 0.02 },
    .{ .name = "Land kick", .unit = "", .min = 0.00, .max = 0.35, .step = 0.01 },
};

const bench_rows_total = bench_knobs.len + 4; // + Chords mode, Corner HUD, Save Bench, Reset All
const bench_visible_rows = 10;
const arena_rows_total = 7;

fn knobPtr(index: usize) *f32 {
    return switch (index) {
        0 => &feel.now.lift_pull,
        1 => &feel.now.lean_speed,
        2 => &feel.now.launch_far,
        3 => &feel.now.run_speed,
        4 => &feel.now.sprint_speed,
        5 => &feel.now.jump_height,
        6 => &feel.now.view_run_ease,
        7 => &feel.now.wake_ease,
        8 => &feel.now.rise_ease,
        9 => &feel.now.settle_ease,
        10 => &feel.now.tilt_full,
        else => &feel.now.land_kick,
    };
}

fn knobDefault(index: usize) f32 {
    return switch (index) {
        0 => feel.defaults.lift_pull,
        1 => feel.defaults.lean_speed,
        2 => feel.defaults.launch_far,
        3 => feel.defaults.run_speed,
        4 => feel.defaults.sprint_speed,
        5 => feel.defaults.jump_height,
        6 => feel.defaults.view_run_ease,
        7 => feel.defaults.wake_ease,
        8 => feel.defaults.rise_ease,
        9 => feel.defaults.settle_ease,
        10 => feel.defaults.tilt_full,
        else => feel.defaults.land_kick,
    };
}

pub const State = struct {
    open: bool = false,
    /// Starts on SONGBOOK on first open, then remembers whichever tab was last used in the session.
    tab: Tab = .songbook,
    opened_once: bool = false,
    opened_at: f64 = 0.0,
    book_page: songbook.Page = .call,
    bench_row: usize = 0,
    bench_scroll: usize = 0,
    arena_row: usize = 0,
    arena_warp: usize = 2, // default highlighted landmark: Great Aster Foot
    arena_day: usize = 2, // 0=dark, 1=dawn, 2=full_day
    prev: Input = .{},
    repeat_dir: i8 = 0,
    repeat_axis: u8 = 0, // 0=none, 1=vert, 2=horiz
    repeat_frames: u16 = 0,
    notice: [64]u8 = @splat(0),
    notice_len: usize = 0,
    notice_until: f64 = 0.0,

    pub fn openAt(self: *State, w: *const World, now_s: f64) void {
        self.open = true;
        self.opened_at = now_s;
        if (!self.opened_once) {
            self.tab = .songbook;
            self.opened_once = true;
        }
        self.book_page = songbook.needed(w) orelse lastLearned(w);
        self.arena_day = if (w.dawn <= 0.01) 0 else if (w.dawn < 0.95) 1 else 2;
        self.prev = .{ .up = true, .down = true, .left = true, .right = true, .tab_prev = true, .tab_next = true, .confirm = true, .reset = true, .close = true };
        self.repeat_axis = 0;
        self.repeat_frames = 0;
    }

    pub fn say(self: *State, now_s: f64, msg: []const u8) void {
        const n = @min(msg.len, self.notice.len);
        @memcpy(self.notice[0..n], msg[0..n]);
        self.notice_len = n;
        self.notice_until = now_s + 2.4;
    }

    /// Process one frame of menu input while paused.
    pub fn update(self: *State, in: Input, w: *World, tel: *Telemetry, now_s: f64) Action {
        const p = self.prev;
        self.prev = in;

        if (in.close and !p.close) {
            self.open = false;
            return .close;
        }
        if (in.tab_prev and !p.tab_prev) {
            const idx = (@intFromEnum(self.tab) + Tab.count - 1) % Tab.count;
            self.tab = @enumFromInt(idx);
        }
        if (in.tab_next and !p.tab_next) {
            const idx = (@intFromEnum(self.tab) + 1) % Tab.count;
            self.tab = @enumFromInt(idx);
        }

        // Edge + clean key-repeat for D-pad / stick navigation
        const v_dir: i8 = if (in.down) 1 else if (in.up) -1 else 0;
        const h_dir: i8 = if (in.right) 1 else if (in.left) -1 else 0;
        var v_step: i8 = 0;
        var h_step: i8 = 0;
        if (v_dir != 0) {
            if (self.repeat_axis != 1 or self.repeat_dir != v_dir) {
                self.repeat_axis = 1;
                self.repeat_dir = v_dir;
                self.repeat_frames = 0;
                v_step = v_dir;
            } else {
                self.repeat_frames +|= 1;
                if (self.repeat_frames >= 18 and (self.repeat_frames - 18) % 5 == 0) v_step = v_dir;
            }
        } else if (h_dir != 0) {
            if (self.repeat_axis != 2 or self.repeat_dir != h_dir) {
                self.repeat_axis = 2;
                self.repeat_dir = h_dir;
                self.repeat_frames = 0;
                h_step = h_dir;
            } else {
                self.repeat_frames +|= 1;
                if (self.repeat_frames >= 16 and (self.repeat_frames - 16) % 4 == 0) h_step = h_dir;
            }
        } else {
            self.repeat_axis = 0;
            self.repeat_dir = 0;
            self.repeat_frames = 0;
        }

        const confirm = in.confirm and !p.confirm;
        const reset = in.reset and !p.reset;

        switch (self.tab) {
            .songbook => {
                if (h_step != 0) self.book_page = nextPage(w, self.book_page, h_step > 0);
            },
            .status => {
                if (confirm) {
                    tel.hud_on = !tel.hud_on;
                    self.say(now_s, if (tel.hud_on) "CORNER HUD: ON" else "CORNER HUD: OFF");
                }
            },
            .bench => {
                if (v_step != 0) {
                    self.bench_row = @intCast(@mod(@as(i32, @intCast(self.bench_row)) + v_step, @as(i32, bench_rows_total)));
                    if (self.bench_row < self.bench_scroll) self.bench_scroll = self.bench_row;
                    if (self.bench_row >= self.bench_scroll + bench_visible_rows) {
                        self.bench_scroll = self.bench_row - bench_visible_rows + 1;
                    }
                }
                if (self.bench_row < bench_knobs.len) {
                    const k = bench_knobs[self.bench_row];
                    const ptr = knobPtr(self.bench_row);
                    if (h_step != 0) {
                        const next = std.math.clamp(ptr.* + @as(f32, @floatFromInt(h_step)) * k.step, k.min, k.max);
                        // snap cleanly to exact default when crossing within half a step
                        const def = knobDefault(self.bench_row);
                        ptr.* = if (@abs(next - def) < k.step * 0.35) def else next;
                    }
                    if (confirm) {
                        if (k.alt_a) |a| {
                            if (k.alt_b) |b| {
                                ptr.* = if (@abs(ptr.* - a) < @abs(ptr.* - b)) b else a;
                                self.say(now_s, "SNAPPED A/B CANDIDATE");
                            }
                        }
                    }
                    if (reset) {
                        ptr.* = knobDefault(self.bench_row);
                        self.say(now_s, "ROW RESET TO DEFAULT");
                    }
                } else {
                    const extra = self.bench_row - bench_knobs.len;
                    if (extra == 0 and (confirm or h_step != 0)) {
                        world_mod.chords_tryout = !world_mod.chords_tryout;
                        if (world_mod.chords_tryout) {
                            w.awake |= @as(u8, 1) << @intFromEnum(world_mod.Mood.drive);
                        }
                        self.say(now_s, if (world_mod.chords_tryout) "CHORDS MODE: ON" else "CHORDS MODE: OFF");
                    } else if (extra == 1 and (confirm or h_step != 0)) {
                        tel.hud_on = !tel.hud_on;
                        self.say(now_s, if (tel.hud_on) "CORNER HUD: LIVE" else "CORNER HUD: OFF");
                    } else if (extra == 2 and confirm) {
                        return .save_bench;
                    } else if (extra == 3 and (confirm or reset)) {
                        feel.reset();
                        self.say(now_s, "ALL FEEL DEFAULTS RESTORED");
                    }
                }
            },
            .arena => {
                if (v_step != 0) {
                    self.arena_row = @intCast(@mod(@as(i32, @intCast(self.arena_row)) + v_step, @as(i32, arena_rows_total)));
                }
                switch (self.arena_row) {
                    0 => {
                        if (h_step != 0) {
                            self.arena_warp = @intCast(@mod(@as(i32, @intCast(self.arena_warp)) + h_step, @as(i32, landmarks.len)));
                        }
                        if (confirm) {
                            const lm = landmarks[self.arena_warp];
                            var wx = lm.x;
                            var wz = lm.z;
                            if (self.arena_warp == 5) {
                                // exact hose knot position from world_mod.hose
                                const kp = world_mod.hose.knot;
                                wx = kp[0];
                                wz = kp[1] + 6.0;
                            }
                            w.warpTo(wx, wz, lm.face);
                            self.open = false;
                            return .warped;
                        }
                    },
                    1 => {
                        if (h_step != 0 or confirm) {
                            const delta: i8 = if (h_step != 0) h_step else 1;
                            const next_k: i8 = @as(i8, @intCast(@mod(@as(i32, w.home_k + 1) + delta, 3))) - 1;
                            w.setChordDirect(next_k);
                            self.say(now_s, chordLabel(next_k));
                        }
                    },
                    2 => {
                        if (h_step != 0 or confirm) {
                            const delta: i8 = if (h_step != 0) h_step else 1;
                            self.arena_day = @intCast(@mod(@as(i32, @intCast(self.arena_day)) + delta, 3));
                            w.setDaylight(@enumFromInt(self.arena_day));
                            self.say(now_s, daylightLabel(self.arena_day));
                        }
                    },
                    3 => {
                        if (confirm) {
                            w.resetCamera();
                            self.say(now_s, "CAMERA RESET BEHIND HUM");
                        }
                    },
                    4 => {
                        if (h_step != 0 or confirm) {
                            tel.without_trail = !tel.without_trail;
                            self.say(now_s, if (tel.without_trail) "PHOSPHOR TRAIL: OFF" else "PHOSPHOR TRAIL: ON");
                        }
                    },
                    5 => {
                        if (h_step != 0 or confirm) {
                            tel.without_ground = !tel.without_ground;
                            self.say(now_s, if (tel.without_ground) "GROUND LIGHT: OFF" else "GROUND LIGHT: ON");
                        }
                    },
                    6 => {
                        if (confirm) {
                            self.open = false;
                            return .capture_png;
                        }
                    },
                    else => {},
                }
            },
        }
        return .none;
    }

    pub fn draw(self: *const State, sk: *songbook.Sketch, words: *room.Type, w: *const World, tel: *const Telemetry, now_s: f64) void {
        if (self.tab == .songbook) {
            const whole: f32 = if (songbook.learned(w, self.book_page)) 1.0 else 0.55;
            songbook.draw(sk, self.book_page, @floatCast(@max(0.0, now_s - self.opened_at)), whole);
            drawTabBar(sk, words, self.tab);
            sk.flush();
            words.flush();
            return;
        }

        sk.veil(0.90);
        // Frame around content panel
        const px0: f32 = 16.0;
        const py0: f32 = 40.0;
        const px1: f32 = sk.w - 16.0;
        const py1: f32 = sk.h - 32.0;
        sk.rect(px0, py0, px1 - px0, py1 - py0, dim_bg, 0.82);
        sk.seg(px0, py0, px1, py0, 1.4, bone, 0.30);
        sk.seg(px0, py1, px1, py1, 1.4, bone, 0.30);
        sk.seg(px0, py0, px0, py1, 1.4, bone, 0.30);
        sk.seg(px1, py0, px1, py1, 1.4, bone, 0.30);

        drawTabBar(sk, words, self.tab);

        switch (self.tab) {
            .status => drawStatus(sk, words, w, tel),
            .bench => drawBench(self, sk, words, tel),
            .arena => drawArena(self, sk, words, w, tel),
            .songbook => {},
        }

        // Notice banner if active
        if (self.notice_len > 0 and now_s < self.notice_until) {
            const msg = self.notice[0..self.notice_len];
            sk.rect(180.0, py1 - 28.0, 280.0, 22.0, .{ 0.14, 0.22, 0.18 }, 0.94);
            putLine(words, 192.0, py1 - 26.0, 0.80, .{ lit_col[0], lit_col[1], lit_col[2], 1.0 }, msg);
        }

        // Footer controls
        const hint: []const u8 = switch (self.tab) {
            .status => "L1/R1 TAB   B TOGGLE HUD   START RESUME",
            .bench => "L1/R1 TAB  L/R TUNE  B ACT/AB  Y RESET  START RESUME",
            .arena => "L1/R1 TAB  L/R PICK  B RUN  START RESUME",
            .songbook => "",
        };
        putLine(words, 24.0, sk.h - 24.0, 0.78, .{ bone[0], bone[1], bone[2], 0.72 }, hint);

        sk.flush();
        words.flush();
    }
};

/// Optional live 1-line Corner Telemetry HUD during play (off by default).
pub fn drawHud(sk: *songbook.Sketch, words: *room.Type, w: *const World, tel: *const Telemetry) void {
    const sp = @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz);
    var buf: [128]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{d:>4.1}fps {d:>4.1}ms | {d:>4.1}k/24k L {d:>3.1}k/12k T | {s} | {d:>4.1}m/s", .{
        tel.fps,
        tel.avg_ms,
        @as(f32, @floatFromInt(tel.lines_now)) / 1000.0,
        @as(f32, @floatFromInt(tel.black_now)) / 1000.0,
        chordShort(w.home_k),
        sp,
    }) catch return;
    sk.rect(6.0, 5.0, sk.w - 12.0, 22.0, .{ 0.0, 0.0, 0.0 }, 0.58);
    sk.flush();
    const hot = tel.avg_ms > 15.0 or tel.lines_now > 24_000 or tel.black_now > 12_000;
    const col = if (hot) [4]f32{ warn_col[0], warn_col[1], warn_col[2], 0.95 } else [4]f32{ bone[0], bone[1], bone[2], 0.90 };
    putLine(words, 12.0, 7.0, 0.76, col, text);
    words.flush();
}

fn putLine(words: *room.Type, x: f32, y: f32, scale: f32, col: [4]f32, text: []const u8) void {
    if (words.used + text.len * 48 > words.verts.len) words.flush();
    words.line(x, y, scale, col, text);
}

fn drawTabBar(sk: *songbook.Sketch, words: *room.Type, active: Tab) void {
    sk.rect(16.0, 6.0, sk.w - 32.0, 28.0, .{ 0.04, 0.05, 0.06 }, 0.88);
    putLine(words, 24.0, 10.0, 0.78, .{ teal[0], teal[1], teal[2], 0.80 }, "[L1]");
    putLine(words, sk.w - 64.0, 10.0, 0.78, .{ teal[0], teal[1], teal[2], 0.80 }, "[R1]");

    const tabs = [_]Tab{ .songbook, .status, .bench, .arena };
    const slot_w: f32 = 122.0;
    const x0: f32 = 76.0;
    for (tabs, 0..) |t, i| {
        const tx = x0 + @as(f32, @floatFromInt(i)) * slot_w;
        const on = t == active;
        if (on) {
            sk.rect(tx - 4.0, 8.0, slot_w - 8.0, 24.0, .{ 0.20, 0.18, 0.10 }, 0.92);
            sk.seg(tx - 4.0, 32.0, tx + slot_w - 12.0, 32.0, 2.2, amber, 0.95);
        }
        const col = if (on) [4]f32{ lit_col[0], lit_col[1], lit_col[2], 1.0 } else [4]f32{ bone[0], bone[1], bone[2], 0.55 };
        putLine(words, tx + 6.0, 10.0, 0.86, col, t.label());
    }
}

fn drawGauge(sk: *songbook.Sketch, x: f32, y: f32, w: f32, h: f32, frac: f32, rgb: [3]f32) void {
    sk.rect(x, y, w, h, bar_bg, 0.95);
    const fill = std.math.clamp(frac, 0.0, 1.0) * w;
    if (fill > 0.5) sk.rect(x, y, fill, h, rgb, 0.90);
}

fn drawStatus(sk: *songbook.Sketch, words: *room.Type, w: *const World, tel: *const Telemetry) void {
    var buf: [128]u8 = undefined;
    const lx: f32 = 30.0;
    var y: f32 = 52.0;

    // Section 1: Hardware / Mali-G31 budget
    putLine(words, lx, y, 0.86, .{ amber[0], amber[1], amber[2], 0.95 }, "ENGINE & MALI-G31 BUDGET");
    y += 26.0;

    const frame_col = if (tel.avg_ms > 15.0) warn_col else green;
    const s_fps = std.fmt.bufPrint(&buf, "FRAME  {d:>4.1} fps  avg {d:>5.2}ms  worst {d:>5.2}ms  late {d}", .{ tel.fps, tel.avg_ms, tel.worst_ms, tel.late }) catch "";
    putLine(words, lx, y, 0.82, .{ bone[0], bone[1], bone[2], 0.95 }, s_fps);
    y += 22.0;
    drawGauge(sk, lx, y, 560.0, 7.0, tel.avg_ms / 16.66, frame_col);
    y += 14.0;

    const lines_f = @as(f32, @floatFromInt(tel.lines_now)) / 24_000.0;
    const s_lines = std.fmt.bufPrint(&buf, "LINES  {d:>5} / 24000  (peak {d})", .{ tel.lines_now, tel.lines_peak }) catch "";
    putLine(words, lx, y, 0.82, .{ bone[0], bone[1], bone[2], 0.92 }, s_lines);
    drawGauge(sk, 370.0, y + 5.0, 220.0, 10.0, lines_f, if (lines_f > 0.95) warn_col else teal);
    y += 24.0;

    const black_f = @as(f32, @floatFromInt(tel.black_now)) / 12_000.0;
    const s_black = std.fmt.bufPrint(&buf, "BLACK  {d:>5} / 12000  (peak {d})", .{ tel.black_now, tel.black_peak }) catch "";
    putLine(words, lx, y, 0.82, .{ bone[0], bone[1], bone[2], 0.92 }, s_black);
    drawGauge(sk, 370.0, y + 5.0, 220.0, 10.0, black_f, if (black_f > 0.95) warn_col else teal);
    y += 24.0;

    const aud_f = tel.audio_worst_ms / 2.67;
    const s_aud = std.fmt.bufPrint(&buf, "AUDIO  {d:>4.2}/2.67ms  ref {d}  drp {d}", .{ tel.audio_worst_ms, tel.refused, tel.dropped }) catch "";
    putLine(words, lx, y, 0.82, .{ bone[0], bone[1], bone[2], 0.92 }, s_aud);
    drawGauge(sk, 370.0, y + 5.0, 220.0, 10.0, aud_f, if (aud_f > 0.75) warn_col else green);
    y += 30.0;

    // Section 2: Harmony & World Reactions
    putLine(words, lx, y, 0.86, .{ amber[0], amber[1], amber[2], 0.95 }, "HARMONY & WORLD REACTIONS");
    y += 26.0;

    const s_harm = std.fmt.bufPrint(&buf, "DAY C  |  {s} (k={d})  |  {s}  |  chords:{s}", .{
        chordLabel(w.home_k),
        w.home_k,
        if (w.in_garden) "GARDEN" else "DARK",
        if (world_mod.chords_tryout) "ON" else "OFF",
    }) catch "";
    putLine(words, lx, y, 0.82, .{ lit_col[0], lit_col[1], lit_col[2], 0.95 }, s_harm);
    y += 24.0;

    // 12-cell Circle-of-Fifths colour strip showing live `world.react.awake[0..12]`
    const names = [12][]const u8{ "C", "G", "D", "A", "E", "B", "F#", "Db", "Ab", "Eb", "Bb", "F" };
    for (0..12) |cell| {
        const cx = lx + @as(f32, @floatFromInt(cell)) * 47.0;
        const awake = w.react.awake[cell];
        const rgb = colour.ofCell(cell);
        sk.rect(cx, y, 42.0, 20.0, rgb, 0.16 + 0.78 * awake);
        putLine(words, cx + 8.0, y + 1.0, 0.72, .{ 0.04, 0.04, 0.05, if (awake > 0.4) 0.95 else 0.0 }, names[cell]);
        if (awake <= 0.4) putLine(words, cx + 8.0, y + 1.0, 0.72, .{ bone[0], bone[1], bone[2], 0.72 }, names[cell]);
    }
    y += 28.0;

    const s_react = std.fmt.bufPrint(&buf, "RISE {d:.2}   TILT {d:.3}   WOUND {d:.2}   BENCH {d} mod", .{
        w.react.rise,
        w.react.tilt,
        w.react.wound,
        feel.diffCount(feel.now),
    }) catch "";
    putLine(words, lx, y, 0.82, .{ bone[0], bone[1], bone[2], 0.90 }, s_react);
    y += 30.0;

    // Section 3: Hum & Camera Physics
    putLine(words, lx, y, 0.86, .{ amber[0], amber[1], amber[2], 0.95 }, "HUM & CAMERA");
    y += 26.0;

    const sp = @sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz);
    const s_pos = std.fmt.bufPrint(&buf, "POS ({d:>5.1}, {d:>4.1}, {d:>5.1})  gnd {d:>4.1}  flr {d:>3.1}  sp {d:>4.1}m/s", .{
        w.hum_x,
        w.hum_y,
        w.hum_z,
        w.hum_ground,
        w.hum_floor,
        sp,
    }) catch "";
    putLine(words, lx, y, 0.80, .{ bone[0], bone[1], bone[2], 0.92 }, s_pos);
    y += 24.0;

    const s_cam = std.fmt.bufPrint(&buf, "CAM orbit {d:>5.2}  pull {d:.2}  lift {d:>4.2}  run {d:.2}", .{
        w.orbit,
        w.eye_pull,
        w.eye_lift,
        w.view_run,
    }) catch "";
    putLine(words, lx, y, 0.80, .{ bone[0], bone[1], bone[2], 0.92 }, s_cam);
    y += 24.0;

    const s_misc = std.fmt.bufPrint(&buf, "COVER {s}  BREATH {d:.1}/{d}  DAWN {d:.2}  STEP {d}  HUD:{s}", .{
        @tagName(w.cover),
        w.breath,
        w.breath_most,
        w.dawn,
        w.step,
        if (tel.hud_on) "ON" else "OFF",
    }) catch "";
    putLine(words, lx, y, 0.80, .{ teal[0], teal[1], teal[2], 0.92 }, s_misc);
}

fn drawBench(self: *const State, sk: *songbook.Sketch, words: *room.Type, tel: *const Telemetry) void {
    var buf: [128]u8 = undefined;
    const lx: f32 = 30.0;
    const header = std.fmt.bufPrint(&buf, "LIVE FEEL BENCH (STEP 1.2)   {d} modified   row {d}/{d}", .{
        feel.diffCount(feel.now),
        self.bench_row + 1,
        bench_rows_total,
    }) catch "";
    putLine(words, lx, 52.0, 0.84, .{ amber[0], amber[1], amber[2], 0.95 }, header);

    const row_h: f32 = 34.0;
    const y0: f32 = 84.0;
    // Subtle vertical scroll track & thumb on right edge
    const track_h: f32 = row_h * @as(f32, @floatFromInt(bench_visible_rows)) - 6.0;
    const thumb_h: f32 = track_h * (@as(f32, @floatFromInt(bench_visible_rows)) / @as(f32, @floatFromInt(bench_rows_total)));
    const max_scroll: f32 = @floatFromInt(bench_rows_total - bench_visible_rows);
    const thumb_y: f32 = y0 + (track_h - thumb_h) * (@as(f32, @floatFromInt(self.bench_scroll)) / max_scroll);
    sk.rect(sk.w - 23.0, y0, 3.0, track_h, bar_bg, 0.85);
    sk.rect(sk.w - 23.0, thumb_y, 3.0, thumb_h, amber, 0.85);

    for (0..bench_visible_rows) |slot| {
        const idx = self.bench_scroll + slot;
        if (idx >= bench_rows_total) break;
        const y = y0 + @as(f32, @floatFromInt(slot)) * row_h;
        const sel = idx == self.bench_row;
        if (sel) {
            sk.rect(24.0, y - 2.0, sk.w - 48.0, row_h - 4.0, .{ 0.19, 0.17, 0.11 }, 0.95);
            sk.seg(24.0, y - 2.0, 24.0, y + row_h - 6.0, 3.0, amber, 0.95);
        }
        const label_col = if (sel) [4]f32{ lit_col[0], lit_col[1], lit_col[2], 1.0 } else [4]f32{ bone[0], bone[1], bone[2], 0.88 };

        if (idx < bench_knobs.len) {
            const k = bench_knobs[idx];
            const val = knobPtr(idx).*;
            const def = knobDefault(idx);
            const mod = val != def;
            const name_s = std.fmt.bufPrint(&buf, "{s}{s}", .{ if (mod) "* " else "  ", k.name }) catch "";
            putLine(words, lx, y + 3.0, 0.82, label_col, name_s);

            const frac = (val - k.min) / (k.max - k.min);
            drawGauge(sk, 316.0, y + 9.0, 165.0, 10.0, frac, if (mod) amber else teal);
            // default tick mark on slider
            const def_x = 316.0 + std.math.clamp((def - k.min) / (k.max - k.min), 0.0, 1.0) * 165.0;
            sk.seg(def_x, y + 6.0, def_x, y + 22.0, 1.6, bone, 0.65);

            var vbuf: [32]u8 = undefined;
            const vs = std.fmt.bufPrint(&vbuf, "{d:>6.3}{s}", .{ val, k.unit }) catch "";
            const vcol = if (mod) [4]f32{ amber[0], amber[1], amber[2], 1.0 } else [4]f32{ bone[0], bone[1], bone[2], 0.88 };
            putLine(words, 492.0, y + 3.0, 0.82, vcol, vs);
        } else {
            const extra = idx - bench_knobs.len;
            const label: []const u8 = switch (extra) {
                0 => "  Chords mode (L1/L2)",
                1 => "  Corner Telemetry HUD",
                2 => "  Save bench -> keep/progress.txt",
                else => "  Reset all feel defaults",
            };
            putLine(words, lx, y + 3.0, 0.82, label_col, label);
            const state_s: []const u8 = switch (extra) {
                0 => if (world_mod.chords_tryout) "[ ON  ]" else "[ OFF ]",
                1 => if (tel.hud_on) "[LIVE ]" else "[ OFF ]",
                2 => "[SAVE ]",
                else => "[RESET]",
            };
            const scol: [4]f32 = switch (extra) {
                0 => if (world_mod.chords_tryout) .{ green[0], green[1], green[2], 1.0 } else .{ bone[0], bone[1], bone[2], 0.65 },
                1 => if (tel.hud_on) .{ green[0], green[1], green[2], 1.0 } else .{ bone[0], bone[1], bone[2], 0.65 },
                else => .{ teal[0], teal[1], teal[2], 0.95 },
            };
            putLine(words, 498.0, y + 3.0, 0.82, scol, state_s);
        }
    }
}

fn drawArena(self: *const State, sk: *songbook.Sketch, words: *room.Type, w: *const World, tel: *const Telemetry) void {
    var buf: [128]u8 = undefined;
    const lx: f32 = 30.0;
    putLine(words, lx, 52.0, 0.86, .{ amber[0], amber[1], amber[2], 0.95 }, "DEV ARENA - QUICK WARPS & CONTROLS");

    const row_h: f32 = 44.0;
    const y0: f32 = 90.0;
    const labels = [arena_rows_total][]const u8{
        "Warp landmark",
        "Set chord directly",
        "Set daylight",
        "Reset camera & pose",
        "Phosphor trail",
        "Ground light layer",
        "Capture PNG frame",
    };

    for (0..arena_rows_total) |idx| {
        const y = y0 + @as(f32, @floatFromInt(idx)) * row_h;
        const sel = idx == self.arena_row;
        if (sel) {
            sk.rect(24.0, y - 2.0, sk.w - 48.0, row_h - 6.0, .{ 0.19, 0.17, 0.11 }, 0.95);
            sk.seg(24.0, y - 2.0, 24.0, y + row_h - 8.0, 3.0, amber, 0.95);
        }
        const label_col = if (sel) [4]f32{ lit_col[0], lit_col[1], lit_col[2], 1.0 } else [4]f32{ bone[0], bone[1], bone[2], 0.88 };
        putLine(words, lx, y + 7.0, 0.86, label_col, labels[idx]);

        const val_s: []const u8 = switch (idx) {
            0 => std.fmt.bufPrint(&buf, "< {s} >", .{landmarks[self.arena_warp].name}) catch "",
            1 => std.fmt.bufPrint(&buf, "< {s} >", .{chordLabel(w.home_k)}) catch "",
            2 => std.fmt.bufPrint(&buf, "< {s} >", .{daylightLabel(self.arena_day)}) catch "",
            3 => "[ B TO RESET ]",
            4 => if (tel.without_trail) "[ OFF ]" else "[ ON  ]",
            5 => if (tel.without_ground) "[ OFF ]" else "[ ON  ]",
            else => "[ B TO SNAP  ]",
        };
        const vcol: [4]f32 = switch (idx) {
            4 => if (tel.without_trail) .{ warn_col[0], warn_col[1], warn_col[2], 1.0 } else .{ green[0], green[1], green[2], 1.0 },
            5 => if (tel.without_ground) .{ warn_col[0], warn_col[1], warn_col[2], 1.0 } else .{ green[0], green[1], green[2], 1.0 },
            else => .{ teal[0], teal[1], teal[2], 0.95 },
        };
        putLine(words, 310.0, y + 7.0, 0.86, vcol, val_s);
    }

    // Extra orientation note at bottom of Arena panel
    const lm = landmarks[self.arena_warp];
    const info = std.fmt.bufPrint(&buf, "Selected warp target: ({d:.0}, {d:.0})  |  press B to jump & resume", .{ lm.x, lm.z }) catch "";
    putLine(words, lx, 412.0, 0.78, .{ bone[0], bone[1], bone[2], 0.72 }, info);
}

fn chordLabel(k: i8) []const u8 {
    return switch (k) {
        -1 => "F LIFT",
        1 => "G LEAN",
        else => "C HOME",
    };
}

fn chordShort(k: i8) []const u8 {
    return switch (k) {
        -1 => "F LIFT",
        1 => "G LEAN",
        else => "C HOME",
    };
}

fn daylightLabel(idx: usize) []const u8 {
    return switch (idx) {
        0 => "DARK",
        1 => "DAWN",
        else => "FULL DAY",
    };
}

fn lastLearned(w: *const World) songbook.Page {
    var last: songbook.Page = .call;
    for (songbook.pages) |p| {
        if (songbook.learned(w, p)) last = p;
    }
    return last;
}

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

comptime {
    _ = music;
}
