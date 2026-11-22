//! The Circle of Fifths: the wheel of keys, moods, and scale degrees.
//!
//! A true Circle of Fifths containing both outer Major keys and inner Relative Minor keys.
//! When R1 is held, time thickens to 1/4 pace, the background dims, and this wheel appears
//! anchored at Hum's waist as a pristine planar disc floating above the terrain.
//! Deflecting the right stick halfway selects the inner minor key; deflecting fully selects
//! the outer major key.
const std = @import("std");
const lines = @import("lines.zig");
const colour = @import("colour.zig");
const world_mod = @import("../world/world.zig");

const Inst = lines.Inst;
const col8 = colour.col8;

pub const outer_r: f32 = 24.0;
pub const mid_r: f32 = 14.5;
pub const inner_r: f32 = 6.0;

const GlyphSeg = [4]f32; // x0, y0, x1, y1 in normalized glyph space [-0.5, 0.5]

fn getGlyph(ch: u8, segs: *[8]GlyphSeg) usize {
    return switch (ch) {
        'C' => blk: {
            segs[0] = .{ 0.4, 0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, -0.4, -0.5 };
            segs[2] = .{ -0.4, -0.5, 0.4, -0.5 };
            break :blk 3;
        },
        'G' => blk: {
            segs[0] = .{ 0.4, 0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, -0.4, -0.5 };
            segs[2] = .{ -0.4, -0.5, 0.4, -0.5 };
            segs[3] = .{ 0.4, -0.5, 0.4, 0.0 };
            segs[4] = .{ 0.4, 0.0, 0.0, 0.0 };
            break :blk 5;
        },
        'D' => blk: {
            segs[0] = .{ -0.4, -0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, 0.2, 0.5 };
            segs[2] = .{ 0.2, 0.5, 0.4, 0.0 };
            segs[3] = .{ 0.4, 0.0, 0.2, -0.5 };
            segs[4] = .{ 0.2, -0.5, -0.4, -0.5 };
            break :blk 5;
        },
        'A' => blk: {
            segs[0] = .{ -0.4, -0.5, 0.0, 0.5 };
            segs[1] = .{ 0.0, 0.5, 0.4, -0.5 };
            segs[2] = .{ -0.2, -0.1, 0.2, -0.1 };
            break :blk 3;
        },
        'E' => blk: {
            segs[0] = .{ 0.4, 0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, -0.4, -0.5 };
            segs[2] = .{ -0.4, -0.5, 0.4, -0.5 };
            segs[3] = .{ -0.4, 0.0, 0.2, 0.0 };
            break :blk 4;
        },
        'B' => blk: {
            segs[0] = .{ -0.4, -0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, 0.2, 0.5 };
            segs[2] = .{ 0.2, 0.5, 0.2, 0.0 };
            segs[3] = .{ 0.2, 0.0, -0.4, 0.0 };
            segs[4] = .{ -0.4, 0.0, 0.3, 0.0 };
            segs[5] = .{ 0.3, 0.0, 0.3, -0.5 };
            segs[6] = .{ 0.3, -0.5, -0.4, -0.5 };
            break :blk 7;
        },
        'F' => blk: {
            segs[0] = .{ 0.4, 0.5, -0.4, 0.5 };
            segs[1] = .{ -0.4, 0.5, -0.4, -0.5 };
            segs[2] = .{ -0.4, 0.0, 0.2, 0.0 };
            break :blk 3;
        },
        '#' => blk: {
            segs[0] = .{ -0.2, -0.5, -0.2, 0.5 };
            segs[1] = .{ 0.2, -0.5, 0.2, 0.5 };
            segs[2] = .{ -0.4, -0.2, 0.4, -0.1 };
            segs[3] = .{ -0.4, 0.1, 0.4, 0.2 };
            break :blk 4;
        },
        'b' => blk: {
            segs[0] = .{ -0.3, -0.5, -0.3, 0.5 };
            segs[1] = .{ -0.3, 0.0, 0.2, 0.0 };
            segs[2] = .{ 0.2, 0.0, 0.2, -0.5 };
            segs[3] = .{ 0.2, -0.5, -0.3, -0.5 };
            break :blk 4;
        },
        'm' => blk: {
            segs[0] = .{ -0.4, -0.4, -0.4, 0.1 };
            segs[1] = .{ -0.4, 0.1, 0.0, 0.1 };
            segs[2] = .{ 0.0, 0.1, 0.0, -0.4 };
            segs[3] = .{ 0.0, 0.1, 0.4, 0.1 };
            segs[4] = .{ 0.4, 0.1, 0.4, -0.4 };
            break :blk 5;
        },
        else => 0,
    };
}

