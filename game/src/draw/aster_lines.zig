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
/// The colour of a note that is not on the wheel (spec/sky.md): no hue.
const chrome = [3]f32{ 0.72, 0.76, 0.82 };

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
    if (world_mod.ground.wet(x, z)) return;
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
/// What the ground wears is the world's to know (world/ground.zig): the picture reads the same sum.
pub const Cover = world_mod.ground.Cover;
pub const coverAt = world_mod.ground.coverAt;

/// How much of the light that falls on it a cover gives back: moss swallows light as it swallows
/// sound (spec/shape.md; spec/texture.md).
pub fn coverGives(cover: Cover) f32 {
    return switch (cover) {
        .soil => 1.0,
        .lawn => 0.85,
        .leaves => 0.8,
        .clover => 0.9,
        .moss => 0.45,
        // still water is a black mirror: it gives back only the lights near it
        .water => 0.3,
    };
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
    if (world_mod.ground.wet(x, z)) return;
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
    if (world_mod.ground.wet(x, z)) return;
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
    if (world_mod.ground.wet(x, z)) return;
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
    if (world_mod.ground.wet(x, z)) return;
    const stone = col8(.{ 0.62, 0.56, 0.50 }, 0.16);
    const r = 0.15 + 0.35 * unit01(s *% 40503);
    const turn = unit01(s *% 69069) * 6.2831853;
    for (0..3) |k| {
        const a0 = turn + @as(f32, @floatFromInt(k)) * 2.0943951;
        const a1 = a0 + 2.0943951;
        out.line(.{ x + r * @cos(a0), 0.03, z + r * @sin(a0) }, .{ x + r * @cos(a1), 0.03, z + r * @sin(a1) }, 1.0, stone);
    }
}

/// A fallen leaf: last year's, 5 to 10 m long at one to a hundred, lying curled with its tips up.
/// One lies in each six metres square of leaf fall, where the world rings it underfoot.
fn fallenLeaf(cx: i32, cz: i32, out: Out) void {
    const s = world_mod.ground.hash32(cx, cz, 41);
    const x = (@as(f32, @floatFromInt(cx)) + 0.2 + 0.6 * unit01(s)) * 6.0;
    const z = (@as(f32, @floatFromInt(cz)) + 0.2 + 0.6 * unit01(s *% 2654435761)) * 6.0;
    if (world_mod.ground.wet(x, z)) return;
    const len = 2.5 + 2.5 * unit01(s *% 40503);
    const wide = len * (0.25 + 0.12 * unit01(s *% 69069));
    const turn = unit01(s *% 22695477) * 6.2831853;
    const along = V{ @cos(turn), 0.0, @sin(turn) };
    const across = V{ -@sin(turn), 0.0, @cos(turn) };
    const curl = 0.3 + 0.8 * unit01(s *% 1103515245);
    const dry = col8(.{ 0.78, 0.66, 0.48 }, 0.17);
    const rib = col8(.{ 0.78, 0.66, 0.48 }, 0.09);
    const c = V{ x, 0.05, z };
    const tip0 = add(add(c, mul(along, -len)), V{ 0.0, curl, 0.0 });
    const tip1 = add(add(c, mul(along, len)), V{ 0.0, curl * 0.7, 0.0 });
    const side0 = add(c, mul(across, wide));
    const side1 = add(c, mul(across, -wide));
    const q0 = add(add(c, mul(along, -len * 0.5)), mul(across, wide * 0.8));
    const q1 = add(add(c, mul(along, len * 0.5)), mul(across, wide * 0.8));
    const q2 = add(add(c, mul(along, len * 0.5)), mul(across, -wide * 0.8));
    const q3 = add(add(c, mul(along, -len * 0.5)), mul(across, -wide * 0.8));
    out.line(tip0, q0, 1.1, dry);
    out.line(q0, side0, 1.1, dry);
    out.line(side0, q1, 1.1, dry);
    out.line(q1, tip1, 1.1, dry);
    out.line(tip1, q2, 1.1, dry);
    out.line(q2, side1, 1.1, dry);
    out.line(side1, q3, 1.1, dry);
    out.line(q3, tip0, 1.1, dry);
    out.line(tip0, tip1, 0.9, rib);
    out.tri(tip0, q0, q3);
    out.tri(q0, q1, q2);
    out.tri(q0, q2, q3);
    out.tri(q1, tip1, q2);
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
        .leaves => {
            // last year's leaves: one to every six metres square, so close by and coarser far off
            const cells_per: i32 = if (near) 1 else 2;
            const span: f32 = size / 6.0;
            const n_side: i32 = @max(1, @as(i32, @intFromFloat(@ceil(span))));
            var a: i32 = 0;
            while (a < n_side) : (a += cells_per) {
                var b: i32 = 0;
                while (b < n_side) : (b += cells_per) {
                    const lx = @as(i32, @intFromFloat(@floor(@as(f32, @floatFromInt(ix)) * size / 6.0))) + a;
                    const lz = @as(i32, @intFromFloat(@floor(@as(f32, @floatFromInt(iz)) * size / 6.0))) + b;
                    fallenLeaf(lx, lz, out);
                }
            }
        },
        // a puddle's water is drawn by its own (poolLines): nothing grows in it
        .water => {},
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

/// The sun (spec/sky.md): not a disc but a figure of light, drawn as its note against home. With
/// home on the day's own note it is a plain ring. It rises on the shore and climbs the horn.
pub fn sun(w: *const world_mod.World, eye: V, out: []Inst) usize {
    if (w.dawnAge() < 0.0 or w.stand < 0.3) return 0;
    const p = w.sunPlace();
    const dx = p[0] - eye[0];
    const dz = p[2] - eye[2];
    const len = @max(@sqrt(dx * dx + dz * dz), 1.0);
    const side = V{ -dz / len, 0.0, dx / len };
    const tint = col8(colour.ofNote(world_mod.garden_hz, world_mod.garden_hz), 1.0);
    var n: usize = 0;
    const radii = [2]f32{ 30.0, 19.0 };
    for (radii) |r| {
        for (0..32) |k| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 32.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 32.0);
            out[n] = .{
                .a = add(add(V{ p[0], p[1] + r, p[2] }, mul(side, r * @cos(a0))), V{ 0.0, r * @sin(a0), 0.0 }),
                .b = add(add(V{ p[0], p[1] + r, p[2] }, mul(side, r * @cos(a1))), V{ 0.0, r * @sin(a1), 0.0 }),
                .half_width = -1.8,
                .body = day_body,
                .col = tint,
            };
            n += 1;
        }
    }
    return n;
}

