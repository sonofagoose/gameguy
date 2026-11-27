//! Solids: what stops Hum, what he can stand on, and what is over his head (docs/engine.md,
//! "Solids, and Hum's body"). A solid is a shape with someone to tell when it is touched. Every
//! solid has sides, a top and an underside, whatever kind of thing it is, so there is one answer
//! to "can I stand on that?" and one to "does that stop me?".
//!
//! A solid's points are whole heights: the ground under each has already been added.
//!
//! Only sums every machine agrees on: add, take, times, divide and square root. No world in it and
//! no platform.
const std = @import("std");
const form = @import("../form/shape.zig");
const V3 = form.V3;

/// Whose a solid is, so that touching it can sound it. The world knows what each kind means.
pub const Kind = enum(u8) { tower, reed, hose, spigot, fallen, clover, crumb, moss, drip, other };

pub const Solid = struct {
    shape: form.Shape,
    kind: Kind = .other,
    /// Which one of its kind: a tower's number, a reed's place among the reeds, a cover's own number.
    id: u32 = 0,
};

/// Something upright and round that moves among solids: Hum. Its feet are a whole height.
pub const Body = struct {
    x: f32,
    z: f32,
    feet: f32,
    /// How far it reaches from its middle line, and how tall it stands.
    reach: f32,
    tall: f32,

    fn low(self: Body) V3 {
        return .{ self.x, self.feet + self.reach, self.z };
    }

    fn high(self: Body) V3 {
        return .{ self.x, self.feet + @max(self.tall - self.reach, self.reach), self.z };
    }

    pub fn head(self: Body) f32 {
        return self.feet + self.tall;
    }
};

/// How a body has to move, level, to stand clear of a solid: which way, and how far.
pub const Meet = struct {
    nx: f32,
    nz: f32,
    by: f32,
};

/// A body this near under the top of a solid steps up onto it; lower than that, the solid is a
/// wall to it. The world gives its own step.
pub const default_step: f32 = 0.3;

/// A stalk no steeper than this, rise over run, is something to stand along: a tube lying down, a
/// low branch. A steeper one is a post, with only its top end to stand on.
const lies_within: f32 = 1.0;

const Pair = struct { s: f32, t: f32 };

/// Where two lines come nearest: how far along each, from nought to one.
fn nearest(p1: V3, q1: V3, p2: V3, q2: V3) Pair {
    const tiny: f32 = 1e-9;
    const d1 = form.sub(q1, p1);
    const d2 = form.sub(q2, p2);
    const r = form.sub(p1, p2);
    const a = form.dot(d1, d1);
    const e = form.dot(d2, d2);
    const f = form.dot(d2, r);
    if (a <= tiny and e <= tiny) return .{ .s = 0.0, .t = 0.0 };
    if (a <= tiny) return .{ .s = 0.0, .t = std.math.clamp(f / e, 0.0, 1.0) };
    const c = form.dot(d1, r);
    if (e <= tiny) return .{ .s = std.math.clamp(-c / a, 0.0, 1.0), .t = 0.0 };
    const b = form.dot(d1, d2);
    const denom = a * e - b * b;
    var s: f32 = if (denom > tiny) std.math.clamp((b * f - c * e) / denom, 0.0, 1.0) else 0.0;
    var t = (b * s + f) / e;
    if (t < 0.0) {
        t = 0.0;
        s = std.math.clamp(-c / a, 0.0, 1.0);
    } else if (t > 1.0) {
        t = 1.0;
        s = std.math.clamp((b - c) / a, 0.0, 1.0);
    }
    return .{ .s = s, .t = t };
}

/// Level push that clears a body from a round thing whose middle line is nearest it at `at`, with
/// `reach` from there to its skin. `from` is where the body stood before, for when it is dead on.
fn clearOf(body: Body, at: V3, on_body: V3, reach: f32, from_x: f32, from_z: f32) ?Meet {
    const both = reach + body.reach;
    const dy = on_body[1] - at[1];
    if (@abs(dy) >= both) return null;
    const need = @sqrt(both * both - dy * dy);
    var hx = on_body[0] - at[0];
    var hz = on_body[2] - at[2];
    const h = @sqrt(hx * hx + hz * hz);
    if (h >= need) return null;
    var len = h;
    if (len < 1e-4) {
        // dead on its middle: out the way the body came from, or east if it has always been here
        hx = from_x - at[0];
        hz = from_z - at[2];
        len = @sqrt(hx * hx + hz * hz);
        if (len < 1e-4) {
            hx = 1.0;
            hz = 0.0;
            len = 1.0;
        }
    }
    return .{ .nx = hx / len, .nz = hz / len, .by = need - h };
}

