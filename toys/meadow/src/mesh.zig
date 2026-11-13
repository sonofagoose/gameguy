//! Shapes. Everything in the meadow is built here from rules, as plain triangle lists with
//! colour baked into the vertices: no model files, no textures to load.
const std = @import("std");
const math = @import("math.zig");
const noise = @import("noise.zig");
const land = @import("land.zig");
const Vec3 = math.Vec3;
const Allocator = std.mem.Allocator;

/// One vertex, 24 bytes. Light, wind and fog are all worked out per vertex from these fields.
pub const Vertex = extern struct {
    pos: [3]f32,
    /// xyz: surface normal (-127..127). w: how far the wind moves this vertex (0..127).
    normal: [4]i8,
    /// rgb: colour before light. a: glow, how much it shines by its own light at night.
    color: [4]u8,
    /// Grass only: [phase, blade height * 8, lean x * 16 + 128, lean z * 16 + 128].
    extra: [4]u8 = .{ 0, 0, 0, 0 },
};

comptime {
    std.debug.assert(@sizeOf(Vertex) == 24);
}

pub fn List(comptime T: type) type {
    return struct {
        items: []T = &.{},
        len: usize = 0,
        const Self = @This();

        pub fn push(self: *Self, gpa: Allocator, item: T) void {
            if (self.len == self.items.len) {
                const cap: usize = if (self.items.len == 0) 256 else self.items.len * 2;
                self.items = if (self.items.len == 0)
                    gpa.alloc(T, cap) catch @panic("out of memory")
                else
                    gpa.realloc(self.items, cap) catch @panic("out of memory");
            }
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn slice(self: *const Self) []T {
            return self.items[0..self.len];
        }

        pub fn deinit(self: *Self, gpa: Allocator) void {
            if (self.items.len != 0) gpa.free(self.items);
            self.* = .{};
        }
    };
}

fn toByte(x: f32) u8 {
    return @intFromFloat(std.math.clamp(x, 0.0, 1.0) * 255.0 + 0.5);
}

fn toSigned(x: f32) i8 {
    return @intFromFloat(std.math.clamp(x, -1.0, 1.0) * 127.0);
}

pub const Color = [3]f32;

pub fn mixColor(a: Color, b: Color, t: f32) Color {
    return .{ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };
}

fn shade(a: Color, k: f32) Color {
    return .{ a[0] * k, a[1] * k, a[2] * k };
}

/// A triangle list with 16-bit indices and its bounding box.
pub const Mesh = struct {
    verts: List(Vertex) = .{},
    indices: List(u16) = .{},
    lo: Vec3 = Vec3.init(1e9, 1e9, 1e9),
    hi: Vec3 = Vec3.init(-1e9, -1e9, -1e9),
    /// Grass: the indices before this point are an evenly spread half of the blades, for
    /// drawing distant stands more thinly.
    half: usize = 0,

    pub fn deinit(self: *Mesh, gpa: Allocator) void {
        self.verts.deinit(gpa);
        self.indices.deinit(gpa);
    }

    pub fn triangles(self: *const Mesh) usize {
        return self.indices.len / 3;
    }

    /// Room for `count` more vertices under the 16-bit index limit?
    pub fn hasRoom(self: *const Mesh, count: usize) bool {
        return self.verts.len + count <= 65535;
    }

    pub fn vertex(self: *Mesh, gpa: Allocator, pos: Vec3, normal: Vec3, sway: f32, color: Color, glow: f32) u16 {
        return self.vertexExtra(gpa, pos, normal, sway, color, glow, .{ 0, 0, 0, 0 });
    }

    pub fn vertexExtra(self: *Mesh, gpa: Allocator, pos: Vec3, normal: Vec3, sway: f32, color: Color, glow: f32, extra: [4]u8) u16 {
        const index: u16 = @intCast(self.verts.len);
        self.verts.push(gpa, .{
            .pos = .{ pos.x, pos.y, pos.z },
            .normal = .{ toSigned(normal.x), toSigned(normal.y), toSigned(normal.z), toSigned(sway) },
            .color = .{ toByte(color[0]), toByte(color[1]), toByte(color[2]), toByte(glow) },
            .extra = extra,
        });
        self.lo = Vec3.init(@min(self.lo.x, pos.x), @min(self.lo.y, pos.y), @min(self.lo.z, pos.z));
        self.hi = Vec3.init(@max(self.hi.x, pos.x), @max(self.hi.y, pos.y), @max(self.hi.z, pos.z));
        return index;
    }

    pub fn triangle(self: *Mesh, gpa: Allocator, a: u16, b: u16, c: u16) void {
        self.indices.push(gpa, a);
        self.indices.push(gpa, b);
        self.indices.push(gpa, c);
    }

    /// Wind and gusts can carry vertices outside the box they were built in.
    pub fn pad(self: *Mesh, amount: f32) void {
        self.lo = self.lo.sub(Vec3.init(amount, amount, amount));
        self.hi = self.hi.add(Vec3.init(amount, amount, amount));
    }
};

// ------------------------------------------------------------------ ground

pub const terrain_chunk: f32 = 32.0;
const terrain_step: f32 = 2.0;

/// One square of ground, `terrain_chunk` units on a side, with its corner at (x0, z0).
pub fn terrain(gpa: Allocator, x0: f32, z0: f32) Mesh {
    var mesh = Mesh{};
    const n: usize = @intFromFloat(terrain_chunk / terrain_step);
    const water_y = land.waterLevel();
    for (0..n + 1) |j| {
        for (0..n + 1) |i| {
            const x = x0 + @as(f32, @floatFromInt(i)) * terrain_step;
            const z = z0 + @as(f32, @floatFromInt(j)) * terrain_step;
            const y = land.groundHeight(x, z);
            var color = land.groundColor(x, z);
            // the pond's bed darkens with depth
            const depth = math.clamp01((water_y - y) / 3.5);
            color = mixColor(color, .{ 0.07, 0.11, 0.10 }, depth * 0.8);
            _ = mesh.vertex(gpa, Vec3.init(x, y, z), land.groundNormal(x, z), 0.0, color, 0.0);
        }
    }
    const row: u16 = @intCast(n + 1);
    for (0..n) |j| {
        for (0..n) |i| {
            const a: u16 = @intCast(j * (n + 1) + i);
            const b = a + row;
            mesh.triangle(gpa, a, b, a + 1);
            mesh.triangle(gpa, a + 1, b, b + 1);
        }
    }
    return mesh;
}

// ------------------------------------------------------------------ grass

pub const grass_chunk: f32 = 16.0;

/// The blades growing in one `grass_chunk` square. Each blade is five triangles; its root takes
/// the colour of the ground it stands in and its tip the colour of the grass.
pub fn grass(gpa: Allocator, x0: f32, z0: f32, spacing: f32) Mesh {
    var mesh = Mesh{};
    const n: usize = @intFromFloat(grass_chunk / spacing);
    const ix0: i32 = @intFromFloat(x0 / spacing);
    const iz0: i32 = @intFromFloat(z0 / spacing);
    // two sweeps over the same grid: every other blade first, then the rest
    for (0..2) |sweep| {
        if (sweep == 1) mesh.half = mesh.indices.len;
        for (0..n * n) |cell_index| {
            const i = cell_index % n;
            const j = cell_index / n;
            const gx = ix0 + @as(i32, @intCast(i));
            const gz = iz0 + @as(i32, @intCast(j));
            const cell_hash = noise.hash(gx, gz, 977);
            if ((cell_hash >> 7) & 1 != sweep) continue;
            var rng = noise.Rng.init(cell_hash);
            const x = (@as(f32, @floatFromInt(gx)) + rng.unit()) * spacing;
            const z = (@as(f32, @floatFromInt(gz)) + rng.unit()) * spacing;
            const density = land.grassDensity(x, z);
            if (rng.unit() > density) continue;
            if (!mesh.hasRoom(7)) break;

            const height = (6.0 + 9.5 * rng.unit()) * (0.55 + 0.6 * density);
            const width = (0.30 + 0.28 * rng.unit()) * (0.8 + 0.02 * height);
            const yaw = rng.range(0.0, std.math.pi);
            const lean_angle = rng.range(0.0, 2.0 * std.math.pi);
            const lean = rng.range(0.05, 0.30) * height;
            const side = Vec3.init(@cos(yaw), 0.0, @sin(yaw));
            const face = Vec3.init(-@sin(yaw), 0.35, @cos(yaw)).normalize();
            const lean_dir = Vec3.init(@cos(lean_angle), 0.0, @sin(lean_angle));
            const root = Vec3.init(x, land.groundHeight(x, z) - 0.15, z);

            // root colour from the ground, tip colour from the kind of grass growing here
            const ground = land.groundColor(x, z);
            const dry = noise.fbm(x / 38.0, z / 38.0, 2, 303) * 0.5 + 0.5;
            var tip = mixColor(.{ 0.36, 0.62, 0.17 }, .{ 0.62, 0.70, 0.22 }, dry);
            tip = shade(tip, 0.88 + 0.24 * rng.unit());
            const root_color = mixColor(ground, tip, 0.25);

            const extra = [4]u8{
                @intCast(rng.next() & 0xff),
                toByte(@min(height * 8.0, 255.0) / 255.0),
                @intFromFloat(std.math.clamp(lean_dir.x * lean * 16.0 + 128.0, 0.0, 255.0)),
                @intFromFloat(std.math.clamp(lean_dir.z * lean * 16.0 + 128.0, 0.0, 255.0)),
            };
            var ids: [7]u16 = undefined;
            for (0..4) |ring| {
                const t = @as(f32, @floatFromInt(ring)) / 3.0;
                const centre = root.add(Vec3.init(0.0, height * t, 0.0)).add(lean_dir.scale(lean * t * t));
                const half = width * 0.5 * (1.0 - std.math.pow(f32, t, 1.6));
                const color = mixColor(root_color, tip, std.math.pow(f32, t, 0.7));
                const sway = t * t;
                if (ring < 3) {
                    // one edge a little darker than the other: the blade reads as folded
                    ids[ring * 2] = mesh.vertexExtra(gpa, centre.sub(side.scale(half)), face, sway, shade(color, 0.80), 0.0, extra);
                    ids[ring * 2 + 1] = mesh.vertexExtra(gpa, centre.add(side.scale(half)), face, sway, color, 0.0, extra);
                } else {
                    ids[6] = mesh.vertexExtra(gpa, centre, face, sway, color, 0.0, extra);
                }
            }
            mesh.triangle(gpa, ids[0], ids[1], ids[2]);
            mesh.triangle(gpa, ids[1], ids[3], ids[2]);
            mesh.triangle(gpa, ids[2], ids[3], ids[4]);
            mesh.triangle(gpa, ids[3], ids[5], ids[4]);
            mesh.triangle(gpa, ids[4], ids[5], ids[6]);
        }
    }
    mesh.pad(4.0);
    return mesh;
}

// ------------------------------------------------------------------ solids of revolution

const Profile = struct { r: f32, y: f32 };

/// A surface of revolution around the y axis at `base`, with optional lumps. `tint` is called
/// per vertex with (height fraction, angle) and returns the colour.
fn lathe(
    mesh: *Mesh,
    gpa: Allocator,
    base: Vec3,
    profile: []const Profile,
    segments: usize,
    lump: f32,
    seed: u32,
    sway_top: f32,
    glow: f32,
    context: anytype,
    comptime tint: fn (@TypeOf(context), f32, f32) Color,
) void {
    if (!mesh.hasRoom(profile.len * (segments + 1))) return;
    const first: u16 = @intCast(mesh.verts.len);
    const y_lo = profile[0].y;
    const y_hi = profile[profile.len - 1].y;
    for (profile, 0..) |point, i| {
        // slope of the profile, for the normal
        const before = profile[if (i == 0) 0 else i - 1];
        const after = profile[@min(i + 1, profile.len - 1)];
        const dr = after.r - before.r;
        const dy = after.y - before.y;
        const t = if (y_hi > y_lo) (point.y - y_lo) / (y_hi - y_lo) else 0.0;
        for (0..segments + 1) |j| {
            const wrapped: i32 = @intCast(j % segments);
            const angle = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(segments)) * 2.0 * std.math.pi;
            const bump = 1.0 + lump * (noise.cell(wrapped, @intCast(i), seed) - 0.5) * 2.0;
            const r = point.r * bump;
            const co = @cos(angle);
            const si = @sin(angle);
            const pos = base.add(Vec3.init(r * co, point.y, r * si));
            const normal = Vec3.init(dy * co, -dr, dy * si).normalize();
            _ = mesh.vertex(gpa, pos, normal, sway_top * t * t, tint(context, t, angle), glow);
        }
    }
    const row: u16 = @intCast(segments + 1);
    for (0..profile.len - 1) |i| {
        for (0..segments) |j| {
            const a = first + @as(u16, @intCast(i * (segments + 1) + j));
            const b = a + row;
            mesh.triangle(gpa, a, b, a + 1);
            mesh.triangle(gpa, b, b + 1, a + 1);
        }
    }
}

