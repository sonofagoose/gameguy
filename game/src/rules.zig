//! The parts of the game with no platform in them: the rules, the sound, and the arithmetic.
//! Tests and the same-take tool start here, so they can run with no screen and no sound card.
pub const world = @import("world/world.zig");
pub const sound = @import("sound/sound.zig");
pub const m = @import("m.zig");
pub const script = @import("bot/script.zig");
pub const walker = @import("bot/walker.zig");
pub const colour = @import("draw/colour.zig");
pub const take = @import("keep/take.zig");

test {
    _ = world;
    _ = world.asters;
    _ = world.cues_mod;
    _ = sound;
    _ = m;
    _ = walker;
    _ = colour;
    _ = take;
}
