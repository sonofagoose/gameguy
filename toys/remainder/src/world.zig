//! The rules of the toy, with no platform code. Places each hold a tone; the player holds a
//! tone. The one rule under test: where the player's tone agrees with a place, the water
//! between them stands still; where it is a little off, the pattern turns, and the turning
//! carries the player. The remainder is the current.
const std = @import("std");
const tuning = @import("tuning.zig");

pub const max_places = 12;
pub const pool_w: f32 = 640.0;
pub const pool_h: f32 = 480.0;
pub const pool_count = 3;
pub const pool_names = [pool_count][]const u8{ "ONE", "THREE", "TWELVE" };

/// Everything about how it feels, in one place, so it can be tuned after a play session.
pub const Feel = struct {
    /// Pitch of a pool's first place when the pool's register is 0.
    ref_hz: f64 = 220.0,
    /// Two partials beating slower than this are felt as one moving pattern.
    beat_limit_hz: f64 = 12.0,
    /// Distance between crests of a pattern, in pixels. One crest passes per beat.
    ring_px: f32 = 56.0,
    /// Beat rate at which a pattern carries hardest. Lean much harder and it lets go.
    grip_hz: f32 = 3.5,
    /// Beat rate by which a pattern has mostly blurred away on screen.
    clear_hz: f32 = 8.5,
    /// How far a place's pattern reaches.
    reach_px: f32 = 220.0,
    /// How far a place's tone carries.
    hear_px: f32 = 190.0,
    /// Heaviness: seconds to take on a new current.
    glide_s: f32 = 0.5,
    /// Speed of the left-stick paddle.
    paddle_px_s: f32 = 34.0,
    /// Lean mode: beat rate at full stick. Letting go returns to the settled tone.
    lean_beat_hz: f64 = 8.0,
    /// Peg mode: how fast full stick retunes, in beats per second per second. Letting go holds.
    peg_beat_hz_s: f64 = 5.0,
    /// Slower than this counts as agreement.
    lock_beat_hz: f64 = 0.12,
    /// Agreement must be held this long before a place blooms.
    lock_hold_s: f32 = 1.2,
    /// Places have a body; the player cannot come closer than this.
    body_px: f32 = 16.0,
};

pub const Mode = enum { lean, peg };

pub const Input = struct {
    /// Right stick, -1..1. Positive is sharp.
    lean: f32 = 0.0,
    paddle_x: f32 = 0.0,
    paddle_y: f32 = 0.0,
    fifth_up: bool = false,
    fifth_down: bool = false,
    octave_up: bool = false,
    octave_down: bool = false,
    home: bool = false,
    toggle_mode: bool = false,
    toggle_paddle: bool = false,
    next_pool: bool = false,
    /// Move the whole pool (places and player together) up or down an octave.
    pool_up: bool = false,
    pool_down: bool = false,
};

pub const Place = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    /// Pitch above the pool's reference, in cents.
    cents: f64 = 0.0,
    /// The partials this place and the player currently nearly share, if any.
    pair: ?tuning.Pair = null,
    /// Phase of the pattern between this place and the player, in turns.
    turns: f64 = 0.0,
    /// Arms of the pattern (the place's partial number in the shared pair).
    arms: u8 = 1,
    /// Smoothed visibility of the pattern, 0..1.
    strength: f32 = 0.0,
    /// How well the player hears this place, 0..1.
    near: f32 = 0.0,
    lock_s: f32 = 0.0,
    /// 0..1, grows while agreement is held.
    bloom: f32 = 0.0,
};

pub const EventKind = enum { pool, mode, paddle, home, fifth, octave, register, bloom };
pub const Event = struct {
    time: f64,
    kind: EventKind,
    /// pool index, mode, fifth count, octave, or place index
    value: i32,
    /// for `bloom`: how far the peg sat from the settled tone, in cents
    cents: f64 = 0.0,
};

