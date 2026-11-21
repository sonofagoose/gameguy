//! The card: a person's take written as it is played, and found again after a flat battery
//! (spec/promises/workshop.md, `card.takes`).
//!
//! The hands go into a ring as they change, and once a second even when they don't, so the take
//! always reaches to within a second of now. A thread of its own drains the ring to the file twenty
//! times a second and makes the card hold it once a second, so a slow write never touches a frame
//! and killing the game at any moment loses about a second. The take's header says "open" until it
//! is closed on leaving; a take that still says "open" was cut off, and the next start goes on
//! from it.
const std = @import("std");
const plat = @import("plat.zig");
const c = plat.c;
const log = plat.log;
const take = @import("../keep/take.zig");
const save = @import("../keep/save.zig");
const world_mod = @import("../world/world.zig");
const Hands = world_mod.Hands;

const ring_len = 4096;
/// The hands are written down at least this often, in steps, even when they don't change.
const tick_steps = 60;

pub const Card = struct {
    file: ?*c.FILE = null,
    scene: take.Scene = .evening,
    number: u32 = 0,
    ring: [ring_len][take.change_size]u8 = undefined,
    head: u32 = 0,
    tail: u32 = 0,
    last: Hands = .{},
    last_step: u64 = 0,
    noted: u32 = 0,
    lost: u32 = 0,
    stopping: bool = false,
    thread: ?std.Thread = null,
    /// A dawn's save waiting to be written. The same thread writes it, after every change of the
    /// hands that came before it, so a save is never on the card ahead of the take that leads to
    /// it: going on from a save and playing the take through from its start always agree.
    save_buf: [save.size]u8 = undefined,
    save_len: usize = 0,
    save_path: [96]u8 = undefined,
    save_pending: bool = false,

    /// Begin a new take for a scene: keep/takes/SCENE-NUMBER.take, the first number not used.
    pub fn begin(self: *Card, scene: take.Scene) bool {
        _ = c.mkdir("keep", 0o755);
        _ = c.mkdir("keep/takes", 0o755);
        var path: [96]u8 = undefined;
        var number: u32 = 1;
        while (number < 100_000) : (number += 1) {
            const p = takePath(&path, scene, number) orelse return false;
            if (c.access(p.ptr, 0) != 0) break;
        }
        const p = takePath(&path, scene, number) orelse return false;
        const file = c.fopen(p.ptr, "wb") orelse return false;
        var header: [take.header_size]u8 = undefined;
        take.openHeader(scene, &header);
        _ = c.fwrite(&header, 1, header.len, file);
        _ = c.fflush(file);
        self.start(file, scene, number, 0);
        log("the take: written as it is played, into {s}", .{p});
        return true;
    }

    /// A take written into its own folder under a name, apart from the player's (a room's walk).
    pub fn beginIn(self: *Card, scene: take.Scene, dir: []const u8, name: []const u8) bool {
        _ = c.mkdir("results", 0o755);
        var dir_z: [128]u8 = undefined;
        const d = std.mem.printSentinel(&dir_z, "{s}", .{dir}, 0) catch return false;
        _ = c.mkdir(d.ptr, 0o755);
        var path: [256]u8 = undefined;
        var number: u32 = 1;
        var p: [:0]u8 = undefined;
        while (number < 100_000) : (number += 1) {
            p = std.mem.printSentinel(&path, "{s}/{s}-{d:0>3}.take", .{ dir, name, number }, 0) catch return false;
            if (c.access(p.ptr, 0) != 0) break;
        }
        const file = c.fopen(p.ptr, "wb") orelse return false;
        var header: [take.header_size]u8 = undefined;
        take.openHeader(scene, &header);
        _ = c.fwrite(&header, 1, header.len, file);
        _ = c.fflush(file);
        self.start(file, scene, number, 0);
        log("the take: written as it is played, into {s}", .{p});
        return true;
    }

    /// Go on writing a take that was cut off, after its last whole change.
    pub fn reopen(self: *Card, scene: take.Scene, number: u32, count: u32, last: Hands, last_step: u64) bool {
        var path: [96]u8 = undefined;
        const p = takePath(&path, scene, number) orelse return false;
        const file = c.fopen(p.ptr, "r+b") orelse return false;
        // anything past the last whole change is a change cut in half: it goes
        _ = c.fseek(file, @intCast(take.header_size + @as(usize, count) * take.change_size), c.SEEK_SET);
        _ = c.ftruncate(c.fileno(file), @intCast(take.header_size + @as(usize, count) * take.change_size));
        self.start(file, scene, number, count);
        self.last = last;
        self.last_step = last_step;
        return true;
    }

    fn start(self: *Card, file: *c.FILE, scene: take.Scene, number: u32, count: u32) void {
        self.file = file;
        self.scene = scene;
        self.number = number;
        self.noted = count;
        self.head = 0;
        self.tail = 0;
        self.stopping = false;
        self.thread = std.Thread.spawn(.{}, writer, .{self}) catch null;
        if (self.thread == null) log("the take: no thread to write it with; it is written as it is played on this one", .{});
    }

    /// The hands at a step: written down if they changed, and once a second if they didn't.
    pub fn note(self: *Card, step: u64, hands: Hands) void {
        if (self.file == null) return;
        const changed = hands.lx != self.last.lx or hands.ly != self.last.ly or hands.rx != self.last.rx or hands.ry != self.last.ry or hands.buttons != self.last.buttons;
        if (!changed and step < self.last_step + tick_steps and self.noted > 0) return;
        const head = @atomicLoad(u32, &self.head, .monotonic);
        const tail = @atomicLoad(u32, &self.tail, .acquire);
        if (head -% tail >= ring_len) {
            self.lost += 1;
            return;
        }
        take.encode(.{ .step = @intCast(step), .hands = hands }, &self.ring[head % ring_len]);
        @atomicStore(u32, &self.head, head +% 1, .release);
        self.last = hands;
        self.last_step = step;
        self.noted += 1;
        if (self.thread == null) self.drain();
    }

    /// Everything noted so far, to the file.
    fn drain(self: *Card) void {
        const file = self.file orelse return;
        var tail = @atomicLoad(u32, &self.tail, .monotonic);
        const head = @atomicLoad(u32, &self.head, .acquire);
        while (tail != head) : (tail +%= 1) {
            _ = c.fwrite(&self.ring[tail % ring_len], 1, take.change_size, file);
        }
        @atomicStore(u32, &self.tail, tail, .release);
        _ = c.fflush(file);
    }

    /// Keep a dawn's save, written after the take has reached it.
    pub fn keepSave(self: *Card, bytes: []const u8, path: [:0]const u8) void {
        if (@atomicLoad(bool, &self.save_pending, .acquire)) {
            log("the dawn: the last dawn's save is still being written, so this one is not kept", .{});
            return;
        }
        @memcpy(self.save_buf[0..bytes.len], bytes);
        self.save_len = bytes.len;
        @memset(&self.save_path, 0);
        @memcpy(self.save_path[0..path.len], path);
        @atomicStore(bool, &self.save_pending, true, .release);
        if (self.thread == null or self.file == null) self.writeSave();
    }

    /// The take first, then the save: under another name until it is whole, then renamed, so a
    /// save cut off half-written is never taken for one.
    fn writeSave(self: *Card) void {
        if (!@atomicLoad(bool, &self.save_pending, .acquire)) return;
        self.drain();
        if (self.file) |file| _ = c.fsync(c.fileno(file));
        const path: [*:0]const u8 = @ptrCast(&self.save_path);
        var tmp: [104]u8 = undefined;
        const tmp_path = std.fmt.bufPrintSentinel(&tmp, "{s}.part", .{std.mem.span(path)}, 0) catch return;
        if (c.fopen(tmp_path.ptr, "wb")) |out| {
            const wrote = c.fwrite(&self.save_buf, 1, self.save_len, out);
            _ = c.fflush(out);
            _ = c.fsync(c.fileno(out));
            _ = c.fclose(out);
            if (wrote == self.save_len) _ = c.rename(tmp_path.ptr, path);
        }
        @atomicStore(bool, &self.save_pending, false, .release);
    }

    fn writer(self: *Card) void {
        var beats: u32 = 0;
        while (true) {
            const stopping = @atomicLoad(bool, &self.stopping, .acquire);
            self.drain();
            self.writeSave();
            beats += 1;
            if (beats % 20 == 0 or stopping) {
                if (self.file) |file| _ = c.fsync(c.fileno(file));
            }
            if (stopping) return;
            _ = c.usleep(50_000);
        }
    }

    /// Close the take: its header says how long it is, and it no longer says "open".
    pub fn finish(self: *Card, steps: u64) void {
        const file = self.file orelse return;
        @atomicStore(bool, &self.stopping, true, .release);
        if (self.thread) |thread| thread.join() else self.drain();
        self.thread = null;
        var header: [take.header_size]u8 = undefined;
        take.closedHeader(self.scene, @intCast(steps), self.noted, self.lost > 0, &header);
        _ = c.fseek(file, 0, c.SEEK_SET);
        _ = c.fwrite(&header, 1, header.len, file);
        _ = c.fflush(file);
        _ = c.fsync(c.fileno(file));
        _ = c.fclose(file);
        self.file = null;
        log("the take: closed, {d} changes of the hands over {d} steps{s}", .{ self.noted, steps, if (self.lost > 0) " (NOT WHOLE: the card fell behind)" else "" });
    }
};

