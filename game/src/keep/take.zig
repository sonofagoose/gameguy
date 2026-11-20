//! A take: what a player's hands did, and nothing else (SPEC.md, rule 10).
//!
//! The world is a function of hands, so a take is enough to make the whole day again: the same
//! world, the same sound, on any machine. It is a list of changes: the step a change happened on
//! and what the hands were from then. Ten bytes a change. Twenty minutes of play is a few hundred
//! kilobytes.
//!
//! No platform here: this turns takes into bytes and back. Files are the caller's business.
const std = @import("std");
const world_mod = @import("../world/world.zig");
const Hands = world_mod.Hands;

pub const magic = [4]u8{ 'G', 'G', 'T', 'K' };
/// Version 2 holds each change's stamp (world.Hands.stamp): twelve bytes a change. Version 1,
/// ten bytes a change with no stamp, is still read.
pub const version: u16 = 2;
pub const header_size = 16;
pub const change_size = 12;
const v1_change_size = 10;

/// Which world the hands were playing in.
pub const Scene = enum(u8) { dark = 0, asters = 1, evening = 2 };

/// The mark in a take's header (its eighth byte): whole, short of changes that did not fit, or
/// still being written. A take written as it is played carries `open` until it is closed; one that
/// still says `open` was cut off, by a flat battery or a crash, and is read as far as it got.
pub const whole_mark: u8 = 0;
pub const lost_mark: u8 = 1;
pub const open_mark: u8 = 2;

/// The header of a take that is about to be written as it is played.
pub fn openHeader(scene: Scene, out: *[header_size]u8) void {
    @memcpy(out[0..4], &magic);
    std.mem.writeInt(u16, out[4..6], version, .little);
    out[6] = @intFromEnum(scene);
    out[7] = open_mark;
    std.mem.writeInt(u32, out[8..12], 0, .little);
    std.mem.writeInt(u32, out[12..16], 0, .little);
}

/// The header of a take once it is closed: how many steps and changes it holds.
pub fn closedHeader(scene: Scene, steps: u32, count: u32, lost: bool, out: *[header_size]u8) void {
    openHeader(scene, out);
    out[7] = if (lost) lost_mark else whole_mark;
    std.mem.writeInt(u32, out[8..12], steps, .little);
    std.mem.writeInt(u32, out[12..16], count, .little);
}

/// One change of the hands, as it is written.
pub fn encode(change: Change, out: *[change_size]u8) void {
    std.mem.writeInt(u32, out[0..4], change.step, .little);
    out[4] = @bitCast(change.hands.lx);
    out[5] = @bitCast(change.hands.ly);
    out[6] = @bitCast(change.hands.rx);
    out[7] = @bitCast(change.hands.ry);
    std.mem.writeInt(u16, out[8..10], change.hands.buttons, .little);
    std.mem.writeInt(u16, out[10..12], change.hands.stamp, .little);
}

pub const Change = struct {
    step: u32,
    hands: Hands,
};

fn same(a: Hands, b: Hands) bool {
    return a.lx == b.lx and a.ly == b.ly and a.rx == b.rx and a.ry == b.ry and a.buttons == b.buttons and a.stamp == b.stamp;
}