const Flat = struct {
    color: Color,
    fn tint(self: Flat, t: f32, angle: f32) Color {
        _ = t;
        _ = angle;
        return self.color;
    }
};

const Gradient = struct {
    bottom: Color,
    top: Color,
    fn tint(self: Gradient, t: f32, angle: f32) Color {
        _ = angle;
        return mixColor(self.bottom, self.top, t);
    }
};

// ------------------------------------------------------------------ stones and plants

fn stone(mesh: *Mesh, gpa: Allocator, s: land.Stone) void {
    const h = s.radius * s.squash;
    var profile: [6]Profile = undefined;
    for (0..6) |i| {
        const a = (@as(f32, @floatFromInt(i)) / 5.0 - 0.5) * std.math.pi;
        profile[i] = .{ .r = @max(s.radius * @cos(a), 0.02), .y = h * @sin(a) };
    }
    const warm = noise.cell(@intCast(s.seed & 0xffff), 3, 5);
    const body = mixColor(.{ 0.47, 0.46, 0.44 }, .{ 0.58, 0.52, 0.44 }, warm);
    // moss gathers on top where grass grows around the stone
    const mossy = math.clamp01(land.grassDensity(s.x, s.z) * 1.4);
    const top = mixColor(shade(body, 1.08), .{ 0.33, 0.45, 0.18 }, mossy * 0.75);
    lathe(mesh, gpa, Vec3.init(s.x, s.y, s.z), &profile, 9, 0.16, s.seed, 0.0, 0.0, Gradient{ .bottom = shade(body, 0.62), .top = top }, Gradient.tint);
}

