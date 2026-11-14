//! What the world looks like: lines of light on black. Every creature's body is the figure of
//! its own note against home, so moving home on the wheel changes every shape on the screen.
const std = @import("std");
const gfx = @import("gfx.zig");
const music = @import("music.zig");
const world_mod = @import("world.zig");
const World = world_mod.World;
const Creature = world_mod.Creature;
const Renderer = gfx.Renderer;

const pi = std.math.pi;
const bone3 = [3]f32{ 0.886, 0.839, 0.784 };
const grey3 = [3]f32{ 0.60, 0.60, 0.62 };
const leaf3 = [3]f32{ 0.52, 0.74, 0.50 };
const water3 = [3]f32{ 0.30, 0.62, 0.96 };

/// Where the camera is. Hum sits in the lower part of the picture.
pub const View = struct {
    cx: f32 = 0.0,
    cy: f32 = 0.0,
    zoom: f32 = 1.0,
    ready: bool = false,
    /// The turning of the figure between Hum and Drip.
    turn: f32 = 0.0,
    clock: f32 = 0.0,

    fn sx(self: *const View, x: f32) f32 {
        return 320.0 + (x - self.cx) * self.zoom;
    }

    fn sy(self: *const View, y: f32) f32 {
        return 292.0 + (y - self.cy) * self.zoom;
    }
};

/// 1 at the start of a pulse, falling away fast.
fn kick(phase: f32) f32 {
    const k = 1.0 - std.math.clamp(phase, 0.0, 1.0);
    return k * k * k;
}

/// The closed figure two pulses in the ratio a:b draw against each other.
fn figure(r: *Renderer, x: f32, y: f32, size: f32, a: u8, b: u8, phase: f32, thick: f32, color: gfx.Color) void {
    const steps: usize = @min(200, 22 * @as(usize, @max(a, b)));
    const fa: f32 = @floatFromInt(a);
    const fb: f32 = @floatFromInt(b);
    var px = x + @sin(phase) * size;
    var py = y;
    for (1..steps + 1) |i| {
        const t = 2.0 * pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
        const qx = x + @sin(fa * t + phase) * size;
        const qy = y + @sin(fb * t) * size;
        r.line(px, py, qx, qy, thick, color);
        px = qx;
        py = qy;
    }
}

pub fn draw(r: *Renderer, w: *const World, v: *View, dt: f32) void {
    v.clock += dt;
    // The camera follows Hum; beside Drip it leans in between the two of them.
    var tx = w.x;
    var ty = w.y;
    const lean = w.lean_in;
    tx += (world_mod.drip_x - w.x) * 0.5 * lean;
    ty += (world_mod.drip_y - w.y) * 0.5 * lean;
    const want_zoom = 1.0 + 0.5 * lean;
    if (!v.ready) {
        v.cx = tx;
        v.cy = ty;
        v.ready = true;
    }
    const ease = @min(1.0, dt * 4.0);
    v.cx += (tx - v.cx) * ease;
    v.cy += (ty - v.cy) * ease;
    v.zoom += (want_zoom - v.zoom) * ease;
    const z = v.zoom;

    r.begin();
    const beat: f32 = @floatCast(@mod(w.beat, 64.0));
    const in_beat = beat - @floor(beat);
    const in_bar: f32 = @floatCast(@mod(w.beat, 4.0));

    // morning
    if (w.light > 0.01) {
        const day = music.hue(0);
        r.glow(v.sx(world_mod.knot_x), v.sy(world_mod.knot_y), 760.0 * z, gfx.rgb(day, 0.20 * w.light));
        r.glow(v.sx(w.x), v.sy(w.y), 330.0 * z, gfx.rgb(day, 0.07 * w.light));
    }

    drawGarden(r, w, v);

    for (w.rings) |ring| {
        if (!ring.alive) continue;
        r.circle(v.sx(ring.x), v.sy(ring.y), ring.r * z, 3.0, gfx.rgb(ring.color, 0.75 * ring.life));
    }

    drawDrip(r, w, v, dt, in_beat);
    for (&w.creatures) |*c| drawCreature(r, w, v, c, in_beat);
    drawHum(r, w, v, in_beat, in_bar);
    drawWheel(r, w, v, in_bar);

    for (w.sparks) |s| {
        if (s.life <= 0.0) continue;
        r.dot(v.sx(s.x), v.sy(s.y), 1.6, gfx.rgb(s.color, s.life));
    }

    // one line of words, large
    const words = if (w.said_left > 0.0) w.said else w.prompt;
    const alpha = if (w.said_left > 0.0) @min(1.0, w.said_left * 2.0) else w.prompt_show;
    if (words.len > 0 and alpha > 0.02) {
        const scale = 2.0;
        const wide = Renderer.textWidth(words, scale);
        r.rect(320.0 - wide / 2.0 - 12.0, 414.0, wide + 24.0, 54.0, gfx.faded(gfx.void_black, 0.55 * alpha));
        r.text(320.0 - wide / 2.0, 418.0, scale, gfx.faded(gfx.bone, alpha), words);
    }
}

