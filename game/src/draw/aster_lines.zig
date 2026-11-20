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

const near_cap = 1400;
const close_cap = 900;
const mid_cap = 170;
const far_cap = 16;
const occ_cap = 640;
/// Nearer than `close_within` an aster also shows what is Hum's own size on it: the joints of
/// its stalk, and a drop of dew at the tip of each leaf. Nearer than `near_within` it is drawn
/// in full; farther than `mid_within`, as a mast.
pub const close_within: f32 = 85.0;
pub const near_within: f32 = 230.0;
pub const mid_within: f32 = 750.0;

const Model = struct {
    near: [near_cap]Inst = undefined,
    near_n: u32 = 0,
    close: [close_cap]Inst = undefined,
    close_n: u32 = 0,
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

/// Which body lights what (the loudness table, lines.zig). Nought is always lit: Hum, a call's
/// ring, the words. One is the day: the sky. Then the ground's cover, one body for each sixteen
/// metres square round Hum, so a call's ring can be seen to cross it. Then every thing.
pub const day_body: f32 = 1.0;
pub const cover_body: u32 = 2;
pub const cover_side: i32 = 15;
pub const thing_body: u32 = 2 + 15 * 15 + 3;

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
    const close = List{ .items = &model.close, .n = &model.close_n };
    const mid = List{ .items = &model.mid, .n = &model.mid_n };
    const far = List{ .items = &model.far, .n = &model.far_n };
    const part = p.tall / @as(f32, asters.segments);
    const stalk_col = col8(stalk, 0.95);
    const leaf_col = col8(stalk, 0.70);
    const rib_col = col8(stalk, 0.35);
    const corners = [4][2]f32{ .{ 1.0, 1.0 }, .{ -1.0, 1.0 }, .{ -1.0, -1.0 }, .{ 1.0, -1.0 } };

    // the stalk: four edges for each of its twelve parts, round a black core
    for (0..asters.segments) |k| {
        const body = thing_body + first + @as(u32, @intCast(k));
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

    // its joints: a ring every metre and a quarter, all the way up. They are what the eye counts.
    {
        const joint_col = col8(stalk, 0.34);
        var h: f32 = 1.25;
        while (h < p.tall) : (h += 1.25) {
            const body = thing_body + first + @min(@as(u32, @intFromFloat(h / part)), asters.segments - 1);
            const c = p.mast(h);
            const r = girth(p, h) * 1.12;
            for (0..4) |i| {
                const j = (i + 1) % 4;
                close.line(.{ c[0] + corners[i][0] * r, h, c[2] + corners[i][1] * r }, .{ c[0] + corners[j][0] * r, h, c[2] + corners[j][1] * r }, 1.0, body, joint_col);
            }
        }
    }

    // where it meets the ground
    const foot = p.mast(0.0);
    for (0..8) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
        const a = V{ foot[0] + 1.7 * @cos(a0), 0.06, foot[2] + 1.7 * @sin(a0) };
        const b = V{ foot[0] + 1.7 * @cos(a1), 0.06, foot[2] + 1.7 * @sin(a1) };
        near.line(a, b, 1.2, thing_body + first, stalk_col);
    }

    // the leaves: a spiral stair of blades, each lit with the part of the stalk it leaves
    for (p.leaves[0..p.leaf_n]) |leaf| {
        const body = thing_body + first + @min(@as(u32, @intFromFloat(leaf.h / part)), asters.segments - 1);
        const out = V{ @cos(leaf.angle), 0.0, @sin(leaf.angle) };
        const side = V{ -@sin(leaf.angle), 0.0, @cos(leaf.angle) };
        const p0 = add(p.mast(leaf.h), mul(out, girth(p, leaf.h)));
        const rise = leaf.len * 0.30;
        const fall = leaf.len * leaf.droop * 1.5;
        const at_a = add(add(p0, mul(out, leaf.len * 0.32)), V{ 0.0, rise * 0.75, 0.0 });
        const at_b = add(add(p0, mul(out, leaf.len * 0.68)), V{ 0.0, rise - fall * 0.35, 0.0 });
        const tip = add(add(p0, mul(out, leaf.len)), V{ 0.0, rise * 0.9 - fall, 0.0 });
        const wide = leaf.len * 0.10;
        const a0 = add(at_a, mul(side, wide));
        const a1 = add(at_a, mul(side, -wide));
        const b0 = add(at_b, mul(side, wide * 0.66));
        const b1 = add(at_b, mul(side, -wide * 0.66));
        near.line(p0, a0, 1.2, body, leaf_col);
        near.line(a0, b0, 1.2, body, leaf_col);
        near.line(b0, tip, 1.2, body, leaf_col);
        near.line(p0, a1, 1.2, body, leaf_col);
        near.line(a1, b1, 1.2, body, leaf_col);
        near.line(b1, tip, 1.2, body, leaf_col);
        near.line(p0, tip, 1.0, body, rib_col);
        tri(model, p0, a0, a1);
        tri(model, a0, b0, a1);
        tri(model, a1, b0, b1);
        tri(model, b0, tip, b1);
        // dew: a drop as wide as Hum is tall would be huge; these are 40 cm
        const drop = add(tip, V{ 0.0, -0.35, 0.0 });
        const dew = col8(.{ 0.85, 0.95, 1.0 }, 0.9);
        close.line(add(drop, V{ 0.0, 0.2, 0.0 }), add(drop, mul(side, 0.2)), 1.0, body, dew);
        close.line(add(drop, mul(side, 0.2)), add(drop, V{ 0.0, -0.2, 0.0 }), 1.0, body, dew);
        close.line(add(drop, V{ 0.0, -0.2, 0.0 }), add(drop, mul(side, -0.2)), 1.0, body, dew);
        close.line(add(drop, mul(side, -0.2)), add(drop, V{ 0.0, 0.2, 0.0 }), 1.0, body, dew);
    }

    // the crown: branches, and on them the bells
    const top_body = thing_body + first + asters.segments - 1;
    for (p.branches[0..p.branch_n]) |b| {
        const base = p.mast(b.h);
        const cr = @cos(b.rise);
        const dir = V{ @cos(b.angle) * cr, @sin(b.rise), @sin(b.angle) * cr };
        const tip = add(base, mul(dir, b.len));
        near.line(base, tip, 1.5, top_body, stalk_col);
        mid.line(base, tip, 1.1, top_body, stalk_col);
    }
    for (p.bells[0..p.bell_n], 0..) |bell, j| {
        const body = thing_body + first + asters.segments + @as(u32, @intCast(j));
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
            if (far < close_within and got.lines + model.close_n <= out.len) {
                @memcpy(out[got.lines..][0..model.close_n], model.close[0..model.close_n]);
                got.lines += model.close_n;
            }
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

/// Everything that sounds shines: round each bell that is ringing, a halo that beats at the
/// bell's own note brought down eight octaves, so its pitch can be seen as a pulse.
pub fn halos(w: *const world_mod.World, eye: V, out: []Inst) usize {
    var n: usize = 0;
    const seconds = @as(f32, @floatFromInt(w.step)) * world_mod.dt;
    for (plans[0..count], 0..) |*p, t| {
        const dx = p.x - eye[0];
        const dz = p.z - eye[2];
        if (dx * dx + dz * dz > 420.0 * 420.0) continue;
        const first = w.towers[t].first + asters.segments;
        for (p.bells[0..p.bell_n], 0..) |bell, j| {
            const thing = w.things[first + j];
            if (thing.loud < 0.12) continue;
            if (n + 8 > out.len) return n;
            const beat = 0.5 + 0.5 * @cos(seconds * bell.hz * (6.2831853 / 256.0));
            const tint = col8(colour.ofNote(world_mod.garden_hz, bell.hz), thing.loud * (0.35 + 0.65 * beat));
            const r = bell.r * (1.7 + 0.9 * beat);
            // facing the eye, near enough: a ring in the plane across the line of sight
            const sx = -dz;
            const sz = dx;
            const len = @max(@sqrt(sx * sx + sz * sz), 1e-3);
            const side = V{ sx / len, 0.0, sz / len };
            for (0..8) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
                out[n] = .{
                    .a = add(add(bell.pos, mul(side, r * @cos(a0))), V{ 0.0, r * @sin(a0), 0.0 }),
                    .b = add(add(bell.pos, mul(side, r * @cos(a1))), V{ 0.0, r * @sin(a1), 0.0 }),
                    .half_width = 1.3,
                    .body = 0.0,
                    .col = tint,
                };
                n += 1;
            }
        }
    }
    return n;
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

/// One blade of grass: a real one is 4 to 9 cm, so here it is a tree 4 to 9 m tall and as wide
/// as a door, and it hides what is behind it.
fn blade(ix: i32, iz: i32, k: u32, cell: f32, body: f32, out: []Inst, n: *usize, occ: []V, occ_n: *usize) void {
    if (n.* + 5 > out.len) return;
    const tint = col8(.{ 0.36, 0.66, 0.46 }, 0.17);
    const vein = col8(.{ 0.36, 0.66, 0.46 }, 0.08);
    const s = hash(ix, iz, k);
    const x = (@as(f32, @floatFromInt(ix)) + unit01(s)) * cell;
    const z = (@as(f32, @floatFromInt(iz)) + unit01(hash(iz, ix, k + 7))) * cell;
    const tall = 4.0 + 5.0 * unit01(s *% 2654435761);
    const way = unit01(s *% 40503) * 6.2831853;
    const bend = tall * (0.12 + 0.30 * unit01(s *% 69069));
    const half = 0.18 + 0.12 * unit01(s *% 22695477);
    const across = V{ -@sin(way) * half, 0.0, @cos(way) * half };
    const base = V{ x, 0.0, z };
    const knee = V{ x + @cos(way) * bend * 0.3, tall * 0.58, z + @sin(way) * bend * 0.3 };
    const tip = V{ x + @cos(way) * bend, tall * 0.95, z + @sin(way) * bend };
    const b0 = add(base, across);
    const b1 = add(base, mul(across, -1.0));
    const k0 = add(knee, across);
    const k1 = add(knee, mul(across, -1.0));
    out[n.*] = .{ .a = b0, .b = k0, .half_width = 1.2, .body = body, .col = tint };
    out[n.* + 1] = .{ .a = k0, .b = tip, .half_width = 1.1, .body = body, .col = tint };
    out[n.* + 2] = .{ .a = b1, .b = k1, .half_width = 1.2, .body = body, .col = tint };
    out[n.* + 3] = .{ .a = k1, .b = tip, .half_width = 1.1, .body = body, .col = tint };
    out[n.* + 4] = .{ .a = base, .b = knee, .half_width = 0.9, .body = body, .col = vein };
    n.* += 5;
    if (occ_n.* + 9 > occ.len) return;
    const shapes = [9]V{ b0, b1, k1, b0, k1, k0, k0, k1, tip };
    @memcpy(occ[occ_n.*..][0..9], &shapes);
    occ_n.* += 9;
}

/// What the ground wears (spec/world.md, "What the ground wears"). These are four of the
/// Garden's own covers. Each land has its own, and no cover is only scenery.
pub const Cover = enum { soil, lawn, clover, moss };

/// Which cover is at a place: wide patches, a hundred metres or so across, by a sum from where
/// it is.
pub fn coverAt(x: f32, z: f32) Cover {
    const fx = x * (1.0 / 105.0);
    const fz = z * (1.0 / 105.0);
    const ix: i32 = @intFromFloat(@floor(fx));
    const iz: i32 = @intFromFloat(@floor(fz));
    const tx = fx - @floor(fx);
    const tz = fz - @floor(fz);
    const sx = tx * tx * (3.0 - 2.0 * tx);
    const sz = tz * tz * (3.0 - 2.0 * tz);
    const a = unit01(hash(ix, iz, 501));
    const b = unit01(hash(ix + 1, iz, 501));
    const c = unit01(hash(ix, iz + 1, 501));
    const d = unit01(hash(ix + 1, iz + 1, 501));
    const v = (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sz;
    return if (v < 0.40) .soil else if (v < 0.50) .lawn else if (v < 0.60) .clover else .moss;
}

const Out = struct {
    lines: []Inst,
    n: *usize,
    occ: []V,
    occ_n: *usize,
    /// The body of the cell of ground being drawn.
    body: f32 = 0.0,

    fn line(self: Out, a: V, b: V, half_width: f32, col: [4]u8) void {
        if (self.n.* >= self.lines.len) return;
        self.lines[self.n.*] = .{ .a = a, .b = b, .half_width = half_width, .body = self.body, .col = col };
        self.n.* += 1;
    }

    fn tri(self: Out, a: V, b: V, c: V) void {
        if (self.occ_n.* + 3 > self.occ.len) return;
        self.occ[self.occ_n.*] = a;
        self.occ[self.occ_n.* + 1] = b;
        self.occ[self.occ_n.* + 2] = c;
        self.occ_n.* += 3;
    }
};

/// Clover: a real leaf stands 3 to 7 cm high on a thread of a stalk, three leaflets each a
/// centimetre or so across. Here it is a roof three to seven metres up, and it hides the sky.
fn clover(x: f32, z: f32, s: u32, out: Out) void {
    const tint = col8(.{ 0.40, 0.72, 0.56 }, 0.22);
    const rib = col8(.{ 0.40, 0.72, 0.56 }, 0.11);
    const tall = 3.0 + 4.0 * unit01(s *% 2654435761);
    const r = 1.1 + 0.7 * unit01(s *% 40503);
    const turn = unit01(s *% 69069) * 6.2831853;
    const lean = V{ @cos(turn) * tall * 0.12, 0.0, @sin(turn) * tall * 0.12 };
    const top = V{ x + lean[0], tall, z + lean[2] };
    out.line(.{ x, 0.0, z }, top, 1.0, rib);
    for (0..3) |k| {
        const a = turn + @as(f32, @floatFromInt(k)) * 2.0943951;
        const far = V{ top[0] + @cos(a) * r * 1.9, tall - r * 0.18, top[2] + @sin(a) * r * 1.9 };
        const left = V{ top[0] + @cos(a - 0.62) * r * 1.25, tall + r * 0.10, top[2] + @sin(a - 0.62) * r * 1.25 };
        const right = V{ top[0] + @cos(a + 0.62) * r * 1.25, tall + r * 0.10, top[2] + @sin(a + 0.62) * r * 1.25 };
        out.line(top, left, 1.2, tint);
        out.line(left, far, 1.2, tint);
        out.line(far, right, 1.2, tint);
        out.line(right, top, 1.2, tint);
        out.line(top, far, 0.9, rib);
        out.tri(top, left, far);
        out.tri(top, far, right);
    }
}

/// Moss: a cushion a few metres across and a metre or so high, bristling with its thin stalks.
fn moss(x: f32, z: f32, s: u32, near: bool, out: Out) void {
    const tint = col8(.{ 0.30, 0.58, 0.36 }, 0.20);
    const fine = col8(.{ 0.52, 0.70, 0.40 }, 0.16);
    const r = 2.0 + 3.0 * unit01(s *% 2654435761);
    const high = 0.5 + 0.9 * unit01(s *% 40503);
    const turn = unit01(s *% 69069) * 6.2831853;
    const top = V{ x, high, z };
    const sides: usize = if (near) 7 else 5;
    for (0..sides) |k| {
        const a0 = turn + @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, @floatFromInt(sides)));
        const a1 = turn + @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, @floatFromInt(sides)));
        const q0 = V{ x + r * @cos(a0), 0.03, z + r * @sin(a0) };
        const q1 = V{ x + r * @cos(a1), 0.03, z + r * @sin(a1) };
        const shoulder = V{ x + r * 0.55 * @cos(a0), high * 0.8, z + r * 0.55 * @sin(a0) };
        out.line(q0, q1, 1.1, tint);
        out.line(q0, shoulder, 1.0, tint);
        out.line(shoulder, top, 1.0, tint);
        out.tri(q0, q1, top);
        if (near and k % 2 == 0) {
            // a stalk with its capsule, as thin as a hair and taller than Hum
            const foot = V{ x + r * 0.4 * @cos(a0 + 0.4), high * 0.85, z + r * 0.4 * @sin(a0 + 0.4) };
            const head = V{ foot[0] + 0.15, high + 1.2 + 0.8 * unit01(s *% @as(u32, @intCast(k + 3))), foot[2] };
            out.line(foot, head, 0.8, fine);
            out.line(head, .{ head[0] + 0.22, head[1] + 0.28, head[2] }, 1.3, fine);
        }
    }
}