/// A thin three-sided stem from `from` to `to`.
fn stem(mesh: *Mesh, gpa: Allocator, from: Vec3, to: Vec3, radius: f32, sway_from: f32, sway_to: f32, color: Color) void {
    if (!mesh.hasRoom(6)) return;
    const first: u16 = @intCast(mesh.verts.len);
    for (0..2) |end| {
        const centre = if (end == 0) from else to;
        const sway = if (end == 0) sway_from else sway_to;
        const r = if (end == 0) radius else radius * 0.7;
        for (0..3) |k| {
            const angle = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / 3.0);
            const out = Vec3.init(@cos(angle), 0.0, @sin(angle));
            _ = mesh.vertex(gpa, centre.add(out.scale(r)), out, sway, shade(color, if (end == 0) 0.7 else 1.0), 0.0);
        }
    }
    for (0..3) |k| {
        const a = first + @as(u16, @intCast(k));
        const b = first + @as(u16, @intCast((k + 1) % 3));
        mesh.triangle(gpa, a, a + 3, b);
        mesh.triangle(gpa, a + 3, b + 3, b);
    }
}

/// A flat rounded leaf or petal: a fan around `centre` in the plane spanned by `along` and
/// `across`. Drawn two-sided by the renderer.
fn leaf(mesh: *Mesh, gpa: Allocator, base: Vec3, along: Vec3, across: Vec3, normal: Vec3, sway: f32, inner: Color, outer: Color, glow: f32) void {
    if (!mesh.hasRoom(8)) return;
    const centre = base.add(along.scale(0.5));
    const hub = mesh.vertex(gpa, centre, normal, sway, inner, glow);
    const first: u16 = @intCast(mesh.verts.len);
    const points = 7;
    for (0..points) |k| {
        const angle = @as(f32, @floatFromInt(k)) / @as(f32, points) * 2.0 * std.math.pi;
        // egg-shaped: narrow at the base, broad toward the far end
        const reach = 0.5 * @cos(angle);
        const wide = 0.5 * @sin(angle) * (0.75 + 0.35 * @cos(angle));
        const pos = centre.add(along.scale(reach)).add(across.scale(wide));
        _ = mesh.vertex(gpa, pos, normal, sway, outer, glow);
    }
    for (0..points) |k| {
        const a = first + @as(u16, @intCast(k));
        const b = first + @as(u16, @intCast((k + 1) % points));
        mesh.triangle(gpa, hub, a, b);
    }
}

