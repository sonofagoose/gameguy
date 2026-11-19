//! Asters as lines of light, drawn from the same plan the world makes its things from
//! (world/asters.zig), at three distances: near, every leaf and every flower; farther off, the
//! stalk, the branches and a small star for each bell; far, a mast and a few points. Each part of
//! the stalk and each bell is its own body, so a call can be seen to climb, and each bell lights
//! in its own note's colour when it rings.
const std = @import("std");
const lines = @import("lines.zig");
const colour = @import("colour.zig");
const world_mod = @import("../world/world.zig");
const asters = world_mod.asters;
const Inst = lines.Inst;
const V = [3]f32;

const near_cap = 1200;
const mid_cap = 170;
const far_cap = 16;
const occ_cap = 640;
/// Nearer than this an aster is drawn in full; farther than `mid_within`, as a mast.
pub const near_within: f32 = 230.0;
pub const mid_within: f32 = 750.0;

const Model = struct {
    near: [near_cap]Inst = undefined,
    near_n: u32 = 0,
    mid: [mid_cap]Inst = undefined,
    mid_n: u32 = 0,
    far: [far_cap]Inst = undefined,
    far_n: u32 = 0,
    occ: [occ_cap]V = undefined,
    occ_n: u32 = 0,
};

var plans: [asters.max_towers]asters.Plan = undefined;
var models: [asters.max_towers]Model = undefined;
var count: usize = 0;

const stalk = [3]f32{ 0.62, 0.86, 0.66 };

fn col8(rgb: [3]f32, alpha: f32) [4]u8 {
    return .{
        @intFromFloat(std.math.clamp(rgb[0], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[1], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[2], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(alpha, 0.0, 1.0) * 255.0),
    };
}

fn add(a: V, b: V) V {
    return .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] };
}

fn mul(a: V, s: f32) V {
    return .{ a[0] * s, a[1] * s, a[2] * s };
}

fn cross(a: V, b: V) V {
    return .{ a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] };
}

fn unit(a: V) V {
    const len = @sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    return mul(a, 1.0 / @max(len, 1e-6));
}

const List = struct {
    items: []Inst,
    n: *u32,

    fn line(self: List, a: V, b: V, half_width: f32, body: u32, col: [4]u8) void {
        if (self.n.* >= self.items.len) return;
        self.items[self.n.*] = .{ .a = a, .b = b, .half_width = half_width, .body = @floatFromInt(body), .col = col };
        self.n.* += 1;
    }
};

fn tri(model: *Model, a: V, b: V, c: V) void {
    if (model.occ_n + 3 > occ_cap) return;
    model.occ[model.occ_n] = a;
    model.occ[model.occ_n + 1] = b;
    model.occ[model.occ_n + 2] = c;
    model.occ_n += 3;
}

/// How thick the stalk is at a height: a metre through at the foot, a third of that at the top.
fn girth(p: *const asters.Plan, h: f32) f32 {
    return 0.5 * (1.0 - 0.62 * h / p.tall) + 0.04;
}