/// A crumb of soil: a boulder from half a metre to three metres across, and no two alike. A real
/// crumb is half a centimetre to three.
fn crumb(x: f32, z: f32, s: u32, out: Out) void {
    const stone = col8(.{ 0.62, 0.56, 0.50 }, 0.20);
    const big = unit01(s *% 40503);
    const r = 0.4 + 2.4 * big * big;
    const high = r * (0.35 + 0.5 * unit01(s *% 69069));
    const sides: usize = 5 + @as(usize, s >> 7) % 3;
    const turn = unit01(s *% 22695477) * 6.2831853;
    const lean = V{ (unit01(s *% 1103515245) - 0.5) * r * 0.5, 0.0, (unit01(s *% 134775813) - 0.5) * r * 0.5 };
    var base: [7]V = undefined;
    var top: [7]V = undefined;
    for (0..sides) |k| {
        const a = turn + @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, @floatFromInt(sides)));
        const out_by = r * (0.65 + 0.55 * unit01(hash(@intCast(k), @bitCast(s), 7)));
        const in_by = out_by * (0.30 + 0.25 * unit01(hash(@intCast(k), @bitCast(s), 11)));
        base[k] = .{ x + out_by * @cos(a), 0.03, z + out_by * @sin(a) };
        top[k] = .{ x + lean[0] + in_by * @cos(a + 0.3), high * (0.8 + 0.3 * unit01(hash(@intCast(k), @bitCast(s), 13))), z + lean[2] + in_by * @sin(a + 0.3) };
    }
    for (0..sides) |k| {
        const n = (k + 1) % sides;
        out.line(base[k], base[n], 1.1, stone);
        out.line(top[k], top[n], 1.0, stone);
        if (k % 2 == 0) out.line(base[k], top[k], 1.0, stone);
        out.tri(base[k], base[n], top[n]);
        out.tri(base[k], top[n], top[k]);
        out.tri(top[0], top[k], top[n]);
    }
}

