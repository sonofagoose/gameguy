//! The parts of the game with no platform in them: the rules, the sound, and the arithmetic.
//! Tests and the same-take tool start here, so they can run with no screen and no sound card.
pub const world = @import("world/world.zig");
pub const sound = @import("sound/sound.zig");
pub const m = @import("m.zig");
pub const script = @import("bot/script.zig");
pub const walker = @import("bot/walker.zig");
pub const newcomer = @import("bot/newcomer.zig");
pub const pages = @import("world/pages.zig");
pub const colour = @import("draw/colour.zig");
pub const take = @import("keep/take.zig");
pub const save = @import("keep/save.zig");

test {
    _ = world;
    _ = world.asters;
    _ = world.cues_mod;
    _ = world.pools;
    _ = world.knots;
    _ = world.hose;
    _ = @import("plat/keys.zig");
    _ = sound;
    _ = m;
    _ = walker;
    _ = newcomer;
    _ = pages;
    _ = colour;
    _ = take;
    _ = save;
}