fn buildOne(p: *const asters.Plan, first: u32, model: *Model) void {
    model.* = .{};
    const near = List{ .items = &model.near, .n = &model.near_n };
    const mid = List{ .items = &model.mid, .n = &model.mid_n };
    const far = List{ .items = &model.far, .n = &model.far_n };
    const part = p.tall / @as(f32, asters.segments);
    const stalk_col = col8(stalk, 0.95);
    const leaf_col = col8(stalk, 0.70);
    const rib_col = col8(stalk, 0.35);
    const corners = [4][2]f32{ .{ 1.0, 1.0 }, .{ -1.0, 1.0 }, .{ -1.0, -1.0 }, .{ 1.0, -1.0 } };

    // the stalk: four edges for each of its twelve parts, round a black core
    for (0..asters.segments) |k| {
        const body = first + @as(u32, @intCast(k)) + 1;
        const h0 = @as(f32, @floatFromInt(k)) * part;
        const h1 = h0 + part;
        const c0 = p.mast(h0);
        const c1 = p.mast(h1);
        const r0 = girth(p, h0);
        const r1 = girth(p, h1);
        var lo: [4]V = undefined;
        var hi: [4]V = undefined;
        for (corners, 0..) |corner, i| {
            lo[i] = .{ c0[0] + corner[0] * r0, c0[1], c0[2] + corner[1] * r0 };
            hi[i] = .{ c1[0] + corner[0] * r1, c1[1], c1[2] + corner[1] * r1 };
            near.line(lo[i], hi[i], 1.4, body, stalk_col);
        }
        for (0..4) |i| {
            const j = (i + 1) % 4;
            const a0 = V{ c0[0] + (lo[i][0] - c0[0]) * 0.9, c0[1], c0[2] + (lo[i][2] - c0[2]) * 0.9 };
            const b0 = V{ c0[0] + (lo[j][0] - c0[0]) * 0.9, c0[1], c0[2] + (lo[j][2] - c0[2]) * 0.9 };
            const a1 = V{ c1[0] + (hi[i][0] - c1[0]) * 0.9, c1[1], c1[2] + (hi[i][2] - c1[2]) * 0.9 };
            const b1 = V{ c1[0] + (hi[j][0] - c1[0]) * 0.9, c1[1], c1[2] + (hi[j][2] - c1[2]) * 0.9 };
            tri(model, a0, b0, b1);
            tri(model, a0, b1, a1);
        }
        mid.line(c0, c1, 1.5, body, stalk_col);
        if (k % 3 == 1) far.line(p.mast(h0 - part), p.mast(h1 + part), 1.3, body, stalk_col);
    }

    // where it meets the ground
    const foot = p.mast(0.0);
    for (0..8) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
        const a = V{ foot[0] + 1.7 * @cos(a0), 0.06, foot[2] + 1.7 * @sin(a0) };
        const b = V{ foot[0] + 1.7 * @cos(a1), 0.06, foot[2] + 1.7 * @sin(a1) };
        near.line(a, b, 1.2, first + 1, stalk_col);
    }

    // the leaves: a spiral stair of blades, each lit with the part of the stalk it leaves
    for (p.leaves[0..p.leaf_n]) |leaf| {
        const body = first + @min(@as(u32, @intFromFloat(leaf.h / part)), asters.segments - 1) + 1;
        const out = V{ @cos(leaf.angle), 0.0, @sin(leaf.angle) };
        const side = V{ -@sin(leaf.angle), 0.0, @cos(leaf.angle) };
        const p0 = add(p.mast(leaf.h), mul(out, girth(p, leaf.h)));
        const p1 = add(add(p0, mul(out, leaf.len * 0.5)), V{ 0.0, leaf.len * 0.30, 0.0 });
        const p2 = add(add(p0, mul(out, leaf.len)), V{ 0.0, leaf.len * (0.34 - leaf.droop * 1.5), 0.0 });
        const wide = leaf.len * 0.11;
        const e0 = add(p1, mul(side, wide));
        const e1 = add(p1, mul(side, -wide));
        near.line(p0, e0, 1.2, body, leaf_col);
        near.line(e0, p2, 1.2, body, leaf_col);
        near.line(p0, e1, 1.2, body, leaf_col);
        near.line(e1, p2, 1.2, body, leaf_col);
        near.line(p0, p2, 1.0, body, rib_col);
        tri(model, p0, e0, e1);
        tri(model, e0, p2, e1);
    }

    // the crown: branches, and on them the bells
    const top_body = first + asters.segments;
    for (p.branches[0..p.branch_n]) |b| {
        const base = p.mast(b.h);
        const cr = @cos(b.rise);
        const dir = V{ @cos(b.angle) * cr, @sin(b.rise), @sin(b.angle) * cr };
        const tip = add(base, mul(dir, b.len));
        near.line(base, tip, 1.5, top_body, stalk_col);
        mid.line(base, tip, 1.1, top_body, stalk_col);
    }
    for (p.bells[0..p.bell_n], 0..) |bell, j| {
        const body = first + asters.segments + @as(u32, @intCast(j)) + 1;
        const tint = colour.ofNote(world_mod.garden_hz, bell.hz);
        const bright = col8(tint, 1.0);
        const soft = col8(tint, 0.6);
        // the flower faces up and out
        const n = unit(.{ @cos(bell.angle) * 0.55, 0.83, @sin(bell.angle) * 0.55 });
        const u = unit(cross(n, .{ 0.0, 1.0, 0.0 }));
        const v = cross(n, u);
        const c = bell.pos;
        const disc = bell.r * 0.36;
        for (0..12) |k| {
            const a = @as(f32, @floatFromInt(k)) * (6.2831853 / 12.0);
            const ray = add(mul(u, @cos(a)), mul(v, @sin(a)));
            near.line(add(c, mul(ray, disc)), add(c, mul(ray, bell.r)), 1.2, body, bright);
        }
        const under = add(c, mul(n, -bell.r * 0.7));
        for (0..6) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 6.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 6.0);
            const q0 = add(c, mul(add(mul(u, @cos(a0)), mul(v, @sin(a0))), disc));
            const q1 = add(c, mul(add(mul(u, @cos(a1)), mul(v, @sin(a1))), disc));
            near.line(q0, q1, 1.3, body, bright);
            if (k % 2 == 0) near.line(q0, under, 1.0, body, soft);
        }
        // farther off, a small star; far off, a point
        mid.line(add(c, mul(u, -bell.r)), add(c, mul(u, bell.r)), 1.3, body, bright);
        mid.line(add(c, mul(v, -bell.r)), add(c, mul(v, bell.r)), 1.3, body, bright);
        mid.line(add(c, mul(n, -bell.r * 0.7)), add(c, mul(n, bell.r * 0.4)), 1.3, body, bright);
        if (j % 3 == 0) far.line(add(c, .{ 0.0, -bell.r, 0.0 }), add(c, .{ 0.0, bell.r, 0.0 }), 1.5, body, bright);
    }
}

