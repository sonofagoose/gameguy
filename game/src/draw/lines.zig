//! Lines of light, kept on the GPU.
//!
//! Each line is one instance of a four-cornered strip: two ends in the world, a width, the body it belongs to and
//! a colour. The vertex shader places it, and sets its brightness from its body's loudness, which
//! is sent each frame as one small table. Black shapes hide what is behind them.
//!
//! Three passes, because each costs this GPU a fixed amount (docs/hardware-target.md):
//!   1. light from things that sound, behind the black shapes, into a full-size target;
//!   2. the phosphor: a half-size copy that keeps the brighter of this frame's light and what is
//!      left of the last frame's, bleeding a little for the halo (from toys/page/src/gfx.zig);
//!   3. the screen: the two together, then the black shapes again, then light from things that
//!      are only lit.
const std = @import("std");
const plat = @import("../plat/plat.zig");
const m = @import("../m.zig");
const c = plat.c;
const gl = plat.gl;

/// One line. 36 bytes.
pub const Inst = extern struct {
    a: [3]f32,
    b: [3]f32,
    /// Half its width, in pixels.
    half_width: f32,
    /// Which body's loudness lights it.
    body: f32,
    /// Its colour, and how bright it is at full loudness.
    col: [4]u8,
};

pub const body_cols = 256;
pub const body_rows = 64;
pub const max_bodies = body_cols * body_rows;

const line_vs =
    \\#version 300 es
    \\layout(location = 0) in vec3 a_a;
    \\layout(location = 1) in vec3 a_b;
    \\layout(location = 2) in vec2 a_wb;
    \\layout(location = 3) in vec4 a_col;
    \\uniform mat4 u_vp;
    \\uniform vec2 u_half;
    \\uniform highp sampler2D u_loud;
    \\uniform float u_fade;
    \\out vec2 v_uv;
    \\out vec3 v_col;
    \\void main() {
    \\    int id = gl_VertexID;
    \\    float e = (id >= 2) ? 1.0 : 0.0;
    \\    float s = ((id & 1) == 1) ? 1.0 : -1.0;
    \\    vec4 pa = u_vp * vec4(a_a, 1.0);
    \\    vec4 pb = u_vp * vec4(a_b, 1.0);
    \\    const float nr = 0.05;
    \\    if (pa.w < nr && pb.w < nr) {
    \\        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    \\        v_uv = vec2(0.0);
    \\        v_col = vec3(0.0);
    \\        return;
    \\    }
    \\    if (pa.w < nr) pa = mix(pa, pb, (nr - pa.w) / (pb.w - pa.w));
    \\    if (pb.w < nr) pb = mix(pb, pa, (nr - pb.w) / (pa.w - pb.w));
    \\    vec2 sa = pa.xy / pa.w * u_half;
    \\    vec2 sb = pb.xy / pb.w * u_half;
    \\    vec2 d = sb - sa;
    \\    float len = max(length(d), 0.0001);
    \\    vec2 dir = d / len;
    \\    vec2 nrm = vec2(-dir.y, dir.x);
    \\    vec4 p = e > 0.5 ? pb : pa;
    \\    // Far parts of a figure are fainter and thinner.
    \\    float nearness = clamp(u_fade / p.w, 0.12, 1.0);
    \\    float hw = a_wb.x * (0.55 + 0.45 * nearness);
    \\    vec2 px = (e > 0.5 ? sb : sa) + nrm * (s * hw) + dir * ((e * 2.0 - 1.0) * hw * 0.5);
    \\    gl_Position = vec4(px / u_half * p.w, p.z, p.w);
    \\    int body = int(a_wb.y);
    \\    float loud = texelFetch(u_loud, ivec2(body & 255, body >> 8), 0).r;
    \\    v_uv = vec2(e, s);
    \\    v_col = a_col.rgb * (a_col.a * loud * nearness);
    \\}
;

const line_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\in vec3 v_col;
    \\out vec4 o;
    \\void main() {
    \\    float a = 1.0 - smoothstep(0.30, 1.0, abs(v_uv.y));
    \\    o = vec4(v_col * a, 0.0);
    \\}
;

const occ_vs =
    \\#version 300 es
    \\layout(location = 0) in vec3 a_pos;
    \\uniform mat4 u_vp;
    \\void main() {
    \\    gl_Position = u_vp * vec4(a_pos, 1.0);
    \\}
;

