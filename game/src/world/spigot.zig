//! The spigot (scores/garden.txt): ten metres of brass on the highest rise, where the hose begins.
//! A riser from the ground, a wider body, a handle like a wheel on a stem, and a spout bent down to
//! where the hose is screwed on. Its sizes are named here once: the picture draws these and the
//! shapes are these, so what is seen is what stops Hum. No platform.
const std = @import("std");
const land = @import("land.zig");
const hose = @import("hose.zig");
const form = @import("../form/shape.zig");

pub const x: f32 = land.spigot[0];
pub const z: f32 = land.spigot[1];
pub const tall: f32 = land.spigot[2];

/// The riser: how far it reaches from its middle, and how far up the spigot it goes.
pub const riser: f32 = 0.9;
pub const riser_to: f32 = 0.7;
/// The body on top of it.
pub const body: f32 = 1.7;
pub const body_to: f32 = 0.86;
/// The stem of the handle, and the handle's wheel at the very top.
pub const stem: f32 = 0.18;
pub const stem_to: f32 = 0.95;
pub const wheel: f32 = 1.6;
/// The spout: how high it leaves the body, how far out it goes, how thick it is, and how low it
/// bends before the hose takes over.
pub const spout_at: f32 = 0.78;
pub const spout_out: f32 = 3.0;
pub const spout: f32 = 0.35;
pub const spout_down: f32 = 0.45;

/// Where the spout turns down: out from the spigot toward the hose's first stretch.
pub fn spoutEnd() [2]f32 {
    const p = hose.path[1];
    const ox = p[0] - x;
    const oz = p[1] - z;
    const ol = @max(@sqrt(ox * ox + oz * oz), 0.001);
    return .{ x + ox / ol * spout_out, z + oz / ol * spout_out };
}

pub fn shapes(sink: *form.Sink) void {
    sink.stalk(.{ x, 0.0, z }, .{ x, tall * riser_to, z }, riser, riser);
    sink.stalk(.{ x, tall * riser_to, z }, .{ x, tall * body_to, z }, body, body);
    sink.stalk(.{ x, tall * body_to, z }, .{ x, tall, z }, stem, stem);
    sink.disc(.{ x, tall, z }, wheel, 0.2);
    const end = spoutEnd();
    sink.stalk(.{ x, tall * spout_at, z }, .{ end[0], tall * spout_at, end[1] }, spout, spout);
    sink.stalk(.{ end[0], tall * spout_at, end[1] }, .{ end[0], tall * spout_down, end[1] }, spout, spout);
}

test "the spigot's shapes stand on its place and reach its top" {
    var room: [8]form.Shape = undefined;
    var sink = form.Sink{ .out = &room };
    shapes(&sink);
    try std.testing.expectEqual(@as(usize, 6), sink.n);
    try std.testing.expectEqual(@as(usize, 0), sink.lost);
    try std.testing.expectEqual(@as(f32, 0.0), sink.out[0].stalk.a[1]);
    try std.testing.expectEqual(tall, sink.out[3].plate.corners[0][1]);
}
