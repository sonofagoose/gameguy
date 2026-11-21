//! What stands on the ground (spec/shape.md, the Garden; spec/laws.md, "What a thing is"): every
//! blade, clover leaf, moss cushion, crumb and pebble, placed by one rule from where it is. The
//! picture draws these bodies and the world feels the same ones, so what is seen and what is felt
//! can't disagree. Fallen leaves lie on their own six-metre grid (`leafAt`). No platform.

const ground = @import("ground.zig");

pub const Kind = enum { blade, clover, moss, crumb, pebble };

pub const Body = struct {
    kind: Kind,
    x: f32,
    z: f32,
    /// Its own number, which sizes the rest of it.
    s: u32,
    /// A blade is sized from the cell it stands in and its key there.
    ix: i32 = 0,
    iz: i32 = 0,
    k: u32 = 0,
    cell: f32 = 0.0,
};

/// At most this many bodies in one patch.
pub const most_in_patch = 3;

/// The patches the ground is drawn and felt in: sixteen-metre squares everywhere, and close by
/// eight-metre squares inside them, more thickly grown, with keys of their own.
pub const far_size: f32 = 16.0;
pub const near_size: f32 = 8.0;
pub const near_salt: u32 = 20;

/// The bodies one patch of ground wears: a square `size` across at (ix, iz), by whatever cover is
/// at its middle, more of them close by (`near`). `salt` keeps the near patches' bodies apart from
/// the far ones'. Nothing stands in a puddle's water.
pub fn patch(ix: i32, iz: i32, size: f32, near: bool, salt: u32, out: *[most_in_patch]Body) usize {
    const mid_x = (@as(f32, @floatFromInt(ix)) + 0.5) * size;
    const mid_z = (@as(f32, @floatFromInt(iz)) + 0.5) * size;
    const many: u32 = if (near) 3 else 2;
    const fx: f32 = @floatFromInt(ix);
    const fz: f32 = @floatFromInt(iz);
    var n: usize = 0;
    switch (ground.coverAt(mid_x, mid_z)) {
        .lawn => {
            for (0..many) |k| {
                const key: u32 = @intCast(k + salt);
                const s = ground.hash32(ix, iz, key);
                const x = (fx + ground.unit01(s)) * size;
                const z = (fz + ground.unit01(ground.hash32(iz, ix, key + 7))) * size;
                if (ground.wet(x, z)) continue;
                out[n] = .{ .kind = .blade, .x = x, .z = z, .s = s, .ix = ix, .iz = iz, .k = key, .cell = size };
                n += 1;
            }
        },
        .clover, .moss => |c| {
            const add: u32 = if (c == .clover) 40 else 60;
            for (0..many - 1) |k| {
                const s = ground.hash32(ix, iz, @intCast(k + salt + add));
                const x = (fx + ground.unit01(s)) * size;
                const z = (fz + ground.unit01(s *% 22695477)) * size;
                if (ground.wet(x, z)) continue;
                out[n] = .{ .kind = if (c == .clover) .clover else .moss, .x = x, .z = z, .s = s };
                n += 1;
            }
        },
        .soil => {
            // bare ground after the storm: mostly nothing, a few pebbles, and now and then a crumb
            for (0..many) |k| {
                const s = ground.hash32(ix, iz, @intCast(k + salt + 80));
                const x = (fx + ground.unit01(s)) * size;
                const z = (fz + ground.unit01(s *% 22695477)) * size;
                if (ground.wet(x, z)) continue;
                out[n] = .{ .kind = if (k == 0 and s % 5 == 0) .crumb else .pebble, .x = x, .z = z, .s = s };
                n += 1;
            }
        },
        .leaves, .water => {},
    }
    return n;
}

/// A clover leaf's stalk: as tall as the roof it holds (a real one 3 to 7 cm, so 3 to 7 m), and
/// as thick at Hum's height as a real stalk is (about a millimetre, so about 0.16 m through).
pub fn cloverTall(s: u32) f32 {
    return 3.0 + 4.0 * ground.unit01(s *% 2654435761);
}
pub const clover_stalk: f32 = 0.08;

