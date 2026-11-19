//! Drawing: batches of quads, every mark placed in the world and seen through the camera in
//! `cam.zig`. Marks are lines, discs and glows of light, plus label type. Each either adds light
//! to what is under it or covers it.
//!
//! Points are worked out on the processor (a few thousand a frame). The graphics card only fills
//! quads, so the page and the place cost it the same.
//!
//! Two ways to put the marks on the screen:
//!
//! - **Lines** (as the toy was first played): one batch, straight to the screen, in the order
//!   the marks were made.
//! - **Beam**: the marks are sorted into three layers. Light from things that sound (voices,
//!   calls, the wheel) goes into a phosphor: a picture that keeps a fading copy of the frames
//!   before it, so a moving voice leaves a short trail of light, as the beam of an oscilloscope
//!   does. It bleeds a little each frame, which gives what lingers a halo. Light from things that
//!   are only lit (the ground, the reeds) goes straight to the screen, crisp. Solid things (Hum's
//!   body, the type) go on top of everything.
//!
//! The phosphor keeps, at each pixel, the brighter of what is left of the last frame and what this
//! frame adds: so something that holds still glows exactly as bright as it would without the
//! phosphor, and only what moves leaves a trail.
//!
//! This GPU draws in tiles and pays for every full-screen pass and every change of target, so
//! the work is laid out to keep full-size passes to two: this frame's light is drawn at full size
//! (it has to be crisp), the trail it leaves is kept at half size (it is soft anyway), and one last
//! pass puts them together on the screen. The halo comes from the trail bleeding, not from passes
//! of its own: three small blur passes cost more here than their few pixels suggest.
const std = @import("std");
const platform = @import("common").platform;
const font = @import("common").font;
const cam_mod = @import("cam.zig");
const c = platform.c;
const gl = platform.gl;

pub const Cam = cam_mod.Cam;
pub const V3 = cam_mod.V3;
pub const Color = [4]f32;
pub const width: f32 = cam_mod.width;
pub const height: f32 = cam_mod.height;

// Khole Caddy Style Book v1.1, section 04: the fixed inks.
pub const void_black = Color{ 0.039, 0.039, 0.039, 1.0 };
pub const bone = Color{ 0.886, 0.839, 0.784, 1.0 };
pub const chrome = Color{ 0.753, 0.753, 0.753, 1.0 };

pub fn rgb(color: [3]f32, alpha: f32) Color {
    return .{ color[0], color[1], color[2], alpha };
}

pub fn faded(color: Color, alpha: f32) Color {
    return .{ color[0], color[1], color[2], color[3] * alpha };
}

pub fn mix(a: [3]f32, b: [3]f32, t: f32) [3]f32 {
    return .{ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };
}

const vs_source =
    \\#version 300 es
    \\layout(location = 0) in vec4 a_pos;
    \\layout(location = 1) in vec2 a_uv;
    \\layout(location = 2) in vec4 a_col;
    \\layout(location = 3) in vec2 a_kind;
    \\out vec2 v_uv;
    \\out vec4 v_col;
    \\out vec2 v_kind;
    \\void main() {
    \\    v_uv = a_uv;
    \\    v_col = a_col;
    \\    v_kind = a_kind;
    \\    gl_Position = a_pos;
    \\}
;

const fs_source =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\in vec4 v_col;
    \\in vec2 v_kind;   // shape; 1.0 if it adds light, 0.0 if it covers
    \\uniform sampler2D u_font;
    \\out vec4 o;
    \\void main() {
    \\    float a;
    \\    if (v_kind.x < 0.5) {
    \\        a = texture(u_font, v_uv).r;                           // label type
    \\    } else if (v_kind.x < 1.5) {
    \\        float d = length(v_uv * 2.0 - 1.0);
    \\        a = 1.0 - smoothstep(0.80, 1.0, d);                    // disc
    \\    } else if (v_kind.x < 2.5) {
    \\        float d = length(v_uv * 2.0 - 1.0);
    \\        a = (1.0 - d) * (1.0 - d) * step(d, 1.0);              // glow
    \\    } else if (v_kind.x < 3.5) {
    \\        float t = abs(v_uv.y * 2.0 - 1.0);
    \\        a = 1.0 - smoothstep(0.30, 1.0, t);                    // line: a core and a soft edge
    \\    } else if (v_kind.x < 4.5) {
    \\        a = 1.0;                                               // flat
    \\    } else {
    \\        a = v_uv.y * v_uv.y;                                   // sky: fades upward
    \\    }
    \\    a *= v_col.a;
    \\    o = vec4(v_col.rgb * a, a * (1.0 - v_kind.y));
    \\}