/// A pebble: a mark on the ground no bigger than Hum, to show where the ground is.
fn pebble(x: f32, z: f32, s: u32, out: Out) void {
    const stone = col8(.{ 0.62, 0.56, 0.50 }, 0.16);
    const r = 0.15 + 0.35 * unit01(s *% 40503);
    const turn = unit01(s *% 69069) * 6.2831853;
    for (0..3) |k| {
        const a0 = turn + @as(f32, @floatFromInt(k)) * 2.0943951;
        const a1 = a0 + 2.0943951;
        out.line(.{ x + r * @cos(a0), 0.03, z + r * @sin(a0) }, .{ x + r * @cos(a1), 0.03, z + r * @sin(a1) }, 1.0, stone);
    }
}

/// One cell of ground, wearing whatever cover is at its middle.
fn patch(ix: i32, iz: i32, size: f32, near: bool, salt: u32, out: Out) void {
    const mid_x = (@as(f32, @floatFromInt(ix)) + 0.5) * size;
    const mid_z = (@as(f32, @floatFromInt(iz)) + 0.5) * size;
    const many: u32 = if (near) 3 else 2;
    switch (coverAt(mid_x, mid_z)) {
        .lawn => {
            for (0..many) |k| blade(ix, iz, @intCast(k + salt), size, out.body, out.lines, out.n, out.occ, out.occ_n);
        },
        .clover => {
            for (0..many - 1) |k| {
                const s = hash(ix, iz, @intCast(k + salt + 40));
                clover((@as(f32, @floatFromInt(ix)) + unit01(s)) * size, (@as(f32, @floatFromInt(iz)) + unit01(s *% 22695477)) * size, s, out);
            }
        },
        .moss => {
            for (0..many - 1) |k| {
                const s = hash(ix, iz, @intCast(k + salt + 60));
                moss((@as(f32, @floatFromInt(ix)) + unit01(s)) * size, (@as(f32, @floatFromInt(iz)) + unit01(s *% 22695477)) * size, s, near, out);
            }
        },
        .soil => {
            // bare ground after the storm: mostly nothing, a few pebbles, and now and then a crumb
            for (0..many) |k| {
                const s = hash(ix, iz, @intCast(k + salt + 80));
                const px = (@as(f32, @floatFromInt(ix)) + unit01(s)) * size;
                const pz = (@as(f32, @floatFromInt(iz)) + unit01(s *% 22695477)) * size;
                if (k == 0 and s % 5 == 0) crumb(px, pz, s, out) else pebble(px, pz, s, out);
            }
        },
    }
}

