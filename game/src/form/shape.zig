//! Shapes: one description of a solid thing, read by what stops Hum and by what hides
//! (docs/engine.md, "Forms"). A kind of thing says what shapes it is made of, once. The body layer
//! turns them into solids and the picture turns the same ones into black shapes, so what is seen
//! and what is felt cannot disagree.
//!
//! A point is x, y, z in metres: x east, z south, and y the height above the ground under that
//! point. Whoever uses a shape adds the ground's height where it matters.
//!
//! No world in it, no picture and no platform.
const std = @import("std");

pub const V3 = [3]f32;

/// A round thing along a line, wider at one end than the other if it tapers: a stalk, a stem, a
/// post, a stretch of tube.
pub const Stalk = struct {
    a: V3,
    b: V3,
    /// How far it reaches from its middle line, at each end.
    ra: f32,
    rb: f32,

    /// A point on its skin: `along` from nought at one end to one at the other, `turn` radians round
    /// it, and `part` of the way out from its middle line (one is the skin itself). Its black shape,
    /// its lines and its solid are all placed by this, so they turn together.
    pub fn skin(self: Stalk, along: f32, turn: f32, part: f32) V3 {
        const uv = across(sub(self.b, self.a));
        const at = between(self.a, self.b, along);
        const reach = (self.ra + (self.rb - self.ra) * along) * part;
        return add(at, add(scale(uv[0], reach * @cos(turn)), scale(uv[1], reach * @sin(turn))));
    }

    /// One of its edges, of as many as it has flat sides: a line along its skin from end to end.
    pub fn edge(self: Stalk, k: usize) [2]V3 {
        const turn = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, @floatFromInt(self.sides())));
        return .{ self.skin(0.0, turn, 1.0), self.skin(1.0, turn, 1.0) };
    }

    /// How many flat sides it is given: few when it is thin, since a thin thing is a dot or two
    /// wide on this screen at any distance worth hiding behind.
    pub fn sides(self: Stalk) usize {
        const reach = @max(self.ra, self.rb);
        return if (reach < 0.35) 3 else if (reach < 0.7) 5 else if (reach < 1.4) 6 else 8;
    }
};

/// A flat thing with a top and an underside: a leaf, a pad, a plank, a ledge. Its corners go round
/// its top in order, all in one plane, and bulge outward everywhere.
pub const Plate = struct {
    pub const most = 8;
    corners: [most]V3 = @splat(.{ 0.0, 0.0, 0.0 }),
    n: u8 = 0,
    /// How far its underside is below its top.
    thick: f32 = 0.15,

    pub fn slice(self: *const Plate) []const V3 {
        return self.corners[0..self.n];
    }

    /// The middle of its corners.
    pub fn middle(self: *const Plate) V3 {
        var m = V3{ 0.0, 0.0, 0.0 };
        for (self.slice()) |c| m = add(m, c);
        return scale(m, 1.0 / @as(f32, @floatFromInt(@max(self.n, 1))));
    }
};

/// A round thing: a bell, a drop, a crumb, a head.
pub const Ball = struct {
    at: V3,
    r: f32,
};

pub const Shape = union(enum) {
    stalk: Stalk,
    plate: Plate,
    ball: Ball,
};

/// Somewhere to put the shapes a kind is made of.
pub const Sink = struct {
    out: []Shape,
    n: usize = 0,
    /// How many did not fit. A kind that fills its sink says so in a test, not at play.
    lost: usize = 0,

    pub fn add(self: *Sink, shape: Shape) void {
        if (self.n >= self.out.len) {
            self.lost += 1;
            return;
        }
        self.out[self.n] = shape;
        self.n += 1;
    }

    pub fn stalk(self: *Sink, a: V3, b: V3, ra: f32, rb: f32) void {
        self.add(.{ .stalk = .{ .a = a, .b = b, .ra = ra, .rb = rb } });
    }

    pub fn ball(self: *Sink, at: V3, r: f32) void {
        self.add(.{ .ball = .{ .at = at, .r = r } });
    }

    pub fn plate(self: *Sink, corners: []const V3, thick: f32) void {
        var p = Plate{ .thick = thick };
        for (corners) |c| {
            if (p.n >= Plate.most) break;
            p.corners[p.n] = c;
            p.n += 1;
        }
        self.add(.{ .plate = p });
    }

    /// A flat round thing, as a plate of eight corners.
    pub fn disc(self: *Sink, at: V3, r: f32, thick: f32) void {
        var corners: [Plate.most]V3 = undefined;
        for (&corners, 0..) |*c, k| {
            const a = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, Plate.most));
            c.* = .{ at[0] + r * @cos(a), at[1], at[2] + r * @sin(a) };
        }
        self.plate(&corners, thick);
    }

    pub fn slice(self: *const Sink) []const Shape {
        return self.out[0..self.n];
    }
};

