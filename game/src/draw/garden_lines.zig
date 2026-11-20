//! The Garden's own things as lines of light (scores/garden.txt; spec/world.md 1; SPEC.md 6.1), made
//! once and picked by how far the eye is, as the asters are: the hose, a green tube a door's height
//! across, from the spigot down across the garden to its coiled end in the reeds; the spigot, ten
//! metres of brass on the rise at the back; the reeds round the Mirror Pool, as tall as towers; and
//! the pool's still edge.
//!
//! What stands near Hum takes the body of the sixteen-metre square of ground it stands in, so a
//! call's ring that crosses the ground shows it too: in the dark, the first call shows reeds and a
//! coiled hose. Farther off, it shines with the day.
const std = @import("std");
const lines = @import("lines.zig");
const aster_lines = @import("aster_lines.zig");
const world_mod = @import("../world/world.zig");
const land = world_mod.land;
const hose = world_mod.hose;
const Inst = lines.Inst;
const V = [3]f32;

pub const near_within: f32 = 230.0;
pub const mid_within: f32 = 750.0;

const max_models = 96;
const near_cap = 900;
const mid_cap = 260;
const far_cap = 80;

const Model = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    near: [near_cap]Inst = undefined,
    near_n: usize = 0,
    mid: [mid_cap]Inst = undefined,
    mid_n: usize = 0,
    far: [far_cap]Inst = undefined,
    far_n: usize = 0,

    fn add(list: []Inst, n: *usize, a: V, b: V, half: f32, col: [4]u8) void {
        if (n.* >= list.len) return;
        list[n.*] = .{ .a = a, .b = b, .half_width = half, .body = aster_lines.day_body, .col = col };
        n.* += 1;
    }
    fn nearLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.near, &self.near_n, a, b, half, col);
    }
    fn midLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.mid, &self.mid_n, a, b, half, col);
    }
    fn farLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.far, &self.far_n, a, b, half, col);
    }
};

var models: [max_models]Model = undefined;
var model_n: usize = 0;

