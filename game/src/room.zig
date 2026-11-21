//! The room: where Morgan's ears, eyes and hands answer, and every answer is logged.
//!
//! Fable can't hear, can't feel a motor and can't see the handheld's screen. So each thing only a
//! person can judge is put here as one item: something plays or happens, a question is asked, and
//! a button answers it. The session log is the result (SPEC.md, section 21).
//!
//! Buttons, by the letters this handheld prints: A (right) yes, B (bottom) no, Y (left) again,
//! R1 next, L1 back, Select and Start together leave.
//!
//! The items, in order:
//!   - who is holding the handheld;
//!   - the ear, before (spec/promises.md): two pairs of notes, one still and one turning, and
//!     which is still? The difference shrinks until it can't be told. The number it ends on is
//!     that person's ear before they have played, to be set beside the same number afterwards;
//!   - the walk (spec/promises.md): each promise that has a scene, from the folder's
//!     `promises.txt`. It names the promise, puts the person in the moment with their own hands,
//!     and when they come back asks its one question. What their hands did there is logged too;
//!   - three checks for the hands and eyes: a tone, the backlight following a swell, the left
//!     stick;
//!   - every listening clip in the folder's `clips.txt`.
//!
//! The rumble line and the headset's microphone were here and are gone: Morgan, 2026-11-19, said
//! this handheld has no motor, and that a microphone is never something to lean on.
const std = @import("std");
const plat = @import("plat/plat.zig");
const font = @import("plat/font.zig");
const png = @import("plat/png.zig");
const dark = @import("dark.zig");
const c = plat.c;
const sdl = plat.sdl;
const gl = plat.gl;
const log = plat.log;

// ------------------------------------------------------------------ type on the screen

const text_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\layout(location = 1) in vec2 a_uv;
    \\layout(location = 2) in vec4 a_col;
    \\uniform vec2 u_size;
    \\out vec2 v_uv;
    \\out vec4 v_col;
    \\void main() {
    \\    v_uv = a_uv;
    \\    v_col = a_col;
    \\    gl_Position = vec4(a_pos.x / u_size.x * 2.0 - 1.0, 1.0 - a_pos.y / u_size.y * 2.0, 0.0, 1.0);
    \\}
;

const text_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\in vec4 v_col;
    \\uniform sampler2D u_font;
    \\out vec4 o;
    \\void main() {
    \\    float a = texture(u_font, v_uv).r * v_col.a;
    \\    o = vec4(v_col.rgb * a, a);
    \\}
;

