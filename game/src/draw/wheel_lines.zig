//! The Circle of Fifths: the wheel of 24 keys (12 outer Major + 12 inner Relative Minor).
//!
//! When R1 is held, time thickens to 1/4 pace, the camera lifts, the background dims, and this
//! true 12-o'clock-aligned 24-cell wheel floats above the terrain around Hum.
//! Deflecting the right stick halfway selects the inner Relative Minor ring; full deflection
//! selects the outer Major ring. All 24 cells are readable and selectable: today's 6 sunlit cells
//! glow warmly, the 18 night cells remain softly tinted and legible, the active cell carries a
//! gold rim, and the hovered cell lights bright white.
const std = @import("std");
const lines = @import("lines.zig");
const colour = @import("colour.zig");
const world_mod = @import("../world/world.zig");
const music = @import("../music/music.zig");

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
                .half_width = 1.35,
                .body = 0.0,
                .col = col,
            };
            n.* += 1;
        }
        x_offset += size * 0.85;
    }
}

pub fn keyLabels(k: i8) struct { major: []const u8, minor: []const u8 } {
    const at: u4 = @intCast(@mod(@as(i32, k), 12));
    return .{
        .major = music.wheel.names[0][at],
        .minor = music.wheel.names[1][at],
    };
}

const Line = struct {
    fn way(fx: f32, fz: f32, rx: f32, rz: f32, a: f32) [2]f32 {
        const ca = @cos(a);
        const sa = @sin(a);
        return .{ fx * ca + rx * sa, fz * ca + rz * sa };
    }
};