/// The horn (spec/sky.md): over the lake, a ring of light for each of the sun's overtones, at
/// 100 m an octave, each as wide as the shore's radius over its number. Each of the first sixteen
/// is a thing of the world, in the hue of its note, and shines as loud as the sun holds it.
/// Above them a ring every octave narrows to a thread, lit by the day.
pub fn horn(w: *const world_mod.World, out: []Inst) usize {
    if (w.rung_first == world_mod.no_thing) return 0;
    var n: usize = 0;
    var k: u32 = 1;
    while (k <= world_mod.rungs) : (k += 1) {
        const r = world_mod.rungRadius(k);
        const h = world_mod.rungHeight(k);
        const hz = world_mod.sun_hz * @as(f32, @floatFromInt(k));
        // a note more than a fifth of a half step from the wheel's has no hue
        const steps = 12.0 * @log2(hz / world_mod.garden_hz);
        const on_wheel = @abs(steps - @round(steps)) <= 0.2;
        const tint = if (on_wheel) colour.ofNote(world_mod.garden_hz, hz) else chrome;
        // red is only ever a thin line (design/look.md)
        const red = on_wheel and colour.fifthsFrom(world_mod.garden_hz, hz) == 4;
        const width: f32 = if (red or k == 1) 0.9 else 1.9;
        const parts: usize = if (k <= 2) 160 else if (k <= 6) 112 else 72;
        const body: f32 = @floatFromInt(thing_body + w.rung_first + k - 1);
        for (0..parts) |j| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(j)) * (6.2831853 / @as(f32, @floatFromInt(parts)));
            const a1 = @as(f32, @floatFromInt(j + 1)) * (6.2831853 / @as(f32, @floatFromInt(parts)));
            out[n] = .{
                .a = .{ world_mod.lake_x + r * @cos(a0), h, world_mod.lake_z + r * @sin(a0) },
                .b = .{ world_mod.lake_x + r * @cos(a1), h, world_mod.lake_z + r * @sin(a1) },
                // a width below nought: the sky is not hazed by distance
                .half_width = -width,
                .body = body,
                .col = col8(tint, 1.0),
            };
            n += 1;
        }
    }
    // Above rung sixteen the thread is dark until someone sings up it (spec/sky.md): nothing is
    // drawn there, since silence is dark.
    return n;
}