/// Writes a take down as it is played.
pub const Recorder = struct {
    changes: []Change,
    count: usize = 0,
    steps: u32 = 0,
    last: Hands = .{},
    /// Changes that did not fit. A take with any is not whole, and says so.
    lost: u32 = 0,

    pub fn note(self: *Recorder, step: u64, hands: Hands) void {
        self.steps = @intCast(step + 1);
        if (self.count > 0 and same(hands, self.last)) return;
        if (self.count == 0 and same(hands, .{})) return;
        if (self.count >= self.changes.len) {
            self.lost += 1;
            return;
        }
        self.changes[self.count] = .{ .step = @intCast(step), .hands = hands };
        self.count += 1;
        self.last = hands;
    }

    /// How many bytes the take is.
    pub fn size(self: *const Recorder) usize {
        return header_size + self.count * change_size;
    }

    /// Put the take into `out`, which must hold `size()` bytes.
    pub fn write(self: *const Recorder, scene: Scene, out: []u8) usize {
        @memcpy(out[0..4], &magic);
        std.mem.writeInt(u16, out[4..6], version, .little);
        out[6] = @intFromEnum(scene);
        out[7] = if (self.lost > 0) 1 else 0;
        std.mem.writeInt(u32, out[8..12], self.steps, .little);
        std.mem.writeInt(u32, out[12..16], @intCast(self.count), .little);
        var at: usize = header_size;
        for (self.changes[0..self.count]) |change| {
            encode(change, out[at..][0..change_size]);
            at += change_size;
        }
        return at;
    }
};

/// Plays a take back: ask it for the hands at each step, in order.
pub const Player = struct {
    bytes: []const u8,
    scene: Scene,
    steps: u32,
    count: u32,
    whole: bool,
    /// It was still being written when it stopped: a flat battery, or a crash.
    cut: bool = false,
    /// Bytes a change: twelve, or ten in a take from before the stamps.
    size: usize = change_size,
    next: u32 = 0,
    now: Hands = .{},

    pub fn open(bytes: []const u8) ?Player {
        if (bytes.len < header_size or !std.mem.eql(u8, bytes[0..4], &magic)) return null;
        const v = std.mem.readInt(u16, bytes[4..6], .little);
        if (v != version and v != 1) return null;
        const size: usize = if (v == 1) v1_change_size else change_size;
        if (bytes[6] > 2) return null;
        if (bytes[7] == open_mark) {
            // cut off while it was being written: every whole change there is, and it ends just
            // after the last one
            const count: u32 = @intCast((bytes.len - header_size) / size);
            var steps: u32 = 0;
            if (count > 0) {
                const at = header_size + @as(usize, count - 1) * size;
                steps = std.mem.readInt(u32, bytes[at..][0..4], .little) + 1;
            }
            return .{ .bytes = bytes, .scene = @enumFromInt(bytes[6]), .steps = steps, .count = count, .whole = false, .cut = true, .size = size };
        }
        const count = std.mem.readInt(u32, bytes[12..16], .little);
        if (bytes.len < header_size + @as(usize, count) * size) return null;
        return .{
            .bytes = bytes,
            .scene = @enumFromInt(bytes[6]),
            .steps = std.mem.readInt(u32, bytes[8..12], .little),
            .count = count,
            .whole = bytes[7] == whole_mark,
            .size = size,
        };
    }

    pub fn hands(self: *Player, step: u64) Hands {
        while (self.next < self.count) {
            const at = header_size + @as(usize, self.next) * self.size;
            if (std.mem.readInt(u32, self.bytes[at..][0..4], .little) > step) break;
            self.now = .{
                .lx = @bitCast(self.bytes[at + 4]),
                .ly = @bitCast(self.bytes[at + 5]),
                .rx = @bitCast(self.bytes[at + 6]),
                .ry = @bitCast(self.bytes[at + 7]),
                .buttons = std.mem.readInt(u16, self.bytes[at + 8 ..][0..2], .little),
                .stamp = if (self.size >= 12) std.mem.readInt(u16, self.bytes[at + 10 ..][0..2], .little) else 0,
            };
            self.next += 1;
        }
        return self.now;
    }

    pub fn done(self: *const Player, step: u64) bool {
        return step >= self.steps;
    }
};

