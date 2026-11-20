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
    started: bool = false,
    heard_at: ?u64 = null,
    arrived_at: u64 = 0,
    figure_marked: bool = false,
    horn_marked: bool = false,
    six_at: ?u64 = null,
    breathing: bool = false,
    ticks_held: u32 = 0,
    rising_marked: bool = false,
    settled: u32 = 0,
    /// The moment this step is, if it is one a promise wants a frame of.
    mark: ?[]const u8 = null,
    done: bool = false,

    fn next(self: *Walker, step: u64) void {
        self.phase += 1;
        self.since = step;
    }

    /// Push the stick toward a place in the world, read against the way the view looks.
    fn toward(w: *const World, h: *Hands, x: f32, z: f32) f32 {
        const dx = x - w.hum_x;
        const dz = z - w.hum_z;
        const far = @sqrt(dx * dx + dz * dz);
        if (far < 0.01) return far;
        const cy = @cos(w.look_yaw);
        const sy = @sin(w.look_yaw);
        h.lx = @intFromFloat(110.0 * (cy * dx / far + sy * dz / far));
        h.ly = @intFromFloat(110.0 * (-sy * dx / far + cy * dz / far));
        return far;
    }

    pub fn hands(self: *Walker, w: *const World) Hands {
        self.mark = null;
        var h = Hands{};
        const step = w.step;
        if (!self.started) {
            self.started = true;
            // begun in the place at dawn, with Drip already on Hum's head: straight to the asters
            if (w.drip_met) self.phase = 4;
        }
        const after = step - self.since;
        switch (self.phase) {
            0 => {
                // the dark: a first call that nobody answers, and a second that somebody does
                if (step == 20) self.mark = "black";
                if (step == 40) h.buttons |= Hands.call;
                if (step == 78) self.mark = "page";
                if (step == 220) h.buttons |= Hands.call;
                if (step == 318) self.mark = "drip";
                if (w.answered and step > w.answered_at + 50) self.next(step);
            },
            1 => {
                // toward where the answer came from
                const drip = w.things[w.drip];
                var probe = Hands{};
                const far = toward(w, &probe, drip.x, drip.z);
                if (far > 3.4) h = probe else self.next(step);
            },
            2 => {
                // beside it: stand, and the page leans in. Then breathe with it: hum from a little
                // before each tick and let go on the tick
                const until = world_mod.untilTick(step);
                if (after > 50 and !w.drip_met and w.locked_at == world_mod.never) {
                    // a breath is two ticks long: begin just after one, let go on the next but one
                    if (!self.breathing and until == world_mod.tick_every - 6) self.breathing = true;
                    if (self.breathing and until == 0) {
                        self.ticks_held += 1;
                        if (self.ticks_held == 2) {
                            self.breathing = false;
                            self.ticks_held = 0;
                        }
                    }
                    if (self.breathing) h.buttons |= Hands.sing;
                    if (w.breaths == 1 and self.breathing and self.ticks_held == 1 and until == 20 and !self.figure_marked) {
                        self.figure_marked = true;
                        self.mark = "figure";
                    }
                }
                if (w.locked_at != world_mod.never and step == w.locked_at + 90) self.mark = "locked";
                if (w.drip_met) self.next(step);
            },
            3 => {
                // the drop has landed, and the page stands up
                if (!self.rising_marked and w.stand >= 0.56) {
                    self.rising_marked = true;
                    self.mark = "rising";
                }
                if (w.stand >= 1.0) {
                    self.settled += 1;
                    if (self.settled == 130) self.mark = "far";
                    if (self.settled >= 150) {
                        self.phase = 5;
                        self.since = step;
                    }
                }
            },
            4 => {
                // the place at dawn: call once, and look at what answers
                if (after == 40) h.buttons |= Hands.call;
                if (after == 150) self.mark = "far";
                if (after >= 170) self.next(step);
            },
            5 => {
                const tower = w.towers[0];
                var probe = Hands{};
                const far = toward(w, &probe, tower.x, tower.z);
                if (far > 9.0) {
                    h = probe;
                } else {
                    self.arrived_at = step;
                    self.next(step);
                }
            },
            6 => {
                // at its foot: stand still, let the gaze climb, then call and ride the call up
                if (after == 3) self.mark = "foot";
                // the gaze takes about two and a half seconds to climb to the crown
                if (after == 205) self.mark = "lean";
                if (after == 215) h.buttons |= Hands.call;
                if (after == 215 + 95) self.mark = "climb";
                // seen before it is heard: the crown lights when the call reaches it, almost three
                // seconds after the call, and its sound takes as long again to come down
                if (after == 215 + 185) self.mark = "answer";
                if (self.heard_at == null and w.seen.get(.garden_asters).met) self.heard_at = step;
                if (self.heard_at) |at| {
                    if (step >= at + 240) self.next(step);
                }
                if (after > 60 * 40) self.next(step); // it never came: give up, and say so by not having met it
            },
            7 => {
                // back away from it with the view still on it, looking down at the ground: where
                // Hum walked and called, and the light the crown's bells left beneath them
                const tower = w.towers[0];
                const dx = w.hum_x - tower.x;
                const dz = w.hum_z - tower.z;
                const far = @sqrt(dx * dx + dz * dz);
                if (after < 40) h.ry = 110;
                if (far < 62.0) {
                    _ = toward(w, &h, w.hum_x + dx, w.hum_z + dz);
                } else {
                    self.mark = "ground";
                    self.next(step);
                }
            },
            8 => {
                // turn to the lake and watch the sky come up: the rungs light as the sun climbs,
                // and each is heard when its note has crossed the water
                const want = std.math.atan2(world_mod.lake_x - w.hum_x, -(world_mod.lake_z - w.hum_z));
                var turn = want - w.look_yaw;
                while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
                while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
                if (@abs(turn) > 0.03) h.rx = @intFromFloat(std.math.clamp(turn * 300.0, -110.0, 110.0));
                if (w.look_tilt < -0.02) h.ry = -110 else if (w.look_tilt > 0.02) h.ry = 110;
                const six = @as(u32, 1) << 6;
                if (w.rung_lit & six != 0 and self.six_at == null) self.six_at = step;
                if (self.six_at) |at| {
                    if (!self.horn_marked and step == at + 120) {
                        self.horn_marked = true;
                        self.mark = "horn";
                    }
                }
                if (w.rung_heard >= 6) self.next(step);
                if (after > 60 * 400) self.next(step);
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
    try std.testing.expect(mark.first > bot.arrived_at + 215 + 240);
    try std.testing.expect(mark.held > 60);
    try std.testing.expectEqual(@as(u32, 0), w.dropped);
}

test "the scripted player is answered by the drip, breathes with it, and the page stands up" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    var bot = Walker{};
    var cues: [world_mod.max_cues]@import("../sound/sound.zig").Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 90 and bot.phase < 5) : (step += 1) {
        _ = w.stepOnce(bot.hands(w), &cues);
    }
    // the second call was answered, and it walked to where the answer came from
    try std.testing.expect(w.seen.get(.evening_call).met);
    // four breaths on the tick, and nothing else: it locked
    try std.testing.expect(w.seen.get(.evening_breathe).met);
    try std.testing.expectEqual(world_mod.breaths_to_lock, w.breaths);
    // the drop landed, the page stood up and the day came
    try std.testing.expect(w.drip_met);
    try std.testing.expectEqual(@as(f32, 1.0), w.stand);
    try std.testing.expect(w.dawnAge() > 0.0);
    try std.testing.expectEqual(@as(u32, 0), w.dropped);
}