fn drawGarden(r: *Renderer, w: *const World, v: *const View) void {
    const z = v.zoom;
    const sway = @sin(v.clock * 0.9) * 3.0;

    // the hose, from the spigot to the knot
    const hose_lit = @max(w.lit[world_mod.things.len - 1], w.light * 0.8);
    if (hose_lit > 0.02) {
        const col = gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.55 * hose_lit);
        for (0..world_mod.hose.len - 1) |i| {
            const a = world_mod.hose[i];
            const b = world_mod.hose[i + 1];
            r.line(v.sx(a[0]), v.sy(a[1]), v.sx(b[0]), v.sy(b[1]), 5.0 * z, col);
        }
        const kx = v.sx(world_mod.knot_x);
        const ky = v.sy(world_mod.knot_y);
        const stage = @intFromEnum(w.stage);
        if (stage >= @intFromEnum(world_mod.Stage.waking)) {
            // the knot, sprung open into a loop
            r.circle(kx, ky, 22.0 * z, 5.0 * z, col);
        } else {
            // the knot moves: five against three
            const writhe: f32 = if (w.drip_riding) 1.6 else 0.3;
            figure(r, kx, ky, 20.0 * z, 5, 3, v.clock * writhe, 4.5 * z, gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.65 * hose_lit));
        }
    }

    // water: once the knots are open it runs along the hose and on to the pool
    if (w.water > 0.0) {
        const reach = w.water * @as(f32, @floatFromInt(world_mod.hose.len));
        for (0..world_mod.hose.len - 1) |i| {
            if (@as(f32, @floatFromInt(i)) > reach) break;
            const a = world_mod.hose[i];
            const b = world_mod.hose[i + 1];
            r.line(v.sx(a[0]), v.sy(a[1]), v.sx(b[0]), v.sy(b[1]), 2.0 * z, gfx.rgb(water3, 0.8));
        }
    }

    for (world_mod.things, 0..) |t, i| {
        const b = @max(w.lit[i], w.light * 0.75);
        if (b < 0.02) continue;
        const x = v.sx(t.x);
        const y = v.sy(t.y);
        if (x < -80.0 or x > 720.0 or y < -80.0 or y > 560.0) continue;
        const s = t.size * z;
        switch (t.kind) {
            .reed => {
                for (0..5) |k| {
                    const f: f32 = @as(f32, @floatFromInt(k)) - 2.0;
                    const tall = 30.0 + 7.0 * @as(f32, @floatFromInt(k % 3));
                    r.line(x + f * 3.0 * s, y, x + (f * 9.0 + sway) * s, y - tall * s, 2.2, gfx.rgb(gfx.mix(bone3, leaf3, 0.5), 0.5 * b));
                }
            },
            .aster => {
                const col = music.hue(7); // aster violet
                r.line(x, y + 4.0 * s, x + sway * 0.4 * s, y + 34.0 * s, 2.2, gfx.rgb(leaf3, 0.4 * b));
                for (0..12) |k| {
                    const a = @as(f32, @floatFromInt(k)) * pi / 6.0 + 0.2;
                    r.line(x + @cos(a) * 4.0 * s, y + @sin(a) * 4.0 * s, x + @cos(a) * 17.0 * s, y + @sin(a) * 17.0 * s, 2.4, gfx.rgb(col, 0.6 * b));
                }
                r.dot(x, y, 3.0 * s, gfx.rgb(bone3, 0.7 * b));
            },
            .spigot => {
                const col = gfx.faded(gfx.chrome, 0.7 * b);
                r.line(x, y - 34.0 * s, x, y, 4.0, col);
                r.line(x, y, x + 12.0 * s, y, 4.0, col);
                r.line(x + 12.0 * s, y, x + 12.0 * s, y + 8.0 * s, 4.0, col);
                r.line(x - 8.0 * s, y - 34.0 * s, x + 8.0 * s, y - 34.0 * s, 3.0, col);
            },
            .pool => {
                r.circle(x, y, 46.0 * s, 3.0, gfx.rgb(gfx.mix(bone3, water3, 0.5), 0.5 * b));
                if (w.water > 0.4) {
                    const fill = (w.water - 0.4) / 0.6;
                    r.glow(x, y, 60.0 * s, gfx.rgb(water3, 0.35 * fill));
                    r.circle(x, y, 30.0 * s * fill + 6.0, 2.0, gfx.rgb(water3, 0.6 * fill));
                    r.circle(x, y, 16.0 * s * fill + 3.0, 2.0, gfx.rgb(water3, 0.4 * fill));
                }
            },
            .hose => {},
        }
    }
}

