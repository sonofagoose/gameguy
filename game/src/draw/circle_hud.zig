//! Shared 2D Circle-of-Fifths renderer for both:
//!   1. The smart-fade Mini Circle Compass during live play (blooms gently for ~3 s on chord/ring/
//!      voicing changes, or stays calm and visible when the Corner HUD is on);
//!   2. The Pause Workbench `STATUS` tab diagram.
//!
//! Draws the true 24-cell concentric Circle of Fifths (12 outer Major + 12 inner Relative Minor,
//! `C`/`Am` centered at 12 o'clock) with today's 6 sunlit cells bracketed in warm amber and the
//! active cell glowing in its exact pitch colour.
const std = @import("std");
const songbook = @import("songbook.zig");
const room = @import("../room.zig");
const colour = @import("colour.zig");
const world_mod = @import("../world/world.zig");
const World = world_mod.World;
const music = @import("../music/music.zig");

const bone = colour.bone;
const amber = [3]f32{ 1.0, 0.80, 0.36 };
const white = [3]f32{ 1.0, 1.0, 1.0 };
const bg_disc = [3]f32{ 0.04, 0.05, 0.07 };

fn putCentered(words: *room.Type, cx: f32, cy: f32, scale: f32, col: [4]f32, text: []const u8) void {
    if (text.len == 0) return;
    if (words.used + text.len * 48 > words.verts.len) words.flush();
    // Exact `room.Type` glyph metrics (`font.cw = 11`, `step = 14 * scale`, `font.ch = 21`)
    const step = 14.0 * scale;
    const w = if (text.len > 0) @as(f32, @floatFromInt(text.len - 1)) * step + 11.0 * scale else 0.0;
    const h = 21.0 * scale;
    words.line(cx - w * 0.5, cy - h * 0.5, scale, col, text);
}

fn drawArcBand(sk: *songbook.Sketch, cx: f32, cy: f32, r_in: f32, r_out: f32, a0: f32, a1: f32, rgb: [3]f32, alpha: f32) void {
    const subs: usize = 2;
    const da = (a1 - a0) / @as(f32, @floatFromInt(subs));
    for (0..subs) |s| {
        const t0 = a0 + da * @as(f32, @floatFromInt(s));
        const t1 = t0 + da;
        const dx0 = @sin(t0);
        const dy0 = -@cos(t0);
        const dx1 = @sin(t1);
        const dy1 = -@cos(t1);
        sk.quad(
            cx + dx0 * r_in,
            cy + dy0 * r_in,
            cx + dx0 * r_out,
            cy + dy0 * r_out,
            cx + dx1 * r_out,
            cy + dy1 * r_out,
            cx + dx1 * r_in,
            cy + dy1 * r_in,
            rgb,
            alpha,
        );
    }
}

fn drawArcLine(sk: *songbook.Sketch, cx: f32, cy: f32, r: f32, a0: f32, a1: f32, wide: f32, rgb: [3]f32, alpha: f32) void {
    const subs: usize = 2;
    const da = (a1 - a0) / @as(f32, @floatFromInt(subs));
    for (0..subs) |s| {
        const t0 = a0 + da * @as(f32, @floatFromInt(s));
        const t1 = t0 + da;
        sk.seg(
            cx + @sin(t0) * r,
            cy - @cos(t0) * r,
            cx + @sin(t1) * r,
            cy - @cos(t1) * r,
            wide,
            rgb,
            alpha,
        );
    }
}