;

// ---------------------------------------------------------------- the phosphor's passes

/// One triangle that covers the screen, with no vertex data: the corners come from the vertex's
/// number.
const full_vs =
    \\#version 300 es
    \\out vec2 v_uv;
    \\void main() {
    \\    vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
    \\    v_uv = p;
    \\    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    \\}
;

/// The trail, at half size: the brighter of what is left of the last frame and this frame's light.
/// What is left also bleeds a little into the pixels beside it, as light spreads in a phosphor:
/// that is the halo, and it widens as the afterglow lengthens.
const decay_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\uniform sampler2D u_src;
    \\uniform sampler2D u_cur;
    \\uniform float u_keep;
    \\uniform float u_floor;
    \\uniform vec2 u_texel;
    \\uniform float u_spread;
    \\out vec4 o;
    \\void main() {
    \\    vec3 c0 = texture(u_src, v_uv).rgb;
    \\    vec3 near = texture(u_src, v_uv + vec2(u_texel.x, 0.0)).rgb + texture(u_src, v_uv - vec2(u_texel.x, 0.0)).rgb
    \\              + texture(u_src, v_uv + vec2(0.0, u_texel.y)).rgb + texture(u_src, v_uv - vec2(0.0, u_texel.y)).rgb;
    \\    vec3 left = max(mix(c0, near * 0.25, u_spread) * u_keep - u_floor, 0.0);
    \\    o = vec4(max(left, texture(u_cur, v_uv).rgb), 1.0);
    \\}
;

/// The screen: black, the brighter of this frame's light and its trail, and a dither too fine to see
/// that keeps the dim ends of trails and halos from showing as steps.
const comp_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\uniform sampler2D u_cur;
    \\uniform sampler2D u_phosphor;
    \\uniform vec3 u_base;
    \\uniform float u_seed;
    \\out vec4 o;
    \\void main() {
    \\    vec3 lit = max(texture(u_cur, v_uv).rgb, texture(u_phosphor, v_uv).rgb);
    \\    vec3 c = u_base + lit;
    \\    float n = fract(sin(dot(gl_FragCoord.xy + u_seed, vec2(12.9898, 78.233))) * 43758.5453);
    \\    o = vec4(c + (n - 0.5) / 255.0, 1.0);
    \\}
;

const floats_per_vertex = 12; // x y z w u v r g b a kind adds
const max_quads = 12000;
const max_glow_quads = 8000;
const max_solid_quads = 2000;

const Kind = enum(u8) { type = 0, disc = 1, glow = 2, line = 3, flat = 4, sky = 5 };

const Layer = enum { main, glow, solid };