pub const Type = struct {
    prog: c.GLuint = 0,
    u_size: c.GLint = -1,
    u_font: c.GLint = -1,
    vao: c.GLuint = 0,
    vbo: c.GLuint = 0,
    tex: c.GLuint = 0,
    verts: [600 * 6 * 8]f32 = undefined,
    used: usize = 0,
    w: f32 = 640.0,
    h: f32 = 480.0,

    pub fn init(self: *Type, w: i32, h: i32) bool {
        self.* = .{};
        self.w = @floatFromInt(w);
        self.h = @floatFromInt(h);
        self.prog = plat.linkProgram(text_vs, text_fs, "type") orelse return false;
        self.u_size = gl.GetUniformLocation(self.prog, "u_size");
        self.u_font = gl.GetUniformLocation(self.prog, "u_font");
        gl.GenVertexArrays(1, &self.vao);
        gl.GenBuffers(1, &self.vbo);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 32, null);
        gl.EnableVertexAttribArray(1);
        gl.VertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 32, @ptrFromInt(8));
        gl.EnableVertexAttribArray(2);
        gl.VertexAttribPointer(2, 4, c.GL_FLOAT, c.GL_FALSE, 32, @ptrFromInt(16));
        gl.BindVertexArray(0);
        gl.GenTextures(1, &self.tex);
        gl.BindTexture(c.GL_TEXTURE_2D, self.tex);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, font.w, font.h, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, font.pixels.ptr);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        return plat.checkGl("type");
    }

    /// One line of type with its top left at (x, y), in pixels.
    pub fn line(self: *Type, x: f32, y: f32, scale: f32, col: [4]f32, string: []const u8) void {
        const cw: f32 = @as(f32, font.cw) * scale;
        const ch: f32 = @as(f32, font.ch) * scale;
        const step: f32 = (@as(f32, font.cw) + 3.0) * scale;
        var px = x;
        for (string) |char| {
            if (char > 32 and char < 127 and self.used + 48 <= self.verts.len) {
                const index: usize = char - 32;
                // half a texel in from each edge of the cell, so a letter never picks up its neighbour
                const s0 = (@as(f32, @floatFromInt((index % 16) * font.cw)) + 0.5) / @as(f32, font.w);
                const t0 = (@as(f32, @floatFromInt((index / 16) * font.ch)) + 0.5) / @as(f32, font.h);
                const s1 = s0 + (@as(f32, font.cw) - 1.0) / @as(f32, font.w);
                const t1 = t0 + (@as(f32, font.ch) - 1.0) / @as(f32, font.h);
                const corners = [6][4]f32{
                    .{ px, y, s0, t0 },           .{ px + cw, y, s1, t0 },      .{ px + cw, y + ch, s1, t1 },
                    .{ px, y, s0, t0 },           .{ px + cw, y + ch, s1, t1 }, .{ px, y + ch, s0, t1 },
                };
                for (corners) |corner| {
                    const v = self.verts[self.used .. self.used + 8];
                    v[0..4].* = corner;
                    v[4..8].* = col;
                    self.used += 8;
                }
            }
            px += step;
        }
    }

    pub fn flush(self: *Type) void {
        if (self.used == 0) return;
        gl.UseProgram(self.prog);
        gl.Uniform2f(self.u_size, self.w, self.h);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.tex);
        gl.Uniform1i(self.u_font, 0);
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(self.used * @sizeOf(f32)), &self.verts, c.GL_STREAM_DRAW);
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(self.used / 8));
        gl.BindVertexArray(0);
        gl.Disable(c.GL_BLEND);
        self.used = 0;
    }
};

// ------------------------------------------------------------------ what plays

const rate: f32 = 48000.0;
var out_channels: usize = 2;
var clip: []f32 = &.{};
var clip_pos: usize = 0;
var clip_on: u32 = 0;
var tone_left: u32 = 0;
var tone_phase: f32 = 0.0;
var swell_left: u32 = 0;
var swell_total: u32 = 1;
var swell_level: u32 = 0; // 0 to 1000, for the backlight to follow

// the ear check: two pairs of notes a fifth apart, one pure and one a little wide
const ear_pair: u32 = 62400; // 1.3 s
const ear_gap: u32 = 16800; // 0.35 s
var ear_left: u32 = 0;
var ear_cents: f32 = 0.0;
var ear_first_pure: bool = true;

fn earSample(at: u32) f32 {
    const total = ear_pair * 2 + ear_gap;
    if (at >= total) return 0.0;
    const second = at >= ear_pair + ear_gap;
    if (at >= ear_pair and !second) return 0.0;
    const n: u32 = if (second) at - ear_pair - ear_gap else at;
    const pure = (second and !ear_first_pure) or (!second and ear_first_pure);
    const root: f64 = 261.63;
    const fifth: f64 = root * 1.5 * (if (pure) 1.0 else std.math.pow(f64, 2.0, @as(f64, ear_cents) / 1200.0));
    const seconds = @as(f64, @floatFromInt(n)) / 48000.0;
    var s: f64 = 0.0;
    for (1..6) |k| {
        const h: f64 = @floatFromInt(k);
        s += @sin(seconds * root * h * 6.283185307) / h;
        if (k < 5) s += @sin(seconds * fifth * h * 6.283185307) / h;
    }
    // in and out over 40 ms, so nothing clicks
    const edge: f64 = 1920.0;
    const from_end: f64 = @floatFromInt(ear_pair - n);
    const env = @min(1.0, @min(@as(f64, @floatFromInt(n)) / edge, from_end / edge));
    return @floatCast(0.085 * env * s);
}

