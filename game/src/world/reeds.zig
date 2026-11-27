//! The reeds round the Mirror Pool (spec/shape.md, the Garden; spec/laws.md, "reeds are open
//! pipes"): cattails as tall as towers, in a band round the pool's still water. One rule places
//! them, and the world (each stem solid, and a pipe that sounds when it is touched or called) and
//! the picture both read it, so what is seen and what is felt can't disagree. No platform.

const std = @import("std");
const land = @import("land.zig");
const ground = @import("ground.zig");
const hose = @import("hose.zig");
const form = @import("../form/shape.zig");

/// Grouped by where round the pool they stand.
pub const groups = 24;
pub const each = 11;
pub const most = groups * each;

pub const Reed = struct {
    x: f32,
    z: f32,
    /// How tall it stands.
    tall: f32,
    /// How far its stem reaches from its middle at the foot: a real stem is a centimetre or two
    /// through for a metre or two of height, so here a metre or two through.
    stem: f32,
    /// Which way its top leans, and how far.
    lean_a: f32,
    lean: f32,
    /// Its own number, which sizes the rest of its shape.
    s: u32,
};

/// The reed at place `k` of group `g`, or none there: none where Hum wakes, at Drip's clearing, or
/// on the hose.
pub fn at(g: usize, k: usize) ?Reed {
    const px = land.pool[0];
    const pz = land.pool[1];
    const r0 = land.pool[2];
    const band = land.pool[3];
    const s = ground.hash32(@intCast(g), @intCast(k), 97);
    const a = (@as(f32, @floatFromInt(g)) + ground.unit01(s)) * (2.0 * std.math.pi / @as(f32, groups));
    const r = r0 + band * ground.unit01(s *% 2654435761);
    const x = px + r * @cos(a);
    const z = pz + r * @sin(a);
    const wx = x - land.wake[0];
    const wz = z - land.wake[1];
    const cx = x - land.clear[0];
    const cz = z - land.clear[1];
    if (wx * wx + wz * wz < 7.0 * 7.0 or cx * cx + cz * cz < 8.0 * 8.0) return null;
    if (hose.distance(x, z) < 4.0) return null;
    const tall = 60.0 + 90.0 * ground.unit01(s *% 40503);
    return .{
        .x = x,
        .z = z,
        .tall = tall,
        .stem = tall / 300.0,
        .lean_a = ground.unit01(s *% 69069) * 2.0 * std.math.pi,
        .lean = tall * (0.03 + 0.06 * ground.unit01(s *% 362437)),
        .s = s,
    };
}

/// A reed's line: its foot, its middle and its top, leaning the way it leans. The picture draws
/// its stem along this, and its shapes follow it.
pub fn spine(reed: Reed) [3]form.V3 {
    const cx = @cos(reed.lean_a) * reed.lean;
    const sz = @sin(reed.lean_a) * reed.lean;
    const foot = form.V3{ reed.x, 0.0, reed.z };
    const top = form.V3{ reed.x + cx, reed.tall, reed.z + sz };
    const mid = form.V3{ (foot[0] + top[0]) * 0.5 + cx * 0.15, reed.tall * 0.5, (foot[2] + top[2]) * 0.5 + sz * 0.15 };
    return .{ foot, mid, top };
}

/// A reed as shapes: its stem, in two stretches, thinner toward the top.
pub fn shapes(reed: Reed, sink: *form.Sink) void {
    const s = spine(reed);
    sink.stalk(s[0], s[1], reed.stem, reed.stem * 0.7);
    sink.stalk(s[1], s[2], reed.stem * 0.7, reed.stem * 0.35);
}

/// Its note: an open pipe as long as the reed is at its real size (a hundredth of what is seen),
/// in real air, at the garden's five notes on the land's note, the nearest of them.
pub fn note(tall: f32, land_hz: f32) f32 {
    var f = 343.0 / (2.0 * tall / 100.0);
    var octave: f32 = 1.0;
    while (f >= land_hz * 2.0) {
        f *= 0.5;
        octave *= 2.0;
    }
    while (f < land_hz) {
        f *= 2.0;
        octave *= 0.5;
    }
    const r = f / land_hz;
    var best: f32 = 1.0;
    var best_off: f32 = 1e9;
    for (ground.five ++ [_]f32{2.0}) |n| {
        const off = @max(r / n, n / r);
        if (off < best_off) {
            best_off = off;
            best = n;
        }
    }
    return land_hz * best * octave;
}

test "the reeds stand in the pool's band, clear of where Hum wakes, Drip's clearing and the hose, each a pipe of the garden's five notes" {
    var n: usize = 0;
    for (0..groups) |g| {
        for (0..each) |k| {
            const reed = at(g, k) orelse continue;
            n += 1;
            const dx = reed.x - land.pool[0];
            const dz = reed.z - land.pool[1];
            const r = @sqrt(dx * dx + dz * dz);
            try std.testing.expect(r >= land.pool[2] and r <= land.pool[2] + land.pool[3]);
            try std.testing.expect(hose.distance(reed.x, reed.z) >= 4.0);
            const hz = note(reed.tall, 261.63);
            var f = hz;
            while (f >= 261.63 * 2.0) f *= 0.5;
            while (f < 261.63) f *= 2.0;
            var on_five = false;
            for (ground.five) |five| {
                if (@abs(f / 261.63 - five) < 0.001) on_five = true;
            }
            try std.testing.expect(on_five);
        }
    }
    try std.testing.expect(n > most / 2);
}
