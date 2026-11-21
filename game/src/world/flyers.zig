//! Who lives in the sky (spec/sky.md, "Who lives up there"). So far, the bee.
//!
//! One law for everything with wings: size is pitch, and speed is an interval. A bee's wings beat
//! at about 230 a second; this one hums the garden's own note, middle C, and flies at a fifth of
//! the speed of sound, so its note comes toward you a third high and goes away a sixth low: a
//! fifth between, heard as it passes (law 6). It works the clover low over the ground and now
//! and then a crown, and the bells it lands among answer its note (law 1).
const std = @import("std");
const world_mod = @import("world.zig");
const cues = @import("cue.zig");
const asters = @import("asters.zig");
const ground = @import("ground.zig");
const World = world_mod.World;

pub const Bee = struct {
    /// Which thing of the world the bee is.
    thing: u32 = world_mod.no_thing,
    /// Where it goes, in turn: four places over clover and one crown.
    stops: [5][3]f32 = @splat(.{ 0.0, 0.0, 0.0 }),
    crown_tower: u16 = 0,
    stop: u32 = 0,
    hover_left: u32 = 0,
    vel: [3]f32 = .{ 0.0, 0.0, 0.0 },
    flying: bool = false,
    visits: u32 = 0,

    /// A fifth of the speed of sound: approach over leave is 1.25 / 0.833, a pure fifth.
    pub const speed: f32 = world_mod.sound_speed / 5.0;
    pub const hover_steps: u32 = 150;
    /// Its buzz carries this far before it has fallen to half.
    pub const carry: f32 = 70.0;
    pub const buzz_every: u32 = 3;
    /// It works the clover this high: just over the roof.
    pub const over_clover: f32 = 8.0;

    /// Set the bee out: four places over clover near `near`, and the crown of `tower`.
    pub fn place(self: *Bee, w: *World, thing: u32, near: [2]f32, tower: u16) void {
        self.* = .{ .thing = thing, .crown_tower = tower };
        var found: usize = 0;
        var ring: f32 = 20.0;
        while (ring < 260.0 and found < 4) : (ring += 18.0) {
            var k: u32 = 0;
            while (k < 12 and found < 4) : (k += 1) {
                const a = @as(f32, @floatFromInt(k)) * (6.2831853 / 12.0) + ring * 0.05;
                const x = near[0] + ring * @cos(a);
                const z = near[1] + ring * @sin(a);
                if (ground.coverAt(x, z) != .clover or ground.wet(x, z)) continue;
                // not two stops close together
                var apart = true;
                for (self.stops[0..found]) |s| {
                    const dx = s[0] - x;
                    const dz = s[2] - z;
                    if (dx * dx + dz * dz < 40.0 * 40.0) apart = false;
                }
                if (!apart) continue;
                self.stops[if (found < 2) found else found + 1] = .{ x, over_clover, z };
                found += 1;
            }
        }
        // the crown is the third stop
        const t = w.towers[tower];
        self.stops[2] = .{ t.x + t.bow_x * 0.74, t.tall * 0.86 + 4.0, t.z + t.bow_z * 0.74 };
        const me = &w.things[thing];
        me.x = self.stops[0][0];
        me.y = self.stops[0][1];
        me.z = self.stops[0][2];
    }

    pub fn step(self: *Bee, w: *World) void {
        if (self.thing == world_mod.no_thing) return;
        // it flies by day, once the world has stood up
        if (!self.flying) {
            if (w.stand < 1.0 or w.dawnAge() < 0.0) return;
            self.flying = true;
        }
        const me = &w.things[self.thing];
        const target = self.stops[self.stop % self.stops.len];
        const was = [3]f32{ me.x, me.y, me.z };
        if (self.hover_left > 0) {
            // hovering: a small figure of eight over the flower
            self.hover_left -= 1;
            const t = @as(f32, @floatFromInt(hover_steps - self.hover_left)) * world_mod.dt;
            me.x = target[0] + 2.4 * @sin(t * 2.6);
            me.y = target[1] + 0.8 * @sin(t * 5.2);
            me.z = target[2] + 1.2 * @sin(t * 5.2);
            if (self.hover_left == 0) self.stop += 1;
        } else {
            const dx = target[0] - me.x;
            const dy = target[1] - me.y;
            const dz = target[2] - me.z;
            const far = @sqrt(dx * dx + dy * dy + dz * dz);
            const stride = speed * world_mod.dt;
            if (far <= stride) {
                me.x = target[0];
                me.y = target[1];
                me.z = target[2];
                self.hover_left = hover_steps;
                self.visits += 1;
                if (self.stop % self.stops.len == 2) self.ringCrown(w);
            } else {
                me.x += dx / far * stride;
                me.y += dy / far * stride;
                me.z += dz / far * stride;
            }
        }
        self.vel = .{ (me.x - was[0]) / world_mod.dt, (me.y - was[1]) / world_mod.dt, (me.z - was[2]) / world_mod.dt };
        // its buzz: the garden's note at the bee, heard bent by how fast it comes or goes
        if (w.clock % buzz_every == 0) {
            const hx = w.hum_x - me.x;
            const hy = 0.5 - me.y;
            const hz = w.hum_z - me.z;
            const far = @max(@sqrt(hx * hx + hy * hy + hz * hz), 0.1);
            // flying, its buzz is bent by how fast it comes or goes (law 6); hovering at a flower
            // it has fallen into step with it (law 3), and its buzz holds still
            const toward = if (self.hover_left > 0) 0.0 else (self.vel[0] * hx + self.vel[1] * hy + self.vel[2] * hz) / far;
            const bent = me.hz * world_mod.sound_speed / (world_mod.sound_speed - toward);
            // bent by its going (law 6), its buzz falls into step on the nearest note of the
            // garden's own chord (law 3): it rises as it comes and falls as it goes, in steps that
            // agree with everything held, instead of sliding through them (spec/laws.md, For the ears)
            const heard = inChord(bent);
            const buzz: f32 = 0.5;
            w.tell(.{ .thing = self.thing }, .{
                .sound = .{ .kind = .hum_on, .voice = 2, .hz = heard, .strength = buzz, .ring = 0.0 },
                // its light is at the bee and in the bee's own note
                .light = .{ .hz = me.hz, .brightness = @sqrt(buzz), .fades = 0.3, .shape = .glow },
            });
        }
    }

    /// Landing among a crown's bells, it rings the ones kin to its note, softly.
    fn ringCrown(self: *Bee, w: *World) void {
        const tower = w.towers[self.crown_tower];
        const first = tower.first + asters.segments;
        const last = tower.first + tower.count;
        var i = first;
        while (i < last) : (i += 1) {
            const bell = w.things[i];
            const rec = @import("../sound/sound.zig").recipe(bell.family);
            const kin = world_mod.sympathy(w.things[self.thing].hz, bell.hz, rec.mult, rec.gain);
            if (kin < 0.3) continue;
            w.tell(.{ .thing = i }, cues.Cue.of(.{ .kind = .strike, .family = bell.family, .hz = bell.hz, .strength = 0.3 * kin, .ring = bell.ring }, .glow));
            // and they pass it on to their kin, as anything rung does (law 1)
            w.things[i].rung_at = @truncate(w.step);
            w.passOn(@intCast(i), 0.3 * kin, false);
        }
    }
};

/// The nearest note of the garden's chord (its note, third, fifth and sixth, in any octave) to a pitch:
/// coming, a bee is heard a third up, and going, a sixth under, a pure fifth between them.
pub fn inChord(hz: f32) f32 {
    const root = world_mod.garden_hz;
    var octave: f32 = 1.0;
    var f = hz;
    while (f >= root * 2.0) {
        f *= 0.5;
        octave *= 2.0;
    }
    while (f < root) {
        f *= 2.0;
        octave *= 0.5;
    }
    const r = f / root;
    var best: f32 = 1.0;
    var best_off: f32 = 1e9;
    for ([_]f32{ 1.0, 1.25, 1.5, 5.0 / 3.0, 2.0 }) |n| {
        const off = @max(r / n, n / r);
        if (off < best_off) {
            best_off = off;
            best = n;
        }
    }
    return root * best * octave;
}