fn playCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * out_channels);
    const out: [*]f32 = @ptrCast(@alignCast(stream));
    const playing = @atomicLoad(u32, &clip_on, .acquire) != 0;
    for (0..frames) |i| {
        var s: f32 = 0.0;
        if (playing and clip_pos < clip.len) {
            s += clip[clip_pos];
            clip_pos += 1;
        }
        if (tone_left > 0) {
            tone_phase += 1000.0 / rate;
            if (tone_phase >= 1.0) tone_phase -= 1.0;
            s += 0.25 * @sin(tone_phase * 6.2831853);
            tone_left -= 1;
        }
        if (ear_left > 0) {
            s += earSample(ear_pair * 2 + ear_gap - ear_left);
            ear_left -= 1;
        }
        if (swell_left > 0) {
            // two swells of a pure fifth, each rising and falling
            const t = 1.0 - @as(f32, @floatFromInt(swell_left)) / @as(f32, @floatFromInt(swell_total));
            const a = @sin(t * 6.2831853);
            const env = a * a;
            const n: f32 = @floatFromInt(swell_total - swell_left);
            s += 0.22 * env * (@sin(n * (6.2831853 * 261.63 / rate)) + 0.8 * @sin(n * (6.2831853 * 392.445 / rate)));
            @atomicStore(u32, &swell_level, @intFromFloat(env * 1000.0), .monotonic);
            swell_left -= 1;
            if (swell_left == 0) @atomicStore(u32, &swell_level, 0, .monotonic);
        }
        for (0..out_channels) |ch| out[i * out_channels + ch] = s;
    }
}

/// Read a WAV file (16-bit, one or two channels, any rate) and bring it to 48,000 Hz, one channel.
fn loadClip(path: [*:0]const u8) ?[]f32 {
    const file = c.fopen(path, "rb") orelse return null;
    defer _ = c.fclose(file);
    _ = c.fseek(file, 0, c.SEEK_END);
    const size: usize = @intCast(c.ftell(file));
    _ = c.fseek(file, 0, c.SEEK_SET);
    if (size < 44 or size > 64 * 1024 * 1024) return null;
    const raw: [*]u8 = @ptrCast(c.malloc(size) orelse return null);
    defer c.free(raw);
    if (c.fread(raw, 1, size, file) != size) return null;
    const bytes = raw[0..size];
    var channels: usize = 1;
    var hz: f32 = 22050.0;
    var data: []const u8 = &.{};
    var at: usize = 12;
    while (at + 8 <= size) {
        const id = bytes[at .. at + 4];
        const len: usize = std.mem.readInt(u32, bytes[at + 4 ..][0..4], .little);
        const body = bytes[at + 8 .. @min(size, at + 8 + len)];
        if (std.mem.eql(u8, id, "fmt ") and body.len >= 16) {
            channels = std.mem.readInt(u16, body[2..4], .little);
            hz = @floatFromInt(std.mem.readInt(u32, body[4..8], .little));
        } else if (std.mem.eql(u8, id, "data")) {
            data = body;
        }
        at += 8 + len + (len & 1);
    }
    if (data.len < 4 or channels == 0) return null;
    const in_frames = data.len / (2 * channels);
    const out_frames: usize = @intFromFloat(@as(f32, @floatFromInt(in_frames)) * rate / hz);
    const mem: [*]f32 = @ptrCast(@alignCast(c.malloc(out_frames * @sizeOf(f32)) orelse return null));
    const out = mem[0..out_frames];
    for (out, 0..) |*o, i| {
        const pos = @as(f32, @floatFromInt(i)) * hz / rate;
        const lo: usize = @min(@as(usize, @intFromFloat(pos)), in_frames - 1);
        const hi: usize = @min(lo + 1, in_frames - 1);
        const frac = pos - @as(f32, @floatFromInt(lo));
        const a: f32 = @floatFromInt(std.mem.readInt(i16, data[lo * 2 * channels ..][0..2], .little));
        const b: f32 = @floatFromInt(std.mem.readInt(i16, data[hi * 2 * channels ..][0..2], .little));
        o.* = (a + (b - a) * frac) * (1.0 / 32768.0);
    }
    return out;
}

fn stopClip() void {
    @atomicStore(u32, &clip_on, 0, .release);
    sdl.Delay(30);
    if (clip.len > 0) c.free(clip.ptr);
    clip = &.{};
    clip_pos = 0;
}

// ------------------------------------------------------------------ the items

const Kind = enum { who, ear, promise, tone, backlight, stick, clip };

