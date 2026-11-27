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
const feel = @import("../feel.zig");
const colour = @import("colour.zig");
const black = @import("black.zig");
const land = world_mod.land;
const hose = world_mod.hose;
const spigot = world_mod.spigot;
const form = world_mod.form;
const react = world_mod.react_mod;
const Inst = lines.Inst;
const V = [3]f32;

pub const near_within: f32 = 230.0;
pub const mid_within: f32 = 750.0;

const max_models = 96;
const near_cap = 900;
const mid_cap = 260;
const far_cap = 80;
/// The points of a model's black shapes, three to a triangle.
const occ_cap = 1300;

const Model = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    near: [near_cap]Inst = undefined,
    near_n: usize = 0,
    mid: [mid_cap]Inst = undefined,
    mid_n: usize = 0,
    far: [far_cap]Inst = undefined,
    far_n: usize = 0,
    /// Its black shapes, drawn while it is near: made from the same shapes that stop Hum.
    occ: [occ_cap]V = undefined,
    occ_tags: [occ_cap]lines.OccTag = @splat(lines.no_tag),
    occ_n: usize = 0,
    cell: u8 = lines.no_note,
    reacts: u8 = 0,

    fn of(self: *Model, cell: u8, reacts: u8) void {
        self.cell = cell;
        self.reacts = reacts;
    }

    /// Give the model the black shapes of what it is made of.
    fn hide(self: *Model, shapes: []const form.Shape) void {
        var tris = black.Tris{ .out = &self.occ, .n = self.occ_n, .tags = &self.occ_tags, .cell = self.cell, .reacts = self.reacts };
        black.ofAll(shapes, &tris);
        self.occ_n = tris.n;
        lost_black += tris.lost;
    }

    fn add(list: []Inst, n: *usize, a: V, b: V, half: f32, col: [4]u8, cell: u8, reacts: u8) void {
        if (n.* >= list.len) return;
        list[n.*] = .{ .a = a, .b = b, .half_width = half, .body = aster_lines.day_body, .col = col };
        list[n.*].tag(cell, reacts);
        n.* += 1;
    }
    fn nearLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.near, &self.near_n, a, b, half, col, self.cell, self.reacts);
    }
    fn midLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.mid, &self.mid_n, a, b, half, col, self.cell, self.reacts);
    }
    fn farLine(self: *Model, a: V, b: V, half: f32, col: [4]u8) void {
        add(&self.far, &self.far_n, a, b, half, col, self.cell, self.reacts);
    }
};

var models: [max_models]Model = undefined;
var model_n: usize = 0;
/// Black triangles that found no room in their model. Always nought (see the test).
pub var lost_black: usize = 0;

const col8 = colour.col8;

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
        var room: [64]form.Shape = undefined;
        var sink = form.Sink{ .out = &room };
        hose.shapes(start, end, &sink);
        m.hide(sink.slice());
    }
}