/// Draw the true 24-cell concentric Circle of Fifths centered at `(cx, cy)` with outer radius `r_out`.
/// Does not flush `sk` or `words` (caller flushes after composing surrounding UI).
pub fn drawCircle(sk: *songbook.Sketch, words: *room.Type, w: *const World, cx: f32, cy: f32, r_out: f32, alpha: f32, detailed: bool) void {
    if (alpha <= 0.01) return;
    const d_day = world_mod.harmony.day(w);
    const cur = w.homeCell();

    const r_bg = r_out + 4.0;
    const r_mid = r_out * 0.58;
    const r_in = r_out * 0.19;

    // Translucent dark circular backdrop
    for (0..12) |i| {
        const a0 = (@as(f32, @floatFromInt(i)) - 0.5) * (std.math.pi / 6.0);
        const a1 = a0 + (std.math.pi / 6.0);
        drawArcBand(sk, cx, cy, 0.0, r_bg, a0, a1, bg_disc, 0.74 * alpha);
    }

    // 12 clock-hour sectors x 2 concentric rings (Outer Major, Inner Relative Minor)
    for (0..12) |i| {
        const at: u4 = @intCast(i);
        const outer_cell = music.wheel.Cell{ .ring = .outer, .at = at };
        const inner_cell = music.wheel.Cell{ .ring = .inner, .at = at };
        const sunlit = d_day.face(outer_cell).awake();
        const cur_outer = cur.ring == .outer and cur.at == at;
        const cur_inner = cur.ring == .inner and cur.at == at;

        const a_mid = @as(f32, @floatFromInt(i)) * (std.math.pi / 6.0);
        const a0 = a_mid - (std.math.pi / 12.0);
        const a1 = a_mid + (std.math.pi / 12.0);

        const col_out = colour.ofCell(outer_cell.root());
        const col_in = colour.ofCell(inner_cell.root());

        // Filled annular wedges
        const out_a: f32 = if (cur_outer) 0.88 else if (sunlit) 0.28 else 0.10;
        const in_a: f32 = if (cur_inner) 0.88 else if (sunlit) 0.24 else 0.08;
        drawArcBand(sk, cx, cy, r_mid + 0.8, r_out - 0.6, a0, a1, col_out, out_a * alpha);
        drawArcBand(sk, cx, cy, r_in + 0.8, r_mid - 0.8, a0, a1, col_in, in_a * alpha);

        // Subtle spokes and concentric ring borders
        const dx0 = @sin(a0);
        const dy0 = -@cos(a0);
        sk.seg(cx + dx0 * r_in, cy + dy0 * r_in, cx + dx0 * r_out, cy + dy0 * r_out, 1.0, bone, (if (sunlit) @as(f32, 0.26) else @as(f32, 0.12)) * alpha);
        drawArcLine(sk, cx, cy, r_out, a0, a1, if (sunlit) 1.6 else 1.0, if (sunlit) amber else bone, (if (sunlit) @as(f32, 0.72) else @as(f32, 0.20)) * alpha);
        drawArcLine(sk, cx, cy, r_mid, a0, a1, 1.0, bone, (if (sunlit) @as(f32, 0.40) else @as(f32, 0.16)) * alpha);
        drawArcLine(sk, cx, cy, r_in, a0, a1, 1.0, if (sunlit) amber else bone, (if (sunlit) @as(f32, 0.55) else @as(f32, 0.18)) * alpha);
    }

    // Warm golden side-walls framing today's 6-cell sunlit slice (10:30 and 1:30 on Day C)
    const land_i: i32 = @intCast(d_day.land());
    const wall_angles = [2]f32{
        (@as(f32, @floatFromInt(land_i)) - 1.5) * (std.math.pi / 6.0),
        (@as(f32, @floatFromInt(land_i)) + 1.5) * (std.math.pi / 6.0),
    };
    for (wall_angles) |wa| {
        sk.seg(cx + @sin(wa) * r_in, cy - @cos(wa) * r_in, cx + @sin(wa) * r_out, cy - @cos(wa) * r_out, 1.6, amber, 0.75 * alpha);
    }

    // Crisp white highlight outline around the active cell wedge
    {
        const a_mid = @as(f32, @floatFromInt(cur.at)) * (std.math.pi / 6.0);
        const a0 = a_mid - (std.math.pi / 12.0);
        const a1 = a_mid + (std.math.pi / 12.0);
        const r_lo = if (cur.ring == .inner) r_in else r_mid;
        const r_hi = if (cur.ring == .inner) r_mid else r_out;
        drawArcLine(sk, cx, cy, r_lo, a0, a1, 1.8, white, 0.96 * alpha);
        drawArcLine(sk, cx, cy, r_hi, a0, a1, 2.0, white, 0.96 * alpha);
        sk.seg(cx + @sin(a0) * r_lo, cy - @cos(a0) * r_lo, cx + @sin(a0) * r_hi, cy - @cos(a0) * r_hi, 1.8, white, 0.96 * alpha);
        sk.seg(cx + @sin(a1) * r_lo, cy - @cos(a1) * r_lo, cx + @sin(a1) * r_hi, cy - @cos(a1) * r_hi, 1.8, white, 0.96 * alpha);
    }

    // Labels: all 12 outer letters + sunlit & active inner letters so 640x480 stays super crisp
    const out_scale: f32 = if (detailed) 0.58 else 0.50;
    const in_scale: f32 = if (detailed) 0.46 else 0.42;
    const r_out_lbl = (r_mid + r_out) * 0.51;
    const r_in_lbl = (r_in + r_mid) * 0.52;
    for (0..12) |i| {
        const at: u4 = @intCast(i);
        const outer_cell = music.wheel.Cell{ .ring = .outer, .at = at };
        const inner_cell = music.wheel.Cell{ .ring = .inner, .at = at };
        const sunlit = d_day.face(outer_cell).awake();
        const cur_outer = cur.ring == .outer and cur.at == at;
        const cur_inner = cur.ring == .inner and cur.at == at;

        const a_mid = @as(f32, @floatFromInt(i)) * (std.math.pi / 6.0);
        const dx = @sin(a_mid);
        const dy = -@cos(a_mid);

        // Outer Major label
        const o_col: [4]f32 = if (cur_outer)
            .{ 0.04, 0.04, 0.06, alpha }
        else if (sunlit)
            .{ bone[0], bone[1], bone[2], 0.96 * alpha }
        else
            .{ bone[0], bone[1], bone[2], 0.52 * alpha };
        putCentered(words, cx + dx * r_out_lbl, cy + dy * r_out_lbl, out_scale, o_col, outer_cell.name());

        // Inner Minor label: always draw sunlit 3 (Am/Em/Dm) + active inner cell (clean & uncrowded!)
        if (sunlit or cur_inner) {
            const i_col: [4]f32 = if (cur_inner)
                .{ 0.04, 0.04, 0.06, alpha }
            else
                .{ bone[0], bone[1], bone[2], 0.84 * alpha };
            putCentered(words, cx + dx * r_in_lbl, cy + dy * r_in_lbl, in_scale, i_col, inner_cell.name());
        }
    }

    // Subtle 4/4 tempo heartbeat pulse inside the center hub (calm teal 70 BPM -> warm amber 120 BPM)
    {
        const bp = w.barPhase();
        const beat_frac = @mod(bp * 4.0, 1.0);
        const is_one = bp < 0.25;
        const pulse = std.math.pow(f32, 1.0 - beat_frac, 3.0);
        const e_vis = std.math.clamp((w.live_bpm - 70.0) / 50.0, 0.0, 1.0);
        const p_rgb = [3]f32{
            0.14 + (amber[0] - 0.14) * e_vis,
            0.76 + (amber[1] - 0.76) * e_vis,
            0.68 + (amber[2] - 0.68) * e_vis,
        };
        const r_dot = r_in * (0.28 + (if (is_one) @as(f32, 0.56) else 0.36) * pulse);
        const p_alpha = (0.30 + (if (is_one) @as(f32, 0.65) else 0.42) * pulse) * alpha;
        for (0..8) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (std.math.pi / 4.0);
            const a1 = a0 + (std.math.pi / 4.0);
            drawArcLine(sk, cx, cy, r_dot, a0, a1, if (is_one) 1.8 else 1.2, p_rgb, p_alpha);
        }
    }
}

