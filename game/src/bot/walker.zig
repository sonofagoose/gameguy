//! A scripted player for the proof field of asters. It plays by rules, from what it can see of
//! the world, not by replaying a take: it stands where the page stood up and calls, walks to the
//! great aster, stops at its foot, waits for the view to lean back, calls, and stays until the
//! bells of the crown have been heard; then it backs away looking down, to see what light was left
//! on the ground. `mark` names the moments a promise wants a frame of.
const std = @import("std");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const Hands = world_mod.Hands;

pub const Walker = struct {
    phase: u8 = 0,
    since: u64 = 0,
    heard_at: ?u64 = null,
    arrived_at: u64 = 0,
    /// The moment this step is, if it is one a promise wants a frame of.
    mark: ?[]const u8 = null,
    done: bool = false,

    fn next(self: *Walker, step: u64) void {
        self.phase += 1;
        self.since = step;
    }

    pub fn hands(self: *Walker, w: *const World) Hands {
        self.mark = null;
        var h = Hands{};
        const step = w.step;
        const after = step - self.since;
        switch (self.phase) {
            0 => {
                // the page: call once, and watch the ring cross it. Then it stands up; look at what
                // has risen, and at what answers
                if (step == 40) h.buttons |= Hands.call;
                if (step == 120) self.mark = "page";
                if (step == 280) self.mark = "rising";
                if (step == 500) self.mark = "far";
                if (step >= 520) self.next(step);
            },
            1 => {
                const tower = w.towers[0];
                const dx = tower.x - w.hum_x;
                const dz = tower.z - w.hum_z;
                const far = @sqrt(dx * dx + dz * dz);
                if (far > 9.0) {
                    // the stick is read against the way the view looks
                    const cy = @cos(w.look_yaw);
                    const sy = @sin(w.look_yaw);
                    const wx = dx / far;
                    const wz = dz / far;
                    h.lx = @intFromFloat(110.0 * (cy * wx + sy * wz));
                    h.ly = @intFromFloat(110.0 * (-sy * wx + cy * wz));
                } else {
                    self.arrived_at = step;
                    self.next(step);
                }
            },
            2 => {
                // at its foot: stand still, let the view lean back, then call and wait
                if (after == 3) self.mark = "foot";
                // the gaze takes about two and a half seconds to climb to the crown
                if (after == 205) self.mark = "lean";
                if (after == 215) h.buttons |= Hands.call;
                if (after == 215 + 95) self.mark = "climb";
                if (self.heard_at == null and w.seen.get(.garden_asters).met) self.heard_at = step;
                // seen before it is heard: the crown lights when the call reaches it, almost three
                // seconds after the call, and its sound takes as long again to come down
                if (after == 215 + 185) self.mark = "answer";
                if (self.heard_at) |at| {
                    if (step >= at + 240) self.next(step);
                }
                if (after > 60 * 40) self.next(step); // it never came: give up, and say so by not having met it
            },
            3 => {
                // back away from it with the view still on it, looking down at the ground: where
                // Hum walked and called, and the light the crown's bells left beneath them
                const tower = w.towers[0];
                const dx = w.hum_x - tower.x;
                const dz = w.hum_z - tower.z;
                const far = @sqrt(dx * dx + dz * dz);
                if (after < 40) h.ry = 110;
                if (far < 62.0) {
                    const cy = @cos(w.look_yaw);
                    const sy = @sin(w.look_yaw);
                    const wx = dx / @max(far, 0.01);
                    const wz = dz / @max(far, 0.01);
                    h.lx = @intFromFloat(110.0 * (cy * wx + sy * wz));
                    h.ly = @intFromFloat(110.0 * (-sy * wx + cy * wz));
                } else {
                    self.mark = "ground";
                    self.next(step);
                }
            },
            else => self.done = true,
        }
        return h;
    }
};

test "the scripted player walks to the great aster and hears its bells from its foot" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initAsters();
    var bot = Walker{};
    var cues: [world_mod.max_cues]@import("../sound/sound.zig").Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 120 and !bot.done) : (step += 1) {
        _ = w.stepOnce(bot.hands(w), &cues);
    }
    const mark = w.seen.get(.garden_asters);
    try std.testing.expect(mark.met);
    // it is a real walk: 150 m at 6 m a second
    try std.testing.expect(bot.arrived_at > 60 * 20);
    // and the bells came down late by the height: more than four seconds after the call
    try std.testing.expect(mark.first > bot.arrived_at + 120 + 240);
    try std.testing.expect(mark.held > 60);
    try std.testing.expectEqual(@as(u32, 0), w.dropped);
}