fn lies(s: form.Stalk) bool {
    const dx = s.b[0] - s.a[0];
    const dz = s.b[2] - s.a[2];
    const run = @sqrt(dx * dx + dz * dz);
    return @abs(s.b[1] - s.a[1]) <= lies_within * run;
}

const Under = struct { at: V3, reach: f32, across: f32 };

/// The point of a lying stalk's middle line that is under or over a place, how far it reaches
/// there, and how far across from it the place is. Null when the place is not over the stalk.
fn alongStalk(s: form.Stalk, x: f32, z: f32) ?Under {
    const dx = s.b[0] - s.a[0];
    const dz = s.b[2] - s.a[2];
    const l2 = dx * dx + dz * dz;
    if (l2 < 1e-9) return null;
    const t = std.math.clamp(((x - s.a[0]) * dx + (z - s.a[2]) * dz) / l2, 0.0, 1.0);
    const at = form.between(s.a, s.b, t);
    const reach = s.ra + (s.rb - s.ra) * t;
    const ox = x - at[0];
    const oz = z - at[2];
    const across = @sqrt(ox * ox + oz * oz);
    if (across > reach) return null;
    return .{ .at = at, .reach = reach, .across = across };
}

/// The top or bottom end of a standing stalk, if a place is over it: its height.
fn endOf(s: form.Stalk, x: f32, z: f32, upper: bool) ?f32 {
    const a_is_end = (s.a[1] >= s.b[1]) == upper;
    const end = if (a_is_end) s.a else s.b;
    const reach = if (a_is_end) s.ra else s.rb;
    const ox = x - end[0];
    const oz = z - end[2];
    if (ox * ox + oz * oz > reach * reach) return null;
    return end[1];
}

/// Where the plate's top is over a place inside its outline; null outside it.
fn onPlate(p: form.Plate, x: f32, z: f32) ?f32 {
    if (p.n < 3) return null;
    // inside if the place is on the same side of every edge, seen from above
    var side: f32 = 0.0;
    for (0..p.n) |i| {
        const a = p.corners[i];
        const b = p.corners[(i + 1) % p.n];
        const turn = (b[0] - a[0]) * (z - a[2]) - (b[2] - a[2]) * (x - a[0]);
        if (turn == 0.0) continue;
        if (side == 0.0) side = turn else if ((turn > 0.0) != (side > 0.0)) return null;
    }
    // its height there, from the plane its first three corners lie in
    const n = form.cross(form.sub(p.corners[1], p.corners[0]), form.sub(p.corners[2], p.corners[0]));
    if (@abs(n[1]) < 1e-6) return null;
    const a = p.corners[0];
    return a[1] - (n[0] * (x - a[0]) + n[2] * (z - a[2])) / n[1];
}

/// The nearest point of a plate's outline to a place, level.
fn nearestOnOutline(p: form.Plate, x: f32, z: f32) V3 {
    var best = p.corners[0];
    var best_d: f32 = std.math.floatMax(f32);
    for (0..p.n) |i| {
        const a = p.corners[i];
        const b = p.corners[(i + 1) % p.n];
        const dx = b[0] - a[0];
        const dz = b[2] - a[2];
        const l2 = dx * dx + dz * dz;
        const t = if (l2 > 1e-9) std.math.clamp(((x - a[0]) * dx + (z - a[2]) * dz) / l2, 0.0, 1.0) else 0.0;
        const q = form.between(a, b, t);
        const ox = x - q[0];
        const oz = z - q[2];
        const d = ox * ox + oz * oz;
        if (d < best_d) {
            best_d = d;
            best = q;
        }
    }
    return best;
}

/// The height of a solid's top under a place, if the place is over it: what a body there could
/// stand on.
pub fn top(solid: *const Solid, x: f32, z: f32) ?f32 {
    switch (solid.shape) {
        .stalk => |s| {
            if (!lies(s)) return endOf(s, x, z, true);
            const u = alongStalk(s, x, z) orelse return null;
            return u.at[1] + @sqrt(u.reach * u.reach - u.across * u.across);
        },
        .ball => |b| {
            const ox = x - b.at[0];
            const oz = z - b.at[2];
            const d2 = ox * ox + oz * oz;
            if (d2 > b.r * b.r) return null;
            return b.at[1] + @sqrt(b.r * b.r - d2);
        },
        .plate => |p| return onPlate(p, x, z),
    }
}