/// The ear check's staircase: two right in a row and the difference shrinks; one wrong and it
/// grows. Where it turns round, eight times, is where the ear's edge is.
const Ear = struct {
    cents: f32 = 32.0,
    streak: u32 = 0,
    last_way: i32 = 0,
    turns: [8]f32 = @splat(0.0),
    turn_count: u32 = 0,
    trials: u32 = 0,
    seed: u32 = 0x6d2b79f5,
    done: bool = false,

    fn next(self: *Ear) void {
        self.seed ^= self.seed << 13;
        self.seed ^= self.seed >> 17;
        self.seed ^= self.seed << 5;
        ear_first_pure = self.seed & 0x100 != 0;
        ear_cents = self.cents;
        ear_left = ear_pair * 2 + ear_gap;
    }

    fn answer(self: *Ear, said_first: bool) void {
        self.trials += 1;
        const right = said_first == ear_first_pure;
        var way: i32 = 0;
        if (right) {
            self.streak += 1;
            if (self.streak == 2) {
                self.cents = @max(0.5, self.cents / 1.41421);
                self.streak = 0;
                way = -1;
            }
        } else {
            self.cents = @min(64.0, self.cents * 1.41421);
            self.streak = 0;
            way = 1;
        }
        if (way != 0) {
            if (self.last_way != 0 and way != self.last_way and self.turn_count < self.turns.len) {
                self.turns[self.turn_count] = self.cents;
                self.turn_count += 1;
            }
            self.last_way = way;
        }
        self.done = self.turn_count >= self.turns.len or self.trials >= 36;
    }

    /// The middle of the last six turns, as a ratio is averaged.
    fn edge(self: *const Ear) f32 {
        if (self.turn_count == 0) return self.cents;
        const from = if (self.turn_count > 6) self.turn_count - 6 else 0;
        var sum: f32 = 0.0;
        for (self.turns[from..self.turn_count]) |c_| sum += @log(c_);
        return @exp(sum / @as(f32, @floatFromInt(self.turn_count - from)));
    }
};
var ear = Ear{};

const Item = struct {
    kind: Kind,
    name: []const u8,
    question: []const u8,
    file: []const u8 = "",
    /// For a walk: its name, the moment of this build's evening it starts from (room/walks.txt),
    /// what to do there in plain words, and its questions, each for a promise.
    id: []const u8 = "",
    start: []const u8 = "",
    before: []const u8 = "",
    asks: [4]Ask = undefined,
    ask_n: usize = 0,
    ask_i: usize = 0,
    /// For a walk: whether the person has been there yet.
    been: bool = false,
    answer: u8 = 0, // 0 none, 'y', 'n'
    plays: u32 = 0,
};

const Ask = struct { promise: []const u8, question: []const u8 };

const checks = [_]Item{
    .{ .kind = .tone, .name = "a tone", .question = "A plain tone plays for two seconds. Did you hear it clearly through the speaker?" },
    .{ .kind = .backlight, .name = "the backlight", .question = "A swell plays twice and the screen's own light follows it. Did that look good? (No: it pumped, flickered or annoyed.)" },
    .{ .kind = .stick, .name = "the left stick", .question = "Push the LEFT stick UP and hold it there. Then press A." },
};

var items: [160]Item = undefined;
var item_count: usize = 0;
var promise_count: usize = 0;
var manifest: [16 * 1024]u8 = undefined;
var promise_list: [16 * 1024]u8 = undefined;
var holder: []const u8 = "someone";

fn readInto(dir: []const u8, name: []const u8, into: []u8) []const u8 {
    var path: [512]u8 = undefined;
    const p = std.mem.printSentinel(&path, "{s}/{s}", .{ dir, name }, 0) catch return "";
    const file = c.fopen(p.ptr, "r") orelse return "";
    const n = c.fread(into.ptr, 1, into.len, file);
    _ = c.fclose(file);
    return into[0..n];
}