/// Make every aster's lines, once, for the world's proof field.
pub fn build(w: *const world_mod.World) void {
    count = asters.field(&plans, world_mod.garden_hz);
    for (plans[0..count], 0..) |*p, t| buildOne(p, w.towers[t].first, &models[t]);
}

/// Where the middle of an aster's stalk is at a height.
pub fn mastAt(tower: usize, h: f32) V {
    return plans[tower].mast(h);
}

pub const Picked = struct { lines: usize, occ: usize, near: u32, mid: u32, far: u32 };

/// The lines and black shapes for where the eye is now: each aster at the detail its distance
/// asks for.
pub fn pick(eye_x: f32, eye_z: f32, out: []Inst, occ: []V) Picked {
    var got = Picked{ .lines = 0, .occ = 0, .near = 0, .mid = 0, .far = 0 };
    for (plans[0..count], 0..) |*p, t| {
        const dx = p.x - eye_x;
        const dz = p.z - eye_z;
        const far = @sqrt(dx * dx + dz * dz);
        const model = &models[t];
        var from: []const Inst = undefined;
        if (far < near_within) {
            from = model.near[0..model.near_n];
            got.near += 1;
            if (got.occ + model.occ_n <= occ.len) {
                @memcpy(occ[got.occ..][0..model.occ_n], model.occ[0..model.occ_n]);
                got.occ += model.occ_n;
            }
        } else if (far < mid_within) {
            from = model.mid[0..model.mid_n];
            got.mid += 1;
        } else {
            from = model.far[0..model.far_n];
            got.far += 1;
        }
        if (got.lines + from.len > out.len) continue;
        @memcpy(out[got.lines..][0..from.len], from);
        got.lines += from.len;
    }
    return got;
}

