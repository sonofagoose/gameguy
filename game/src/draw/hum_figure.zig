//! Hum's figure as it stands in a place: an oval a metre high that faces the eye. Its lines and
//! its black shape are both made from this one outline, so the figure hides exactly what it
//! covers. No platform.
const std = @import("std");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const V3 = [3]f32;

/// How many parts its outline is drawn in.
pub const parts = 14;

pub const Oval = struct {
    /// Across the view, on the ground: the way Hum's width lies.
    rx: f32,
    rz: f32,
    /// Half its width and half its height now: wider and lower as it lands, larger as it sings.
    wide: f32,
    high: f32,
    /// How far its feet are off the ground: a jump, and a small lift with each stride.
    lift: f32,
    /// How far its top swings into a turn.
    tip: f32,
    /// Seen from above its upright leans away from the eye, so it stays a figure and never a sliver.
    back_x: f32,
    back_z: f32,
    upright: f32,
    x: f32,
    z: f32,

    pub fn of(w: *const World, eye: V3) Oval {
        const swell = w.humSwell();
        const rx = @cos(w.look_yaw);
        const rz = @sin(w.look_yaw);
        // landing, it squashes a little and springs back
        var squash: f32 = 1.0;
        if (w.landed_at > 0 and w.step >= w.landed_at) {
            const since = @as(f32, @floatFromInt(w.step - w.landed_at));
            if (since < 6.0) squash = 0.85 else if (since < 15.0) squash = 0.85 + 0.15 * (since - 6.0) / 9.0;
        }
        const ex = w.hum_x - eye[0];
        const ey = (w.hum_ground + w.hum_y + world_mod.hum_middle) - eye[1];
        const ez = w.hum_z - eye[2];
        const el = @max(@sqrt(ex * ex + ey * ey + ez * ez), 0.001);
        const down = -ey / el;
        const flat = @max(@sqrt(ex * ex + ez * ez), 0.001);
        // its stride: a small lift each step, as fast as it goes
        const going = std.math.clamp(@sqrt(w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz) / world_mod.run_speed, 0.0, 1.0);
        // visual-sonic unity: subtle living bar-breath, call/chord bloom, and harmonic posture
        const bar_breath = @sin(w.barPhase() * (2.0 * std.math.pi));
        const breath_w: f32 = 1.0 + 0.032 * bar_breath;
        const breath_h: f32 = 1.0 + 0.024 * bar_breath;
        const call_w: f32 = 1.0 + 0.12 * w.hum_call_vis + 0.045 * w.hum_chord_vis;
        const call_h: f32 = 1.0 + 0.06 * w.hum_call_vis + 0.030 * w.hum_chord_vis;
        const posture_w: f32 = if (w.home_minor) 1.03 else if (w.home_k == -1) 0.98 else if (w.home_k == 1) 1.02 else 1.0;
        const posture_h: f32 = if (w.home_minor) 0.97 else if (w.home_k == -1) 1.04 else if (w.home_k == 1) 0.99 else 1.0;
        return .{
            .rx = rx,
            .rz = rz,
            .wide = world_mod.hum_body * swell * (2.0 - squash) * breath_w * call_w * posture_w,
            .high = world_mod.hum_half_high * swell * squash * breath_h * call_h * posture_h,
            .lift = w.hum_y + (if (w.airborne) 0.0 else 0.06 * going * @abs(@sin(w.stride * (std.math.pi / 0.9)))),
            .tip = w.lean_x * rx + w.lean_z * rz,
            .back_x = ex / flat * down,
            .back_z = ez / flat * down,
            .upright = @sqrt(@max(1.0 - down * down, 0.0)),
            .x = w.hum_x,
            .z = w.hum_z,
        };
    }

    /// The point of its outline this far round, in radians: nought at its side, a quarter turn at
    /// its top. Its height is above the ground under Hum.
    pub fn rim(self: Oval, turn: f32) V3 {
        const side = self.wide * @cos(turn) + self.tip * (1.0 + @sin(turn));
        const up = self.high * @sin(turn);
        return .{
            self.x + self.rx * side + self.back_x * up,
            world_mod.hum_middle + self.lift + up * self.upright,
            self.z + self.rz * side + self.back_z * up,
        };
    }

    /// The line across it at a height, from -1 at its feet to 1 at its top: one of its breaths.
    pub fn across(self: Oval, f: f32) [2]V3 {
        const half = self.wide * @sqrt(@max(1.0 - f * f, 0.0));
        const sway = self.tip * (1.0 + f);
        const y = world_mod.hum_middle + self.lift + self.high * f;
        return .{
            .{ self.x + self.rx * (sway - half), y, self.z + self.rz * (sway - half) },
            .{ self.x + self.rx * (sway + half), y, self.z + self.rz * (sway + half) },
        };
    }

    pub fn middle(self: Oval) V3 {
        return .{ self.x + self.rx * self.tip, world_mod.hum_middle + self.lift, self.z + self.rz * self.tip };
    }

    /// Its whole outline, in order.
    pub fn outline(self: Oval) [parts]V3 {
        var out: [parts]V3 = undefined;
        for (&out, 0..) |*p, k| p.* = self.rim(@as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, parts)));
        return out;
    }
};

test "Hum's outline is a metre high and as wide as its body, round its middle" {
    var w = World{};
    w.hum_x = 3.0;
    w.hum_z = -2.0;
    const oval = Oval.of(&w, .{ 3.0, 2.0, 9.0 });
    const top = oval.rim(std.math.pi / 2.0);
    const foot = oval.rim(-std.math.pi / 2.0);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 * world_mod.hum_half_high), (top[1] - foot[1]) / oval.upright, 1e-4);
    const side = oval.rim(0.0);
    const other = oval.rim(std.math.pi);
    const dx = side[0] - other[0];
    const dz = side[2] - other[2];
    try std.testing.expectApproxEqAbs(@as(f32, 2.0 * world_mod.hum_body), @sqrt(dx * dx + dz * dz), 1e-4);
    try std.testing.expectEqual(@as(usize, parts), oval.outline().len);
}
