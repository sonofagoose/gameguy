//! The parts of the game with no platform in them: the rules, the sound, and the arithmetic.
//! Tests and the same-take tool start here, so they can run with no screen and no sound card.
pub const music = @import("music/music.zig");
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
    _ = music;
    _ = world;
    _ = world.asters;
    _ = world.cues_mod;
    _ = world.pools;
    _ = world.knots;
    _ = world.hose;
    _ = world.reeds;
    _ = world.spigot;
    _ = world.form;
    _ = @import("draw/black.zig");
    _ = @import("draw/hum_figure.zig");
    _ = @import("body/solid.zig");
    _ = @import("body/grid.zig");
    _ = @import("place/garden.zig");
    _ = world.covers;
    _ = world.home;
    _ = world.drip;
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