fn loadItems(dir: []const u8) void {
    items[0] = .{ .kind = .who, .name = "who is holding it", .question = "The answers are kept with a name. Who is holding the handheld?" };
    items[1] = .{ .kind = .ear, .name = "the ear, before", .question = "Two pairs of notes. One pair is still and one is turning. Which is STILL? It gets harder until you are guessing: guess. About two minutes." };
    item_count = 2;
    // the walks (room/walks.txt): walk|id|start|title|before, then its questions, ask|promise|question
    var rows = std.mem.splitScalar(u8, readInto(dir, "walks.txt", &promise_list), '\n');
    while (rows.next()) |row| {
        if (item_count >= items.len) break;
        var parts = std.mem.splitScalar(u8, row, '|');
        const what = parts.next() orelse continue;
        if (std.mem.eql(u8, what, "walk")) {
            const id = parts.next() orelse continue;
            const start = parts.next() orelse continue;
            const title = parts.next() orelse continue;
            const before = parts.next() orelse continue;
            items[item_count] = .{ .kind = .promise, .name = title, .question = "", .id = id, .start = start, .before = before };
            item_count += 1;
            promise_count += 1;
        } else if (std.mem.eql(u8, what, "ask") and item_count > 0 and items[item_count - 1].kind == .promise) {
            const walk = &items[item_count - 1];
            const promise = parts.next() orelse continue;
            const question = parts.next() orelse continue;
            if (walk.ask_n < walk.asks.len) {
                walk.asks[walk.ask_n] = .{ .promise = promise, .question = question };
                walk.ask_n += 1;
            }
        }
    }
    for (checks) |check| {
        items[item_count] = check;
        item_count += 1;
    }
    rows = std.mem.splitScalar(u8, readInto(dir, "clips.txt", &manifest), '\n');
    while (rows.next()) |row| {
        if (item_count >= items.len) break;
        var parts = std.mem.splitScalar(u8, row, '|');
        const file_name = parts.next() orelse continue;
        const question = parts.next() orelse continue;
        if (file_name.len == 0) continue;
        items[item_count] = .{ .kind = .clip, .name = file_name, .question = question, .file = file_name };
        item_count += 1;
    }
}

const bone = [4]f32{ 0.886, 0.839, 0.784, 1.0 };
const dim = [4]f32{ 0.55, 0.53, 0.50, 1.0 };
const green = [4]f32{ 0.45, 0.95, 0.60, 1.0 };
const red = [4]f32{ 0.70, 0.02, 0.01, 1.0 };

/// What the backlight was when the room opened, so it can be put back to that.
fn readBacklight() i32 {
    const file = c.fopen("/sys/class/backlight/backlight/brightness", "r") orelse return 200;
    defer _ = c.fclose(file);
    var text: [16]u8 = @splat(0);
    const n = c.fread(&text, 1, text.len - 1, file);
    return std.fmt.parseInt(i32, std.mem.trim(u8, text[0..n], " \n"), 10) catch 200;
}

fn setBacklight(value: i32) void {
    const file = c.fopen("/sys/class/backlight/backlight/brightness", "w") orelse return;
    var text: [8]u8 = undefined;
    const s = std.mem.printSentinel(&text, "{d}", .{value}, 0) catch return;
    _ = c.fputs(s.ptr, file);
    _ = c.fclose(file);
}

fn enter(item: *Item, dir: []const u8) void {
    stopClip();
    ear_left = 0;
    item.plays += 1;
    switch (item.kind) {
        .tone => tone_left = 96000,
        .backlight => {
            swell_total = 48000 * 6;
            swell_left = swell_total;
        },
        .who, .promise, .stick => {},
        .ear => {
            if (!ear.done) ear.next();
        },
        .clip => {
            var path: [512]u8 = undefined;
            const p = std.mem.printSentinel(&path, "{s}/clips/{s}.wav", .{ dir, item.file }, 0) catch return;
            if (loadClip(p.ptr)) |samples| {
                clip = samples;
                clip_pos = 0;
                @atomicStore(u32, &clip_on, 1, .release);
            } else {
                log("room: could not read {s}", .{p});
            }
        },
    }
}

fn openPlay() c.SDL_AudioDeviceID {
    var want = std.mem.zeroes(c.SDL_AudioSpec);
    want.freq = 48000;
    want.format = c.AUDIO_F32SYS;
    want.channels = 2;
    want.samples = 512;
    want.callback = &playCallback;
    var have = std.mem.zeroes(c.SDL_AudioSpec);
    const device = sdl.OpenAudioDevice(null, 0, &want, &have, c.SDL_AUDIO_ALLOW_CHANNELS_CHANGE);
    if (device != 0) {
        out_channels = have.channels;
        sdl.PauseAudioDevice(device, 0);
    } else {
        log("room: no sound device ({s})", .{std.mem.span(sdl.GetError())});
    }
    return device;
}

