//! Black shapes: the triangles that hide what is behind a solid thing, made from its shapes
//! (docs/engine.md, "Hiding"). Lines are drawn by adding light, so a line can never hide a line;
//! only these can. Every solid kind of thing gets its black shapes from here and nowhere else, so
//! what hides is always what the body layer finds solid.
//!
//! A black shape stands a little inside the thing's own lines, so that it never hides them. It has
//! no faces to tell front from back: a triangle hides from both sides.
//!
//! No world in it and no platform.
const std = @import("std");
const form = @import("../form/shape.zig");
const V3 = form.V3;

/// How much of a round thing's width its black shape takes.
pub const inside: f32 = 0.9;

/// Where black triangles go: three points to each.
pub const Tris = struct {
    out: []V3,
    n: usize = 0,
    /// How many triangles did not fit.
    lost: usize = 0,

    pub fn tri(self: *Tris, a: V3, b: V3, c: V3) void {
        if (self.n + 3 > self.out.len) {
            self.lost += 1;
            return;
        }
        self.out[self.n] = a;
        self.out[self.n + 1] = b;
        self.out[self.n + 2] = c;
        self.n += 3;
    }

    pub fn slice(self: *const Tris) []const V3 {
        return self.out[0..self.n];
    }

    pub fn count(self: *const Tris) usize {
        return self.n / 3;
    }
};

/// A stalk: its sides, as flat faces from one end to the other, between the edges its lines are
/// drawn on. Its ends are left open, as a stalk's nearly always stand on something or carry
/// something.
pub fn stalk(s: form.Stalk, tris: *Tris) void {
    const sides = s.sides();
    const step = 2.0 * std.math.pi / @as(f32, @floatFromInt(sides));
    for (0..sides) |k| {
        const t0 = @as(f32, @floatFromInt(k)) * step;
        const t1 = @as(f32, @floatFromInt(k + 1)) * step;
        const a0 = s.skin(0.0, t0, inside);
        const a1 = s.skin(0.0, t1, inside);
        const b0 = s.skin(1.0, t0, inside);
        const b1 = s.skin(1.0, t1, inside);
        tris.tri(a0, a1, b1);
        tris.tri(a0, b1, b0);
    }
}

/// A plate: its top, fanned out from its first corner.
pub fn plate(p: form.Plate, tris: *Tris) void {
    if (p.n < 3) return;
    for (1..p.n - 1) |k| tris.tri(p.corners[0], p.corners[k], p.corners[k + 1]);
}

/// A ball: eight faces round it, each from a tip to two of its waist.
pub fn ball(b: form.Ball, tris: *Tris) void {
    const r = b.r * inside;
    const top = form.add(b.at, .{ 0.0, r, 0.0 });
    const bottom = form.add(b.at, .{ 0.0, -r, 0.0 });
    const waist = [4]V3{
        form.add(b.at, .{ r, 0.0, 0.0 }),
        form.add(b.at, .{ 0.0, 0.0, r }),
        form.add(b.at, .{ -r, 0.0, 0.0 }),
        form.add(b.at, .{ 0.0, 0.0, -r }),
    };
    for (0..4) |k| {
        tris.tri(top, waist[k], waist[(k + 1) % 4]);
        tris.tri(bottom, waist[(k + 1) % 4], waist[k]);
    }
}

pub fn of(shape: form.Shape, tris: *Tris) void {
    switch (shape) {
        .stalk => |s| stalk(s, tris),
        .plate => |p| plate(p, tris),
        .ball => |b| ball(b, tris),
    }
}

pub fn ofAll(shapes: []const form.Shape, tris: *Tris) void {
    for (shapes) |shape| of(shape, tris);
}

/// A round thing that always faces the eye, as Hum does: an oval of so many parts, fanned from its
/// middle. `rim` gives its points in order round it; the black shape is drawn in from them toward
/// the middle by `inside`.
pub fn facing(middle: V3, rim: []const V3, tris: *Tris) void {
    if (rim.len < 3) return;
    for (0..rim.len) |k| {
        const a = form.between(middle, rim[k], inside);
        const b = form.between(middle, rim[(k + 1) % rim.len], inside);
        tris.tri(middle, a, b);
    }
}

const expectEqual = std.testing.expectEqual;
const expectApprox = std.testing.expectApproxEqAbs;

test "a stalk's black shape keeps inside its width, all the way along" {
    var room: [3 * 16]V3 = undefined;
    var tris = Tris{ .out = &room };
    stalk(.{ .a = .{ 0.0, 0.0, 0.0 }, .b = .{ 0.0, 10.0, 0.0 }, .ra = 1.0, .rb = 0.5 }, &tris);
    try expectEqual(@as(usize, 12), tris.count());
    for (tris.slice()) |p| {
        const off = @sqrt(p[0] * p[0] + p[2] * p[2]);
        const reach = 1.0 - 0.5 * p[1] / 10.0;
        try expectApprox(reach * inside, off, 1e-4);
    }
}

test "a plate of five corners is three triangles, a ball eight" {
    var room: [3 * 12]V3 = undefined;
    var tris = Tris{ .out = &room };
    var p = form.Plate{ .n = 5 };
    for (0..5) |k| p.corners[k] = .{ @floatFromInt(k), 2.0, @floatFromInt(k * k) };
    plate(p, &tris);
    try expectEqual(@as(usize, 3), tris.count());
    ball(.{ .at = .{ 0.0, 1.0, 0.0 }, .r = 1.0 }, &tris);
    try expectEqual(@as(usize, 11), tris.count());
    // what does not fit is counted, not written
    ball(.{ .at = .{ 0.0, 1.0, 0.0 }, .r = 1.0 }, &tris);
    try expectEqual(@as(usize, 12), tris.count());
    try expectEqual(@as(usize, 7), tris.lost);
}
