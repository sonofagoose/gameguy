//! The hose (spec/world.md, "Its great instrument: the Hose"; scores/garden.txt): a curve from the
//! spigot down across the Garden to its coiled end in the reeds, through the points the score gives
//! it. It is worked out once, when the game is built, so it is the same on every machine: a
//! Catmull-Rom curve through the points, each stretch between two of them cut into the same number
//! of pieces, and how far along it each piece starts.
const std = @import("std");
const land = @import("land.zig");
const form = @import("../form/shape.zig");

/// How many pieces each stretch between two of the score's points is cut into.
const per = 48;
pub const count = (land.hose.len - 1) * per + 1;

/// The curve, from the spigot to the hose's end.
pub const path: [count][2]f32 = blk: {
    @setEvalBranchQuota(4_000_000);
    var out: [count][2]f32 = undefined;
    const n = land.hose.len;
    var k: usize = 0;
    for (0..n - 1) |i| {
        const a = land.hose[if (i == 0) 0 else i - 1];
        const b = land.hose[i];
        const c = land.hose[i + 1];
        const d = land.hose[if (i + 2 < n) i + 2 else n - 1];
        for (0..per) |s| {
            const t: f32 = @as(f32, @floatFromInt(s)) / @as(f32, per);
            for (0..2) |j| {
                const p0 = 2.0 * b[j];
                const p1 = (c[j] - a[j]) * t;
                const p2 = (2.0 * a[j] - 5.0 * b[j] + 4.0 * c[j] - d[j]) * (t * t);
                const p3 = (3.0 * b[j] - a[j] - 3.0 * c[j] + d[j]) * (t * t * t);
                out[k][j] = 0.5 * (p0 + p1 + p2 + p3);
            }
            k += 1;
        }
    }
    out[k] = land.hose[n - 1];
    break :blk out;
};

/// How far along the curve each of its points is, from the spigot.
pub const along: [count]f32 = blk: {
    @setEvalBranchQuota(4_000_000);
    var out: [count]f32 = undefined;
    out[0] = 0.0;
    for (1..count) |i| {
        const dx = path[i][0] - path[i - 1][0];
        const dz = path[i][1] - path[i - 1][1];
        out[i] = out[i - 1] + @sqrt(dx * dx + dz * dz);
    }
    break :blk out;
};

/// The hose's length, from the spigot to its end.
pub const length: f32 = along[count - 1];

/// The point this far back along the hose from its end.
pub fn backFromEnd(d: f32) [2]f32 {
    @setEvalBranchQuota(100_000);
    const want = length - d;
    if (want <= 0.0) return path[0];
    var i: usize = count - 1;
    while (i > 0 and along[i - 1] > want) i -= 1;
    if (i == 0) return path[0];
    const span = along[i] - along[i - 1];
    const t = if (span > 0.0) (want - along[i - 1]) / span else 0.0;
    return .{ path[i - 1][0] + (path[i][0] - path[i - 1][0]) * t, path[i - 1][1] + (path[i][1] - path[i - 1][1]) * t };
}

/// Where the hose is knotted.
pub const knot: [2]f32 = backFromEnd(land.hose_knot);

pub const Near = struct { p: [2]f32, d: f32, along: f32 };

/// The hose's nearest point to a place, how far it is, and how far along the hose from the spigot.
pub fn nearest(x: f32, z: f32) Near {
    var best: f32 = std.math.floatMax(f32);
    var out = Near{ .p = path[0], .d = 0.0, .along = 0.0 };
    for (0..count - 1) |i| {
        const ax = path[i][0];
        const az = path[i][1];
        const dx = path[i + 1][0] - ax;
        const dz = path[i + 1][1] - az;
        const l2 = dx * dx + dz * dz;
        var t: f32 = 0.0;
        if (l2 > 0.0) t = std.math.clamp(((x - ax) * dx + (z - az) * dz) / l2, 0.0, 1.0);
        const qx = ax + dx * t;
        const qz = az + dz * t;
        const px = x - qx;
        const pz = z - qz;
        const d2 = px * px + pz * pz;
        if (d2 < best) {
            best = d2;
            out = .{ .p = .{ qx, qz }, .d = 0.0, .along = along[i] + (along[i + 1] - along[i]) * t };
        }
    }
    out.d = @sqrt(best);
    return out;
}

