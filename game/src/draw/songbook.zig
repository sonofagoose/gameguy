//! The songbook (SPEC.md 8: Start opens it, and the world waits): pages drawn in lines of light,
//! no words. Each page is one thing Hum can do: the moment it belongs to, drawn small, and the
//! handheld drawn by its real layout with the control's place lit and moving in the rhythm the thing
//! wants. A page is drawn whole once Hum has done its thing; the page the present moment needs lies
//! on top, faint and half drawn. Never a letter (spec/promises/hands.md, `hands.by-position`): a
//! control is shown by where it is.
//!
//! The way games that teach without words do it (Tunic's manual pages, Outer Wilds' log): a thing
//! of the world that remembers what you have learned and shows what the moment asks.
const std = @import("std");
const plat = @import("../plat/plat.zig");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const c = plat.c;
const gl = plat.gl;

pub const Page = pages_mod.Page;
pub const pages = pages_mod.pages;
pub const learned = pages_mod.learned;
pub const needed = pages_mod.needed;
const pages_mod = @import("../world/pages.zig");

const bone = [3]f32{ 0.886, 0.839, 0.784 };
const teal = [3]f32{ 0.25, 0.86, 0.80 };
const green = [3]f32{ 0.55, 0.95, 0.60 };
const amber = [3]f32{ 1.0, 0.78, 0.40 };
const lit_col = [3]f32{ 1.0, 0.95, 0.70 };

// ------------------------------------------------------------------ drawing in light, on the screen

const sketch_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\layout(location = 1) in float a_across;
    \\layout(location = 2) in vec4 a_col;
    \\uniform vec2 u_size;
    \\out float v_across;
    \\out vec4 v_col;
    \\void main() {
    \\    v_across = a_across;
    \\    v_col = a_col;
    \\    gl_Position = vec4(a_pos.x / u_size.x * 2.0 - 1.0, 1.0 - a_pos.y / u_size.y * 2.0, 0.0, 1.0);
    \\}
;

const sketch_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in float v_across;
    \\in vec4 v_col;
    \\out vec4 o;
    \\void main() {
    \\    float a = (1.0 - smoothstep(0.35, 1.0, abs(v_across))) * v_col.a;
    \\    o = vec4(v_col.rgb * a, a);
    \\}
;

