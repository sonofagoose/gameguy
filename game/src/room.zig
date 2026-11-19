//! The room: where Morgan's ears, eyes and hands answer, and every answer is logged.
//!
//! Fable can't hear, can't feel a motor and can't see the handheld's screen. So each thing only a
//! person can judge is put here as one item: something plays or happens, a question is asked, and
//! a button answers it. The session log is the result (SPEC.md, section 21).
//!
//! Buttons, by the letters this handheld prints: A (right) yes, B (bottom) no, Y (left) again,
//! R1 next, L1 back, Select and Start together leave.
//!
//! The items: a tone, the rumble line, the backlight following a swell, the left stick, a headset's
//! microphone, and then every listening clip in the folder's `clips.txt`.
const std = @import("std");
const plat = @import("plat/plat.zig");
const font = @import("plat/font.zig");
const png = @import("plat/png.zig");
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

const Type = struct {
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

    fn init(self: *Type, w: i32, h: i32) bool {
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
    fn line(self: *Type, x: f32, y: f32, scale: f32, col: [4]f32, string: []const u8) void {
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

    fn flush(self: *Type) void {
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

// ------------------------------------------------------------------ what listens

var heard: [48000 * 5]f32 = undefined;
var heard_n: usize = 0;
var in_channels: usize = 1;

fn hearCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * in_channels);
    const in: [*]const f32 = @ptrCast(@alignCast(stream));
    var n = @atomicLoad(usize, &heard_n, .monotonic);
    for (0..frames) |i| {
        if (n >= heard.len) break;
        // the loudest of the channels: on this board only one carries anything
        var s: f32 = 0.0;
        for (0..in_channels) |ch| {
            const v = in[i * in_channels + ch];
            if (@abs(v) > @abs(s)) s = v;
        }
        heard[n] = s;
        n += 1;
    }
    @atomicStore(usize, &heard_n, n, .release);
}

fn level(samples: []const f32) f32 {
    if (samples.len == 0) return -120.0;
    var mean: f64 = 0.0;
    for (samples) |x| mean += x;
    mean /= @floatFromInt(samples.len);
    var sum: f64 = 0.0;
    for (samples) |x| sum += (x - mean) * (x - mean);
    const rms = @sqrt(sum / @as(f64, @floatFromInt(samples.len)));
    return @floatCast(20.0 * @log10(@max(rms, 1e-9)));
}

/// Record a second of quiet and three of whatever is said, through the recording path.
fn hearHeadset(screen: *Screen) void {
    _ = c.system("amixer -q -c 0 sset 'Capture MIC Path' 'Main Mic' > /dev/null 2>&1");
    defer _ = c.system("amixer -q -c 0 sset 'Capture MIC Path' 'MIC OFF' > /dev/null 2>&1");
    var want = std.mem.zeroes(c.SDL_AudioSpec);
    want.freq = 48000;
    want.format = c.AUDIO_F32SYS;
    want.channels = 2;
    want.samples = 1024;
    want.callback = &hearCallback;
    var have = std.mem.zeroes(c.SDL_AudioSpec);
    const device = sdl.OpenAudioDevice(null, 1, &want, &have, c.SDL_AUDIO_ALLOW_CHANNELS_CHANGE);
    if (device == 0) {
        log("room: headset: the recording path did not open ({s})", .{std.mem.span(sdl.GetError())});
        return;
    }
    in_channels = have.channels;
    @atomicStore(usize, &heard_n, 0, .release);
    sdl.PauseAudioDevice(device, 0);
    screen.say("QUIET FOR A MOMENT...", "");
    sdl.Delay(1300);
    const quiet_end = @min(@atomicLoad(usize, &heard_n, .acquire), heard.len);
    screen.say("NOW: SAY AH", "for three seconds, into the headset's microphone");
    sdl.Delay(3200);
    const end = @min(@atomicLoad(usize, &heard_n, .acquire), heard.len);
    sdl.CloseAudioDevice(device);
    const quiet = level(heard[@min(4800, quiet_end)..quiet_end]);
    const voice = level(heard[quiet_end..end]);
    var peak: f32 = 0.0;
    for (heard[quiet_end..end]) |x| peak = @max(peak, @abs(x));
    log("room: headset: quiet {d:.1} dBFS, then {d:.1} dBFS with a peak of {d:.3}: {s}", .{
        quiet,
        voice,
        peak,
        if (voice > quiet + 12.0) "the jack hears a voice" else "no voice came through",
    });
}

// ------------------------------------------------------------------ the rumble line

/// Find the gamepad among the kernel's input devices and play one rumble effect through it.
fn rumble() void {
    var text: [8192]u8 = undefined;
    const file = c.fopen("/proc/bus/input/devices", "r") orelse return;
    const n = c.fread(&text, 1, text.len, file);
    _ = c.fclose(file);
    const all = text[0..n];
    const at = std.mem.indexOf(u8, all, "Gamepad") orelse {
        log("room: rumble: no gamepad among the input devices", .{});
        return;
    };
    const handlers = std.mem.indexOfPos(u8, all, at, "Handlers=") orelse return;
    const ev = std.mem.indexOfPos(u8, all, handlers, "event") orelse return;
    var number: u32 = 0;
    var i = ev + 5;
    while (i < all.len and all[i] >= '0' and all[i] <= '9') : (i += 1) number = number * 10 + (all[i] - '0');
    var path: [64]u8 = undefined;
    const p = std.mem.printSentinel(&path, "/dev/input/event{d}", .{number}, 0) catch return;
    const fd = c.open(p.ptr, c.O_RDWR);
    if (fd < 0) {
        log("room: rumble: could not open {s}", .{p});
        return;
    }
    defer _ = c.close(fd);
    // struct input_event: two 64-bit times, then type, code, value
    const Event = extern struct { sec: i64 = 0, usec: i64 = 0, kind: u16, code: u16, value: i32 };
    const ev_ff: u16 = 0x15;
    var gain = Event{ .kind = ev_ff, .code = 0x60, .value = 0xFFFF }; // FF_GAIN: without it the pin stays low
    _ = c.write(fd, &gain, @sizeOf(Event));
    // struct ff_effect, 48 bytes: type, id, direction, trigger, replay, then the rumble's two strengths
    var effect: [48]u8 = @splat(0);
    std.mem.writeInt(u16, effect[0..2], 0x50, .little); // FF_RUMBLE
    std.mem.writeInt(i16, effect[2..4], -1, .little);
    std.mem.writeInt(u16, effect[10..12], 350, .little); // length, ms
    std.mem.writeInt(u16, effect[16..18], 0xFFFF, .little);
    std.mem.writeInt(u16, effect[18..20], 0xFFFF, .little);
    if (c.ioctl(fd, @as(c_ulong, 0x40304580), &effect) < 0) { // EVIOCSFF
        log("room: rumble: the effect was refused", .{});
        return;
    }
    const id = std.mem.readInt(i16, effect[2..4], .little);
    for (0..3) |_| {
        var play = Event{ .kind = ev_ff, .code = @intCast(id), .value = 1 };
        _ = c.write(fd, &play, @sizeOf(Event));
        sdl.Delay(600);
    }
    log("room: rumble: three effects played through {s}", .{p});
}

// ------------------------------------------------------------------ the items

const Kind = enum { tone, rumble, backlight, stick, headset, clip };

const Item = struct {
    kind: Kind,
    name: []const u8,
    question: []const u8,
    file: []const u8 = "",
    answer: u8 = 0, // 0 none, 'y', 'n'
    plays: u32 = 0,
};

const checks = [_]Item{
    .{ .kind = .tone, .name = "a tone", .question = "A plain tone plays for two seconds. Did you hear it clearly through the speaker?" },
    .{ .kind = .rumble, .name = "the rumble line", .question = "Hold the handheld. Three short pulses are sent to its rumble line. Did it buzz?" },
    .{ .kind = .backlight, .name = "the backlight", .question = "A swell plays twice and the screen's own light follows it. Did that look good? (No: it pumped, flickered or annoyed.)" },
    .{ .kind = .stick, .name = "the left stick", .question = "Push the LEFT stick UP and hold it there. Then press A." },
    .{ .kind = .headset, .name = "a headset", .question = "Plug a phone headset WITH a microphone into the jack. Press A, stay quiet a moment, then say AH. (No headset: press B.)" },
};

var items: [80]Item = undefined;
var item_count: usize = 0;
var manifest: [16 * 1024]u8 = undefined;

fn loadItems(dir: []const u8) void {
    for (checks) |check| {
        items[item_count] = check;
        item_count += 1;
    }
    var path: [512]u8 = undefined;
    const p = std.mem.printSentinel(&path, "{s}/clips.txt", .{dir}, 0) catch return;
    const file = c.fopen(p.ptr, "r") orelse {
        log("room: no clips.txt in {s}; only the hand checks", .{dir});
        return;
    };
    const n = c.fread(&manifest, 1, manifest.len, file);
    _ = c.fclose(file);
    var rows = std.mem.splitScalar(u8, manifest[0..n], '\n');
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

const Screen = struct {
    window: plat.Window,
    words: *Type,

    /// A whole screen of two lines, for the moments in the middle of a check.
    fn say(self: *Screen, big: []const u8, small: []const u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.Viewport(0, 0, self.window.width, self.window.height);
        gl.ClearColor(0.0, 0.0, 0.0, 1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT);
        self.words.line(30.0, 180.0, 2.0, bone, big);
        self.words.line(30.0, 250.0, 1.0, dim, small);
        self.words.flush();
        sdl.GL_SwapWindow(self.window.handle);
    }
};

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
    item.plays += 1;
    switch (item.kind) {
        .tone => tone_left = 96000,
        .rumble => rumble(),
        .backlight => {
            swell_total = 48000 * 6;
            swell_left = swell_total;
        },
        .stick, .headset => {},
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

pub fn run(window: plat.Window, dir_z: [*:0]const u8, max_frames: u32, dump: ?[*:0]const u8) bool {
    const dir = std.mem.span(dir_z);
    var type_: Type = undefined;
    if (!type_.init(window.width, window.height)) return false;
    var screen = Screen{ .window = window, .words = &type_ };
    loadItems(dir);
    log("room: {d} items ({d} checks for the hands, {d} clips for the ears)", .{ item_count, checks.len, item_count - checks.len });

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
    defer if (device != 0) sdl.CloseAudioDevice(device);

    var pad: ?*c.SDL_GameController = null;
    var j: c_int = 0;
    while (j < sdl.NumJoysticks()) : (j += 1) {
        if (sdl.IsGameController(j) == c.SDL_FALSE) continue;
        pad = sdl.GameControllerOpen(j);
        if (pad != null) break;
    }

    var current: usize = 0;
    var was: [7]bool = @splat(false);
    var frame: u32 = 0;
    var move_on_at: ?u32 = null;
    const backlight_normal = readBacklight();
    var backlight_was: i32 = backlight_normal;
    enter(&items[0], dir);

    var running = true;
    while (running) : (frame += 1) {
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
        }
        var down: [7]bool = @splat(false);
        if (pad) |handle| {
            const buttons = [7]c_int{
                c.SDL_CONTROLLER_BUTTON_B, // right face, printed A: yes
                c.SDL_CONTROLLER_BUTTON_A, // bottom face, printed B: no
                c.SDL_CONTROLLER_BUTTON_X, // left face, printed Y: again
                c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER,
                c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER,
                c.SDL_CONTROLLER_BUTTON_BACK,
                c.SDL_CONTROLLER_BUTTON_START,
            };
            for (buttons, 0..) |button, i| down[i] = sdl.GameControllerGetButton(handle, button) != 0;
        }
        var pressed: [7]bool = undefined;
        for (0..7) |i| pressed[i] = down[i] and !was[i];
        was = down;
        if (down[5] and down[6]) running = false;

        const item = &items[current];
        var go: i32 = 0;
        if (pressed[0] or pressed[1]) {
            item.answer = if (pressed[0]) 'y' else 'n';
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
            } else if (item.kind == .headset and pressed[0]) {
                hearHeadset(&screen);
            }
            log("room: {s}: {s} (played {d})", .{ item.name, if (item.answer == 'y') "yes" else "no", item.plays });
            move_on_at = frame + 25;
        }
        if (pressed[2]) enter(item, dir);
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

        // the backlight follows the swell, and nothing else
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
        // the question, wrapped at words
        var y: f32 = 140.0;
        var rest = shown.question;
        while (rest.len > 0 and y < 380.0) {
            var take: usize = @min(rest.len, 40);
            if (take < rest.len) {
                while (take > 0 and rest[take] != ' ') take -= 1;
                if (take == 0) take = @min(rest.len, 40);
            }
            type_.line(30.0, y, 1.2, bone, rest[0..take]);
            rest = std.mem.trimStart(u8, rest[take..], " ");
            y += 34.0;
        }
        if (shown.answer == 'y') type_.line(470.0, 70.0, 1.7, green, "yes");
        if (shown.answer == 'n') type_.line(470.0, 70.0, 1.7, red, "no");
        type_.line(30.0, 420.0, 1.0, dim, "A yes   B no   Y again   R1 next   L1 back");
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
