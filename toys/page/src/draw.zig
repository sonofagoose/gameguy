//! The wheel toy's garden, drawn so that it can be a page or a place.
//!
//! Nothing here decides what happens: the rules are the wheel toy's, untouched. This file only
//! decides where the eye is and whether things lie or stand.
//!
//! - Before the third note there are only two voices, and two voices draw a flat figure: the
//!   world is a page, seen from above.
//! - When the third note sounds (the one neither of them is singing) the page tilts back and
//!   everything on it stands up: reeds, asters, the bodies of creatures. Each body's depth is
//!   the note between its own note and home. Kin, with no note between, stay flat.
//! - Hold the wheel and the place folds back onto the page so it can be read; let go and it
//!   stands again. The wheel's seven lit wedges are the half that stands above the ground, and
//!   its five dark ones the half that goes under it.
const std = @import("std");
const gfx = @import("gfx.zig");
const cam_mod = @import("cam.zig");
const rules = @import("wheel");
const music = rules.music;
const world_mod = rules.world;
const World = world_mod.World;
const Creature = world_mod.Creature;
const Renderer = gfx.Renderer;
const Cam = cam_mod.Cam;
const V3 = cam_mod.V3;

const pi = std.math.pi;
const bone3 = [3]f32{ 0.886, 0.839, 0.784 };
const grey3 = [3]f32{ 0.60, 0.60, 0.62 };
const leaf3 = [3]f32{ 0.52, 0.74, 0.50 };
const water3 = [3]f32{ 0.30, 0.62, 0.96 };

/// Which way the toy shows the world.
pub const Look = enum {
    /// A page until the third note, then a place; holding the wheel folds it back to the page.
    both,
    /// A place from the start; the wheel stands round Hum, its dark wedges under the ground.
    place,
    /// The page only: the wheel toy's picture.
    page,

    pub fn name(self: Look) []const u8 {
        return switch (self) {
            .both => "PAGE AND PLACE",
            .place => "PLACE ONLY",
            .page => "PAGE ONLY",
        };
    }

    pub fn next(self: Look, step: i32) Look {
        const n: i32 = @intFromEnum(self);
        return @enumFromInt(@as(u2, @intCast(@mod(n + step, 3))));
    }
};

/// Everything about how the view moves, in one place for tuning.
pub const Feel = struct {
    /// How fast the place folds to the page when the wheel opens, and back (per second).
    fold_rate: f32 = 7.0,
    /// How fast the look changes when asked for by hand.
    look_rate: f32 = 2.2,
    /// Radians a second the view turns at a full stick.
    turn_rate: f32 = 1.9,
    /// A creature this near pulls the camera up and back.
    tense_within: f32 = 340.0,
    tense_in: f32 = 1.5,
    tense_out: f32 = 0.5,
    /// The share of the morning's light by which the world has finished standing.
    stood_by: f32 = 0.75,
};

pub const View = struct {
    feel: Feel = .{},
    look: Look = .both,
    cam: Cam = .{},
    cx: f32 = 0.0,
    cy: f32 = 0.0,
    zoom: f32 = 1.0,
    ready: bool = false,
    yaw: f32 = 0.0,
    /// 0 page, 1 place: where the story has got to.
    stood: f32 = 0.0,
    /// 1 while the wheel holds the world folded.
    fold: f32 = 0.0,
    tense: f32 = 0.0,
    /// The turning of the figure between Hum and Drip.
    turn: f32 = 0.0,
    clock: f32 = 0.0,
    label_left: f32 = 0.0,
    // for the session log
    page_s: f32 = 0.0,
    place_s: f32 = 0.0,
    between_s: f32 = 0.0,

    pub fn setLook(self: *View, look: Look) void {
        self.look = look;
        self.label_left = 2.5;
    }

    /// Move the eye. `turn_stick` is the right stick's sideways push when it is free.
    pub fn update(self: *View, w: *const World, dt: f32, turn_stick: f32) void {
        const f = self.feel;
        self.clock += dt;
        self.label_left = @max(0.0, self.label_left - dt);

        // The camera follows Hum; beside Drip it leans in between the two of them.
        const lean = w.lean_in;
        const tx = w.x + (world_mod.drip_x - w.x) * 0.5 * lean;
        const ty = w.y + (world_mod.drip_y - w.y) * 0.5 * lean;
        const want_zoom = 1.0 + 0.5 * lean;
        if (!self.ready) {
            self.cx = tx;
            self.cy = ty;
            self.ready = true;
            if (self.look == .place) self.stood = 1.0;
        }
        const ease = @min(1.0, dt * 4.0);
        self.cx += (tx - self.cx) * ease;
        self.cy += (ty - self.cy) * ease;
        self.zoom += (want_zoom - self.zoom) * ease;

        // the story: the world stands as the third note brings the morning
        const want_stood: f32 = switch (self.look) {
            .page => 0.0,
            .place => 1.0,
            .both => smooth(w.light / f.stood_by),
        };
        self.stood += (want_stood - self.stood) * @min(1.0, dt * f.look_rate);
        if (@abs(want_stood - self.stood) < 0.002) self.stood = want_stood;

        // the wheel folds the place back onto the page
        const want_fold: f32 = if (self.look == .both) smooth(w.wheel_show) else 0.0;
        self.fold += (want_fold - self.fold) * @min(1.0, dt * f.fold_rate);

        // a creature near pulls the camera up and back, so a fight can be read
        var near = false;
        for (&w.creatures) |*cr| {
            if (!cr.live()) continue;
            const dx = cr.x - w.x;
            const dy = cr.y - w.y;
            if (dx * dx + dy * dy < f.tense_within * f.tense_within) near = true;
        }
        const want_tense: f32 = if (near) 1.0 else 0.0;
        self.tense += (want_tense - self.tense) * @min(1.0, dt * (if (near) f.tense_in else f.tense_out));

        if (self.stood > 0.5 and !w.wheel_open and !w.swell) self.yaw += turn_stick * f.turn_rate * dt;

        const k = smooth(self.tense);
        const pose = cam_mod.Pose{
            .pitch = cam_mod.calm.pitch + (cam_mod.fight.pitch - cam_mod.calm.pitch) * k,
            .back = (cam_mod.calm.back + (cam_mod.fight.back - cam_mod.calm.back) * k) / self.zoom,
            .ahead = (cam_mod.calm.ahead + (cam_mod.fight.ahead - cam_mod.calm.ahead) * k) / self.zoom,
        };
        const deep = smooth(self.stood * (1.0 - self.fold));
        self.cam.aim(self.cx, self.cy, self.yaw, self.zoom, deep, pose);

        if (deep < 0.05) self.page_s += dt else if (deep > 0.95) self.place_s += dt else self.between_s += dt;
    }
};

