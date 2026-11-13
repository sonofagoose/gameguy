//! Repeatable randomness: integer hashes, smooth value noise, and a few layers of it summed.
//! Everything is a pure function of its inputs, so the meadow is the same on every machine.
const std = @import("std");

pub fn hash(x: i32, y: i32, seed: u32) u32 {
    var h: u32 = @as(u32, @bitCast(x)) *% 0x27d4eb2d +% @as(u32, @bitCast(y)) *% 0x165667b1 +% seed *% 0x9e3779b9;
    h ^= h >> 15;
    h *%= 0x85ebca6b;
    h ^= h >> 13;
    h *%= 0xc2b2ae35;
    h ^= h >> 16;
    return h;
}

/// A value in [0, 1) for a lattice point.
pub fn cell(x: i32, y: i32, seed: u32) f32 {
    return @as(f32, @floatFromInt(hash(x, y, seed) >> 8)) / 16777216.0;
}

/// Smooth noise in [-1, 1]; features are about one unit across.
pub fn value(x: f32, y: f32, seed: u32) f32 {
    const fx = @floor(x);
    const fy = @floor(y);
    const ix: i32 = @intFromFloat(fx);
    const iy: i32 = @intFromFloat(fy);
    const tx = x - fx;
    const ty = y - fy;
    const sx = tx * tx * (3.0 - 2.0 * tx);
    const sy = ty * ty * (3.0 - 2.0 * ty);
    const a = cell(ix, iy, seed);
    const b = cell(ix + 1, iy, seed);
    const c = cell(ix, iy + 1, seed);
    const d = cell(ix + 1, iy + 1, seed);
    const top = a + (b - a) * sx;
    const bottom = c + (d - c) * sx;
    return (top + (bottom - top) * sy) * 2.0 - 1.0;
}

/// `octaves` layers of value noise, each twice as fine and half as strong. Roughly [-1, 1].
pub fn fbm(x: f32, y: f32, octaves: u32, seed: u32) f32 {
    var sum: f32 = 0.0;
    var amplitude: f32 = 0.5;
    var frequency: f32 = 1.0;
    var total: f32 = 0.0;
    var i: u32 = 0;
    while (i < octaves) : (i += 1) {
        sum += amplitude * value(x * frequency, y * frequency, seed +% i *% 101);
        total += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return sum / total;
}

/// A small deterministic generator for placing things.
pub const Rng = struct {
    state: u32,

    pub fn init(seed: u32) Rng {
        return .{ .state = seed *% 747796405 +% 2891336453 };
    }
    pub fn next(self: *Rng) u32 {
        self.state = self.state *% 747796405 +% 2891336453;
        var word = ((self.state >> @intCast((self.state >> 28) + 4)) ^ self.state) *% 277803737;
        word ^= word >> 22;
        return word;
    }
    /// A float in [0, 1).
    pub fn unit(self: *Rng) f32 {
        return @as(f32, @floatFromInt(self.next() >> 8)) / 16777216.0;
    }
    pub fn range(self: *Rng, lo: f32, hi: f32) f32 {
        return lo + (hi - lo) * self.unit();
    }
};

test "noise is repeatable, bounded and continuous" {
    try std.testing.expectEqual(value(3.7, -2.2, 5), value(3.7, -2.2, 5));
    var x: f32 = -20.0;
    while (x < 20.0) : (x += 0.37) {
        const v = fbm(x, x * 0.61, 4, 9);
        try std.testing.expect(v >= -1.0 and v <= 1.0);
        try std.testing.expect(@abs(value(x + 0.001, 1.5, 3) - value(x, 1.5, 3)) < 0.01);
    }
}

test "the generator spreads its values" {
    var rng = Rng.init(7);
    var low: u32 = 0;
    for (0..1000) |_| {
        if (rng.unit() < 0.5) low += 1;
    }
    try std.testing.expect(low > 420 and low < 580);
}
