//! The songbook's pages, as the world knows them (draw/songbook.zig draws them): which things Hum
//! has done, and which one the present moment asks for. No screen here.
const std = @import("std");
const world_mod = @import("world.zig");
const World = world_mod.World;

pub const Page = enum(u8) { call, breathe, walk, jump, sprint, strike, dodge, wheel, swell, clap };
pub const pages = std.enums.values(Page);


/// Whether Hum has done a page's thing yet.
pub fn learned(w: *const World, p: Page) bool {
    return switch (p) {
        .call => w.calls > 0,
        .breathe => w.locked_at != world_mod.never,
        .walk => w.stand >= 1.0 and w.locked_at != world_mod.never,
        .jump => w.jumps > 0,
        .sprint => w.sprints > 0,
        .strike => w.timed_strikes + w.placed_strikes > 0,
        .dodge => w.pockets > 0,
        .wheel => w.wheel_opens > 0,
        .swell => w.cadences > 0,
        .clap => w.claps > 0,
    };
}

/// The page the present moment asks for, if it asks for one Hum has not yet done.
pub fn needed(w: *const World) ?Page {
    if (w.calls == 0) return .call;
    if (w.locked_at == world_mod.never) return .breathe;
    if (w.at_hose and w.jumps == 0) return .jump;
    if (w.threatened()) {
        if (w.wheel_opens == 0) return .wheel;
        if (w.timed_strikes + w.placed_strikes == 0) return .strike;
        if (w.pockets == 0) return .dodge;
        if (w.cadences == 0) return .swell;
    }
    return null;
}

test "the page a moment needs: the call first, then the breath, then the hose's jump" {
    const w = try std.testing.allocator.create(World);
    defer std.testing.allocator.destroy(w);
    w.initEvening();
    try std.testing.expectEqual(Page.call, needed(w).?);
    w.calls = 1;
    try std.testing.expectEqual(Page.breathe, needed(w).?);
    // stood up and called: nothing asked of Hum until the hose is against it
    w.initAsters();
    w.knot_count = 0;
    w.calls = 1;
    try std.testing.expectEqual(@as(?Page, null), needed(w));
    w.at_hose = true;
    try std.testing.expectEqual(Page.jump, needed(w).?);
    w.jumps = 1;
    try std.testing.expect(learned(w, .jump));
}
