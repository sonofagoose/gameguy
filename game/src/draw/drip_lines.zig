//! Procedural line rendering for Drip, ground guidance ripples, and the Lissajous entrainment figure.
//! Extracted from dark.zig for separation of concerns and DRY modularity.
const std = @import("std");
const lines = @import("lines.zig");
const colour = @import("colour.zig");
const Inst = lines.Inst;
const col8 = colour.col8;

pub const teal = [3]f32{ 0.12, 0.72, 0.65 };
pub const bone = [3]f32{ 0.92, 0.90, 0.82 };

/// Draw Drip, its guidance ripples, answer rings, and the breathing figure.
pub fn dripLines(w: anytype, out: []Inst) usize {
    if (w.drip == 0 or w.drip >= w.things.len) return 0;
    var n: usize = 0;
    const drip = w.things[w.drip];
    const drip_body: f32 = @floatFromInt(100 + w.drip); // thing_body offset

    // 1. Drip's directional guidance ripple: on each bar's downbeat a ripple of light runs out along
    // the ground from Hum toward the next landmark in Drip's colour, fading as it goes
    if (w.drip_met and w.lead_step > 0 and w.step >= w.lead_step and w.step - w.lead_step < 60) {
        const f = @as(f32, @floatFromInt(w.step - w.lead_step)) / 60.0;
        const way = std.math.atan2(w.lead_z - w.hum_z, w.lead_x - w.hum_x);
        for (0..3) |wave| {
            const d = 3.0 + 16.0 * f + @as(f32, @floatFromInt(wave)) * 2.5;
            const alpha = (1.0 - f) * (0.75 - 0.2 * @as(f32, @floatFromInt(wave)));
            for (0..6) |k| {
                if (n >= out.len) return n;
                const a0 = way + (@as(f32, @floatFromInt(k)) - 3.0) * 0.07;
                const a1 = a0 + 0.07;
                out[n] = .{
                    .a = .{ w.hum_x + d * @cos(a0), 0.08, w.hum_z + d * @sin(a0) },
                    .b = .{ w.hum_x + d * @cos(a1), 0.08, w.hum_z + d * @sin(a1) },
                    .half_width = 1.8,
                    .body = 0.0,
                    .col = col8(teal, alpha),
                };
                n += 1;
            }
        }
    }

    // 2. Drip riding Hum's head (or hopping/waiting)
    if (w.drip_met) {
        const rx = @cos(w.look_yaw);
        const rz = @sin(w.look_yaw);
        const is_asleep = (w.drip_state.mood == .asleep);

        // Alpha and breathing modulation
        const sleep_breath = if (is_asleep) @sin(@as(f32, @floatFromInt(w.clock)) * 0.05) * 0.04 else 0.0;
        const alpha: f32 = if (is_asleep) 0.58 + sleep_breath else 0.95;
        const tint = col8(teal, alpha);

        // Procedural squash & stretch
        const sy = w.drip_state.squash_y * (1.0 + sleep_breath);
        const sxz = w.drip_state.squash_xz;

        // 16-segment living procedural teardrop
        const parts = 16;
        for (0..parts) |k| {
            if (n >= out.len) return n;
            const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, parts));

            const s0 = @sin(a0);
            const s1 = @sin(a1);

            // Teardrop profile: round bulb below, tapered point above
            const narrow0: f32 = if (s0 > 0.0) 1.0 - 0.72 * s0 * s0 else 1.0;
            const narrow1: f32 = if (s1 > 0.0) 1.0 - 0.72 * s1 * s1 else 1.0;

            const tall0: f32 = if (s0 > 0.0) 1.7 * sy else 1.0 * sy;
            const tall1: f32 = if (s1 > 0.0) 1.7 * sy else 1.0 * sy;

            const r0 = 0.20 * narrow0 * sxz;
            const r1 = 0.20 * narrow1 * sxz;

            // Sleeping nightcap tip curl / dynamic tilt
            const curl_x = if (is_asleep and s0 > 0.6) (s0 - 0.6) * 0.08 else 0.0;
            const curl_z = if (is_asleep and s1 > 0.6) (s1 - 0.6) * 0.08 else 0.0;

            const y0 = drip.y + 0.20 * s0 * tall0;
            const y1 = drip.y + 0.20 * s1 * tall1;

            const p0x = drip.x + (rx * r0 * @cos(a0) + curl_x + w.drip_state.tilt_x * s0 * 0.1);
            const p0z = drip.z + (rz * r0 * @cos(a0) + curl_z + w.drip_state.tilt_z * s0 * 0.1);
            const p1x = drip.x + (rx * r1 * @cos(a1) + curl_x + w.drip_state.tilt_x * s1 * 0.1);
            const p1z = drip.z + (rz * r1 * @cos(a1) + curl_z + w.drip_state.tilt_z * s1 * 0.1);

            out[n] = .{
                .a = .{ p0x, y0, p0z },
                .b = .{ p1x, y1, p1z },
                .half_width = if (is_asleep) 1.2 else 1.5,
                .body = 0.0,
                .col = tint,
            };
            n += 1;
        }

        // Inner liquid glint crescent (glassy droplet sheen when awake)
        if (!is_asleep and n + 3 <= out.len) {
            const glint_tint = col8([3]f32{ 0.7, 0.95, 0.9 }, 0.75);
            for (0..3) |k| {
                const ga0 = (1.8 + @as(f32, @floatFromInt(k)) * 0.3) * (std.math.pi / 4.0);
                const ga1 = (1.8 + @as(f32, @floatFromInt(k + 1)) * 0.3) * (std.math.pi / 4.0);
                const gr0 = 0.10 * sxz;
                const gr1 = 0.10 * sxz;
                const gy0 = drip.y + 0.16 * sy + @sin(ga0) * 0.08;
                const gy1 = drip.y + 0.16 * sy + @sin(ga1) * 0.08;
                out[n] = .{
                    .a = .{ drip.x + rx * gr0 * @cos(ga0), gy0, drip.z + rz * gr0 * @cos(ga0) },
                    .b = .{ drip.x + rx * gr1 * @cos(ga1), gy1, drip.z + rz * gr1 * @cos(ga1) },
                    .half_width = 1.0,
                    .body = 0.0,
                    .col = glint_tint,
                };
                n += 1;
            }
        }
        return n;
    }

    // 3. Out in the dark: a small ring on the ground that is only seen when it ticks or hums
    for (0..8) |k| {
        if (n >= out.len) return n;
        const a0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / 8.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / 8.0);
        out[n] = .{
            .a = .{ drip.x + 0.55 * @cos(a0), 0.05, drip.z + 0.55 * @sin(a0) },
            .b = .{ drip.x + 0.55 * @cos(a1), 0.05, drip.z + 0.55 * @sin(a1) },
            .half_width = 2.2,
            .body = drip_body,
            .col = col8(teal, 1.0),
        };
        n += 1;
    }

    const dx = drip.x - w.hum_x;
    const dz = drip.z - w.hum_z;
    const far = @sqrt(dx * dx + dz * dz);

    // 4. The answer ripple: for two seconds after its answer arrives, arcs on the ground toward it
    if (w.answered and w.step - w.answered_at < 130 and far > 1.0) {
        const age = @as(f32, @floatFromInt(w.step - w.answered_at)) / 130.0;
        const way = std.math.atan2(dz, dx);
        for (0..3) |arc| {
            const r = 3.0 + 2.2 * @as(f32, @floatFromInt(arc)) + age * 2.0;
            const r_tint = col8(teal, (1.0 - age) * (0.9 - 0.2 * @as(f32, @floatFromInt(arc))));
            for (0..6) |k| {
                if (n >= out.len) return n;
                const a0 = way - 0.5 + @as(f32, @floatFromInt(k)) * (1.0 / 6.0);
                const a1 = a0 + 1.0 / 6.0;
                out[n] = .{
                    .a = .{ w.hum_x + r * @cos(a0), 0.05, w.hum_z + r * @sin(a0) },
                    .b = .{ w.hum_x + r * @cos(a1), 0.05, w.hum_z + r * @sin(a1) },
                    .half_width = 1.6,
                    .body = 0.0,
                    .col = r_tint,
                };
                n += 1;
            }
        }
    }

    // 5. The figure between the two voices: three lobes by two, because their notes are as three
    // to two, turning as fast as they beat. It lies on the ground between them.
    // It is their beating, so it is there only while both sound (World.figureLight)
    if (far < 10.0 and w.figureLight() > 0.0) {
        const locked = w.locked_at != 1e18; // never
        const k_true = @as(f32, @floatFromInt(w.breaths)) / 4.0;
        const tint3 = [3]f32{
            teal[0] + (bone[0] - teal[0]) * k_true,
            teal[1] + (bone[1] - teal[1]) * k_true,
            teal[2] + (bone[2] - teal[2]) * k_true,
        };
        const shown: f32 = w.figureLight();
        const fig_tint = col8(tint3, shown);
        const cx = (drip.x + w.hum_x) * 0.5;
        const cz = (drip.z + w.hum_z) * 0.5;
        const r = @min(1.5, far * 0.40);
        const fig_parts = 72;
        const heavy: f32 = if (locked) 2.0 else 1.5;
        for (0..fig_parts) |k| {
            if (n >= out.len) return n;
            const t0 = @as(f32, @floatFromInt(k)) * (2.0 * std.math.pi / @as(f32, fig_parts));
            const t1 = @as(f32, @floatFromInt(k + 1)) * (2.0 * std.math.pi / @as(f32, fig_parts));
            out[n] = .{
                .a = .{ cx + r * @sin(3.0 * t0 + w.figure_turn), 0.06, cz + r * @sin(2.0 * t0) },
                .b = .{ cx + r * @sin(3.0 * t1 + w.figure_turn), 0.06, cz + r * @sin(2.0 * t1) },
                .half_width = heavy,
                .body = 0.0,
                .col = fig_tint,
            };
            n += 1;
        }
    }

    return n;
}