/// The ground round Hum, one to a hundred, wearing its covers: lawn, clover, moss and bare soil
/// in wide patches, thick close by and thinner farther off. The return is how many lines;
/// `occ_n` grows by the black shapes. `grid` is given the corner cell of the fifteen by fifteen
/// square of sixteen-metre cells that was drawn, so the caller can light each cell by its body.
pub fn ground(hum_x: f32, hum_z: f32, lines_out: []Inst, occ: []V, occ_n: *usize, grid: *[2]i32) usize {
    var n: usize = 0;
    var out = Out{ .lines = lines_out, .n = &n, .occ = occ, .occ_n = occ_n };
    const size: f32 = 16.0;
    const half: i32 = @divTrunc(cover_side, 2);
    const cx: i32 = @intFromFloat(@floor(hum_x / size));
    const cz: i32 = @intFromFloat(@floor(hum_z / size));
    grid.* = .{ cx - half, cz - half };
    var iz: i32 = cz - half;
    while (iz <= cz + half) : (iz += 1) {
        var ix: i32 = cx - half;
        while (ix <= cx + half) : (ix += 1) {
            out.body = @floatFromInt(@as(i32, @intCast(cover_body)) + (ix - grid[0]) + (iz - grid[1]) * cover_side);
            patch(ix, iz, size, false, 0, out);
            // close by, four smaller squares in each, thick with whatever grows there
            if (@abs(ix - cx) <= 3 and @abs(iz - cz) <= 3) {
                for (0..4) |q| patch(ix * 2 + @as(i32, @intCast(q % 2)), iz * 2 + @as(i32, @intCast(q / 2)), size * 0.5, true, 20, out);
            }
        }
    }
    return n;
}