/// Lines of light drawn straight onto the screen, in pixels from its top left.
pub const Sketch = struct {
    prog: c.GLuint = 0,
    u_size: c.GLint = -1,
    vao: c.GLuint = 0,
    vbo: c.GLuint = 0,
    verts: [9000 * 7]f32 = undefined,
    used: usize = 0,
    w: f32 = 640.0,
    h: f32 = 480.0,

    pub fn init(self: *Sketch, w: i32, h: i32) bool {
        self.* = .{};
        self.w = @floatFromInt(w);
        self.h = @floatFromInt(h);
        self.prog = plat.linkProgram(sketch_vs, sketch_fs, "the songbook") orelse return false;
        self.u_size = gl.GetUniformLocation(self.prog, "u_size");
        gl.GenVertexArrays(1, &self.vao);
        gl.GenBuffers(1, &self.vbo);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 28, null);
        gl.EnableVertexAttribArray(1);
        gl.VertexAttribPointer(1, 1, c.GL_FLOAT, c.GL_FALSE, 28, @ptrFromInt(8));
        gl.EnableVertexAttribArray(2);
        gl.VertexAttribPointer(2, 4, c.GL_FLOAT, c.GL_FALSE, 28, @ptrFromInt(12));
        gl.BindVertexArray(0);
        return plat.checkGl("the songbook");
    }

    fn vert(self: *Sketch, x: f32, y: f32, across: f32, col: [4]f32) void {
        const v = self.verts[self.used .. self.used + 7];
        v[0] = x;
        v[1] = y;
        v[2] = across;
        v[3..7].* = col;
        self.used += 7;
    }

    /// A line from (x0, y0) to (x1, y1), `wide` pixels across, soft at its edges.
    pub fn seg(self: *Sketch, x0: f32, y0: f32, x1: f32, y1: f32, wide: f32, rgb: [3]f32, alpha: f32) void {
        if (self.used + 6 * 7 > self.verts.len or alpha <= 0.0) return;
        const dx = x1 - x0;
        const dy = y1 - y0;
        const len = @max(@sqrt(dx * dx + dy * dy), 0.001);
        const nx = -dy / len * wide * 0.5;
        const ny = dx / len * wide * 0.5;
        const col = [4]f32{ rgb[0], rgb[1], rgb[2], alpha };
        self.vert(x0 + nx, y0 + ny, 1.0, col);
        self.vert(x1 + nx, y1 + ny, 1.0, col);
        self.vert(x1 - nx, y1 - ny, -1.0, col);
        self.vert(x0 + nx, y0 + ny, 1.0, col);
        self.vert(x1 - nx, y1 - ny, -1.0, col);
        self.vert(x0 - nx, y0 - ny, -1.0, col);
    }

    /// A ring, in `parts` pieces; `drawn` of the way round, for a page half drawn.
    pub fn ring(self: *Sketch, cx: f32, cy: f32, r: f32, wide: f32, rgb: [3]f32, alpha: f32, drawn: f32) void {
        const parts: usize = 28;
        const upto: usize = @intFromFloat(@as(f32, @floatFromInt(parts)) * std.math.clamp(drawn, 0.0, 1.0));
        for (0..upto) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            self.seg(cx + r * @cos(a0), cy + r * @sin(a0), cx + r * @cos(a1), cy + r * @sin(a1), wide, rgb, alpha);
        }
    }

    /// The whole screen darkened, so nothing but the page is seen.
    pub fn veil(self: *Sketch, alpha: f32) void {
        if (self.used + 6 * 7 > self.verts.len) return;
        const col = [4]f32{ 0.0, 0.0, 0.0, alpha };
        self.vert(0, 0, 0, col);
        self.vert(self.w, 0, 0, col);
        self.vert(self.w, self.h, 0, col);
        self.vert(0, 0, 0, col);
        self.vert(self.w, self.h, 0, col);
        self.vert(0, self.h, 0, col);
    }

    pub fn flush(self: *Sketch) void {
        if (self.used == 0) return;
        gl.UseProgram(self.prog);
        gl.Uniform2f(self.u_size, self.w, self.h);
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
        gl.BindVertexArray(self.vao);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(self.used * @sizeOf(f32)), &self.verts, c.GL_STREAM_DRAW);
        gl.DrawArrays(c.GL_TRIANGLES, 0, @intCast(self.used / 7));
        gl.BindVertexArray(0);
        gl.Disable(c.GL_BLEND);
        self.used = 0;
    }
};

// ------------------------------------------------------------------ the handheld, by where things are

/// A control on the handheld, by its place.
pub const Control = enum { r1, r2, l1, l2, bottom, right, left, top, left_stick, right_stick, start };

/// How a page's control moves: lit while it is held, at the times of a phrase that repeats.
const Rhythm = struct {
    /// The phrase's length, in beats, and the beat in seconds.
    beats: f32 = 4.0,
    beat_s: f32 = 50.0 / 60.0,
    /// Held from this beat to this one (a tap is a short hold).
    from: f32 = 0.0,
    to: f32 = 0.3,
};