fn drawDrip(r: *Renderer, w: *const World, v: *View, dt: f32, in_beat: f32) void {
    if (w.drip_riding or w.stage == .dark_call) return;
    const z = v.zoom;
    const teal = music.hue(world_mod.drip_note);
    const x = v.sx(world_mod.drip_x);
    const y = v.sy(world_mod.drip_y);
    const seen = @max(w.drip_seen, w.lean_in);
    r.glow(x, y, 22.0 * z, gfx.rgb(teal, 0.35 * seen));
    r.disc(x, y + 2.0 * kick(in_beat) * z, (3.6 + 1.2 * kick(in_beat)) * z, gfx.rgb(teal, seen));

    // The figure between the two of them: a fifth, three lobes by two. It turns while they are
    // out of step and comes to rest as they fall in.
    if (w.lean_in > 0.02) {
        const out_of_step = @as(f32, @floatFromInt(4 - @min(w.together, 4))) / 4.0;
        v.turn += dt * (0.25 + 9.0 * w.flam) * out_of_step;
        const mx = (x + v.sx(w.x)) * 0.5;
        const my = (y + v.sy(w.y)) * 0.5 - 6.0 * z;
        const bright = 0.35 + 0.15 * @as(f32, @floatFromInt(w.together));
        figure(r, mx, my, 26.0 * z, 3, 2, v.turn, 2.6, gfx.rgb(gfx.mix(bone3, teal, 0.5), bright * w.lean_in));
    }
}

