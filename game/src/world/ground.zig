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

/// What is underfoot: water where a puddle is, and the ground's cover everywhere else.
pub fn underfootAt(x: f32, z: f32) Cover {
    return if (wet(x, z)) .water else coverAt(x, z);
}
