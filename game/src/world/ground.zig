//! What the ground wears (spec/shape.md): the Garden's covers, in wide patches, by a sum from
//! where a place is. The world reads it to know what is under Hum's feet, and the picture reads
//! the same sum to draw it, so what is seen and what is felt can't disagree. No platform.

/// The Garden's covers. Each does something to Hum by a law (spec/shape.md, the Garden).
pub const Cover = enum { soil, lawn, leaves, clover, moss, water };

pub fn hash32(a: i32, b: i32, k: u32) u32 {
    var s: u32 = @as(u32, @bitCast(a)) *% 0x9e3779b1 ^ @as(u32, @bitCast(b)) *% 0x85ebca6b ^ (k +% 1) *% 0xc2b2ae35;
    s ^= s >> 15;
    s *%= 0x2c1b3c6d;
    s ^= s >> 12;
    s *%= 0x297a2d39;
    s ^= s >> 15;
    return s;
}

pub fn unit01(s: u32) f32 {
    return @as(f32, @floatFromInt(s >> 8)) * (1.0 / 16777216.0);
}

/// The map's own number, chosen so that the first evening's walk crosses lawn, fallen leaves,
/// clover and moss.
const salt: u32 = 1975;

/// Which cover is at a place: wide patches, a hundred metres or so across. The five bands each
/// take about a fifth of the ground.
pub fn coverAt(x: f32, z: f32) Cover {
    const fx = x * (1.0 / 105.0);
    const fz = z * (1.0 / 105.0);
    const ix: i32 = @intFromFloat(@floor(fx));
    const iz: i32 = @intFromFloat(@floor(fz));
    const tx = fx - @floor(fx);
    const tz = fz - @floor(fz);
    const sx = tx * tx * (3.0 - 2.0 * tx);
    const sz = tz * tz * (3.0 - 2.0 * tz);
    const a = unit01(hash32(ix, iz, salt));
    const b = unit01(hash32(ix + 1, iz, salt));
    const c = unit01(hash32(ix, iz + 1, salt));
    const d = unit01(hash32(ix + 1, iz + 1, salt));
    const v = (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sz;
    return if (v < 0.307) .soil else if (v < 0.461) .lawn else if (v < 0.602) .leaves else if (v < 0.724) .clover else .moss;
}

/// The pure garden's five-note scale, for things that are tuned to it: dew, and fallen leaves.
pub const five = [5]f32{ 1.0, 9.0 / 8.0, 5.0 / 4.0, 3.0 / 2.0, 5.0 / 3.0 };

/// A fallen leaf is a bar with its own note: one leaf to every six metres square of leaf fall.
pub fn leafNote(x: f32, z: f32) usize {
    return hash32(@intFromFloat(@floor(x / 6.0)), @intFromFloat(@floor(z / 6.0)), 23) % 5;
}

const pools = @import("pools.zig");
const world = @import("world.zig");
const std = @import("std");

/// Whether a place is under a puddle's water (pools.zig): nothing grows there, and nothing lies
/// there but what floats.
pub fn wet(x: f32, z: f32) bool {
    // the Mirror Pool
    const mx = x - world.land.pool[0];
    const mz = z - world.land.pool[1];
    if (mx * mx + mz * mz < world.land.pool[2] * world.land.pool[2]) return true;
    inline for (pools.garden) |p| {
        const r = comptime pools.radiusFor(p.shape, world.garden_hz * p.note);
        const dx = x - p.x;
        const dz = z - p.z;
        if (dx * dx + dz * dz < r * r) return true;
    }
    return false;
}

fn smooth01(t: f32) f32 {
    const c = std.math.clamp(t, 0.0, 1.0);
    return c * c * (3.0 - 2.0 * c);
}

/// The bowl's own ground, before the puddles level it (spec/shape.md, "The Garden: a bowl"): the
/// Mirror Pool's still water at nought, the lowest point; from its shore the ground rises gently,
/// eased at both ends, to the rim; behind the rim's wall the raised beds stand higher; and the
/// spigot's rise at the back is the highest ground of all. Only sums and a square root: the same
/// on every machine.
pub fn bowlAt(x: f32, z: f32) f32 {
    const L = world.land;
    const dx = x - L.pool[0];
    const dz = z - L.pool[1];
    const r = @sqrt(dx * dx + dz * dz);
    var h: f32 = if (r < L.pool[2]) 0.0 else if (r < L.rim[2]) L.bowl_depth * smooth01((r - L.pool[2]) / (L.rim[2] - L.pool[2])) else L.bowl_depth + L.bowl_beds;
    const sx = x - L.rise[0];
    const sz = z - L.rise[1];
    const d = @sqrt(sx * sx + sz * sz);
    if (d < L.rise[3]) {
        const q = 1.0 - (d / L.rise[3]) * (d / L.rise[3]);
        h += L.rise[2] * q * q;
    }
    return h;
}

/// How far round a puddle the ground eases from the slope to the water's level.
pub const pad_blend: f32 = 30.0;

/// Each puddle's place, radius and level (the bowl's height at its middle): water lies flat.
pub const pads: [pools.garden.len][4]f32 = blk: {
    @setEvalBranchQuota(100_000);
    var out: [pools.garden.len][4]f32 = undefined;
    for (pools.garden, 0..) |p, i| out[i] = .{ p.x, p.z, pools.radiusFor(p.shape, world.garden_hz * p.note), bowlAt(p.x, p.z) };
    break :blk out;
};

/// The ground's height: the bowl's, levelled under each puddle.
pub fn heightAt(x: f32, z: f32) f32 {
    var h = bowlAt(x, z);
    for (pads) |pad| {
        const dx = x - pad[0];
        const dz = z - pad[1];
        const k = 1.0 - smooth01((@sqrt(dx * dx + dz * dz) - pad[2]) / pad_blend);
        h += (pad[3] - h) * k;
    }
    return h;
}

/// What is underfoot: water where a puddle is, and the ground's cover everywhere else.
pub fn underfootAt(x: f32, z: f32) Cover {
    return if (wet(x, z)) .water else coverAt(x, z);
}