pub const World = struct {
    feel: Feel = .{},
    pool: u8 = 0,
    places: [max_places]Place = @splat(.{}),
    count: usize = 0,

    x: f32 = 0.0,
    y: f32 = 0.0,
    vx: f32 = 0.0,
    vy: f32 = 0.0,

    /// The tone reached by walking fifths from home, folded into one octave.
    base_cents: f64 = 0.0,
    /// Retuning that stays (peg mode).
    peg_cents: f64 = 0.0,
    /// Retuning that lasts only while the stick is held (lean mode).
    lean_cents: f64 = 0.0,
    octave: i8 = 0,
    /// Register of the whole pool, in octaves above `feel.ref_hz`. It changes nothing about
    /// the rules; it is there to find where the tones carry best on a small speaker.
    pool_octave: i8 = 1,
    /// Net count of fifths walked from home.
    fifths: i32 = 0,

    mode: Mode = .lean,
    paddle: bool = true,
    time: f64 = 0.0,
    /// The place whose pattern carries the player hardest right now.
    anchor: ?usize = null,

    events: [64]Event = undefined,
    event_count: usize = 0,

    pub fn init(pool: u8) World {
        var self = World{};
        self.loadPool(pool);
        return self;
    }

    pub fn loadPool(self: *World, pool: u8) void {
        self.pool = pool % pool_count;
        self.places = @splat(.{});
        self.vx = 0.0;
        self.vy = 0.0;
        self.base_cents = 0.0;
        self.peg_cents = 0.0;
        self.lean_cents = 0.0;
        self.octave = 0;
        self.fifths = 0;
        self.anchor = null;
        switch (self.pool) {
            // One place. The player starts beside it, in agreement.
            0 => {
                self.count = 1;
                self.places[0] = .{ .x = 320.0, .y = 240.0, .cents = 0.0 };
                self.x = 430.0;
                self.y = 240.0;
            },
            // Three places that all agree with each other: 1, 5/4, 3/2.
            1 => {
                self.count = 3;
                self.places[0] = .{ .x = 320.0, .y = 110.0, .cents = 0.0 };
                self.places[1] = .{ .x = 150.0, .y = 370.0, .cents = tuning.fifth_cents };
                self.places[2] = .{ .x = 490.0, .y = 370.0, .cents = tuning.centsFromRatio(5.0 / 4.0) };
                self.x = 320.0;
                self.y = 270.0;
            },
            // Twelve places on a wheel, each a pure fifth from the one before. The twelfth
            // fifth lands a comma past the first: the wheel cannot close.
            else => {
                self.count = 12;
                for (0..12) |k| {
                    const angle = (@as(f32, @floatFromInt(k)) * 30.0 - 90.0) * std.math.pi / 180.0;
                    self.places[k] = .{
                        .x = 320.0 + 195.0 * @cos(angle),
                        .y = 240.0 + 195.0 * @sin(angle),
                        .cents = tuning.fold(@as(f64, @floatFromInt(k)) * tuning.fifth_cents),
                    };
                }
                self.x = 320.0;
                self.y = 110.0;
            },
        }
        self.note(.pool, self.pool, 0.0);
    }

    fn note(self: *World, kind: EventKind, value: i32, cents: f64) void {
        if (self.event_count == self.events.len) return;
        self.events[self.event_count] = .{ .time = self.time, .kind = kind, .value = value, .cents = cents };
        self.event_count += 1;
    }

    /// Hand the recorded events to the caller and forget them.
    pub fn drainEvents(self: *World, out: []Event) usize {
        const n = @min(out.len, self.event_count);
        @memcpy(out[0..n], self.events[0..n]);
        self.event_count = 0;
        return n;
    }

    fn hz(self: *const World, cents: f64, octave: i8) f64 {
        const octaves: f64 = @floatFromInt(@as(i32, octave) + self.pool_octave);
        return self.feel.ref_hz * tuning.ratioFromCents(cents + 1200.0 * octaves);
    }

    /// The player's tone with the stick at rest.
    pub fn settledHz(self: *const World) f64 {
        return self.hz(self.base_cents + self.peg_cents, self.octave);
    }

    pub fn playerHz(self: *const World) f64 {
        return self.hz(self.base_cents + self.peg_cents + self.lean_cents, self.octave);
    }

    pub fn placeHz(self: *const World, index: usize) f64 {
        return self.hz(self.places[index].cents, 0);
    }

    fn distanceTo(self: *const World, index: usize) f32 {
        const dx = self.x - self.places[index].x;
        const dy = self.y - self.places[index].y;
        return @sqrt(dx * dx + dy * dy);
    }

    fn falloff(dist: f32, scale: f32) f32 {
        const q = dist / scale;
        return 1.0 / (1.0 + q * q);
    }

    /// The partial of the player's tone that matters most at this pitch: the one in the
    /// strongest nearby agreement. The stick is scaled by it so "this much stick" always means
    /// "this much beating".
    fn leadingPartial(self: *const World, player_hz: f64) u8 {
        var best_score: f64 = 0.0;
        var best_m: u8 = 1;
        for (0..self.count) |i| {
            const pair = tuning.nearestPair(player_hz, self.placeHz(i), self.feel.beat_limit_hz) orelse continue;
            const score = pair.weight * falloff(self.distanceTo(i), self.feel.reach_px);
            if (score > best_score) {
                best_score = score;
                best_m = pair.m;
            }
        }
        return best_m;
    }

    pub fn step(self: *World, in: Input, dt: f32) void {
        const feel = self.feel;

        if (in.next_pool) self.loadPool((self.pool + 1) % pool_count);
        if (in.toggle_mode) {
            self.mode = if (self.mode == .lean) .peg else .lean;
            self.note(.mode, @backingInt(self.mode), 0.0);
        }
        if (in.toggle_paddle) {
            self.paddle = !self.paddle;
            self.note(.paddle, @intFromBool(self.paddle), 0.0);
        }
        if (in.home) {
            self.base_cents = 0.0;
            self.peg_cents = 0.0;
            self.octave = 0;
            self.fifths = 0;
            self.note(.home, 0, 0.0);
        }
        if (in.fifth_up) {
            self.base_cents = tuning.fold(self.base_cents + tuning.fifth_cents);
            self.fifths += 1;
            self.note(.fifth, self.fifths, 0.0);
        }
        if (in.fifth_down) {
            self.base_cents = tuning.fold(self.base_cents - tuning.fifth_cents);
            self.fifths -= 1;
            self.note(.fifth, self.fifths, 0.0);
        }
        if (in.octave_up and self.octave < 2) {
            self.octave += 1;
            self.note(.octave, self.octave, 0.0);
        }
        if (in.octave_down and self.octave > -1) {
            self.octave -= 1;
            self.note(.octave, self.octave, 0.0);
        }
        if (in.pool_up and self.pool_octave < 2) {
            self.pool_octave += 1;
            self.note(.register, self.pool_octave, 0.0);
        }
        if (in.pool_down and self.pool_octave > -1) {
            self.pool_octave -= 1;
            self.note(.register, self.pool_octave, 0.0);
        }

        // The stick is the remainder. Cubed, so the middle of its travel is fine control.
        const settled = self.settledHz();
        const partial = self.leadingPartial(settled);
        const curve: f64 = @as(f64, in.lean) * @as(f64, in.lean) * @as(f64, in.lean);
        switch (self.mode) {
            .lean => self.lean_cents = tuning.centsForBeat(settled, partial, curve * feel.lean_beat_hz),
            .peg => {
                self.lean_cents = 0.0;
                self.peg_cents += tuning.centsForBeat(settled, partial, curve * feel.peg_beat_hz_s * dt);
            },
        }

        // Every place the player nearly agrees with turns its pattern at the beat rate, and the
        // pattern carries the player along with it.
        const player_hz = self.playerHz();
        var carry_x: f32 = 0.0;
        var carry_y: f32 = 0.0;
        var anchor: ?usize = null;
        var anchor_pull: f32 = 0.0;
        const settle = 1.0 - @exp(-dt * 6.0);
        for (self.places[0..self.count], 0..) |*place, i| {
            const dx = self.x - place.x;
            const dy = self.y - place.y;
            const dist = @max(@sqrt(dx * dx + dy * dy), 1.0);
            const reach = falloff(dist, feel.reach_px);
            place.near = falloff(dist, feel.hear_px);
            place.pair = tuning.nearestPair(player_hz, self.placeHz(i), feel.beat_limit_hz);

            var want_strength: f32 = 0.0;
            var agreeing = false;
            if (place.pair) |pair| {
                const weight: f32 = @floatCast(pair.weight);
                const beat: f32 = @floatCast(pair.beat_hz);
                place.arms = pair.n;
                place.turns += pair.beat_hz * dt;
                place.turns -= @floor(place.turns);
                // fast beating is roughness, not a pattern: it blurs out as the beat quickens
                const blur = beat / feel.clear_hz;
                want_strength = weight * reach * @exp(-blur * blur);

                // The pattern's phase, in turns: distance / ring + arms * angle / 2pi - turns.
                // A point of constant phase moves along the phase gradient at beat / |gradient|.
                const ex = dx / dist;
                const ey = dy / dist;
                const radial = 1.0 / feel.ring_px;
                const around = @as(f32, @floatFromInt(pair.n)) / (2.0 * std.math.pi * @max(dist, feel.body_px));
                const gx = radial * ex - around * ey;
                const gy = radial * ey + around * ex;
                const g2 = gx * gx + gy * gy;
                // carry = beat * grip peaks at grip_hz; beating much faster than that lets go
                const ratio = beat / (feel.grip_hz * std.math.sqrt2);
                const grip = @exp(-ratio * ratio);
                const pull = beat * grip * weight * reach;
                carry_x += pull * gx / g2;
                carry_y += pull * gy / g2;

                if (want_strength > anchor_pull) {
                    anchor_pull = want_strength;
                    anchor = i;
                }
                agreeing = @abs(pair.beat_hz) < feel.lock_beat_hz and place.near > 0.25;
            }
            place.strength += (want_strength - place.strength) * settle;

            const was_open = place.lock_s >= feel.lock_hold_s;
            if (agreeing) {
                place.lock_s = @min(place.lock_s + dt, feel.lock_hold_s + 1.0);
            } else {
                place.lock_s = @max(place.lock_s - 2.0 * dt, 0.0);
            }
            place.bloom = std.math.clamp(place.lock_s / feel.lock_hold_s, 0.0, 1.0);
            if (!was_open and place.lock_s >= feel.lock_hold_s) {
                self.note(.bloom, @intCast(i), self.peg_cents);
            }
        }
        self.anchor = anchor;

        if (self.paddle) {
            carry_x += in.paddle_x * feel.paddle_px_s;
            carry_y += in.paddle_y * feel.paddle_px_s;
        }

        // Heavy on the frame: the player takes on a current slowly and keeps it a while.
        const take = 1.0 - @exp(-dt / feel.glide_s);
        self.vx += (carry_x - self.vx) * take;
        self.vy += (carry_y - self.vy) * take;
        self.x += self.vx * dt;
        self.y += self.vy * dt;

        // Places have a body.
        for (self.places[0..self.count]) |place| {
            const dx = self.x - place.x;
            const dy = self.y - place.y;
            const dist = @sqrt(dx * dx + dy * dy);
            if (dist < feel.body_px and dist > 0.001) {
                const ex = dx / dist;
                const ey = dy / dist;
                self.x = place.x + ex * feel.body_px;
                self.y = place.y + ey * feel.body_px;
                const inward = self.vx * ex + self.vy * ey;
                if (inward < 0.0) {
                    self.vx -= inward * ex;
                    self.vy -= inward * ey;
                }
            }
        }

        // The pool has an edge.
        const margin = 10.0;
        if (self.x < margin) {
            self.x = margin;
            self.vx = @max(self.vx, 0.0);
        }
        if (self.x > pool_w - margin) {
            self.x = pool_w - margin;
            self.vx = @min(self.vx, 0.0);
        }
        if (self.y < margin) {
            self.y = margin;
            self.vy = @max(self.vy, 0.0);
        }
        if (self.y > pool_h - margin) {
            self.y = pool_h - margin;
            self.vy = @min(self.vy, 0.0);
        }

        self.time += dt;
    }
};

