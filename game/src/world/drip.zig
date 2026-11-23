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

    /// Whether Drip's metronome tick should sound audibly.
    /// Single source of truth for auditory balance.
    pub fn isAudible(self: *const DripState, w: anytype, far: f32) bool {
        // While at the faucet or in the dark before meeting, always audible
        if (!w.drip_met) return true;
        // While demonstrating the jump over the coil or waiting beyond it, always audible
        if (w.drip_out != 0) return true;
        // While actively singing, wheel is open, threatened/combat, or entraining
        if (w.singing or w.wheel_open or w.threatened() or w.step < w.hold_until) return true;
        // While waking up or near the faucet
        if (self.wake_anim > 0.0) return true;
        if (far <= 4.0) return true;
        // In open exploration: silent when asleep
        return self.mood != .asleep;
    }

    /// Called on each metronome beat.
    pub fn onBeat(self: *DripState, is_one: bool, peaceful: bool) void {
        if (peaceful) {
            self.peaceful_beats += 1;
            if (self.peaceful_beats >= self.sleep_after_bars * 4) {
                self.mood = .asleep;
            }
        } else {
            self.wake();
        }

        if (self.mood == .awake) {
            // Beat recoil: crisp squash on tick, higher bounce on the one
            self.squash_y = if (is_one) 0.82 else 0.93;
            self.squash_xz = 1.0 / @sqrt(self.squash_y);
        } else if (self.mood == .asleep) {
            // Gentle sleep breathing on the one
            if (is_one) {
                self.squash_y = 0.95;
                self.squash_xz = 1.02;
            }
        }
    }

    /// Wake Drip up immediately with a springy stretch.
    pub fn wake(self: *DripState) void {
        if (self.mood == .asleep) {
            self.mood = .waking;
            self.wake_anim = 1.0;
            self.squash_y = 1.35; // springy vertical stretch
            self.squash_xz = 0.86;
        } else if (self.mood != .waking and self.mood != .hanging and self.mood != .entraining and self.mood != .hopping and self.mood != .waiting) {
            self.mood = .awake;
        }
        self.peaceful_beats = 0;
    }

    /// Step physical dynamics, inertia, jump response, and animation timers.
    pub fn stepPhysics(self: *DripState, w: anytype) void {
        const dt: f32 = 1.0 / 60.0;

        // Wake animation decay
        if (self.wake_anim > 0.0) {
            self.wake_anim = @max(0.0, self.wake_anim - 3.0 * dt);
            if (self.wake_anim <= 0.0 and self.mood == .waking) {
                self.mood = .awake;
            }
        }

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
            // Elastic spring recovery towards target rest scale
            const target_y: f32 = if (self.mood == .asleep) 0.75 else 1.0;
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
    state.onBeat(false, true);
    try std.testing.expectEqual(DripMood.asleep, state.mood);
    try std.testing.expect(!state.isAudible(w, 20.0));
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
