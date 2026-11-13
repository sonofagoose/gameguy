//! Labels and flat rectangles drawn over a finished frame: one batch of quads, one draw call.
//! Coordinates are in a fixed 640x480 space whatever the framebuffer size, y down.
const std = @import("std");
const platform = @import("platform.zig");
const font = @import("font.zig");
const c = platform.c;
const gl = platform.gl;

pub const Color = [4]f32;
pub const width: f32 = 640.0;
pub const height: f32 = 480.0;
/// Extra space between letters (the labels are set wide, as in the style book).
pub const tracking: f32 = 3.0;
pub const line: f32 = font.ch;

const vs_source =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\layout(location = 1) in vec2 a_uv;
    \\layout(location = 2) in vec4 a_col;
    \\out vec2 v_uv;
    \\out vec4 v_col;
    \\void main() {
    \\    v_uv = a_uv;
    \\    v_col = a_col;
    \\    vec2 q = a_pos / vec2(640.0, 480.0) * 2.0 - 1.0;
    \\    gl_Position = vec4(q.x, -q.y, 0.0, 1.0);
    \\}
;

const fs_source =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\in vec4 v_col;
    \\uniform sampler2D u_font;
    \\out vec4 o;
    \\void main() { o = vec4(v_col.rgb, v_col.a * texture(u_font, v_uv).r); }
;

const floats_per_vertex = 8; // x y u v r g b a
const max_quads = 600;

var program: c.GLuint = 0;
var u_font: c.GLint = 0;
var vao: c.GLuint = 0;
var vbo: c.GLuint = 0;
var texture: c.GLuint = 0;
var verts: [max_quads * 6 * floats_per_vertex]f32 = undefined;
var used: usize = 0;

pub fn init() bool {
    program = platform.linkProgram(vs_source, fs_source, "hud") orelse return false;
    u_font = gl.GetUniformLocation(program, "u_font");
    gl.GenVertexArrays(1, &vao);
    gl.GenBuffers(1, &vbo);
    gl.GenTextures(1, &texture);
    gl.BindTexture(c.GL_TEXTURE_2D, texture);
    gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
    gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, font.w, font.h, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, font.pixels.ptr);
    gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
    gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    return true;
}

fn quad(x0: f32, y0: f32, x1: f32, y1: f32, s0: f32, t0: f32, s1: f32, t1: f32, color: Color) void {
    if (used + 6 * floats_per_vertex > verts.len) return;
    const corners = [6][4]f32{
        .{ x0, y0, s0, t0 }, .{ x1, y0, s1, t0 }, .{ x1, y1, s1, t1 },
        .{ x0, y0, s0, t0 }, .{ x1, y1, s1, t1 }, .{ x0, y1, s0, t1 },
    };
    for (corners) |corner| {
        const v = verts[used .. used + floats_per_vertex];
        v[0] = corner[0];
        v[1] = corner[1];
        v[2] = corner[2];
        v[3] = corner[3];
        v[4] = color[0];
        v[5] = color[1];
        v[6] = color[2];
        v[7] = color[3];
        used += floats_per_vertex;
    }
}

pub fn rect(x: f32, y: f32, w: f32, h: f32, color: Color) void {
    // the middle of the atlas's last cell, which is solid
    const s: f32 = 15.5 * @as(f32, font.cw) / @as(f32, font.w);
    const t: f32 = 5.5 * @as(f32, font.ch) / @as(f32, font.h);
    quad(x, y, x + w, y + h, s, t, s, t, color);
}

pub fn text(x: f32, y: f32, color: Color, string: []const u8) void {
    var pen = x;
    for (string) |ch| {
        if (ch > 32 and ch < 127) {
            const index: usize = ch - 32;
            const cx: f32 = @floatFromInt((index % 16) * font.cw);
            const cy: f32 = @floatFromInt((index / 16) * font.ch);
            quad(pen, y, pen + font.cw, y + font.ch, cx / font.w, cy / font.h, (cx + font.cw) / font.w, (cy + font.ch) / font.h, color);
        }
        pen += font.cw + tracking;
    }
}

pub fn textWidth(string: []const u8) f32 {
    return @as(f32, @floatFromInt(string.len)) * (font.cw + tracking);
}

/// Draw everything queued since the last flush onto the current framebuffer.
pub fn flush(fb_width: i32, fb_height: i32) void {
    if (used == 0) return;
    gl.Viewport(0, 0, fb_width, fb_height);
    gl.Disable(c.GL_DEPTH_TEST);
    gl.Disable(c.GL_CULL_FACE);
    gl.Enable(c.GL_BLEND);
    gl.BlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    gl.UseProgram(program);
    gl.ActiveTexture(c.GL_TEXTURE0);
    gl.BindTexture(c.GL_TEXTURE_2D, texture);
    gl.Uniform1i(u_font, 0);
    gl.BindVertexArray(vao);
    gl.BindBuffer(c.GL_ARRAY_BUFFER, vbo);
    gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(used * @sizeOf(f32)), &verts, c.GL_STREAM_DRAW);
    const stride = floats_per_vertex * @sizeOf(f32);
    inline for (.{ .{ 0, 2, 0 }, .{ 1, 2, 2 }, .{ 2, 4, 4 } }) |attribute| {
        gl.EnableVertexAttribArray(attribute[0]);
        gl.VertexAttribPointer(attribute[0], attribute[1], c.GL_FLOAT, c.GL_FALSE, stride, @ptrFromInt(attribute[2] * @sizeOf(f32)));
    }
    gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(used / floats_per_vertex));
    gl.Disable(c.GL_BLEND);
    gl.BindVertexArray(0);
    used = 0;
}