fn smooth(t: f32) f32 {
    const x = std.math.clamp(t, 0.0, 1.0);
    return x * x * (3.0 - 2.0 * x);
}

/// 1 at the start of a pulse, falling away fast.
fn kick(phase: f32) f32 {
    const k = 1.0 - std.math.clamp(phase, 0.0, 1.0);
    return k * k * k;
}

/// The figure two pulses in the ratio a:b draw against each other. On the page it is flat. In
/// the place it stands, and gains depth from a third pulse: the difference of the two, which is
/// the note that sounds between them and that neither is singing. With no difference (kin, 1:1)
/// it has no depth.
const Figure = struct {
    x: f32,
    y: f32,
    /// How far its middle floats above the ground once standing.
    hover: f32,
    size: f32,
    a: u8,
    b: u8,
    phase: f32,
    thick: f32,
    sized: bool = false,
    /// Radians it is turned about its upright axis (only once standing).
    rock: f32 = 0.0,
    /// It stays on the ground whatever the view (a sleeper).
    lying: bool = false,
};

fn figure(r: *Renderer, f: Figure, color: gfx.Color) void {
    const cam = r.cam;
    const steps: usize = @min(200, 22 * @as(usize, @max(f.a, f.b)));
    const fa: f32 = @floatFromInt(f.a);
    const fb: f32 = @floatFromInt(f.b);
    const between: f32 = @abs(fa - fb);
    const reach: f32 = if (between > 0.0) f.size * 0.85 else 0.0;
    const rho = f.rock * cam.stand;
    const cr = @cos(rho);
    const sr = @sin(rho);
    var points: [201]V3 = undefined;
    for (0..steps + 1) |i| {
        const t = 2.0 * pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
        const s = @sin(fa * t + f.phase) * f.size;
        const up = -@sin(fb * t) * f.size;
        const d = @sin(between * t + f.phase * 0.5) * reach;
        points[i] = if (f.lying)
            cam.ground(f.x + s, f.y - up)
        else
            cam.solid(f.x, f.y, s * cr + d * sr, up, d * cr - s * sr, f.hover);
    }
    points[steps] = points[0];
    r.path(points[0 .. steps + 1], f.thick, f.sized, color, true);
}

