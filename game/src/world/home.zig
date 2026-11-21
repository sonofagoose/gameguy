//! What a thing is to home (design/the-wheel.md; the wheel toy's music.zig, made the world's law):
//! how many fifths round the wheel its note stands from home, the two whole numbers of that
//! interval, and how often its pulse meets Hum's. A creature's body is drawn from the pair, how
//! near it keeps from how far round it is, and its pulse meets Hum's by the same count, so all
//! three change the moment home moves. No platform.

const std = @import("std");
const world = @import("world.zig");

/// Fifths from home to a note, from -6 to 5.
pub fn fifthsApart(w: *const world.World, hz: f32) i8 {
    var k: i32 = @as(i32, world.wedgeOfHz(w.day_hz, hz)) - w.home_k;
    while (k > 5) k -= 12;
    while (k < -6) k += 12;
    return @intCast(k);
}

/// The two whole numbers of the interval (a fifth is 3 against 2): kin a hoop, a neighbour a
/// pretzel, a third a rosette.
pub fn pair(fifths: i8) [2]u8 {
    return switch (fifths) {
        0 => .{ 1, 1 },
        1 => .{ 3, 2 },
        -1 => .{ 4, 3 },
        2 => .{ 9, 8 },
        -2 => .{ 16, 9 },
        3 => .{ 5, 3 },
        -3 => .{ 6, 5 },
        4 => .{ 5, 4 },
        -4 => .{ 8, 5 },
        5 => .{ 15, 8 },
        -5 => .{ 16, 15 },
        else => .{ 45, 32 },
    };
}

/// How many of Hum's beats pass between the moments its pulse meets Hum's: kin every beat, a
/// neighbour every second, a third once a bar.
pub fn meetBeats(fifths: i8) u8 {
    return switch (@abs(fifths)) {
        0 => 1,
        1 => 2,
        3, 4 => 4,
        2, 5 => 8,
        else => 16,
    };
}

/// How near it keeps: what leans in comes close, what is straight across keeps away.
pub fn keepsOff(fifths: i8) f32 {
    return 5.0 + 2.5 * @as(f32, @floatFromInt(@abs(fifths)));
}

test "kin is a hoop that meets every beat and keeps close; straight across keeps away" {
    try std.testing.expectEqual([2]u8{ 1, 1 }, pair(0));
    try std.testing.expectEqual([2]u8{ 3, 2 }, pair(1));
    try std.testing.expectEqual(@as(u8, 1), meetBeats(0));
    try std.testing.expectEqual(@as(u8, 2), meetBeats(-1));
    try std.testing.expect(keepsOff(0) < keepsOff(3));
    try std.testing.expect(keepsOff(3) < keepsOff(-6));
}
