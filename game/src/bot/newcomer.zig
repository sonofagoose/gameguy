//! Newcomers: scripted players who know nothing, for the first evening's teaching (the plan: the
//! game teaches itself). One copies what Drip shows, letting go late by a person's reaction, as
//! Morgan did on his first evening (220 to 360 ms after the tick). One presses R2 at random. Both
//! stand beside Drip in the dark. They must get in: a player with poor timing takes longer and still
//! gets there (spec/promises/first-evening.md, evening.breathe).
const std = @import("std");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const Hands = world_mod.Hands;

/// A small, fixed sequence of numbers, so a newcomer does the same every run.
const Dice = struct {
    s: u32,
    fn next(self: *Dice) u32 {
        self.s ^= self.s << 13;
        self.s ^= self.s >> 17;
        self.s ^= self.s << 5;
        return self.s;
    }
    fn between(self: *Dice, lo: u32, hi: u32) u32 {
        return lo + self.next() % (hi - lo + 1);
    }
};

/// Copies Drip: once it has seen Drip hum and let go, it hums from a tick and lets go a reaction
/// after the third tick it hears.
pub const Copier = struct {
    dice: Dice = .{ .s = 0x2545f491 },
    seen_drip: bool = false,
    humming: bool = false,
    ticks_heard: u32 = 0,
    was_after: bool = true,
    late_ms: u32 = 0,
    rest_until: u64 = 0,

    pub fn hands(self: *Copier, w: *const World) Hands {
        if (w.drip_shows > 0 and !w.drip_showing) self.seen_drip = true;
        if (!self.seen_drip or w.step < self.rest_until) return .{};
        const off = w.afterHeardTick(w.step * world_mod.samples_per_step);
        const after = off >= 0;
        // a tick heard: the moment the nearest tick goes from ahead to behind
        const heard = after and !self.was_after;
        self.was_after = after;
        if (!self.humming) {
            if (heard) {
                self.humming = true;
                self.ticks_heard = 0;
                self.late_ms = self.dice.between(220, 360);
            }
            return if (self.humming) .{ .buttons = Hands.sing } else .{};
        }
        if (heard) self.ticks_heard += 1;
        if (self.ticks_heard >= 3 and @divTrunc(off, 48) >= self.late_ms) {
            self.humming = false;
            self.rest_until = w.step + self.dice.between(40, 120);
            return .{};
        }
        return .{ .buttons = Hands.sing };
    }
};

/// Presses R2 for a while and lets go, at random, with nothing to do with the ticks.
pub const Guesser = struct {
    dice: Dice = .{ .s = 0x9e3779b9 },
    until: u64 = 0,
    humming: bool = false,

    pub fn hands(self: *Guesser, w: *const World) Hands {
        if (w.step >= self.until) {
            self.humming = !self.humming;
            self.until = w.step + (if (self.humming) self.dice.between(30, 240) else self.dice.between(20, 120));
        }
        return if (self.humming) .{ .buttons = Hands.sing } else .{};
    }
};

/// The first evening, with Hum set down beside Drip in the dark, still.
fn besideDrip(w: *World) void {
    w.initEvening();
    const d = w.things[w.drip];
    w.hum_x = d.x + 2.0;
    w.hum_z = d.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
}

const Cue = @import("../sound/sound.zig").Cue;

test "beside a silent Hum Drip shows its breath: it hums from a downbeat and lets go on a tick" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    besideDrip(w);
    var cues: [world_mod.max_cues]Cue = undefined;
    var on_at: ?u64 = null;
    var off_on_tick = false;
    var step: u32 = 0;
    while (step < 60 * 20) : (step += 1) {
        const n = w.stepOnce(.{}, &cues);
        for (cues[0..n]) |cue| {
            if (cue.voice != 1) continue;
            if (cue.kind == .hum_on and on_at == null) on_at = w.step;
            // a cue leaves the world a few steps ahead of its sample: judge the sample it is for
            if (cue.kind == .hum_off and on_at != null and world_mod.fromTick(cue.at / world_mod.samples_per_step) <= 4) off_on_tick = true;
        }
        // the figure is their beating: with Hum silent there is none
        try std.testing.expectEqual(@as(f32, 0.0), w.figureLight());
    }
    try std.testing.expect(on_at != null);
    try std.testing.expect(off_on_tick);
    try std.testing.expect(w.drip_shows >= 2);
    // Hum hums: the figure blooms, and Drip hums with Hum instead of showing
    _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.sing }, &cues);
    try std.testing.expect(w.figureLight() > 0.0);
    try std.testing.expect(!w.drip_showing);
}

test "a newcomer who copies Drip, letting go a reaction late, gets in within eight breaths" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    besideDrip(w);
    var who = Copier{};
    var cues: [world_mod.max_cues]Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 180 and w.locked_at == world_mod.never) : (step += 1) _ = w.stepOnce(who.hands(w), &cues);
    try std.testing.expect(w.locked_at != world_mod.never);
    try std.testing.expect(w.breaths_tried <= 8);
}

test "a newcomer pressing R2 at random, nothing to do with the ticks, still gets in" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    besideDrip(w);
    var who = Guesser{};
    var cues: [world_mod.max_cues]Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 300 and w.locked_at == world_mod.never) : (step += 1) _ = w.stepOnce(who.hands(w), &cues);
    try std.testing.expect(w.locked_at != world_mod.never);
}

test "in the dark the knots lie still: walked right up to, they never come or knock" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    const kn = w.knots[0];
    w.hum_x = kn.x + 20.0;
    w.hum_z = kn.z;
    w.hum_ground = w.groundAt(w.hum_x, w.hum_z);
    var cues: [world_mod.max_cues]Cue = undefined;
    var step: u32 = 0;
    while (step < 60 * 30) : (step += 1) _ = w.stepOnce(.{}, &cues);
    try std.testing.expectEqual(@as(u32, 0), w.knocked);
    try std.testing.expectEqual(kn.x, w.knots[0].x);
    try std.testing.expectEqual(kn.z, w.knots[0].z);
}

test "on the page a face button with no verb yet is still answered, softly" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    var cues: [world_mod.max_cues]Cue = undefined;
    _ = w.stepOnce(.{}, &cues);
    _ = w.stepOnce(.{ .buttons = Hands.strike }, &cues);
    try std.testing.expectEqual(@as(u32, 1), w.dark_presses);
    try std.testing.expect(w.hum_light > 0.3);
}
