//! The eye as a small solid (docs/engine.md, "The eye"; ROADMAP.md, step 0.7).
//!
//! The eye keeps at least `eye_reach` (0.6 m) clear of every solid so the screen's near plane
//! (0.4 m clip, 0.53 m corners at 55 deg) can never slice into a thing. When a big solid stands
//! between the eye and Hum, the eye moves in along its line first, then up.
//!
//! Pure geometry on `form/shape.zig` and `body/solid.zig`: no world in it and no platform.
//! Only sums every machine agrees on.
const std = @import("std");
const form = @import("../form/shape.zig");
const solid = @import("solid.zig");
const V3 = form.V3;

/// How far the eye keeps clear of every solid's skin, in metres.
pub const eye_reach: f32 = 0.6;
/// How wide the clear line of sight from Hum's middle to the eye is kept against big solids.
pub const sight_reach: f32 = 0.35;
/// Skip solids within this distance of Hum's middle along the ray so standing against a wall does
/// not collapse the eye onto Hum.
pub const hum_skip: f32 = 0.85;
/// The closest the eye pulls in when pinned directly against a solid right behind Hum.
pub const hard_min_dist: f32 = 1.1;
/// The most extra vertical lift solids alone may add over the desired eye height (enough to clear
/// the hose, fallen flower head, crumbs, moss and risen leaves, without climbing tall stalks).
pub const max_solid_lift: f32 = 4.5;

/// Whether a solid is big enough to pull the eye in when it stands along the line of sight.
/// Drip is small and moves beside Hum; clover stalks are thread-thin (0.08 m radius).
pub fn blocksSight(s: *const solid.Solid) bool {
    return switch (s.kind) {
        .drip, .clover => false,
        else => true,
    };
}

/// Signed distance from point `p` to a solid's surface (`<= 0` inside, `> 0` outside).
pub fn distPoint(s: *const solid.Solid, p: V3) f32 {
    switch (s.shape) {
        .stalk => |st| {
            const d = form.sub(st.b, st.a);
            const l2 = form.dot(d, d);
            const t = if (l2 > 1e-9) std.math.clamp(form.dot(form.sub(p, st.a), d) / l2, 0.0, 1.0) else 0.0;
            const at = form.between(st.a, st.b, t);
            const r = st.ra + (st.rb - st.ra) * t;
            return form.length(form.sub(p, at)) - r;
        },
        .ball => |b| return form.length(form.sub(p, b.at)) - b.r,
        .plate => |pl| {
            if (pl.n < 3) return 1.0e9;
            if (solid.onPlate(pl, p[0], p[2])) |y| {
                if (p[1] > y) return p[1] - y;
                const bot = y - pl.thick;
                if (p[1] < bot) return bot - p[1];
                return -@min(y - p[1], p[1] - bot);
            }
            const q = solid.nearestOnOutline(pl, p[0], p[2]);
            const ox = p[0] - q[0];
            const oz = p[2] - q[2];
            const bot = q[1] - pl.thick;
            const oy = if (p[1] > q[1]) p[1] - q[1] else if (p[1] < bot) bot - p[1] else 0.0;
            return @sqrt(ox * ox + oy * oy + oz * oz);
        },
    }
}

