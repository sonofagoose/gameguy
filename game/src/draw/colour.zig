//! A note's colour. Pitch class is hue, by fifths round the wheel: green at the garden's own
//! note, sharps warming and flats cooling, purple straight across (design/look.md; SPEC.md 15).
//! No platform in it, so it can be tested with the rules.
const std = @import("std");

/// The hue, in degrees, of each step round the circle of fifths from the garden's note.
pub const hues = [12]f32{ 120.0, 90.0, 60.0, 30.0, 0.0, 330.0, 285.0, 265.0, 235.0, 205.0, 180.0, 150.0 };

/// How many fifths up from `home_hz` the note is, 0 to 11.
pub fn fifthsFrom(home_hz: f32, hz: f32) usize {
    const steps = 12.0 * @log2(hz / home_hz);
    const pc: i32 = @mod(@as(i32, @intFromFloat(@round(steps))), 12);
    return @intCast(@mod(pc * 7, 12));
}

pub fn ofNote(home_hz: f32, hz: f32) [3]f32 {
    const h = hues[fifthsFrom(home_hz, hz)] / 60.0;
    const x = 1.0 - @abs(@mod(h, 2.0) - 1.0);
    const sector: i32 = @intFromFloat(h);
    const rgb: [3]f32 = switch (sector) {
        0 => .{ 1.0, x, 0.0 },
        1 => .{ x, 1.0, 0.0 },
        2 => .{ 0.0, 1.0, x },
        3 => .{ 0.0, x, 1.0 },
        4 => .{ x, 0.0, 1.0 },
        else => .{ 1.0, 0.0, x },
    };
    // a quarter of the way to white, so no colour is harsh
    return .{ 0.25 + 0.75 * rgb[0], 0.25 + 0.75 * rgb[1], 0.25 + 0.75 * rgb[2] };
}

test "a note's colour goes round the wheel by fifths" {
    const home: f32 = 261.63;
    // twelve pure fifths up, folded into one octave, visit the twelve hues in order
    var hz: f32 = home;
    for (0..12) |k| {
        try std.testing.expectEqual(k, fifthsFrom(home, hz));
        hz *= 1.5;
        if (hz >= home * 2.0) hz *= 0.5;
    }
    // home is green; a fifth up is a step warmer, a fifth down a step cooler; across is purple
    try std.testing.expectEqual(@as(f32, 120.0), hues[fifthsFrom(home, home)]);
    try std.testing.expectEqual(@as(f32, 90.0), hues[fifthsFrom(home, home * 1.5)]);
    try std.testing.expectEqual(@as(f32, 150.0), hues[fifthsFrom(home, home / 1.5)]);
    try std.testing.expectEqual(@as(f32, 285.0), hues[fifthsFrom(home, home * 1.41421)]);
    // an octave is the same colour
    try std.testing.expectEqual(fifthsFrom(home, 392.0), fifthsFrom(home, 784.0));
}