fn plant(mesh: *Mesh, gpa: Allocator, p: land.Plant) void {
    var rng = noise.Rng.init(p.seed);
    const ground = Vec3.init(p.x, land.groundHeight(p.x, p.z) - 0.1, p.z);
    const bend = Vec3.init(rng.range(-0.12, 0.12) * p.height, 0.0, rng.range(-0.12, 0.12) * p.height);
    const top = ground.add(Vec3.init(0.0, p.height, 0.0)).add(bend);
    const up = Vec3.init(0.0, 1.0, 0.0);
    const stem_green = Color{ 0.30, 0.50, 0.16 };

    switch (p.kind) {
        .clover => {
            stem(mesh, gpa, ground, top, 0.10 + 0.012 * p.height, 0.0, 1.0, stem_green);
            const turn = rng.range(0.0, 2.0);
            const dark = Color{ 0.16, 0.42, 0.13 };
            const light = Color{ 0.33, 0.62, 0.20 };
            for (0..3) |k| {
                const angle = turn + @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / 3.0);
                const out = Vec3.init(@cos(angle), -0.18, @sin(angle)).normalize();
                const across = up.cross(out).normalize();
                const normal = out.cross(across).normalize();
                leaf(mesh, gpa, top, out.scale(p.spread), across.scale(p.spread * 1.05), normal, 1.0, dark, light, 0.0);
            }
        },
        .aster, .buttercup => {
            stem(mesh, gpa, ground, top, 0.16, 0.0, 1.0, stem_green);
            const aster = p.kind == .aster;
            const petal = if (aster) Color{ 0.47, 0.25, 0.66 } else Color{ 0.96, 0.80, 0.16 };
            const petal_tip = if (aster) Color{ 0.66, 0.44, 0.86 } else Color{ 1.0, 0.90, 0.36 };
            const count: usize = if (aster) 11 else 5;
            const face = Vec3.init(bend.x * 0.04, 1.0, bend.z * 0.04).normalize();
            for (0..count) |k| {
                const angle = @as(f32, @floatFromInt(k)) / @as(f32, @floatFromInt(count)) * 2.0 * std.math.pi;
                const lift: f32 = if (aster) 0.10 else 0.45;
                const out = Vec3.init(@cos(angle), lift, @sin(angle)).normalize();
                const across = face.cross(out).normalize();
                const width: f32 = if (aster) 0.34 else 0.95;
                leaf(mesh, gpa, top, out.scale(p.spread * 0.5), across.scale(p.spread * width * 0.5), face, 1.0, petal, petal_tip, 0.55);
            }
            // the eye of the flower
            const eye = [_]Profile{ .{ .r = p.spread * 0.13, .y = 0.0 }, .{ .r = p.spread * 0.10, .y = p.spread * 0.05 }, .{ .r = 0.02, .y = p.spread * 0.07 } };
            lathe(mesh, gpa, top, &eye, 6, 0.0, 0, 0.0, 0.5, Flat{ .color = .{ 0.95, 0.72, 0.18 } }, Flat.tint);
        },
        .verbena, .snowberry => {
            stem(mesh, gpa, ground, top, 0.16, 0.0, 1.0, stem_green);
            const verbena = p.kind == .verbena;
            const count: usize = if (verbena) 7 else 5;
            for (0..count) |k| {
                const angle = rng.range(0.0, 2.0 * std.math.pi);
                const reach = if (k == 0) 0.0 else p.spread * rng.range(0.25, 0.5);
                const centre = top.add(Vec3.init(@cos(angle) * reach, rng.range(-0.1, 0.35) * p.spread, @sin(angle) * reach));
                const r = p.spread * (if (verbena) rng.range(0.16, 0.24) else rng.range(0.20, 0.32));
                const ball = [_]Profile{ .{ .r = 0.02, .y = -r }, .{ .r = r * 0.9, .y = -r * 0.4 }, .{ .r = r * 0.9, .y = r * 0.4 }, .{ .r = 0.02, .y = r } };
                const bottom = if (verbena) Color{ 0.42, 0.36, 0.72 } else Color{ 0.66, 0.44, 0.70 };
                const crown = if (verbena) Color{ 0.62, 0.55, 0.88 } else Color{ 0.93, 0.76, 0.90 };
                lathe(mesh, gpa, centre, &ball, 6, 0.0, 0, 0.0, 0.5, Gradient{ .bottom = bottom, .top = crown }, Gradient.tint);
            }
        },
        .mushroom => {
            const stalk = [_]Profile{ .{ .r = p.spread * 0.20, .y = 0.0 }, .{ .r = p.spread * 0.14, .y = p.height * 0.5 }, .{ .r = p.spread * 0.16, .y = p.height } };
            lathe(mesh, gpa, ground, &stalk, 7, 0.0, 0, 0.0, 0.15, Gradient{ .bottom = .{ 0.62, 0.56, 0.46 }, .top = .{ 0.90, 0.85, 0.74 } }, Gradient.tint);
            const cap_base = ground.add(Vec3.init(0.0, p.height - p.spread * 0.06, 0.0));
            const cap = [_]Profile{
                .{ .r = p.spread * 0.30, .y = 0.0 },
                .{ .r = p.spread * 1.00, .y = p.spread * 0.02 },
                .{ .r = p.spread * 0.90, .y = p.spread * 0.17 },
                .{ .r = p.spread * 0.55, .y = p.spread * 0.29 },
                .{ .r = 0.02, .y = p.spread * 0.34 },
            };
            const warm = rng.unit();
            const top_color = mixColor(.{ 0.78, 0.30, 0.20 }, .{ 0.86, 0.62, 0.36 }, warm);
            lathe(mesh, gpa, cap_base, &cap, 11, 0.05, p.seed, 0.0, 0.3, Gradient{ .bottom = .{ 0.50, 0.40, 0.34 }, .top = top_color }, Gradient.tint);
        },
    }
}