/// The height of a solid's underside over a place, if the place is under it: what a body rising
/// there would meet.
pub fn underside(solid: *const Solid, x: f32, z: f32) ?f32 {
    switch (solid.shape) {
        .stalk => |s| {
            if (!lies(s)) return endOf(s, x, z, false);
            const u = alongStalk(s, x, z) orelse return null;
            return u.at[1] - @sqrt(u.reach * u.reach - u.across * u.across);
        },
        .ball => |b| {
            const ox = x - b.at[0];
            const oz = z - b.at[2];
            const d2 = ox * ox + oz * oz;
            if (d2 > b.r * b.r) return null;
            return b.at[1] - @sqrt(b.r * b.r - d2);
        },
        .plate => |p| {
            const y = onPlate(p, x, z) orelse return null;
            return y - p.thick;
        },
    }
}

/// Whether a solid is a floor to a body where it is: the body is over it, and no lower than a
/// step under its top.
pub fn floorTo(solid: *const Solid, body: Body, step: f32) bool {
    const t = top(solid, body.x, body.z) orelse return false;
    return body.feet >= t - step;
}

/// How a body must move, level, to stand clear of a solid's sides; null if it is clear already, or
/// if the solid is a floor to it. `from` is where the body stood before this step.
pub fn meet(solid: *const Solid, body: Body, step: f32, from_x: f32, from_z: f32) ?Meet {
    if (floorTo(solid, body, step)) return null;
    switch (solid.shape) {
        .stalk => |s| {
            const pair = nearest(body.low(), body.high(), s.a, s.b);
            const on_body = form.between(body.low(), body.high(), pair.s);
            const at = form.between(s.a, s.b, pair.t);
            return clearOf(body, at, on_body, s.ra + (s.rb - s.ra) * pair.t, from_x, from_z);
        },
        .ball => |b| {
            const pair = nearest(body.low(), body.high(), b.at, b.at);
            const on_body = form.between(body.low(), body.high(), pair.s);
            return clearOf(body, b.at, on_body, b.r, from_x, from_z);
        },
        .plate => |p| {
            if (p.n < 3) return null;
            if (onPlate(p, body.x, body.z)) |y| {
                // under it or over it there is nothing to its side; inside it, the way up and down
                // is the world's to mend, not a level push
                _ = y;
                return null;
            }
            const q = nearestOnOutline(p, body.x, body.z);
            // only if the body's height takes in the plate's edge there
            if (body.feet >= q[1] or body.head() <= q[1] - p.thick) return null;
            const ox = body.x - q[0];
            const oz = body.z - q[2];
            const d = @sqrt(ox * ox + oz * oz);
            if (d >= body.reach) return null;
            if (d < 1e-4) {
                const mid = p.middle();
                const mx = body.x - mid[0];
                const mz = body.z - mid[2];
                const ml = @max(@sqrt(mx * mx + mz * mz), 1e-4);
                return .{ .nx = mx / ml, .nz = mz / ml, .by = body.reach };
            }
            return .{ .nx = ox / d, .nz = oz / d, .by = body.reach - d };
        },
    }
}

/// How far a solid reaches level from a place at most: for finding what is near.
pub fn bounds(solid: *const Solid) struct { min_x: f32, max_x: f32, min_z: f32, max_z: f32 } {
    switch (solid.shape) {
        .stalk => |s| {
            const r = @max(s.ra, s.rb);
            return .{ .min_x = @min(s.a[0], s.b[0]) - r, .max_x = @max(s.a[0], s.b[0]) + r, .min_z = @min(s.a[2], s.b[2]) - r, .max_z = @max(s.a[2], s.b[2]) + r };
        },
        .ball => |b| return .{ .min_x = b.at[0] - b.r, .max_x = b.at[0] + b.r, .min_z = b.at[2] - b.r, .max_z = b.at[2] + b.r },
        .plate => |p| {
            var out = .{ .min_x = p.corners[0][0], .max_x = p.corners[0][0], .min_z = p.corners[0][2], .max_z = p.corners[0][2] };
            for (p.slice()) |c| {
                out.min_x = @min(out.min_x, c[0]);
                out.max_x = @max(out.max_x, c[0]);
                out.min_z = @min(out.min_z, c[2]);
                out.max_z = @max(out.max_z, c[2]);
            }
            return .{ .min_x = out.min_x, .max_x = out.max_x, .min_z = out.min_z, .max_z = out.max_z };
        },
    }
}

