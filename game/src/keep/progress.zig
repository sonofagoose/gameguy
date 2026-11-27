//! Durable cross-build progress & bench overrides (ROADMAP.md, step 1.38).
//!
//! Unlike raw whole-world snapshots (`keep/save.zig`), which break whenever `World` changes layout,
//! this plain-text `v1` key=value file survives every build: unknown keys are ignored on load and
//! missing keys keep their defaults. Never written during live frames — only on explicit save or at
//! night/exit so storage never stalls the handheld.
//!
//! No platform and no allocation.
const std = @import("std");
const feel = @import("../feel.zig");

pub const version: u32 = 1;

pub const Progress = struct {
    /// Bitmask of the 12 rivers freed round the circle of fifths (bit 0 = Garden C).
    rivers_freed: u16 = 0,
    /// Hum's opened overtones stage (1 = fifths, 2 = third, 3 = octave, 4 = seventh).
    overtones: u8 = 1,
    /// Last woken day key cell (0..11, 0 = C).
    day_key: u8 = 0,
    /// Number of nights slept in running water and kept moments on the island.
    days_slept: u32 = 0,
    kept_moments: u32 = 0,
    /// Workbench display & mode preferences persisted across sessions.
    hud_overlay: bool = false,
    /// Live feel overrides (saved only when non-default).
    bench: feel.Table = feel.defaults,
};

/// Serialize `p` into `out` as readable `key=value` lines. Returns the written slice or null if
/// `out` is too small.
pub fn write(p: Progress, out: []u8) ?[]const u8 {
    var pos: usize = 0;
    const head = std.fmt.bufPrint(out[pos..],
        \\# gameguy durable progress
        \\version={d}
        \\rivers_freed={d}
        \\overtones={d}
        \\day_key={d}
        \\days_slept={d}
        \\kept_moments={d}
        \\hud_overlay={d}
        \\
    , .{
        version,
        p.rivers_freed,
        p.overtones,
        p.day_key,
        p.days_slept,
        p.kept_moments,
        @as(u8, @intFromBool(p.hud_overlay)),
    }) catch return null;
    pos += head.len;
    inline for (@typeInfo(feel.Table).@"struct".field_names) |name| {
        const cur = @field(p.bench, name);
        const def = @field(feel.defaults, name);
        if (cur != def) {
            const line = std.fmt.bufPrint(out[pos..], "bench.{s}={d:.5}\n", .{ name, cur }) catch return null;
            pos += line.len;
        }
    }
    return out[0..pos];
}

/// Parse durable progress text. Unknown or malformed lines are skipped so older and newer builds
/// always open cleanly.
pub fn read(text: []const u8) Progress {
    var p = Progress{};
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const trimmed = std.mem.trim(u8, raw, " \t\r");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;
        const eq = std.mem.indexOfScalar(u8, trimmed, '=') orelse continue;
        const key = std.mem.trim(u8, trimmed[0..eq], " \t");
        const val = std.mem.trim(u8, trimmed[eq + 1 ..], " \t");
        if (std.mem.eql(u8, key, "rivers_freed")) {
            p.rivers_freed = std.fmt.parseInt(u16, val, 10) catch p.rivers_freed;
        } else if (std.mem.eql(u8, key, "overtones")) {
            p.overtones = std.fmt.parseInt(u8, val, 10) catch p.overtones;
        } else if (std.mem.eql(u8, key, "day_key")) {
            const k = std.fmt.parseInt(u8, val, 10) catch p.day_key;
            p.day_key = @min(k, 11);
        } else if (std.mem.eql(u8, key, "days_slept")) {
            p.days_slept = std.fmt.parseInt(u32, val, 10) catch p.days_slept;
        } else if (std.mem.eql(u8, key, "kept_moments")) {
            p.kept_moments = std.fmt.parseInt(u32, val, 10) catch p.kept_moments;
        } else if (std.mem.eql(u8, key, "hud_overlay")) {
            p.hud_overlay = std.mem.eql(u8, val, "1") or std.mem.eql(u8, val, "true");
        } else if (std.mem.startsWith(u8, key, "bench.")) {
            const name = key["bench.".len..];
            inline for (@typeInfo(feel.Table).@"struct".field_names) |fname| {
                if (std.mem.eql(u8, name, fname)) {
                    if (std.fmt.parseFloat(f32, val)) |v| {
                        if (std.math.isFinite(v)) @field(p.bench, fname) = v;
                    } else |_| {}
                }
            }
        }
    }
    return p;
}

test "durable progress round-trips across builds and ignores unknown or malformed keys" {
    var src = Progress{
        .rivers_freed = 0b0000_0000_0101,
        .overtones = 2,
        .day_key = 7,
        .days_slept = 14,
        .kept_moments = 9,
        .hud_overlay = true,
    };
    src.bench.lift_pull = 0.667;
    src.bench.lean_speed = 1.333;
    var buf: [2048]u8 = undefined;
    const text = write(src, &buf).?;
    const got = read(text);
    try std.testing.expectEqual(src.rivers_freed, got.rivers_freed);
    try std.testing.expectEqual(src.overtones, got.overtones);
    try std.testing.expectEqual(src.day_key, got.day_key);
    try std.testing.expectEqual(src.days_slept, got.days_slept);
    try std.testing.expectEqual(src.kept_moments, got.kept_moments);
    try std.testing.expectEqual(src.hud_overlay, got.hud_overlay);
    try std.testing.expectApproxEqAbs(@as(f32, 0.667), got.bench.lift_pull, 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, 1.333), got.bench.lean_speed, 1e-4);
    try std.testing.expectEqual(feel.defaults.run_speed, got.bench.run_speed);

    // forward compatibility: future keys and broken lines do not break loading
    const messy =
        \\# future build
        \\version=99
        \\future_land_99=true
        \\garbage line without equals
        \\day_key=3
        \\bench.run_speed=not_a_number
        \\bench.jump_height=4.25
    ;
    const parsed = read(messy);
    try std.testing.expectEqual(@as(u8, 3), parsed.day_key);
    try std.testing.expectEqual(feel.defaults.run_speed, parsed.bench.run_speed);
    try std.testing.expectApproxEqAbs(@as(f32, 4.25), parsed.bench.jump_height, 1e-4);
}
