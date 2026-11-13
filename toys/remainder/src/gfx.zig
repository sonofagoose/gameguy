//! Drawing. The water is one full-screen shader: black is the field, and light appears only
//! where the player's tone and a place's tone nearly agree. Marks and labels are a single
//! batch of quads on top.
const std = @import("std");
const platform = @import("common").platform;
const world_mod = @import("world.zig");
const font = @import("common").font;
const c = platform.c;
const gl = platform.gl;

pub const Color = [4]f32;

fn hex(comptime rgb: u24) Color {
    return .{
        @as(f32, @floatFromInt((rgb >> 16) & 0xff)) / 255.0,
        @as(f32, @floatFromInt((rgb >> 8) & 0xff)) / 255.0,
        @as(f32, @floatFromInt(rgb & 0xff)) / 255.0,
        1.0,
    };
}

pub fn faded(color: Color, alpha: f32) Color {
    return .{ color[0], color[1], color[2], color[3] * alpha };
}

// Khole Caddy Style Book v1.1, section 04.
pub const void_black = hex(0x0A0A0A);
pub const bone = hex(0xE2D6C8);
pub const chrome = hex(0xC0C0C0);
pub const aster = hex(0x773FA8);
pub const verbena = hex(0x907ECF);
pub const snowberry = hex(0xC194CA);

/// How many places' patterns the water shader draws at once (the strongest ones).
pub const water_places = 4;

const water_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\void main() { gl_Position = vec4(a_pos, 0.0, 1.0); }
;

const water_fs =
    \\#version 300 es
    \\precision highp float;
    \\uniform vec2 u_frame;      // framebuffer height in fragments; pool pixels per fragment
    \\uniform vec4 u_place[4];   // x, y, arms, strength
    \\uniform vec4 u_wave[4];    // crests per pixel, phase in turns, bloom, unused
    \\uniform vec4 u_player;     // x, y, wake phase in turns, wake strength
    \\uniform vec4 u_light;      // light direction x, y; contrast; grain seed
    \\uniform vec3 u_lead;       // the one garden colour
    \\out vec4 o;
    \\
    \\// sin(2 pi t) from a parabola: accurate to a fraction of a percent, a few operations
    \\mediump float wave(highp float t) {
    \\    mediump float x = fract(t) * 2.0 - 1.0;
    \\    mediump float y = 4.0 * x * (1.0 - abs(x));
    \\    return -(0.225 * (y * abs(y) - y) + y);
    \\}
    \\
    \\void main() {
    \\    highp vec2 p = vec2(gl_FragCoord.x, u_frame.x - gl_FragCoord.y) * u_frame.y;
    \\    mediump float height = 0.0;
    \\    mediump vec2 slope = vec2(0.0);
    \\    mediump float energy = 0.0;
    \\    mediump float glow = 0.0;
    \\    for (int i = 0; i < 4; i++) {
    \\        highp vec2 d = p - u_place[i].xy;
    \\        highp float r2 = dot(d, d) + 0.01;
    \\        highp float ir = inversesqrt(r2);
    \\        highp float r = r2 * ir;
    \\        mediump vec2 e = d * ir;
    \\        // (cos, sin) of arms * angle, by multiplying the unit vector by itself
    \\        mediump vec2 z = vec2(1.0, 0.0);
    \\        int arms = int(u_place[i].z);
    \\        for (int j = 0; j < arms; j++) z = vec2(z.x * e.x - z.y * e.y, z.x * e.y + z.y * e.x);
    \\        highp float t = u_wave[i].x * r - u_wave[i].y;
    \\        mediump float s = wave(t);
    \\        mediump float co = wave(t + 0.25);
    \\        mediump float fall = -(s * z.x + co * z.y);
    \\        mediump float q = r * (1.0 / 220.0);
    \\        mediump float env = u_place[i].w / (1.0 + q * q) * clamp((r - 10.0) * 0.06, 0.0, 1.0);
    \\        mediump float around = u_place[i].z * 0.159155 * ir;
    \\        height += env * (co * z.x - s * z.y);
    \\        slope += env * fall * (u_wave[i].x * e + around * vec2(-e.y, e.x));
    \\        energy += env;
    \\        mediump float b = 1.0 / (1.0 + r2 * (1.0 / 1500.0));
    \\        glow += u_wave[i].z * b * b;
    \\    }
    \\    // the player's own wake: small quick rings
    \\    highp vec2 dp = p - u_player.xy;
    \\    highp float rp2 = dot(dp, dp) + 0.01;
    \\    highp float irp = inversesqrt(rp2);
    \\    mediump float wenv = u_player.w / (1.0 + rp2 * (1.0 / 1500.0));
    \\    highp float tp = rp2 * irp * (1.0 / 16.0) - u_player.z;
    \\    mediump float wake = smoothstep(0.05, 0.16, wenv * wave(tp + 0.25));
    \\
    \\    // Black is the field. Light lives only on the crests, and a crest is shaded like a
    \\    // strip of chrome: bright flank, a hard horizon along the top, dark flank.
    \\    mediump float ridge = smoothstep(0.10, 0.34, height);
    \\    mediump float tilt = clamp(dot(slope, u_light.xy) * u_light.z * 0.5 + 0.5, 0.0, 1.0);
    \\    mediump float sky = mix(0.58, 0.95, smoothstep(0.55, 1.0, tilt));
    \\    mediump float ground = mix(0.16, 0.90, smoothstep(0.05, 0.50, tilt));
    \\    mediump float metal = mix(ground, sky, smoothstep(0.47, 0.53, tilt));
    \\    mediump vec3 col = vec3(0.95, 0.93, 0.90) * max(metal * ridge, wake * 0.34);
    \\    // the one garden colour: a haze in the troughs, and the bloom of a place at rest
    \\    col += u_lead * (clamp(energy, 0.0, 1.0) * 0.20 * (1.0 - ridge) + glow * 0.9);
    \\    // one texture pass: fine grain
    \\    highp float n = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233)) + u_light.w) * 43758.5453);
    \\    col += vec3(0.039) + (n - 0.5) * 0.03;
    \\    o = vec4(col, 1.0);
    \\}
