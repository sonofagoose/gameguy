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
    drip_marked: bool = false,
    waited_from: u64 = 0,
    knots_from: u64 = 0,
    asleep_marked: bool = false,
    open_marked: bool = false,
    water_marked: bool = false,
    edge_marked: bool = false,
    lean_marked: bool = false,
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
    /// How many stalks had been brushed before the run at the great aster, and when it rang.
    bumps_before: u32 = 0,
    brushed_at: ?u64 = null,
    sprint_marked: bool = false,
    breathed_at: ?u64 = null,
    fly_from: ?u64 = null,
    glide_pressed: bool = false,
    flown: bool = false,

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
        // the hose across the way: jump it, as a person would
        if (w.at_hose and !w.airborne and w.step % 2 == 0) h.buttons |= Hands.jump;
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
                // the answer on its way back, almost half way: far off, a ring in teal
                if (!self.drip_marked) {
                    for (w.rings) |r| {
                        if (!r.live or r.own) continue;
                        const dx = w.hum_x - r.x;
                        const dz = w.hum_z - r.z;
                        const reach = r.age * world_mod.dt * world_mod.sound_speed;
                        if (reach >= 0.45 * @sqrt(dx * dx + dz * dz)) {
                            self.drip_marked = true;
                            self.mark = "drip";
                        }
                    }
                }
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
                    // a long way to go and breath to spare: sprint, and stop with some left
                    if (far > 40.0 and w.breath > 1.5 and !w.winded) {
                        h.buttons |= Hands.dodge;
                        if (!self.sprint_marked and w.sprinting) {
                            self.sprint_marked = true;
                            self.mark = "sprint";
                        }
                    }
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
                    // then, as a person would, run at the stalk and brush it: its bells answer
                    // from high up, each when its sound has come down
                    if (step >= at + 240 and w.bumps == self.bumps_before) {
                        const tower = w.towers[0];
                        _ = toward(w, &h, tower.x, tower.z);
                        h.lx = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(h.lx)) * 1.15, -127.0, 127.0));
                        h.ly = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(h.ly)) * 1.15, -127.0, 127.0));
                        if (step > at + 240 + 60 * 8) self.next(step);
                    } else if (step >= at + 240) {
                        if (self.brushed_at == null) {
                            self.brushed_at = step;
                            self.mark = "brush";
                        }
                        if (step >= self.brushed_at.? + 240) self.next(step);
                    }
                }
                if (after > 60 * 50) self.next(step); // it never came: give up, and say so by not having met it
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
                // out in the open, once: a jump, the glide opened at its top, and down again
                if (!self.flown) {
                    h.ly = -100;
                    if (self.fly_from == null) {
                        self.fly_from = step;
                        h.buttons |= Hands.jump;
                        self.mark = "jump";
                        return h;
                    }
                    if (w.airborne and !w.gliding and w.hum_vy <= 0.0 and !self.glide_pressed) {
                        self.glide_pressed = true;
                        h.buttons |= Hands.jump;
                        return h;
                    }
                    if (!w.airborne and step > self.fly_from.? + 5) self.flown = true;
                    return h;
                }
                // the bee, while the sky is still coming up: if it is working the clover near by,
                // go and watch it a while, as a person would
                if (!self.bee_marked and after < 60 * 90 and w.bee.thing != world_mod.no_thing and w.bee.hover_left > 0) {
                    const b = w.things[w.bee.thing];
                    const bx = b.x - w.hum_x;
                    const bz = b.z - w.hum_z;
                    const bfar = @sqrt(bx * bx + bz * bz);
                    if (bfar < 90.0 and b.y < 20.0) {
                        if (bfar > 25.0) _ = toward(w, &h, b.x, b.z);
                        _ = face(w, &h, b.x, b.z);
                        return h;
                    }
                }
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
                // first a breath: stand silent until it is full, for the wheel's jump costs a home
                if (self.breathed_at == null) {
                    if (w.winded or w.breath < @as(f32, @floatFromInt(w.breath_most))) {
                        if (after > 60 * 20) self.breathed_at = after;
                        return h;
                    }
                    self.breathed_at = after;
                }
                const from = self.breathed_at.?;
                // stand still, hold R1: the wheel opens; point a twelfth of a turn left, at wonder,
                // and let go there
                if (after < from + 15) return h;
                if (after < from + 95) {
                    h.buttons |= Hands.call;
                    if (after >= from + 40) {
                        h.rx = -63;
                        h.ry = -110;
                    }
                    if (after == from + 80) self.mark = "wheel";
                    return h;
                }
                if (after > from + 110) self.next(step);
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
                // let go, and walk away from the water toward the hose's knot, so the swell is seen at
                // Hum's own height and the knots, stumbling, come out to meet it
                // until the knot is near enough for the knots to notice, and no nearer: Hum stays
                // on its side of the hose
                const k = world_mod.hose.knot;
                const kx = k[0] - w.hum_x;
                const kz = k[1] - w.hum_z;
                const near_knot = kx * kx + kz * kz < 150.0 * 150.0;
                if (!near_knot and after < 60 * 60) {
                    // round the puddle's water, not through it
                    const via = detour(w, k[0], k[1]);
                    _ = toward(w, &h, via[0], via[1]);
                    _ = face(w, &h, via[0], via[1]);
                } else if (self.waited_from == 0) {
                    self.waited_from = step;
                }
                if (self.waited_from != 0 and step > self.waited_from + 120) self.next(step);
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
                    self.knots_from = step;
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
                if (near and coloured and !self.placed_tried and w.clock % (4 * world_mod.tick_every) == 120) {
                    self.placed_tried = true;
                    h.buttons |= Hands.strike;
                    self.mark = "placed";
                }
                if (near and !coloured) self.next(step);
                // a minute and a half after they came, or three minutes waiting for them
                if ((self.knots_marked and step > self.knots_from + 60 * 90) or after > 60 * 180) self.next(step);
            },
            18 => {
                // the swell, Gentle: hold R2 and never touch the stick. After a bar home drifts
                // beside the grey knots on their amen side, sunny home; let go on the next downbeat,
                // the amen lands, and they settle and sleep (SPEC.md 6.1; design/the-wheel.md)
                h.buttons |= Hands.sing;
                // the knots are grey, and each leans toward the wedge on its left
                if (after > 12 and !self.lean_marked) {
                    self.lean_marked = true;
                    self.mark = "grey";
                }
                if (after > 30 and w.swell_bars >= 2 and !self.swell_marked) {
                    self.swell_marked = true;
                    self.mark = "swell";
                }
                if (w.leans_for_you > 0 and !self.nudged) {
                    self.nudged = true;
                    self.nudged_at = step;
                }
                if (self.nudged and w.downbeat_at != world_mod.never and w.downbeat_at + 1 == w.step and w.home_k == 0 and w.step > self.nudged_at + 60) {
                    h.buttons &= ~Hands.sing;
                    self.next(step);
                }
                if (after > 60 * 40) self.next(step);
            },
            19 => {
                // a while beside them as they sleep; every knot home, the hose springs open
                if (w.hose_open and !self.open_marked) {
                    self.open_marked = true;
                    self.mark = "open";
                }
                if (!self.asleep_marked and after > 60 * 3) {
                    self.asleep_marked = true;
                    self.mark = "asleep";
                }
                if (after > 60 * 4) self.next(step);
            },
            20 => {
                // to the north shore beside the hose's coil, staying north of the hose, and looking
                // along the edge to where the figure will sit, so it is seen from its side
                const view = [2]f32{ 40.0, -15.0 };
                const vx = view[0] - w.hum_x;
                const vz = view[1] - w.hum_z;
                if (vx * vx + vz * vz > 9.0) _ = toward(w, &h, view[0], view[1]);
                _ = face(w, &h, world_mod.figure_at[0], world_mod.figure_at[1]);
                if (w.water_at != world_mod.never and !self.water_marked and w.step > w.water_at + 20) {
                    self.water_marked = true;
                    self.mark = "water";
                }
                if (w.figureNow() and !self.edge_marked and w.step > w.figure_from + 25) {
                    self.edge_marked = true;
                    self.mark = "edge";
                }
                if (self.edge_marked and !w.figureNow()) self.next(step);
                if (after > 60 * 60) self.next(step);
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
    // it is a real walk: the 141 m to its foot, no quicker than a sprint can cover it
    try std.testing.expect(@as(f32, @floatFromInt(bot.arrived_at)) > 141.0 / world_mod.sprint_speed * 60.0);
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

test "through the whole first evening every thing and every ring keeps the ground under it" {
    // a thing's kept ground (world.zig, Thing.ground) must be the ground under it wherever it has
    // moved: the bee flying, the knots lunging, the hose's drone following Hum along it
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    var bot = Walker{};
    var cues: [world_mod.max_cues]@import("../sound/sound.zig").Cue = undefined;
    var moved_bee = false;
    var bee_was = [2]f32{ 0.0, 0.0 };
    while (!bot.done and w.step < 60 * 60 * 14) {
        _ = w.stepOnce(bot.hands(w), &cues);
        if (w.step % 30 == 0) try std.testing.expect(w.groundsTrue());
        if (w.bee.thing != world_mod.no_thing) {
            const me = w.things[w.bee.thing];
            if (w.step > 1 and (me.x != bee_was[0] or me.z != bee_was[1])) moved_bee = true;
            bee_was = .{ me.x, me.z };
        }
    }
    try std.testing.expect(bot.done);
    try std.testing.expect(moved_bee);
    try std.testing.expect(w.knots_home > 0);
}