fn takePath(buf: []u8, scene: take.Scene, number: u32) ?[:0]u8 {
    return std.fmt.bufPrintSentinel(buf, "keep/takes/{s}-{d:0>5}.take", .{ @tagName(scene), number }, 0) catch null;
}

/// Where the save of a take's dawn is kept: keep/dawns/SCENE-NUMBER-DAWN.save.
pub fn dawnPath(buf: []u8, scene: take.Scene, number: u32, dawn: u32) ?[:0]u8 {
    return std.fmt.bufPrintSentinel(buf, "keep/dawns/{s}-{d:0>5}-{d:0>3}.save", .{ @tagName(scene), number, dawn }, 0) catch null;
}

/// The newest take of a scene, if it was cut off: its number, read into `buf`.
pub fn lastCut(scene: take.Scene, buf: []u8) ?struct { number: u32, bytes: []u8 } {
    var path: [96]u8 = undefined;
    var newest: u32 = 0;
    var number: u32 = 1;
    while (number < 100_000) : (number += 1) {
        const p = takePath(&path, scene, number) orelse return null;
        if (c.access(p.ptr, 0) != 0) break;
        newest = number;
    }
    if (newest == 0) return null;
    const p = takePath(&path, scene, newest) orelse return null;
    const file = c.fopen(p.ptr, "rb") orelse return null;
    const n = c.fread(buf.ptr, 1, buf.len, file);
    _ = c.fclose(file);
    if (n < take.header_size or buf[7] != take.open_mark) return null;
    if (n == buf.len) {
        // more than there is room to read: going on from part of it would cut the rest off
        log("the take {s} was cut off, but it is too long to go on from here; it is left as it is", .{p});
        return null;
    }
    return .{ .number = newest, .bytes = buf[0..n] };
}

/// The newest dawn kept for a take, if any: how many dawns it has.
pub fn dawnsOf(scene: take.Scene, number: u32) u32 {
    var path: [96]u8 = undefined;
    var dawn: u32 = 0;
    while (dawn < 1000) : (dawn += 1) {
        const p = dawnPath(&path, scene, number, dawn + 1) orelse return dawn;
        if (c.access(p.ptr, 0) != 0) return dawn;
    }
    return dawn;
}