/// A crumb of soil: from half a metre to three across, and as high as its own shape makes it.
pub const Crumb = struct { r: f32, high: f32 };
pub fn crumb(s: u32) Crumb {
    const big = ground.unit01(s *% 40503);
    const r = 0.4 + 2.4 * big * big;
    return .{ .r = r, .high = r * (0.35 + 0.5 * ground.unit01(s *% 69069)) };
}
/// How far a crumb's foot reaches from its middle, on the whole: its corners reach from 0.65 to
/// 1.2 of its size.
pub const crumb_reach: f32 = 0.9;

const std = @import("std");

test "the near patches and the far ones wear the same covers, and nothing stands in water" {
    var bodies: [most_in_patch]Body = undefined;
    var seen: [5]u32 = @splat(0);
    var iz: i32 = -40;
    while (iz < 40) : (iz += 1) {
        var ix: i32 = -40;
        while (ix < 40) : (ix += 1) {
            for ([_]bool{ false, true }) |near| {
                const size: f32 = if (near) near_size else far_size;
                const n = patch(ix, iz, size, near, if (near) near_salt else 0, &bodies);
                for (bodies[0..n]) |b| {
                    try std.testing.expect(!ground.wet(b.x, b.z));
                    seen[@intFromEnum(b.kind)] += 1;
                }
            }
        }
    }
    for (seen) |count| try std.testing.expect(count > 0);
}

/// A fallen leaf: last year's, 5 to 10 m long at one to a hundred, lying curled with its tips up.
/// One lies in each six-metre square of leaf fall, where the leaves are the ground's cover there.
pub const Leaf = struct {
    x: f32,
    z: f32,
    /// Half its length and half its width, which way it lies, and how high its tips curl.
    len: f32,
    wide: f32,
    turn: f32,
    curl: f32,
    s: u32,
};
pub const leaf_cell: f32 = 6.0;

pub fn leafAt(cx: i32, cz: i32) ?Leaf {
    const s = ground.hash32(cx, cz, 41);
    const x = (@as(f32, @floatFromInt(cx)) + 0.2 + 0.6 * ground.unit01(s)) * leaf_cell;
    const z = (@as(f32, @floatFromInt(cz)) + 0.2 + 0.6 * ground.unit01(s *% 2654435761)) * leaf_cell;
    if (ground.wet(x, z) or ground.coverAt(x, z) != .leaves) return null;
    const len = 2.5 + 2.5 * ground.unit01(s *% 40503);
    return .{
        .x = x,
        .z = z,
        .len = len,
        .wide = len * (0.25 + 0.12 * ground.unit01(s *% 69069)),
        .turn = ground.unit01(s *% 22695477) * 6.2831853,
        .curl = 0.3 + 0.8 * ground.unit01(s *% 1103515245),
        .s = s,
    };
}

/// Whether a place is on the leaf: inside the oval its outline makes.
pub fn onLeaf(leaf: Leaf, x: f32, z: f32) bool {
    const dx = x - leaf.x;
    const dz = z - leaf.z;
    const u = dx * @cos(leaf.turn) + dz * @sin(leaf.turn);
    const v = -dx * @sin(leaf.turn) + dz * @cos(leaf.turn);
    return (u / leaf.len) * (u / leaf.len) + (v / leaf.wide) * (v / leaf.wide) <= 1.0;
}

/// The leaf under a place, if one is: its own six-metre square and the ones round it, since a long
/// leaf reaches over into its neighbours. Its key is its square.
pub fn leafUnder(x: f32, z: f32) ?[2]i32 {
    const cx: i32 = @intFromFloat(@floor(x / leaf_cell));
    const cz: i32 = @intFromFloat(@floor(z / leaf_cell));
    var iz = cz - 1;
    while (iz <= cz + 1) : (iz += 1) {
        var ix = cx - 1;
        while (ix <= cx + 1) : (ix += 1) {
            const leaf = leafAt(ix, iz) orelse continue;
            if (onLeaf(leaf, x, z)) return .{ ix, iz };
        }
    }
    return null;
}