fn drawLabel(cx: f32, cy: f32, cz: f32, d: [2]f32, dist: f32, text: []const u8, size: f32, col: [4]u8, out: []Inst, n: *usize) void {
    const t = [2]f32{ -d[1], d[0] };
    const total_w = @as(f32, @floatFromInt(text.len)) * size * 0.85;
    var x_offset = -total_w * 0.5 + size * 0.4;
    for (text) |ch| {
        var segs: [8]GlyphSeg = undefined;
        const seg_count = getGlyph(ch, &segs);
        for (segs[0..seg_count]) |s| {
            if (n.* >= out.len) return;
            const p0x = cx + d[0] * dist + t[0] * (x_offset + s[0] * size) + d[0] * (s[1] * size);
            const p0z = cz + d[1] * dist + t[1] * (x_offset + s[0] * size) + d[1] * (s[1] * size);
            const p1x = cx + d[0] * dist + t[0] * (x_offset + s[2] * size) + d[0] * (s[3] * size);
            const p1z = cz + d[1] * dist + t[1] * (x_offset + s[2] * size) + d[1] * (s[3] * size);
            out[n.*] = .{
                .a = .{ p0x, cy, p0z },
                .b = .{ p1x, cy, p1z },
                .half_width = 1.3,
                .body = 0.0,
                .col = col,
            };
            n.* += 1;
        }
        x_offset += size * 0.85;
    }
}

pub fn keyLabels(k: i8) struct { major: []const u8, minor: []const u8 } {
    return switch (k) {
        -6 => .{ .major = "F#", .minor = "D#m" },
        -5 => .{ .major = "Db", .minor = "Bbm" },
        -4 => .{ .major = "Ab", .minor = "Fm" },
        -3 => .{ .major = "Eb", .minor = "Cm" },
        -2 => .{ .major = "Bb", .minor = "Gm" },
        -1 => .{ .major = "F", .minor = "Dm" },
        0 => .{ .major = "C", .minor = "Am" },
        1 => .{ .major = "G", .minor = "Em" },
        2 => .{ .major = "D", .minor = "Bm" },
        3 => .{ .major = "A", .minor = "F#m" },
        4 => .{ .major = "E", .minor = "C#m" },
        5 => .{ .major = "B", .minor = "G#m" },
        else => .{ .major = "C", .minor = "Am" },
    };
}

const Line = struct {
    fn way(fx: f32, fz: f32, rx: f32, rz: f32, a: f32) [2]f32 {
        const ca = @cos(a);
        const sa = @sin(a);
        return .{ fx * ca + rx * sa, fz * ca + rz * sa };
    }
};