fn col8(rgb: [3]f32, alpha: f32) [4]u8 {
    return .{
        @intFromFloat(std.math.clamp(rgb[0], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[1], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[2], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(alpha, 0.0, 1.0) * 255.0),
    };
}

const green = [3]f32{ 0.30, 0.80, 0.42 };
const brass = [3]f32{ 0.92, 0.72, 0.30 };
const straw = [3]f32{ 0.72, 0.76, 0.50 };
const plume = [3]f32{ 0.84, 0.70, 0.50 };
const still = [3]f32{ 0.36, 0.52, 0.72 };

fn hash(a: u32, b: u32) u32 {
    var h = a *% 0x9e37_79b9 +% b *% 0x85eb_ca6b;
    h ^= h >> 16;
    h *%= 0x7feb_352d;
    h ^= h >> 15;
    return h;
}

fn unit(s: u32) f32 {
    return @as(f32, @floatFromInt(s >> 8)) * (1.0 / 16777216.0);
}

fn newModel(x: f32, z: f32) *Model {
    const m = &models[model_n];
    m.* = .{ .x = x, .z = z };
    model_n += 1;
    return m;
}

/// The hose: a tube along its curve, a side at either hand and its top, ribbed every few metres
/// near; its top and one side farther off; its top far away. In pieces of twenty-four points.
fn buildHose() void {
    const rb = land.hose_bore * 0.5;
    const piece = 24;
    var start: usize = 0;
    while (start + 1 < hose.count) : (start += piece) {
        const end = @min(start + piece, hose.count - 1);
        const mid_i = (start + end) / 2;
        const m = newModel(hose.path[mid_i][0], hose.path[mid_i][1]);
        var i = start;
        while (i < end) : (i += 1) {
            const p = hose.path[i];
            const q = hose.path[i + 1];
            const tx = q[0] - p[0];
            const tz = q[1] - p[1];
            const tl = @max(@sqrt(tx * tx + tz * tz), 0.001);
            const nx = -tz / tl * rb;
            const nz = tx / tl * rb;
            const top_a = V{ p[0], 2.0 * rb, p[1] };
            const top_b = V{ q[0], 2.0 * rb, q[1] };
            m.nearLine(top_a, top_b, 1.3, col8(green, 0.7));
            m.nearLine(.{ p[0] + nx, rb, p[1] + nz }, .{ q[0] + nx, rb, q[1] + nz }, 1.1, col8(green, 0.45));
            m.nearLine(.{ p[0] - nx, rb, p[1] - nz }, .{ q[0] - nx, rb, q[1] - nz }, 1.1, col8(green, 0.45));
            if (i % 4 == 0) {
                // a rib over the top, side to side
                var k: usize = 0;
                while (k < 5) : (k += 1) {
                    const a0 = @as(f32, @floatFromInt(k)) * (std.math.pi / 5.0);
                    const a1 = @as(f32, @floatFromInt(k + 1)) * (std.math.pi / 5.0);
                    m.nearLine(.{ p[0] + nx * @cos(a0), rb + rb * @sin(a0), p[1] + nz * @cos(a0) }, .{ p[0] + nx * @cos(a1), rb + rb * @sin(a1), p[1] + nz * @cos(a1) }, 1.0, col8(green, 0.45));
                }
            }
            m.midLine(top_a, top_b, 1.2, col8(green, 0.5));
            m.midLine(.{ p[0] + nx, rb, p[1] + nz }, .{ q[0] + nx, rb, q[1] + nz }, 1.0, col8(green, 0.3));
            if (i % 3 == 0 or i + 1 == end) {
                const r = @min(i + 3, end);
                m.farLine(top_a, .{ hose.path[r][0], 2.0 * rb, hose.path[r][1] }, 1.3, col8(green, 0.45));
            }
        }
    }
    // the coil at its end, in the reeds: two turns lying on the ground beside its mouth
    const mouth = hose.path[hose.count - 1];
    const m = newModel(mouth[0] - 6.0, mouth[1] + 4.0);
    const turns = 2.0;
    const parts = 40;
    var k: usize = 0;
    while (k < parts) : (k += 1) {
        const t0 = @as(f32, @floatFromInt(k)) / @as(f32, parts);
        const t1 = @as(f32, @floatFromInt(k + 1)) / @as(f32, parts);
        const a0 = t0 * turns * 2.0 * std.math.pi;
        const a1 = t1 * turns * 2.0 * std.math.pi;
        const r0 = 6.5 - 3.0 * t0;
        const r1 = 6.5 - 3.0 * t1;
        const cx = mouth[0] - 7.0;
        const cz = mouth[1] + 5.0;
        const a = V{ cx + r0 * @cos(a0), 2.0 * rb, cz + r0 * @sin(a0) };
        const b = V{ cx + r1 * @cos(a1), 2.0 * rb, cz + r1 * @sin(a1) };
        m.nearLine(a, b, 1.4, col8(green, 0.85));
        m.nearLine(.{ a[0], rb * 0.3, a[2] }, .{ b[0], rb * 0.3, b[2] }, 1.1, col8(green, 0.5));
        m.midLine(a, b, 1.3, col8(green, 0.7));
        if (k % 4 == 0) m.farLine(a, b, 1.5, col8(green, 0.6));
    }
}

/// The spigot: a riser of brass from the ground, its body, a handle like a wheel on top, and a spout
/// bent down to where the hose is screwed on.
fn buildSpigot() void {
    const x = land.spigot[0];
    const z = land.spigot[1];
    const tall = land.spigot[2];
    const m = newModel(x, z);
    const rr: f32 = 0.9;
    const sides = 8;
    // the riser, a pipe
    for (0..sides) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, sides));
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, sides));
        const p = V{ x + rr * @cos(a0), 0.0, z + rr * @sin(a0) };
        m.nearLine(p, .{ p[0], tall * 0.7, p[2] }, 1.2, col8(brass, 0.7));
        for ([_]f32{ 0.0, tall * 0.35, tall * 0.7 }) |y| m.nearLine(.{ x + rr * @cos(a0), y, z + rr * @sin(a0) }, .{ x + rr * @cos(a1), y, z + rr * @sin(a1) }, 1.0, col8(brass, 0.55));
    }
    // the body, wider
    const rb2: f32 = 1.7;
    for (0..sides) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, sides));
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, sides));
        for ([_]f32{ tall * 0.7, tall * 0.86 }) |y| m.nearLine(.{ x + rb2 * @cos(a0), y, z + rb2 * @sin(a0) }, .{ x + rb2 * @cos(a1), y, z + rb2 * @sin(a1) }, 1.3, col8(brass, 0.85));
        m.nearLine(.{ x + rb2 * @cos(a0), tall * 0.7, z + rb2 * @sin(a0) }, .{ x + rb2 * @cos(a0), tall * 0.86, z + rb2 * @sin(a0) }, 1.1, col8(brass, 0.7));
    }
    // the handle: a wheel with four spokes, on a stem
    m.nearLine(.{ x, tall * 0.86, z }, .{ x, tall * 0.95, z }, 1.3, col8(brass, 0.9));
    const rh: f32 = 1.6;
    for (0..12) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / 12.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / 12.0);
        m.nearLine(.{ x + rh * @cos(a0), tall, z + rh * @sin(a0) }, .{ x + rh * @cos(a1), tall, z + rh * @sin(a1) }, 1.4, col8(brass, 0.95));
        if (k % 3 == 0) m.nearLine(.{ x, tall * 0.95, z }, .{ x + rh * @cos(a0), tall, z + rh * @sin(a0) }, 1.1, col8(brass, 0.75));
    }
    // the spout: out toward the hose's first stretch, then down to where the hose begins
    const p1 = hose.path[1];
    const ox = p1[0] - x;
    const oz = p1[1] - z;
    const ol = @max(@sqrt(ox * ox + oz * oz), 0.001);
    const sx = x + ox / ol * 3.0;
    const sz = z + oz / ol * 3.0;
    m.nearLine(.{ x, tall * 0.78, z }, .{ sx, tall * 0.78, sz }, 1.5, col8(brass, 0.9));
    m.nearLine(.{ sx, tall * 0.78, sz }, .{ sx, tall * 0.45, sz }, 1.5, col8(brass, 0.9));
    // the hose from the spout down to the ground
    m.nearLine(.{ sx, tall * 0.45, sz }, .{ hose.path[2][0], land.hose_bore, hose.path[2][1] }, 1.4, col8(green, 0.85));
    // farther off: the riser, the body and the wheel as a few strokes
    m.midLine(.{ x, 0.0, z }, .{ x, tall, z }, 1.8, col8(brass, 0.9));
    m.midLine(.{ x - rh, tall, z }, .{ x + rh, tall, z }, 1.6, col8(brass, 0.9));
    m.midLine(.{ x, tall * 0.78, z }, .{ sx, tall * 0.45, sz }, 1.6, col8(brass, 0.85));
    m.farLine(.{ x, 0.0, z }, .{ x, tall, z }, 2.0, col8(brass, 0.9));
}