/// Earliest parameter `t` in `[start_t, 1.0]` where the segment `from -> to` comes within `pad`
/// of `s`, or null when the whole stretch is clear.
pub fn hitSegment(s: *const solid.Solid, from: V3, to: V3, pad: f32, start_t: f32) ?f32 {
    if (start_t >= 1.0) return null;
    const a = form.between(from, to, start_t);
    const b = to;
    const span = 1.0 - start_t;
    var lo: f32 = 0.0;
    var hi: f32 = 0.0;
    switch (s.shape) {
        .stalk => |st| {
            const pair = solid.nearest(a, b, st.a, st.b);
            const on_seg = form.between(a, b, pair.s);
            const on_st = form.between(st.a, st.b, pair.t);
            const r = st.ra + (st.rb - st.ra) * pair.t;
            if (form.length(form.sub(on_seg, on_st)) >= r + pad) return null;
            hi = pair.s;
        },
        .ball => |bl| {
            const d = form.sub(b, a);
            const l2 = form.dot(d, d);
            const s_near = if (l2 > 1e-9) std.math.clamp(form.dot(form.sub(bl.at, a), d) / l2, 0.0, 1.0) else 0.0;
            if (form.length(form.sub(form.between(a, b, s_near), bl.at)) >= bl.r + pad) return null;
            hi = s_near;
        },
        .plate => |pl| {
            if (pl.n < 3) return null;
            const bnd = solid.bounds(s);
            if (@max(a[0], b[0]) + pad < bnd.min_x or @min(a[0], b[0]) - pad > bnd.max_x) return null;
            if (@max(a[2], b[2]) + pad < bnd.min_z or @min(a[2], b[2]) - pad > bnd.max_z) return null;
            var hit_s: ?f32 = null;
            var prev_s: f32 = 0.0;
            const steps: usize = 8;
            for (0..steps + 1) |i| {
                const u = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
                if (distPoint(s, form.between(a, b, u)) < pad) {
                    hit_s = u;
                    break;
                }
                prev_s = u;
            }
            // also check where the ray crosses the plate's mid-plane, in case a thin plate lies between samples
            const dy = b[1] - a[1];
            if (@abs(dy) > 1e-5) {
                const mid_y = pl.middle()[1] - pl.thick * 0.5;
                const u_plane = (mid_y - a[1]) / dy;
                if (u_plane > 0.0 and u_plane < 1.0) {
                    if (distPoint(s, form.between(a, b, u_plane)) < pad) {
                        if (hit_s == null or u_plane < hit_s.?) {
                            hit_s = u_plane;
                            prev_s = @max(0.0, u_plane - 1.0 / @as(f32, @floatFromInt(steps)));
                        }
                    }
                }
            }
            hi = hit_s orelse return null;
            lo = prev_s;
        },
    }
    if (distPoint(s, a) < pad) return start_t;
    for (0..8) |_| {
        const mid = (lo + hi) * 0.5;
        if (distPoint(s, form.between(a, b, mid)) < pad) hi = mid else lo = mid;
    }
    return start_t + span * hi;
}

pub const Clear = struct {
    pull: f32 = 1.0,
    lift: f32 = 0.0,
    blocked: bool = false,
};

/// Move the eye clear of `solids`: in along `target -> desired` first, then up if the eye ball
/// still sits within `eye_reach` of anything solid.
pub fn clearEye(solids: []const *const solid.Solid, target: V3, desired: V3, min_pull: f32) Clear {
    const seg = form.sub(desired, target);
    const len = form.length(seg);
    if (len < 0.05 or solids.len == 0) return .{};
    const hard_min = @min(min_pull, hard_min_dist / len);
    const start_t = @min(hum_skip / len, min_pull);
    var pull: f32 = 1.0;
    var blocked = false;

    // 1. In along the line of sight first, stopping `eye_reach` before any blocking solid.
    const extra = (eye_reach - sight_reach) / len;
    for (solids) |s| {
        if (!blocksSight(s)) continue;
        if (hitSegment(s, target, desired, sight_reach, start_t)) |t_hit| {
            const safe = @max(min_pull, t_hit - extra);
            if (safe < pull) {
                pull = safe;
                blocked = true;
            }
        }
    }

    // 2. Make sure the eye ball itself is never nearer than `eye_reach` to any solid (except Drip):
    // nudge inward further (down to `hard_min`) first if needed.
    for (0..4) |_| {
        const p_eye = form.between(target, desired, pull);
        var worst: f32 = eye_reach;
        for (solids) |s| {
            if (s.kind == .drip) continue;
            const d = distPoint(s, p_eye);
            if (d < worst) worst = d;
        }
        if (worst >= eye_reach - 1e-3) break;
        blocked = true;
        if (pull <= hard_min) break;
        const nudge = (eye_reach - worst + 0.05) / len;
        pull = @max(hard_min, pull - nudge);
    }

    // 3. Then up: if the eye ball is still inside or within `eye_reach` of a low solid (hose,
    // crumb, moss, fallen head, risen leaf), lift over its top.
    const p_base = form.between(target, desired, pull);
    var lift: f32 = 0.0;
    for (0..4) |_| {
        const q = V3{ p_base[0], p_base[1] + lift, p_base[2] };
        var need: f32 = 0.0;
        for (solids) |s| {
            if (s.kind == .drip) continue;
            const d = distPoint(s, q);
            if (d >= eye_reach - 1e-3) continue;
            blocked = true;
            if (solid.top(s, q[0], q[2])) |top_y| {
                const over = (top_y + eye_reach) - q[1];
                if (over > 0.0 and over <= max_solid_lift - lift) {
                    need = @max(need, over);
                    continue;
                }
            }
            // beside a curved shoulder or plate edge: step up gently within the cap
            const step_up = @min(eye_reach - d + 0.08, max_solid_lift - lift);
            if (step_up > 0.0) need = @max(need, step_up);
        }
        if (need <= 1e-3) break;
        lift = @min(max_solid_lift, lift + need);
    }

    return .{ .pull = pull, .lift = lift, .blocked = blocked };
}

