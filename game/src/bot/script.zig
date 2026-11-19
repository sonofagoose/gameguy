//! A scripted pair of hands for runs with no person: it walks in arcs, calls every few seconds
//! and sings now and then. It is a sum from the step's number and a seed, so every machine gets
//! the same hands.
const world = @import("../world/world.zig");

pub const Script = struct {
    seed: u32 = 0x1234_abcd,
    turn: f32 = 0.0,
    next_call: u64 = 45,
    sing_until: u64 = 0,
    next_sing: u64 = 400,

    fn rand(self: *Script) u32 {
        self.seed ^= self.seed << 13;
        self.seed ^= self.seed >> 17;
        self.seed ^= self.seed << 5;
        return self.seed;
    }

    pub fn hands(self: *Script, step: u64) world.Hands {
        var h = world.Hands{};
        // walk in a slow wandering arc, with rests
        if (step % 600 < 420) {
            self.turn += (@as(f32, @floatFromInt(self.rand() % 201)) - 100.0) * 0.0004;
            h.lx = @intFromFloat(110.0 * @sin(self.turn));
            h.ly = @intFromFloat(-110.0 * @cos(self.turn));
        }
        if (step == self.next_call) {
            h.buttons |= world.Hands.call;
            self.next_call = step + 120 + self.rand() % 240;
        }
        if (step >= self.next_sing) {
            self.sing_until = step + 90 + self.rand() % 120;
            self.next_sing = self.sing_until + 300 + self.rand() % 600;
        }
        if (step < self.sing_until) h.buttons |= world.Hands.sing;
        return h;
    }
};
