//! The parts of the game with no platform in them: the rules, the sound, and the arithmetic.
//! Tests and the same-take tool start here, so they can run with no screen and no sound card.
pub const world = @import("world/world.zig");
pub const sound = @import("sound/sound.zig");
pub const m = @import("m.zig");
pub const script = @import("bot/script.zig");

test {
    _ = world;
    _ = sound;
    _ = m;
}
