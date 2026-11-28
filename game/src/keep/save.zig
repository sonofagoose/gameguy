//! A save: the whole world at one step, as it is (SPEC.md 13; spec/size.md, "Nothing is forgotten").
//!
//! The world is plain data with no pointers in it, so its bytes are the whole of it, and a world
//! read back from them steps on exactly as the one that was saved would have. Every dawn's save is
//! kept on the card, so any morning can be opened again and walked from.
//!
//! A save opens only in a build whose world is laid out the same: its header carries a print of
//! the world's layout, and a build that has changed it says so instead of reading garbage. The day's
//! take (take.zig) is the other half: from a dawn's save and that day's hands, the whole day comes
//! back.
//!
//! No platform here: this turns a world into bytes and back. Files are the caller's business.
const std = @import("std");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;

pub const magic = [8]u8{ 'G', 'G', 'S', 'A', 'V', 'E', '0', '1' };
pub const header_size = 40;
pub const size = header_size + @sizeOf(World);

/// A print of how the world is laid out: every field's name, size and place, all the way down.
/// Two builds with the same print read each other's saves.
pub const layout: u64 = blk: {
    @setEvalBranchQuota(2_000_000);
    var h: u64 = 0xcbf29ce484222325;
    h = printType(h, World);
    break :blk h;
};

fn mixByte(h: u64, b: u8) u64 {
    return (h ^ b) *% 0x100000001b3;
}

fn mixWord(h0: u64, v: u64) u64 {
    var h = h0;
    var i: u6 = 0;
    while (true) : (i += 8) {
        h = mixByte(h, @truncate(v >> i));
        if (i == 56) break;
    }
    return h;
}

fn mixText(h0: u64, text: []const u8) u64 {
    var h = h0;
    for (text) |b| h = mixByte(h, b);
    return h;
}

fn printType(h0: u64, comptime T: type) u64 {
    var h = mixText(h0, @typeName(T));
    h = mixWord(h, @sizeOf(T));
    switch (@typeInfo(T)) {
        .@"struct" => |s| {
            inline for (s.field_names, s.field_types) |name, field_type| {
                h = mixText(h, name);
                h = mixWord(h, @offsetOf(T, name));
                h = printType(h, field_type);
            }
        },
        .array => |a| {
            h = mixWord(h, a.len);
            h = printType(h, a.child);
        },
        else => {},
    }
    return h;
}

fn check(bytes: []const u8) u64 {
    var h: u64 = 0xcbf29ce484222325;
    for (bytes) |b| h = mixByte(h, b);
    return h;
}

/// Write the world into `out`, which must hold `size` bytes. The return is how many were written.
pub fn write(world: *const World, out: []u8) usize {
    std.debug.assert(out.len >= size);
    const body = std.mem.asBytes(world);
    @memcpy(out[0..8], &magic);
    std.mem.writeInt(u64, out[8..16], layout, .little);
    std.mem.writeInt(u64, out[16..24], world.step, .little);
    std.mem.writeInt(u64, out[24..32], body.len, .little);
    std.mem.writeInt(u64, out[32..40], check(body), .little);
    @memcpy(out[header_size..][0..body.len], body);
    return size;
}

pub const Refused = error{
    /// Not a save at all.
    NotASave,
    /// A save from a build whose world is laid out differently.
    OtherBuild,
    /// Cut short, or changed since it was written.
    Damaged,
};

/// Read a save back into `world`. Nothing is changed unless the whole of it is good.
pub fn read(bytes: []const u8, world: *World) Refused!void {
    if (bytes.len < header_size or !std.mem.eql(u8, bytes[0..8], &magic)) return error.NotASave;
    if (std.mem.readInt(u64, bytes[8..16], .little) != layout) return error.OtherBuild;
    const len = std.mem.readInt(u64, bytes[24..32], .little);
    if (len != @sizeOf(World) or bytes.len < header_size + len) return error.Damaged;
    const body = bytes[header_size..][0..len];
    if (check(body) != std.mem.readInt(u64, bytes[32..40], .little)) return error.Damaged;
    @memcpy(std.mem.asBytes(world), body);
}

/// The step a save was made at, without reading the rest.
pub fn stepOf(bytes: []const u8) ?u64 {
    if (bytes.len < header_size or !std.mem.eql(u8, bytes[0..8], &magic)) return null;
    return std.mem.readInt(u64, bytes[16..24], .little);
}

const walker = @import("../bot/walker.zig");
const take = @import("take.zig");
const sound = @import("../sound/sound.zig");