/// Lift a shape whose heights are over its own ground to whole heights, by the ground at each of
/// its points.
pub fn lifted(shape: form.Shape, height: *const fn (f32, f32) f32) form.Shape {
    var out = shape;
    switch (out) {
        .stalk => |*s| {
            s.a[1] += height(s.a[0], s.a[2]);
            s.b[1] += height(s.b[0], s.b[2]);
        },
        .ball => |*b| b.at[1] += height(b.at[0], b.at[2]),
        .plate => |*p| {
            for (p.corners[0..p.n]) |*c| c[1] += height(c[0], c[2]);
        },
    }
    return out;
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const approx = std.testing.expectApproxEqAbs;

fn hum(x: f32, z: f32, feet: f32) Body {
    return .{ .x = x, .z = z, .feet = feet, .reach = 0.36, .tall = 1.0 };
}

fn post(x: f32, z: f32, tall: f32, reach: f32) Solid {
    return .{ .shape = .{ .stalk = .{ .a = .{ x, 0.0, z }, .b = .{ x, tall, z }, .ra = reach, .rb = reach } } };
}

fn tube(reach: f32) Solid {
    // lying east to west along z = 0, on the ground
    return .{ .shape = .{ .stalk = .{ .a = .{ -10.0, reach, 0.0 }, .b = .{ 10.0, reach, 0.0 }, .ra = reach, .rb = reach } } };
}

test "a post pushes a body out to where they touch, and no further" {
    const p = post(0.0, 0.0, 20.0, 0.5);
    // well clear
    try expect(meet(&p, hum(2.0, 0.0, 0.0), default_step, 3.0, 0.0) == null);
    // overlapping by a hand's width from the east
    const m = meet(&p, hum(0.76, 0.0, 0.0), default_step, 2.0, 0.0).?;
    try approx(@as(f32, 1.0), m.nx, 1e-5);
    try approx(@as(f32, 0.0), m.nz, 1e-5);
    try approx(@as(f32, 0.10), m.by, 1e-4);
    // dead on its middle: out the way it came
    const dead = meet(&p, hum(0.0, 0.0, 0.0), default_step, 0.0, -1.0).?;
    try approx(@as(f32, -1.0), dead.nz, 1e-5);
    try approx(@as(f32, 0.86), dead.by, 1e-4);
    // above its top there is nothing to its side
    try expect(meet(&p, hum(0.5, 0.0, 20.5), default_step, 2.0, 0.0) == null);
}

test "a post's top is a place to stand" {
    const p = post(0.0, 0.0, 4.0, 1.0);
    try approx(@as(f32, 4.0), top(&p, 0.5, 0.0).?, 1e-5);
    try expect(top(&p, 1.5, 0.0) == null);
    // standing on it, it is a floor and not a wall
    try expect(floorTo(&p, hum(0.5, 0.0, 4.0), default_step));
    try expect(meet(&p, hum(0.5, 0.0, 4.0), default_step, 0.5, 0.0) == null);
    // at its foot it is a wall
    try expect(!floorTo(&p, hum(0.5, 0.0, 0.0), default_step));
}

test "a tube lying on the ground: a wall at its side, a floor on top, a roof from inside" {
    const t = tube(0.9);
    // beside it on the ground it stops a body
    const side = meet(&t, hum(0.0, 1.0, 0.0), default_step, 0.0, 3.0).?;
    try approx(@as(f32, 1.0), side.nz, 1e-5);
    try expect(side.by > 0.0);
    // far enough off it does not
    try expect(meet(&t, hum(0.0, 1.5, 0.0), default_step, 0.0, 3.0) == null);
    // its top is its whole width high over its middle, and lower toward its shoulders
    try approx(@as(f32, 1.8), top(&t, 3.0, 0.0).?, 1e-5);
    try approx(@as(f32, 0.9 + @sqrt(0.81 - 0.25)), top(&t, 3.0, 0.5).?, 1e-5);
    try expect(top(&t, 3.0, 1.0) == null);
    // a body standing on top of it is not pushed
    try expect(meet(&t, hum(0.0, 0.0, 1.8), default_step, 0.0, 0.0) == null);
    try expect(meet(&t, hum(0.0, 0.5, 1.8), default_step, 0.0, 0.0) == null);
    // and a body high over it is clear
    try expect(meet(&t, hum(0.0, 0.0, 5.0), default_step, 0.0, 0.0) == null);
    try approx(@as(f32, 0.0), underside(&t, 0.0, 0.0).?, 1e-5);
}

test "a leaning stalk is a post: it has no floor along it" {
    const reed = Solid{ .shape = .{ .stalk = .{ .a = .{ 0.0, 0.0, 0.0 }, .b = .{ 3.0, 40.0, 0.0 }, .ra = 0.3, .rb = 0.2 } } };
    try expect(top(&reed, 0.1, 0.0) == null);
    try expect(!floorTo(&reed, hum(0.1, 0.0, 0.0), default_step));
    try expect(meet(&reed, hum(0.3, 0.0, 0.0), default_step, 1.0, 0.0) != null);
}

test "a ball: round to walk into, round to stand on" {
    const b = Solid{ .shape = .{ .ball = .{ .at = .{ 0.0, 1.0, 0.0 }, .r = 1.0 } } };
    try approx(@as(f32, 2.0), top(&b, 0.0, 0.0).?, 1e-5);
    try approx(@as(f32, 0.0), underside(&b, 0.0, 0.0).?, 1e-5);
    const m = meet(&b, hum(1.2, 0.0, 0.0), default_step, 3.0, 0.0).?;
    try approx(@as(f32, 1.0), m.nx, 1e-5);
    try expect(meet(&b, hum(0.0, 0.0, 2.0), default_step, 0.0, 0.0) == null);
    // a mound: a ball sunk so that only its cap shows is walked up, never walked into
    const mound = Solid{ .shape = .{ .ball = .{ .at = .{ 0.0, -4.0, 0.0 }, .r = 5.0 } } };
    try approx(@as(f32, 1.0), top(&mound, 0.0, 0.0).?, 1e-5);
    try expect(meet(&mound, hum(2.9, 0.0, 0.0), default_step, 4.0, 0.0) == null);
}

test "a plate: a floor above, a roof below, an edge at its side" {
    var sink_room: [1]form.Shape = undefined;
    var sink = form.Sink{ .out = &sink_room };
    sink.plate(&.{ .{ -2.0, 3.0, -2.0 }, .{ 2.0, 3.0, -2.0 }, .{ 2.0, 3.0, 2.0 }, .{ -2.0, 3.0, 2.0 } }, 0.2);
    const leaf = Solid{ .shape = sink.out[0] };
    try approx(@as(f32, 3.0), top(&leaf, 0.0, 0.0).?, 1e-5);
    try approx(@as(f32, 2.8), underside(&leaf, 1.0, -1.0).?, 1e-5);
    try expect(top(&leaf, 2.5, 0.0) == null);
    // under it or on it nothing pushes level
    try expect(meet(&leaf, hum(0.0, 0.0, 0.0), default_step, 0.0, 0.0) == null);
    try expect(meet(&leaf, hum(0.0, 0.0, 3.0), default_step, 0.0, 0.0) == null);
    // beside it at its height, its edge does
    const m = meet(&leaf, hum(2.2, 0.0, 2.4), default_step, 3.0, 0.0).?;
    try approx(@as(f32, 1.0), m.nx, 1e-5);
    try approx(@as(f32, 0.16), m.by, 1e-4);
    // beside it on the ground, it is over the body's head
    try expect(meet(&leaf, hum(2.2, 0.0, 0.0), default_step, 3.0, 0.0) == null);
    // a tilted plate's top follows its slope
    var tilt_room: [1]form.Shape = undefined;
    var tilt = form.Sink{ .out = &tilt_room };
    tilt.plate(&.{ .{ 0.0, 0.0, 0.0 }, .{ 4.0, 2.0, 0.0 }, .{ 4.0, 2.0, 4.0 }, .{ 0.0, 0.0, 4.0 } }, 0.1);
    const ramp = Solid{ .shape = tilt.out[0] };
    try approx(@as(f32, 1.0), top(&ramp, 2.0, 2.0).?, 1e-5);
}

test "lifting a shape adds the ground under each of its points" {
    const slope = struct {
        fn at(x: f32, z: f32) f32 {
            _ = z;
            return x * 0.5;
        }
    }.at;
    const s = lifted(.{ .stalk = .{ .a = .{ 0.0, 1.0, 0.0 }, .b = .{ 4.0, 1.0, 0.0 }, .ra = 1.0, .rb = 1.0 } }, &slope);
    try approx(@as(f32, 1.0), s.stalk.a[1], 1e-6);
    try approx(@as(f32, 3.0), s.stalk.b[1], 1e-6);
}