test "a take written down and played back makes the same world, step for step" {
    const Walker = @import("../bot/walker.zig").Walker;
    const allocator = std.testing.allocator;
    const first = try allocator.create(world_mod.World);
    defer allocator.destroy(first);
    const again = try allocator.create(world_mod.World);
    defer allocator.destroy(again);
    const changes = try allocator.alloc(Change, 8000);
    defer allocator.free(changes);
    var cues: [world_mod.max_cues]@import("../sound/sound.zig").Cue = undefined;

    // the walk to the great aster, by a player that decides from what it sees
    first.initAsters();
    var bot = Walker{};
    var recorder = Recorder{ .changes = changes };
    var prints: [40]u64 = undefined;
    var step: u32 = 0;
    while (step < 4000 and !bot.done) : (step += 1) {
        const hands = bot.hands(first);
        recorder.note(step, hands);
        _ = first.stepOnce(hands, &cues);
        if (step % 100 == 99) prints[step / 100] = first.fingerprint();
    }
    try std.testing.expectEqual(@as(u32, 0), recorder.lost);
    // hands that walk in a straight line and call twice change only a handful of times, so the
    // whole walk is a few dozen bytes
    try std.testing.expect(recorder.count > 5 and recorder.count < 200);

    // written down: ten bytes a change
    const bytes = try allocator.alloc(u8, recorder.size());
    defer allocator.free(bytes);
    try std.testing.expectEqual(recorder.size(), recorder.write(.asters, bytes));

    // played back from the bytes alone: the same world at every hundredth step, and the same end
    var player = Player.open(bytes) orelse return error.NotATake;
    try std.testing.expect(player.whole and player.scene == .asters);
    again.initAsters();
    var back: u32 = 0;
    while (!player.done(back)) : (back += 1) {
        _ = again.stepOnce(player.hands(back), &cues);
        if (back % 100 == 99) try std.testing.expectEqual(prints[back / 100], again.fingerprint());
    }
    try std.testing.expectEqual(step, back);
    try std.testing.expectEqual(first.fingerprint(), again.fingerprint());
    // and what the first player met, the played-back one meets on the same step
    try std.testing.expectEqual(first.seen.get(.garden_asters).first, again.seen.get(.garden_asters).first);
    try std.testing.expect(again.seen.get(.garden_asters).met);
}

test "a file that is not a take is refused" {
    try std.testing.expect(Player.open("not a take at all") == null);
    var short: [header_size]u8 = undefined;
    @memcpy(short[0..4], &magic);
    std.mem.writeInt(u16, short[4..6], version, .little);
    short[6] = 0;
    short[7] = 0;
    std.mem.writeInt(u32, short[8..12], 10, .little);
    std.mem.writeInt(u32, short[12..16], 5, .little); // says five changes and holds none
    try std.testing.expect(Player.open(&short) == null);
}

test "a take cut off while it was written is read as far as it got" {
    var bytes: [header_size + 5 * change_size + 4]u8 = undefined;
    openHeader(.evening, bytes[0..header_size]);
    const steps_at = [5]u32{ 3, 60, 61, 120, 180 };
    for (steps_at, 0..) |s, i| {
        encode(.{ .step = s, .hands = .{ .lx = @intCast(i * 10), .buttons = @intCast(i), .stamp = @intCast(i * 150) } }, bytes[header_size + i * change_size ..][0..change_size]);
    }
    // the last four bytes are the start of a change that never finished
    @memset(bytes[header_size + 5 * change_size ..], 0xee);
    var player = Player.open(&bytes).?;
    try std.testing.expect(player.cut and !player.whole);
    try std.testing.expectEqual(@as(u32, 5), player.count);
    try std.testing.expectEqual(@as(u32, 181), player.steps);
    try std.testing.expectEqual(@as(i8, 40), player.hands(500).lx);
    // and each change keeps where in its step R1 or R2 moved, so a replay sounds on that sample
    try std.testing.expectEqual(@as(u16, 600), player.now.stamp);
    // and a closed one says how long it is
    closedHeader(.evening, 400, 5, false, bytes[0..header_size]);
    const closed = Player.open(bytes[0 .. header_size + 5 * change_size]).?;
    try std.testing.expect(closed.whole and !closed.cut);
    try std.testing.expectEqual(@as(u32, 400), closed.steps);
}