pub const Renderer = struct {
    fb_width: i32,
    fb_height: i32,
    program: c.GLuint,
    u_font: c.GLint,
    vao: c.GLuint = 0,
    vbo: c.GLuint = 0,
    font_tex: c.GLuint = 0,
    cam: *const Cam = undefined,
    /// Everything (lines), or crisp light (beam).
    verts: [max_quads * 6 * floats_per_vertex]f32 = undefined,
    used: usize = 0,
    /// Light that goes into the phosphor (beam only).
    glow_verts: [max_glow_quads * 6 * floats_per_vertex]f32 = undefined,
    glow_used: usize = 0,
    /// Things that cover (beam only).
    solid_verts: [max_solid_quads * 6 * floats_per_vertex]f32 = undefined,
    solid_used: usize = 0,
    /// Quads in the last finished frame, and quads that did not fit (so a too-busy picture shows
    /// up in the log, not as a silent hole).
    quads: u32 = 0,
    most_quads: u32 = 0,
    dropped: u32 = 0,

    // How this frame is put on the screen; set before `begin`.
    /// Beam: sort the marks into layers and keep a phosphor.
    layered: bool = false,
    /// Light made while this is set lingers in the phosphor.
    persist: bool = false,
    /// Figures are brightest where their beam moves slowest.
    dwell: bool = false,
    /// The share of its light the phosphor keeps from one frame to the next (0 to 1).
    keep: f32 = 0.0,
    /// How much what lingers bleeds into the pixels beside it each frame (0: none): the halo.
    bloom: f32 = 0.0,

    // the phosphor
    phosphor_ok: bool = false,
    half_float: bool = false,
    /// The trail, at half size, in two copies that take turns being read and written.
    fbo: [2]c.GLuint = .{ 0, 0 },
    tex: [2]c.GLuint = .{ 0, 0 },
    half_w: i32 = 1,
    half_h: i32 = 1,
    /// This frame's light from things that sound, before it meets the phosphor.
    cur_fbo: c.GLuint = 0,
    cur_tex: c.GLuint = 0,
    ping: usize = 0,
    was_layered: bool = false,
    frame_seed: f32 = 0.0,
    empty_vao: c.GLuint = 0,
    decay_prog: c.GLuint = 0,
    decay_u_src: c.GLint = -1,
    decay_u_cur: c.GLint = -1,
    decay_u_keep: c.GLint = -1,
    decay_u_floor: c.GLint = -1,
    decay_u_texel: c.GLint = -1,
    decay_u_spread: c.GLint = -1,
    comp_prog: c.GLuint = 0,
    comp_u_cur: c.GLint = -1,
    comp_u_phosphor: c.GLint = -1,
    comp_u_base: c.GLint = -1,
    comp_u_seed: c.GLint = -1,

    /// Fills `self` in place (it is too large to return by value comfortably).
    pub fn init(self: *Renderer, fb_width: i32, fb_height: i32) bool {
        const program = platform.linkProgram(vs_source, fs_source, "marks") orelse return false;
        self.fb_width = fb_width;
        self.fb_height = fb_height;
        self.program = program;
        self.u_font = gl.GetUniformLocation(program, "u_font");
        self.used = 0;
        self.glow_used = 0;
        self.solid_used = 0;
        self.quads = 0;
        self.most_quads = 0;
        self.dropped = 0;
        self.layered = false;
        self.persist = false;
        self.dwell = false;
        self.keep = 0.0;
        self.bloom = 0.0;
        self.phosphor_ok = false;
        self.half_float = false;
        self.fbo = .{ 0, 0 };
        self.tex = .{ 0, 0 };
        self.ping = 0;
        self.was_layered = false;
        self.frame_seed = 0.0;
        gl.GenVertexArrays(1, &self.vao);
        gl.GenBuffers(1, &self.vbo);
        gl.GenTextures(1, &self.font_tex);
        gl.BindTexture(c.GL_TEXTURE_2D, self.font_tex);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, font.w, font.h, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, font.pixels.ptr);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        if (!platform.checkGl("renderer init")) return false;
        self.phosphor_ok = self.initPhosphor();
        if (self.phosphor_ok) {
            platform.log("phosphor: light {d}x{d}, trail {d}x{d} in {s}", .{
                fb_width,
                fb_height,
                self.half_w,
                self.half_h,
                if (self.half_float) "half floats" else "8 bits a channel",
            });
        } else {
            platform.log("phosphor: not available on this GPU; the beam looks are drawn as lines", .{});
        }
        _ = platform.checkGl("phosphor init");
        return true;
    }

    /// A texture to draw into, with its framebuffer.
    fn target(w: i32, h: i32, half: bool, fbo: *c.GLuint, tex: *c.GLuint) bool {
        gl.GenTextures(1, tex);
        gl.BindTexture(c.GL_TEXTURE_2D, tex.*);
        if (half) {
            gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA16F, w, h, 0, c.GL_RGBA, c.GL_HALF_FLOAT, null);
        } else {
            gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA8, w, h, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
        }
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        gl.GenFramebuffers(1, fbo);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, fbo.*);
        gl.FramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, tex.*, 0);
        const ok = gl.CheckFramebufferStatus(c.GL_FRAMEBUFFER) == c.GL_FRAMEBUFFER_COMPLETE;
        if (ok) {
            gl.ClearColor(0.0, 0.0, 0.0, 1.0);
            gl.Clear(c.GL_COLOR_BUFFER_BIT);
        }
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        // a failed half-float attempt leaves an error behind; it is not one
        while (gl.GetError() != c.GL_NO_ERROR) {}
        return ok;
    }

    fn initPhosphor(self: *Renderer) bool {
        self.decay_prog = platform.linkProgram(full_vs, decay_fs, "phosphor decay") orelse return false;
        self.comp_prog = platform.linkProgram(full_vs, comp_fs, "phosphor to screen") orelse return false;
        self.decay_u_src = gl.GetUniformLocation(self.decay_prog, "u_src");
        self.decay_u_cur = gl.GetUniformLocation(self.decay_prog, "u_cur");
        self.decay_u_keep = gl.GetUniformLocation(self.decay_prog, "u_keep");
        self.decay_u_floor = gl.GetUniformLocation(self.decay_prog, "u_floor");
        self.decay_u_texel = gl.GetUniformLocation(self.decay_prog, "u_texel");
        self.decay_u_spread = gl.GetUniformLocation(self.decay_prog, "u_spread");
        self.comp_u_cur = gl.GetUniformLocation(self.comp_prog, "u_cur");
        self.comp_u_phosphor = gl.GetUniformLocation(self.comp_prog, "u_phosphor");
        self.comp_u_base = gl.GetUniformLocation(self.comp_prog, "u_base");
        self.comp_u_seed = gl.GetUniformLocation(self.comp_prog, "u_seed");
        gl.GenVertexArrays(1, &self.empty_vao);

        // This frame's light, full size, eight bits a channel.
        if (!target(self.fb_width, self.fb_height, false, &self.cur_fbo, &self.cur_tex)) return false;
        // The trail, half size. Half floats keep its faint end smooth; eight bits is the fallback.
        self.half_w = @max(1, @divTrunc(self.fb_width, 2));
        self.half_h = @max(1, @divTrunc(self.fb_height, 2));
        self.half_float = true;
        if (!target(self.half_w, self.half_h, true, &self.fbo[0], &self.tex[0])) self.half_float = false;
        if (!self.half_float) {
            if (!target(self.half_w, self.half_h, false, &self.fbo[0], &self.tex[0])) return false;
        }
        if (!target(self.half_w, self.half_h, self.half_float, &self.fbo[1], &self.tex[1])) return false;
        return true;
    }

    fn push(self: *Renderer, p: [4][4]f32, uv: [4][2]f32, color: Color, kind: Kind, adds: bool) void {
        // Only what a beam draws (lines and dots) lingers; soft halos and pools of light do not.
        const beam_drawn = kind == .line or kind == .disc;
        const layer: Layer = if (!self.layered) .main else if (!adds) .solid else if (self.persist and beam_drawn) .glow else .main;
        const buf: []f32 = switch (layer) {
            .main => &self.verts,
            .glow => &self.glow_verts,
            .solid => &self.solid_verts,
        };
        const used: *usize = switch (layer) {
            .main => &self.used,
            .glow => &self.glow_used,
            .solid => &self.solid_used,
        };
        if (used.* + 6 * floats_per_vertex > buf.len) {
            self.dropped += 1;
            return;
        }
        const order = [6]usize{ 0, 1, 2, 0, 2, 3 };
        for (order) |i| {
            const v = buf[used.* .. used.* + floats_per_vertex];
            v[0..4].* = p[i];
            v[4] = uv[i][0];
            v[5] = uv[i][1];
            v[6..10].* = color;
            v[10] = @floatFromInt(@intFromEnum(kind));
            v[11] = if (adds) 1.0 else 0.0;
            used.* += floats_per_vertex;
        }
    }

    const unit_uv = [4][2]f32{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } };

    /// A quad given in screen pixels (y down).
    fn quad(self: *Renderer, p: [4][2]f32, uv: [4][2]f32, color: Color, kind: Kind, adds: bool) void {
        var q: [4][4]f32 = undefined;
        for (0..4) |i| q[i] = .{ p[i][0] / (width / 2.0) - 1.0, 1.0 - p[i][1] / (height / 2.0), 0.0, 1.0 };
        self.push(q, uv, color, kind, adds);
    }

    fn box(self: *Renderer, x: f32, y: f32, radius: f32, color: Color, kind: Kind, adds: bool) void {
        if (x + radius < 0.0 or x - radius > width or y + radius < 0.0 or y - radius > height) return;
        self.quad(
            .{ .{ x - radius, y - radius }, .{ x + radius, y - radius }, .{ x + radius, y + radius }, .{ x - radius, y + radius } },
            unit_uv,
            color,
            kind,
            adds,
        );
    }

    // ------------------------------------------------------------ on the screen

    /// A line of light between two screen points, `t0` pixels across at the start and `t1` at
    /// the end, including its soft edge.
    fn ribbon(self: *Renderer, x0: f32, y0: f32, x1: f32, y1: f32, t0: f32, t1: f32, color: Color) void {
        if (@max(x0, x1) < -8.0 or @min(x0, x1) > width + 8.0 or @max(y0, y1) < -8.0 or @min(y0, y1) > height + 8.0) return;
        var dx = x1 - x0;
        var dy = y1 - y0;
        const len = @sqrt(dx * dx + dy * dy);
        if (len < 0.001) return;
        dx /= len;
        dy /= len;
        // no overlap at the ends: where lines of light overlap they add, and a curve made of
        // short lines would show as a row of beads
        const ax = -dy * t0 * 0.5;
        const ay = dx * t0 * 0.5;
        const bx = -dy * t1 * 0.5;
        const by = dx * t1 * 0.5;
        self.quad(
            .{ .{ x0 - ax, y0 - ay }, .{ x1 - bx, y1 - by }, .{ x1 + bx, y1 + by }, .{ x0 + ax, y0 + ay } },
            unit_uv,
            color,
            .line,
            true,
        );
    }

    pub fn rect(self: *Renderer, x: f32, y: f32, w: f32, h: f32, color: Color) void {
        self.quad(.{ .{ x, y }, .{ x + w, y }, .{ x + w, y + h }, .{ x, y + h } }, unit_uv, color, .flat, false);
    }

    /// Light that is strongest along its bottom edge and gone at its top: the sky over the far
    /// edge of the ground.
    pub fn sky(self: *Renderer, y_top: f32, y_bottom: f32, color: Color) void {
        if (y_bottom <= 0.0 or y_top >= y_bottom) return;
        self.quad(.{ .{ 0, y_top }, .{ width, y_top }, .{ width, y_bottom }, .{ 0, y_bottom } }, unit_uv, color, .sky, true);
    }

    pub fn glowAt(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.box(x, y, radius, color, .glow, true);
    }

    /// One line of label type: Space Mono, tracked wide, `scale` times its drawn size.
    pub fn text(self: *Renderer, x: f32, y: f32, scale: f32, color: Color, string: []const u8) void {
        var pen = x;
        const cw: f32 = @as(f32, font.cw) * scale;
        const ch: f32 = @as(f32, font.ch) * scale;
        for (string) |char| {
            if (char > 32 and char < 127) {
                const index: usize = char - 32;
                const cx: f32 = @floatFromInt((index % 16) * font.cw);
                const cy: f32 = @floatFromInt((index / 16) * font.ch);
                const s0 = cx / font.w;
                const t0 = cy / font.h;
                const s1 = (cx + font.cw) / font.w;
                const t1 = (cy + font.ch) / font.h;
                self.quad(
                    .{ .{ pen, y }, .{ pen + cw, y }, .{ pen + cw, y + ch }, .{ pen, y + ch } },
                    .{ .{ s0, t0 }, .{ s1, t0 }, .{ s1, t1 }, .{ s0, t1 } },
                    color,
                    .type,
                    false,
                );
            }
            pen += cw + 3.0 * scale;
        }
    }

    pub fn textWidth(string: []const u8, scale: f32) f32 {
        return @as(f32, @floatFromInt(string.len)) * (@as(f32, font.cw) + 3.0) * scale;
    }

    // ------------------------------------------------------------ in the world

    /// How wide a mark that keeps its size on the screen is at a point `scale` pixels per unit
    /// away: it thins a little with distance, so far things read as far.
    fn held(self: *const Renderer, scale: f32) f32 {
        return std.math.clamp(scale / self.cam.ref, 0.5, 2.2);
    }

    /// A line of light between two points in the world. `thick` is in pixels, or in world units
    /// if `sized`.
    pub fn line(self: *Renderer, a: V3, b: V3, thick: f32, sized: bool, color: Color) void {
        const part = self.cam.cut(a, b) orelse return;
        const p = self.cam.see(part[0]);
        const q = self.cam.see(part[1]);
        var t0 = if (sized) thick * p.scale else thick * self.held(p.scale);
        var t1 = if (sized) thick * q.scale else thick * self.held(q.scale);
        // a line thinner than the screen can show is drawn at the thinnest it can, and dimmer
        var col = color;
        const thin = 1.3;
        const least = @min(t0, t1);
        if (least < thin) col[3] *= @max(least / thin, 0.25);
        t0 = @max(t0, thin);
        t1 = @max(t1, thin);
        self.ribbon(p.x, p.y, q.x, q.y, t0, t1, col);
    }

    pub const max_path = 256;

    /// A run of joined lines through up to `max_path` points in the world, drawn as one ribbon:
    /// each joint is shared by the two lines that meet there, so a curve made of short lines has
    /// no gaps on the outside of its bends and no doubled light on the inside. If `closed`, the
    /// last point must repeat the first, and that joint is shared too.
    pub fn path(self: *Renderer, points: []const V3, thick: f32, sized: bool, color: Color, closed: bool) void {
        self.pathWeighted(points, null, thick, sized, color, closed);
    }

    /// The same, with each line's light scaled by a weight (one per line, `points.len - 1` of
    /// them), applied only while `dwell` is set.
    pub fn pathWeighted(self: *Renderer, points: []const V3, weights: ?[]const f32, thick: f32, sized: bool, color: Color, closed: bool) void {
        const n = points.len;
        if (n < 2 or n > max_path) return;
        var sx: [max_path]f32 = undefined;
        var sy: [max_path]f32 = undefined;
        var th: [max_path]f32 = undefined;
        var ok: [max_path]bool = undefined;
        var ox: [max_path]f32 = undefined;
        var oy: [max_path]f32 = undefined;
        for (points, 0..) |p, i| {
            const s = self.cam.see(p);
            ok[i] = s.ok;
            sx[i] = s.x;
            sy[i] = s.y;
            th[i] = if (sized) thick * s.scale else thick * self.held(s.scale);
        }
        const thin = 1.3;
        for (0..n) |i| {
            ox[i] = 0.0;
            oy[i] = 0.0;
            if (!ok[i]) continue;
            const before: ?usize = if (i > 0) i - 1 else if (closed) n - 2 else null;
            const after: ?usize = if (i + 1 < n) i + 1 else if (closed) 1 else null;
            var mx: f32 = 0.0;
            var my: f32 = 0.0;
            var nx: f32 = 0.0;
            var ny: f32 = 0.0;
            var found = false;
            for ([2]?usize{ before, after }, 0..) |other, which| {
                const j = other orelse continue;
                if (!ok[j]) continue;
                var dx = if (which == 0) sx[i] - sx[j] else sx[j] - sx[i];
                var dy = if (which == 0) sy[i] - sy[j] else sy[j] - sy[i];
                const len = @sqrt(dx * dx + dy * dy);
                if (len < 0.0005) continue;
                dx /= len;
                dy /= len;
                nx = -dy;
                ny = dx;
                mx += nx;
                my += ny;
                found = true;
            }
            if (!found) continue;
            const len = @sqrt(mx * mx + my * my);
            if (len < 0.05) {
                // the path doubles back on itself here: square the end off
                mx = nx;
                my = ny;
            } else {
                mx /= len;
                my /= len;
            }
            const half = @max(th[i], thin) * 0.5 / @max(mx * nx + my * ny, 0.75);
            ox[i] = mx * half;
            oy[i] = my * half;
        }
        const weigh = self.dwell and weights != null and weights.?.len >= n - 1;
        for (0..n - 1) |i| {
            const j = i + 1;
            if (!ok[i] and !ok[j]) continue;
            var col = color;
            if (weigh) col[3] *= weights.?[i];
            if (!ok[i] or !ok[j]) {
                self.line(points[i], points[j], thick, sized, col); // it passes behind the eye
                continue;
            }
            if (@max(sx[i], sx[j]) < -8.0 or @min(sx[i], sx[j]) > width + 8.0 or @max(sy[i], sy[j]) < -8.0 or @min(sy[i], sy[j]) > height + 8.0) continue;
            const least = @min(th[i], th[j]);
            if (least < thin) col[3] *= @max(least / thin, 0.25);
            self.quad(
                .{ .{ sx[i] - ox[i], sy[i] - oy[i] }, .{ sx[j] - ox[j], sy[j] - oy[j] }, .{ sx[j] + ox[j], sy[j] + oy[j] }, .{ sx[i] + ox[i], sy[i] + oy[i] } },
                unit_uv,
                col,
                .line,
                true,
            );
        }
    }

    fn mark(self: *Renderer, p: V3, radius: f32, sized: bool, color: Color, kind: Kind, adds: bool) void {
        const s = self.cam.see(p);
        if (!s.ok) return;
        const r = if (sized) radius * s.scale else radius * self.held(s.scale);
        self.box(s.x, s.y, r, color, kind, adds);
    }

    /// A filled circle facing the viewer that covers what is behind it. Radius in world units.
    pub fn disc(self: *Renderer, p: V3, radius: f32, color: Color) void {
        self.mark(p, radius, true, color, .disc, false);
    }

    /// A filled circle of light. Radius in pixels, or in world units if `sized`.
    pub fn dot(self: *Renderer, p: V3, radius: f32, sized: bool, color: Color) void {
        self.mark(p, radius, sized, color, .disc, true);
    }

    /// Soft light around a point, facing the viewer. Radius in world units.
    pub fn glow(self: *Renderer, p: V3, radius: f32, color: Color) void {
        self.mark(p, radius, true, color, .glow, true);
    }

    /// Soft light lying on the ground: a pool of it, seen at the slant the ground is seen at.
    pub fn pool(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        const cam = self.cam;
        self.push(
            .{
                cam.clip(.{ x - radius, 0.0, y - radius }),
                cam.clip(.{ x + radius, 0.0, y - radius }),
                cam.clip(.{ x + radius, 0.0, y + radius }),
                cam.clip(.{ x - radius, 0.0, y + radius }),
            },
            unit_uv,
            color,
            .glow,
            true,
        );
    }

    /// Part of a circle lying on the ground, from angle `a0` to `a1` in radians, measured
    /// clockwise from "up the page".
    pub fn groundArc(self: *Renderer, x: f32, y: f32, radius: f32, a0: f32, a1: f32, thick: f32, sized: bool, color: Color) void {
        const cam = self.cam;
        const span = @abs(a1 - a0);
        // enough points that a small circle seen from far off is still round
        const fewest: f32 = if (span > 6.0) 18.0 else 4.0;
        const steps: usize = @intFromFloat(std.math.clamp(span * radius * cam.ref / 7.0, fewest, 72.0));
        var points: [73]V3 = undefined;
        for (0..steps + 1) |i| {
            const a = a0 + (a1 - a0) * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            points[i] = cam.ground(x + @sin(a) * radius, y - @cos(a) * radius);
        }
        self.path(points[0 .. steps + 1], thick, sized, color, span > 6.28);
    }

    pub fn groundCircle(self: *Renderer, x: f32, y: f32, radius: f32, thick: f32, sized: bool, color: Color) void {
        self.groundArc(x, y, radius, 0.0, 2.0 * std.math.pi, thick, sized, color);
    }

    /// Part of a circle that stands on its hinge at (`x`, `y`): on the page it lies flat round
    /// that point, in the place it stands facing the viewer with its lower half under the ground
    /// (unless `hover` lifts it clear). Angles clockwise from twelve o'clock.
    pub fn hingedArc(self: *Renderer, x: f32, y: f32, hover: f32, radius: f32, a0: f32, a1: f32, thick: f32, color: Color) void {
        const cam = self.cam;
        const span = @abs(a1 - a0);
        const fewest: f32 = if (span > 6.0) 18.0 else 3.0;
        const steps: usize = @intFromFloat(std.math.clamp(span * radius * cam.ref / 7.0, fewest, 72.0));
        var points: [73]V3 = undefined;
        for (0..steps + 1) |i| {
            const a = a0 + (a1 - a0) * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            points[i] = cam.standing(x, y, @sin(a) * radius, @cos(a) * radius, hover);
        }
        self.path(points[0 .. steps + 1], thick, false, color, span > 6.28);
    }

    // ------------------------------------------------------------ the frame

    pub fn begin(self: *Renderer, cam: *const Cam) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.Viewport(0, 0, self.fb_width, self.fb_height);
        gl.ClearColor(void_black[0], void_black[1], void_black[2], 1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT);
        self.used = 0;
        self.glow_used = 0;
        self.solid_used = 0;
        self.cam = cam;
        if (!self.phosphor_ok) self.layered = false;
    }

    fn drawBatch(self: *Renderer, data: []const f32) void {
        if (data.len == 0) return;
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
        gl.UseProgram(self.program);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.font_tex);
        gl.Uniform1i(self.u_font, 0);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(data.len * @sizeOf(f32)), data.ptr, c.GL_STREAM_DRAW);
        const stride = floats_per_vertex * @sizeOf(f32);
        inline for (.{ .{ 0, 4, 0 }, .{ 1, 2, 4 }, .{ 2, 4, 6 }, .{ 3, 2, 10 } }) |attribute| {
            gl.EnableVertexAttribArray(attribute[0]);
            gl.VertexAttribPointer(attribute[0], attribute[1], c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(attribute[2] * @sizeOf(f32)));
        }
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(data.len / floats_per_vertex));
        gl.Disable(c.GL_BLEND);
        gl.BindVertexArray(0);
    }

    /// Draw the covering triangle with whatever program and textures are bound.
    fn fullScreen(self: *Renderer, fbo: c.GLuint, w: i32, h: i32) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, fbo);
        gl.Viewport(0, 0, w, h);
        gl.BindVertexArray(self.empty_vao);
        gl.DrawArrays(c.GL_TRIANGLES, 0, 3);
        gl.BindVertexArray(0);
    }

    /// Draw everything queued since `begin`.
    pub fn flush(self: *Renderer) void {
        const per_quad = 6 * floats_per_vertex;
        self.quads = @intCast((self.used + self.glow_used + self.solid_used) / per_quad);
        self.most_quads = @max(self.most_quads, self.quads);
        if (!self.layered) {
            self.drawBatch(self.verts[0..self.used]);
            self.used = 0;
            self.was_layered = false;
            return;
        }

        const prev = self.ping;
        const next = 1 - prev;
        gl.Disable(c.GL_BLEND);
        if (!self.was_layered) {
            // coming back to the beam: forget what the phosphor held before
            for (0..2) |i| {
                gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.fbo[i]);
                gl.ClearColor(0.0, 0.0, 0.0, 1.0);
                gl.Clear(c.GL_COLOR_BUFFER_BIT);
            }
        }

        // 1. this frame's light from things that sound, on its own
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.cur_fbo);
        gl.Viewport(0, 0, self.fb_width, self.fb_height);
        gl.ClearColor(0.0, 0.0, 0.0, 1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT);
        self.drawBatch(self.glow_verts[0..self.glow_used]);

        // 2. the trail, half size: the brighter of what is left of the last frame and this one
        gl.UseProgram(self.decay_prog);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.tex[prev]);
        gl.Uniform1i(self.decay_u_src, 0);
        gl.ActiveTexture(c.GL_TEXTURE1);
        gl.BindTexture(c.GL_TEXTURE_2D, self.cur_tex);
        gl.Uniform1i(self.decay_u_cur, 1);
        gl.Uniform1f(self.decay_u_keep, std.math.clamp(self.keep, 0.0, 0.995));
        gl.Uniform1f(self.decay_u_floor, if (self.half_float) 0.0008 else 1.5 / 255.0);
        gl.Uniform2f(self.decay_u_texel, 1.0 / @as(f32, @floatFromInt(self.half_w)), 1.0 / @as(f32, @floatFromInt(self.half_h)));
        gl.Uniform1f(self.decay_u_spread, std.math.clamp(self.bloom, 0.0, 1.0));
        self.fullScreen(self.fbo[next], self.half_w, self.half_h);
        gl.ActiveTexture(c.GL_TEXTURE0);

        // 3. the screen: black, this frame's light and its trail
        self.frame_seed = @mod(self.frame_seed + 17.31, 997.0);
        gl.UseProgram(self.comp_prog);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.cur_tex);
        gl.Uniform1i(self.comp_u_cur, 0);
        gl.ActiveTexture(c.GL_TEXTURE1);
        gl.BindTexture(c.GL_TEXTURE_2D, self.tex[next]);
        gl.Uniform1i(self.comp_u_phosphor, 1);
        gl.Uniform3f(self.comp_u_base, void_black[0], void_black[1], void_black[2]);
        gl.Uniform1f(self.comp_u_seed, self.frame_seed);
        self.fullScreen(0, self.fb_width, self.fb_height);
        gl.ActiveTexture(c.GL_TEXTURE0);

        // 4. light from things that are only lit, crisp; 5. what covers
        self.drawBatch(self.verts[0..self.used]);
        self.drawBatch(self.solid_verts[0..self.solid_used]);

        self.used = 0;
        self.glow_used = 0;
        self.solid_used = 0;
        self.ping = next;
        self.was_layered = true;
    }

    /// Read the finished frame (bottom row first, RGBA) into `out`.
    pub fn readFrame(self: *Renderer, out: []u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.ReadPixels(0, 0, self.fb_width, self.fb_height, c.GL_RGBA, c.GL_UNSIGNED_BYTE, out.ptr);
    }
};
