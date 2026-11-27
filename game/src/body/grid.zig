//! A place's solids, and a grid of cells to find the ones near a spot (docs/engine.md, "Solids,
//! and Hum's body"). The solids that never move are put in once, when the place is made, and
//! after that the store is only read.
//!
//! No world in it and no platform.
const std = @import("std");
const solid_mod = @import("solid.zig");
const Solid = solid_mod.Solid;

/// A cell is as wide as the squares the ground is drawn and lit in.
pub const cell: f32 = 16.0;

pub const most_solids = 6000;
pub const most_cells = 128 * 128;
pub const most_slots = 24_000;

pub const Store = struct {
    solids: [most_solids]Solid = undefined,
    n: u32 = 0,
    /// Solids that found no room. Always nought (a place's own test says so).
    lost: u32 = 0,
    /// The grid: its corner, how many cells each way, where each cell's solids begin in `slots`.
    min_x: f32 = 0.0,
    min_z: f32 = 0.0,
    nx: u32 = 0,
    nz: u32 = 0,
    starts: [most_cells + 1]u32 = undefined,
    slots: [most_slots]u32 = undefined,
    finished: bool = false,

    pub fn clear(self: *Store) void {
        self.n = 0;
        self.lost = 0;
        self.nx = 0;
        self.nz = 0;
        self.finished = false;
    }

    pub fn add(self: *Store, solid: Solid) void {
        if (self.n >= most_solids) {
            self.lost += 1;
            return;
        }
        self.solids[self.n] = solid;
        self.n += 1;
    }

    fn cellOf(self: *const Store, x: f32, z: f32) [2]u32 {
        const cx = std.math.clamp(@floor((x - self.min_x) / cell), 0.0, @as(f32, @floatFromInt(self.nx - 1)));
        const cz = std.math.clamp(@floor((z - self.min_z) / cell), 0.0, @as(f32, @floatFromInt(self.nz - 1)));
        return .{ @intFromFloat(cx), @intFromFloat(cz) };
    }

    /// Sort every solid into the cells it reaches. After this the store is only read.
    pub fn finish(self: *Store) void {
        self.finished = true;
        if (self.n == 0) return;
        var min_x: f32 = std.math.floatMax(f32);
        var min_z: f32 = std.math.floatMax(f32);
        var max_x: f32 = -std.math.floatMax(f32);
        var max_z: f32 = -std.math.floatMax(f32);
        for (self.solids[0..self.n]) |*s| {
            const b = solid_mod.bounds(s);
            min_x = @min(min_x, b.min_x);
            min_z = @min(min_z, b.min_z);
            max_x = @max(max_x, b.max_x);
            max_z = @max(max_z, b.max_z);
        }
        self.min_x = @floor(min_x / cell) * cell;
        self.min_z = @floor(min_z / cell) * cell;
        self.nx = @intFromFloat(@floor((max_x - self.min_x) / cell) + 1.0);
        self.nz = @intFromFloat(@floor((max_z - self.min_z) / cell) + 1.0);
        while (self.nx * self.nz > most_cells) {
            // a place too wide for the grid keeps its far edges in its last cells
            if (self.nx >= self.nz) self.nx -= 1 else self.nz -= 1;
        }
        const cells = self.nx * self.nz;
        // count, then place: two passes over the same sum
        @memset(self.starts[0 .. cells + 1], 0);
        for (self.solids[0..self.n]) |*s| {
            const b = solid_mod.bounds(s);
            const lo = self.cellOf(b.min_x, b.min_z);
            const hi = self.cellOf(b.max_x, b.max_z);
            var cz = lo[1];
            while (cz <= hi[1]) : (cz += 1) {
                var cx = lo[0];
                while (cx <= hi[0]) : (cx += 1) self.starts[cz * self.nx + cx + 1] += 1;
            }
        }
        for (0..cells) |i| self.starts[i + 1] += self.starts[i];
        var filled: [most_cells]u32 = undefined;
        @memset(filled[0..cells], 0);
        for (self.solids[0..self.n], 0..) |*s, index| {
            const b = solid_mod.bounds(s);
            const lo = self.cellOf(b.min_x, b.min_z);
            const hi = self.cellOf(b.max_x, b.max_z);
            var cz = lo[1];
            while (cz <= hi[1]) : (cz += 1) {
                var cx = lo[0];
                while (cx <= hi[0]) : (cx += 1) {
                    const c = cz * self.nx + cx;
                    const at = self.starts[c] + filled[c];
                    if (at < most_slots) self.slots[at] = @intCast(index) else self.lost += 1;
                    filled[c] += 1;
                }
            }
        }
    }

    /// The solids that could reach within `reach` of a place, each once. Returns how many.
    pub fn near(self: *const Store, x: f32, z: f32, reach: f32, out: []*const Solid) usize {
        if (self.n == 0 or self.nx == 0) return 0;
        if (x + reach < self.min_x or z + reach < self.min_z) return 0;
        if (x - reach > self.min_x + cell * @as(f32, @floatFromInt(self.nx))) return 0;
        if (z - reach > self.min_z + cell * @as(f32, @floatFromInt(self.nz))) return 0;
        const lo = self.cellOf(x - reach, z - reach);
        const hi = self.cellOf(x + reach, z + reach);
        var n: usize = 0;
        var cz = lo[1];
        while (cz <= hi[1]) : (cz += 1) {
            var cx = lo[0];
            while (cx <= hi[0]) : (cx += 1) {
                const c = cz * self.nx + cx;
                const from = self.starts[c];
                const to = @min(self.starts[c + 1], most_slots);
                for (self.slots[from..to]) |index| {
                    const s = &self.solids[index];
                    var seen = false;
                    for (out[0..n]) |already| {
                        if (already == s) {
                            seen = true;
                            break;
                        }
                    }
                    if (seen) continue;
                    if (n >= out.len) return n;
                    out[n] = s;
                    n += 1;
                }
            }
        }
        return n;
    }
};

