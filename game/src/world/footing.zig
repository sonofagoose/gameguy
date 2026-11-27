//! Hum's footing among what is solid (docs/engine.md, "Solids, and Hum's body"): what stops a
//! step, what Hum stands on, and what is over its head. There is one routine here for every kind of
//! solid thing, and one table of what each kind does when it is touched. No kind has collision
//! code of its own.
//!
//! No platform.
const std = @import("std");
const world_mod = @import("world.zig");
const World = world_mod.World;
const solid = @import("../body/solid.zig");
const form = @import("../form/shape.zig");
const feel = @import("../feel.zig");
const garden = @import("../place/garden.zig");
const covers = world_mod.covers;
const ground = world_mod.ground;
const harmony = world_mod.harmony;
const react = world_mod.react_mod;
const hose = world_mod.hose;
const cues_mod = world_mod.cues_mod;

/// How far round Hum solids are gathered: its own reach, the furthest one step takes it, and room.
const gather_reach: f32 = 4.0;
const most_placed = 80;
const most_made = 48;

/// Something Hum is against now, so that a touch sounds only as it begins.
pub const Touch = struct {
    kind: solid.Kind = .other,
    id: u32 = 0,
    /// How fast Hum came into it, in metres a second.
    came: f32 = 0.0,
    live: bool = false,
};
pub const most_touches = 6;

/// Every solid that could reach Hum round one place: the place's own, and the ones made for this
/// step alone, which are the ground's covers there and Drip while it still waits. It is filled
/// where it stands and never copied, since its list points into itself.
pub const Near = struct {
    list: [most_placed + most_made]*const solid.Solid = undefined,
    n: usize = 0,
    made: [most_made]solid.Solid = undefined,
    made_n: usize = 0,

    fn make(self: *Near, shape: form.Shape, kind: solid.Kind, id: u32) void {
        if (self.made_n >= most_made) return;
        self.made[self.made_n] = .{ .shape = solid.lifted(shape, &ground.heightAt), .kind = kind, .id = id };
        self.list[self.n] = &self.made[self.made_n];
        self.made_n += 1;
        self.n += 1;
    }

    pub fn slice(self: *const Near) []const *const solid.Solid {
        return self.list[0..self.n];
    }
};

/// Gather what is solid round a place.
pub fn gather(w: *const World, x: f32, z: f32, near: *Near) void {
    near.n = 0;
    near.made_n = 0;
    if (w.in_garden) {
        near.n = garden.solids().near(x, z, gather_reach, near.list[0..most_placed]);
        // on the page the hose is a drawn line, walked over; stood up, it is a tube
        if (w.stand < 1.0) {
            var kept: usize = 0;
            for (near.list[0..near.n]) |s| {
                if (s.kind == .hose) continue;
                near.list[kept] = s;
                kept += 1;
            }
            near.n = kept;
        }
        // the ground's covers: the same bodies the picture draws, from the same rule
        var bodies: [covers.most_in_patch]covers.Body = undefined;
        for ([2]bool{ false, true }) |close| {
            const size: f32 = if (close) covers.near_size else covers.far_size;
            const salt: u32 = if (close) covers.near_salt else 0;
            const cx: i32 = @intFromFloat(@floor(x / size));
            const cz: i32 = @intFromFloat(@floor(z / size));
            var iz = cz - 1;
            while (iz <= cz + 1) : (iz += 1) {
                var ix = cx - 1;
                while (ix <= cx + 1) : (ix += 1) {
                    const n = covers.patch(ix, iz, size, close, salt, &bodies);
                    for (bodies[0..n]) |b| {
                        var room: [2]form.Shape = undefined;
                        var sink = form.Sink{ .out = &room };
                        covers.shapes(b, &sink);
                        const kind: solid.Kind = switch (b.kind) {
                            .clover => .clover,
                            .crumb => .crumb,
                            .moss => .moss,
                            else => .other,
                        };
                        for (sink.slice()) |shape| near.make(shape, kind, b.s);
                    }
                }
            }
        }
        // fallen leaves that have risen off the ground: plates to stand on or bump a head under
        if (w.stand > 0.0 and w.react.rise > 0.01) {
            const lcx: i32 = @intFromFloat(@floor(x / covers.leaf_cell));
            const lcz: i32 = @intFromFloat(@floor(z / covers.leaf_cell));
            const leaf_reacts = react.Reacts{ .rise = feel.leaf_rises };
            var liz = lcz - 1;
            while (liz <= lcz + 1) : (liz += 1) {
                var lix = lcx - 1;
                while (lix <= lcx + 1) : (lix += 1) {
                    const leaf = covers.leafAt(lix, liz) orelse continue;
                    const up = harmony.moved(w, covers.leafCell(lix, liz), leaf_reacts, 0.0, leaf.x, leaf.z)[1];
                    if (up <= 0.05) continue;
                    var room: [1]form.Shape = undefined;
                    var sink = form.Sink{ .out = &room };
                    covers.leafShape(leaf, up, &sink);
                    for (sink.slice()) |shape| near.make(shape, .leaf, leaf.s);
                }
            }
        }
    }
    // before the two of you meet, Drip holds Hum off
    if (!w.drip_met and w.drip < w.thing_count) {
        const th = w.things[w.drip];
        near.make(.{ .ball = .{ .at = .{ th.x, th.y, th.z }, .r = th.tall * 0.5 } }, .drip, 0);
    }
}