/// The walk: put the person in the promise's moment, with their own hands, and come back.
fn visit(window: plat.Window, item: *Item, device: *c.SDL_AudioDeviceID) void {
    stopClip();
    if (device.* != 0) sdl.CloseAudioDevice(device.*);
    // from this build's own evening, kept at the walk's moment
    var path: [512]u8 = undefined;
    const save_path = std.mem.printSentinel(&path, "{s}/walks/{s}.save", .{ room_dir, item.start }, 0) catch return;
    log("room: walk {s}: going there (from {s})", .{ item.id, save_path });
    const first: ?[]const u8 = if (item.ask_n > 0) item.asks[0].promise else null;
    _ = dark.run(window, .{ .scene = .evening, .load = save_path.ptr, .walk = item.id, .promise = first });
    item.been = true;
    item.plays += 1;
    device.* = openPlay();
}

/// Wrap `text` at words and draw it from `top` down.
fn paragraph(words: *Type, text: []const u8, top: f32, col: [4]f32) void {
    var y = top;
    var rest = text;
    while (rest.len > 0 and y < 388.0) {
        var take: usize = @min(rest.len, 40);
        if (take < rest.len) {
            while (take > 0 and rest[take] != ' ') take -= 1;
            if (take == 0) take = @min(rest.len, 40);
        }
        words.line(30.0, y, 1.2, col, rest[0..take]);
        rest = std.mem.trimStart(u8, rest[take..], " ");
        y += 34.0;
    }
}

var room_dir: []const u8 = "room";
/// Which build this is (build.sh writes it beside the walks): so a person's answers name the game
/// they were given.
var build_said: []const u8 = "build: not said";
var build_text: [256]u8 = undefined;