/// The stars (spec/sky.md): star n is the land n pure fifths from the Garden, set round the
/// horizon by the fifth's own turn of the octave and higher the farther out it is. Each is in its
/// land's colour and twinkles at its land's note eight octaves down. They fade as the day fills
/// the sky.
pub fn stars(w: *const world_mod.World, eye: V, out: []Inst) usize {
    const night = 1.0 - w.skyLevel();
    if (night <= 0.01 or w.stand < 0.3) return 0;
    const seconds = @as(f32, @floatFromInt(w.step)) * world_mod.dt;
    const base = std.math.atan2(world_mod.lake_z, world_mod.lake_x);
    var n: usize = 0;
    var k: u32 = 12;
    while (k < 665) : (k += 1) {
        if (n >= out.len) return n;
        const kf: f32 = @floatFromInt(k);
        // the fifth is 0.585 of an octave: 210.59 degrees of the horizon
        const turn = kf * 0.5849625;
        const az = base + (turn - @floor(turn)) * 6.2831853;
        const from_top = 1.5707963 * @sqrt(1.0 - kf / 665.0);
        const up = 1.5707963 - from_top;
        const far: f32 = 6000.0;
        const p = V{ eye[0] + far * @cos(up) * @cos(az), eye[1] + far * @sin(up), eye[2] + far * @cos(up) * @sin(az) };
        // its land's note, folded into the garden's octave
        const ratio = std.math.pow(f32, 1.5, @floatFromInt(k % 12));
        const folded = world_mod.garden_hz * ratio / std.math.pow(f32, 2.0, @floor(@log2(ratio)));
        const beat = 0.55 + 0.45 * @cos(seconds * folded * (6.2831853 / 256.0) + kf);
        out[n] = .{ .a = p, .b = .{ p[0], p[1] + 14.0, p[2] }, .half_width = -1.2, .body = 0.0, .col = col8(colour.ofNote(world_mod.garden_hz, folded), night * beat * 0.8) };
        n += 1;
    }
    return n;
}

/// The dawn's edge: a line of the day's light running over the ground from where the sun rose,
/// at the speed of sound (spec/sky.md, "Dawn travels at the speed of sound").
pub fn dawnEdge(w: *const world_mod.World, out: []Inst) usize {
    const age = w.dawnAge();
    if (age < 0.0 or w.stand < 0.5) return 0;
    const reach = age * world_mod.sound_speed;
    if (reach > 2600.0) return 0;
    const fade = 1.0 - reach / 2600.0;
    const tint = col8(colour.ofNote(world_mod.garden_hz, world_mod.garden_hz), 0.75 * fade);
    const parts = 180;
    var n: usize = 0;
    for (0..parts) |j| {
        if (n >= out.len) return n;
        const a0 = @as(f32, @floatFromInt(j)) * (6.2831853 / @as(f32, parts));
        const a1 = @as(f32, @floatFromInt(j + 1)) * (6.2831853 / @as(f32, parts));
        out[n] = .{
            .a = .{ w.sun_x + reach * @cos(a0), 0.06, w.sun_z + reach * @sin(a0) },
            .b = .{ w.sun_x + reach * @cos(a1), 0.06, w.sun_z + reach * @sin(a1) },
            .half_width = 2.2,
            .body = 0.0,
            .col = tint,
        };
        n += 1;
    }
    return n;
}