fn drawCreature(r: *Renderer, w: *const World, v: *const View, c: *const Creature, in_beat: f32) void {
    if (c.state == .none) return;
    const z = v.zoom;
    const x = v.sx(c.x);
    const y = v.sy(c.y);
    if (x < -60.0 or x > 700.0 or y < -60.0 or y > 540.0) return;
    const hue = music.hue(c.note);
    const col = gfx.mix(grey3, hue, c.colour);
    const hx = v.sx(w.x);
    const hy = v.sy(w.y);

    switch (c.state) {
        .roam, .windup, .lunge, .recover, .grey => {
            const p = music.pair(w.home, c.note);
            var size = 15.0 * z * (1.0 + 0.22 * kick(c.pulse));
            var bright = 0.70 + 0.30 * c.flash;
            if (c.state == .windup) {
                size *= 1.25;
                bright = 1.0;
            }
            if (c.state == .grey) bright = 0.55 + 0.25 * @sin(v.clock * 2.0 + @as(f32, @floatFromInt(c.id)));
            r.glow(x, y, size * 2.4, gfx.rgb(col, 0.10 + 0.35 * c.meet_flash + 0.2 * c.flash));
            figure(r, x, y, size, p[0], p[1], c.spin + @as(f32, @floatFromInt(c.id)), if (c.knot) 2.0 else 2.6, gfx.rgb(gfx.mix(col, bone3, c.flash * 0.6), bright));
            if (c.knot) {
                const p2 = music.pair(w.home, c.other);
                const col2 = gfx.mix(grey3, music.hue(c.other), c.colour);
                const size2 = 9.0 * z * (1.0 + 0.3 * kick(c.pulse2));
                figure(r, x, y, size2, p2[0], p2[1], -c.spin * 1.3, 2.0, gfx.rgb(gfx.mix(col2, bone3, c.flash * 0.6), bright));
            }
            // two eyes, toward Hum
            const dx = hx - x;
            const dy = hy - y;
            const d = @max(@sqrt(dx * dx + dy * dy), 0.001);
            const ex = dx / d;
            const ey = dy / d;
            r.dot(x + ex * 4.0 - ey * 3.0, y + ey * 4.0 + ex * 3.0, 1.7 * z, gfx.faded(gfx.bone, 0.95));
            r.dot(x + ex * 4.0 + ey * 3.0, y + ey * 4.0 - ex * 3.0, 1.7 * z, gfx.faded(gfx.bone, 0.95));

            if (c.state == .windup) {
                // it is about to come: a line toward Hum that fills as its beat arrives
                r.line(x, y, x + dx * in_beat, y + dy * in_beat, 2.0, gfx.rgb(col, 0.5));
            }
            if (c.state == .grey) {
                // a thread to Hum when a close would bring it home (bright) or sing it to
                // sleep (soft)
                const door = w.door(c);
                if (door != 0) r.line(x, y, hx, hy, 1.6, gfx.rgb(bone3, if (door == 1) 0.55 else 0.28));
            }
        },
        .homing => {
            const t = 1.0 - c.timer / 2.0;
            r.circle(x, y, (10.0 + 70.0 * t) * z, 3.0, gfx.rgb(hue, 1.0 - t));
            const p = music.pair(w.home, c.note);
            figure(r, x, y, 15.0 * z * (1.0 - t), p[0], p[1], c.spin * 3.0, 2.6, gfx.rgb(hue, 1.0 - t));
            r.glow(x, y, 50.0 * z, gfx.rgb(hue, 0.5 * (1.0 - t)));
        },
        .open => {
            // a loop of hose, lying open
            r.circle(x, y, 12.0 * z, 4.0, gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.6));
        },
        .follow => {
            const hop = 2.5 * kick(in_beat);
            r.glow(x, y, 12.0 * z, gfx.rgb(hue, 0.25));
            r.circle(x, y - hop, 5.0 * z, 2.0, gfx.rgb(hue, 0.9));
            r.dot(x, y - hop, 1.8 * z, gfx.faded(gfx.bone, 0.9));
        },
        .asleep => {
            const breathe = 0.5 + 0.5 * @sin(v.clock * 1.2 + @as(f32, @floatFromInt(c.id)));
            figure(r, x, y, (7.0 + breathe) * z, 1, 1, pi / 2.0, 2.2, gfx.rgb(hue, 0.30 + 0.15 * breathe));
        },
        .none => {},
    }
}

fn drawHum(r: *Renderer, w: *const World, v: *const View, in_beat: f32, in_bar: f32) void {
    const z = v.zoom;
    var x = v.sx(w.x);
    const y = v.sy(w.y);
    if (w.hurt > 0.0) x += @sin(v.clock * 60.0) * 2.5 * w.hurt;

    // the one: a ring runs out from Hum at the start of each bar
    if (w.drip_riding and in_bar < 0.9) {
        const p = in_bar / 0.9;
        r.circle(x, y, (14.0 + 120.0 * p) * z, 2.5, gfx.rgb(bone3, 0.30 * (1.0 - p) * (1.0 - p)));
    }

    // Hum's note is its lantern
    var lantern: f32 = 36.0;
    if (w.swell) lantern += 6.0 * @min(w.swell_beats, 12.0);
    r.glow(x, y, (lantern + 60.0 * w.landed) * z, gfx.rgb(bone3, 0.18 + 0.3 * w.landed));
    if (w.landed > 0.0) r.circle(x, y, (20.0 + 90.0 * (1.0 - w.landed)) * z, 3.0, gfx.rgb(music.hue(w.home), w.landed));

    if (w.swell) {
        // the swell gathers; the arc is the breath left
        r.circle(x, y, (15.0 + 2.2 * @min(w.swell_beats, 16.0)) * z, 2.5, gfx.rgb(music.hue(w.swell_root), 0.6));
        const left = std.math.clamp(w.breath / w.breath_cap, 0.0, 1.0);
        r.arc(x, y, 12.0 * z, 0.0, 2.0 * pi * left, 2.5, gfx.faded(gfx.bone, 0.8));
    }
    if (w.pocket > 0.0) r.circle(x, y, 60.0 * z, 2.0, gfx.rgb(music.hue(w.home), 0.5));

    if (w.strike_anim > 0.0) {
        // the fork rings: an arc in front
        const face = std.math.atan2(w.face_x, -w.face_y);
        const reach = w.feel.reach * z * (1.0 - 0.45 * w.strike_anim);
        r.arc(x, y, reach, face - 1.1, face + 1.1, 3.5, gfx.rgb(gfx.mix(bone3, music.hue(w.home), 0.5), w.strike_anim));
    }

    const body = gfx.faded(gfx.bone, if (w.invuln > 0.0 and @mod(v.clock * 12.0, 1.0) < 0.4) 0.55 else 1.0);
    r.disc(x, y, 7.5 * z, body);
    // two dark eyes, a glint in each
    const fx = w.face_x;
    const fy = w.face_y;
    for ([2]f32{ -1.0, 1.0 }) |side| {
        const ex = x + (fx * 2.6 - fy * 2.7 * side) * z;
        const ey = y + (fy * 2.6 + fx * 2.7 * side) * z;
        r.disc(ex, ey, 2.0 * z, gfx.void_black);
        r.disc(ex - 0.5 * z, ey - 0.6 * z, 0.75 * z, gfx.bone);
    }

    if (w.drip_riding) {
        // Drip rides on Hum's head and keeps time
        const teal = music.hue(world_mod.drip_note);
        const squash = kick(in_beat);
        const dy = -11.0 - 14.0 * w.drip_hop * (1.0 - w.drip_hop) * 4.0;
        r.disc(x, y + (dy + 1.5 * squash) * z, (3.4 + 0.9 * squash) * z, gfx.rgb(teal, 1.0));
        r.disc(x - 0.9 * z, y + (dy - 0.6) * z, 0.8 * z, gfx.bone);
    }
}