pub fn draw(r: *Renderer, w: *const World, v: *View, dt: f32) void {
    const cam = &v.cam;
    r.begin(cam);
    const beat: f32 = @floatCast(@mod(w.beat, 64.0));
    const in_beat = beat - @floor(beat);
    const in_bar: f32 = @floatCast(@mod(w.beat, 4.0));
    const day = music.hue(0);

    // the sky over the far edge of the ground, and the day coming up in it
    if (cam.horizon > -320.0 and w.light > 0.01) {
        const a = w.light * smooth(cam.deep);
        r.sky(cam.horizon - 320.0, cam.horizon, gfx.rgb(day, 0.30 * a));
        r.sky(cam.horizon - 44.0, cam.horizon, gfx.rgb(gfx.mix(day, bone3, 0.45), 0.36 * a));
        // the sun comes up a little to the right of "up the page"
        var rel = 0.42 - v.yaw;
        rel -= 2.0 * pi * @round(rel / (2.0 * pi));
        if (@abs(rel) < 1.25) {
            const sx = gfx.width / 2.0 + cam.focal * @tan(rel);
            const sy = cam.horizon - 4.0 - 30.0 * w.light;
            r.glowAt(sx, sy, 230.0, gfx.rgb(day, 0.26 * a));
            r.glowAt(sx, sy, 46.0, gfx.rgb(gfx.mix(day, bone3, 0.7), 0.55 * a));
        }
    }

    // morning, lying on the ground
    if (w.light > 0.01) {
        r.pool(world_mod.knot_x, world_mod.knot_y, 760.0, gfx.rgb(day, 0.20 * w.light));
        r.pool(w.x, w.y, 330.0, gfx.rgb(day, 0.07 * w.light));
        // and thinly out to the far edge, once there is a far edge to see
        if (cam.deep > 0.02) r.pool(v.cx, v.cy, 2600.0, gfx.rgb(day, 0.11 * w.light * cam.deep));
    }

    const hum_depth = cam.see(cam.ground(w.x, w.y)).depth;
    const sway = @sin(v.clock * 0.9) * 3.0;

    drawGround(r, w, v);
    for (w.rings) |ring| {
        if (!ring.alive) continue;
        r.groundCircle(ring.x, ring.y, ring.r, 3.0, false, gfx.rgb(ring.color, 0.75 * ring.life));
    }

    // what is beyond Hum, then Hum, then what is nearer: only Hum and Drip cover anything
    drawGrass(r, w, v, sway, hum_depth, true);
    drawGiants(r, w, sway);
    drawThings(r, w, sway, hum_depth, true);
    drawDrip(r, w, v, dt, in_beat);
    for (&w.creatures) |*cr| {
        if (cam.see(cam.ground(cr.x, cr.y)).depth >= hum_depth - 0.5) drawCreature(r, w, v, cr, in_beat);
    }
    drawHum(r, w, v, in_beat, in_bar);
    for (&w.creatures) |*cr| {
        if (cam.see(cam.ground(cr.x, cr.y)).depth < hum_depth - 0.5) drawCreature(r, w, v, cr, in_beat);
    }
    drawThings(r, w, sway, hum_depth, false);
    drawGrass(r, w, v, sway, hum_depth, false);
    drawWheel(r, w, v, in_bar);

    for (w.sparks) |s| {
        if (s.life <= 0.0) continue;
        r.dot(.{ s.x, (8.0 + 26.0 * (1.0 - s.life)) * cam.stand, s.y }, 1.6, false, gfx.rgb(s.color, s.life));
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
    if (v.label_left > 0.0) {
        const name = v.look.name();
        r.text(630.0 - Renderer.textWidth(name, 1.0), 8.0, 1.0, gfx.faded(gfx.bone, @min(1.0, v.label_left)), name);
    }
}

/// What lies on the ground in either view: the hose, the water in it, the pool.
fn drawGround(r: *Renderer, w: *const World, v: *const View) void {
    const cam = r.cam;
    const hose_lit = @max(w.lit[world_mod.things.len - 1], w.light * 0.8);
    if (hose_lit > 0.02) {
        const col = gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.55 * hose_lit);
        var run: [world_mod.hose.len]V3 = undefined;
        for (world_mod.hose, 0..) |h, i| run[i] = cam.ground(h[0], h[1]);
        r.path(&run, 5.0, true, col, false);
        const stage = @intFromEnum(w.stage);
        if (stage >= @intFromEnum(world_mod.Stage.waking)) {
            // the knot, sprung open into a loop
            r.groundCircle(world_mod.knot_x, world_mod.knot_y, 22.0, 5.0, true, col);
        } else {
            // the knot moves: five against three
            const writhe: f32 = if (w.drip_riding) 1.6 else 0.3;
            figure(r, .{
                .x = world_mod.knot_x,
                .y = world_mod.knot_y,
                .hover = 24.0,
                .size = 20.0,
                .a = 5,
                .b = 3,
                .phase = v.clock * writhe,
                .thick = 4.5,
                .sized = true,
                .rock = 0.5 * @sin(v.clock * 0.6),
            }, gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.65 * hose_lit));
        }
    }

    // water: once the knots are open it runs along the hose and on to the pool
    if (w.water > 0.0) {
        const reach = w.water * @as(f32, @floatFromInt(world_mod.hose.len));
        var run: [world_mod.hose.len]V3 = undefined;
        var count: usize = 0;
        for (world_mod.hose, 0..) |h, i| {
            if (@as(f32, @floatFromInt(i)) > reach + 1.0) break;
            run[i] = cam.ground(h[0], h[1]);
            count = i + 1;
        }
        r.path(run[0..count], 2.0, true, gfx.rgb(water3, 0.8), false);
    }

    for (world_mod.things, 0..) |t, i| {
        if (t.kind != .pool) continue;
        const b = @max(w.lit[i], w.light * 0.75) * cam.haze(t.x, t.y);
        if (b < 0.02) continue;
        const s = t.size;
        r.groundCircle(t.x, t.y, 46.0 * s, 3.0, false, gfx.rgb(gfx.mix(bone3, water3, 0.5), 0.5 * b));
        if (w.water > 0.4) {
            const fill = (w.water - 0.4) / 0.6;
            r.pool(t.x, t.y, 60.0 * s, gfx.rgb(water3, 0.35 * fill));
            r.groundCircle(t.x, t.y, 30.0 * s * fill + 6.0, 2.0, false, gfx.rgb(water3, 0.6 * fill));
            r.groundCircle(t.x, t.y, 16.0 * s * fill + 3.0, 2.0, false, gfx.rgb(water3, 0.4 * fill));
        }
    }
}

fn hash(n: u32) u32 {
    var x = n *% 0x9E3779B1;
    x ^= x >> 15;
    x *%= 0x85EBCA77;
    x ^= x >> 13;
    return x;
}

fn unit(n: u32) f32 {
    return @as(f32, @floatFromInt(hash(n) & 0xFFFF)) / 65535.0;
}

const tufts = 460;

