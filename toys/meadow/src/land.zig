//! The place: a patch of meadow seen from the height of a seed. Ground shape, ground colour,
//! where grass grows, and the things standing in it. One unit is the creature's own height.
//! No platform code; everything is a pure function of position and a seed.
const std = @import("std");
const math = @import("math.zig");
const noise = @import("noise.zig");
const Vec3 = math.Vec3;

/// The meadow is a square this many units on a side.
pub const size: f32 = 320.0;
/// The player is kept this far inside the edge, where the ground starts to rise into the rim.
pub const margin: f32 = 34.0;

pub const pond = struct {
    pub const x: f32 = 112.0;
    pub const z: f32 = 198.0;
    pub const radius: f32 = 36.0;
};

pub const tree = struct {
    pub const x: f32 = 236.0;
    pub const z: f32 = 100.0;
    pub const radius: f32 = 22.0;
    pub const height: f32 = 420.0;
    /// How far the flared foot of the trunk reaches at ground level.
    pub const foot: f32 = 44.0;
};

/// The trunk's radius at a height above its base: wide at the foot, straight above.
pub fn trunkRadius(above_base: f32) f32 {
    return tree.radius * (1.0 + 0.9 * @exp(-@max(above_base, 0.0) / 14.0));
}

fn distance(x: f32, z: f32, cx: f32, cz: f32) f32 {
    const dx = x - cx;
    const dz = z - cz;
    return @sqrt(dx * dx + dz * dz);
}

/// How far (x, z) is from the worn path that winds from the pond toward the tree.
pub fn pathDistance(x: f32, z: f32) f32 {
    // the path is the zero line of a slowly bending field; wobble keeps it from looking drawn
    const along = (x - pond.x) * 0.62 + (z - pond.z) * -0.78; // distance along the pond-tree line
    const across = (x - pond.x) * 0.78 + (z - pond.z) * 0.62;
    const bend = 26.0 * @sin(along * 0.021) + 9.0 * noise.value(along * 0.03, 3.7, 41);
    const d = @abs(across - bend);
    // the path only exists between the pond's shore and the roots
    const before = math.smoothstep(pond.radius * 0.6, pond.radius * 1.2, along);
    const after = 1.0 - math.smoothstep(150.0, 185.0, along);
    return d + (1.0 - before * after) * 60.0;
}

/// Height of the bare ground at (x, z).
pub fn groundHeight(x: f32, z: f32) f32 {
    var h = 6.5 * noise.fbm(x / 105.0, z / 105.0, 3, 11) + 1.2 * noise.fbm(x / 19.0, z / 19.0, 2, 23);
    // the pond sits in a bowl
    const to_pond = distance(x, z, pond.x, pond.z) / pond.radius;
    h -= 6.0 * (1.0 - math.smoothstep(0.15, 1.35, to_pond));
    // the ground swells toward the trunk, where the roots are
    const to_tree = distance(x, z, tree.x, tree.z);
    h += 11.0 * (1.0 - math.smoothstep(tree.foot * 0.5, tree.foot * 1.9, to_tree));
    // the meadow's rim rises on every side, so the world has no visible edge
    const half = size * 0.5;
    const edge = @max(@abs(x - half), @abs(z - half)) / half;
    const rim = math.smoothstep(0.80, 1.0, edge);
    h += 34.0 * rim * rim;
    // the path is trodden slightly lower than what grows beside it
    h -= 0.5 * (1.0 - math.smoothstep(2.0, 7.0, pathDistance(x, z)));
    return h;
}

/// Height of the pond's surface.
pub fn waterLevel() f32 {
    return groundHeight(pond.x, pond.z) + 2.6;
}

/// The ground's upward direction at (x, z).
pub fn groundNormal(x: f32, z: f32) Vec3 {
    const e = 0.6;
    const dx = groundHeight(x + e, z) - groundHeight(x - e, z);
    const dz = groundHeight(x, z + e) - groundHeight(x, z - e);
    return Vec3.init(-dx, 2.0 * e, -dz).normalize();
}

/// How thickly grass grows at (x, z): 0 none, 1 a full stand.
pub fn grassDensity(x: f32, z: f32) f32 {
    var d = 0.55 + 0.75 * noise.fbm(x / 46.0, z / 46.0, 2, 57);
    d = math.clamp01(d * 1.3);
    // nothing grows in the water, on the path, or in the dry shade against the trunk
    const shore = groundHeight(x, z) - waterLevel();
    d *= math.smoothstep(0.1, 1.6, shore);
    d *= math.smoothstep(2.5, 8.0, pathDistance(x, z));
    d *= math.smoothstep(tree.foot * 1.05, tree.foot * 1.5, distance(x, z, tree.x, tree.z));
    return d;
}