fn stepFor(world: *World, in: Input, seconds: f32) void {
    const dt: f32 = 1.0 / 60.0;
    var t: f32 = 0.0;
    while (t < seconds) : (t += dt) world.step(in, dt);
}

fn gap(world: *const World, index: usize) f32 {
    const dx = world.x - world.places[index].x;
    const dy = world.y - world.places[index].y;
    return @sqrt(dx * dx + dy * dy);
}

test "in agreement the player stays put" {
    var world = World.init(0);
    const start = gap(&world, 0);
    stepFor(&world, .{}, 5.0);
    try std.testing.expectApproxEqAbs(start, gap(&world, 0), 0.01);
    try std.testing.expect(world.places[0].bloom == 1.0);
}

test "leaning sharp carries the player away, leaning flat draws the player in" {
    var sharp = World.init(0);
    const start = gap(&sharp, 0);
    stepFor(&sharp, .{ .lean = 0.7 }, 2.0);
    try std.testing.expect(gap(&sharp, 0) > start + 20.0);

    var flat = World.init(0);
    stepFor(&flat, .{ .lean = -0.7 }, 2.0);
    try std.testing.expect(gap(&flat, 0) < start - 20.0);
}

test "letting go of the stick brings the player to rest" {
    var world = World.init(0);
    stepFor(&world, .{ .lean = 0.7 }, 1.0);
    stepFor(&world, .{}, 4.0);
    try std.testing.expect(@abs(world.vx) < 0.5 and @abs(world.vy) < 0.5);
}