/// Short grass, so the ground is a ground: it shows where a call's ring passes, and by day.
fn drawGrass(r: *Renderer, w: *const World, v: *const View, sway: f32, hum_depth: f32, beyond: bool) void {
    const cam = r.cam;
    _ = v;
    for (0..tufts) |i| {
        const n: u32 = @intCast(i);
        const x = -760.0 + unit(n * 3 + 1) * 2200.0;
        const y = -1250.0 + unit(n * 3 + 2) * 1900.0;
        const foot = cam.see(cam.ground(x, y));
        if (!foot.ok or foot.x < -20.0 or foot.x > 660.0 or foot.y < -10.0 or foot.y > 500.0) continue;
        if ((foot.depth >= hum_depth - 0.5) != beyond) continue;
        var lit = w.light * 0.8;
        for (w.rings) |ring| {
            if (!ring.alive) continue;
            const dx = x - ring.x;
            const dy = y - ring.y;
            const off = @abs(@sqrt(dx * dx + dy * dy) - ring.r);
            if (off < 60.0) lit = @max(lit, (1.0 - off / 60.0) * ring.life);
        }
        lit *= cam.haze(x, y);
        if (lit < 0.03) continue;
        const tall = 6.0 + 5.0 * unit(n * 3 + 3);
        const col = gfx.rgb(gfx.mix(bone3, leaf3, 0.7), 0.30 * lit);
        const lean = sway * 0.35;
        r.line(cam.standing(x, y, -1.5, 0.0, 0.0), cam.standing(x, y, -4.0 + lean, tall * 0.7, 0.0), 1.6, false, col);
        r.line(cam.standing(x, y, 0.0, 0.0, 0.0), cam.standing(x, y, 0.5 + lean, tall, 0.0), 1.6, false, col);
        r.line(cam.standing(x, y, 1.5, 0.0, 0.0), cam.standing(x, y, 4.0 + lean, tall * 0.65, 0.0), 1.6, false, col);
    }
}

/// An aster whose flower is at (`x`, `y`) on the page. Its foot is `stem` units nearer the
/// viewer, so that standing puts the flower `stem` units up.
fn aster(r: *Renderer, x: f32, y: f32, s: f32, stem: f32, sway: f32, bright: f32, sized: bool) void {
    const cam = r.cam;
    const fx = x;
    const fy = y + stem;
    const nod = sway * 0.4 * s * cam.stand;
    const col = music.hue(7); // aster violet
    r.line(cam.standing(fx, fy, 0.0, 0.0, 0.0), cam.standing(fx, fy, nod, stem - 4.0 * s, 0.0), if (sized) 0.9 * s else 2.2, sized, gfx.rgb(leaf3, 0.4 * bright));
    for (0..12) |k| {
        const a = @as(f32, @floatFromInt(k)) * pi / 6.0 + 0.2;
        r.line(
            cam.standing(fx, fy, nod + @cos(a) * 4.0 * s, stem - @sin(a) * 4.0 * s, 0.0),
            cam.standing(fx, fy, nod + @cos(a) * 17.0 * s, stem - @sin(a) * 17.0 * s, 0.0),
            if (sized) 1.1 * s else 2.4,
            sized,
            gfx.rgb(col, 0.6 * bright),
        );
    }
    r.dot(cam.standing(fx, fy, nod, stem, 0.0), 3.0 * s, true, gfx.rgb(bone3, 0.7 * bright));
}

const Giant = struct { x: f32, y: f32, s: f32 };

/// Asters as tall as cathedrals, out past the garden. On the page they lie far off its edges.
const giants = [_]Giant{
    .{ .x = -640, .y = -1250, .s = 9 },   .{ .x = 260, .y = -1650, .s = 12 },
    .{ .x = 1180, .y = -1420, .s = 10 },  .{ .x = 1720, .y = -760, .s = 8 },
    .{ .x = -1240, .y = -520, .s = 9 },   .{ .x = 880, .y = -2250, .s = 14 },
    .{ .x = -330, .y = -2380, .s = 13 },  .{ .x = 1950, .y = -1850, .s = 12 },
    .{ .x = -1520, .y = -1720, .s = 11 }, .{ .x = -940, .y = 980, .s = 10 },
    .{ .x = 620, .y = 1480, .s = 12 },    .{ .x = 1840, .y = 640, .s = 9 },
    .{ .x = -1740, .y = 360, .s = 10 },   .{ .x = 2300, .y = -420, .s = 13 },
};

fn drawGiants(r: *Renderer, w: *const World, sway: f32) void {
    const cam = r.cam;
    if (w.light < 0.02) return;
    for (giants, 0..) |g, i| {
        const stem = 30.0 * g.s;
        // fade by where the foot is, not the flower
        const bright = w.light * 0.8 * cam.haze(g.x, g.y + stem) * (0.55 + 0.45 * cam.stand);
        if (bright < 0.02) continue;
        aster(r, g.x, g.y, g.s, stem, sway * (0.6 + 0.1 * @as(f32, @floatFromInt(i % 4))), bright, true);
    }
}

