//! Asters, one to a hundred (spec/size.md): a real New England aster is 0.9 to 1.85 m, so here
//! one stands 90 to 185 m, as tall as the tallest churches ever built. A stalk a metre through,
//! leaves five to ten metres long leaving it in a spiral all the way up, and a crown of branches
//! hung with flower heads, each a bell wider than Hum is tall.
//!
//! This is the plan of one aster and of a proof field of them, made by rule from a number. The
//! world makes its things from the plan and the picture makes its lines from the same plan, so
//! what sounds and what shows can't disagree. No platform, and only sums every machine agrees on.
//!
//! The Garden's own asters will come from its score (stage 2). This field is a proof piece.
const std = @import("std");
const pools = @import("pools.zig");

pub const segments = 12;
pub const max_leaves = 56;
pub const max_branches = 9;
pub const max_bells = 36;
pub const max_towers = 80;

/// The notes of the pure garden, as ratios above its own note (spec/laws.md, tuning).
pub const scale = [7]f32{ 1.0, 9.0 / 8.0, 5.0 / 4.0, 4.0 / 3.0, 3.0 / 2.0, 5.0 / 3.0, 15.0 / 8.0 };

pub const Leaf = struct {
    h: f32 = 0.0,
    angle: f32 = 0.0,
    len: f32 = 0.0,
    droop: f32 = 0.0,
};

pub const Branch = struct {
    h: f32 = 0.0,
    angle: f32 = 0.0,
    len: f32 = 0.0,
    /// How steeply it rises, in radians above level.
    rise: f32 = 0.0,
};

pub const Bell = struct {
    pos: [3]f32 = .{ 0.0, 0.0, 0.0 },
    /// Half its width. Real flower heads are 2.6 to 4.4 cm across.
    r: f32 = 0.0,
    hz: f32 = 0.0,
    /// The way its branch points, level: which way the flower faces.
    angle: f32 = 0.0,
};

pub const Plan = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    tall: f32 = 0.0,
    /// How far the top has bowed from over the foot.
    bow_x: f32 = 0.0,
    bow_z: f32 = 0.0,
    /// Which note of the garden's scale this aster is.
    degree: u8 = 0,
    leaf_n: u32 = 0,
    leaves: [max_leaves]Leaf = @splat(.{}),
    branch_n: u32 = 0,
    branches: [max_branches]Branch = @splat(.{}),
    bell_n: u32 = 0,
    bells: [max_bells]Bell = @splat(.{}),

    /// Where the middle of the stalk is at height `h`.
    pub fn mast(self: *const Plan, h: f32) [3]f32 {
        const t = h / self.tall;
        return .{ self.x + self.bow_x * t * t, h, self.z + self.bow_z * t * t };
    }
};

const Rand = struct {
    s: u32,

    fn next(self: *Rand) u32 {
        self.s ^= self.s << 13;
        self.s ^= self.s >> 17;
        self.s ^= self.s << 5;
        return self.s;
    }

    /// From nought up to one.
    fn unit(self: *Rand) f32 {
        return @as(f32, @floatFromInt(self.next() >> 8)) * (1.0 / 16777216.0);
    }
};

const golden_angle: f32 = 2.39996323;

/// One aster, from its number, its foot and its height.
pub fn plan(index: u32, x: f32, z: f32, tall: f32, home_hz: f32) Plan {
    var p = Plan{ .x = x, .z = z, .tall = tall };
    var rnd = Rand{ .s = 0x9e3779b9 ^ ((index + 1) *% 2654435761) };
    _ = rnd.next();
    const bow = tall * (0.015 + 0.035 * rnd.unit());
    const bow_angle = rnd.unit() * 6.2831853;
    p.bow_x = bow * @cos(bow_angle);
    p.bow_z = bow * @sin(bow_angle);
    p.degree = if (index == 0) 0 else @intCast(index % 7);

    // leaves: bare for the first nine metres, then one every two and a half, in a spiral
    const crown_from = tall * 0.74;
    const leaf_phase = rnd.unit() * 6.2831853;
    var h: f32 = 9.0;
    while (h < crown_from and p.leaf_n < max_leaves) : (h += 2.3 + (crown_from - 9.0) / @as(f32, max_leaves) * 0.5) {
        const t = h / tall;
        p.leaves[p.leaf_n] = .{
            .h = h,
            .angle = leaf_phase + @as(f32, @floatFromInt(p.leaf_n)) * golden_angle,
            .len = (5.0 + 5.0 * rnd.unit()) * (1.0 - 0.35 * t),
            .droop = 0.10 + 0.22 * rnd.unit(),
        };
        p.leaf_n += 1;
    }

    // the crown: branches from three quarters of the way up, the lower ones longer
    p.branch_n = 5 + rnd.next() % 5;
    const branch_phase = rnd.unit() * 6.2831853;
    for (0..p.branch_n) |k| {
        const f = @as(f32, @floatFromInt(k)) / @as(f32, @floatFromInt(p.branch_n));
        p.branches[k] = .{
            .h = crown_from + (tall * 0.97 - crown_from) * f,
            .angle = branch_phase + @as(f32, @floatFromInt(k)) * golden_angle,
            .len = (13.0 + 15.0 * rnd.unit()) * (1.0 - 0.45 * f),
            .rise = 0.50 + 0.30 * rnd.unit(),
        };
    }

    // the bells: two to five on each branch, and one at the very top
    const triad = [3]f32{ scale[p.degree], scale[(p.degree + 4) % 7], scale[(p.degree + 2) % 7] };
    for (0..p.branch_n) |k| {
        const b = p.branches[k];
        const on_this: u32 = 2 + rnd.next() % 4;
        const base = p.mast(b.h);
        const cr = @cos(b.rise);
        const dir = [3]f32{ @cos(b.angle) * cr, @sin(b.rise), @sin(b.angle) * cr };
        for (0..on_this) |j| {
            if (p.bell_n >= max_bells - 1) break;
            const along = b.len * (0.45 + 0.55 * @as(f32, @floatFromInt(j + 1)) / @as(f32, @floatFromInt(on_this)));
            const r = 1.3 + 0.9 * rnd.unit();
            p.bells[p.bell_n] = .{
                .pos = .{ base[0] + dir[0] * along, base[1] + dir[1] * along, base[2] + dir[2] * along },
                .r = r,
                .hz = note(home_hz, triad, r, rnd.unit()),
                .angle = b.angle,
            };
            p.bell_n += 1;
        }
    }
    const top = p.mast(tall);
    p.bells[p.bell_n] = .{ .pos = .{ top[0], top[1] + 1.2, top[2] }, .r = 2.2, .hz = home_hz * triad[0] * 0.5, .angle = bow_angle };
    p.bell_n += 1;
    return p;
}