pub const prop_cell: f32 = 64.0;

/// The stones in one `prop_cell` square (single-sided, lit as solids).
pub fn stonesIn(gpa: Allocator, things: *const land.Things, x0: f32, z0: f32) Mesh {
    var mesh = Mesh{};
    for (things.stones[0..things.stone_count]) |s| {
        if (s.x < x0 or s.x >= x0 + prop_cell or s.z < z0 or s.z >= z0 + prop_cell) continue;
        stone(&mesh, gpa, s);
    }
    return mesh;
}

/// The plants in one `prop_cell` square (two-sided: their leaves are seen from below).
pub fn plantsIn(gpa: Allocator, things: *const land.Things, x0: f32, z0: f32) Mesh {
    var mesh = Mesh{};
    for (things.plants[0..things.plant_count]) |p| {
        if (p.x < x0 or p.x >= x0 + prop_cell or p.z < z0 or p.z >= z0 + prop_cell) continue;
        plant(&mesh, gpa, p);
    }
    mesh.pad(3.0);
    return mesh;
}

// ------------------------------------------------------------------ the tree

const Bark = struct {
    fn tint(self: Bark, t: f32, angle: f32) Color {
        _ = self;
        const streak = noise.value(angle * 5.0, t * 3.0, 71) * 0.5 + 0.5;
        const base = mixColor(.{ 0.30, 0.21, 0.14 }, .{ 0.46, 0.34, 0.23 }, streak);
        // darker where it meets the ground, paler far up in the haze
        return shade(base, 0.55 + 0.6 * math.smoothstep(0.0, 0.12, t));
    }
};