/// What stands in the garden: reeds, asters, the spigot.
fn drawThings(r: *Renderer, w: *const World, sway: f32, hum_depth: f32, beyond: bool) void {
    const cam = r.cam;
    for (world_mod.things, 0..) |t, i| {
        if (t.kind == .pool or t.kind == .hose) continue;
        const b = @max(w.lit[i], w.light * 0.75) * cam.haze(t.x, t.y);
        if (b < 0.02) continue;
        const foot = cam.see(cam.ground(t.x, t.y));
        if (!foot.ok) continue;
        if ((foot.depth >= hum_depth - 0.5) != beyond) continue;
        if (foot.x < -160.0 or foot.x > 800.0 or foot.y < -160.0 or foot.y > 640.0) continue;
        const s = t.size;
        switch (t.kind) {
            .reed => {
                for (0..5) |k| {
                    const f: f32 = @as(f32, @floatFromInt(k)) - 2.0;
                    const tall = 30.0 + 7.0 * @as(f32, @floatFromInt(k % 3));
                    r.line(
                        cam.standing(t.x, t.y, f * 3.0 * s, 0.0, 0.0),
                        cam.standing(t.x, t.y, (f * 9.0 + sway) * s, tall * s, 0.0),
                        2.2,
                        false,
                        gfx.rgb(gfx.mix(bone3, leaf3, 0.5), 0.5 * b),
                    );
                }
            },
            .aster => aster(r, t.x, t.y, s, 34.0 * s, sway, b, false),
            .spigot => {
                // A standpipe with a handle on top and an arm to the right; the drop hangs
                // under the arm's spout, part way to the ground.
                const col = gfx.faded(gfx.chrome, 0.7 * b);
                const fx = t.x;
                const fy = t.y + 40.0 * s;
                r.line(cam.standing(fx, fy, -12.0 * s, 0.0, 0.0), cam.standing(fx, fy, -12.0 * s, 62.0 * s, 0.0), 4.0, false, col);
                r.line(cam.standing(fx, fy, -20.0 * s, 62.0 * s, 0.0), cam.standing(fx, fy, -4.0 * s, 62.0 * s, 0.0), 3.0, false, col);
                r.line(cam.standing(fx, fy, -12.0 * s, 46.0 * s, 0.0), cam.standing(fx, fy, 0.0, 46.0 * s, 0.0), 4.0, false, col);
                r.line(cam.standing(fx, fy, 0.0, 46.0 * s, 0.0), cam.standing(fx, fy, 0.0, 38.0 * s, 0.0), 4.0, false, col);
            },
            .pool, .hose => {},
        }
    }
}

/// Drip's foot: straight under the spout. The drop hangs 14 units above it.
const drip_foot_y = world_mod.drip_y + 14.0;

fn drawDrip(r: *Renderer, w: *const World, v: *View, dt: f32, in_beat: f32) void {
    const cam = r.cam;
    const teal = music.hue(world_mod.drip_note);

    // The figure between the two of them: a fifth, three lobes by two. It turns while they are
    // out of step and comes to rest as they fall in. When the third note sounds it is the first
    // thing to take on depth, and it rises over them into the morning.
    const dawning: f32 = if (w.stage == .dawn) std.math.clamp(1.0 - w.light * 1.3, 0.0, 1.0) else 0.0;
    const shown = @max(w.lean_in, dawning);
    if (shown > 0.02 and w.stage != .dark_call) {
        const out_of_step = @as(f32, @floatFromInt(4 - @min(w.together, 4))) / 4.0;
        v.turn += dt * (0.25 + 9.0 * w.flam) * out_of_step;
        const other_x = if (w.drip_riding) w.x else world_mod.drip_x;
        const other_y = if (w.drip_riding) w.y else world_mod.drip_y;
        const bright = 0.35 + 0.15 * @as(f32, @floatFromInt(@min(w.together, 4)));
        figure(r, .{
            .x = (other_x + w.x) * 0.5,
            .y = (other_y + w.y) * 0.5 - 6.0,
            .hover = 44.0 + 50.0 * w.light,
            .size = 26.0 * (1.0 + 0.8 * w.light),
            .a = 3,
            .b = 2,
            .phase = v.turn,
            .thick = 2.6,
            .rock = 0.7 * @sin(v.clock * 0.5),
        }, gfx.rgb(gfx.mix(bone3, teal, 0.5), bright * shown));
    }

    if (w.drip_riding or w.stage == .dark_call) return;
    const seen = @max(w.drip_seen, w.lean_in);
    const at = cam.standing(world_mod.drip_x, drip_foot_y, 0.0, 14.0 - 2.0 * kick(in_beat), 0.0);
    r.glow(at, 22.0, gfx.rgb(teal, 0.35 * seen));
    r.disc(at, 3.6 + 1.2 * kick(in_beat), gfx.rgb(teal, seen));
}