/// Draw the handheld, its top left at (x, y), `s` pixels to a unit, with `lit` controls bright.
/// Its shape is the R36S's: the screen above; the cross and the face buttons below it; a stick under
/// each; the shoulder buttons on its top edge, the nearer pair below the farther.
fn handheld(sk: *Sketch, x: f32, y: f32, s: f32, lit: []const Control, glow: f32, drawn: f32) void {
    const dim: f32 = 0.5 * drawn;
    const wb: f32 = 1.4;
    // the body, with rounded bottom corners
    const W: f32 = 100.0;
    const H: f32 = 150.0;
    sk.seg(x, y, x + W * s, y, wb, bone, dim);
    sk.seg(x, y, x, y + (H - 12.0) * s, wb, bone, dim);
    sk.seg(x + W * s, y, x + W * s, y + (H - 12.0) * s, wb, bone, dim);
    sk.seg(x + 12.0 * s, y + H * s, x + (W - 12.0) * s, y + H * s, wb, bone, dim);
    sk.seg(x, y + (H - 12.0) * s, x + 12.0 * s, y + H * s, wb, bone, dim);
    sk.seg(x + W * s, y + (H - 12.0) * s, x + (W - 12.0) * s, y + H * s, wb, bone, dim);
    // the screen
    const sx0 = x + 14.0 * s;
    const sx1 = x + (W - 14.0) * s;
    const sy0 = y + 10.0 * s;
    const sy1 = y + 64.0 * s;
    sk.seg(sx0, sy0, sx1, sy0, wb, bone, dim);
    sk.seg(sx0, sy1, sx1, sy1, wb, bone, dim);
    sk.seg(sx0, sy0, sx0, sy1, wb, bone, dim);
    sk.seg(sx1, sy0, sx1, sy1, wb, bone, dim);
    const isLit = struct {
        fn f(list: []const Control, want: Control) bool {
            for (list) |l| if (l == want) return true;
            return false;
        }
    }.f;
    const colOf = struct {
        fn f(on: bool) [3]f32 {
            return if (on) lit_col else bone;
        }
    }.f;
    const al = struct {
        fn f(on: bool, d: f32, g: f32) f32 {
            return if (on) (0.35 + 0.65 * g) else d;
        }
    }.f;
    // the shoulders: on the top edge, the nearer (R1, L1) as tabs and the farther (R2, L2) above
    const tabs = [4]struct { c: Control, x0: f32, x1: f32, y: f32 }{
        .{ .c = .l1, .x0 = 4.0, .x1 = 30.0, .y = -4.0 },
        .{ .c = .l2, .x0 = 2.0, .x1 = 24.0, .y = -10.0 },
        .{ .c = .r1, .x0 = W - 30.0, .x1 = W - 4.0, .y = -4.0 },
        .{ .c = .r2, .x0 = W - 24.0, .x1 = W - 2.0, .y = -10.0 },
    };
    for (tabs) |t| {
        const on = isLit(lit, t.c);
        const wide: f32 = if (on) 4.0 else 2.2;
        sk.seg(x + t.x0 * s, y + t.y * s, x + t.x1 * s, y + t.y * s, wide, colOf(on), al(on, dim, glow));
    }
    // the cross, left of middle
    const dx = x + 25.0 * s;
    const dy = y + 85.0 * s;
    sk.seg(dx - 9.0 * s, dy, dx + 9.0 * s, dy, 3.0, bone, dim);
    sk.seg(dx, dy - 9.0 * s, dx, dy + 9.0 * s, 3.0, bone, dim);
    // the face buttons: a diamond, right of middle
    const fx = x + 75.0 * s;
    const fy = y + 85.0 * s;
    const faces = [4]struct { c: Control, ox: f32, oy: f32 }{
        .{ .c = .top, .ox = 0.0, .oy = -8.0 },
        .{ .c = .left, .ox = -8.0, .oy = 0.0 },
        .{ .c = .right, .ox = 8.0, .oy = 0.0 },
        .{ .c = .bottom, .ox = 0.0, .oy = 8.0 },
    };
    for (faces) |f| {
        const on = isLit(lit, f.c);
        sk.ring(fx + f.ox * s, fy + f.oy * s, @as(f32, if (on) 4.2 else 3.2) * s, if (on) 3.0 else 1.6, colOf(on), al(on, dim, glow), 1.0);
    }
    // the sticks, under the cross and under the face buttons
    const sticks = [2]struct { c: Control, ox: f32 }{ .{ .c = .left_stick, .ox = 30.0 }, .{ .c = .right_stick, .ox = 70.0 } };
    for (sticks) |st| {
        const on = isLit(lit, st.c);
        sk.ring(x + st.ox * s, y + 118.0 * s, 9.0 * s, if (on) 3.0 else 1.6, colOf(on), al(on, dim, glow), 1.0);
        sk.ring(x + st.ox * s, y + 118.0 * s, 4.0 * s, 1.4, colOf(on), al(on, dim, glow) * 0.7, 1.0);
    }
    // start, under the screen on the right
    const on_start = isLit(lit, .start);
    sk.seg(x + 58.0 * s, y + 140.0 * s, x + 66.0 * s, y + 140.0 * s, if (on_start) 4.0 else 2.4, colOf(on_start), al(on_start, dim, glow));
    sk.seg(x + 34.0 * s, y + 140.0 * s, x + 42.0 * s, y + 140.0 * s, 2.4, bone, dim);
}