const expectEqual = std.testing.expectEqual;

test "the grid finds what is near a place, each solid once, and nothing far" {
    const S = struct {
        var store: Store = .{};
    };
    const store = &S.store;
    store.clear();
    // a row of posts every ten metres, and one long tube across four cells
    for (0..20) |i| {
        const x = @as(f32, @floatFromInt(i)) * 10.0;
        store.add(.{ .shape = .{ .stalk = .{ .a = .{ x, 0.0, 0.0 }, .b = .{ x, 5.0, 0.0 }, .ra = 0.5, .rb = 0.5 } }, .kind = .tower, .id = @intCast(i) });
    }
    store.add(.{ .shape = .{ .stalk = .{ .a = .{ 0.0, 1.0, 40.0 }, .b = .{ 60.0, 1.0, 40.0 }, .ra = 1.0, .rb = 1.0 } }, .kind = .hose });
    store.finish();
    try expectEqual(@as(u32, 0), store.lost);
    var out: [16]*const Solid = undefined;
    // beside the fifth post: it, and its neighbours in the cells round it, and not the far ones
    const n = store.near(40.0, 1.0, 1.5, &out);
    var found_fifth = false;
    for (out[0..n]) |s| {
        if (s.kind == .tower and s.id == 4) found_fifth = true;
        if (s.kind == .tower) try std.testing.expect(s.id >= 2 and s.id <= 6);
    }
    try std.testing.expect(found_fifth);
    // the tube is found once, though it lies in four cells
    var tubes: usize = 0;
    const m = store.near(30.0, 40.0, 20.0, &out);
    for (out[0..m]) |s| {
        if (s.kind == .hose) tubes += 1;
    }
    try expectEqual(@as(usize, 1), tubes);
    // far outside the grid there is nothing
    try expectEqual(@as(usize, 0), store.near(5000.0, 5000.0, 2.0, &out));
}
