//! The shoulders, read straight from the kernel on the sound's own thread (spec/promises/workshop.md,
//! hands.voice-in-a-buffer). The sound thread looks at them before every buffer it renders, so
//! Hum's call, hum and clap start on the buffer after the press: under one buffer, 2.67 ms, after
//! the kernel saw it. L1 and L2 come this way too, so all four are stamped on one clock and the
//! clap (L1 and R1 together) is found where the presses are. Everything else in the hands is read
//! by the main thread as before.
const std = @import("std");
const plat = @import("plat.zig");
const c = plat.c;
const keys = @import("keys.zig");

pub const What = enum(u8) { call_down, call_up, sing_down, sing_up, voice_down, voice_up, guard_down, guard_up, clap };
pub const Edge = struct { what: What, at_s: f64 };

const ev_key: u16 = 1;
const btn_tr: u16 = 0x137; // R1
const btn_tr2: u16 = 0x139; // R2
const btn_tl: u16 = 0x136; // L1
const btn_tl2: u16 = 0x138; // L2
/// _IOW('E', 0xa0, int): which clock the kernel stamps this device's events with.
const eviocsclockid: c_ulong = 0x400445a0;
const clock_monotonic: c_int = 1;

pub const Shoulders = struct {
    fd: c_int = -1,
    event: u32 = 0,

    /// Find the pad's own device by its name and open it to be read without waiting.
    pub fn open(name: []const u8) Shoulders {
        var s = Shoulders{};
        var buf: [32768]u8 = undefined;
        const file = c.fopen("/proc/bus/input/devices", "r") orelse return s;
        const got = c.fread(&buf, 1, buf.len, file);
        _ = c.fclose(file);
        const n = keys.eventOf(buf[0..got], name) orelse return s;
        var path: [64]u8 = undefined;
        const p = std.fmt.bufPrintSentinel(&path, "/dev/input/event{d}", .{n}, 0) catch return s;
        const fd = c.open(p.ptr, c.O_RDONLY | c.O_NONBLOCK);
        if (fd < 0) return s;
        // stamped on the same clock as plat.now()
        var clk: c_int = clock_monotonic;
        _ = c.ioctl(fd, eviocsclockid, &clk);
        s.fd = fd;
        s.event = n;
        return s;
    }

    pub fn close(self: *Shoulders) void {
        if (self.fd >= 0) _ = c.close(self.fd);
        self.fd = -1;
    }

    /// Whatever the shoulders have done since the last look, in order, each with when the kernel saw
    /// it.
    pub fn poll(self: *const Shoulders, out: []Edge) usize {
        if (self.fd < 0) return 0;
        var n: usize = 0;
        // struct input_event on a 64-bit kernel: seconds and microseconds (8 bytes each), type,
        // code (2 each), value (4)
        var raw: [24 * 16]u8 = undefined;
        while (n < out.len) {
            const got = c.read(self.fd, &raw, raw.len);
            if (got <= 0) break;
            const count: usize = @as(usize, @intCast(got)) / 24;
            for (0..count) |i| {
                const e = raw[i * 24 ..][0..24];
                const kind = std.mem.readInt(u16, e[16..18], .little);
                const code = std.mem.readInt(u16, e[18..20], .little);
                const value = std.mem.readInt(i32, e[20..24], .little);
                if (kind != ev_key or value == 2) continue;
                const what: What = switch (code) {
                    btn_tr => if (value == 1) .call_down else .call_up,
                    btn_tr2 => if (value == 1) .sing_down else .sing_up,
                    btn_tl => if (value == 1) .voice_down else .voice_up,
                    btn_tl2 => if (value == 1) .guard_down else .guard_up,
                    else => continue,
                };
                const sec = std.mem.readInt(i64, e[0..8], .little);
                const usec = std.mem.readInt(i64, e[8..16], .little);
                if (n < out.len) {
                    out[n] = .{ .what = what, .at_s = @as(f64, @floatFromInt(sec)) + @as(f64, @floatFromInt(usec)) * 1e-6 };
                    n += 1;
                }
            }
        }
        return n;
    }
};
