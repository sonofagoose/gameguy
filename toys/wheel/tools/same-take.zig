//! Does one take play out the same on the laptop and on the handheld?
//!
//! "A take is only its inputs" (design/thirteenth-morning.md, section 15) holds only if the same
//! inputs make the same world and the same sound on every machine that replays them. This runs the
//! wheel toy's rules and synth (no picture, no SDL) for twenty minutes of play at a fixed 60 steps
//! a second, with the scripted player plus a seeded scatter of extra calls, dodges and walks, and
//! prints a fingerprint of the world and of the sound after every minute. Build it for both
//! machines and compare the lines.
//!
//!   ZIG=.tools/zig/zig; cd toys/wheel
//!   $ZIG build-exe -O ReleaseSafe --dep rules -Mroot=tools/same-take.zig -Mrules=src/rules.zig \
//!       -lc -lm -femit-bin=build/same-take-x86_64 --cache-dir build/cache
//!   $ZIG build-exe -O ReleaseSafe -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35 --dep rules \
//!       -Mroot=tools/same-take.zig -Mrules=src/rules.zig -lc -lm \
//!       -femit-bin=build/same-take-aarch64 --cache-dir build/cache
//!
//! Both builds link the C library's maths as the toys do, so a difference in sin or exp between
//! the two machines' libraries shows up here.
//!
//! Each line also gives the loudest sample so far, so a silent synth can't pass for a matching
//! one. The first version (2026-11-17, morning) never built the synth's wavetables, and the two
//! machines matched on twenty minutes of silence.
const std = @import("std");
const rules = @import("rules");
const world_mod = rules.world;
const music = rules.music;
const synth = rules.synth;
const World = world_mod.World;

const steps_per_second = 60;
const minutes = 20;

/// The scripted player from the wheel toy's main.zig, unchanged.
const Bot = struct {
    r1_frames: u32 = 0,
    aim_x: f32 = 0.0,
    aim_y: f32 = 0.0,
    wait: u32 = 0,
    struck_for: i64 = -100,
    stepped_at: f64 = -100.0,

    fn point(self: *Bot, note: music.Note) void {
        const a = @as(f32, @floatFromInt(music.noteWedge(note))) * std.math.pi / 6.0;
        self.aim_x = @sin(a);
        self.aim_y = -@cos(a);
        self.r1_frames = 40;
        self.wait = 70;
    }

    fn walkTo(w: *const World, in: *world_mod.Input, x: f32, y: f32, near: f32) bool {
        const dx = x - w.x;
        const dy = y - w.y;
        const d = @sqrt(dx * dx + dy * dy);
        if (d <= near) return true;
        in.move_x = dx / d;
        in.move_y = dy / d;
        return false;
    }

    fn strikeOn(self: *Bot, w: *const World, in: *world_mod.Input, target: *const world_mod.Creature) void {
        const frac = w.beat - @floor(w.beat);
        const next: i64 = @as(i64, @intFromFloat(@floor(w.beat))) + 1;
        if (frac > 0.72 and frac < 0.93 and self.struck_for != next and w.meets(target, next)) {
            in.strike = true;
            self.struck_for = next;
        }
    }

    fn play(self: *Bot, w: *const World, frame: u32) world_mod.Input {
        var in = world_mod.Input{};
        if (self.r1_frames > 0) {
            self.r1_frames -= 1;
            in.r1 = true;
            in.aim_x = self.aim_x;
            in.aim_y = self.aim_y;
            return in;
        }
        if (self.wait > 0) self.wait -= 1;
        const in_bar = @mod(w.beat, 4.0);
        const frac = w.beat - @floor(w.beat);

        switch (w.stage) {
            .dark_call => in.r1 = (frame >= 90 and frame < 94) or (frame >= 240 and frame < 244),
            .dark_find => _ = walkTo(w, &in, world_mod.drip_x - 34.0, world_mod.drip_y + 62.0, 8.0),
            .phase => in.r2 = frac > 0.3,
            .dawn, .waking => {},
            .knots, .run, .garden => {
                var a: ?*const world_mod.Creature = null;
                var others: usize = 0;
                var grey: ?*const world_mod.Creature = null;
                var nearest: ?*const world_mod.Creature = null;
                var best: f32 = 1e12;
                for (&w.creatures) |*cr| {
                    if (!cr.live()) continue;
                    if (cr.state == .grey) {
                        grey = cr;
                        continue;
                    }
                    if (!cr.knot and cr.note == 3) a = cr;
                    if (!cr.knot and (cr.note == 2 or cr.note == 1)) others += 1;
                    const dx = cr.x - w.x;
                    const dy = cr.y - w.y;
                    if (dx * dx + dy * dy < best) {
                        best = dx * dx + dy * dy;
                        nearest = cr;
                    }
                }
                if (w.stage == .run and w.swell and w.walk < 2 and (w.home == 2 or w.home == 1)) {
                    in.r2 = true;
                    if (in_bar > 3.95 or in_bar < 0.04) {
                        in.aim_x = -1.0;
                        self.stepped_at = w.beat;
                    }
                    return in;
                }
                if (w.swell) {
                    in.r2 = !(in_bar < 0.5 and w.swell_beats > 0.8 and w.beat - self.stepped_at > 2.0);
                    return in;
                }
                if (grey) |g| {
                    var want: music.Note = if (g.knot) World.meetingPlace(g) else music.fold(g.note - 1);
                    if (!w.isAwake(want)) want = music.fold(g.note + 1);
                    if (w.home != want) {
                        if (self.wait == 0 and w.pending == null) self.point(want);
                        return in;
                    }
                    _ = walkTo(w, &in, g.x, g.y, 120.0);
                    in.r2 = in_bar >= 3.0;
                    return in;
                }
                const target = (if (w.stage == .run and others == 2) a else null) orelse nearest orelse return in;
                const want: music.Note = if (target.knot) World.meetingPlace(target) else if (w.stage == .run and others == 2 and a != null) 2 else target.note;
                if (w.home != want) {
                    if (self.wait == 0 and w.pending == null) self.point(want);
                    return in;
                }
                if (walkTo(w, &in, target.x, target.y, 52.0)) self.strikeOn(w, &in, target);
            },
        }
        return in;
    }
};