/// How brightly a control held to a rhythm is lit at time `t` (seconds), 0 or 1 eased.
fn held(r: Rhythm, t: f32) f32 {
    const phrase = r.beats * r.beat_s;
    const at = @mod(t, phrase) / r.beat_s;
    return if (at >= r.from and at < r.to) 1.0 else 0.0;
}

/// The tick marks of a phrase across the bottom of a scene, each flashing as the phrase passes it,
/// and a moving mark for now.
fn ticks(sk: *Sketch, x: f32, y: f32, wide: f32, r: Rhythm, t: f32, drawn: f32) void {
    const phrase = r.beats * r.beat_s;
    const at = @mod(t, phrase) / r.beat_s;
    const n: usize = @intFromFloat(r.beats);
    for (0..n + 1) |k| {
        const kx = x + wide * @as(f32, @floatFromInt(k)) / r.beats;
        const near = @abs(at - @as(f32, @floatFromInt(k)));
        const flash = std.math.clamp(1.0 - near * 4.0, 0.0, 1.0);
        sk.ring(kx, y, 3.0 + 3.0 * flash, 2.0, teal, (0.35 + 0.65 * flash) * drawn, 1.0);
    }
    const nx = x + wide * at / r.beats;
    sk.seg(nx, y - 10.0, nx, y + 10.0, 1.6, bone, 0.6 * drawn);
}

/// Hum, small, as it is on the page: a ring and a tick for where it faces.
fn hum(sk: *Sketch, x: f32, y: f32, r: f32, glow: f32, drawn: f32) void {
    sk.ring(x, y, r, 2.4, bone, (0.6 + 0.4 * glow) * drawn, 1.0);
    sk.seg(x, y, x, y - r * 1.4, 2.0, bone, 0.7 * drawn);
}