/// The trunk: to a seed, a tower. Flared at the foot, with ridges where the roots leave it.
pub fn trunk(gpa: Allocator) Mesh {
    var mesh = Mesh{};
    const heights = [_]f32{ -6.0, 2.0, 9.0, 18.0, 32.0, 55.0, 90.0, 150.0, 250.0, land.tree.height };
    var profile: [heights.len]Profile = undefined;
    for (heights, 0..) |y, i| {
        profile[i] = .{ .r = land.trunkRadius(y), .y = y };
    }
    const base = Vec3.init(land.tree.x, land.groundHeight(land.tree.x, land.tree.z) - 2.0, land.tree.z);
    lathe(&mesh, gpa, base, &profile, 22, 0.10, 4242, 0.0, 0.0, Bark{}, Bark.tint);
    return mesh;
}

/// The leaves far overhead: big flat shapes in a dome, with sky between them.
pub fn canopy(gpa: Allocator) Mesh {
    var mesh = Mesh{};
    var rng = noise.Rng.init(99);
    const top = land.groundHeight(land.tree.x, land.tree.z) + land.tree.height * 0.82;
    for (0..230) |_| {
        const angle = rng.range(0.0, 2.0 * std.math.pi);
        const reach = 40.0 + 300.0 * @sqrt(rng.unit());
        const drop = (reach / 340.0) * (reach / 340.0) * 150.0 + rng.range(0.0, 60.0);
        const centre = Vec3.init(land.tree.x + @cos(angle) * reach, top - drop, land.tree.z + @sin(angle) * reach);
        const turn = rng.range(0.0, 2.0 * std.math.pi);
        const tilt = rng.range(-0.5, 0.5);
        const along = Vec3.init(@cos(turn), tilt, @sin(turn)).normalize();
        const across = Vec3.init(-@sin(turn), rng.range(-0.3, 0.3), @cos(turn)).normalize();
        const normal = across.cross(along).normalize();
        const length = rng.range(34.0, 70.0);
        const green = mixColor(.{ 0.13, 0.33, 0.12 }, .{ 0.26, 0.50, 0.16 }, rng.unit());
        leaf(&mesh, gpa, centre, along.scale(length), across.scale(length * 0.55), normal, 0.0, shade(green, 0.8), green, 0.0);
    }
    return mesh;
}