/// The flower head that has fallen by the great aster's foot, lying on its side: a bell at Hum's
/// own size. Its body is the world's thing for it.
pub fn fallen(w: *const world_mod.World, out: []Inst) usize {
    if (w.fallen >= w.thing_count) return 0;
    const thing = w.things[w.fallen];
    const body: f32 = @floatFromInt(thing_body + w.fallen);
    const tint = colour.ofNote(world_mod.garden_hz, thing.hz);
    const bright = col8(tint, 1.0);
    const soft = col8(tint, 0.6);
    const c = V{ thing.x, thing.y, thing.z };
    const r = thing.tall;
    const n = unit(.{ 0.75, 0.55, -0.35 });
    const u = unit(cross(n, .{ 0.0, 1.0, 0.0 }));
    const v = cross(n, u);
    const disc = r * 0.36;
    var made: usize = 0;
    for (0..16) |k| {
        if (made >= out.len) return made;
        const a = @as(f32, @floatFromInt(k)) * (6.2831853 / 16.0);
        const ray = add(mul(u, @cos(a)), mul(v, @sin(a)));
        out[made] = .{ .a = add(c, mul(ray, disc)), .b = add(c, mul(ray, r)), .half_width = 1.6, .body = body, .col = bright };
        made += 1;
    }
    const under = add(c, mul(n, -r * 0.7));
    for (0..8) |k| {
        if (made + 2 > out.len) return made;
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
        const q0 = add(c, mul(add(mul(u, @cos(a0)), mul(v, @sin(a0))), disc));
        const q1 = add(c, mul(add(mul(u, @cos(a1)), mul(v, @sin(a1))), disc));
        out[made] = .{ .a = q0, .b = q1, .half_width = 1.7, .body = body, .col = bright };
        out[made + 1] = .{ .a = q0, .b = under, .half_width = 1.3, .body = body, .col = soft };
        made += 2;
    }
    return made;
}