/// A bell's note: mostly the aster's own, sometimes its fifth or its third; the wider the lower.
fn note(home_hz: f32, triad: [3]f32, r: f32, pick: f32) f32 {
    const ratio = if (pick < 0.55) triad[0] else if (pick < 0.80) triad[1] else triad[2];
    const octave: f32 = if (r >= 1.9) 0.5 else if (r >= 1.55) 1.0 else 2.0;
    return home_hz * ratio * octave;
}

// where they stand comes from the Garden's score (scores/garden.txt, through tools/score.py)
const land = @import("land.zig");
pub const great_tall: f32 = land.great_tall;
pub const great_x: f32 = land.great[0];
pub const great_z: f32 = land.great[1];
pub const field_across: f32 = land.aster_rule.across;
/// A place in the field that is kept clear of asters: where Drip waits in the dark.
pub const clear_x: f32 = land.clear[0];
pub const clear_z: f32 = land.clear[1];

/// The proof field: the great aster a hundred and fifty metres ahead of where Hum stands, and
/// the rest on a loose grid over a field more than a kilometre across. The return is how many.
pub fn field(out: *[max_towers]Plan, home_hz: f32) usize {
    out[0] = plan(0, great_x, great_z, great_tall, home_hz);
    var n: usize = 1;
    const rule = land.aster_rule;
    var rnd = Rand{ .s = rule.seed };
    const cells = rule.cells;
    const cell = field_across / @as(f32, @floatFromInt(cells));
    for (0..cells) |iz| {
        for (0..cells) |ix| {
            const cx = -field_across * 0.5 + (@as(f32, @floatFromInt(ix)) + 0.5) * cell;
            const cz = rule.from - (@as(f32, @floatFromInt(iz)) + 0.5) * cell;
            const x = cx + (rnd.unit() - 0.5) * rule.jitter;
            const z = cz + (rnd.unit() - 0.5) * rule.jitter;
            const tall = rule.tall_least + rule.tall_more * rnd.unit();
            const skip = rnd.next() % rule.skip == 0;
            // nothing on top of where Hum stands, or on the great aster
            const wx = x - land.wake[0];
            const wz = z - land.wake[1];
            const near_start = wx * wx + wz * wz < land.keep_wake * land.keep_wake;
            const gx = x - great_x;
            const gz = z - great_z;
            const near_great = gx * gx + gz * gz < land.keep_great * land.keep_great;
            const dx = x - clear_x;
            const dz = z - clear_z;
            const near_clear = dx * dx + dz * dz < land.keep_clear * land.keep_clear;
            // and nothing standing in a puddle, nor so near one that it leans over the water
            var in_water = false;
            for (pools.garden) |pd| {
                const px = x - pd.x;
                const pz = z - pd.z;
                const keep = pools.radiusFor(pd.shape, home_hz) + land.keep_puddle;
                if (px * px + pz * pz < keep * keep) in_water = true;
            }
            if (skip or near_start or near_great or near_clear or in_water or n >= max_towers) continue;
            out[n] = plan(@intCast(n), x, z, tall, home_hz);
            n += 1;
        }
    }
    return n;
}

test "asters stand as tall as cathedrals, one to a hundred" {
    const plans = try std.testing.allocator.create([max_towers]Plan);
    defer std.testing.allocator.destroy(plans);
    const n = field(plans, 261.63);
    try std.testing.expect(n >= 60);
    var tallest: f32 = 0.0;
    var shortest: f32 = 1e9;
    for (plans[0..n]) |p| {
        tallest = @max(tallest, p.tall);
        shortest = @min(shortest, p.tall);
        // a real aster is 0.9 to 1.85 m (to about 2 m), and the world is one to a hundred
        try std.testing.expect(p.tall >= 90.0 and p.tall <= 200.0);
        try std.testing.expect(p.bell_n >= 11 and p.leaf_n >= 20);
        for (p.bells[0..p.bell_n]) |bell| {
            // every bell is wider than Hum is tall, and hangs in the crown
            try std.testing.expect(bell.r * 2.0 > 1.0);
            try std.testing.expect(bell.pos[1] > p.tall * 0.7);
        }
    }
    // Cologne Cathedral is 157 m; Ulm Minster's spire, the tallest ever built, 161.5 m
    try std.testing.expect(tallest >= 161.5);
    try std.testing.expect(shortest >= 90.0);
}
