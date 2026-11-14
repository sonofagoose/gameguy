//! Drawing: one batch of quads, one draw call a frame. Lines, discs, glows and label type, in
//! a fixed 640x480 space (y down) whatever the framebuffer size. Each quad says whether it
//! adds light to what is under it (glowing lines on black) or covers it (Hum's body, the type).
const std = @import("std");
const platform = @import("common").platform;
const font = @import("common").font;
const c = platform.c;
const gl = platform.gl;

pub const Color = [4]f32;
pub const width: f32 = 640.0;
pub const height: f32 = 480.0;

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
    \\layout(location = 0) in vec2 a_pos;
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
    \\    vec2 q = a_pos / vec2(640.0, 480.0) * 2.0 - 1.0;
    \\    gl_Position = vec4(q.x, -q.y, 0.0, 1.0);
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
    \\    } else {
    \\        a = 1.0;                                               // flat
    \\    }
    \\    a *= v_col.a;
    \\    o = vec4(v_col.rgb * a, a * (1.0 - v_kind.y));
    \\}
;

const floats_per_vertex = 10; // x y u v r g b a kind adds
const max_quads = 6000;

pub const Renderer = struct {
    fb_width: i32,
    fb_height: i32,
    program: c.GLuint,
    u_font: c.GLint,
    vao: c.GLuint = 0,
    vbo: c.GLuint = 0,
    font_tex: c.GLuint = 0,
    verts: [max_quads * 6 * floats_per_vertex]f32 = undefined,
    used: usize = 0,
    /// Quads that did not fit this frame (so a too-busy picture shows up in the log, not as a
    /// silent hole).
    dropped: u32 = 0,

    /// Fills `self` in place (it is too large to return by value comfortably).
    pub fn init(self: *Renderer, fb_width: i32, fb_height: i32) bool {
        const program = platform.linkProgram(vs_source, fs_source, "marks") orelse return false;
        self.fb_width = fb_width;
        self.fb_height = fb_height;
        self.program = program;
        self.u_font = gl.GetUniformLocation(program, "u_font");
        self.used = 0;
        self.dropped = 0;
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
        return platform.checkGl("renderer init");
    }

    fn quad(self: *Renderer, p: [4][2]f32, uv: [4][2]f32, color: Color, kind: f32, adds: bool) void {
        if (self.used + 6 * floats_per_vertex > self.verts.len) {
            self.dropped += 1;
            return;
        }
        const order = [6]usize{ 0, 1, 2, 0, 2, 3 };
        for (order) |i| {
            const v = self.verts[self.used .. self.used + floats_per_vertex];
            v[0] = p[i][0];
            v[1] = p[i][1];
            v[2] = uv[i][0];
            v[3] = uv[i][1];
            v[4] = color[0];
            v[5] = color[1];
            v[6] = color[2];
            v[7] = color[3];
            v[8] = kind;
            v[9] = if (adds) 1.0 else 0.0;
            self.used += floats_per_vertex;
        }
    }

    fn box(self: *Renderer, x: f32, y: f32, radius: f32, color: Color, kind: f32, adds: bool) void {
        self.quad(
            .{ .{ x - radius, y - radius }, .{ x + radius, y - radius }, .{ x + radius, y + radius }, .{ x - radius, y + radius } },
            .{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } },
            color,
            kind,
            adds,
        );
    }

    /// A filled circle that covers what is under it.
    pub fn disc(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.box(x, y, radius, color, 1.0, false);
    }

    /// A filled circle of light.
    pub fn dot(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.box(x, y, radius, color, 1.0, true);
    }

    /// Soft light, brightest in the middle.
    pub fn glow(self: *Renderer, x: f32, y: f32, radius: f32, color: Color) void {
        self.box(x, y, radius, color, 2.0, true);
    }

    /// A line of light, `thick` pixels across including its soft edge.
    pub fn line(self: *Renderer, x0: f32, y0: f32, x1: f32, y1: f32, thick: f32, color: Color) void {
        var dx = x1 - x0;
        var dy = y1 - y0;
        const len = @sqrt(dx * dx + dy * dy);
        if (len < 0.001) return;
        dx /= len;
        dy /= len;
        const h = thick * 0.5;
        const nx = -dy * h;
        const ny = dx * h;
        // no overlap at the ends: where lines of light overlap they add, and a curve made of
        // short lines would show as a row of beads
        const ex: f32 = 0.0;
        const ey: f32 = 0.0;
        self.quad(
            .{ .{ x0 - nx - ex, y0 - ny - ey }, .{ x1 - nx + ex, y1 - ny + ey }, .{ x1 + nx + ex, y1 + ny + ey }, .{ x0 + nx - ex, y0 + ny - ey } },
            .{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } },
            color,
            3.0,
            true,
        );
    }

    /// Part of a circle, from angle `a0` to `a1` in radians, measured clockwise from twelve
    /// o'clock.
    pub fn arc(self: *Renderer, x: f32, y: f32, radius: f32, a0: f32, a1: f32, thick: f32, color: Color) void {
        const span = @abs(a1 - a0);
        const steps: usize = @intFromFloat(std.math.clamp(span * radius / 7.0, 3.0, 72.0));
        var px = x + @sin(a0) * radius;
        var py = y - @cos(a0) * radius;
        for (1..steps + 1) |i| {
            const a = a0 + (a1 - a0) * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            const qx = x + @sin(a) * radius;
            const qy = y - @cos(a) * radius;
            self.line(px, py, qx, qy, thick, color);
            px = qx;
            py = qy;
        }
    }

    pub fn circle(self: *Renderer, x: f32, y: f32, radius: f32, thick: f32, color: Color) void {
        self.arc(x, y, radius, 0.0, 2.0 * std.math.pi, thick, color);
    }

    pub fn rect(self: *Renderer, x: f32, y: f32, w: f32, h: f32, color: Color) void {
        self.quad(
            .{ .{ x, y }, .{ x + w, y }, .{ x + w, y + h }, .{ x, y + h } },
            .{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } },
            color,
            4.0,
            false,
        );
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
                    0.0,
                    false,
                );
            }
            pen += cw + 3.0 * scale;
        }
    }

    pub fn textWidth(string: []const u8, scale: f32) f32 {
        return @as(f32, @floatFromInt(string.len)) * (@as(f32, font.cw) + 3.0) * scale;
    }

    pub fn begin(self: *Renderer) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.Viewport(0, 0, self.fb_width, self.fb_height);
        gl.ClearColor(void_black[0], void_black[1], void_black[2], 1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT);
        self.used = 0;
    }

    /// Draw everything queued since `begin`.
    pub fn flush(self: *Renderer) void {
        if (self.used == 0) return;
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
        gl.UseProgram(self.program);
        gl.ActiveTexture(c.GL_TEXTURE0);
        gl.BindTexture(c.GL_TEXTURE_2D, self.font_tex);
        gl.Uniform1i(self.u_font, 0);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(self.used * @sizeOf(f32)), &self.verts, c.GL_STREAM_DRAW);
        const stride = floats_per_vertex * @sizeOf(f32);
        inline for (.{ .{ 0, 2, 0 }, .{ 1, 2, 2 }, .{ 2, 4, 4 }, .{ 3, 2, 8 } }) |attribute| {
            gl.EnableVertexAttribArray(attribute[0]);
            gl.VertexAttribPointer(attribute[0], attribute[1], c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(attribute[2] * @sizeOf(f32)));
        }
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(self.used / floats_per_vertex));
        gl.Disable(c.GL_BLEND);
        gl.BindVertexArray(0);
        self.used = 0;
    }

    /// Read the finished frame (bottom row first, RGBA) into `out`.
    pub fn readFrame(self: *Renderer, out: []u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.ReadPixels(0, 0, self.fb_width, self.fb_height, c.GL_RGBA, c.GL_UNSIGNED_BYTE, out.ptr);
    }
};