/// Draw the Circle of Fifths: dual concentric circles with major and relative minor keys,
/// anchored at Hum's waist height.
pub fn wheelLines(w: *const world_mod.World, out: []Inst) usize {
    if (!w.wheel_open) return 0;
    var n: usize = 0;
    const cx = w.hum_x;
    const cz = w.hum_z;
    const fx = @sin(w.look_yaw);
    const fz = -@cos(w.look_yaw);
    const rx = @cos(w.look_yaw);
    const rz = @sin(w.look_yaw);
    const cool = [3]f32{ 0.18, 0.22, 0.28 };
    const y = w.hum_ground + w.hum_y + 0.25;

    // 12 wedge dividers & arc segments across all 12 fifths
    var k: i8 = -6;
    while (k <= 5) : (k += 1) {
        const awake = w.isAwake(k);
        const pointed = if (w.wheel_point) |p| p == k else false;
        const a = @as(f32, @floatFromInt(k)) * (std.math.pi / 6.0);
        const d = Line.way(fx, fz, rx, rz, a);
        const note_hz = world_mod.wedgeHz(w.day_hz, k);
        const tint = colour.ofNote(world_mod.garden_hz, note_hz);
        const minor_tint = colour.ofNote(world_mod.garden_hz, note_hz * 5.0 / 6.0);
        const sel_inner = pointed and w.wheel_minor;
        const sel_outer = pointed and !w.wheel_minor;

        // Radial dividing rays
        const edge_col = if (awake) col8(tint, if (pointed) 0.85 else 0.4) else col8(cool, 0.2);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d[0] * inner_r, y, cz + d[1] * inner_r }, .b = .{ cx + d[0] * outer_r, y, cz + d[1] * outer_r }, .half_width = if (awake) 1.2 else 0.8, .body = 0.0, .col = edge_col };
            n += 1;
        }

        // Inner/outer dividing circle arc (mid_r)
        const a_next = @as(f32, @floatFromInt(k + 1)) * (std.math.pi / 6.0);
        const d_next = Line.way(fx, fz, rx, rz, a_next);
        const div_col = if (awake) col8(tint, if (pointed) 0.7 else 0.3) else col8(cool, 0.15);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d[0] * mid_r, y, cz + d[1] * mid_r }, .b = .{ cx + d_next[0] * mid_r, y, cz + d_next[1] * mid_r }, .half_width = if (pointed and awake) 2.0 else 1.0, .body = 0.0, .col = div_col };
            n += 1;
        }

        // Concentric perimeter arc (outer_r)
        const outer_col = if (awake) (if (sel_outer) col8(tint, 1.0) else col8(tint, 0.45)) else col8(cool, 0.2);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d[0] * outer_r, y, cz + d[1] * outer_r }, .b = .{ cx + d_next[0] * outer_r, y, cz + d_next[1] * outer_r }, .half_width = if (sel_outer) 2.6 else 1.2, .body = 0.0, .col = outer_col };
            n += 1;
        }

        // Concentric inner perimeter arc (inner_r)
        const inner_col = if (awake) (if (sel_inner) col8(minor_tint, 1.0) else col8(minor_tint, 0.35)) else col8(cool, 0.15);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d[0] * inner_r, y, cz + d[1] * inner_r }, .b = .{ cx + d_next[0] * inner_r, y, cz + d_next[1] * inner_r }, .half_width = if (sel_inner) 2.2 else 1.0, .body = 0.0, .col = inner_col };
            n += 1;
        }

        // Wedge center direction for letter glyphs & cursor ray
        const a_mid = a + (std.math.pi / 12.0);
        const d_mid = Line.way(fx, fz, rx, rz, a_mid);
        const labels = keyLabels(k);

        // Outer Major Key Label
        const maj_col = if (awake) (if (sel_outer) col8([3]f32{ 1.0, 1.0, 1.0 }, 1.0) else col8(tint, 0.8)) else col8(cool, 0.35);
        drawLabel(cx, y, cz, d_mid, (mid_r + outer_r) * 0.5, labels.major, if (sel_outer) 1.5 else 1.2, maj_col, out, &n);

        // Inner Minor Key Label
        const min_col = if (awake) (if (sel_inner) col8([3]f32{ 1.0, 1.0, 1.0 }, 1.0) else col8(minor_tint, 0.65)) else col8(cool, 0.25);
        drawLabel(cx, y, cz, d_mid, (inner_r + mid_r) * 0.5, labels.minor, if (sel_inner) 1.2 else 0.9, min_col, out, &n);

        // Cursor spoke if pointed
        if (pointed and awake) {
            const cursor_r = if (w.wheel_minor) mid_r else outer_r;
            const cursor_col = if (w.wheel_minor) col8(minor_tint, 0.95) else col8(tint, 0.95);
            if (n < out.len) {
                out[n] = .{ .a = .{ cx + d_mid[0] * inner_r, y, cz + d_mid[1] * inner_r }, .b = .{ cx + d_mid[0] * cursor_r, y, cz + d_mid[1] * cursor_r }, .half_width = 2.4, .body = 0.0, .col = cursor_col };
                n += 1;
            }
        }
    }

    // Thread lines from creatures / things to the wheel
    const most_threads = 64;
    var knot_threads: usize = 0;
    for (w.knots[0..w.knot_count]) |kn| {
        if (kn.home) continue;
        const kdx = kn.x - cx;
        const kdz = kn.z - cz;
        if (kdx * kdx + kdz * kdz > 160.0 * 160.0) continue;
        const grey = kn.colour <= 0.0;
        const rk = world_mod.wedgeOfHz(w.day_hz, kn.root_hz) + (if (grey and kn.fate != .turn) w.doorSide() else 0);
        const ra = @as(f32, @floatFromInt(rk)) * (std.math.pi / 6.0);
        const re = Line.way(fx, fz, rx, rz, ra);
        const pointed_at = if (w.wheel_point) |p| p == rk else false;
        const lit: f32 = if (pointed_at) 1.0 else 0.45;
        const width: f32 = if (pointed_at) 2.6 else 1.2;
        for (kn.strands) |st| {
            if (n >= out.len or knot_threads >= most_threads) return n;
            const thread = if (grey) (if (pointed_at) [3]f32{ 1.0, 0.88, 0.45 } else [3]f32{ 0.72, 0.72, 0.78 }) else colour.ofNote(world_mod.garden_hz, st.hz);
            out[n] = .{ .a = .{ kn.x, 1.5, kn.z }, .b = .{ cx + re[0] * (outer_r + 1.0), y, cz + re[1] * (outer_r + 1.0) }, .half_width = width, .body = 0.0, .col = col8(thread, lit) };
            n += 1;
            knot_threads += 1;
        }
    }

    return n;
}