fn bodyAt(w: *const World, x: f32, z: f32, feet: f32) solid.Body {
    return .{ .x = x, .z = z, .feet = @max(feet, w.groundAt(x, z)), .reach = world_mod.hum_body, .tall = world_mod.hum_tall };
}

/// Whether Hum standing on the ground at a place would be inside something solid.
pub fn solidAt(w: *const World, x: f32, z: f32) bool {
    var near: Near = undefined;
    gather(w, x, z, &near);
    return inside(w, &near, x, z, w.groundAt(x, z));
}

fn inside(w: *const World, near: *const Near, x: f32, z: f32, feet: f32) bool {
    const body = bodyAt(w, x, z, feet);
    for (near.slice()) |s| {
        if (solid.meet(s, body, world_mod.step_up, x, z)) |m| {
            // a hair's overlap is standing against it, not inside it
            if (m.by > 0.005) return true;
        }
    }
    return false;
}

/// Push a step out of whatever is solid, and sound what it newly touches. `go` is the step Hum's
/// legs ask for; it comes back as the step Hum can take.
pub fn against(w: *World, go_x: *f32, go_z: *f32) void {
    var near: Near = undefined;
    gather(w, w.hum_x + go_x.*, w.hum_z + go_z.*, &near);
    const feet = w.hum_ground + w.hum_y;
    var now: [most_touches]Touch = @splat(.{});
    var pass: usize = 0;
    while (pass < 3) : (pass += 1) {
        var pushed = false;
        for (near.slice()) |s| {
            const body = bodyAt(w, w.hum_x + go_x.*, w.hum_z + go_z.*, feet);
            const m = solid.meet(s, body, world_mod.step_up, w.hum_x, w.hum_z) orelse continue;
            go_x.* += m.nx * m.by;
            go_z.* += m.nz * m.by;
            // what it was going into the solid with is taken away, and is how hard it touched
            const v_in = w.hum_vx * m.nx + w.hum_vz * m.nz;
            var came: f32 = 0.0;
            if (v_in < 0.0) {
                w.hum_vx -= v_in * m.nx;
                w.hum_vz -= v_in * m.nz;
                came = -v_in;
            }
            note(&now, s.kind, s.id, came);
            pushed = true;
        }
        if (!pushed) break;
    }
    // pushed out of one solid into another, the step is not taken: Hum never ends a step inside
    // anything, unless it began inside, when it may walk out
    if (inside(w, &near, w.hum_x + go_x.*, w.hum_z + go_z.*, feet) and !inside(w, &near, w.hum_x, w.hum_z, feet)) {
        go_x.* = 0.0;
        go_z.* = 0.0;
    }
    // a touch sounds as it begins
    for (now) |t| {
        if (!t.live) continue;
        var was = false;
        for (w.touches) |old| {
            if (old.live and old.kind == t.kind and old.id == t.id) was = true;
        }
        if (!was) touched(w, t);
    }
    w.touches = now;
    w.at_hose = false;
    w.touching = world_mod.no_tower;
    for (now) |t| {
        if (!t.live) continue;
        if (t.kind == .hose) w.at_hose = true;
        if (t.kind == .tower) w.touching = @intCast(t.id);
    }
}