/// Two far rings of growth beyond the meadow's rim. They have no detail; haze does the work.
pub fn backdrop(gpa: Allocator) Mesh {
    var mesh = Mesh{};
    const centre = land.size * 0.5;
    const rings = [_]struct { radius: f32, low: f32, tall: f32, color: Color, seed: u32 }{
        .{ .radius = 250.0, .low = 46.0, .tall = 70.0, .color = .{ 0.16, 0.34, 0.14 }, .seed = 5 },
        .{ .radius = 430.0, .low = 120.0, .tall = 160.0, .color = .{ 0.13, 0.27, 0.16 }, .seed = 6 },
    };
    for (rings) |ring| {
        const segments = 120;
        const first: u16 = @intCast(mesh.verts.len);
        for (0..segments + 1) |j| {
            const wrapped = j % segments;
            const angle = @as(f32, @floatFromInt(wrapped)) / @as(f32, segments) * 2.0 * std.math.pi;
            const co = @cos(angle);
            const si = @sin(angle);
            // a ragged skyline: broad masses with spikes of single giants
            const broad = noise.fbm(co * 2.4 + 9.0, si * 2.4 + 9.0, 3, ring.seed) * 0.5 + 0.5;
            const spike = std.math.pow(f32, noise.cell(@intCast(wrapped), 1, ring.seed), 6.0);
            const height = ring.low + ring.tall * (broad + 0.8 * spike);
            const inward = Vec3.init(-co, 0.25, -si).normalize();
            const foot = Vec3.init(centre + co * ring.radius, -30.0, centre + si * ring.radius);
            _ = mesh.vertex(gpa, foot, inward, 0.0, shade(ring.color, 0.7), 0.0);
            _ = mesh.vertex(gpa, foot.add(Vec3.init(0.0, height + 30.0, 0.0)), inward, 0.0, ring.color, 0.0);
        }
        for (0..segments) |j| {
            const a = first + @as(u16, @intCast(j * 2));
            mesh.triangle(gpa, a, a + 1, a + 2);
            mesh.triangle(gpa, a + 2, a + 1, a + 3);
        }
    }
    return mesh;
}

// ------------------------------------------------------------------ water, creature

/// The pond's surface: a disc wider than the pond, so the ground cuts its shoreline.
pub fn water(gpa: Allocator) Mesh {
    var mesh = Mesh{};
    const y = land.waterLevel();
    const up = Vec3.init(0.0, 1.0, 0.0);
    const hub = mesh.vertex(gpa, Vec3.init(land.pond.x, y, land.pond.z), up, 0.0, .{ 1.0, 1.0, 1.0 }, 0.0);
    const segments = 28;
    const rings = [_]f32{ 0.45, 0.9, 1.45 };
    for (rings) |ring| {
        for (0..segments) |j| {
            const angle = @as(f32, @floatFromInt(j)) / @as(f32, segments) * 2.0 * std.math.pi;
            const r = land.pond.radius * ring;
            _ = mesh.vertex(gpa, Vec3.init(land.pond.x + @cos(angle) * r, y, land.pond.z + @sin(angle) * r), up, 0.0, .{ 1.0, 1.0, 1.0 }, 0.0);
        }
    }
    for (0..segments) |j| {
        const a: u16 = @intCast(1 + j);
        const b: u16 = @intCast(1 + (j + 1) % segments);
        mesh.triangle(gpa, hub, b, a);
        for (0..rings.len - 1) |ring| {
            const inner_a = a + @as(u16, @intCast(ring * segments));
            const inner_b = b + @as(u16, @intCast(ring * segments));
            const outer_a = inner_a + segments;
            const outer_b = inner_b + segments;
            mesh.triangle(gpa, inner_a, inner_b, outer_a);
            mesh.triangle(gpa, inner_b, outer_b, outer_a);
        }
    }
    return mesh;
}