pub fn run(window: plat.Window, dir_z: [*:0]const u8, max_frames: u32, dump: ?[*:0]const u8) bool {
    const dir = std.mem.span(dir_z);
    room_dir = dir;
    build_said = std.mem.trim(u8, readInto(dir, "build.txt", &build_text), " \n");
    if (build_said.len == 0) build_said = "build: not said";
    var type_: Type = undefined;
    if (!type_.init(window.width, window.height)) return false;
    loadItems(dir);
    log("room: {d} items (the ear check, {d} walks, {d} checks for the hands, {d} clips for the ears)", .{ item_count, promise_count, checks.len, item_count - 2 - promise_count - checks.len });
    log("room: {s}", .{build_said});

    var device = openPlay();
    defer if (device != 0) sdl.CloseAudioDevice(device);

    var pad: ?*c.SDL_GameController = null;
    var faces = plat.Faces{};
    var j: c_int = 0;
    while (j < sdl.NumJoysticks()) : (j += 1) {
        if (sdl.IsGameController(j) == c.SDL_FALSE) continue;
        pad = sdl.GameControllerOpen(j);
        if (pad) |handle| {
            faces = plat.Faces.find(handle);
            var said: [128]u8 = undefined;
            log("room: controls: {s}; {s}", .{ std.mem.span(sdl.GameControllerName(handle)), faces.describe(&said) });
            break;
        }
    }

    var current: usize = 0;
    var was: [8]bool = @splat(false);
    var frame: u32 = 0;
    var move_on_at: ?u32 = null;
    // after a visit both leaving buttons are still down: they must be let go before they count
    var leave_armed = true;
    const backlight_normal = readBacklight();
    var backlight_was: i32 = backlight_normal;
    enter(&items[0], dir);

    var running = true;
    while (running) : (frame += 1) {
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
        }
        var down: [8]bool = @splat(false);
        if (pad) |handle| {
            // the face buttons by where they are, found by the kernel's codes: on this handheld
            // the right one is printed A (yes), the bottom B (no), the left Y (again)
            down[0] = faces.down(handle, .right);
            down[1] = faces.down(handle, .bottom);
            down[2] = faces.down(handle, .left);
            const others = [4]c_int{
                c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
                c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
                c.SDL_CONTROLLER_BUTTON_BACK,
                c.SDL_CONTROLLER_BUTTON_START,
            };
            for (others, 3..) |button, i| down[i] = sdl.GameControllerGetButton(handle, button) != 0;
            // the top one, printed X: "it didn't happen"
            down[7] = faces.down(handle, .top);
        }
        var pressed: [8]bool = undefined;
        for (0..8) |i| pressed[i] = down[i] and !was[i];
        was = down;
        if (!down[5] and !down[6]) leave_armed = true;
        if (leave_armed and down[5] and down[6]) running = false;

        const item = &items[current];
        var go: i32 = 0;
        if (item.kind == .who) {
            if (pressed[0] or pressed[1] or pressed[2]) {
                holder = if (pressed[0]) "morgan" else if (pressed[1]) "jj" else "other";
                item.answer = 'y';
                log("room: held by {s}", .{holder});
                move_on_at = frame + 15;
            }
        } else if (item.kind == .ear) {
            if (!ear.done and (pressed[0] or pressed[1])) {
                ear.seed +%= frame;
                ear.answer(pressed[0]);
                if (ear.done) {
                    item.answer = 'y';
                    log("room: ear: a still fifth from a turning one: the edge is {d:.1} cents by {s} ({d} trials, {d} turns)", .{ ear.edge(), holder, ear.trials, ear.turn_count });
                    move_on_at = frame + 90;
                } else {
                    ear.next();
                }
            } else if (!ear.done and pressed[2]) {
                ear_left = ear_pair * 2 + ear_gap;
            }
        } else if (item.kind == .promise and !item.been) {
            if (pressed[0]) {
                visit(window, item, &device);
                leave_armed = false;
                was = @splat(true);
                backlight_was = -1;
            }
        } else if (item.kind == .promise and item.ask_i < item.ask_n and (pressed[0] or pressed[1] or pressed[7])) {
            // a walk's questions, one at a time: yes, no, or it didn't happen
            const word: []const u8 = if (pressed[0]) "yes" else if (pressed[1]) "no" else "didn't happen";
            const v = dark.last_visit;
            log("room: promise {s} {s} by {s}; walk {s}; visit: met {s}, stayed {d:.1} s, calls {d}, {d:.0} s there, went {d}", .{
                item.asks[item.ask_i].promise,
                word,
                holder,
                item.id,
                if (!v.witnessed) "-" else if (v.met) "yes" else "no",
                v.stayed_s,
                v.calls,
                v.seconds,
                item.plays - 1,
            });
            item.ask_i += 1;
            if (item.ask_i >= item.ask_n) {
                item.answer = 'y';
                move_on_at = frame + 25;
            }
        } else if (item.kind != .promise and (pressed[0] or pressed[1])) {
            item.answer = if (pressed[0]) 'y' else 'n';
            const word: []const u8 = if (item.answer == 'y') "yes" else "no";
            {
                if (item.kind == .stick and pressed[0]) {
                    if (pad) |handle| {
                        const lx = sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_LEFTX);
                        const ly = sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_LEFTY);
                        log("room: the left stick held up reads x {d}, y {d}: {s}", .{
                            lx,
                            ly,
                            if (ly < -16000 and @abs(@as(i32, lx)) < 12000) "as it should (up is -y)" else "NOT as it should (up should be -y, with x near nought)",
                        });
                    }
                }
                log("room: {s}: {s} by {s} (played {d})", .{ item.name, word, holder, item.plays });
            }
            move_on_at = frame + 25;
        } else if (pressed[2]) {
            if (item.kind == .promise) {
                visit(window, item, &device);
                leave_armed = false;
                was = @splat(true);
                backlight_was = -1;
            } else {
                enter(item, dir);
            }
        }
        if (pressed[3]) go = 1;
        if (pressed[4]) go = -1;
        if (move_on_at) |at| {
            if (frame >= at) {
                go = 1;
                move_on_at = null;
            }
        }
        if (go != 0) {
            const next: i64 = @as(i64, @intCast(current)) + go;
            if (next >= 0 and next < @as(i64, @intCast(item_count))) {
                current = @intCast(next);
                enter(&items[current], dir);
            } else if (next >= @as(i64, @intCast(item_count))) {
                running = false;
            }
        }

        // the backlight follows the swell, and nothing else; a scene's own light is put back
        if (items[current].kind == .backlight) {
            const lv: i32 = 20 + @as(i32, @intCast(@atomicLoad(u32, &swell_level, .monotonic) * 180 / 1000));
            if (lv != backlight_was) {
                setBacklight(lv);
                backlight_was = lv;
            }
        } else if (backlight_was != backlight_normal) {
            setBacklight(backlight_normal);
            backlight_was = backlight_normal;
        }

        // the screen
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.Viewport(0, 0, window.width, window.height);
        gl.ClearColor(0.0, 0.0, 0.0, 1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT);
        const shown = &items[current];
        var head: [64]u8 = undefined;
        const head_text: []const u8 = std.mem.printSentinel(&head, "the room   {d} of {d}", .{ current + 1, item_count }, 0) catch "the room";
        type_.line(30.0, 24.0, 1.0, dim, head_text);
        type_.line(30.0, 70.0, 1.7, bone, shown.name[0..@min(shown.name.len, 28)]);
        if (shown.name.len > 28) type_.line(30.0, 106.0, 1.2, bone, shown.name[28..@min(shown.name.len, 68)]);
        if (shown.kind == .promise and !shown.been) {
            paragraph(&type_, shown.before, 120.0, bone);
            type_.line(30.0, 395.0, 1.0, dim, "Hold Select and Start to come back; questions follow.");
            type_.line(30.0, 420.0, 1.0, dim, "A go there   R1 skip   L1 back");
        } else if (shown.kind == .promise) {
            if (shown.ask_i < shown.ask_n) {
                var count: [48]u8 = undefined;
                const which: []const u8 = std.mem.printSentinel(&count, "question {d} of {d}", .{ shown.ask_i + 1, shown.ask_n }, 0) catch "";
                type_.line(30.0, 106.0, 1.0, dim, which);
                paragraph(&type_, shown.asks[shown.ask_i].question, 150.0, bone);
            } else {
                paragraph(&type_, "Thank you.", 150.0, bone);
            }
            type_.line(30.0, 420.0, 1.0, dim, "A yes   B no   X didn't happen   Y go again");
        } else {
            paragraph(&type_, shown.question, 150.0, bone);
            const keys: []const u8 = switch (shown.kind) {
                .who => "A Morgan   B JJ   Y someone else",
                .ear => "A the first   B the second   Y again   R1 skip",
                .promise => "A yes   B no   Y go there again   R1 next",
                else => "A yes   B no   Y again   R1 next   L1 back",
            };
            type_.line(30.0, 420.0, 1.0, dim, keys);
        }
        if (shown.kind == .ear) {
            var count: [48]u8 = undefined;
            const text: []const u8 = if (ear.done)
                (std.mem.printSentinel(&count, "done: {d:.1} cents", .{ear.edge()}, 0) catch "done")
            else
                (std.mem.printSentinel(&count, "pair {d}", .{ear.trials + 1}, 0) catch "");
            type_.line(30.0, 106.0, 1.2, dim, text);
        }
        if (shown.answer == 'y' and shown.kind != .who and shown.kind != .ear) type_.line(470.0, 70.0, 1.7, green, "yes");
        if (shown.answer == 'n') type_.line(470.0, 70.0, 1.7, red, "no");
        type_.line(30.0, 448.0, 1.0, dim, "Select and Start together: leave");
        type_.flush();
        if (dump) |out_dir| {
            if (frame == 2) {
                const n: usize = @intCast(window.width * window.height * 4);
                if (c.malloc(n)) |mem| {
                    const pixels: [*]u8 = @ptrCast(mem);
                    gl.ReadPixels(0, 0, window.width, window.height, c.GL_RGBA, c.GL_UNSIGNED_BYTE, pixels);
                    var path: [512]u8 = undefined;
                    if (std.mem.printSentinel(&path, "{s}/room.png", .{std.mem.span(out_dir)}, 0)) |text| {
                        _ = png.writeFromGl(text.ptr, @intCast(window.width), @intCast(window.height), pixels[0..n]);
                    } else |_| {}
                    c.free(mem);
                }
            }
        }
        sdl.GL_SwapWindow(window.handle);
        if (max_frames > 0 and frame + 1 >= max_frames) running = false;
    }

    stopClip();
    setBacklight(backlight_normal);
    var answered: u32 = 0;
    for (items[0..item_count]) |it| {
        if (it.answer != 0) answered += 1;
    }
    log("room: left after {d} of {d} items were answered", .{ answered, item_count });
    return plat.checkGl("the room");
}