fn drawCreature(r: *Renderer, w: *const World, v: *const View, cr: *const Creature, in_beat: f32) void {
    if (cr.state == .none) return;
    const cam = r.cam;
    const foot = cam.see(cam.ground(cr.x, cr.y));
    if (!foot.ok or foot.x < -140.0 or foot.x > 780.0 or foot.y < -140.0 or foot.y > 620.0) return;
    const hue = music.hue(cr.note);
    const col = gfx.mix(grey3, hue, cr.colour);
    const id: f32 = @floatFromInt(cr.id);
    const rock = 0.55 * @sin(v.clock * 0.7 + id * 1.7);
    const hum_mid = V3{ w.x, 7.5 * cam.stand, w.y };

    switch (cr.state) {
        .roam, .windup, .lunge, .recover, .grey => {
            const p = music.pair(w.home, cr.note);
            var size = 15.0 * (1.0 + 0.22 * kick(cr.pulse));
            var bright = 0.70 + 0.30 * cr.flash;
            if (cr.state == .windup) {
                size *= 1.25;
                bright = 1.0;
            }
            if (cr.state == .grey) bright = 0.55 + 0.25 * @sin(v.clock * 2.0 + id);
            const hover = 20.0;
            const mid = V3{ cr.x, hover * cam.stand, cr.y };
            r.glow(mid, size * 2.4, gfx.rgb(col, 0.10 + 0.35 * cr.meet_flash + 0.2 * cr.flash));
            if (cam.stand > 0.05) r.pool(cr.x, cr.y, size * 1.6, gfx.rgb(col, 0.10 * cam.stand));
            figure(r, .{
                .x = cr.x,
                .y = cr.y,
                .hover = hover,
                .size = size,
                .a = p[0],
                .b = p[1],
                .phase = cr.spin + id,
                .thick = if (cr.knot) 2.0 else 2.6,
                .rock = rock,
            }, gfx.rgb(gfx.mix(col, bone3, cr.flash * 0.6), bright));
            if (cr.knot) {
                const p2 = music.pair(w.home, cr.other);
                const col2 = gfx.mix(grey3, music.hue(cr.other), cr.colour);
                figure(r, .{
                    .x = cr.x,
                    .y = cr.y,
                    .hover = hover,
                    .size = 9.0 * (1.0 + 0.3 * kick(cr.pulse2)),
                    .a = p2[0],
                    .b = p2[1],
                    .phase = -cr.spin * 1.3,
                    .thick = 2.0,
                    .rock = -rock,
                }, gfx.rgb(gfx.mix(col2, bone3, cr.flash * 0.6), bright));
            }
            // two eyes, toward Hum
            const dx = w.x - cr.x;
            const dy = w.y - cr.y;
            const d = @max(@sqrt(dx * dx + dy * dy), 0.001);
            const ex = dx / d;
            const ey = dy / d;
            r.dot(.{ mid[0] + ex * 4.0 - ey * 3.0, mid[1], mid[2] + ey * 4.0 + ex * 3.0 }, 1.7, true, gfx.faded(gfx.bone, 0.95));
            r.dot(.{ mid[0] + ex * 4.0 + ey * 3.0, mid[1], mid[2] + ey * 4.0 - ex * 3.0 }, 1.7, true, gfx.faded(gfx.bone, 0.95));

            if (cr.state == .windup) {
                // it is about to come: a line toward Hum that fills as its beat arrives
                const tip = V3{
                    mid[0] + (hum_mid[0] - mid[0]) * in_beat,
                    mid[1] + (hum_mid[1] - mid[1]) * in_beat,
                    mid[2] + (hum_mid[2] - mid[2]) * in_beat,
                };
                r.line(mid, tip, 2.0, false, gfx.rgb(col, 0.5));
            }
            if (cr.state == .grey) {
                // a thread to Hum when a close would bring it home (bright) or sing it to
                // sleep (soft)
                const door = w.door(cr);
                if (door != 0) r.line(mid, hum_mid, 1.6, false, gfx.rgb(bone3, if (door == 1) 0.55 else 0.28));
            }
        },
        .homing => {
            const t = 1.0 - cr.timer / 2.0;
            r.groundCircle(cr.x, cr.y, 10.0 + 70.0 * t, 3.0, false, gfx.rgb(hue, 1.0 - t));
            const p = music.pair(w.home, cr.note);
            figure(r, .{
                .x = cr.x,
                .y = cr.y,
                .hover = 20.0 + 30.0 * t,
                .size = 15.0 * (1.0 - t),
                .a = p[0],
                .b = p[1],
                .phase = cr.spin * 3.0,
                .thick = 2.6,
                .rock = rock,
            }, gfx.rgb(hue, 1.0 - t));
            r.glow(.{ cr.x, (20.0 + 30.0 * t) * cam.stand, cr.y }, 50.0, gfx.rgb(hue, 0.5 * (1.0 - t)));
        },
        .open => {
            // a loop of hose, lying open
            r.groundCircle(cr.x, cr.y, 12.0, 4.0, false, gfx.rgb(gfx.mix(bone3, leaf3, 0.6), 0.6));
        },
        .follow => {
            const hop = 2.5 * kick(in_beat);
            const at = V3{ cr.x, (6.0 + hop) * cam.stand, cr.y - hop * cam.lie };
            r.glow(at, 12.0, gfx.rgb(hue, 0.25));
            r.hingedArc(cr.x, cr.y - hop * cam.lie, 6.0 + hop, 5.0, 0.0, 2.0 * pi, 2.0, gfx.rgb(hue, 0.9));
            r.dot(at, 1.8, true, gfx.faded(gfx.bone, 0.9));
        },
        .asleep => {
            const breathe = 0.5 + 0.5 * @sin(v.clock * 1.2 + id);
            figure(r, .{
                .x = cr.x,
                .y = cr.y,
                .hover = 0.0,
                .size = 7.0 + breathe,
                .a = 1,
                .b = 1,
                .phase = pi / 2.0,
                .thick = 2.2,
                .lying = true,
            }, gfx.rgb(hue, 0.30 + 0.15 * breathe));
        },
        .none => {},
    }
}