/// The spigot: a riser of brass from the ground, its body, a handle like a wheel on top, and a spout
/// bent down to where the hose is screwed on.
fn buildSpigot() void {
    const x = spigot.x;
    const z = spigot.z;
    const tall = spigot.tall;
    const m = newModel(x, z);
    const rr: f32 = spigot.riser;
    const sides = 8;
    // the riser, a pipe
    for (0..sides) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, sides));
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, sides));
        const p = V{ x + rr * @cos(a0), 0.0, z + rr * @sin(a0) };
        m.nearLine(p, .{ p[0], tall * spigot.riser_to, p[2] }, 1.2, col8(brass, 0.7));
        for ([_]f32{ 0.0, tall * spigot.riser_to * 0.5, tall * spigot.riser_to }) |y| m.nearLine(.{ x + rr * @cos(a0), y, z + rr * @sin(a0) }, .{ x + rr * @cos(a1), y, z + rr * @sin(a1) }, 1.0, col8(brass, 0.55));
    }
    // the body, wider
    const rb2: f32 = spigot.body;
    for (0..sides) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, sides));
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, sides));
        for ([_]f32{ tall * spigot.riser_to, tall * spigot.body_to }) |y| m.nearLine(.{ x + rb2 * @cos(a0), y, z + rb2 * @sin(a0) }, .{ x + rb2 * @cos(a1), y, z + rb2 * @sin(a1) }, 1.3, col8(brass, 0.85));
        m.nearLine(.{ x + rb2 * @cos(a0), tall * spigot.riser_to, z + rb2 * @sin(a0) }, .{ x + rb2 * @cos(a0), tall * spigot.body_to, z + rb2 * @sin(a0) }, 1.1, col8(brass, 0.7));
    }
    // the handle: a wheel with four spokes, on a stem
    m.nearLine(.{ x, tall * spigot.body_to, z }, .{ x, tall * spigot.stem_to, z }, 1.3, col8(brass, 0.9));
    const rh: f32 = spigot.wheel;
    for (0..12) |k| {
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / 12.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / 12.0);
        m.nearLine(.{ x + rh * @cos(a0), tall, z + rh * @sin(a0) }, .{ x + rh * @cos(a1), tall, z + rh * @sin(a1) }, 1.4, col8(brass, 0.95));
        if (k % 3 == 0) m.nearLine(.{ x, tall * spigot.stem_to, z }, .{ x + rh * @cos(a0), tall, z + rh * @sin(a0) }, 1.1, col8(brass, 0.75));
    }
    // the spout: out toward the hose's first stretch, then down to where the hose begins
    const spout_end = spigot.spoutEnd();
    const sx = spout_end[0];
    const sz = spout_end[1];
    m.nearLine(.{ x, tall * spigot.spout_at, z }, .{ sx, tall * spigot.spout_at, sz }, 1.5, col8(brass, 0.9));
    m.nearLine(.{ sx, tall * spigot.spout_at, sz }, .{ sx, tall * spigot.spout_down, sz }, 1.5, col8(brass, 0.9));
    // the hose from the spout down to the ground
    m.nearLine(.{ sx, tall * spigot.spout_down, sz }, .{ hose.path[2][0], land.hose_bore, hose.path[2][1] }, 1.4, col8(green, 0.85));
    // farther off: the riser, the body and the wheel as a few strokes
    m.midLine(.{ x, 0.0, z }, .{ x, tall, z }, 1.8, col8(brass, 0.9));
    m.midLine(.{ x - rh, tall, z }, .{ x + rh, tall, z }, 1.6, col8(brass, 0.9));
    m.midLine(.{ x, tall * spigot.spout_at, z }, .{ sx, tall * spigot.spout_down, sz }, 1.6, col8(brass, 0.85));
    m.farLine(.{ x, 0.0, z }, .{ x, tall, z }, 2.0, col8(brass, 0.9));
    var room: [8]form.Shape = undefined;
    var sink = form.Sink{ .out = &room };
    spigot.shapes(&sink);
    m.hide(sink.slice());
}