;

const blit_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\out vec2 v_uv;
    \\void main() { v_uv = a_pos * 0.5 + 0.5; gl_Position = vec4(a_pos, 0.0, 1.0); }
;

const blit_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\uniform sampler2D u_tex;
    \\out vec4 o;
    \\void main() { o = texture(u_tex, v_uv); }
;

const mark_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\layout(location = 1) in vec2 a_uv;
    \\layout(location = 2) in vec4 a_col;
    \\layout(location = 3) in float a_kind;
    \\uniform vec2 u_size;
    \\out vec2 v_uv;
    \\out vec4 v_col;
    \\out float v_kind;
    \\void main() {
    \\    v_uv = a_uv;
    \\    v_col = a_col;
    \\    v_kind = a_kind;
    \\    vec2 q = a_pos / u_size * 2.0 - 1.0;
    \\    gl_Position = vec4(q.x, -q.y, 0.0, 1.0);
    \\}
;

const mark_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\in vec4 v_col;
    \\in float v_kind;
    \\uniform sampler2D u_font;
    \\out vec4 o;
    \\void main() {
    \\    float a;
    \\    if (v_kind < 0.5) {
    \\        a = texture(u_font, v_uv).r;                                   // label
    \\    } else {
    \\        float d = length(v_uv * 2.0 - 1.0);
    \\        if (v_kind < 1.5) a = 1.0 - smoothstep(0.75, 1.0, d);          // disc
    \\        else if (v_kind < 2.5) a = smoothstep(0.70, 0.82, d) * (1.0 - smoothstep(0.88, 1.0, d));  // ring
    \\        else a = (1.0 - d) * (1.0 - d) * step(d, 1.0);                 // glow
    \\    }
    \\    o = vec4(v_col.rgb, v_col.a * a);
    \\}
;

fn compile(kind: c.GLenum, source: [:0]const u8, name: []const u8) ?c.GLuint {
    const shader = gl.CreateShader(kind);
    var text: [*c]const u8 = source.ptr;
    gl.ShaderSource(shader, 1, &text, null);
    gl.CompileShader(shader);
    var ok: c.GLint = 0;
    gl.GetShaderiv(shader, c.GL_COMPILE_STATUS, &ok);
    if (ok == 0) {
        var info: [1024]u8 = @splat(0);
        gl.GetShaderInfoLog(shader, info.len - 1, null, &info);
        platform.log("shader '{s}' did not compile: {s}", .{ name, std.mem.sliceTo(&info, 0) });
        return null;
    }
    return shader;
}