test "a full stick beats at the lean rate in every register" {
    var world = World.init(0);
    world.step(.{ .lean = 1.0 }, 1.0 / 60.0);
    try std.testing.expectApproxEqAbs(world.feel.lean_beat_hz, world.places[0].pair.?.beat_hz, 1e-6);
    world.step(.{ .lean = 1.0, .octave_up = true }, 1.0 / 60.0);
    // an octave up, partial 1 of the player meets partial 2 of the place
    try std.testing.expectEqual(@as(u8, 2), world.places[0].pair.?.n);
    try std.testing.expectApproxEqAbs(world.feel.lean_beat_hz, world.places[0].pair.?.beat_hz, 1e-6);
}

test "peg mode holds its retuning after the stick is released" {
    var world = World.init(0);
    world.step(.{ .toggle_mode = true }, 1.0 / 60.0);
    stepFor(&world, .{ .lean = 0.8 }, 1.0);
    const held = world.peg_cents;
    try std.testing.expect(held > 1.0);
    stepFor(&world, .{}, 1.0);
    try std.testing.expectApproxEqAbs(held, world.peg_cents, 1e-9);
}

test "twelve fifths around the wheel leave a comma, and the first place turns" {
    var world = World.init(2);
    world.paddle = false;
    world.pool_octave = 0;
    for (0..12) |_| world.step(.{ .fifth_up = true }, 1.0 / 60.0);
    try std.testing.expectApproxEqAbs(tuning.comma_cents, world.base_cents, 1e-6);
    const pair = world.places[0].pair.?;
    try std.testing.expectEqual(@as(u8, 1), pair.m);
    try std.testing.expectEqual(@as(u8, 1), pair.n);
    // 220 Hz raised by a comma beats about 3 times a second against 220 Hz
    try std.testing.expectApproxEqAbs(@as(f64, 3.0), pair.beat_hz, 0.05);
}

test "each fifth walked agrees exactly with the next place on the wheel" {
    var world = World.init(2);
    for (1..12) |k| {
        world.step(.{ .fifth_up = true }, 1.0 / 60.0);
        const hz_player = world.playerHz();
        const hz_place = world.placeHz(k);
        // same pitch class: the ratio is a power of two
        const octaves = @log2(hz_player / hz_place);
        try std.testing.expectApproxEqAbs(@round(octaves), octaves, 1e-9);
    }
}

test "the player never leaves the pool or enters a place" {
    var world = World.init(1);
    var seed: u32 = 12345;
    for (0..6000) |i| {
        seed = seed *% 1664525 +% 1013904223;
        const lean = @as(f32, @floatFromInt(seed >> 16 & 0xff)) / 127.5 - 1.0;
        world.step(.{ .lean = lean, .fifth_up = i % 97 == 0, .paddle_x = 1.0 }, 1.0 / 60.0);
        try std.testing.expect(world.x >= 9.9 and world.x <= pool_w - 9.9);
        try std.testing.expect(world.y >= 9.9 and world.y <= pool_h - 9.9);
        for (0..world.count) |p| try std.testing.expect(gap(&world, p) >= world.feel.body_px - 0.01);
    }
}