/// The reeds round the Mirror Pool, as tall as towers: each a stalk leaning a little, with its
/// plume of seed at the top and, near, two long leaves from its foot. Grouped by where round the
/// pool they stand.
fn buildReeds() void {
    const px = land.pool[0];
    const pz = land.pool[1];
    const r0 = land.pool[2];
    const band = land.pool[3];
    const groups = world_mod.reeds.groups;
    const each = world_mod.reeds.each;
    const reed_reacts = (react.Reacts{ .tilt = feel.reed_tilts }).byte();
    for (0..groups) |g| {
        const ga = (@as(f32, @floatFromInt(g)) + 0.5) * (2.0 * std.math.pi / @as(f32, groups));
        const m = newModel(px + (r0 + band * 0.5) * @cos(ga), pz + (r0 + band * 0.5) * @sin(ga));
        for (0..each) |k| {
            // where it stands and how it is made is the world's (world/reeds.zig): the stem the
            // world feels is the stem drawn
            const reed = world_mod.reeds.at(g, k) orelse continue;
            const hz = world_mod.reeds.note(reed.tall, world_mod.garden_hz);
            m.of(@intCast(colour.fifthsFrom(world_mod.garden_hz, hz)), reed_reacts);
            const s = reed.s;
            const x = reed.x;
            const z = reed.z;
            const tall = reed.tall;
            const lean_a = reed.lean_a;
            const line = world_mod.reeds.spine(reed);
            const foot = line[0];
            const top = line[2];
            // its stem, near: the edges of the very shapes that stop Hum and hide what is behind,
            // so the stem's own black shape never covers its lines
            var room: [2]form.Shape = undefined;
            var sink = form.Sink{ .out = &room };
            world_mod.reeds.shapes(reed, &sink);
            m.hide(sink.slice());
            for (sink.slice()) |shape| {
                const stem = shape.stalk;
                for (0..stem.sides()) |e| {
                    const ends = stem.edge(e);
                    m.nearLine(ends[0], ends[1], 1.0, col8(straw, 0.5));
                }
            }
            // the plume: seeds hanging from the top
            for (0..5) |f| {
                const fa = lean_a + (@as(f32, @floatFromInt(f)) - 2.0) * 0.45;
                const fl = 4.0 + 5.0 * unit(s *% @as(u32, @intCast(f + 7)));
                m.nearLine(top, .{ top[0] + @cos(fa) * fl * 0.6, top[1] - fl, top[2] + @sin(fa) * fl * 0.6 }, 1.0, col8(plume, 0.5));
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
            m.midLine(foot, top, 1.1, col8(straw, 0.5));
            m.midLine(top, .{ top[0] + @cos(lean_a) * 3.0, top[1] - 6.0, top[2] + @sin(lean_a) * 3.0 }, 1.0, col8(plume, 0.45));
            if (k % 2 == 0) m.farLine(foot, top, 1.3, col8(straw, 0.45));
        }
        // the pool's still edge under this group's reeds: a faint line on the water's rim
        m.of(lines.no_note, 0);
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

/// Stand every one of the Garden's own things on the ground (`height` at a place), once, after build.
pub fn liftModels(height: *const fn (f32, f32) f32) void {
    for (models[0..model_n]) |*md| {
        lines.lift(md.near[0..md.near_n], height);
        lines.lift(md.mid[0..md.mid_n], height);
        lines.lift(md.far[0..md.far_n], height);
        lines.liftPoints(md.occ[0..md.occ_n], height);
    }
}

/// The Garden's own things for where the eye is now, each at the detail its distance asks for.
/// What stands within the squares of ground round Hum (`grid`, their corner, from
/// aster_lines.ground) takes that square's body, so a call's ring lights it as it crosses. What is
/// near also gives its black shapes to `occ`.
pub fn pick(eye_x: f32, eye_z: f32, grid: [2]i32, out: []Inst, occ: *black.Tris) usize {
    var n: usize = 0;
    for (models[0..model_n]) |*m| {
        const dx = m.x - eye_x;
        const dz = m.z - eye_z;
        const far = @sqrt(dx * dx + dz * dz);
        if (far < near_within and occ.n + m.occ_n <= occ.out.len) {
            @memcpy(occ.out[occ.n..][0..m.occ_n], m.occ[0..m.occ_n]);
            if (occ.n + m.occ_n <= occ.tags.len) {
                @memcpy(occ.tags[occ.n..][0..m.occ_n], m.occ_tags[0..m.occ_n]);
            }
            occ.n += m.occ_n;
        }
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

const water = [3]f32{ 0.55, 0.82, 1.0 };
const figure_blue = [3]f32{ 0.42, 0.64, 1.0 };
const hum_green = [3]f32{ 0.70, 1.0, 0.75 };

/// The hose humming: along the stretch nearest Hum a glow that pulses at its note brought down eight
/// octaves, as every sound shines: slow and hollow while it is stopped, twice as quick sprung open.
pub fn humLines(w: *const world_mod.World, out: []Inst) usize {
    if (!w.in_garden or w.hose_thing == world_mod.no_thing) return 0;
    const near = hose.nearest(w.hum_x, w.hum_z);
    const reach: f32 = 260.0;
    if (near.d > reach) return 0;
    const hz: f32 = if (w.hose_open) world_mod.hose_open_hz else world_mod.hose_stopped_hz;
    const t = @as(f32, @floatFromInt(w.step)) * world_mod.dt;
    const beat = 0.5 + 0.5 * @sin(2.0 * std.math.pi * t * hz / 256.0);
    const glow = (0.18 + 0.30 * beat) * (1.0 - near.d / reach) * (if (w.hose_open) @as(f32, 1.4) else 1.0);
    var n: usize = 0;
    var d = @max(0.0, near.along - 80.0);
    const end = @min(hose.length, near.along + 80.0);
    while (d < end and n < out.len) : (d += 5.0) {
        const p = hose.at(d);
        const q = hose.at(@min(d + 5.0, hose.length));
        const fade = 1.0 - @abs(d - near.along) / 80.0;
        out[n] = .{ .a = .{ p[0], land.hose_bore, p[1] }, .b = .{ q[0], land.hose_bore, q[1] }, .half_width = 1.8, .body = 0.0, .col = col8(hum_green, glow * fade) };
        n += 1;
    }
    return n;
}

/// The water once the knot springs open: a bright front running down the hose from the knot to its
/// mouth; then the whole hose flowing, drops of light running down it; and at the mouth the water
/// pouring into the pool, rings spreading out on it.
pub fn waterLines(w: *const world_mod.World, out: []Inst) usize {
    if (w.water_from == world_mod.never) return 0;
    var n: usize = 0;
    const since = @as(f32, @floatFromInt(w.step - w.water_from)) * world_mod.dt;
    const knot_along = hose.length - land.hose_knot;
    if (w.water_at == world_mod.never) {
        const front = knot_along + since * world_mod.water_speed;
        var d = @max(knot_along, front - 60.0);
        while (d < front and n < out.len) : (d += 4.0) {
            const p = hose.at(d);
            const q = hose.at(@min(d + 4.0, front));
            const bright = 0.35 + 0.6 * (1.0 - (front - d) / 60.0);
            out[n] = .{ .a = .{ p[0], land.hose_bore * 1.05, p[1] }, .b = .{ q[0], land.hose_bore * 1.05, q[1] }, .half_width = 2.0, .body = 0.0, .col = col8(water, bright) };
            n += 1;
        }
        return n;
    }
    // flowing: a drop of light every thirty metres, running down at the water's speed
    const run = since * world_mod.water_speed;
    const shift = run - @floor(run / 30.0) * 30.0;
    var d: f32 = shift;
    while (d < hose.length and n < out.len) : (d += 30.0) {
        const p = hose.at(d);
        const q = hose.at(@min(d + 5.0, hose.length));
        out[n] = .{ .a = .{ p[0], land.hose_bore * 1.05, p[1] }, .b = .{ q[0], land.hose_bore * 1.05, q[1] }, .half_width = 1.6, .body = 0.0, .col = col8(water, 0.55) };
        n += 1;
    }
    // the pour, from the mouth over the reeds' feet into the water
    const m = hose.path[hose.count - 1];
    const px = land.pool[0];
    const pz = land.pool[1];
    const ox = px - m[0];
    const oz = pz - m[1];
    const ol = @max(@sqrt(ox * ox + oz * oz), 0.001);
    const inflow = [2]f32{ px - ox / ol * land.pool[2], pz - oz / ol * land.pool[2] };
    for (0..3) |k| {
        const s = @as(f32, @floatFromInt(k)) - 1.0;
        const a = V{ m[0], land.hose_bore * 0.5, m[1] };
        const mid = V{ (m[0] + inflow[0]) * 0.5 + s * 1.5, land.hose_bore * 0.8, (m[1] + inflow[1]) * 0.5 };
        const b = V{ inflow[0] + s * 2.0, 0.05, inflow[1] };
        if (n + 2 > out.len) return n;
        out[n] = .{ .a = a, .b = mid, .half_width = 1.4, .body = 0.0, .col = col8(water, 0.6) };
        out[n + 1] = .{ .a = mid, .b = b, .half_width = 1.4, .body = 0.0, .col = col8(water, 0.6) };
        n += 2;
    }
    // rings spreading on the pool from where it pours in, for the first six seconds
    const after = @as(f32, @floatFromInt(w.step - w.water_at)) * world_mod.dt;
    if (after < 6.0) {
        for (0..3) |k| {
            const r = (after - @as(f32, @floatFromInt(k)) * 0.8) * 22.0;
            if (r <= 0.0) continue;
            const fade = 0.6 * (1.0 - after / 6.0);
            const parts = 40;
            for (0..parts) |i| {
                if (n >= out.len) return n;
                const a0 = @as(f32, @floatFromInt(i)) * (2.0 * std.math.pi / @as(f32, parts));
                const a1 = @as(f32, @floatFromInt(i + 1)) * (2.0 * std.math.pi / @as(f32, parts));
                const p0 = [2]f32{ inflow[0] + r * @cos(a0), inflow[1] + r * @sin(a0) };
                const p1 = [2]f32{ inflow[0] + r * @cos(a1), inflow[1] + r * @sin(a1) };
                // only on the water
                const d0x = p0[0] - px;
                const d0z = p0[1] - pz;
                if (d0x * d0x + d0z * d0z > land.pool[2] * land.pool[2]) continue;
                out[n] = .{ .a = .{ p0[0], 0.06, p0[1] }, .b = .{ p1[0], 0.06, p1[1] }, .half_width = 1.2, .body = 0.0, .col = col8(water, fade) };
                n += 1;
            }
        }
    }
    return n;
}

/// For a second, a blue figure sits on the pool's edge (SPEC.md 6.1): at the garden's own size, as
/// a person sits by a garden pond, legs over the water, leaning back on its hands. Lines only, no
/// face, no name. Who it is stays Morgan's.
pub fn figureLines(w: *const world_mod.World, out: []Inst) usize {
    if (!w.figureNow()) return 0;
    const at = world_mod.figure_at;
    const fx = land.pool[0] - at[0];
    const fz = land.pool[1] - at[1];
    const fl = @max(@sqrt(fx * fx + fz * fz), 0.001);
    const u = [2]f32{ fx / fl, fz / fl };
    const r = [2]f32{ -u[1], u[0] };
    // there at once and gone at once, a few steps either way
    const into = w.step - w.figure_from;
    const left = world_mod.figure_for - into;
    const edge = @min(into, left);
    const col = col8(figure_blue, @min(1.0, @as(f32, @floatFromInt(edge)) / 6.0));
    const P = struct {
        fn place(a: [2]f32, uu: [2]f32, rr: [2]f32, fwd: f32, side: f32, up: f32) V {
            return .{ a[0] + uu[0] * fwd + rr[0] * side, up, a[1] + uu[1] * fwd + rr[1] * side };
        }
    };
    var n: usize = 0;
    const segs = [_][2][3]f32{
        // spine, shoulders, neck
        .{ .{ 0.0, 0.0, 6.0 }, .{ -4.0, 0.0, 62.0 } },
        .{ .{ -4.0, -18.0, 60.0 }, .{ -4.0, 18.0, 60.0 } },
        .{ .{ -4.0, 0.0, 62.0 }, .{ -5.0, 0.0, 70.0 } },
        // arms, back to the hands on the bank
        .{ .{ -4.0, -18.0, 60.0 }, .{ -14.0, -24.0, 32.0 } },
        .{ .{ -14.0, -24.0, 32.0 }, .{ -22.0, -25.0, 4.0 } },
        .{ .{ -4.0, 18.0, 60.0 }, .{ -14.0, 24.0, 32.0 } },
        .{ .{ -14.0, 24.0, 32.0 }, .{ -22.0, 25.0, 4.0 } },
        // hips, thighs over the water, shins down into it
        .{ .{ 0.0, -11.0, 6.0 }, .{ 0.0, 11.0, 6.0 } },
        .{ .{ 0.0, -10.0, 6.0 }, .{ 40.0, -12.0, 16.0 } },
        .{ .{ 40.0, -12.0, 16.0 }, .{ 47.0, -14.0, 0.0 } },
        .{ .{ 0.0, 10.0, 6.0 }, .{ 40.0, 12.0, 16.0 } },
        .{ .{ 40.0, 12.0, 16.0 }, .{ 47.0, 14.0, 0.0 } },
    };
    for (segs) |s| {
        if (n >= out.len) return n;
        out[n] = .{ .a = P.place(at, u, r, s[0][0], s[0][1], s[0][2]), .b = P.place(at, u, r, s[1][0], s[1][1], s[1][2]), .half_width = 2.6, .body = 0.0, .col = col };
        n += 1;
    }
    // the head: two rings across each other, so it is round from any side, and nothing in it
    const head = [3]f32{ -6.0, 0.0, 80.0 };
    const hr: f32 = 10.0;
    for (0..2) |ring| {
        for (0..18) |i| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(i)) * (2.0 * std.math.pi / 18.0);
            const a1 = @as(f32, @floatFromInt(i + 1)) * (2.0 * std.math.pi / 18.0);
            const p0 = if (ring == 0) P.place(at, u, r, head[0], hr * @cos(a0), head[2] + hr * @sin(a0)) else P.place(at, u, r, head[0] + hr * @cos(a0), 0.0, head[2] + hr * @sin(a0));
            const p1 = if (ring == 0) P.place(at, u, r, head[0], hr * @cos(a1), head[2] + hr * @sin(a1)) else P.place(at, u, r, head[0] + hr * @cos(a1), 0.0, head[2] + hr * @sin(a1));
            out[n] = .{ .a = p0, .b = p1, .half_width = 2.6, .body = 0.0, .col = col };
            n += 1;
        }
    }
    return n;
}