/// Where the sun will come up: as a way across the ground (x is its cosine, z its sine), and as
/// a turn of the view from straight ahead.
const dawn_way: f32 = -1.12;
pub const dawn_yaw: f32 = dawn_way + 1.5707963;

/// The day coming up: the rim of the sun on the horizon, as arcs of light, and a faint line
/// where the ground ends. They stand round the eye, as a sky does.
pub fn sky(eye: V, out: []Inst) usize {
    const radius: f32 = 420.0;
    const dawn: f32 = dawn_way;
    const centre = V{ eye[0] + radius * @cos(dawn), eye[1], eye[2] + radius * @sin(dawn) };
    const right = V{ -@sin(dawn), 0.0, @cos(dawn) };
    var n: usize = 0;
    const arcs = 9;
    const parts = 18;
    for (0..arcs) |k| {
        const f = @as(f32, @floatFromInt(k)) / @as(f32, arcs - 1);
        const wide = radius * @tan((1.6 + 2.1 * @as(f32, @floatFromInt(k))) * (std.math.pi / 180.0));
        const tint = col8(.{ 1.0, 0.74 - 0.20 * f, 0.44 + 0.30 * f }, (1.0 - f) * (1.0 - f) * 0.88 + 0.12);
        for (0..parts) |j| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(j)) * (std.math.pi / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(j + 1)) * (std.math.pi / @as(f32, parts));
            out[n] = .{
                .a = add(add(centre, mul(right, wide * @cos(a0))), V{ 0.0, wide * @sin(a0), 0.0 }),
                .b = add(add(centre, mul(right, wide * @cos(a1))), V{ 0.0, wide * @sin(a1), 0.0 }),
                .half_width = 3.0,
                .body = day_body,
                .col = tint,
            };
            n += 1;
        }
    }
    const rim = col8(.{ 0.75, 0.62, 0.55 }, 0.30);
    const round = 48;
    for (0..round) |k| {
        if (n >= out.len) return n;
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, round));
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, round));
        const toward = @max(0.0, @cos((a0 + a1) * 0.5 - dawn));
        if (toward < 0.2) continue;
        out[n] = .{
            .a = .{ eye[0] + radius * @cos(a0), eye[1] - 1.5, eye[2] + radius * @sin(a0) },
            .b = .{ eye[0] + radius * @cos(a1), eye[1] - 1.5, eye[2] + radius * @sin(a1) },
            .half_width = 2.0,
            .body = day_body,
            .col = rim,
        };
        n += 1;
    }
    return n;
}