/// The colour of the ground itself at (x, z), before light. Everything that grows takes the
/// colour of its roots from here, so the meadow reads as one painting.
pub fn groundColor(x: f32, z: f32) [3]f32 {
    const soil = [3]f32{ 0.36, 0.27, 0.17 };
    const sward = [3]f32{ 0.20, 0.36, 0.11 };
    const moss = [3]f32{ 0.27, 0.40, 0.14 };
    const sand = [3]f32{ 0.58, 0.52, 0.36 };
    const mud = [3]f32{ 0.21, 0.17, 0.12 };
    const litter = [3]f32{ 0.33, 0.24, 0.15 };

    const mix3 = struct {
        fn f(a: [3]f32, b: [3]f32, t: f32) [3]f32 {
            return .{ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };
        }
    }.f;

    const grass = grassDensity(x, z);
    const patch = noise.fbm(x / 31.0, z / 31.0, 2, 83) * 0.5 + 0.5;
    var color = mix3(soil, mix3(sward, moss, patch), math.smoothstep(0.05, 0.6, grass));
    // wet near the water: sand at the shoreline, mud under it
    const shore = groundHeight(x, z) - waterLevel();
    color = mix3(color, sand, (1.0 - math.smoothstep(0.3, 2.6, @abs(shore - 0.6))) * 0.85);
    color = mix3(color, mud, 1.0 - math.smoothstep(-2.0, 0.2, shore));
    // leaf litter in the shade of the trunk
    const to_tree = distance(x, z, tree.x, tree.z);
    color = mix3(color, litter, (1.0 - math.smoothstep(tree.foot * 0.9, tree.foot * 1.8, to_tree)) * 0.8);
    // a little uneven everywhere, like a wash laid by hand
    const mottle = 0.90 + 0.20 * (noise.fbm(x / 7.0, z / 7.0, 2, 131) * 0.5 + 0.5);
    return .{ color[0] * mottle, color[1] * mottle, color[2] * mottle };
}

pub const Stone = struct {
    x: f32,
    z: f32,
    /// Centre height; the stone sits partly in the ground.
    y: f32,
    radius: f32,
    /// Height as a fraction of width.
    squash: f32,
    seed: u32,
};

pub const PlantKind = enum(u8) { clover, aster, verbena, snowberry, buttercup, mushroom };

pub const Plant = struct {
    kind: PlantKind,
    x: f32,
    z: f32,
    /// Stem height in units.
    height: f32,
    /// Width of the head, leaf or cap.
    spread: f32,
    seed: u32,
};

pub const max_stones = 64;
pub const max_plants = 320;

