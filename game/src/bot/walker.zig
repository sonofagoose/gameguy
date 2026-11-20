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
    in_open: bool = false,
    bee_marked: bool = false,
    bridge_marked: bool = false,
    swell_marked: bool = false,
    knots_marked: bool = false,
    pocket_marked: bool = false,
    afterimage_marked: bool = false,
    placed_tried: bool = false,
    nudged: bool = false,
    nudge_left: u8 = 0,
    nudged_at: u64 = 0,
    cross_from: f32 = 0.0,
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

    /// Turn the view toward a place with the right stick; true once it is facing it.
    fn face(w: *const World, h: *Hands, x: f32, z: f32) bool {
        const want = std.math.atan2(x - w.hum_x, -(z - w.hum_z));
        var turn = want - w.look_yaw;
        while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
        while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
        if (@abs(turn) > 0.04) {
            // never inside the stick's dead middle, or the view would stop just short
            const push = std.math.clamp(turn * 300.0, -110.0, 110.0);
            h.rx = @intFromFloat(if (push > 0.0) @max(push, 24.0) else @min(push, -24.0));
            return false;
        }
        return true;
    }

    /// Where to head for on the way to a place: straight there, unless the straight way crosses a
    /// puddle, and then round its shore, the shorter way.
    fn detour(w: *const World, x: f32, z: f32) [2]f32 {
        for (w.pools[0..w.pool_count]) |*p| {
            if (p.holds(x, z)) continue;
            const ax = x - w.hum_x;
            const az = z - w.hum_z;
            const len2 = ax * ax + az * az;
            if (len2 < 1.0) continue;
            const t = std.math.clamp(((p.x - w.hum_x) * ax + (p.z - w.hum_z) * az) / len2, 0.0, 1.0);
            const qx = w.hum_x + ax * t - p.x;
            const qz = w.hum_z + az * t - p.z;
            if (qx * qx + qz * qz > (p.r + 4.0) * (p.r + 4.0)) continue;
            const here = std.math.atan2(w.hum_z - p.z, w.hum_x - p.x);
            var gap = std.math.atan2(z - p.z, x - p.x) - here;
            while (gap > std.math.pi) gap -= 2.0 * std.math.pi;
            while (gap < -std.math.pi) gap += 2.0 * std.math.pi;
            const ang = here + std.math.clamp(gap, -0.3, 0.3);
            return .{ p.x + (p.r + 8.0) * @cos(ang), p.z + (p.r + 8.0) * @sin(ang) };
        }
        return .{ x, z };
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
        // the bee, once: hovering near and ahead, where the view can see it
        if (!self.bee_marked and self.phase >= 5 and w.bee.thing != world_mod.no_thing and w.bee.hover_left > 0) {
            const b = w.things[w.bee.thing];
            const dx = b.x - w.hum_x;
            const dz = b.z - w.hum_z;
            const far = @sqrt(dx * dx + dz * dz);
            const ahead = (dx * @sin(w.look_yaw) - dz * @cos(w.look_yaw)) / @max(far, 0.1);
            if (far < 40.0 and far > 10.0 and ahead > 0.85 and b.y < 20.0) {
                self.bee_marked = true;
                self.mark = "bee";
            }
        }
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
                // first out from under any roof of clover or moss, onto open ground, away from
                // the aster
                if (!self.in_open and (w.cover == .clover or w.cover == .moss) and after < 600) {
                    const tower = w.towers[0];
                    const dx = w.hum_x - tower.x;
                    const dz = w.hum_z - tower.z;
                    _ = toward(w, &h, w.hum_x + dx, w.hum_z + dz);
                    return h;
                }
                self.in_open = true;
                // then turn to the lake and watch the sky come up: the rungs light as the sun
                // climbs, and each is heard when its note has crossed the water
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
            9 => {
                // to the bridge puddle: facing it, walk until just short of its edge
                if (w.pool_count == 0) {
                    self.phase = 99;
                    return h;
                }
                const p = &w.pools[0];
                const dx = p.x - w.hum_x;
                const dz = p.z - w.hum_z;
                const far = @sqrt(dx * dx + dz * dz);
                if (!face(w, &h, p.x, p.z)) return h;
                if (far > p.r + 3.0) {
                    var probe = Hands{};
                    _ = toward(w, &probe, p.x, p.z);
                    h.lx = probe.lx;
                    h.ly = probe.ly;
                } else self.next(step);
            },
            10 => {
                // hum at its edge, standing still, while the figure comes up, the view rises over
                // it, and the pollen gathers on its still lines
                h.buttons |= Hands.sing;
                if (after == 60 * 14) self.mark = "pool";
                if (after > 60 * 15) self.next(step);
            },
            11 => {
                // still humming, round the shore to the nearest end of a still spoke
                h.buttons |= Hands.sing;
                const p = &w.pools[0];
                const f = &p.figs[0];
                const m = world_mod.pools.modes[f.mode].m;
                const here = std.math.atan2(w.hum_z - p.z, w.hum_x - p.x);
                if (m == 0) {
                    self.phase = 99;
                    return h;
                }
                // the spokes' ends lie at the turn plus an odd number of half-spacings
                const turn = std.math.atan2(f.turn_s, f.turn_c);
                const spacing = std.math.pi / @as(f32, @floatFromInt(m));
                var goal: f32 = 0.0;
                var nearest: f32 = 1e9;
                var e: u32 = 0;
                while (e < 2 * m) : (e += 1) {
                    const at_end = turn + (@as(f32, @floatFromInt(e)) + 0.5) * spacing;
                    var gap = at_end - here;
                    while (gap > std.math.pi) gap -= 2.0 * std.math.pi;
                    while (gap < -std.math.pi) gap += 2.0 * std.math.pi;
                    if (@abs(gap) < @abs(nearest)) {
                        nearest = gap;
                        goal = at_end;
                    }
                }
                if (@abs(nearest) > 0.01) {
                    const ang = here + std.math.clamp(nearest, -0.08, 0.08);
                    _ = toward(w, &h, p.x + (p.r + 3.0) * @cos(ang), p.z + (p.r + 3.0) * @sin(ang));
                } else {
                    self.cross_from = goal;
                    self.next(step);
                }
            },
            12 => {
                // face across, and walk the still line to the far side, humming all the way
                h.buttons |= Hands.sing;
                const p = &w.pools[0];
                const tx = p.x - (p.r + 8.0) * @cos(self.cross_from);
                const tz = p.z - (p.r + 8.0) * @sin(self.cross_from);
                if (after < 240 and !face(w, &h, tx, tz)) return h;
                var probe = Hands{};
                const far = toward(w, &probe, tx, tz);
                h.lx = probe.lx;
                h.ly = probe.ly;
                // a third of the way over, out on the still line with the water heaving either side
                const cx = w.hum_x - p.x;
                const cz = w.hum_z - p.z;
                if (!self.bridge_marked and w.on_pool != 0 and cx * cx + cz * cz < (p.r * 0.45) * (p.r * 0.45)) {
                    self.bridge_marked = true;
                    self.mark = "bridge";
                }
                if (w.crossed > 0 or far < 2.0 or after > 60 * 60) self.next(step);
            },
            13 => {
                // stand still, hold R1: the wheel opens; point a twelfth of a turn left, at wonder,
                // and let go there
                if (after < 15) return h;
                if (after < 95) {
                    h.buttons |= Hands.call;
                    if (after >= 40) {
                        h.rx = -63;
                        h.ry = -110;
                    }
                    if (after == 80) self.mark = "wheel";
                    return h;
                }
                if (after > 110) self.next(step);
            },
            14 => {
                // home is wonder now: to the puddle sized for it
                const fp = &w.pools[w.pool_count - 1];
                const dx = fp.x - w.hum_x;
                const dz = fp.z - w.hum_z;
                const far = @sqrt(dx * dx + dz * dz);
                const way = detour(w, fp.x, fp.z);
                if (far > fp.r + 3.0) {
                    if (!face(w, &h, way[0], way[1]) and after < 240) return h;
                    var probe = Hands{};
                    _ = toward(w, &probe, way[0], way[1]);
                    h.lx = probe.lx;
                    h.ly = probe.ly;
                    // keep the view turned the way it walks
                    _ = face(w, &h, way[0], way[1]);
                } else self.next(step);
                if (after > 60 * 150) self.next(step);
            },
            15 => {
                // hum at its edge: silent to the garden's note, it stands for wonder's
                h.buttons |= Hands.sing;
                if (after == 60 * 12) self.mark = "wonder";
                if (after > 60 * 13) self.next(step);
            },
            16 => {
                // let go, and walk away from the water, so the swell is seen at Hum's own height
                const fp = &w.pools[w.pool_count - 1];
                if (after < 360) {
                    _ = toward(w, &h, w.hum_x + (w.hum_x - fp.x), w.hum_z + (w.hum_z - fp.z));
                    _ = face(w, &h, w.hum_x + (w.hum_x - fp.x), w.hum_z + (w.hum_z - fp.z));
                }
                if (after > 480) self.next(step);
            },
            17 => {
                // the first knots come and circle, stumbling. Home is on wonder, their root: strike on
                // the downbeats, where both strands meet Hum's one, until they are grey
                var near = false;
                var coloured = false;
                for (w.knots[0..w.knot_count]) |kn| {
                    if (kn.home) continue;
                    const dx = kn.x - w.hum_x;
                    const dz = kn.z - w.hum_z;
                    if (dx * dx + dz * dz < 9.0 * 9.0) near = true;
                    if (kn.colour > 0.0) coloured = true;
                }
                if (near and !self.knots_marked) {
                    self.knots_marked = true;
                    self.mark = "knots";
                }
                // a lunge about to arrive: step aside on its beat, and the pocket opens
                var lunge_due = false;
                for (w.knots[0..w.knot_count]) |kn| {
                    if (kn.lunge_from != world_mod.knots.never_lunged and w.clock + 2 == kn.lunge_from + world_mod.knots.lunge_steps / 2) lunge_due = true;
                }
                if (lunge_due) h.buttons |= Hands.dodge;
                if (w.pockets == 1 and !self.pocket_marked) {
                    self.pocket_marked = true;
                    self.mark = "pocket";
                }
                // the afterimage: a bar in the pocket keeps its strikes, and they land again beside Hum
                if (w.layer_n >= 1 and w.ghost_strikes >= 1 and !self.afterimage_marked) {
                    self.afterimage_marked = true;
                    self.mark = "afterimage";
                }
                // with two layers kept and the knots still coloured, clap: L1 and R1 together
                if (w.layer_n >= 2 and coloured and w.claps == 0 and !lunge_due and w.clock % (4 * world_mod.tick_every) == 100) {
                    h.buttons |= Hands.voice | Hands.call | Hands.clap;
                    self.mark = "clap";
                }
                if (near and coloured and w.clock % (4 * world_mod.tick_every) == 0 and w.clock > 0) h.buttons |= Hands.strike;
                // once, before any strike lands, a press well off the beat: the game places it on the
                // next beat, plain, and the downbeat after is struck on time, fuller
                if (near and coloured and w.strikes == 0 and !self.placed_tried and w.clock % (4 * world_mod.tick_every) == 120) {
                    self.placed_tried = true;
                    h.buttons |= Hands.strike;
                    self.mark = "placed";
                }
                if (near and !coloured) self.next(step);
                if (after > 60 * 60) self.next(step);
            },
            18 => {
                // the swell: hold R2 and let it grow two bars; on the next downbeat nudge home back up
                // to sunny home, beside the knots' root; let go on the one after, the amen lands, and
                // the grey knots come home
                h.buttons |= Hands.sing;
                if (after > 30 and w.swell_bars >= 2 and !self.swell_marked) {
                    self.swell_marked = true;
                    self.mark = "swell";
                }
                if (!self.nudged and after > 30 and w.swell_bars >= 2 and w.downbeat_at != world_mod.never and w.downbeat_at + 1 == w.step) self.nudge_left = 4;
                if (self.nudge_left > 0) {
                    h.rx = 110;
                    self.nudge_left -= 1;
                    if (self.nudge_left == 0) {
                        self.nudged = true;
                        self.nudged_at = step;
                    }
                }
                if (self.nudged and w.downbeat_at != world_mod.never and w.downbeat_at + 1 == w.step and w.home_k == 0 and w.step > self.nudged_at + 60) {
                    h.buttons &= ~Hands.sing;
                    self.next(step);
                }
                if (after > 60 * 40) self.next(step);
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