const occ_fs =
    \\#version 300 es
    \\precision mediump float;
    \\out vec4 o;
    \\void main() {
    \\    o = vec4(0.0, 0.0, 0.0, 1.0);
    \\}
;

const full_vs =
    \\#version 300 es
    \\out vec2 v_uv;
    \\void main() {
    \\    vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
    \\    v_uv = p;
    \\    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    \\}
;

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

pub const Renderer = struct {
    fb_w: i32 = 0,
    fb_h: i32 = 0,
    half_w: i32 = 1,
    half_h: i32 = 1,
    half_float: bool = false,

    line_prog: c.GLuint = 0,
    line_u_vp: c.GLint = -1,
    line_u_half: c.GLint = -1,
    line_u_loud: c.GLint = -1,
    line_u_fade: c.GLint = -1,
    occ_prog: c.GLuint = 0,
    occ_u_vp: c.GLint = -1,
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

    line_vao: c.GLuint = 0,
    line_vbo: c.GLuint = 0,
    occ_vao: c.GLuint = 0,
    occ_vbo: c.GLuint = 0,
    empty_vao: c.GLuint = 0,
    loud_tex: c.GLuint = 0,

    cur_fbo: c.GLuint = 0,
    cur_tex: c.GLuint = 0,
    cur_depth: c.GLuint = 0,
    fbo: [2]c.GLuint = .{ 0, 0 },
    tex: [2]c.GLuint = .{ 0, 0 },
    ping: usize = 0,
    seed: f32 = 0.0,

    /// Lines from things that sound come first in the buffer, then lines that are only lit.
    sounding: u32 = 0,
    lit: u32 = 0,
    occ_verts: u32 = 0,

    /// The share of its light the phosphor keeps from one frame to the next.
    keep: f32 = 0.6,
    /// How much what lingers bleeds into the pixels beside it: the halo.
    bloom: f32 = 0.6,
    base: [3]f32 = .{ 0.039, 0.039, 0.039 },
    /// Lines keep their full brightness out to this distance, then fade with it.
    fade: f32 = 45.0,

    pub fn init(self: *Renderer, fb_w: i32, fb_h: i32) bool {
        self.* = .{};
        self.fb_w = fb_w;
        self.fb_h = fb_h;
        self.line_prog = plat.linkProgram(line_vs, line_fs, "lines") orelse return false;
        self.occ_prog = plat.linkProgram(occ_vs, occ_fs, "black shapes") orelse return false;
        self.decay_prog = plat.linkProgram(full_vs, decay_fs, "phosphor decay") orelse return false;
        self.comp_prog = plat.linkProgram(full_vs, comp_fs, "phosphor to screen") orelse return false;
        self.line_u_vp = gl.GetUniformLocation(self.line_prog, "u_vp");
        self.line_u_half = gl.GetUniformLocation(self.line_prog, "u_half");
        self.line_u_loud = gl.GetUniformLocation(self.line_prog, "u_loud");
        self.line_u_fade = gl.GetUniformLocation(self.line_prog, "u_fade");
        self.occ_u_vp = gl.GetUniformLocation(self.occ_prog, "u_vp");
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

        // the lines: one buffer of instances, four corners each from the vertex's number
        gl.GenVertexArrays(1, &self.line_vao);
        gl.GenBuffers(1, &self.line_vbo);
        gl.BindVertexArray(self.line_vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.line_vbo);
        const stride: c.GLsizei = @sizeOf(Inst);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(@offsetOf(Inst, "a")));
        gl.VertexAttribDivisor(0, 1);
        gl.EnableVertexAttribArray(1);
        gl.VertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(@offsetOf(Inst, "b")));
        gl.VertexAttribDivisor(1, 1);
        gl.EnableVertexAttribArray(2);
        gl.VertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(@offsetOf(Inst, "half_width")));
        gl.VertexAttribDivisor(2, 1);
        gl.EnableVertexAttribArray(3);
        gl.VertexAttribPointer(3, 4, c.GL_UNSIGNED_BYTE, c.GL_TRUE, stride, @ptrFromInt(@offsetOf(Inst, "col")));
        gl.VertexAttribDivisor(3, 1);
        gl.BindVertexArray(0);

        // the black shapes: plain triangles
        gl.GenVertexArrays(1, &self.occ_vao);
        gl.GenBuffers(1, &self.occ_vbo);
        gl.BindVertexArray(self.occ_vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.occ_vbo);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 12, null);
        gl.BindVertexArray(0);

        // each body's loudness, one byte, sent every frame
        gl.GenTextures(1, &self.loud_tex);
        gl.BindTexture(c.GL_TEXTURE_2D, self.loud_tex);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, body_cols, body_rows, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, null);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        if (!plat.checkGl("line renderer")) return false;

        // this frame's sounding light, full size, with depth for the black shapes
        if (!target(fb_w, fb_h, false, &self.cur_fbo, &self.cur_tex)) return false;
        gl.GenRenderbuffers(1, &self.cur_depth);
        gl.BindRenderbuffer(c.GL_RENDERBUFFER, self.cur_depth);
        gl.RenderbufferStorage(c.GL_RENDERBUFFER, c.GL_DEPTH_COMPONENT16, fb_w, fb_h);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.cur_fbo);
        gl.FramebufferRenderbuffer(c.GL_FRAMEBUFFER, c.GL_DEPTH_ATTACHMENT, c.GL_RENDERBUFFER, self.cur_depth);
        if (gl.CheckFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) return false;
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);

        // the trail, half size; half floats keep its faint end smooth
        self.half_w = @max(1, @divTrunc(fb_w, 2));
        self.half_h = @max(1, @divTrunc(fb_h, 2));
        self.half_float = true;
        if (!target(self.half_w, self.half_h, true, &self.fbo[0], &self.tex[0])) self.half_float = false;
        if (!self.half_float) {
            if (!target(self.half_w, self.half_h, false, &self.fbo[0], &self.tex[0])) return false;
        }
        if (!target(self.half_w, self.half_h, self.half_float, &self.fbo[1], &self.tex[1])) return false;
        plat.log("lines: light {d}x{d}, trail {d}x{d} in {s}", .{
            fb_w,
            fb_h,
            self.half_w,
            self.half_h,
            if (self.half_float) "half floats" else "8 bits a channel",
        });
        return plat.checkGl("line renderer targets");
    }

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

    /// Hand the GPU a piece of land: its sounding lines, its lit lines, and its black shapes
    /// (three points to a triangle).
    pub fn setLand(self: *Renderer, sounding: []const Inst, lit: []const Inst, occ: []const [3]f32) void {
        self.sounding = @intCast(sounding.len);
        self.lit = @intCast(lit.len);
        self.occ_verts = @intCast(occ.len);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.line_vbo);
        const total: c.GLsizeiptr = @intCast((sounding.len + lit.len) * @sizeOf(Inst));
        gl.BufferData(c.GL_ARRAY_BUFFER, total, null, c.GL_STATIC_DRAW);
        if (sounding.len > 0) gl.BufferSubData(c.GL_ARRAY_BUFFER, 0, @intCast(sounding.len * @sizeOf(Inst)), sounding.ptr);
        if (lit.len > 0) gl.BufferSubData(c.GL_ARRAY_BUFFER, @intCast(sounding.len * @sizeOf(Inst)), @intCast(lit.len * @sizeOf(Inst)), lit.ptr);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.occ_vbo);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(occ.len * 12), if (occ.len > 0) occ.ptr else null, c.GL_STATIC_DRAW);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, 0);
        _ = plat.checkGl("land upload");
    }

    fn drawOcc(self: *Renderer, vp: *const m.M4) void {
        if (self.occ_verts == 0) return;
        gl.UseProgram(self.occ_prog);
        gl.UniformMatrix4fv(self.occ_u_vp, 1, c.GL_FALSE, vp);
        gl.Enable(c.GL_DEPTH_TEST);
        gl.DepthFunc(c.GL_LEQUAL);
        gl.DepthMask(c.GL_TRUE);
        gl.ColorMask(c.GL_FALSE, c.GL_FALSE, c.GL_FALSE, c.GL_FALSE);
        gl.Enable(c.GL_POLYGON_OFFSET_FILL);
        gl.PolygonOffset(1.0, 1.0);
        gl.BindVertexArray(self.occ_vao);
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(self.occ_verts));
        gl.Disable(c.GL_POLYGON_OFFSET_FILL);
        gl.ColorMask(c.GL_TRUE, c.GL_TRUE, c.GL_TRUE, c.GL_TRUE);
    }

    fn drawLines(self: *Renderer, vp: *const m.M4, first: u32, count: u32) void {
        if (count == 0) return;
        gl.UseProgram(self.line_prog);
        gl.UniformMatrix4fv(self.line_u_vp, 1, c.GL_FALSE, vp);
        gl.Uniform2f(self.line_u_half, @as(f32, @floatFromInt(self.fb_w)) * 0.5, @as(f32, @floatFromInt(self.fb_h)) * 0.5);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.loud_tex);
        gl.Uniform1i(self.line_u_loud, 0);
        gl.Uniform1f(self.line_u_fade, self.fade);
        gl.Enable(c.GL_DEPTH_TEST);
        gl.DepthFunc(c.GL_LEQUAL);
        gl.DepthMask(c.GL_FALSE);
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_ONE, c.GL_ONE);
        gl.BindVertexArray(self.line_vao);
        // The instance buffer is read from `first` on: move the attribute pointers there.
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.line_vbo);
        const stride: c.GLsizei = @sizeOf(Inst);
        const base: usize = @as(usize, first) * @sizeOf(Inst);
        gl.VertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(base + @offsetOf(Inst, "a")));
        gl.VertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(base + @offsetOf(Inst, "b")));
        gl.VertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(base + @offsetOf(Inst, "half_width")));
        gl.VertexAttribPointer(3, 4, c.GL_UNSIGNED_BYTE, c.GL_TRUE, stride, @ptrFromInt(base + @offsetOf(Inst, "col")));
        gl.DrawArraysInstanced(c.GL_TRIANGLE_STRIP, 0, 4, @intCast(count));
        gl.BindVertexArray(0);
        gl.Disable(c.GL_BLEND);
        gl.DepthMask(c.GL_TRUE);
        gl.Disable(c.GL_DEPTH_TEST);
    }

    fn fullScreen(self: *Renderer, fbo: c.GLuint, w: i32, h: i32) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, fbo);
        gl.Viewport(0, 0, w, h);
        gl.BindVertexArray(self.empty_vao);
        gl.DrawArrays(c.GL_TRIANGLES, 0, 3);
        gl.BindVertexArray(0);
    }

    /// Draw one frame of the land through `vp`, with each body as loud as `loud` says.
    pub fn frame(self: *Renderer, vp: *const m.M4, loud: *const [max_bodies]u8) void {
        gl.BindTexture(c.GL_TEXTURE_2D, self.loud_tex);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexSubImage2D(c.GL_TEXTURE_2D, 0, 0, 0, body_cols, body_rows, c.GL_RED, c.GL_UNSIGNED_BYTE, loud);

        const prev = self.ping;
        const next = 1 - prev;

        // 1. light from things that sound, behind the black shapes
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.cur_fbo);
        gl.Viewport(0, 0, self.fb_w, self.fb_h);
        gl.ClearColor(0.0, 0.0, 0.0, 1.0);
        gl.ClearDepthf(1.0);
        gl.DepthMask(c.GL_TRUE);
        gl.Clear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        self.drawOcc(vp);
        self.drawLines(vp, 0, self.sounding);

        // 2. the trail, half size
        gl.Disable(c.GL_DEPTH_TEST);
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

        // 3. the screen: the two together, the black shapes again, then what is only lit
        self.seed += 17.0;
        if (self.seed > 1024.0) self.seed -= 1024.0;
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.DepthMask(c.GL_TRUE);
        gl.ClearDepthf(1.0);
        gl.Clear(c.GL_DEPTH_BUFFER_BIT);
        gl.UseProgram(self.comp_prog);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.cur_tex);
        gl.Uniform1i(self.comp_u_cur, 0);
        gl.ActiveTexture(c.GL_TEXTURE1);
        gl.BindTexture(c.GL_TEXTURE_2D, self.tex[next]);
        gl.Uniform1i(self.comp_u_phosphor, 1);
        gl.Uniform3f(self.comp_u_base, self.base[0], self.base[1], self.base[2]);
        gl.Uniform1f(self.comp_u_seed, self.seed);
        self.fullScreen(0, self.fb_w, self.fb_h);
        gl.ActiveTexture(c.GL_TEXTURE0);
        self.drawOcc(vp);
        self.drawLines(vp, self.sounding, self.lit);

        self.ping = next;
    }

    /// Read the finished frame (bottom row first, RGBA) into `out`.
    pub fn readFrame(self: *Renderer, out: []u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.ReadPixels(0, 0, self.fb_w, self.fb_h, c.GL_RGBA, c.GL_UNSIGNED_BYTE, out.ptr);
    }
};