test "a save keeps the pool-crossing witness and crossing state" {
   const a = std.testing.allocator;
   const w = try a.create(World);
   defer a.destroy(w);
   const back = try a.create(World);
   defer a.destroy(back);
   const bytes = try a.alloc(u8, size);
   defer a.free(bytes);
   var cues: [world_mod.max_cues]sound.Cue = undefined;

   w.initEvening();
   const r = w.pools[0].r;
   w.hum_x = -(r + 1.0) * 0.7071;
   w.hum_z = -(r + 1.0) * 0.7071;

   var entered = false;
   var step: u64 = 0;
   while (step < 60 * 50 and w.crossed == 0) : (step += 1) {
       _ = w.stepOnce(.{ .lx = 78, .ly = 78, .buttons = world_mod.Hands.sing }, &cues);
       if (!entered and w.on_pool != 0) {
           entered = true;
           _ = write(w, bytes);
       }
   }
   try std.testing.expect(entered);
   try std.testing.expect(!w.seen.get(.garden_w04).met);

   try read(bytes, back);
   try std.testing.expectEqual(w.on_pool, back.on_pool);
   try std.testing.expectApproxEqAbs(w.hum_x, back.hum_x, 0.001);
   try std.testing.expectApproxEqAbs(w.hum_z, back.hum_z, 0.001);

   while (back.crossed == 0 and back.step < step + 60 * 50) {
       _ = back.stepOnce(.{ .lx = 78, .ly = 78, .buttons = world_mod.Hands.sing }, &cues);
   }
   try std.testing.expectEqual(w.crossed, back.crossed);
   try std.testing.expectEqual(w.seen.get(.garden_w04).met, back.seen.get(.garden_w04).met);
}

test "a save made in the middle of the evening and loaded again reaches the same end" {
    const a = std.testing.allocator;
    const w = try a.create(World);
    defer a.destroy(w);
    const back = try a.create(World);
    defer a.destroy(back);
    const bytes = try a.alloc(u8, size);
    defer a.free(bytes);
    const changes = try a.alloc(take.Change, 8192);
    defer a.free(changes);
    var cues: [world_mod.max_cues]sound.Cue = undefined;

    // the scripted player walks the evening as far as the great aster's foot, its hands written down
    w.initEvening();
    var bot = walker.Walker{};
    var rec = take.Recorder{ .changes = changes };
    var step: u64 = 0;
    const middle: u64 = 2400;
    const end: u64 = 4200;
    while (step < end) : (step += 1) {
        const hands = bot.hands(w);
        rec.note(step, hands);
        if (step == middle) _ = write(w, bytes);
        _ = w.stepOnce(hands, &cues);
    }
    const end_print = w.fingerprint();
    try std.testing.expectEqual(middle, stepOf(bytes).?);

    // a fresh world opened from the save, and played on by the same hands from the take
    const take_bytes = try a.alloc(u8, rec.size());
    defer a.free(take_bytes);
    _ = rec.write(.evening, take_bytes);
    var player = take.Player.open(take_bytes).?;
    try read(bytes, back);
    try std.testing.expectEqual(middle, back.step);
    step = middle;
    while (step < end) : (step += 1) _ = back.stepOnce(player.hands(step), &cues);
    try std.testing.expectEqual(end_print, back.fingerprint());
}

test "a dawn's save is kept and opened again a hundred dawns later" {
    const a = std.testing.allocator;
    const w = try a.create(World);
    defer a.destroy(w);
    const back = try a.create(World);
    defer a.destroy(back);
    // a hundred and one dawns, each kept; a short day each, so the test is quick
    const dawns = 101;
    const kept = try a.alloc(u8, size * dawns);
    defer a.free(kept);
    var prints: [dawns]u64 = undefined;
    var cues: [world_mod.max_cues]sound.Cue = undefined;
    w.initAsters();
    for (0..dawns) |d| {
        _ = write(w, kept[d * size ..][0..size]);
        prints[d] = w.fingerprint();
        // a day: walk a little and call once
        var s: u32 = 0;
        while (s < 30) : (s += 1) {
            const hands = world_mod.Hands{ .ly = if (s < 20) -90 else 0, .buttons = if (s == 25) world_mod.Hands.call else 0 };
            _ = w.stepOnce(hands, &cues);
        }
    }
    // the first morning, opened after a hundred more: the same world, and it goes on the same way
    try read(kept[0..size], back);
    try std.testing.expectEqual(prints[0], back.fingerprint());
    var s: u32 = 0;
    while (s < 30) : (s += 1) {
        const hands = world_mod.Hands{ .ly = if (s < 20) -90 else 0, .buttons = if (s == 25) world_mod.Hands.call else 0 };
        _ = back.stepOnce(hands, &cues);
    }
    try std.testing.expectEqual(prints[1], back.fingerprint());
    // a damaged save is refused and changes nothing
    kept[size + header_size + 100] ^= 0xff;
    const before = back.fingerprint();
    try std.testing.expectError(error.Damaged, read(kept[size..][0..size], back));
    try std.testing.expectEqual(before, back.fingerprint());
    // and something that isn't a save is refused as one
    try std.testing.expectError(error.NotASave, read("not a save at all, not at all", back));
}