/// Smart-fade Mini Circle Compass in the top-right corner during live play.
/// Blooms for 3 seconds (180 steps) after any chord step, ring flip, voicing change, or R1 leap,
/// or stays calmly visible whenever Corner Telemetry HUD is turned on.
pub fn drawLiveCompass(sk: *songbook.Sketch, words: *room.Type, w: *const World, always_on: bool) void {
    const t = world_mod.tryout;
    const since: f32 = if (t.changed_at == world_mod.never) 1.0e9 else @floatFromInt(w.step - t.changed_at);
    const bloom: f32 = if (since < 180.0)
        std.math.clamp(@min((since + 6.0) / 10.0, (180.0 - since) / 45.0), 0.0, 1.0)
    else
        0.0;
    const alpha: f32 = if (always_on) @max(bloom, 0.78) else bloom;
    if (alpha <= 0.02) return;

    const r_out: f32 = 52.0;
    const cx: f32 = sk.w - r_out - 20.0;
    const cy: f32 = (if (always_on) @as(f32, 34.0) else @as(f32, 16.0)) + r_out;

    drawCircle(sk, words, w, cx, cy, r_out, alpha, false);

    // Compact label pill directly below the Mini Circle Compass (includes live BPM), clamped inside right edge
    const cur = w.homeCell();
    const d_day = world_mod.harmony.day(w);
    const vmode = world_mod.harmony.VoicingMode.fromU8(w.voicing);
    var buf: [48]u8 = undefined;
    const pill = std.fmt.bufPrint(&buf, "{s} {s} [{s}] {d:.0}", .{
        world_mod.harmony.cellShort(cur),
        world_mod.harmony.cellFace(d_day, cur),
        vmode.label(),
        w.live_bpm,
    }) catch "";
    const p_scale: f32 = 0.52;
    const text_w: f32 = if (pill.len > 0) @as(f32, @floatFromInt(pill.len - 1)) * (14.0 * p_scale) + 11.0 * p_scale else 0.0;
    const pill_w: f32 = @max(114.0, text_w + 16.0);
    const pill_x: f32 = @min(cx - pill_w * 0.5, sk.w - pill_w - 8.0);
    const py: f32 = cy + r_out + 8.0;
    sk.rect(pill_x, py, pill_w, 18.0, bg_disc, 0.82 * alpha);
    const c_rgb = colour.ofCell(cur.root());
    sk.seg(pill_x, py, pill_x + pill_w, py, 1.6, c_rgb, 0.88 * alpha);
    putCentered(words, pill_x + pill_w * 0.5, py + 9.0, p_scale, .{ bone[0], bone[1], bone[2], 0.96 * alpha }, pill);

    sk.flush();
    words.flush();
}