fn drawWheel(r: *Renderer, w: *const World, v: *const View, in_bar: f32) void {
    const show = w.wheel_show;
    if (show < 0.02) return;
    const x = v.sx(w.x);
    const y = v.sy(w.y);
    const radius = 96.0 * (0.72 + 0.28 * show);
    const step = pi / 6.0;
    const on_one = 1.0 - std.math.clamp(in_bar / 0.5, 0.0, 1.0);

    // the star: its strings join notes a half step apart
    for (0..12) |k| {
        const a = @as(f32, @floatFromInt(k)) * step;
        const b = @as(f32, @floatFromInt(k + 5)) * step;
        r.line(x + @sin(a) * radius, y - @cos(a) * radius, x + @sin(b) * radius, y - @cos(b) * radius, 1.4, gfx.rgb(bone3, 0.05 * show));
    }

    // twelve wedges: the awake ones bright, the sleeping lit ones dim, the five dark ones faint
    for (0..12) |k| {
        const note = music.wedgeNote(k);
        const a = @as(f32, @floatFromInt(k)) * step;
        const hue = music.hue(note);
        if (w.isAwake(note)) {
            r.arc(x, y, radius, a - 0.21, a + 0.21, 6.5, gfx.rgb(hue, (0.80 + 0.2 * on_one) * show));
        } else if (music.isLit(note)) {
            r.arc(x, y, radius, a - 0.21, a + 0.21, 3.0, gfx.rgb(hue, 0.26 * show));
        } else {
            r.arc(x, y, radius, a - 0.21, a + 0.21, 2.0, gfx.rgb(hue, 0.14 * show));
        }
    }

    // home, and the wedge being pointed at
    const ah = @as(f32, @floatFromInt(music.noteWedge(w.home))) * step;
    r.arc(x, y, radius + 8.0, ah - 0.23, ah + 0.23, 4.0, gfx.faded(gfx.bone, (0.75 + 0.25 * w.home_flash) * show));
    const hpx = x + @sin(ah) * (radius - 13.0);
    const hpy = y - @cos(ah) * (radius - 13.0);
    r.dot(hpx, hpy, 3.2, gfx.faded(gfx.bone, show));
    const pointed: ?music.Note = if (w.wheel_open) w.hover else w.pending;
    if (pointed) |h| {
        if (h != w.home) {
            const a = @as(f32, @floatFromInt(music.noteWedge(h))) * step;
            const pulse = 0.6 + 0.4 * @sin(v.clock * 9.0);
            r.arc(x, y, radius + 8.0, a - 0.23, a + 0.23, 4.0, gfx.rgb(music.hue(h), pulse * show));
        }
    }

    // every creature near is a point on the ring, with a thread to home
    var stack: [12]u8 = @splat(0);
    for (&w.creatures) |*c| {
        if (!c.live()) continue;
        const dx = c.x - w.x;
        const dy = c.y - w.y;
        if (dx * dx + dy * dy > 460.0 * 460.0) continue;
        const notes = [2]music.Note{ c.note, c.other };
        const count: usize = if (c.knot) 2 else 1;
        var at: [2][2]f32 = undefined;
        for (0..count) |i| {
            const k = music.noteWedge(notes[i]);
            const a = @as(f32, @floatFromInt(k)) * step;
            const rr = radius + 19.0 + 8.0 * @as(f32, @floatFromInt(stack[k]));
            stack[k] += 1;
            const px = x + @sin(a) * rr;
            const py = y - @cos(a) * rr;
            at[i] = .{ px, py };
            const col = gfx.mix(grey3, music.hue(notes[i]), c.colour);
            const beat_now = if (i == 0) c.pulse else c.pulse2;
            r.dot(px, py, 3.2 + 1.8 * kick(beat_now), gfx.rgb(gfx.mix(col, bone3, 0.2), show));
            if (c.knot) continue;
            const thread: f32 = switch (music.relation(w.home, notes[i])) {
                .kin => 0.55,
                .leans_in, .lean_to => 0.60,
                .warm => 0.22,
                else => 0.07,
            };
            r.line(hpx, hpy, px, py, 1.6, gfx.rgb(gfx.mix(bone3, col, 0.4), thread * show));
            if (c.state == .grey) {
                // it leans toward the wedge on its left
                r.arc(x, y, rr, a, a - step * 0.8, 2.2, gfx.faded(gfx.bone, 0.85 * show));
                const tip = a - step * 0.8;
                const tx = x + @sin(tip) * rr;
                const ty = y - @cos(tip) * rr;
                r.line(tx, ty, x + @sin(tip + 0.12) * (rr + 5.0), y - @cos(tip + 0.12) * (rr + 5.0), 2.2, gfx.faded(gfx.bone, 0.85 * show));
                r.line(tx, ty, x + @sin(tip + 0.12) * (rr - 5.0), y - @cos(tip + 0.12) * (rr - 5.0), 2.2, gfx.faded(gfx.bone, 0.85 * show));
            }
        }
        if (c.knot) {
            // its two strands point at the wedge where they meet
            const meet = World.meetingPlace(c);
            const am = @as(f32, @floatFromInt(music.noteWedge(meet))) * step;
            const mx = x + @sin(am) * radius;
            const my = y - @cos(am) * radius;
            const bright: f32 = if (w.home == meet) 0.35 else 0.70;
            for (0..2) |i| r.line(at[i][0], at[i][1], mx, my, 1.6, gfx.rgb(bone3, bright * show));
            if (w.home != meet) r.circle(mx, my, 7.0 + 2.0 * @sin(v.clock * 7.0), 2.0, gfx.faded(gfx.bone, 0.8 * show));
        }
    }
}