fn link(vs_source: [:0]const u8, fs_source: [:0]const u8, name: []const u8) ?c.GLuint {
    const vs = compile(c.GL_VERTEX_SHADER, vs_source, name) orelse return null;
    const fs = compile(c.GL_FRAGMENT_SHADER, fs_source, name) orelse return null;
    const program = gl.CreateProgram();
    gl.AttachShader(program, vs);
    gl.AttachShader(program, fs);
    gl.LinkProgram(program);
    gl.DeleteShader(vs);
    gl.DeleteShader(fs);
    var ok: c.GLint = 0;
    gl.GetProgramiv(program, c.GL_LINK_STATUS, &ok);
    if (ok == 0) {
        var info: [1024]u8 = @splat(0);
        gl.GetProgramInfoLog(program, info.len - 1, null, &info);
        platform.log("program '{s}' did not link: {s}", .{ name, std.mem.sliceTo(&info, 0) });
        return null;
    }
    return program;
}

const floats_per_vertex = 9; // x y u v r g b a kind
const max_quads = 1200;

pub const Renderer = struct {
    width: i32,
    height: i32,
    /// 1: water at full resolution. 2: water at half resolution, stretched.
    scale: u8 = 1,

    water: c.GLuint,
    blit: c.GLuint,
    marks: c.GLuint,
    u_frame: c.GLint,
    u_place: c.GLint,
    u_wave: c.GLint,
    u_player: c.GLint,
    u_light: c.GLint,
    u_lead: c.GLint,
    u_blit_tex: c.GLint,
    u_mark_size: c.GLint,
    u_mark_font: c.GLint,

    vao: c.GLuint = 0,
    triangle: c.GLuint = 0,
    batch: c.GLuint = 0,
    font_tex: c.GLuint = 0,
    half_fbo: c.GLuint = 0,
    half_tex: c.GLuint = 0,

    verts: [max_quads * 6 * floats_per_vertex]f32 = undefined,
    used: usize = 0,

    /// Fills `self` in place (it is too large to return by value comfortably).
    pub fn init(self: *Renderer, width: i32, height: i32) bool {
        const water = link(water_vs, water_fs, "water") orelse return false;
        const blit = link(blit_vs, blit_fs, "blit") orelse return false;
        const marks = link(mark_vs, mark_fs, "marks") orelse return false;
        self.* = .{
            .width = width,
            .height = height,
            .water = water,
            .blit = blit,
            .marks = marks,
            .u_frame = gl.GetUniformLocation(water, "u_frame"),
            .u_place = gl.GetUniformLocation(water, "u_place"),
            .u_wave = gl.GetUniformLocation(water, "u_wave"),
            .u_player = gl.GetUniformLocation(water, "u_player"),
            .u_light = gl.GetUniformLocation(water, "u_light"),
            .u_lead = gl.GetUniformLocation(water, "u_lead"),
            .u_blit_tex = gl.GetUniformLocation(blit, "u_tex"),
            .u_mark_size = gl.GetUniformLocation(marks, "u_size"),
            .u_mark_font = gl.GetUniformLocation(marks, "u_font"),
        };

        gl.GenVertexArrays(1, &self.vao);
        gl.BindVertexArray(self.vao);
        gl.GenBuffers(1, &self.triangle);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.triangle);
        const corners = [6]f32{ -1.0, -1.0, 3.0, -1.0, -1.0, 3.0 };
        gl.BufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(corners)), &corners, c.GL_STATIC_DRAW);
        gl.GenBuffers(1, &self.batch);

        gl.GenTextures(1, &self.font_tex);
        gl.BindTexture(c.GL_TEXTURE_2D, self.font_tex);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, font.w, font.h, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, font.pixels.ptr);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
        setFilter(c.GL_NEAREST);

        // half-resolution target for the water, used when the full-resolution shader is too slow
        gl.GenTextures(1, &self.half_tex);
        gl.BindTexture(c.GL_TEXTURE_2D, self.half_tex);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA8, @divTrunc(width, 2), @divTrunc(height, 2), 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
        setFilter(c.GL_LINEAR);
        gl.GenFramebuffers(1, &self.half_fbo);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.half_fbo);
        gl.FramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, self.half_tex, 0);
        const status = gl.CheckFramebufferStatus(c.GL_FRAMEBUFFER);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        if (status != c.GL_FRAMEBUFFER_COMPLETE) {
            platform.log("half-resolution target incomplete: 0x{x}", .{status});
            return false;
        }
        return checkGl("renderer init");
    }

    fn setFilter(filter: c.GLint) void {
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, filter);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, filter);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    }

    fn fullScreenTriangle(self: *Renderer) void {
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.triangle);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);
        gl.DrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    /// The water: the patterns of the (up to four) places the player most nearly agrees with.
    pub fn drawWater(self: *Renderer, world: *const world_mod.World, grain_seed: f32) void {
        var place: [water_places * 4]f32 = @splat(0.0);
        var wave: [water_places * 4]f32 = @splat(0.0);
        var taken: [world_mod.max_places]bool = @splat(false);
        var strongest: f32 = 0.0;
        for (world.places[0..world.count]) |p| strongest = @max(strongest, p.strength);
        for (0..water_places) |slot| {
            var best: ?usize = null;
            for (0..world.count) |i| {
                if (taken[i]) continue;
                const p = world.places[i];
                // faint patterns under a strong one only muddy it
                if (p.strength < 0.3 * strongest or (p.strength < 0.004 and p.bloom < 0.01)) continue;
                if (best == null or p.strength > world.places[best.?].strength) best = i;
            }
            const i = best orelse break;
            taken[i] = true;
            const p = world.places[i];
            place[slot * 4 + 0] = p.x;
            place[slot * 4 + 1] = p.y;
            place[slot * 4 + 2] = @floatFromInt(p.arms);
            // weaker agreements are drawn stronger than they pull, so they can still be read
            place[slot * 4 + 3] = std.math.pow(f32, p.strength, 0.6);
            wave[slot * 4 + 0] = 1.0 / world.feel.ring_px;
            wave[slot * 4 + 1] = @floatCast(p.turns);
            wave[slot * 4 + 2] = p.bloom;
        }

        const half = self.scale == 2;
        const target_h = if (half) @divTrunc(self.height, 2) else self.height;
        const target_w = if (half) @divTrunc(self.width, 2) else self.width;
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, if (half) self.half_fbo else 0);
        gl.Viewport(0, 0, target_w, target_h);
        gl.Disable(c.GL_BLEND);
        gl.UseProgram(self.water);
        const pool_per_fragment = world_mod.pool_h / @as(f32, @floatFromInt(target_h));
        gl.Uniform2f(self.u_frame, @floatFromInt(target_h), pool_per_fragment);
        gl.Uniform4fv(self.u_place, water_places, &place);
        gl.Uniform4fv(self.u_wave, water_places, &wave);
        const wake_turns: f32 = @floatCast(@mod(world.time * 1.6, 1.0));
        gl.Uniform4f(self.u_player, world.x, world.y, wake_turns, 0.26);
        gl.Uniform4f(self.u_light, -0.6, -0.8, 110.0, grain_seed);
        gl.Uniform3f(self.u_lead, aster[0], aster[1], aster[2]);
        self.fullScreenTriangle();

        if (half) {
            gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
            gl.Viewport(0, 0, self.width, self.height);
            gl.UseProgram(self.blit);
            gl.ActiveTexture(c.GL_TEXTURE0);
            gl.BindTexture(c.GL_TEXTURE_2D, self.half_tex);
            gl.Uniform1i(self.u_blit_tex, 0);
            self.fullScreenTriangle();
        }
    }

    fn quad(self: *Renderer, x0: f32, y0: f32, x1: f32, y1: f32, s0: f32, t0: f32, s1: f32, t1: f32, color: Color, kind: f32) void {
        if (self.used + 6 * floats_per_vertex > self.verts.len) return;
        const corners = [6][4]f32{
            .{ x0, y0, s0, t0 }, .{ x1, y0, s1, t0 }, .{ x1, y1, s1, t1 },
            .{ x0, y0, s0, t0 }, .{ x1, y1, s1, t1 }, .{ x0, y1, s0, t1 },
        };
        for (corners) |corner| {
            const v = self.verts[self.used .. self.used + floats_per_vertex];
            v[0] = corner[0];
            v[1] = corner[1];
            v[2] = corner[2];
            v[3] = corner[3];
            v[4] = color[0];
            v[5] = color[1];
            v[6] = color[2];
            v[7] = color[3];
            v[8] = kind;
            self.used += floats_per_vertex;
        }
    }

    pub fn disc(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.quad(x - radius, y - radius, x + radius, y + radius, 0.0, 0.0, 1.0, 1.0, color, 1.0);
    }

    pub fn ring(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.quad(x - radius, y - radius, x + radius, y + radius, 0.0, 0.0, 1.0, 1.0, color, 2.0);
    }

    pub fn glow(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.quad(x - radius, y - radius, x + radius, y + radius, 0.0, 0.0, 1.0, 1.0, color, 3.0);
    }

    pub fn rect(self: *Renderer, x: f32, y: f32, w: f32, h: f32, color: Color) void {
        // the middle of the atlas's last cell, which is solid
        const s: f32 = 15.5 * @as(f32, font.cw) / @as(f32, font.w);
        const t: f32 = 5.5 * @as(f32, font.ch) / @as(f32, font.h);
        self.quad(x, y, x + w, y + h, s, t, s, t, color, 0.0);
    }

    /// One line of label type: Space Mono, tracked wide. Coordinates are pool pixels.
    pub fn text(self: *Renderer, x: f32, y: f32, color: Color, string: []const u8) void {
        const tracking = 3.0;
        var pen = x;
        for (string) |ch| {
            if (ch > 32 and ch < 127) {
                const index: usize = ch - 32;
                const cx: f32 = @floatFromInt((index % 16) * font.cw);
                const cy: f32 = @floatFromInt((index / 16) * font.ch);
                self.quad(
                    pen,
                    y,
                    pen + font.cw,
                    y + font.ch,
                    cx / font.w,
                    cy / font.h,
                    (cx + font.cw) / font.w,
                    (cy + font.ch) / font.h,
                    color,
                    0.0,
                );
            }
            pen += font.cw + tracking;
        }
    }

    pub fn textWidth(string: []const u8) f32 {
        return @as(f32, @floatFromInt(string.len)) * (font.cw + 3.0);
    }

    /// Draw everything queued by disc / ring / glow / text, over the water.
    pub fn flush(self: *Renderer) void {
        if (self.used == 0) return;
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.Viewport(0, 0, self.width, self.height);
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
        gl.UseProgram(self.marks);
        gl.Uniform2f(self.u_mark_size, world_mod.pool_w, world_mod.pool_h);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.font_tex);
        gl.Uniform1i(self.u_mark_font, 0);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.batch);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(self.used * @sizeOf(f32)), &self.verts, c.GL_STREAM_DRAW);
        const stride = floats_per_vertex * @sizeOf(f32);
        inline for (.{ .{ 0, 2, 0 }, .{ 1, 2, 2 }, .{ 2, 4, 4 }, .{ 3, 1, 8 } }) |attribute| {
            gl.EnableVertexAttribArray(attribute[0]);
            gl.VertexAttribPointer(attribute[0], attribute[1], c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(attribute[2] * @sizeOf(f32)));
        }
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(self.used / floats_per_vertex));
        gl.Disable(c.GL_BLEND);
        self.used = 0;
    }

    /// The marks of the pool: every place, its bloom, and the player.
    pub fn drawMarks(self: *Renderer, world: *const world_mod.World) void {
        for (world.places[0..world.count]) |place| {
            if (place.bloom > 0.01) self.glow(place.x, place.y, 16.0 + 30.0 * place.bloom, faded(snowberry, 0.55 * place.bloom));
            self.ring(place.x, place.y, 9.0, faded(chrome, 0.35 + 0.5 * place.near));
            self.disc(place.x, place.y, 4.0, faded(bone, 0.55 + 0.45 * place.near));
        }
        self.glow(world.x, world.y, 22.0, faded(bone, 0.30));
        self.disc(world.x, world.y, 3.5, bone);
    }

    /// Read the finished frame (bottom row first, RGBA) into `out`.
    pub fn readFrame(self: *Renderer, out: []u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.ReadPixels(0, 0, self.width, self.height, c.GL_RGBA, c.GL_UNSIGNED_BYTE, out.ptr);
    }
};

/// Log and clear any pending OpenGL errors. True when there were none.
pub fn checkGl(where: []const u8) bool {
    var clean = true;
    for (0..8) |_| {
        const err = gl.GetError();
        if (err == c.GL_NO_ERROR) break;
        platform.log("OpenGL error 0x{x} at {s}", .{ err, where });
        clean = false;
    }
    return clean;
}