fn drawHum(r: *Renderer, w: *const World, v: *const View, in_beat: f32, in_bar: f32) void {
    const cam = r.cam;
    var x = w.x;
    const y = w.y;
    if (w.hurt > 0.0) x += @sin(v.clock * 60.0) * 2.5 * w.hurt;
    const radius = 7.5;
    const mid = V3{ x, radius * cam.stand, y };

    // the one: a ring runs out from Hum over the ground at the start of each bar
    if (w.drip_riding and in_bar < 0.9) {
        const p = in_bar / 0.9;
        r.groundCircle(x, y, 14.0 + 120.0 * p, 2.5, false, gfx.rgb(bone3, 0.30 * (1.0 - p) * (1.0 - p)));
    }

    // Hum's note is its lantern: a pool of light on the ground
    var lantern: f32 = 36.0;
    if (w.swell) lantern += 6.0 * @min(w.swell_beats, 12.0);
    r.pool(x, y, lantern + 60.0 * w.landed, gfx.rgb(bone3, 0.18 + 0.3 * w.landed));
    if (cam.stand > 0.05) r.glow(mid, 20.0, gfx.rgb(bone3, 0.10 * cam.stand));
    if (w.landed > 0.0) r.groundCircle(x, y, 20.0 + 90.0 * (1.0 - w.landed), 3.0, false, gfx.rgb(music.hue(w.home), w.landed));

    if (w.swell) {
        // the swell gathers on the ground; the arc round Hum is the breath left
        r.groundCircle(x, y, 15.0 + 2.2 * @min(w.swell_beats, 16.0), 2.5, false, gfx.rgb(music.hue(w.swell_root), 0.6));
        const left = std.math.clamp(w.breath / w.breath_cap, 0.0, 1.0);
        r.hingedArc(x, y, radius, 12.0, 0.0, 2.0 * pi * left, 2.5, gfx.faded(gfx.bone, 0.8));
    }
    if (w.pocket > 0.0) r.groundCircle(x, y, 60.0, 2.0, false, gfx.rgb(music.hue(w.home), 0.5));

    if (w.strike_anim > 0.0) {
        // the fork rings: an arc on the ground in front
        const face = std.math.atan2(w.face_x, -w.face_y);
        const reach = w.feel.reach * (1.0 - 0.45 * w.strike_anim);
        r.groundArc(x, y, reach, face - 1.1, face + 1.1, 3.5, false, gfx.rgb(gfx.mix(bone3, music.hue(w.home), 0.5), w.strike_anim));
    }

    const body = gfx.faded(gfx.bone, if (w.invuln > 0.0 and @mod(v.clock * 12.0, 1.0) < 0.4) 0.55 else 1.0);
    r.disc(mid, radius, body);

    // Two dark eyes, a glint in each. On the page they are seen from above; as Hum stands they
    // come round to the front of its face, and from behind they cannot be seen.
    const st = cam.stand;
    const fwd = 0.347 + 0.45 * st;
    const out = 0.360 + 0.06 * st;
    const up = 0.866 - 0.52 * st;
    const norm = 1.0 / @sqrt(fwd * fwd + out * out + up * up);
    for ([2]f32{ -1.0, 1.0 }) |side| {
        const n = V3{
            (w.face_x * fwd - w.face_y * out * side) * norm,
            up * norm,
            (w.face_y * fwd + w.face_x * out * side) * norm,
        };
        const at = V3{ x + n[0] * radius, mid[1] + n[1] * radius * st, y + n[2] * radius };
        var to_eye = V3{ cam.eye[0] - at[0], cam.eye[1] - at[1], cam.eye[2] - at[2] };
        const len = @sqrt(to_eye[0] * to_eye[0] + to_eye[1] * to_eye[1] + to_eye[2] * to_eye[2]);
        to_eye = .{ to_eye[0] / len, to_eye[1] / len, to_eye[2] / len };
        const facing = n[0] * to_eye[0] + n[1] * to_eye[1] + n[2] * to_eye[2];
        if (facing < 0.10) continue;
        const open = @sqrt(@min(1.0, facing * 1.5));
        r.disc(at, 2.0 * open, gfx.void_black);
        r.disc(.{
            at[0] - cam.right[0] * 0.5 + cam.up[0] * 0.6,
            at[1] - cam.right[1] * 0.5 + cam.up[1] * 0.6,
            at[2] - cam.right[2] * 0.5 + cam.up[2] * 0.6,
        }, 0.75 * open, gfx.bone);
    }

    if (w.drip_riding) {
        // Drip rides on Hum's head and keeps time
        const teal = music.hue(world_mod.drip_note);
        const squash = kick(in_beat);
        const high = 11.0 + 56.0 * w.drip_hop * (1.0 - w.drip_hop) - 1.5 * squash;
        const at = cam.standing(x, y, 0.0, high, radius);
        r.disc(at, 3.4 + 0.9 * squash, gfx.rgb(teal, 1.0));
        r.disc(.{
            at[0] - cam.right[0] * 0.9 + cam.up[0] * 0.6,
            at[1] - cam.right[1] * 0.9 + cam.up[1] * 0.6,
            at[2] - cam.right[2] * 0.9 + cam.up[2] * 0.6,
        }, 0.8, gfx.bone);
    }
}

