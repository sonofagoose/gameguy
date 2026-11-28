//! Drip (spec/people.md): a drop that never finished falling.
//! Rhythm is pitch slowed down (Law 3). Drip keeps time for the Garden,
//! acts as Hum's traveling companion, and sleeps during peaceful exploration
//! to prevent metronome auditory fatigue.
const std = @import("std");

pub const DripMood = enum {
    hanging,
    entraining,
    hopping,
    waiting,
    awake,
    asleep,
    waking,
    guiding,
};

pub const DripState = struct {
    mood: DripMood = .hanging,
    peaceful_beats: u32 = 0,
    sleep_after_bars: u32 = 2, // 2 bars = 8 beats of peaceful exploration before sleep
    wake_anim: f32 = 0.0,
    squash_y: f32 = 1.0,
    squash_xz: f32 = 1.0,
    tilt_x: f32 = 0.0,
    tilt_z: f32 = 0.0,
    bob_phase: f32 = 0.0,
    /// Expanding crown halo pulse (1.0 -> 0.0) and beat weight (1.0 on 1, 0.58 on 3, 0.34 on 2/4)
    /// so Drip's active ticking reads unmistakably at a glance on the 3.5" handheld screen.
    beat_pulse: f32 = 0.0,
    beat_accent: f32 = 0.0,

    /// Whether Drip's metronome tick should sound audibly.
    /// Single source of truth for auditory balance.
    pub fn isAudible(self: *const DripState, w: anytype, far: f32) bool {
        // While at the faucet or in the dark before meeting, always audible
        if (!w.drip_met) return true;
        // While demonstrating the jump over the coil or waiting beyond it, always audible
        if (w.drip_out != 0) return true;
        // While actively singing, wheel is open, threatened/combat, or entraining
        if (w.singing or w.wheel_open or w.threatened() or w.step < w.hold_until) return true;
        // While waking up
        if (self.wake_anim > 0.0) return true;
        // Note: when riding on Hum's head (`w.drip_met and w.drip_out == 0`), `far` is always 0;
        // only apply proximity audibility when Drip is off Hum's head.
        if ((!w.drip_met or w.drip_out != 0) and far <= 4.0) return true;
        // In open exploration on Hum's head: silent when asleep
        return self.mood != .asleep;
    }

    /// Called on each metronome beat (legacy convenience wrapper).
    pub fn onBeat(self: *DripState, is_one: bool, peaceful: bool) void {
        self.onBeatDetail(if (is_one) 0 else 1, peaceful, true);
    }

    /// Called on each metronome beat with exact 4/4 beat index (`0..3`) and whether the tick sounded.
    pub fn onBeatDetail(self: *DripState, beat_in_bar: u64, peaceful: bool, audible: bool) void {
        const is_one = (beat_in_bar == 0);
        if (peaceful) {
            self.peaceful_beats += 1;
            if (self.peaceful_beats >= self.sleep_after_bars * 4) {
                self.mood = .asleep;
            }
        } else {
            self.wake();
        }

        if (self.mood == .awake or self.mood == .waking) {
            // Crisp beat recoil: deep punch on beat 1, warm bounce on 3, nimble tap on 2/4
            self.squash_y = switch (beat_in_bar) {
                0 => 0.68,
                2 => 0.80,
                else => 0.88,
            };
            self.squash_xz = 1.0 / @sqrt(self.squash_y);
            if (audible) {
                self.beat_pulse = 1.0;
                self.beat_accent = switch (beat_in_bar) {
                    0 => 1.0,
                    2 => 0.58,
                    else => 0.34,
                };
            }
        } else if (self.mood == .asleep) {
            // Gentle flat sleep breathing on beat 1 only (no bright pulse ring)
            if (is_one) {
                self.squash_y = 0.54;
                self.squash_xz = 1.0 / @sqrt(self.squash_y);
            }
        }
    }

    /// Wake Drip up immediately with a joyful springy vertical pop.
    pub fn wake(self: *DripState) void {
        if (self.mood == .asleep) {
            self.mood = .waking;
            self.wake_anim = 1.0;
            self.squash_y = 1.45; // joyful springy vertical pop
            self.squash_xz = 0.83;
            self.beat_pulse = 1.0;
            self.beat_accent = 0.85;
        } else if (self.mood != .waking and self.mood != .hanging and self.mood != .entraining and self.mood != .hopping and self.mood != .waiting) {
            self.mood = .awake;
        }
        self.peaceful_beats = 0;
    }

    /// Step physical dynamics, inertia, jump response, and animation timers.
    pub fn stepPhysics(self: *DripState, w: anytype) void {
        const dt: f32 = 1.0 / 60.0;

        // Wake animation & crown beat-halo decay
        if (self.wake_anim > 0.0) {
            self.wake_anim = @max(0.0, self.wake_anim - 3.0 * dt);
            if (self.wake_anim <= 0.0 and self.mood == .waking) {
                self.mood = .awake;
            }
        }
        self.beat_pulse *= 0.82;
        if (self.beat_pulse < 0.01) self.beat_pulse = 0.0;

        // Airborne jumping dynamics
        if (w.airborne) {
            if (w.hum_vy > 2.0) {
                // Launch / upward ascent: stretch tall
                const stretch = @min(1.30, 1.0 + w.hum_vy * 0.015);
                self.squash_y += (stretch - self.squash_y) * 0.25;
            } else if (w.hum_vy < -2.0) {
                // Falling: streamline slightly
                self.squash_y += (0.95 - self.squash_y) * 0.20;
            } else {
                // Apex float: sphere up weightlessly
                self.squash_y += (1.05 - self.squash_y) * 0.15;
            }
        } else if (w.step == w.landed_at) {
            // Landing impact squash
            self.squash_y = 0.68;
            self.squash_xz = 1.25;
        } else {
            // Elastic spring recovery: unmistakable low cozy resting cap (0.48) when asleep vs
            // lively upright droplet (1.08) when awake
            const target_y: f32 = if (self.mood == .asleep) 0.48 else 1.08;
            self.squash_y += (target_y - self.squash_y) * 0.18;
        }
        self.squash_xz = 1.0 / @sqrt(@max(0.1, self.squash_y));

        // Inertial tilt from Hum's velocity and turns
        const speed2 = w.hum_vx * w.hum_vx + w.hum_vz * w.hum_vz;
        if (speed2 > 0.1) {
            const sp = @sqrt(speed2);
            // Tilt backward against motion direction, lean with turns
            const target_tilt_x = -(w.hum_vx / sp) * 0.18 + w.lean_x * 0.3;
            const target_tilt_z = -(w.hum_vz / sp) * 0.18 + w.lean_z * 0.3;
            self.tilt_x += (target_tilt_x - self.tilt_x) * 0.12;
            self.tilt_z += (target_tilt_z - self.tilt_z) * 0.12;
        } else {
            self.tilt_x += (0.0 - self.tilt_x) * 0.15;
            self.tilt_z += (0.0 - self.tilt_z) * 0.15;
        }
    }
};