/// The creature: a seed with two eyes and a sprout. One unit tall, standing on y = 0, facing +z.
/// A placeholder body for testing how movement feels, not a character design.
pub fn creature(gpa: Allocator) Mesh {
    var mesh = Mesh{};
    const body = [_]Profile{
        .{ .r = 0.02, .y = 0.0 },
        .{ .r = 0.24, .y = 0.05 },
        .{ .r = 0.38, .y = 0.20 },
        .{ .r = 0.43, .y = 0.40 },
        .{ .r = 0.39, .y = 0.60 },
        .{ .r = 0.29, .y = 0.78 },
        .{ .r = 0.15, .y = 0.92 },
        .{ .r = 0.02, .y = 0.99 },
    };
    lathe(&mesh, gpa, Vec3.init(0.0, 0.0, 0.0), &body, 14, 0.0, 0, 0.0, 0.0, Gradient{ .bottom = .{ 0.72, 0.60, 0.44 }, .top = .{ 0.96, 0.90, 0.76 } }, Gradient.tint);

    // eyes: dark, wide-set, each with a glint that stays bright in any light
    for ([_]f32{ -1.0, 1.0 }) |sign| {
        const centre = Vec3.init(sign * 0.175, 0.56, 0.355);
        const out = Vec3.init(sign * 0.35, 0.12, 1.0).normalize();
        const across = Vec3.init(0.0, 1.0, 0.0).cross(out).normalize();
        const upward = out.cross(across).normalize();
        const base = centre.sub(upward.scale(0.085));
        leaf(&mesh, gpa, base, upward.scale(0.17), across.scale(0.13), out, 0.0, .{ 0.05, 0.04, 0.05 }, .{ 0.05, 0.04, 0.05 }, 0.0);
        const glint = centre.add(upward.scale(0.035)).add(across.scale(-0.02)).add(out.scale(0.012));
        leaf(&mesh, gpa, glint.sub(upward.scale(0.022)), upward.scale(0.045), across.scale(0.04), out, 0.0, .{ 1.0, 1.0, 1.0 }, .{ 1.0, 1.0, 1.0 }, 1.0);
    }

    // the sprout: a stem and two leaves that trail behind every movement
    const crown = Vec3.init(0.0, 0.97, 0.0);
    const tip = Vec3.init(0.0, 1.36, -0.05);
    stem(&mesh, gpa, crown, tip, 0.035, 0.0, 0.5, .{ 0.36, 0.58, 0.20 });
    for ([_]f32{ -1.0, 1.0 }) |sign| {
        const out = Vec3.init(sign * 0.9, 0.42, -0.15).normalize();
        const across = Vec3.init(0.0, 0.0, 1.0);
        const normal = across.cross(out).normalize().scale(sign);
        leaf(&mesh, gpa, tip, out.scale(0.52), across.scale(0.30), normal, 1.0, .{ 0.30, 0.56, 0.18 }, .{ 0.48, 0.74, 0.24 }, 0.0);
    }
    return mesh;
}

test "a vertex is 24 bytes and a mesh keeps its bounds" {
    var mesh = Mesh{};
    defer mesh.deinit(std.testing.allocator);
    _ = mesh.vertex(std.testing.allocator, Vec3.init(1.0, 2.0, 3.0), Vec3.init(0.0, 1.0, 0.0), 0.5, .{ 1.0, 0.5, 0.0 }, 0.0);
    _ = mesh.vertex(std.testing.allocator, Vec3.init(-1.0, 5.0, 0.0), Vec3.init(0.0, 1.0, 0.0), 0.0, .{ 1.0, 0.5, 0.0 }, 0.0);
    try std.testing.expectEqual(@as(f32, -1.0), mesh.lo.x);
    try std.testing.expectEqual(@as(f32, 5.0), mesh.hi.y);
    try std.testing.expectEqual(@as(u8, 255), mesh.verts.items[0].color[0]);
    try std.testing.expectEqual(@as(i8, 127), mesh.verts.items[0].normal[1]);
}

test "every shape stays inside the 16-bit index limit and has whole triangles" {
    const gpa = std.testing.allocator;
    const things = land.Things.generate(1);
    var total: usize = 0;
    var meshes = [_]Mesh{
        terrain(gpa, 96.0, 96.0),
        grass(gpa, 160.0, 160.0, 0.9),
        stonesIn(gpa, &things, 128.0, 128.0),
        plantsIn(gpa, &things, 128.0, 128.0),
        trunk(gpa),
        canopy(gpa),
        backdrop(gpa),
        water(gpa),
        creature(gpa),
    };
    for (&meshes) |*mesh| {
        defer mesh.deinit(gpa);
        try std.testing.expect(mesh.verts.len <= 65535);
        try std.testing.expectEqual(@as(usize, 0), mesh.indices.len % 3);
        for (mesh.indices.slice()) |index| try std.testing.expect(index < mesh.verts.len);
        total += mesh.triangles();
    }
    try std.testing.expect(total > 2000);
}

test "ground triangles face up" {
    const gpa = std.testing.allocator;
    var mesh = terrain(gpa, 96.0, 96.0);
    defer mesh.deinit(gpa);
    const v = mesh.verts.items;
    const ids = mesh.indices.items;
    const a = Vec3.init(v[ids[0]].pos[0], v[ids[0]].pos[1], v[ids[0]].pos[2]);
    const b = Vec3.init(v[ids[1]].pos[0], v[ids[1]].pos[1], v[ids[1]].pos[2]);
    const c = Vec3.init(v[ids[2]].pos[0], v[ids[2]].pos[1], v[ids[2]].pos[2]);
    try std.testing.expect(b.sub(a).cross(c.sub(a)).y > 0.0);
}
