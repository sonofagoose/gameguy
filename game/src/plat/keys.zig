//! What an input device has, from the kernel's own list (/proc/bus/input/devices). No SDL in
//! here, so the rules' tests can check it.
const std = @import("std");

/// The key codes a named input device has, from the "B: KEY=" line of its block in
/// /proc/bus/input/devices: words of 64 bits, most significant first.
pub const Keys = struct {
    words: [16]u64 = @splat(0),

    pub fn has(self: Keys, code: u32) bool {
        const w = code / 64;
        if (w >= self.words.len) return false;
        return (self.words[w] >> @intCast(code % 64)) & 1 != 0;
    }
};

pub fn keysOf(text: []const u8, name: []const u8) ?Keys {
    var blocks = std.mem.splitSequence(u8, text, "\n\n");
    while (blocks.next()) |block| {
        var named = false;
        var key_line: ?[]const u8 = null;
        var lines = std.mem.splitScalar(u8, block, '\n');
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "N: Name=\"")) {
                const rest = line["N: Name=\"".len..];
                const end = std.mem.lastIndexOfScalar(u8, rest, '"') orelse rest.len;
                named = std.mem.eql(u8, rest[0..end], name);
            }
            if (std.mem.startsWith(u8, line, "B: KEY=")) key_line = line["B: KEY=".len..];
        }
        if (!named) continue;
        const line = key_line orelse return null;
        var parts: [16][]const u8 = undefined;
        var n: usize = 0;
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        while (it.next()) |part| {
            if (n == parts.len) return null;
            parts[n] = part;
            n += 1;
        }
        var keys = Keys{};
        for (0..n) |i| {
            // the last word printed is bits 0 to 63
            keys.words[n - 1 - i] = std.fmt.parseInt(u64, parts[i], 16) catch return null;
        }
        return keys;
    }
    return null;
}

test "the face buttons are found by the kernel's codes, as the purple has them" {
    // the purple's own block, 2026-11-20
    const text = "I: Bus=0019 Vendor=484b Product=1100 Version=0100\nN: Name=\"GO-Super Gamepad\"\nH: Handlers=js0 event2 dmcfreq\nB: KEY=1f 0 0 f00000000 0 0 0 3db000000000000 0 0 0 0\n\nI: Bus=0019\nN: Name=\"other\"\nB: KEY=1\n";
    const keys = keysOf(text, "GO-Super Gamepad").?;
    // bottom, right, top, left; the shoulders; the pad; select and start
    for ([_]u32{ 0x130, 0x131, 0x133, 0x134, 0x136, 0x137, 0x138, 0x139, 0x220, 0x223, 0x2c0, 0x2c4 }) |code| try std.testing.expect(keys.has(code));
    try std.testing.expect(!keys.has(0x132));
    // SDL's numbering of them from 0x120 up: bottom 0, right 1, top 2, left 3
    var index: u32 = 0;
    var k: u32 = 0x120;
    while (k < 0x134) : (k += 1) {
        if (keys.has(k)) index += 1;
    }
    try std.testing.expectEqual(@as(u32, 3), index);
    try std.testing.expect(keysOf(text, "nobody") == null);
}