const expect = std.testing.expect;
const approx = std.testing.expectApproxEqAbs;

test "open air leaves the eye untouched" {
    const empty = [_]*const solid.Solid{};
    const r = clearEye(&empty, .{ 0.0, 0.5, 0.0 }, .{ 0.0, 2.5, 11.0 }, 0.25);
    try approx(@as(f32, 1.0), r.pull, 1e-5);
    try approx(@as(f32, 0.0), r.lift, 1e-5);
    try expect(!r.blocked);
}

test "an aster stalk between Hum and the eye pulls the eye cleanly in front of it" {
    const stalk = solid.Solid{
        .shape = .{ .stalk = .{ .a = .{ 0.0, 0.0, 6.0 }, .b = .{ 0.0, 120.0, 6.0 }, .ra = 0.6, .rb = 0.2 } },
        .kind = .tower,
    };
    const list = [_]*const solid.Solid{&stalk};
    const target = V3{ 0.0, 0.5, 0.0 };
    const desired = V3{ 0.0, 2.2, 11.0 };
    const r = clearEye(&list, target, desired, 0.25);
    try expect(r.blocked);
    try expect(r.pull < 0.5);
    try approx(@as(f32, 0.0), r.lift, 1e-5);
    const p = form.between(target, desired, r.pull);
    try expect(p[2] < 6.0 - 0.6);
    try expect(distPoint(&stalk, p) >= eye_reach - 0.05);
}

test "the hose right under the eye lifts the eye clear over its top" {
    // horizontal tube along x at z = 11.0, radius 0.9, centre y = 0.9 (top at 1.8)
    const hose = solid.Solid{
        .shape = .{ .stalk = .{ .a = .{ -10.0, 0.9, 11.0 }, .b = .{ 10.0, 0.9, 11.0 }, .ra = 0.9, .rb = 0.9 } },
        .kind = .hose,
    };
    const list = [_]*const solid.Solid{&hose};
    const target = V3{ 0.0, 0.5, 0.0 };
    const desired = V3{ 0.0, 2.0, 11.0 };
    const r = clearEye(&list, target, desired, 0.25);
    try expect(r.blocked);
    const p = form.between(target, desired, r.pull);
    const final_eye = V3{ p[0], p[1] + r.lift, p[2] };
    try expect(distPoint(&hose, final_eye) >= eye_reach - 0.05);
}

test "a risen leaf plate between Hum and the eye pulls the eye clear of the plate" {
    var sink_room: [1]form.Shape = undefined;
    var sink = form.Sink{ .out = &sink_room };
    sink.plate(&.{ .{ -3.0, 2.4, 3.0 }, .{ 3.0, 2.4, 3.0 }, .{ 3.0, 2.4, 9.0 }, .{ -3.0, 2.4, 9.0 } }, 0.15);
    const leaf = solid.Solid{ .shape = sink.out[0], .kind = .leaf };
    const list = [_]*const solid.Solid{&leaf};
    const target = V3{ 0.0, 0.5, 0.0 };
    const desired = V3{ 0.0, 4.0, 11.0 };
    const r = clearEye(&list, target, desired, 0.25);
    try expect(r.blocked);
    const p = form.between(target, desired, r.pull);
    const final_eye = V3{ p[0], p[1] + r.lift, p[2] };
    try expect(distPoint(&leaf, final_eye) >= eye_reach - 0.05);
}

test "thread-thin clover stalks do not yank the sight line, but the eye still clears them if inside" {
    const clover = solid.Solid{
        .shape = .{ .stalk = .{ .a = .{ 0.0, 0.0, 5.0 }, .b = .{ 0.0, 5.0, 5.0 }, .ra = 0.08, .rb = 0.08 } },
        .kind = .clover,
    };
    const list = [_]*const solid.Solid{&clover};
    // midway along the ray: ignored by sight pull
    const mid = clearEye(&list, .{ 0.0, 0.5, 0.0 }, .{ 0.0, 2.2, 11.0 }, 0.25);
    try approx(@as(f32, 1.0), mid.pull, 1e-5);
    try expect(!mid.blocked);
    // right on the eye itself: pushed clear by at least eye_reach
    const at_eye = clearEye(&list, .{ 0.0, 0.5, 0.0 }, .{ 0.0, 2.2, 5.0 }, 0.25);
    try expect(at_eye.blocked);
    const p = form.between(.{ 0.0, 0.5, 0.0 }, .{ 0.0, 2.2, 5.0 }, at_eye.pull);
    try expect(distPoint(&clover, .{ p[0], p[1] + at_eye.lift, p[2] }) >= eye_reach - 0.05);
}