/// The reeds round the Mirror Pool, as tall as towers: each a stalk leaning a little, with its
/// plume of seed at the top and, near, two long leaves from its foot. Grouped by where round the
/// pool they stand.
fn buildReeds() void {
    const px = land.pool[0];
    const pz = land.pool[1];
    const r0 = land.pool[2];
    const band = land.pool[3];
    const groups = 24;
    const each = 11;
    for (0..groups) |g| {
        const ga = (@as(f32, @floatFromInt(g)) + 0.5) * (2.0 * std.math.pi / @as(f32, groups));
        const m = newModel(px + (r0 + band * 0.5) * @cos(ga), pz + (r0 + band * 0.5) * @sin(ga));
        for (0..each) |k| {
            const s = hash(@intCast(g), @intCast(k));
            const a = (@as(f32, @floatFromInt(g)) + unit(s)) * (2.0 * std.math.pi / @as(f32, groups));
            const r = r0 + band * unit(s *% 2654435761);
            const x = px + r * @cos(a);
            const z = pz + r * @sin(a);
            // none where Hum wakes, at Drip's clearing, or on the hose
            const wx = x - land.wake[0];
            const wz = z - land.wake[1];
            const cx = x - land.clear[0];
            const cz = z - land.clear[1];
            if (wx * wx + wz * wz < 7.0 * 7.0 or cx * cx + cz * cz < 8.0 * 8.0) continue;
            if (hose.distance(x, z) < 4.0) continue;
            const tall = 60.0 + 90.0 * unit(s *% 40503);
            const lean_a = unit(s *% 69069) * 2.0 * std.math.pi;
            const lean = tall * (0.03 + 0.06 * unit(s *% 362437));
            const top = V{ x + @cos(lean_a) * lean, tall, z + @sin(lean_a) * lean };
            const foot = V{ x, 0.0, z };
            const midp = V{ (foot[0] + top[0]) * 0.5 + @cos(lean_a) * lean * 0.15, tall * 0.5, (foot[2] + top[2]) * 0.5 + @sin(lean_a) * lean * 0.15 };
            m.nearLine(foot, midp, 1.2, col8(straw, 0.75));
            m.nearLine(midp, top, 1.1, col8(straw, 0.7));
            // the plume: seeds hanging from the top
            for (0..5) |f| {
                const fa = lean_a + (@as(f32, @floatFromInt(f)) - 2.0) * 0.45;
                const fl = 4.0 + 5.0 * unit(s *% @as(u32, @intCast(f + 7)));
                m.nearLine(top, .{ top[0] + @cos(fa) * fl * 0.6, top[1] - fl, top[2] + @sin(fa) * fl * 0.6 }, 1.0, col8(plume, 0.7));
            }
            // two long leaves from its foot
            for (0..2) |f| {
                const la = lean_a + 1.6 + @as(f32, @floatFromInt(f)) * 3.0;
                const ll = tall * (0.18 + 0.1 * unit(s *% @as(u32, @intCast(f + 11))));
                const bend = V{ x + @cos(la) * ll * 0.35, ll * 0.7, z + @sin(la) * ll * 0.35 };
                const tip = V{ x + @cos(la) * ll * 0.8, ll * 0.45, z + @sin(la) * ll * 0.8 };
                m.nearLine(.{ x, ll * 0.05, z }, bend, 1.0, col8(straw, 0.5));
                m.nearLine(bend, tip, 0.9, col8(straw, 0.45));
            }
            m.midLine(foot, top, 1.2, col8(straw, 0.7));
            m.midLine(top, .{ top[0] + @cos(lean_a) * 3.0, top[1] - 6.0, top[2] + @sin(lean_a) * 3.0 }, 1.1, col8(plume, 0.65));
            if (k % 2 == 0) m.farLine(foot, top, 1.4, col8(straw, 0.6));
        }
        // the pool's still edge under this group's reeds: a faint line on the water's rim
        const arc = 8;
        for (0..arc) |k| {
            const a0 = (@as(f32, @floatFromInt(g)) + @as(f32, @floatFromInt(k)) / @as(f32, arc)) * (2.0 * std.math.pi / @as(f32, groups));
            const a1 = (@as(f32, @floatFromInt(g)) + @as(f32, @floatFromInt(k + 1)) / @as(f32, arc)) * (2.0 * std.math.pi / @as(f32, groups));
            const a = V{ px + r0 * @cos(a0), 0.05, pz + r0 * @sin(a0) };
            const b = V{ px + r0 * @cos(a1), 0.05, pz + r0 * @sin(a1) };
            m.nearLine(a, b, 1.2, col8(still, 0.4));
            m.midLine(a, b, 1.1, col8(still, 0.3));
        }
    }
}