/// Sparks: the light of a small thing that sounded where it is, a drop of dew landing or a leaf
/// stepped on, in its note's colour, fading as it rings (world.Spark).
pub fn sparks(w: *const world_mod.World, out: []Inst) usize {
    var n: usize = 0;
    for (w.sparks) |spark| {
        if (!spark.live) continue;
        const age = @as(f32, @floatFromInt(w.step - spark.born)) * world_mod.dt;
        const level = spark.bright * @exp(-age * 2.3 / spark.fades);
        if (level < 0.02) continue;
        const tint = col8(colour.ofNote(world_mod.garden_hz, spark.hz), level);
        const r = 0.25 + 0.5 * level;
        const c = V{ spark.x, spark.y + 0.1, spark.z };
        for (0..6) |k| {
            if (n >= out.len) return n;
            const ang = @as(f32, @floatFromInt(k)) * (6.2831853 / 6.0);
            const ray = V{ @cos(ang) * r, @sin(ang) * r * 0.6, @sin(ang) * r * 0.4 };
            out[n] = .{ .a = add(c, mul(ray, 0.3)), .b = add(c, ray), .half_width = 1.3, .body = 0.0, .col = tint };
            n += 1;
        }
    }
    return n;
}

/// The bee (world/flyers.zig): a body as long as Hum, in its note's colour and as bright as it
/// hums; hovering, its wingtips draw figures of eight, as a real hoverer's do; flying, its wings
/// are a blur and its path a fading line behind it.
pub fn beeLines(w: *const world_mod.World, out: []Inst) usize {
    const b = w.bee;
    if (b.thing == world_mod.no_thing or !b.flying) return 0;
    const me = w.things[b.thing];
    const body: f32 = @floatFromInt(thing_body + b.thing);
    const tint = colour.ofNote(world_mod.garden_hz, me.hz);
    const c = V{ me.x, me.y, me.z };
    const speed = @sqrt(b.vel[0] * b.vel[0] + b.vel[2] * b.vel[2]);
    const along = if (speed > 0.5) V{ b.vel[0] / speed, 0.0, b.vel[2] / speed } else V{ 1.0, 0.0, 0.0 };
    const side = V{ -along[2], 0.0, along[0] };
    var n: usize = 0;
    // the body
    for (0..10) |k| {
        if (n >= out.len) return n;
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
        out[n] = .{
            .a = add(add(c, mul(along, 0.65 * @cos(a0))), V{ 0.0, 0.3 * @sin(a0), 0.0 }),
            .b = add(add(c, mul(along, 0.65 * @cos(a1))), V{ 0.0, 0.3 * @sin(a1), 0.0 }),
            .half_width = 1.6,
            .body = body,
            .col = col8(tint, 1.0),
        };
        n += 1;
    }
    if (b.hover_left > 0) {
        // two figures of eight, one each side
        for ([2]f32{ 1.0, -1.0 }) |sgn| {
            const root = add(c, mul(side, 0.25 * sgn));
            for (0..16) |k| {
                if (n >= out.len) return n;
                const t0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 16.0);
                const t1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 16.0);
                const p0 = add(add(root, mul(side, sgn * 0.9 * (0.5 + 0.5 * @cos(t0)))), add(mul(along, 0.5 * @sin(2.0 * t0) * 0.5), V{ 0.0, 0.2 * @sin(t0), 0.0 }));
                const p1 = add(add(root, mul(side, sgn * 0.9 * (0.5 + 0.5 * @cos(t1)))), add(mul(along, 0.5 * @sin(2.0 * t1) * 0.5), V{ 0.0, 0.2 * @sin(t1), 0.0 }));
                out[n] = .{ .a = p0, .b = p1, .half_width = 1.0, .body = body, .col = col8(tint, 0.6) };
                n += 1;
            }
        }
    } else {
        // wings as a blur, and its path behind it
        for ([2]f32{ 1.0, -1.0 }) |sgn| {
            if (n >= out.len) return n;
            out[n] = .{ .a = add(c, mul(side, 0.2 * sgn)), .b = add(add(c, mul(side, 1.0 * sgn)), V{ 0.0, 0.25, 0.0 }), .half_width = 1.2, .body = body, .col = col8(tint, 0.45) };
            n += 1;
        }
        for (0..6) |k| {
            if (n >= out.len) return n;
            const k0: f32 = @floatFromInt(k);
            out[n] = .{
                .a = add(c, mul(along, -1.6 * k0 - 0.7)),
                .b = add(c, mul(along, -1.6 * (k0 + 1.0) - 0.7)),
                .half_width = 1.0,
                .body = body,
                .col = col8(tint, 0.5 * (1.0 - k0 / 6.0)),
            };
            n += 1;
        }
    }
    return n;
}