test "drip enters sleep after 2 bars of peaceful exploration" {
    var state = DripState{};
    state.mood = .awake;
    state.sleep_after_bars = 2;

    const DummyWorld = struct {
        drip_met: bool = true,
        drip_out: u8 = 0,
        singing: bool = false,
        wheel_open: bool = false,
        step: u64 = 1000,
        hold_until: u64 = 0,
        pub fn threatened(_: @This()) bool {
            return false;
        }
    };
    const w = DummyWorld{};

    // Initial awake state: audible
    try std.testing.expect(state.isAudible(w, 20.0));

    // 7 peaceful beats (less than 2 bars = 8 beats): still awake & audible
    for (0..7) |i| {
        state.onBeat(i % 4 == 0, true);
        try std.testing.expectEqual(DripMood.awake, state.mood);
        try std.testing.expect(state.isAudible(w, 20.0));
    }

    // 8th beat completes 2 bars of peaceful exploration: enters sleep & silences metronome
    // even when riding on Hum's head (`far == 0.0`)
    state.onBeat(false, true);
    try std.testing.expectEqual(DripMood.asleep, state.mood);
    try std.testing.expect(!state.isAudible(w, 20.0));
    try std.testing.expect(!state.isAudible(w, 0.0));
}

test "drip wakes immediately on R2 swell or R1 wheel press" {
    var state = DripState{};
    state.mood = .asleep;

    var w = struct {
        drip_met: bool = true,
        drip_out: u8 = 0,
        singing: bool = false,
        wheel_open: bool = false,
        step: u64 = 1000,
        hold_until: u64 = 0,
        pub fn threatened(_: @This()) bool {
            return false;
        }
    }{};

    // Asleep in open world: silent
    try std.testing.expect(!state.isAudible(w, 20.0));

    // Player presses R2 to sing: isAudible becomes true immediately
    w.singing = true;
    try std.testing.expect(state.isAudible(w, 20.0));

    // Calling wake() transitions to waking with springy stretch
    state.wake();
    try std.testing.expectEqual(DripMood.waking, state.mood);
    try std.testing.expect(state.squash_y > 1.2);
    try std.testing.expect(state.wake_anim > 0.0);
    try std.testing.expect(state.isAudible(w, 20.0));
}

test "drip squash-and-stretch responds to airborne jumps and touchdown" {
    var state = DripState{};
    state.mood = .awake;

    var w = struct {
        airborne: bool = true,
        hum_vy: f32 = 12.0, // ascending in jump
        hum_vx: f32 = 0.0,
        hum_vz: f32 = 0.0,
        lean_x: f32 = 0.0,
        lean_z: f32 = 0.0,
        step: u64 = 100,
        landed_at: u64 = 0,
    }{};

    // Ascending in jump: stretches tall
    state.stepPhysics(w);
    try std.testing.expect(state.squash_y > 1.0);
    try std.testing.expect(state.squash_xz < 1.0);

    // Touchdown landing impact
    w.airborne = false;
    w.landed_at = 101;
    w.step = 101;
    state.stepPhysics(w);
    try std.testing.expect(state.squash_y < 0.8);
    try std.testing.expect(state.squash_xz > 1.1);
}