/// The point this far along the hose from the spigot.
pub fn at(d: f32) [2]f32 {
    return backFromEnd(length - d);
}

/// How far a place is from the hose's line.
pub fn distance(x: f32, z: f32) f32 {
    var best: f32 = std.math.floatMax(f32);
    for (0..count - 1) |i| {
        const ax = path[i][0];
        const az = path[i][1];
        const dx = path[i + 1][0] - ax;
        const dz = path[i + 1][1] - az;
        const l2 = dx * dx + dz * dz;
        var t: f32 = 0.0;
        if (l2 > 0.0) t = std.math.clamp(((x - ax) * dx + (z - az) * dz) / l2, 0.0, 1.0);
        const px = x - (ax + dx * t);
        const pz = z - (az + dz * t);
        best = @min(best, px * px + pz * pz);
    }
    return @sqrt(best);
}

/// How far the hose reaches from its middle line: half its bore. It lies on the ground, so its
/// middle line is that high.
pub const reach: f32 = land.hose_bore * 0.5;
/// One straight stretch of tube stands for a piece of the curve no longer than this, that turns no
/// more than this (the cosine of six hundredths of a radian), which keeps each within about two
/// centimetres of the curve. So a long run is few stretches and the coil
/// is many short ones.
const stretch_long: f32 = 3.0;
const stretch_turn: f32 = 0.9982;
/// Each stretch is this much longer than its piece at either end, so that no gap opens on the
/// outside of a bend.
const stretch_laps: f32 = reach * 0.12;

fn heading(i: usize) [2]f32 {
    const dx = path[i + 1][0] - path[i][0];
    const dz = path[i + 1][1] - path[i][1];
    const l = @max(@sqrt(dx * dx + dz * dz), 1e-6);
    return .{ dx / l, dz / l };
}

/// The hose as shapes, between two of its curve's points: stretches of tube. What stops Hum and
/// what hides are both made from these.
pub fn shapes(first: usize, last: usize, sink: *form.Sink) void {
    const end = @min(last, count - 1);
    var from = first;
    while (from < end) {
        const way = heading(from);
        var to = from + 1;
        while (to < end and along[to] - along[from] < stretch_long) {
            const next = heading(to);
            if (way[0] * next[0] + way[1] * next[1] < stretch_turn) break;
            to += 1;
        }
        const dx = path[to][0] - path[from][0];
        const dz = path[to][1] - path[from][1];
        const l = @max(@sqrt(dx * dx + dz * dz), 1e-6);
        const lx = dx / l * stretch_laps;
        const lz = dz / l * stretch_laps;
        sink.stalk(.{ path[from][0] - lx, reach, path[from][1] - lz }, .{ path[to][0] + lx, reach, path[to][1] + lz }, reach, reach);
        from = to;
    }
}

test "the hose's shapes follow its curve from end to end, a bore across" {
    var room: [1200]form.Shape = undefined;
    var sink = form.Sink{ .out = &room };
    shapes(0, count - 1, &sink);
    try std.testing.expectEqual(@as(usize, 0), sink.lost);
    try std.testing.expect(sink.n > 300 and sink.n < 1100);
    var covered: f32 = 0.0;
    for (sink.slice()) |shape| {
        const s = shape.stalk;
        try std.testing.expectEqual(reach, s.ra);
        // each stretch lies along the curve: both its ends are on it, give or take what it laps
        try std.testing.expect(distance(s.a[0], s.a[2]) < 0.3);
        try std.testing.expect(distance(s.b[0], s.b[2]) < 0.3);
        covered += form.length(form.sub(s.b, s.a)) - 2.0 * stretch_laps;
    }
    // together they are as long as the hose, less what the chords cut off its bends
    try std.testing.expect(covered > length * 0.99 and covered <= length + 0.01);
}

test "the hose runs from the spigot to its end in the reeds, at least a kilometre and a half" {
    try std.testing.expectEqual(land.hose[0], path[0]);
    try std.testing.expectEqual(land.hose[land.hose.len - 1], path[count - 1]);
    // spec/promises/garden.md, garden.great: "at least 1.5 km long"
    try std.testing.expect(length >= 1500.0);
    // the knot lies on it, as far back from its end as the score says
    try std.testing.expect(distance(knot[0], knot[1]) < 0.5);
    // and every one of the score's points is on the curve
    for (land.hose) |p| try std.testing.expect(distance(p[0], p[1]) < 0.5);
}