fn note(now: *[most_touches]Touch, kind: solid.Kind, id: u32, came: f32) void {
    for (now) |*t| {
        if (t.live and t.kind == kind and t.id == id) {
            t.came = @max(t.came, came);
            return;
        }
    }
    for (now) |*t| {
        if (!t.live) {
            t.* = .{ .kind = kind, .id = id, .came = came, .live = true };
            return;
        }
    }
}

/// What each kind of solid thing does when Hum comes against it: the one table of it.
fn touched(w: *World, t: Touch) void {
    const at_hum = world_mod.Place{ .x = w.hum_x, .y = 0.5, .z = w.hum_z };
    const hard = std.math.clamp((t.came - world_mod.bump_least) / (world_mod.run_speed - world_mod.bump_least), 0.0, 1.0);
    const firmly = t.came > world_mod.bump_least;
    switch (t.kind) {
        // a stalk brushed rings its bells
        .tower => if (firmly) w.brushStalk(@intCast(t.id), t.came),
        // a reed is a pipe, and sounds
        .reed => if (firmly) w.touch(w.reed_first + t.id, t.came, at_hum),
        .fallen => if (firmly and w.fallen < w.thing_count) w.touch(w.fallen, t.came, at_hum),
        .spigot => if (firmly and w.spigot_thing != world_mod.no_thing) w.touch(w.spigot_thing, t.came, at_hum),
        // run into, the hose sounds in its own voice, where it was touched
        .hose => if (firmly and w.hose_thing != world_mod.no_thing) {
            const p = hose.nearest(w.hum_x, w.hum_z).p;
            w.touch(w.hose_thing, t.came, .{ .x = p[0], .y = hose.reach, .z = p[1] });
        },
        // a clover's roof trembles above, a drum skin, heard late by its height
        .clover => if (firmly) {
            const tall = covers.cloverTall(t.id);
            w.tell(.{ .at = .{ .x = w.hum_x, .y = tall, .z = w.hum_z } }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = world_mod.garden_hz * 2.0 * ground.five[t.id % 5], .strength = 0.03 + 0.07 * hard, .ring = 0.3 }, .glow));
        },
        // a crumb knocks, dull
        .crumb => if (firmly) w.tell(.{ .at = at_hum }, cues_mod.Cue.of(.{ .kind = .strike, .family = .skin, .hz = world_mod.garden_hz * 0.5 * ground.five[t.id % 5], .strength = 0.04 + 0.08 * hard, .ring = 0.06 }, .glow)),
        // Drip, before the two have met, sounds its own note softly
        .drip => if (t.came > 0.3 and w.drip < w.thing_count) w.tell(.{ .thing = w.drip }, cues_mod.Cue.of(.{ .kind = .strike, .family = .fork, .hz = w.dripHz(), .strength = 0.05, .ring = 0.2 }, .glow)),
        .moss, .leaf, .other => {},
    }
}

/// What is under Hum's feet and over its head where it stands, among what is solid: whole heights.
pub const Stand = struct {
    /// The highest thing there to stand on that is no more than a step above its feet; the ground
    /// if there is nothing.
    floor: f32,
    /// The lowest underside over its head; very high if there is nothing.
    roof: f32,
};

pub const no_roof: f32 = 1.0e9;

/// `feet` is how high Hum's feet were before this step's rise or fall.
pub fn under(w: *const World, feet: f32) Stand {
    var near: Near = undefined;
    gather(w, w.hum_x, w.hum_z, &near);
    var out = Stand{ .floor = w.groundAt(w.hum_x, w.hum_z), .roof = no_roof };
    const head = feet + world_mod.hum_tall;
    for (near.slice()) |s| {
        if (solid.top(s, w.hum_x, w.hum_z)) |top| {
            if (top <= feet + world_mod.step_up and top > out.floor) out.floor = top;
        }
        if (solid.underside(s, w.hum_x, w.hum_z)) |low| {
            if (low >= head - 0.05 and low < out.roof) out.roof = low;
        }
    }
    return out;
}