/// Make every one of the Garden's own things, once.
pub fn build() void {
    model_n = 0;
    buildHose();
    buildSpigot();
    buildReeds();
}

/// The Garden's own things for where the eye is now, each at the detail its distance asks for.
/// What stands within the squares of ground round Hum (`grid`, their corner, from
/// aster_lines.ground) takes that square's body, so a call's ring lights it as it crosses.
pub fn pick(eye_x: f32, eye_z: f32, grid: [2]i32, out: []Inst) usize {
    var n: usize = 0;
    for (models[0..model_n]) |*m| {
        const dx = m.x - eye_x;
        const dz = m.z - eye_z;
        const far = @sqrt(dx * dx + dz * dz);
        const from: []const Inst = if (far < near_within) m.near[0..m.near_n] else if (far < mid_within) m.mid[0..m.mid_n] else m.far[0..m.far_n];
        if (n + from.len > out.len) continue;
        @memcpy(out[n..][0..from.len], from);
        if (far < near_within + 60.0) {
            for (out[n..][0..from.len]) |*l| {
                const cx: i32 = @intFromFloat(@floor((l.a[0] + l.b[0]) * 0.5 / 16.0));
                const cz: i32 = @intFromFloat(@floor((l.a[2] + l.b[2]) * 0.5 / 16.0));
                const ix = cx - grid[0];
                const iz = cz - grid[1];
                if (ix >= 0 and ix < aster_lines.cover_side and iz >= 0 and iz < aster_lines.cover_side) {
                    l.body = @floatFromInt(@as(i32, @intCast(aster_lines.cover_body)) + ix + iz * aster_lines.cover_side);
                }
            }
        }
        n += from.len;
    }
    return n;
}