/// The puddles (world/pools.zig). Still water is black, with only its edge drawn. A shape standing
/// in it draws its still lines in the colour of its note, as bright as it is loud (law 4); between
/// them the water heaves, drawn as a net of lines on the surface rising and falling at the note
/// eight octaves down and lit as much as it moves; and the pollen floating on it, thrown onto the
/// still lines, draws the figure again in gold and keeps it when the water stills.
pub fn poolLines(w: *const world_mod.World, eye: V, out: []Inst) usize {
    const pools = world_mod.pools;
    var n: usize = 0;
    const water = [3]f32{ 0.55, 0.75, 0.92 };
    const pollen = [3]f32{ 1.0, 0.82, 0.38 };
    const seconds: f64 = @as(f64, @floatFromInt(w.step)) * (1.0 / 60.0);
    for (w.pools[0..w.pool_count]) |*p| {
        const body: f32 = @floatFromInt(thing_body + p.thing);
        const ex = eye[0] - p.x;
        const ez = eye[2] - p.z;
        const eye_far = @sqrt(ex * ex + ez * ez);
        // the water's edge, a still line of its own
        const rim_n: usize = 96;
        for (0..rim_n) |k| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, @floatFromInt(rim_n)));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, @floatFromInt(rim_n)));
            out[n] = .{ .a = .{ p.x + p.r * @cos(a0), 0.06, p.z + p.r * @sin(a0) }, .b = .{ p.x + p.r * @cos(a1), 0.06, p.z + p.r * @sin(a1) }, .half_width = 1.3, .body = body, .col = col8(water, 0.45) };
            n += 1;
        }
        // where each figure is in its heave, as a sine of its slowed note
        var swing: [2]f32 = .{ 0.0, 0.0 };
        for (p.figs, 0..) |f, k| {
            if (f.loud <= 0.0) continue;
            const turns = @mod(seconds * @as(f64, f.hz) / @as(f64, pools.heave_octaves), 1.0);
            swing[k] = @sin(@as(f32, @floatCast(turns)) * 6.2831853);
        }
        // the still lines of each standing shape
        for (p.figs) |f| {
            if (f.loud < 0.03) continue;
            const md = pools.modes[f.mode];
            const tint = col8(colour.ofNote(world_mod.garden_hz, f.hz), @min(1.0, f.loud * 1.3));
            var k: u32 = 0;
            while (k < md.m) : (k += 1) {
                // a still diameter halfway between two bellies
                const a = (@as(f32, @floatFromInt(k)) + 0.5) * std.math.pi / @as(f32, @floatFromInt(md.m));
                const ca = @cos(a);
                const sa = @sin(a);
                const dx = f.turn_c * ca - f.turn_s * sa;
                const dz = f.turn_s * ca + f.turn_c * sa;
                for (0..24) |s| {
                    if (n >= out.len) return n;
                    const f0 = -1.0 + 2.0 * @as(f32, @floatFromInt(s)) / 24.0;
                    const f1 = -1.0 + 2.0 * @as(f32, @floatFromInt(s + 1)) / 24.0;
                    out[n] = .{ .a = .{ p.x + dx * p.r * f0, 0.15, p.z + dz * p.r * f0 }, .b = .{ p.x + dx * p.r * f1, 0.15, p.z + dz * p.r * f1 }, .half_width = 2.0, .body = 0.0, .col = tint };
                    n += 1;
                }
            }
            var i: u32 = 0;
            while (i + 1 < md.n) : (i += 1) {
                const rr = p.r * pools.zeros[md.m][i] / md.j;
                for (0..96) |s| {
                    if (n >= out.len) return n;
                    const a0 = @as(f32, @floatFromInt(s)) * (6.2831853 / 96.0);
                    const a1 = @as(f32, @floatFromInt(s + 1)) * (6.2831853 / 96.0);
                    out[n] = .{ .a = .{ p.x + rr * @cos(a0), 0.15, p.z + rr * @sin(a0) }, .b = .{ p.x + rr * @cos(a1), 0.15, p.z + rr * @sin(a1) }, .half_width = 2.0, .body = 0.0, .col = tint };
                    n += 1;
                }
            }
        }
        // the heaving water: a net of rings and spokes over the surface, each crossing as high as
        // the water there is in its heave, lit as much as the water there moves
        if (p.loud() > 0.01 and eye_far < p.r * 3.0 + 400.0) {
            const rings_n = 16;
            const around = 96;
            var heave: [rings_n + 1][around]f32 = undefined;
            var moves: [rings_n + 1][around]f32 = undefined;
            var px: [rings_n + 1][around]f32 = undefined;
            var pz: [rings_n + 1][around]f32 = undefined;
            for (0..rings_n + 1) |ri| {
                const rr = p.r * @as(f32, @floatFromInt(ri)) / @as(f32, rings_n);
                for (0..around) |ai| {
                    const ang = @as(f32, @floatFromInt(ai)) * (6.2831853 / @as(f32, around));
                    const dx = rr * @cos(ang);
                    const dz = rr * @sin(ang);
                    var h: f32 = 0.0;
                    var e: f32 = 0.0;
                    for (p.figs, 0..) |f, k| {
                        if (f.loud <= 0.0) continue;
                        const s = f.shape(dx, dz, p.r) * f.loud;
                        h += s * swing[k];
                        e += s * s;
                    }
                    heave[ri][ai] = h * pools.heave_m;
                    moves[ri][ai] = @sqrt(e);
                    px[ri][ai] = p.x + dx;
                    pz[ri][ai] = p.z + dz;
                }
            }
            // a lobe on its way up catches the light and one on its way down goes dark, so the
            // heaving is seen even in a single frame: lit and dark lobes, changing places
            const lift = 1.0 / pools.heave_m;
            for (1..rings_n) |ri| {
                for (0..around) |ai| {
                    const bi = (ai + 1) % around;
                    const m = @max(moves[ri][ai], moves[ri][bi]);
                    if (m < 0.04) continue;
                    if (n >= out.len) return n;
                    const up = @max(0.0, (heave[ri][ai] + heave[ri][bi]) * 0.5 * lift);
                    out[n] = .{ .a = .{ px[ri][ai], 0.1 + heave[ri][ai], pz[ri][ai] }, .b = .{ px[ri][bi], 0.1 + heave[ri][bi], pz[ri][bi] }, .half_width = 1.0, .body = 0.0, .col = col8(water, 0.04 + 0.16 * m + 0.62 * up) };
                    n += 1;
                }
            }
            var ai: usize = 0;
            while (ai < around) : (ai += 2) {
                for (0..rings_n) |ri| {
                    const m = @max(moves[ri][ai], moves[ri + 1][ai]);
                    if (m < 0.04) continue;
                    if (n >= out.len) return n;
                    const up = @max(0.0, (heave[ri][ai] + heave[ri + 1][ai]) * 0.5 * lift);
                    out[n] = .{ .a = .{ px[ri][ai], 0.1 + heave[ri][ai], pz[ri][ai] }, .b = .{ px[ri + 1][ai], 0.1 + heave[ri + 1][ai], pz[ri + 1][ai] }, .half_width = 1.0, .body = 0.0, .col = col8(water, 0.04 + 0.16 * m + 0.62 * up) };
                    n += 1;
                }
            }
        }
        // the pollen, riding the surface
        if (eye_far < p.r * 2.0 + 300.0) {
            for (0..p.motes) |i| {
                if (n >= out.len) return n;
                const mx = p.mote_x[i];
                const mz = p.mote_z[i];
                var h: f32 = 0.0;
                for (p.figs, 0..) |f, k| {
                    if (f.loud <= 0.0) continue;
                    h += f.shape(mx, mz, p.r) * f.loud * swing[k];
                }
                const turn = @as(f32, @floatFromInt((i *% 2654435761) % 628)) * 0.01;
                const half = 0.22;
                const y = 0.2 + h * pools.heave_m;
                out[n] = .{ .a = .{ p.x + mx - @cos(turn) * half, y, p.z + mz - @sin(turn) * half }, .b = .{ p.x + mx + @cos(turn) * half, y, p.z + mz + @sin(turn) * half }, .half_width = 2.4, .body = 0.0, .col = col8(pollen, 0.8) };
                n += 1;
            }
        }
    }
    return n;
}