/// Draw the true 12-o'clock-aligned 24-cell Circle of Fifths anchored at Hum's waist height.
/// Wedge `k` is centered at `k * 30°` (`C`/`Am` straight ahead at 12 o'clock, `G`/`Em` at 1,
/// `F`/`Dm` at 11, `F#`/`D#m` at 6) matching `World.wedgeAt(rx, ry)` exactly.
pub fn wheelLines(w: *const world_mod.World, out: []Inst) usize {
    if (!w.wheel_open) return 0;
    var n: usize = 0;
    const cx = w.hum_x;
    const cz = w.hum_z;
    const fx = @sin(w.look_yaw);
    const fz = -@cos(w.look_yaw);
    const rx = @cos(w.look_yaw);
    const rz = @sin(w.look_yaw);
    const y = w.hum_ground + w.hum_y + 0.25;
    const gold = [3]f32{ 1.0, 0.86, 0.42 };
    const white = [3]f32{ 1.0, 1.0, 1.0 };
    const d_day = world_mod.harmony.day(w);

    var k: i8 = -6;
    while (k <= 5) : (k += 1) {
        const at: u4 = @intCast(@mod(@as(i32, k), 12));
        const outer_cell = music.wheel.Cell{ .ring = .outer, .at = at };
        const inner_cell = music.wheel.Cell{ .ring = .inner, .at = at };
        const sunlit = d_day.face(outer_cell).awake();

        const pointed = if (w.wheel_point) |p| p == k else false;
        const sel_outer = pointed and !w.wheel_minor;
        const sel_inner = pointed and w.wheel_minor;
        const cur_outer = w.home_k == k and !w.home_minor;
        const cur_inner = w.home_k == k and w.home_minor;

        // Symmetrical wedge centered at exact clock hour `a_mid = k * 30°`
        const a_mid = @as(f32, @floatFromInt(k)) * (std.math.pi / 6.0);
        const a0 = a_mid - (std.math.pi / 12.0);
        const a1 = a_mid + (std.math.pi / 12.0);
        const d0 = Line.way(fx, fz, rx, rz, a0);
        const d1 = Line.way(fx, fz, rx, rz, a1);
        const d_mid = Line.way(fx, fz, rx, rz, a_mid);

        const tint = colour.ofCell(outer_cell.root());
        const minor_tint = colour.ofCell(inner_cell.root());

        // Radial dividing ray on counter-clockwise edge `a0`
        const edge_col = if (pointed) col8(white, 0.65) else if (sunlit) col8(tint, 0.52) else col8(tint, 0.22);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d0[0] * inner_r, y, cz + d0[1] * inner_r }, .b = .{ cx + d0[0] * outer_r, y, cz + d0[1] * outer_r }, .half_width = if (sunlit) 1.3 else 0.85, .body = 0.0, .col = edge_col };
            n += 1;
        }

        // Mid dividing circle arc (`mid_r` separating Outer Major and Inner Minor)
        const mid_col = if (sel_inner or sel_outer) col8(white, 0.95) else if (cur_outer or cur_inner) col8(gold, 0.90) else if (sunlit) col8(tint, 0.55) else col8(tint, 0.22);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d0[0] * mid_r, y, cz + d0[1] * mid_r }, .b = .{ cx + d1[0] * mid_r, y, cz + d1[1] * mid_r }, .half_width = if (pointed or cur_outer or cur_inner) 2.2 else if (sunlit) 1.4 else 0.9, .body = 0.0, .col = mid_col };
            n += 1;
        }

        // Outer Major perimeter arc (`outer_r`)
        const outer_col = if (sel_outer) col8(white, 1.0) else if (cur_outer) col8(gold, 1.0) else if (sunlit) col8(tint, 0.72) else col8(tint, 0.30);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d0[0] * outer_r, y, cz + d0[1] * outer_r }, .b = .{ cx + d1[0] * outer_r, y, cz + d1[1] * outer_r }, .half_width = if (sel_outer) 3.0 else if (cur_outer) 2.5 else if (sunlit) 1.5 else 1.0, .body = 0.0, .col = outer_col };
            n += 1;
        }

        // Inner Minor perimeter arc (`inner_r`)
        const inner_col = if (sel_inner) col8(white, 1.0) else if (cur_inner) col8(gold, 1.0) else if (sunlit) col8(minor_tint, 0.65) else col8(minor_tint, 0.26);
        if (n < out.len) {
            out[n] = .{ .a = .{ cx + d0[0] * inner_r, y, cz + d0[1] * inner_r }, .b = .{ cx + d1[0] * inner_r, y, cz + d1[1] * inner_r }, .half_width = if (sel_inner) 2.8 else if (cur_inner) 2.3 else if (sunlit) 1.3 else 0.9, .body = 0.0, .col = inner_col };
            n += 1;
        }

        // Active cell side rails in gold so current chord stands out immediately
        if (cur_outer or cur_inner) {
            const r_lo = if (cur_inner) inner_r else mid_r;
            const r_hi = if (cur_inner) mid_r else outer_r;
            if (n + 2 <= out.len) {
                out[n] = .{ .a = .{ cx + d0[0] * r_lo, y, cz + d0[1] * r_lo }, .b = .{ cx + d0[0] * r_hi, y, cz + d0[1] * r_hi }, .half_width = 2.2, .body = 0.0, .col = col8(gold, 0.95) };
                out[n + 1] = .{ .a = .{ cx + d1[0] * r_lo, y, cz + d1[1] * r_lo }, .b = .{ cx + d1[0] * r_hi, y, cz + d1[1] * r_hi }, .half_width = 2.2, .body = 0.0, .col = col8(gold, 0.95) };
                n += 2;
            }
        }

        // Labels dead-center at exact clock hour `a_mid`
        const labels = keyLabels(k);
        const maj_col = if (sel_outer) col8(white, 1.0) else if (cur_outer) col8(gold, 1.0) else if (sunlit) col8(tint, 0.95) else col8(tint, 0.44);
        drawLabel(cx, y, cz, d_mid, (mid_r + outer_r) * 0.5, labels.major, if (sel_outer) 1.65 else if (sunlit or cur_outer) 1.3 else 1.05, maj_col, out, &n);

        const min_col = if (sel_inner) col8(white, 1.0) else if (cur_inner) col8(gold, 1.0) else if (sunlit) col8(minor_tint, 0.85) else col8(minor_tint, 0.36);
        drawLabel(cx, y, cz, d_mid, (inner_r + mid_r) * 0.5, labels.minor, if (sel_inner) 1.25 else if (sunlit or cur_inner) 0.95 else 0.78, min_col, out, &n);

        // Hovered cell cursor spoke (works for ALL 24 cells!)
        if (pointed) {
            const cursor_r = if (w.wheel_minor) mid_r else outer_r;
            const c_col = if (w.wheel_minor) col8(minor_tint, 0.95) else col8(tint, 0.95);
            if (n < out.len) {
                out[n] = .{ .a = .{ cx + d_mid[0] * inner_r, y, cz + d_mid[1] * inner_r }, .b = .{ cx + d_mid[0] * cursor_r, y, cz + d_mid[1] * cursor_r }, .half_width = 2.6, .body = 0.0, .col = c_col };
                n += 1;
            }
        }
    }

    // Thread lines from creatures to their exact clock hour on the wheel
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
