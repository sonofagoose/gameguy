//! The jack, by the playback path the system sets (docs/hardware-target.md, "The jack"). The
//! kernel's own headphone switch reads backwards on these handhelds, "in" with the jack empty, but
//! the system turns the codec's 'Playback Path' to HP within a second of a plug going in and back
//! to SPK when it comes out (measured on the purple, 2026-11-20, three plugs in and out). That path
//! is read here straight from the sound card's control device, with no library: with headphones
//! the sound has its full range; on the speaker, and whenever the path can't be read, the sound is
//! shaped for the speaker (sound.zig, "The speaker is the floor").
const std = @import("std");
const plat = @import("plat.zig");
const c = plat.c;

pub const Path = enum { unknown, off, speaker, headphones, both };

/// struct snd_ctl_elem_value on a 64-bit kernel: the element's id (64 bytes), a word, then the
/// value's union (1,024 bytes, from byte 72) and 128 bytes kept back.
const value_size = 1224;
const value_at = 72;
/// _IOWR('U', 0x12, struct snd_ctl_elem_value)
const ctl_elem_read: c_ulong = 0xC4C85512;
const iface_mixer: i32 = 2;

pub const Jack = struct {
    fd: c_int = -1,

    pub fn open() Jack {
        return .{ .fd = c.open("/dev/snd/controlC0", c.O_RDONLY | c.O_NONBLOCK) };
    }

    pub fn close(self: *Jack) void {
        if (self.fd >= 0) _ = c.close(self.fd);
        self.fd = -1;
    }

    /// Where the codec is sending the sound now, found by the control's name.
    pub fn path(self: *const Jack) Path {
        if (self.fd < 0) return .unknown;
        var v: [value_size]u8 align(8) = @splat(0);
        std.mem.writeInt(i32, v[4..8], iface_mixer, .little);
        const name = "Playback Path";
        @memcpy(v[16 .. 16 + name.len], name);
        if (c.ioctl(self.fd, ctl_elem_read, &v) < 0) return .unknown;
        // the rk817 codec's items, in its own order
        return switch (std.mem.readInt(u32, v[value_at..][0..4], .little)) {
            0 => .off,
            1 => .speaker,
            2 => .headphones,
            3 => .both,
            else => .unknown,
        };
    }
};