fn hash(a: i32, b: i32, k: u32) u32 {
    var s: u32 = @as(u32, @bitCast(a)) *% 0x9e3779b1 ^ @as(u32, @bitCast(b)) *% 0x85ebca6b ^ (k +% 1) *% 0xc2b2ae35;
    s ^= s >> 15;
    s *%= 0x2c1b3c6d;
    s ^= s >> 12;
    s *%= 0x297a2d39;
    s ^= s >> 15;
    return s;
}

fn unit01(s: u32) f32 {
    return @as(f32, @floatFromInt(s >> 8)) * (1.0 / 16777216.0);
}

/// Grass round the eye: a real blade is 4 to 9 cm, so here each is a tree of 4 to 9 m.
pub fn grass(eye_x: f32, eye_z: f32, out: []Inst) usize {
    const cell: f32 = 16.0;
    const reach: i32 = 6;
    const cx: i32 = @intFromFloat(@floor(eye_x / cell));
    const cz: i32 = @intFromFloat(@floor(eye_z / cell));
    var n: usize = 0;
    var iz: i32 = cz - reach;
    while (iz <= cz + reach) : (iz += 1) {
        var ix: i32 = cx - reach;
        while (ix <= cx + reach) : (ix += 1) {
            for (0..4) |k| {
                if (n + 2 > out.len) return n;
                const s = hash(ix, iz, @intCast(k));
                const x = (@as(f32, @floatFromInt(ix)) + unit01(s)) * cell;
                const z = (@as(f32, @floatFromInt(iz)) + unit01(hash(iz, ix, @intCast(k + 7)))) * cell;
                const tall = 4.0 + 5.0 * unit01(s *% 2654435761);
                const way = unit01(s *% 40503) * 6.2831853;
                const bend = tall * (0.10 + 0.25 * unit01(s *% 69069));
                const base = V{ x, 0.0, z };
                const knee = V{ x + @cos(way) * bend * 0.3, tall * 0.55, z + @sin(way) * bend * 0.3 };
                const tip = V{ x + @cos(way) * bend, tall * 0.94, z + @sin(way) * bend };
                const tint = col8(.{ 0.36, 0.62, 0.44 }, 0.42);
                out[n] = .{ .a = base, .b = knee, .half_width = 1.2, .body = 0.0, .col = tint };
                out[n + 1] = .{ .a = knee, .b = tip, .half_width = 1.0, .body = 0.0, .col = tint };
                n += 2;
            }
        }
    }
    return n;
}

const sky_rows = 12;
const sky_parts = 36;

/// The day coming up: bands of light low in the sky, warm at the horizon and brightest toward
/// where the sun will be. They stand round the eye, as a sky does.
pub fn sky(eye: V, out: []Inst) usize {
    const radius: f32 = 1500.0;
    const dawn: f32 = -1.95; // a little right of straight ahead
    var n: usize = 0;
    for (0..sky_rows) |row| {
        const f = @as(f32, @floatFromInt(row)) / @as(f32, sky_rows - 1);
        const up = (0.5 + 15.0 * f * f + 3.0 * f) * (std.math.pi / 180.0);
        const y = eye[1] + radius * @sin(up);
        const flat = radius * @cos(up);
        const warm = [3]f32{ 1.0, 0.70, 0.42 };
        const cool = [3]f32{ 0.45, 0.52, 0.95 };
        const tint = [3]f32{ warm[0] + (cool[0] - warm[0]) * f, warm[1] + (cool[1] - warm[1]) * f, warm[2] + (cool[2] - warm[2]) * f };
        for (0..sky_parts) |k| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, sky_parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, sky_parts));
            const toward = @max(0.0, @cos((a0 + a1) * 0.5 - dawn));
            const level = (1.0 - f) * (0.25 + 0.75 * toward * toward);
            if (level < 0.06) continue;
            out[n] = .{
                .a = .{ eye[0] + flat * @cos(a0), y, eye[2] + flat * @sin(a0) },
                .b = .{ eye[0] + flat * @cos(a1), y, eye[2] + flat * @sin(a1) },
                .half_width = 2.6,
                .body = 0.0,
                .col = col8(tint, level),
            };
            n += 1;
        }
    }
    return n;
}