/// A few lines of numbers, top left, for whoever is tuning the toy.
pub fn numbers(r: *Renderer, w: *const World, frame_ms: f64, gaps: u32) void {
    var buf: [120]u8 = undefined;
    const quiet = gfx.faded(gfx.bone, 0.6);
    const mood = music.mood(w.home);
    const first = std.fmt.bufPrint(&buf, "{s}  HOME {s}  BEAT {d:.2}", .{
        @tagName(w.stage),
        if (mood) |m| music.mood_names[@intFromEnum(m)] else "BORROWED",
        @mod(w.beat, 4.0) + 1.0,
    }) catch "";
    r.text(10.0, 8.0, 1.0, quiet, first);
    const second = std.fmt.bufPrint(&buf, "TO THE ONE {d:.0} MS  BREATH {d:.1}/{d:.0}  BEST WALK {d}", .{
        w.toTheOne() * 1000.0,
        w.breath,
        w.breath_cap,
        w.best_walk,
    }) catch "";
    r.text(10.0, 8.0 + 24.0, 1.0, quiet, second);
    const third = std.fmt.bufPrint(&buf, "{d:.1} MS  AUDIO GAPS {d}  {s}", .{ frame_ms, gaps, if (w.gentle) "GENTLE" else "PLAIN" }) catch "";
    r.text(10.0, 8.0 + 48.0, 1.0, quiet, third);
}