/// The wheel, hinged along its nine-to-three line through Hum. On the page it lies round Hum,
/// all twelve wedges. In the place its seven lit wedges stand over Hum as an arch and its five
/// dark ones go under the ground.
fn drawWheel(r: *Renderer, w: *const World, v: *const View, in_bar: f32) void {
    const show = w.wheel_show;
    if (show < 0.02) return;
    const cam = r.cam;
    const x = w.x;
    const y = w.y;
    const radius = 96.0 * (0.72 + 0.28 * show) * (1.0 - 0.25 * cam.stand);
    const step = pi / 6.0;
    const on_one = 1.0 - std.math.clamp(in_bar / 0.5, 0.0, 1.0);
    const under = 1.0 - 0.5 * cam.stand; // what is under the ground is seen dimly through it

    const at = struct {
        fn point(c: *const Cam, hx: f32, hy: f32, a: f32, rr: f32) V3 {
            return c.standing(hx, hy, @sin(a) * rr, @cos(a) * rr, 0.0);
        }
    }.point;

    // the star: its strings join notes a half step apart
    for (0..12) |k| {
        const a = @as(f32, @floatFromInt(k)) * step;
        const b = @as(f32, @floatFromInt(k + 5)) * step;
        r.line(at(cam, x, y, a, radius), at(cam, x, y, b, radius), 1.4, false, gfx.rgb(bone3, 0.05 * show));
    }

    // twelve wedges: the awake ones bright, the sleeping lit ones dim, the five dark ones faint
    for (0..12) |k| {
        const note = music.wedgeNote(k);
        const a = @as(f32, @floatFromInt(k)) * step;
        const hue = music.hue(note);
        if (w.isAwake(note)) {
            r.hingedArc(x, y, 0.0, radius, a - 0.21, a + 0.21, 6.5, gfx.rgb(hue, (0.80 + 0.2 * on_one) * show));
        } else if (music.isLit(note)) {
            r.hingedArc(x, y, 0.0, radius, a - 0.21, a + 0.21, 3.0, gfx.rgb(hue, 0.26 * show));
        } else {
            r.hingedArc(x, y, 0.0, radius, a - 0.21, a + 0.21, 2.0, gfx.rgb(hue, 0.14 * show * under));
        }
    }

    // home, and the wedge being pointed at
    const ah = @as(f32, @floatFromInt(music.noteWedge(w.home))) * step;
    r.hingedArc(x, y, 0.0, radius + 8.0, ah - 0.23, ah + 0.23, 4.0, gfx.faded(gfx.bone, (0.75 + 0.25 * w.home_flash) * show));
    const home_at = at(cam, x, y, ah, radius - 13.0);
    r.dot(home_at, 3.2, false, gfx.faded(gfx.bone, show));
    const pointed: ?music.Note = if (w.wheel_open) w.hover else w.pending;
    if (pointed) |h| {
        if (h != w.home) {
            const a = @as(f32, @floatFromInt(music.noteWedge(h))) * step;
            const pulse = 0.6 + 0.4 * @sin(v.clock * 9.0);
            r.hingedArc(x, y, 0.0, radius + 8.0, a - 0.23, a + 0.23, 4.0, gfx.rgb(music.hue(h), pulse * show));
        }
    }

    // every creature near is a point on the ring, with a thread to home
    var stack: [12]u8 = @splat(0);
    for (&w.creatures) |*cr| {
        if (!cr.live()) continue;
        const dx = cr.x - w.x;
        const dy = cr.y - w.y;
        if (dx * dx + dy * dy > 460.0 * 460.0) continue;
        const notes = [2]music.Note{ cr.note, cr.other };
        const count: usize = if (cr.knot) 2 else 1;
        var spot: [2]V3 = undefined;
        for (0..count) |i| {
            const k = music.noteWedge(notes[i]);
            const a = @as(f32, @floatFromInt(k)) * step;
            const rr = radius + 19.0 + 8.0 * @as(f32, @floatFromInt(stack[k]));
            stack[k] += 1;
            spot[i] = at(cam, x, y, a, rr);
            const col = gfx.mix(grey3, music.hue(notes[i]), cr.colour);
            const beat_now = if (i == 0) cr.pulse else cr.pulse2;
            r.dot(spot[i], 3.2 + 1.8 * kick(beat_now), false, gfx.rgb(gfx.mix(col, bone3, 0.2), show));
            if (cr.knot) continue;
            const thread: f32 = switch (music.relation(w.home, notes[i])) {
                .kin => 0.55,
                .leans_in, .lean_to => 0.60,
                .warm => 0.22,
                else => 0.07,
            };
            r.line(home_at, spot[i], 1.6, false, gfx.rgb(gfx.mix(bone3, col, 0.4), thread * show));
            if (cr.state == .grey) {
                // it leans toward the wedge on its left
                r.hingedArc(x, y, 0.0, rr, a, a - step * 0.8, 2.2, gfx.faded(gfx.bone, 0.85 * show));
                const tip = a - step * 0.8;
                const tip_at = at(cam, x, y, tip, rr);
                r.line(tip_at, at(cam, x, y, tip + 0.12, rr + 5.0), 2.2, false, gfx.faded(gfx.bone, 0.85 * show));
                r.line(tip_at, at(cam, x, y, tip + 0.12, rr - 5.0), 2.2, false, gfx.faded(gfx.bone, 0.85 * show));
            }
        }
        if (cr.knot) {
            // its two strands point at the wedge where they meet
            const meet = World.meetingPlace(cr);
            const am = @as(f32, @floatFromInt(music.noteWedge(meet))) * step;
            const meet_at = at(cam, x, y, am, radius);
            const bright: f32 = if (w.home == meet) 0.35 else 0.70;
            for (0..2) |i| r.line(spot[i], meet_at, 1.6, false, gfx.rgb(bone3, bright * show));
            if (w.home != meet) {
                // a small ring round the meeting place, in the wheel's own plane
                const ring = 7.0 + 2.0 * @sin(v.clock * 7.0);
                const side = @sin(am) * radius;
                const along = @cos(am) * radius;
                var prev = cam.standing(x, y, side + ring, along, 0.0);
                for (1..13) |i| {
                    const t = @as(f32, @floatFromInt(i)) * pi / 6.0;
                    const next = cam.standing(x, y, side + @cos(t) * ring, along + @sin(t) * ring, 0.0);
                    r.line(prev, next, 2.0, false, gfx.faded(gfx.bone, 0.8 * show));
                    prev = next;
                }
            }
        }
    }
}

/// A few lines of numbers, top left, for whoever is tuning the toy.
pub fn numbers(r: *Renderer, w: *const World, v: *const View, frame_ms: f64, gaps: u32) void {
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
    const third = std.fmt.bufPrint(&buf, "{d:.1} MS  {d} MARKS  GAPS {d}  DEEP {d:.2}  {s}", .{
        frame_ms,
        r.quads,
        gaps,
        v.cam.deep,
        if (w.gentle) "GENTLE" else "PLAIN",
    }) catch "";
    r.text(10.0, 8.0 + 48.0, 1.0, quiet, third);
}