pub const Things = struct {
    stones: [max_stones]Stone = undefined,
    stone_count: usize = 0,
    plants: [max_plants]Plant = undefined,
    plant_count: usize = 0,

    pub fn generate(seed: u32) Things {
        var self = Things{};
        var rng = noise.Rng.init(seed);

        // stones: many pebbles, a few boulders
        var tries: u32 = 0;
        while (self.stone_count < 46 and tries < 4000) : (tries += 1) {
            const x = rng.range(margin, size - margin);
            const z = rng.range(margin, size - margin);
            const big = rng.unit() < 0.16;
            const radius = if (big) rng.range(5.5, 10.5) else rng.range(1.2, 3.8);
            if (distance(x, z, pond.x, pond.z) < pond.radius * 0.8) continue;
            if (distance(x, z, tree.x, tree.z) < tree.foot + 2.0 + radius) continue;
            if (pathDistance(x, z) < radius + 1.5) continue;
            if (self.tooCloseToStone(x, z, radius * 1.3)) continue;
            const squash = rng.range(0.55, 0.85);
            self.stones[self.stone_count] = .{
                .x = x,
                .z = z,
                .y = groundHeight(x, z) + radius * squash * 0.35,
                .radius = radius,
                .squash = squash,
                .seed = rng.next(),
            };
            self.stone_count += 1;
        }

        // plants: clover in patches, flowers scattered through the grass, mushrooms in shade
        tries = 0;
        while (self.plant_count < max_plants - 40 and tries < 20000) : (tries += 1) {
            const x = rng.range(margin * 0.8, size - margin * 0.8);
            const z = rng.range(margin * 0.8, size - margin * 0.8);
            if (groundHeight(x, z) - waterLevel() < 0.8) continue;
            if (distance(x, z, tree.x, tree.z) < tree.foot + 2.0) continue;
            if (self.tooCloseToStone(x, z, 0.6)) continue;
            const clover_ground = noise.fbm(x / 24.0, z / 24.0, 2, 211);
            const pick = rng.unit();
            var plant = Plant{ .kind = .clover, .x = x, .z = z, .height = 0.0, .spread = 0.0, .seed = rng.next() };
            if (clover_ground > 0.12 and pick < 0.75) {
                plant.kind = .clover;
                plant.height = rng.range(2.6, 6.5);
                plant.spread = rng.range(2.2, 3.8);
            } else if (pick < 0.84 and grassDensity(x, z) > 0.3) {
                plant.kind = switch (rng.next() % 4) {
                    0 => .aster,
                    1 => .verbena,
                    2 => .snowberry,
                    else => .buttercup,
                };
                plant.height = rng.range(9.0, 19.0);
                plant.spread = rng.range(2.4, 4.2);
            } else continue;
            self.plants[self.plant_count] = plant;
            self.plant_count += 1;
        }
        tries = 0;
        var mushrooms: u32 = 0;
        while (mushrooms < 16 and self.plant_count < max_plants and tries < 4000) : (tries += 1) {
            const angle = rng.range(0.0, 2.0 * std.math.pi);
            const reach = rng.range(tree.foot + 5.0, tree.foot * 2.3);
            // most ring the trunk; a few stand along the path as stepping stones
            var x = tree.x + @cos(angle) * reach;
            var z = tree.z + @sin(angle) * reach;
            if (mushrooms % 4 == 3) {
                x = rng.range(margin, size - margin);
                z = rng.range(margin, size - margin);
                if (pathDistance(x, z) > 9.0 or pathDistance(x, z) < 3.0) continue;
            }
            if (x < margin or z < margin or x > size - margin or z > size - margin) continue;
            if (self.tooCloseToStone(x, z, 3.0)) continue;
            self.plants[self.plant_count] = .{
                .kind = .mushroom,
                .x = x,
                .z = z,
                .height = rng.range(2.4, 5.2),
                .spread = rng.range(3.0, 5.6),
                .seed = rng.next(),
            };
            self.plant_count += 1;
            mushrooms += 1;
        }
        return self;
    }

    fn tooCloseToStone(self: *const Things, x: f32, z: f32, clearance: f32) bool {
        for (self.stones[0..self.stone_count]) |stone| {
            if (distance(x, z, stone.x, stone.z) < stone.radius + clearance) return true;
        }
        return false;
    }

    /// Height of whatever can be stood on at (x, z): the ground, or the top of a stone.
    pub fn standingHeight(self: *const Things, x: f32, z: f32) f32 {
        var h = groundHeight(x, z);
        for (self.stones[0..self.stone_count]) |stone| {
            const dx = x - stone.x;
            const dz = z - stone.z;
            const d2 = dx * dx + dz * dz;
            const r2 = stone.radius * stone.radius;
            if (d2 >= r2) continue;
            const top = stone.y + @sqrt(r2 - d2) * stone.squash;
            h = @max(h, top);
        }
        return h;
    }

    /// The mushroom whose cap is under (x, z), if any: caps are springboards.
    pub fn mushroomAt(self: *const Things, x: f32, z: f32) ?usize {
        for (self.plants[0..self.plant_count], 0..) |plant, i| {
            if (plant.kind != .mushroom) continue;
            if (distance(x, z, plant.x, plant.z) < plant.spread * 0.92) return i;
        }
        return null;
    }

    /// Height of a mushroom's cap top above the world origin.
    pub fn capHeight(plant: Plant) f32 {
        return groundHeight(plant.x, plant.z) + plant.height + plant.spread * 0.28;
    }
};

test "the ground is continuous and the pond is the low place" {
    var x: f32 = margin;
    while (x < size - margin) : (x += 3.1) {
        const a = groundHeight(x, 150.0);
        const b = groundHeight(x + 0.05, 150.0);
        try std.testing.expect(@abs(a - b) < 0.2);
    }
    try std.testing.expect(groundHeight(pond.x, pond.z) < waterLevel());
    try std.testing.expect(groundHeight(pond.x + pond.radius * 1.6, pond.z) > waterLevel());
    try std.testing.expect(grassDensity(pond.x, pond.z) == 0.0);
}

test "things are placed the same way every time and stand on the ground" {
    const a = Things.generate(1);
    const b = Things.generate(1);
    try std.testing.expectEqual(a.stone_count, b.stone_count);
    try std.testing.expectEqual(a.plant_count, b.plant_count);
    try std.testing.expect(a.stone_count > 30);
    try std.testing.expect(a.plant_count > 150);
    for (a.stones[0..a.stone_count], b.stones[0..b.stone_count]) |sa, sb| {
        try std.testing.expectEqual(sa.x, sb.x);
        // standing on the middle of a stone is higher than the ground under it
        try std.testing.expect(a.standingHeight(sa.x, sa.z) > groundHeight(sa.x, sa.z));
    }
    var mushrooms: usize = 0;
    for (a.plants[0..a.plant_count]) |plant| {
        if (plant.kind == .mushroom) mushrooms += 1;
    }
    try std.testing.expect(mushrooms >= 10);
}