/// Draw a page into the scene box (x, y, wide, high) and the handheld beside it, at time `t`.
/// `whole` is how far it is drawn: a page not yet learned is half drawn.
pub fn draw(sk: *Sketch, p: Page, t: f32, whole: f32) void {
    sk.veil(0.86);
    const W = sk.w;
    const H = sk.h;
    const drawn = whole;
    // the page's own edge
    const px0: f32 = 26.0;
    const py0: f32 = 26.0;
    const px1 = W - 26.0;
    const py1 = H - 26.0;
    sk.seg(px0, py0, px1, py0, 1.2, bone, 0.18);
    sk.seg(px0, py1, px1, py1, 1.2, bone, 0.18);
    sk.seg(px0, py0, px0, py1, 1.2, bone, 0.18);
    sk.seg(px1, py0, px1, py1, 1.2, bone, 0.18);
    // the scene on the left, the handheld on the right
    const sx: f32 = 60.0;
    const sy: f32 = 70.0;
    const sw: f32 = 300.0;
    const sh: f32 = 300.0;
    const hx: f32 = 420.0;
    const hy: f32 = 110.0;
    const hs: f32 = 1.9;
    switch (p) {
        .call => {
            // R1, a tap: a ring runs out from Hum; far off, an answer comes back
            const r = Rhythm{ .beats = 4.0, .from = 0.0, .to = 0.35 };
            const g = held(r, t);
            const phrase = r.beats * r.beat_s;
            const age = @mod(t, phrase) / phrase;
            hum(sk, sx + 90.0, sy + 200.0, 10.0, g, drawn);
            sk.ring(sx + 90.0, sy + 200.0, 12.0 + age * 160.0, 2.0, bone, (1.0 - age) * 0.8 * drawn, drawn);
            const back = std.math.clamp(age * 2.0 - 0.8, 0.0, 1.0);
            sk.ring(sx + 250.0, sy + 80.0, 5.0, 2.4, teal, (0.3 + 0.7 * back) * drawn, 1.0);
            if (back > 0.0) sk.ring(sx + 250.0, sy + 80.0, 6.0 + back * 60.0, 1.8, teal, (1.0 - back) * 0.8 * drawn, drawn);
            handheld(sk, hx, hy, hs, &.{.r1}, g, drawn);
        },
        .breathe => {
            // R2, held through three beats and let go on the fourth tick, beside the small thing:
            // the figure between them turns while both hum
            const r = Rhythm{ .beats = 4.0, .from = 0.0, .to = 3.0 };
            const g = held(r, t);
            hum(sk, sx + 100.0, sy + 170.0, 12.0 + 4.0 * g, g, drawn);
            sk.ring(sx + 200.0, sy + 170.0, 7.0, 2.6, teal, (0.5 + 0.5 * g) * drawn, 1.0);
            if (g > 0.0) {
                // three lobes by two
                const cx = sx + 150.0;
                const cy = sy + 170.0;
                const parts: usize = 60;
                for (0..parts) |k| {
                    const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
                    const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
                    sk.seg(cx + 34.0 * @sin(3.0 * a0 + t), cy + 26.0 * @sin(2.0 * a0), cx + 34.0 * @sin(3.0 * a1 + t), cy + 26.0 * @sin(2.0 * a1), 1.6, teal, 0.7 * drawn);
                }
            }
            ticks(sk, sx + 40.0, sy + 270.0, 220.0, r, t, drawn);
            handheld(sk, hx, hy, hs, &.{.r2}, g, drawn);
        },
        .walk => {
            // the left stick walks; the right stick turns the view
            const along = @mod(t, 3.0) / 3.0;
            hum(sk, sx + 60.0 + along * 180.0, sy + 200.0, 10.0, 0.0, drawn);
            sk.seg(sx + 60.0, sy + 200.0, sx + 60.0 + along * 180.0, sy + 200.0, 1.4, bone, 0.4 * drawn);
            sk.ring(sx + 150.0, sy + 90.0, 40.0, 1.6, green, 0.5 * drawn, 0.3 + 0.4 * along);
            handheld(sk, hx, hy, hs, &.{ .left_stick, .right_stick }, 0.6 + 0.4 * @sin(t * 3.0), drawn);
        },
        .jump => {
            // the bottom face: up and over the hose; again at the top, the sail
            const r = Rhythm{ .beats = 4.0, .from = 0.0, .to = 0.3 };
            const g = held(r, t) + held(.{ .beats = 4.0, .from = 1.0, .to = 1.3 }, t);
            const phrase = r.beats * r.beat_s;
            const u = @mod(t, phrase) / phrase;
            const bx = sx + 40.0 + u * 230.0;
            const by = sy + 220.0 - 110.0 * @sin(std.math.pi * std.math.clamp(u * 1.6, 0.0, 1.0)) * @as(f32, if (u > 0.3) 0.9 else 1.0);
            // the hose, end on: a round tube on the ground
            sk.ring(sx + 150.0, sy + 220.0, 22.0, 2.4, green, 0.8 * drawn, drawn);
            sk.seg(sx + 10.0, sy + 243.0, sx + 290.0, sy + 243.0, 1.4, bone, 0.3 * drawn);
            hum(sk, bx, by, 10.0, g, drawn);
            if (u > 0.3 and u < 0.85) {
                sk.seg(bx, by - 4.0, bx - 26.0, by - 18.0, 2.0, bone, 0.8 * drawn);
                sk.seg(bx, by - 4.0, bx + 26.0, by - 18.0, 2.0, bone, 0.8 * drawn);
            }
            handheld(sk, hx, hy, hs, &.{.bottom}, @min(g, 1.0), drawn);
        },
        .sprint => {
            // the right face held while the left stick walks: faster, breathing
            const u = @mod(t, 2.0) / 2.0;
            const bx = sx + 30.0 + u * 250.0;
            hum(sk, bx, sy + 200.0, 10.0, 0.5, drawn);
            for (0..4) |k| {
                const back = @as(f32, @floatFromInt(k + 1)) * 14.0;
                sk.seg(bx - back - 8.0, sy + 200.0 + @as(f32, @floatFromInt(k)) * 3.0 - 4.0, bx - back + 4.0, sy + 200.0 + @as(f32, @floatFromInt(k)) * 3.0 - 4.0, 1.4, bone, 0.5 * drawn);
            }
            handheld(sk, hx, hy, hs, &.{ .right, .left_stick }, 1.0, drawn);
        },
        .strike => {
            // the left face on the downbeat: the knot rings
            const r = Rhythm{ .beats = 4.0, .from = 0.0, .to = 0.3 };
            const g = held(r, t);
            hum(sk, sx + 100.0, sy + 190.0, 10.0, g, drawn);
            sk.ring(sx + 200.0, sy + 170.0, 16.0, 2.2, amber, (0.4 + 0.6 * g) * drawn, 1.0);
            sk.ring(sx + 200.0, sy + 170.0, 9.0, 1.6, green, (0.4 + 0.6 * g) * drawn, 1.0);
            if (g > 0.0) sk.seg(sx + 112.0, sy + 186.0, sx + 184.0, sy + 172.0, 3.0, lit_col, 0.9 * drawn);
            ticks(sk, sx + 40.0, sy + 270.0, 220.0, r, t, drawn);
            handheld(sk, hx, hy, hs, &.{.left}, g, drawn);
        },
        .dodge => {
            // the right face as the lunge arrives: a step aside, and time opens
            const r = Rhythm{ .beats = 4.0, .from = 2.0, .to = 2.3 };
            const g = held(r, t);
            const phrase = r.beats * r.beat_s;
            const u = @mod(t, phrase) / phrase;
            const side: f32 = if (u > 0.5) 40.0 else 0.0;
            hum(sk, sx + 120.0, sy + 190.0 - side, 10.0, g, drawn);
            const lx = sx + 250.0 - 120.0 * std.math.clamp(u * 2.0, 0.0, 1.0);
            sk.ring(lx, sy + 190.0, 14.0, 2.2, amber, 0.8 * drawn, 1.0);
            ticks(sk, sx + 40.0, sy + 270.0, 220.0, r, t, drawn);
            handheld(sk, hx, hy, hs, &.{.right}, g, drawn);
        },
        .wheel => {
            // R1 held: the wheel opens round Hum; the right stick points at a wedge; let go there
            const u = @mod(t, 4.0) / 4.0;
            const cx = sx + 150.0;
            const cy = sy + 160.0;
            sk.ring(cx, cy, 110.0, 1.6, bone, 0.5 * drawn, std.math.clamp(u * 3.0, 0.0, 1.0));
            for (0..12) |k| {
                const a = @as(f32, @floatFromInt(k)) * (6.2831853 / 12.0) - std.math.pi * 0.5;
                const pointed = k == 11 and u > 0.45;
                sk.seg(cx + 40.0 * @cos(a), cy + 40.0 * @sin(a), cx + 110.0 * @cos(a), cy + 110.0 * @sin(a), if (pointed) 3.5 else 1.2, if (pointed) lit_col else green, @as(f32, if (pointed) 0.95 else 0.35) * drawn);
            }
            hum(sk, cx, cy, 10.0, 0.5, drawn);
            const holding = u < 0.8;
            handheld(sk, hx, hy, hs, if (u > 0.45 and holding) &.{ .r1, .right_stick } else if (holding) &.{.r1} else &.{}, 1.0, drawn);
        },
        .swell => {
            // R2 held, a nudge of the right stick on a downbeat, and let go on the one
            const r = Rhythm{ .beats = 8.0, .from = 0.0, .to = 8.0 - 0.05 };
            const phrase = r.beats * r.beat_s;
            const u = @mod(t, phrase) / phrase;
            hum(sk, sx + 150.0, sy + 170.0, 12.0 + 20.0 * u, 1.0, drawn);
            for (0..@as(usize, @intFromFloat(u * 4.0))) |k| sk.ring(sx + 150.0, sy + 170.0, 16.0 + 8.0 * @as(f32, @floatFromInt(k)), 2.0, green, 0.5 * drawn, 1.0);
            ticks(sk, sx + 40.0, sy + 270.0, 220.0, .{ .beats = 8.0 }, t, drawn);
            const nudge = @abs(@mod(t, phrase) / r.beat_s - 4.0) < 0.3;
            handheld(sk, hx, hy, hs, if (nudge) &.{ .r2, .right_stick } else &.{.r2}, 1.0, drawn);
        },
        .clap => {
            // the two nearer shoulders together: a clap
            const r = Rhythm{ .beats = 4.0, .from = 0.0, .to = 0.3 };
            const g = held(r, t);
            const phrase = r.beats * r.beat_s;
            const age = @mod(t, phrase) / phrase;
            hum(sk, sx + 150.0, sy + 170.0, 10.0, g, drawn);
            sk.ring(sx + 150.0, sy + 170.0, 14.0 + age * 120.0, 3.0, bone, (1.0 - age) * drawn, drawn);
            handheld(sk, hx, hy, hs, &.{ .l1, .r1 }, g, drawn);
        },
    }
    _ = sw;
    _ = sh;
}