pub fn add(a: V3, b: V3) V3 {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

pub fn sub(a: V3, b: V3) V3 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}

pub fn scale(a: V3, s: f32) V3 {
    return .{ a[0] * s, a[1] * s, a[2] * s };
}

pub fn dot(a: V3, b: V3) f32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

pub fn cross(a: V3, b: V3) V3 {
    return .{ a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] };
}

pub fn length(a: V3) f32 {
    return @sqrt(dot(a, a));
}

/// The same way, one metre long; a point with no length stays where it is.
pub fn unit(a: V3) V3 {
    const len = length(a);
    return if (len > 1e-6) scale(a, 1.0 / len) else a;
}

/// Part of the way from one point to another.
pub fn between(a: V3, b: V3, t: f32) V3 {
    return .{ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };
}

/// Two ways across a line, each a metre long and square to it and to each other. Whatever goes
/// round a stalk goes round by these, so its solid, its black shape and its lines turn together.
pub fn across(axis: V3) [2]V3 {
    const along = unit(axis);
    // start from whichever of up and east the line is less along
    const start: V3 = if (@abs(along[1]) < 0.9) .{ 0.0, 1.0, 0.0 } else .{ 1.0, 0.0, 0.0 };
    const u = unit(cross(along, start));
    const v = cross(along, u);
    return .{ u, v };
}

const expectApprox = std.testing.expectApproxEqAbs;
const expectEqual = std.testing.expectEqual;

test "two ways across a line are square to it and to each other" {
    for ([_]V3{ .{ 0.0, 1.0, 0.0 }, .{ 1.0, 0.0, 0.0 }, .{ 0.3, 0.9, -0.2 }, .{ 0.0, 0.0, 5.0 } }) |axis| {
        const uv = across(axis);
        try expectApprox(@as(f32, 0.0), dot(uv[0], unit(axis)), 1e-5);
        try expectApprox(@as(f32, 0.0), dot(uv[1], unit(axis)), 1e-5);
        try expectApprox(@as(f32, 0.0), dot(uv[0], uv[1]), 1e-5);
        try expectApprox(@as(f32, 1.0), length(uv[0]), 1e-5);
        try expectApprox(@as(f32, 1.0), length(uv[1]), 1e-5);
    }
}

test "a stalk's edges run along its skin, one to a side" {
    const s = Stalk{ .a = .{ 1.0, 0.0, 2.0 }, .b = .{ 1.0, 10.0, 2.0 }, .ra = 1.0, .rb = 0.5 };
    try expectEqual(@as(usize, 6), s.sides());
    try expectEqual(@as(usize, 3), (Stalk{ .a = s.a, .b = s.b, .ra = 0.2, .rb = 0.1 }).sides());
    try expectEqual(@as(usize, 8), (Stalk{ .a = s.a, .b = s.b, .ra = 2.0, .rb = 2.0 }).sides());
    for (0..s.sides()) |k| {
        const e = s.edge(k);
        try expectApprox(@as(f32, 1.0), length(sub(e[0], s.a)), 1e-4);
        try expectApprox(@as(f32, 0.5), length(sub(e[1], s.b)), 1e-4);
    }
}

test "a sink keeps what fits and counts what does not" {
    var room: [2]Shape = undefined;
    var sink = Sink{ .out = &room };
    sink.ball(.{ 0.0, 1.0, 0.0 }, 0.5);
    sink.stalk(.{ 0.0, 0.0, 0.0 }, .{ 0.0, 4.0, 0.0 }, 0.5, 0.2);
    sink.disc(.{ 0.0, 2.0, 0.0 }, 1.0, 0.1);
    try expectEqual(@as(usize, 2), sink.n);
    try expectEqual(@as(usize, 1), sink.lost);
}

test "a disc is a plate of eight corners round its middle" {
    var room: [1]Shape = undefined;
    var sink = Sink{ .out = &room };
    sink.disc(.{ 3.0, 2.0, -1.0 }, 1.5, 0.1);
    const p = sink.out[0].plate;
    try expectEqual(@as(u8, 8), p.n);
    const m = p.middle();
    try expectApprox(@as(f32, 3.0), m[0], 1e-4);
    try expectApprox(@as(f32, 2.0), m[1], 1e-4);
    try expectApprox(@as(f32, -1.0), m[2], 1e-4);
}