/// A seeded scatter of human-looking extras on top of the script, the same on every machine.
const Scatter = struct {
    state: u64 = 0x9E3779B97F4A7C15,
    doing: enum { nothing, wander, call, dodge } = .nothing,
    left: u32 = 0,
    angle: f32 = 0.0,

    fn next(self: *Scatter) u32 {
        self.state ^= self.state << 13;
        self.state ^= self.state >> 7;
        self.state ^= self.state << 17;
        return @truncate(self.state >> 32);
    }

    fn apply(self: *Scatter, in: *world_mod.Input) void {
        if (self.left == 0) {
            const roll = self.next() % 1000;
            self.doing = if (roll < 6) .wander else if (roll < 9) .call else if (roll < 13) .dodge else .nothing;
            self.left = switch (self.doing) {
                .nothing => 1,
                .wander => 20 + self.next() % 90,
                .call => 5,
                .dodge => 1,
            };
            self.angle = @as(f32, @floatFromInt(self.next() % 6283)) / 1000.0;
        }
        self.left -= 1;
        switch (self.doing) {
            .nothing => {},
            .wander => {
                in.move_x = @cos(self.angle);
                in.move_y = @sin(self.angle);
                self.angle += 0.02;
            },
            .call => if (!in.r2) {
                in.r1 = true;
            },
            .dodge => in.dodge = true,
        }
    }
};

const Fingerprint = struct {
    world: std.hash.Fnv1a_64 = std.hash.Fnv1a_64.init(),
    sound: std.hash.Fnv1a_64 = std.hash.Fnv1a_64.init(),

    fn add(h: *std.hash.Fnv1a_64, value: anytype) void {
        h.update(std.mem.asBytes(&value));
    }

    fn takeWorld(self: *Fingerprint, w: *const World) void {
        const h = &self.world;
        add(h, w.time);
        add(h, w.beat);
        add(h, w.x);
        add(h, w.y);
        add(h, w.steady);
        add(h, w.breath);
        add(h, w.light);
        add(h, w.home);
        add(h, @as(u8, @intFromEnum(w.stage)));
        add(h, w.best_walk);
        for (w.creatures) |c| {
            add(h, @as(u8, @intFromEnum(c.state)));
            add(h, c.x);
            add(h, c.y);
            add(h, c.vx);
            add(h, c.vy);
            add(h, c.colour);
            add(h, c.timer);
        }
    }
};

pub fn main() void {
    var shared: synth.Shared = .{};
    var engine: synth.Engine = .{};
    engine.init(); // builds the wavetables, as the toy's main.zig does
    var world = World.init(&shared);
    var bot = Bot{};
    var scatter = Scatter{};
    var print = Fingerprint{};
    var events: [64]world_mod.Event = undefined;
    var event_total: u64 = 0;
    var scratch: [1024]f32 = undefined;
    var loudest: f32 = 0.0;

    const dt: f32 = 1.0 / @as(f32, steps_per_second);
    const total: u32 = steps_per_second * 60 * minutes;
    var frame: u32 = 0;
    while (frame < total) : (frame += 1) {
        var in = bot.play(&world, frame);
        if (world.stage == .garden or world.stage == .run) scatter.apply(&in);
        world.step(in, dt, shared.beat());

        const n_events = world.drainEvents(&events);
        for (events[0..n_events]) |e| {
            Fingerprint.add(&print.world, @as(u8, @intFromEnum(e.kind)));
            Fingerprint.add(&print.world, e.time);
            Fingerprint.add(&print.world, e.a);
            Fingerprint.add(&print.world, e.b);
        }
        event_total += n_events;
        print.takeWorld(&world);

        var left: usize = @intFromFloat(@round(dt * synth.sample_rate));
        while (left > 0) {
            const n = @min(left, scratch.len);
            engine.render(&shared, scratch[0..n], n, 1);
            print.sound.update(std.mem.sliceAsBytes(scratch[0..n]));
            for (scratch[0..n]) |x| loudest = @max(loudest, @abs(x));
            left -= n;
        }

        if ((frame + 1) % (steps_per_second * 60) == 0) {
            std.debug.print("minute {d:>2}: world {x:0>16}  sound {x:0>16}  scene {s}, {d} events, best walk {d}, loudest {d:.3}\n", .{
                (frame + 1) / (steps_per_second * 60),
                print.world.final(),
                print.sound.final(),
                @tagName(world.stage),
                event_total,
                world.best_walk,
                loudest,
            });
        }
    }
}
