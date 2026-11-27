//! The Garden as a place: what in it is solid and never moves (docs/engine.md, "Places and the
//! world"). Its asters, its reeds, its hose, its spigot and the flower head that has fallen, each
//! from the shapes its own rules give. It is made once, the first time it is asked for, from the
//! Garden's score alone, so it is the same every time and on every machine; after that it is only
//! read. Nothing here is the world's state: a save holds none of it.
const std = @import("std");
const form = @import("../form/shape.zig");
const solid = @import("../body/solid.zig");
const grid = @import("../body/grid.zig");
const land = @import("../world/land.zig");
const ground = @import("../world/ground.zig");
const asters = @import("../world/asters.zig");
const reeds = @import("../world/reeds.zig");
const hose = @import("../world/hose.zig");
const spigot = @import("../world/spigot.zig");

var store: grid.Store = .{};
var made = false;

/// The flower head that has fallen by the great aster's foot: where it lies, and how far it
/// reaches. The world's own thing for it is made from these.
pub const fallen_x: f32 = asters.great_x + 7.5;
pub const fallen_z: f32 = asters.great_z + 6.0;
pub const fallen_y: f32 = 1.5;
pub const fallen_tall: f32 = 2.2;
pub const fallen_reach: f32 = fallen_tall * 0.9;

fn addAll(sink: *const form.Sink, kind: solid.Kind, id: u32) void {
    for (sink.slice()) |shape| store.add(.{ .shape = solid.lifted(shape, &ground.heightAt), .kind = kind, .id = id });
}

fn make() void {
    store.clear();
    var room: [1200]form.Shape = undefined;
    // the asters: each a tower, numbered as the world numbers them
    var plans: [asters.max_towers]asters.Plan = undefined;
    const towers = asters.field(&plans, land.note);
    for (plans[0..towers], 0..) |*p, t| {
        var sink = form.Sink{ .out = &room };
        p.shapes(&sink);
        addAll(&sink, .tower, @intCast(t));
    }
    // the reeds, numbered in the order the world makes its own things for them
    var reed: u32 = 0;
    for (0..reeds.groups) |g| {
        for (0..reeds.each) |k| {
            const r = reeds.at(g, k) orelse continue;
            var sink = form.Sink{ .out = &room };
            reeds.shapes(r, &sink);
            addAll(&sink, .reed, reed);
            reed += 1;
        }
    }
    {
        var sink = form.Sink{ .out = &room };
        hose.shapes(0, hose.count - 1, &sink);
        addAll(&sink, .hose, 0);
    }
    {
        var sink = form.Sink{ .out = &room };
        spigot.shapes(&sink);
        addAll(&sink, .spigot, 0);
    }
    {
        var sink = form.Sink{ .out = &room };
        sink.ball(.{ fallen_x, fallen_y, fallen_z }, fallen_reach);
        addAll(&sink, .fallen, 0);
    }
    store.finish();
    made = true;
}

/// The Garden's solids.
pub fn solids() *const grid.Store {
    if (!made) make();
    return &store;
}

test "the Garden's solids: every aster, reed, stretch of hose and the spigot, with room to spare" {
    const s = solids();
    try std.testing.expectEqual(@as(u32, 0), s.lost);
    var counts: [@typeInfo(solid.Kind).@"enum".field_names.len]u32 = @splat(0);
    for (s.solids[0..s.n]) |sol| counts[@intFromEnum(sol.kind)] += 1;
    var plans: [asters.max_towers]asters.Plan = undefined;
    const towers = asters.field(&plans, land.note);
    try std.testing.expectEqual(@as(u32, @intCast(towers * asters.segments)), counts[@intFromEnum(solid.Kind.tower)]);
    try std.testing.expect(counts[@intFromEnum(solid.Kind.reed)] > reeds.most);
    try std.testing.expect(counts[@intFromEnum(solid.Kind.hose)] > 300);
    try std.testing.expectEqual(@as(u32, 6), counts[@intFromEnum(solid.Kind.spigot)]);
    try std.testing.expectEqual(@as(u32, 1), counts[@intFromEnum(solid.Kind.fallen)]);
    // at the great aster's foot the grid finds its stalk
    var near: [64]*const solid.Solid = undefined;
    const n = s.near(asters.great_x, asters.great_z, 2.0, &near);
    var found = false;
    for (near[0..n]) |sol| {
        if (sol.kind == .tower and sol.id == 0) found = true;
    }
    try std.testing.expect(found);
    // and where Hum wakes there is nothing solid within reach
    const wake = solid.Body{ .x = land.wake[0], .z = land.wake[1], .feet = ground.heightAt(land.wake[0], land.wake[1]), .reach = 0.36, .tall = 1.0 };
    const m = s.near(wake.x, wake.z, 2.0, &near);
    for (near[0..m]) |sol| try std.testing.expect(solid.meet(sol, wake, solid.default_step, wake.x, wake.z) == null);
}
