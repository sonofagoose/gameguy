//! The toy's world and its rules: Hum, Drip, the knots, the wheel, the swell and the walk home.
//! No platform code. It reads musical time from the synth's clock and asks the synth for sound.
//!
//! Everything about how it feels is in `Feel`.
const std = @import("std");
const music = @import("music.zig");
const synth = @import("synth.zig");
const Note = music.Note;

pub const Feel = struct {
    /// Beats a minute at full speed.
    bpm: f32 = 96.0,
    /// The day's own note, and Hum's: middle C.
    day_hz: f64 = 261.6256,
    /// How fast time runs while the wheel is held open, and in the pocket.
    thick: f32 = 0.25,
    pocket: f32 = 0.4,
    /// R1 held this long (seconds) opens the wheel; let go sooner and it is a call.
    wheel_delay: f32 = 0.17,
    /// How far the stick must be pushed to point at a wedge, or to nudge.
    point: f32 = 0.55,
    nudge: f32 = 0.6,
    rearm: f32 = 0.3,
    /// Seconds either side of the one in which a release or a nudge counts as on it.
    one_window: f32 = 0.11,
    one_window_gentle: f32 = 0.17,
    /// Seconds either side of a beat in which a strike is one you timed yourself.
    true_window: f32 = 0.05,
    /// Seconds either side of Drip's tick that count as together.
    tick_window: f32 = 0.12,
    /// Pixels per beat.
    hum_speed: f32 = 75.0,
    creature_speed: f32 = 46.0,
    lunge_speed: f32 = 380.0,
    dodge_speed: f32 = 330.0,
    /// How near a creature must be for the fork to ring it.
    reach: f32 = 88.0,
    /// Clean strikes on a meeting that drain a creature to grey.
    hits_to_grey: f32 = 2.0,
    /// Beats a grey creature waits before its colour starts to come back.
    grey_beats: f32 = 40.0,
    /// How many homes a breath holds at first.
    breath: f32 = 3.0,
};

pub const Stage = enum {
    /// Black. Call.
    dark_call,
    /// Something answered. Walk to it.
    dark_find,
    /// Beside Drip: breathe with it.
    phase,
    /// "Oh. You're in." The light comes up.
    dawn,
    /// Three small knots; stand where they meet.
    knots,
    /// Water runs; three more wedges wake.
    waking,
    /// Three creatures on a run of fifths: home the long way.
    run,
    /// Packs, for as long as you like.
    garden,
};

pub const Input = struct {
    move_x: f32 = 0.0,
    move_y: f32 = 0.0,
    aim_x: f32 = 0.0,
    aim_y: f32 = 0.0,
    r1: bool = false,
    r2: bool = false,
    strike: bool = false,
    dodge: bool = false,
    gentle: bool = false,
    skip: bool = false,
};

pub const max_creatures = 16;

pub const CreatureState = enum {
    none,
    roam,
    /// Rearing: it lunges on the next beat.
    windup,
    lunge,
    recover,
    /// Drained: it leans, and waits to be brought home.
    grey,
    /// Coming home.
    homing,
    /// A knot sprung open into a loop.
    open,
    /// Sung to sleep.
    asleep,
    /// Came home with a ring: it keeps you company and drums.
    follow,
};

pub const Creature = struct {
    state: CreatureState = .none,
    /// Knots have two strands, each with its own note; `other` is the second.
    knot: bool = false,
    note: Note = 0,
    other: Note = 0,
    x: f32 = 0.0,
    y: f32 = 0.0,
    vx: f32 = 0.0,
    vy: f32 = 0.0,
    /// 1 full colour, 0 grey.
    colour: f32 = 1.0,
    id: u8 = 0,
    /// Beats left in the current state, where it has a length.
    timer: f32 = 0.0,
    /// The beat it will lunge on.
    lunge_beat: i64 = 0,
    cooldown: f32 = 0.0,
    orbit: f32 = 0.0,
    /// Where each strand is in its own pulse, 0 to 1.
    pulse: f32 = 0.0,
    pulse2: f32 = 0.0,
    /// Fades after a hit, a call, or a meeting.
    flash: f32 = 0.0,
    meet_flash: f32 = 0.0,
    /// Beats for which its point stays on the wheel after it has rung.
    rung: f32 = 0.0,
    spin: f32 = 0.0,
    hit_hum: bool = false,

    pub fn live(self: *const Creature) bool {
        return switch (self.state) {
            .roam, .windup, .lunge, .recover, .grey => true,
            else => false,
        };
    }
};

pub const Ring = struct {
    alive: bool = false,
    x: f32 = 0.0,
    y: f32 = 0.0,
    r: f32 = 0.0,
    /// 1 fresh, 0 gone.
    life: f32 = 0.0,
    color: [3]f32 = .{ 0.89, 0.84, 0.78 },
    speed: f32 = 330.0,
    reach: f32 = 760.0,
    /// A call from Hum wakes what it touches; other rings are only light.
    call: bool = false,
};

pub const Spark = struct {
    life: f32 = 0.0,
    x: f32 = 0.0,
    y: f32 = 0.0,
    vx: f32 = 0.0,
    vy: f32 = 0.0,
    color: [3]f32 = .{ 1.0, 1.0, 1.0 },
};

pub const EventKind = enum { stage, call, in_phase, wheel, home, strike, lash, pocket, grey, close, amen, plain, soft, step, walk, breath, gentle, dusk };

pub const Event = struct {
    kind: EventKind,
    time: f32,
    a: i32 = 0,
    b: f32 = 0.0,
};

/// Things in the garden that a call lights up in the dark.
pub const Thing = struct {
    kind: enum { reed, aster, spigot, pool, hose },
    x: f32,
    y: f32,
    size: f32 = 1.0,
};

pub const things = [_]Thing{
    .{ .kind = .reed, .x = -60, .y = -30 },   .{ .kind = .reed, .x = 48, .y = 34, .size = 1.2 },
    .{ .kind = .reed, .x = -20, .y = 70 },    .{ .kind = .reed, .x = 110, .y = -62, .size = 0.9 },
    .{ .kind = .reed, .x = -130, .y = 40 },   .{ .kind = .reed, .x = 180, .y = 30, .size = 1.1 },
    .{ .kind = .reed, .x = 60, .y = -150 },   .{ .kind = .reed, .x = -90, .y = -140, .size = 1.3 },
    .{ .kind = .reed, .x = 240, .y = -210 },  .{ .kind = .reed, .x = 330, .y = -60, .size = 0.8 },
    .{ .kind = .reed, .x = 470, .y = -180 },  .{ .kind = .reed, .x = 380, .y = -330, .size = 1.2 },
    .{ .kind = .aster, .x = 150, .y = -330, .size = 1.5 }, .{ .kind = .aster, .x = 560, .y = -120, .size = 1.2 },
    .{ .kind = .aster, .x = 300, .y = 90, .size = 1.7 },   .{ .kind = .aster, .x = 620, .y = -420, .size = 1.4 },
    .{ .kind = .aster, .x = 40, .y = -420 },               .{ .kind = .aster, .x = 500, .y = 60, .size = 1.3 },
    .{ .kind = .aster, .x = -80, .y = -290, .size = 1.2 }, .{ .kind = .aster, .x = 700, .y = -250, .size = 1.6 },
    .{ .kind = .pool, .x = 420, .y = -40, .size = 1.0 },
    .{ .kind = .spigot, .x = drip_x, .y = drip_y - 26 },
    .{ .kind = .hose, .x = knot_x, .y = knot_y },
};

/// The hose, from the spigot to the knot.
pub const hose = [_][2]f32{
    .{ 430, -312 }, .{ 418, -280 }, .{ 380, -262 }, .{ 348, -276 }, .{ 322, -250 },
    .{ 338, -214 }, .{ 372, -196 }, .{ 368, -160 }, .{ 334, -150 }, .{ 306, -168 },
    .{ 286, -146 }, .{ 300, -118 },
};

pub const drip_x: f32 = 430.0;
pub const drip_y: f32 = -300.0;
pub const knot_x: f32 = 300.0;
pub const knot_y: f32 = -112.0;

/// Drip's note: the wedge on the left, teal. It is also the note under the first knots.
pub const drip_note: Note = -1;

// which drone is which
const d_hum = 0;
const d_pad = 1; // 1, 2, 3: the chord; 4: its bass
const d_bass = 4;
const d_swell = 6; // 6..10
const d_drip = 11;
const d_third = 12;
const d_ache = 13; // 13..16

pub const World = struct {
    feel: Feel = .{},
    sound: *synth.Shared,
    stage: Stage = .dark_call,
    /// Seconds of real time, and musical time in beats.
    time: f32 = 0.0,
    beat: f64 = 0.0,
    stage_beat: f64 = 0.0,
    gentle: bool = false,
    rng: u32 = 0x2545F491,

    // Hum
    x: f32 = 0.0,
    y: f32 = 0.0,
    face_x: f32 = 0.0,
    face_y: f32 = -1.0,
    still_beats: f32 = 0.0,
    /// 1 steady, 0 shaken apart.
    steady: f32 = 1.0,
    invuln: f32 = 0.0,
    dodge: f32 = 0.0,
    dodge_x: f32 = 0.0,
    dodge_y: f32 = 0.0,
    hurt: f32 = 0.0,

    // home and the wheel
    home: Note = 0,
    /// Chosen on the wheel, taken up on the next beat.
    pending: ?Note = null,
    awake: [7]bool = .{ true, true, false, false, false, false, false },
    r1_held: f32 = -1.0,
    wheel_open: bool = false,
    /// 0 shut, 1 open: for drawing.
    wheel_show: f32 = 0.0,
    hover: ?Note = null,
    wheel_opens: u32 = 0,
    home_flash: f32 = 0.0,

    // the fork
    strike_beat: f64 = -1.0,
    strike_true: bool = false,
    strike_anim: f32 = 0.0,
    strike_count: u32 = 0,
    hitstop: f32 = 0.0,
    pocket: f32 = 0.0,
    pocket_hits: u8 = 0,

    // the swell
    swell: bool = false,
    swell_beats: f32 = 0.0,
    swell_root: Note = 0,
    swell_leaner: bool = false,
    nudge_armed: bool = true,
    nudged: bool = false,
    walk: u8 = 0,
    best_walk: u8 = 0,
    breath: f32 = 3.0,
    breath_cap: f32 = 3.0,
    r2_was: bool = false,
    /// A ring of light on Hum when a close lands.
    landed: f32 = 0.0,

    // Drip
    drip_riding: bool = false,
    drip_seen: f32 = 0.0,
    drip_hop: f32 = 0.0,
    together: u8 = 0,
    /// How far out of step the last breath was, seconds; shown as the figure's turning.
    flam: f32 = 0.3,
    lean_in: f32 = 0.0,
    calls: u32 = 0,
    answer_at: f64 = -1.0,

    /// 0 black, 1 morning.
    light: f32 = 0.0,
    water: f32 = 0.0,
    wake_step: u8 = 0,
    pack: u8 = 0,
    rest: f32 = 0.0,

    creatures: [max_creatures]Creature = @splat(.{}),
    rings: [10]Ring = @splat(.{}),
    sparks: [48]Spark = @splat(.{}),
    lit: [things.len]f32 = @splat(0.0),

    prompt: []const u8 = "",
    prompt_show: f32 = 0.0,
    said: []const u8 = "",
    said_left: f32 = 0.0,
    taught: packed struct { wheel: bool = false, strike: bool = false, hold: bool = false, nudge: bool = false } = .{},
    idle: f32 = 0.0,

    events: [64]Event = undefined,
    event_count: usize = 0,

    pub fn init(sound: *synth.Shared) World {
        var w = World{ .sound = sound };
        sound.bps = w.feel.bpm / 60.0;
        sound.table[d_hum] = .hum;
        for (d_pad..d_bass + 1) |d| {
            sound.table[d] = .pad;
            sound.sinks[d] = true;
        }
        for (d_swell..d_swell + 5) |d| {
            sound.table[d] = .pad;
            sound.sinks[d] = true;
        }
        sound.table[d_drip] = .soft;
        sound.table[d_third] = .pad;
        for (d_ache..d_ache + 4) |d| sound.table[d] = .reed;
        w.breath = w.feel.breath;
        w.breath_cap = w.feel.breath;
        return w;
    }

    // ------------------------------------------------------------ small helpers

    fn note_event(self: *World, kind: EventKind, a: i32, b: f32) void {
        if (self.event_count < self.events.len) {
            self.events[self.event_count] = .{ .kind = kind, .time = self.time, .a = a, .b = b };
            self.event_count += 1;
        }
    }

    pub fn drainEvents(self: *World, out: []Event) usize {
        const n = @min(out.len, self.event_count);
        @memcpy(out[0..n], self.events[0..n]);
        self.event_count = 0;
        return n;
    }

    fn random(self: *World) f32 {
        self.rng = self.rng *% 1664525 +% 1013904223;
        return @as(f32, @floatFromInt(self.rng >> 8)) / 16777216.0;
    }

    fn bps(self: *const World) f32 {
        return self.feel.bpm / 60.0;
    }

    /// Seconds (at full speed) from now to the nearest beat that starts a bar; negative if it
    /// has just passed.
    pub fn toTheOne(self: *const World) f32 {
        const in_bar = @mod(self.beat, 4.0);
        const beats = if (in_bar > 2.0) 4.0 - in_bar else -in_bar;
        return @floatCast(beats / self.bps());
    }

    fn toBeat(self: *const World) f32 {
        const frac = self.beat - @floor(self.beat);
        const beats = if (frac > 0.5) 1.0 - frac else -frac;
        return @floatCast(beats / self.bps());
    }

    fn oneWindow(self: *const World) f32 {
        return if (self.gentle) self.feel.one_window_gentle else self.feel.one_window;
    }

    pub fn noteHz(self: *const World, note: Note, floor: f64) f32 {
        return @floatCast(music.hz(self.feel.day_hz, self.home, note, floor));
    }

    fn homeHz(self: *const World, home: Note, floor: f64) f32 {
        return @floatCast(music.into(self.feel.day_hz * music.degree(home), floor));
    }

    fn play(self: *World, shot: synth.Shot) void {
        self.sound.play(shot);
    }

    fn say(self: *World, text: []const u8, seconds: f32) void {
        self.said = text;
        self.said_left = seconds;
    }

    fn ring(self: *World, x: f32, y: f32, color: [3]f32, is_call: bool, reach: f32) void {
        for (&self.rings) |*r| {
            if (r.alive) continue;
            r.* = .{ .alive = true, .x = x, .y = y, .life = 1.0, .color = color, .call = is_call, .reach = reach };
            return;
        }
    }

    fn burst(self: *World, x: f32, y: f32, color: [3]f32, count: usize, speed: f32) void {
        var made: usize = 0;
        for (&self.sparks) |*s| {
            if (s.life > 0.0) continue;
            const a = self.random() * 2.0 * std.math.pi;
            const v = speed * (0.4 + 0.6 * self.random());
            s.* = .{ .life = 1.0, .x = x, .y = y, .vx = @cos(a) * v, .vy = @sin(a) * v, .color = color };
            made += 1;
            if (made == count) return;
        }
    }

    pub fn isAwake(self: *const World, note: Note) bool {
        const m = music.mood(note) orelse return false;
        return self.awake[@intFromEnum(m)];
    }

    /// The wedge a knot's two strands both point to.
    pub fn meetingPlace(c: *const Creature) Note {
        return music.generator(c.note, c.other) orelse c.note;
    }

    /// Does this creature's pulse meet yours on beat `b`?
    pub fn meets(self: *const World, c: *const Creature, b: i64) bool {
        if (c.knot) {
            if (self.home == meetingPlace(c)) return @mod(b, 4) == 0;
            const period: i64 = if (self.home == music.fold(c.note)) 3 else 5;
            return @mod(b + c.id, period) == 0;
        }
        return @mod(b, @as(i64, music.meetBeats(self.home, c.note))) == 0;
    }

    /// Would a close, with home where it is, bring this grey creature home (1), sing it to
    /// sleep (2), or neither (0)?
    pub fn door(self: *const World, c: *const Creature) u8 {
        if (c.knot) return if (self.home == meetingPlace(c)) 1 else 0;
        return switch (music.stepsFrom(self.home, c.note)) {
            1 => 1,
            -1 => 2,
            else => 0,
        };
    }

    fn spawn(self: *World, c: Creature) void {
        for (&self.creatures, 0..) |*slot, i| {
            if (slot.state != .none) continue;
            slot.* = c;
            slot.id = @intCast(i);
            slot.orbit = self.random() * 6.283;
            slot.cooldown = 4.0 + 2.0 * @as(f32, @floatFromInt(i % 3));
            return;
        }
    }

    fn liveCount(self: *const World) usize {
        var n: usize = 0;
        for (self.creatures) |c| {
            if (c.live()) n += 1;
        }
        return n;
    }

    fn setStage(self: *World, stage: Stage) void {
        self.stage = stage;
        self.stage_beat = self.beat;
        self.note_event(.stage, @intFromEnum(stage), 0.0);
    }

    // ------------------------------------------------------------ sound that is always on

    fn publishDrones(self: *World) void {
        const s = self.sound;
        const f = self.feel;
        // The chord under everything follows home; while the wheel is open it follows the
        // wedge being pointed at, so the ear hears a mood before the thumb commits to it.
        const heard = if (self.wheel_open) (self.hover orelse self.home) else self.home;
        const root = music.into(f.day_hz * music.degree(heard), 130.0);
        const tones = music.chordRatios(music.quality(heard));
        const level = 0.085 * self.light;
        for (0..3) |k| s.set(d_pad + k, @floatCast(music.into(root * tones[k], 196.0)), level);
        s.set(d_bass, @floatCast(music.into(root, 98.0)), level * 1.2);

        // Hum's one note: the day's own, whatever home is.
        const singing = self.swell or (self.stage == .phase and self.r2_was);
        s.set(d_hum, @floatCast(f.day_hz), if (singing) 0.20 else 0.0);
        @atomicStore(f32, &s.waver, (1.0 - self.steady) + self.hurt, .monotonic);

        // The swell: a chord that gathers on the note that leans (or on home), one more colour
        // each bar it is held.
        const r_note = self.swell_root;
        const base = music.hz(f.day_hz, self.home, r_note, 196.0);
        const leaning = self.swell_leaner and music.stepsFrom(self.home, r_note) == 1;
        const third: f64 = if (music.isLit(r_note) and music.quality(r_note) != .major) 6.0 / 5.0 else 5.0 / 4.0;
        const layers = [5]f64{ 1.0, 3.0 / 2.0, third, if (leaning) 7.0 / 4.0 else 9.0 / 8.0, 9.0 / 4.0 };
        for (layers, 0..) |r, k| {
            var g: f32 = 0.0;
            if (self.swell) {
                const start: f32 = if (k < 2) 0.0 else 4.0 * @as(f32, @floatFromInt(k - 1));
                g = std.math.clamp((self.swell_beats - start) / 3.0, 0.0, 1.0) * (0.045 + 0.006 * @min(self.swell_beats, 16.0));
            }
            s.set(d_swell + k, @floatCast(base * r), g);
        }

        // Drip, before it rides: a soft tone you walk toward. After: the note under you both.
        const dx = drip_x - self.x;
        const dy = drip_y - self.y;
        const far = @sqrt(dx * dx + dy * dy);
        var drip_gain: f32 = 0.0;
        if (!self.drip_riding and self.stage != .dark_call) drip_gain = 0.02 + 0.10 / (1.0 + far / 160.0);
        s.set(d_drip, @floatCast(f.day_hz * 2.0 / 3.0), drip_gain * (0.6 + 0.4 * self.drip_seen));
        s.set(d_third, @floatCast(f.day_hz / 3.0), if (self.drip_riding) 0.10 * (1.0 - self.light * 0.7) else 0.0);

        // Grey creatures ache: a hollow held note each, in tune with home.
        var slot: usize = 0;
        for (self.creatures) |c| {
            if (c.state != .grey or slot == 4) continue;
            const breathe = 0.6 + 0.4 * @sin(@as(f32, @floatCast(self.beat)) * 1.5 + @as(f32, @floatFromInt(c.id)));
            s.set(d_ache + slot, self.noteHz(c.note, 196.0), 0.035 * breathe);
            slot += 1;
        }
        while (slot < 4) : (slot += 1) s.setGain(d_ache + slot, 0.0);

        const pace: f32 = if (self.wheel_open) f.thick else if (self.pocket > 0.0) f.pocket else 1.0;
        @atomicStore(f32, &s.scale, pace, .monotonic);
        @atomicStore(f32, &s.sink, if (self.wheel_open) 0.5 else 1.0, .monotonic);
    }

    // ------------------------------------------------------------ on each beat

    fn onBeat(self: *World, b: i64) void {
        const one = @mod(b, 4) == 0;
        const next: f64 = @floatFromInt(b + 1);
        const next_one = @mod(b + 1, 4) == 0;

        // Drip keeps time: a tick on every beat, lower and louder on the one, and a quiet
        // off-beat that sits a little late. Asked for one beat ahead so it lands exactly.
        if (self.stage != .dark_call) {
            const near = self.drip_riding or self.stage == .phase;
            const g: f32 = if (near) 0.16 else 0.05 * self.drip_seen + 0.02;
            self.play(.{ .at_beat = next, .table = .tick, .hz = if (next_one) 880.0 else 1320.0, .gain = if (next_one) g * 1.5 else g, .decay = if (next_one) 0.05 else 0.025 });
            if (self.drip_riding) self.play(.{ .at_beat = next - 0.42, .table = .tick, .hz = 1760.0, .gain = 0.04, .decay = 0.015 });
            if (next_one and self.drip_riding) self.play(.{ .at_beat = next, .table = .soft, .hz = @floatCast(self.feel.day_hz / 3.0), .gain = 0.16, .decay = 0.16, .bend = 1.5 });
        }

        // Home chosen on the wheel is taken up here.
        if (self.pending) |p| {
            if (!self.wheel_open) {
                self.setHome(p, true);
                self.pending = null;
            }
        }

        // The ones that came home drum: one each, round the bar.
        var k: i64 = 0;
        for (self.creatures) |c| {
            if (c.state != .follow) continue;
            if (@mod(b + 1 + k, 2) == 0 or next_one) {
                self.play(.{ .at_beat = next, .table = .soft, .hz = 150.0 + 40.0 * @as(f32, @floatFromInt(@mod(k, 4))), .gain = if (next_one) 0.13 else 0.07, .decay = 0.07, .bend = 2.2 });
            }
            k += 1;
        }

        // Who rears up: at most one at a time, and only if the next beat is a meeting.
        var busy = false;
        for (self.creatures) |c| {
            if (c.state == .windup or c.state == .lunge) busy = true;
        }
        for (&self.creatures) |*c| {
            if (c.state == .windup and c.lunge_beat == b) {
                const dx = self.x - c.x;
                const dy = self.y - c.y;
                const d = @max(@sqrt(dx * dx + dy * dy), 1.0);
                c.state = .lunge;
                c.timer = 0.5;
                c.vx = dx / d * self.feel.lunge_speed;
                c.vy = dy / d * self.feel.lunge_speed;
                c.hit_hum = false;
                self.play(.{ .table = .reed, .hz = self.noteHz(c.note, 196.0), .gain = 0.16, .decay = 0.12, .bend = 1.4 });
                continue;
            }
            if (busy or c.state != .roam or c.cooldown > 0.0) continue;
            // What is near you on the wheel listens to the swell and holds still. What is far
            // from home does not.
            if (self.swell) {
                const near = if (c.knot) self.home == meetingPlace(c) else music.apart(self.home, c.note) <= 1;
                if (near) continue;
            }
            const dx = self.x - c.x;
            const dy = self.y - c.y;
            if (dx * dx + dy * dy > 190.0 * 190.0) continue;
            if (!self.meets(c, b + 1)) continue;
            c.state = .windup;
            c.lunge_beat = b + 1;
            busy = true;
        }

        if (one and self.swell) self.note_event(.breath, @intFromFloat(self.swell_beats), self.breath);
    }

    fn setHome(self: *World, home: Note, announce: bool) void {
        const was = self.home;
        self.home = music.fold(home);
        self.home_flash = 1.0;
        self.note_event(.home, self.home, @floatFromInt(was));
        if (!announce) return;
        // the new home says itself: its three notes, rising
        const root = self.homeHz(self.home, 261.0);
        const tones = music.chordRatios(music.quality(self.home));
        for (tones, 0..) |r, k| {
            self.play(.{ .at_beat = self.beat + 0.12 * @as(f64, @floatFromInt(k)), .table = .bell, .hz = root * @as(f32, @floatCast(r)), .gain = 0.13, .decay = 0.35 });
        }
    }

    // ------------------------------------------------------------ the fork

    fn askStrike(self: *World) void {
        if (self.strike_beat >= 0.0 or self.stage == .dark_call or self.stage == .dark_find or self.stage == .phase) return;
        self.strike_true = @abs(self.toBeat()) <= self.feel.true_window;
        // Hum turns to whatever is nearest and within reach, so a strike never rings empty air
        // beside a creature.
        var best: f32 = self.feel.reach * 1.25;
        for (self.creatures) |c| {
            if (!c.live()) continue;
            const dx = c.x - self.x;
            const dy = c.y - self.y;
            const d = @sqrt(dx * dx + dy * dy);
            if (d < best and d > 0.5) {
                best = d;
                self.face_x = dx / d;
                self.face_y = dy / d;
            }
        }
        if (self.pocket > 0.0) {
            self.strike_beat = self.beat; // in the pocket every strike lands at once
            return;
        }
        // The game places the strike on the beat's nearest half: now if that has just gone by,
        // or else the next one.
        const halves = self.beat * 2.0;
        const frac = halves - @floor(halves);
        self.strike_beat = if (frac < 0.3) self.beat else @ceil(halves) / 2.0;
    }

    fn landStrike(self: *World) void {
        const when = self.strike_beat;
        self.strike_beat = -1.0;
        self.strike_anim = 1.0;
        self.strike_count += 1;
        const in_pocket = self.pocket > 0.0;
        const halves: i64 = @intFromFloat(@round(when * 2.0));
        const on_beat = @mod(halves, 2) == 0;
        const b = @divFloor(halves, 2);

        // the fork's own note: home's chord, one note after another
        const tones = music.chordRatios(music.quality(self.home));
        const turn = if (in_pocket) self.pocket_hits else self.strike_count % 3;
        const fork = self.homeHz(self.home, 392.0) * @as(f32, @floatCast(tones[turn % 3]));
        self.play(.{ .table = .bell, .hz = fork, .gain = if (self.strike_true) 0.20 else 0.15, .decay = if (self.strike_true) 0.45 else 0.22 });
        if (self.strike_true) {
            // a strike you timed yourself rings fuller
            self.play(.{ .table = .bell, .hz = fork * 2.0, .gain = 0.09, .decay = 0.6 });
            self.play(.{ .table = .soft, .hz = fork * 3.0, .gain = 0.03, .decay = 0.8 });
        }

        var struck: i32 = 0;
        var met: i32 = 0;
        for (&self.creatures) |*c| {
            if (!c.live()) continue;
            const dx = c.x - self.x;
            const dy = c.y - self.y;
            const d = @sqrt(dx * dx + dy * dy);
            if (d > self.feel.reach) continue;
            // only what is in front: an arc a little wider than the one drawn
            if (d > 14.0 and (dx * self.face_x + dy * self.face_y) / d < 0.36) continue;
            struck += 1;
            c.flash = 1.0;
            c.rung = 8.0;
            const push: f32 = if (self.strike_true) 40.0 else 22.0;
            c.vx += dx / @max(d, 1.0) * push * 6.0;
            c.vy += dy / @max(d, 1.0) * push * 6.0;
            self.play(.{ .table = .bell, .hz = self.noteHz(c.note, 392.0), .gain = 0.14, .decay = 0.3 });
            if (c.knot) self.play(.{ .at_beat = self.beat + 0.08, .table = .bell, .hz = self.noteHz(c.other, 392.0), .gain = 0.10, .decay = 0.3 });
            if (c.state == .grey) continue;
            const meeting = in_pocket or (on_beat and self.meets(c, b));
            if (!meeting) continue;
            met += 1;
            c.meet_flash = 1.0;
            var drain = 1.0 / self.feel.hits_to_grey;
            if (self.strike_true or in_pocket) drain *= 2.0;
            if (in_pocket and self.pocket_hits < 2) drain = 0.34;
            c.colour = @max(0.0, c.colour - drain);
            if (c.state == .windup or c.state == .lunge) {
                c.state = .recover;
                c.timer = 2.0;
            }
            self.burst(c.x, c.y, music.hue(c.note), 6, 120.0);
            if (c.colour <= 0.001) self.turnGrey(c);
        }
        if (in_pocket) {
            self.pocket_hits += 1;
            if (self.pocket_hits >= 3) self.pocket = 0.0;
        }
        if (met > 0) {
            self.hitstop = 0.045; // the picture holds for two or three frames: a rest, in place of a rumble
            self.play(.{ .table = .soft, .hz = 110.0, .gain = 0.20, .decay = 0.08, .bend = 2.5 });
            if (!self.taught.hold and self.stage == .knots) self.taught.strike = true;
        }
        self.note_event(.strike, struck * 10 + met, if (self.strike_true) 1.0 else 0.0);
    }

    fn turnGrey(self: *World, c: *Creature) void {
        c.colour = 0.0;
        c.state = .grey;
        c.timer = self.feel.grey_beats;
        c.vx *= 0.3;
        c.vy *= 0.3;
        self.note_event(.grey, c.note, @floatFromInt(c.id));
        // it rings its own chord once, unresolved, as it goes
        const root = self.noteHz(c.note, 196.0);
        self.play(.{ .table = .reed, .hz = root, .gain = 0.12, .hold = 0.2, .decay = 0.5 });
        self.play(.{ .table = .reed, .hz = root * 1.5, .gain = 0.08, .hold = 0.2, .decay = 0.5 });
    }

    // ------------------------------------------------------------ the swell and the close

    fn beginSwell(self: *World) void {
        if (self.breath < 0.5) return;
        self.swell = true;
        self.swell_beats = 0.0;
        self.nudged = false;
        self.walk = 0;
        self.pickSwellRoot();
        // anything near on the wheel that was rearing up settles again and listens
        for (&self.creatures) |*c| {
            if (c.state != .windup) continue;
            const near = if (c.knot) self.home == meetingPlace(c) else music.apart(self.home, c.note) <= 1;
            if (near) {
                c.state = .roam;
                c.cooldown = 2.0;
            }
        }
    }

    /// The swell gathers on the nearest grey creature's note, if there is one.
    fn pickSwellRoot(self: *World) void {
        var best: f32 = 320.0 * 320.0;
        self.swell_root = self.home;
        self.swell_leaner = false;
        for (self.creatures) |c| {
            if (c.state != .grey) continue;
            const dx = c.x - self.x;
            const dy = c.y - self.y;
            const d2 = dx * dx + dy * dy;
            if (d2 < best) {
                best = d2;
                self.swell_root = if (c.knot) meetingPlace(&c) else c.note;
                self.swell_leaner = true;
            }
        }
    }

    fn bringHome(self: *World, c: *Creature, kind: u8, delay: f64) void {
        c.timer = 2.0;
        c.colour = 1.0;
        c.flash = 1.0;
        if (kind == 2) {
            c.state = .asleep;
            self.note_event(.amen, c.note, @floatFromInt(c.id));
            // the amen: two soft chords, the second one home
            const h = self.homeHz(self.home, 196.0);
            self.play(.{ .at_beat = self.beat + delay, .table = .pad, .hz = h * 4.0 / 3.0, .gain = 0.08, .attack = 0.05, .hold = 0.25, .decay = 0.3 });
            self.play(.{ .at_beat = self.beat + delay, .table = .pad, .hz = h * 5.0 / 3.0, .gain = 0.07, .attack = 0.05, .hold = 0.25, .decay = 0.3 });
            self.play(.{ .at_beat = self.beat + delay + 0.75, .table = .pad, .hz = h, .gain = 0.09, .attack = 0.05, .hold = 0.4, .decay = 0.6 });
            self.play(.{ .at_beat = self.beat + delay + 0.75, .table = .pad, .hz = h * 5.0 / 4.0, .gain = 0.07, .attack = 0.05, .hold = 0.4, .decay = 0.6 });
        } else {
            c.state = .homing;
            self.note_event(.close, c.note, @floatFromInt(c.id));
        }
        self.burst(c.x, c.y, music.hue(c.note), 10, 160.0);
        self.ring(c.x, c.y, music.hue(c.note), false, 150.0);
    }

    /// The chord that lands when something comes home: home's own, with one more colour for
    /// each step of the walk that led here, over a low note on the one.
    fn landChord(self: *World, colours: u8, loud: f32) void {
        const root = self.homeHz(self.home, 196.0);
        const q = music.quality(self.home);
        const tones = music.chordRatios(q);
        const seventh: f32 = if (q == .major) 15.0 / 8.0 else 9.0 / 5.0;
        const extra = [_]f32{ seventh, 9.0 / 4.0, 3.0, 5.0 / 2.0 };
        var n: usize = 0;
        for (tones) |r| {
            self.play(.{ .at_beat = self.beat + 0.09 * @as(f64, @floatFromInt(n)), .table = .bell, .hz = root * 2.0 * @as(f32, @floatCast(r)), .gain = 0.15 * loud, .decay = 0.9 });
            self.play(.{ .table = .pad, .hz = root * @as(f32, @floatCast(r)), .gain = 0.10 * loud, .attack = 0.03, .hold = 0.5, .decay = 0.9 });
            n += 1;
        }
        var k: usize = 0;
        while (k + 2 < colours and k < extra.len) : (k += 1) {
            self.play(.{ .at_beat = self.beat + 0.09 * @as(f64, @floatFromInt(n)), .table = .bell, .hz = root * 2.0 * extra[k], .gain = 0.11 * loud, .decay = 1.1 });
            self.play(.{ .table = .pad, .hz = root * extra[k], .gain = 0.06 * loud, .attack = 0.03, .hold = 0.5, .decay = 0.9 });
            n += 1;
        }
        self.play(.{ .table = .pad, .hz = self.homeHz(self.home, 98.0), .gain = 0.20 * loud, .attack = 0.01, .hold = 0.3, .decay = 0.7 });
        self.play(.{ .table = .soft, .hz = 80.0, .gain = 0.28 * loud, .decay = 0.14, .bend = 3.0 });
    }

    /// A nudge during a swell: home moves one wedge at once. On the one, whatever was leaning
    /// into the wedge you leave comes home in passing, and whatever shares that wedge's note
    /// goes grey and leans in turn.
    fn nudge(self: *World, dir: i32) void {
        const to = music.fold(self.home + dir);
        if (!self.isAwake(to)) {
            self.play(.{ .table = .soft, .hz = 90.0, .gain = 0.10, .decay = 0.05 });
            return;
        }
        const old = self.home;
        const on_one = @abs(self.toTheOne()) <= self.oneWindow();
        self.nudged = true;
        var carried: u8 = 0;
        if (on_one) {
            for (&self.creatures) |*c| {
                if (c.state != .grey or c.knot) continue;
                const steps = music.stepsFrom(old, c.note);
                if (dir < 0 and steps == 1) {
                    self.bringHome(c, 1, 0.0);
                    carried += 1;
                } else if (dir > 0 and steps == -1) {
                    self.bringHome(c, 2, 0.0);
                    carried += 1;
                }
            }
        }
        self.setHome(to, false);
        if (carried > 0) {
            self.walk += 1;
            // the wedge you left rings as you pass it, and its own creatures take up the lean
            const root = self.homeHz(old, 261.0);
            const tones = music.chordRatios(music.quality(old));
            for (tones, 0..) |r, k| {
                self.play(.{ .at_beat = self.beat + 0.07 * @as(f64, @floatFromInt(k)), .table = .bell, .hz = root * @as(f32, @floatCast(r)), .gain = 0.14, .decay = 0.4 });
            }
            self.play(.{ .table = .soft, .hz = 96.0, .gain = 0.18, .decay = 0.09, .bend = 2.5 });
            for (&self.creatures) |*c| {
                if (c.knot or !c.live() or c.state == .grey) continue;
                if (music.fold(c.note) == old) self.turnGrey(c);
            }
            self.swell_root = old;
            self.swell_leaner = true;
            self.landed = 0.6;
            self.note_event(.step, old, @floatFromInt(self.walk));
        } else {
            self.play(.{ .table = .tick, .hz = 990.0, .gain = 0.07, .decay = 0.03 });
            self.pickSwellRoot();
        }
    }

    fn release(self: *World, ran_out: bool) void {
        const off = self.toTheOne();
        const on_one = !ran_out and @abs(off) <= self.oneWindow();
        self.swell = false;
        var closed: u8 = 0;
        var slept: u8 = 0;
        var plain: u8 = 0;
        var nearest: ?*Creature = null;
        var best: f32 = 340.0 * 340.0;
        for (&self.creatures) |*c| {
            if (c.state != .grey) continue;
            const dx = c.x - self.x;
            const dy = c.y - self.y;
            const d2 = dx * dx + dy * dy;
            if (d2 > 340.0 * 340.0) continue;
            const fresh = self.feel.grey_beats - c.timer < 1.0;
            const kind: u8 = if (fresh) 0 else self.door(c);
            if (kind == 0) {
                plain += 1;
                if (fresh) continue;
                c.timer = self.feel.grey_beats; // calmer for a while
                continue;
            }
            if (on_one) {
                self.bringHome(c, kind, 0.0);
                if (kind == 1) closed += 1 else slept += 1;
            } else if (d2 < best) {
                best = d2;
                nearest = c;
            }
        }
        if (!on_one) {
            // off the one it still lands, plainer: only the nearest, and softly
            if (nearest) |c| {
                const kind = self.door(c);
                if (kind != 0) self.bringHome(c, kind, 0.0);
                self.landChord(0, 0.45);
                self.note_event(.soft, c.note, off);
            } else {
                self.play(.{ .table = .pad, .hz = self.homeHz(self.home, 196.0), .gain = 0.08, .attack = 0.03, .hold = 0.2, .decay = 0.5 });
                self.note_event(.plain, plain, off);
            }
            self.walk = 0;
            return;
        }
        if (closed + slept == 0 and self.walk == 0) {
            self.play(.{ .table = .pad, .hz = self.homeHz(self.home, 196.0), .gain = 0.10, .attack = 0.03, .hold = 0.3, .decay = 0.6 });
            self.note_event(.plain, plain, off);
            return;
        }
        if (closed + slept > 0) self.walk += 1;
        self.landed = 1.0;
        self.landChord(self.walk, 1.0);
        self.ring(self.x, self.y, music.hue(self.home), false, 420.0);
        self.note_event(.walk, self.walk, off);
        if (self.walk > self.best_walk) self.best_walk = self.walk;
        // the first time a walk fills the breath, the breath grows to hold one more
        if (@as(f32, @floatFromInt(self.walk)) >= self.breath_cap and self.breath_cap < 8.0) {
            self.breath_cap += 1.0;
            self.say(switch (@as(u8, @intFromFloat(self.breath_cap))) {
                4 => "A BREATH OF FOUR",
                5 => "A BREATH OF FIVE",
                6 => "A BREATH OF SIX",
                7 => "A BREATH OF SEVEN",
                else => "A BREATH OF EIGHT",
            }, 2.5);
        }
        self.walk = 0;
    }

    // ------------------------------------------------------------ one frame

    /// `dt` is real seconds since the last frame; `beat_now` is the synth's clock.
    pub fn step(self: *World, in: Input, dt: f32, beat_now: f64) void {
        self.time += dt;
        const was = self.beat;
        self.beat = @max(beat_now, was);
        var db: f32 = @floatCast(self.beat - was); // beats of musical time this frame
        if (self.hitstop > 0.0) {
            self.hitstop -= dt;
            db = 0.0;
        }

        if (in.gentle) {
            self.gentle = !self.gentle;
            self.say(if (self.gentle) "GENTLE" else "PLAIN", 1.5);
            self.note_event(.gentle, if (self.gentle) 1 else 0, 0.0);
        }
        if (in.skip) self.skipAhead();

        var b: i64 = @intFromFloat(@floor(was));
        const last: i64 = @intFromFloat(@floor(self.beat));
        while (b < last) {
            b += 1;
            self.onBeat(b);
        }

        self.stepHands(in, dt, db);
        self.stepHum(in, db);
        self.stepStage(in, dt, db);
        self.stepCreatures(db);
        self.stepLight(dt, db);
        self.publishDrones();
    }

    fn skipAhead(self: *World) void {
        switch (self.stage) {
            .dark_call, .dark_find, .phase => {
                self.x = drip_x - 40.0;
                self.y = drip_y + 50.0;
                self.together = 4;
                self.becomeIn();
            },
            .dawn => {},
            .knots => {
                for (&self.creatures) |*c| {
                    if (c.live()) c.state = .open;
                }
            },
            .waking => {},
            .run => {
                for (&self.creatures) |*c| {
                    if (c.live()) c.state = .follow;
                }
            },
            .garden => {},
        }
    }

    fn stepHands(self: *World, in: Input, dt: f32, db: f32) void {
        const f = self.feel;
        // R1: a tap is a call, a hold opens the wheel
        if (in.r1) {
            if (self.r1_held < 0.0) self.r1_held = 0.0;
            self.r1_held += dt;
            if (!self.wheel_open and self.r1_held >= f.wheel_delay and self.light > 0.5 and !self.swell) {
                self.wheel_open = true;
                self.wheel_opens += 1;
                self.hover = null;
                self.note_event(.wheel, 1, 0.0);
            }
        } else if (self.r1_held >= 0.0) {
            if (self.wheel_open) {
                self.wheel_open = false;
                if (self.hover) |h| {
                    if (h != self.home) self.pending = h;
                }
                self.note_event(.wheel, 0, self.r1_held);
            } else if (self.r1_held < 0.4) {
                self.call();
            }
            self.r1_held = -1.0;
        }
        if (self.wheel_open) {
            const m = @sqrt(in.aim_x * in.aim_x + in.aim_y * in.aim_y);
            if (m >= f.point) {
                // angle clockwise from twelve o'clock, to the nearest wedge
                var a = std.math.atan2(in.aim_x, -in.aim_y);
                if (a < 0.0) a += 2.0 * std.math.pi;
                const k: usize = @as(usize, @intFromFloat(@round(a / (std.math.pi / 6.0)))) % 12;
                const n = music.wedgeNote(k);
                if (self.isAwake(n)) self.hover = n;
            }
        }
        const target: f32 = if (self.wheel_open or self.swell) 1.0 else 0.0;
        self.wheel_show += (target - self.wheel_show) * @min(1.0, dt * 14.0);

        // R2: the swell (in the first scene it is only Hum's breath)
        const fighting = self.stage != .dark_call and self.stage != .dark_find and self.stage != .phase;
        if (fighting) {
            if (in.r2 and !self.r2_was and !self.wheel_open) self.beginSwell();
            if (self.swell) {
                self.swell_beats += db;
                self.breath -= db / 4.0;
                if (@abs(in.aim_x) < f.rearm) self.nudge_armed = true;
                if (self.nudge_armed and @abs(in.aim_x) >= f.nudge) {
                    self.nudge_armed = false;
                    self.nudge(if (in.aim_x < 0.0) -1 else 1);
                }
                // Gentle leans for you: after a bar with no steering, home drifts beside the
                // grey creature, on its amen side if that wedge is awake.
                if (self.gentle and !self.nudged and self.swell_beats >= 4.0 and self.swell_leaner) self.leanForMe();
                if (!in.r2) {
                    self.release(false);
                } else if (self.breath <= 0.0) {
                    self.release(true);
                }
            } else {
                self.breath = @min(self.breath_cap, self.breath + db / 2.0);
            }
        }
        if (!self.swell) self.swell_beats = 0.0;

        if (in.strike) self.askStrike();
        if (self.strike_beat >= 0.0 and self.beat >= self.strike_beat) self.landStrike();
        self.strike_anim = @max(0.0, self.strike_anim - dt * 5.0);

        if (in.dodge and self.dodge <= 0.0 and fighting) self.startDodge(in);
        if (self.pocket > 0.0) self.pocket = @max(0.0, self.pocket - dt);
        self.landed = @max(0.0, self.landed - dt * 1.2);
        self.home_flash = @max(0.0, self.home_flash - dt * 2.0);
        self.hurt = @max(0.0, self.hurt - dt * 0.8);
    }

    fn leanForMe(self: *World) void {
        for (self.creatures) |c| {
            if (c.state != .grey) continue;
            if (self.door(&c) != 0) return;
            const wanted: [2]Note = if (c.knot) .{ meetingPlace(&c), meetingPlace(&c) } else .{ music.fold(c.note + 1), music.fold(c.note - 1) };
            for (wanted) |h| {
                if (self.isAwake(h)) {
                    self.setHome(h, true);
                    self.nudged = true;
                    return;
                }
            }
        }
    }

    fn call(self: *World) void {
        self.calls += 1;
        self.ring(self.x, self.y, .{ 0.89, 0.84, 0.78 }, true, 760.0);
        self.play(.{ .table = .hum, .hz = @floatCast(self.feel.day_hz), .gain = 0.30, .attack = 0.03, .hold = 0.16, .decay = 0.12 });
        self.note_event(.call, @intCast(self.calls), 0.0);
        if (self.stage == .dark_call and self.calls >= 2) {
            self.answer_at = self.beat + 1.5;
            self.setStage(.dark_find);
        } else if (self.stage == .dark_find) {
            self.answer_at = self.beat + 1.0;
        }
    }

    fn startDodge(self: *World, in: Input) void {
        var dx = in.move_x;
        var dy = in.move_y;
        // which creature is about to land, if any
        var threat: ?*Creature = null;
        for (&self.creatures) |*c| {
            if (c.state == .windup or c.state == .lunge) threat = c;
        }
        if (dx * dx + dy * dy < 0.1) {
            if (threat) |c| {
                // step across its line
                dx = -(c.y - self.y);
                dy = c.x - self.x;
            } else {
                dx = -self.face_x;
                dy = -self.face_y;
            }
        }
        const m = @max(@sqrt(dx * dx + dy * dy), 0.001);
        self.dodge_x = dx / m;
        self.dodge_y = dy / m;
        self.dodge = 0.35;
        self.invuln = 0.7;
        self.play(.{ .table = .soft, .hz = 520.0, .gain = 0.06, .decay = 0.04, .bend = 0.6 });
        // On the beat a lunge lands on, the dodge opens the pocket: time thickens and the next
        // three strikes each count, and each is a note of one chord.
        if (threat) |c| {
            const lands: f64 = @floatFromInt(c.lunge_beat);
            const away: f32 = @floatCast(@abs(self.beat - lands) / self.bps());
            if (away <= self.oneWindow() * 1.2) {
                self.pocket = 1.5;
                self.pocket_hits = 0;
                self.note_event(.pocket, c.note, away);
                self.play(.{ .table = .pad, .hz = self.homeHz(self.home, 392.0), .gain = 0.08, .attack = 0.02, .hold = 0.3, .decay = 0.5 });
            }
        }
    }

    fn stepHum(self: *World, in: Input, db: f32) void {
        const m = @sqrt(in.move_x * in.move_x + in.move_y * in.move_y);
        var vx: f32 = 0.0;
        var vy: f32 = 0.0;
        if (m > 0.05) {
            const k = @min(m, 1.0) / m;
            vx = in.move_x * k * self.feel.hum_speed;
            vy = in.move_y * k * self.feel.hum_speed;
            self.face_x = in.move_x / m;
            self.face_y = in.move_y / m;
            self.still_beats = 0.0;
            self.idle = 0.0;
        } else {
            self.still_beats += db;
        }
        if (self.swell) {
            vx *= 0.5; // singing, it walks
            vy *= 0.5;
        }
        if (self.dodge > 0.0) {
            self.dodge -= db;
            vx = self.dodge_x * self.feel.dodge_speed;
            vy = self.dodge_y * self.feel.dodge_speed;
        }
        self.invuln = @max(0.0, self.invuln - db);
        self.x += vx * db;
        self.y += vy * db;
        self.x = std.math.clamp(self.x, -260.0, 820.0);
        self.y = std.math.clamp(self.y, -560.0, 220.0);
    }

    fn becomeIn(self: *World) void {
        self.drip_riding = true;
        self.drip_hop = 1.0;
        self.say("Oh. You're in.", 4.0);
        self.note_event(.in_phase, @intCast(self.calls), self.flam);
        // the note under you both blooms, and one bell for the two of you landing together
        const c = @as(f32, @floatCast(self.feel.day_hz));
        self.play(.{ .table = .bell, .hz = c, .gain = 0.14, .decay = 1.0 });
        self.play(.{ .table = .bell, .hz = c * 2.0 / 3.0, .gain = 0.14, .decay = 1.0 });
        self.play(.{ .table = .pad, .hz = c / 3.0, .gain = 0.16, .attack = 0.4, .hold = 1.2, .decay = 1.2 });
        self.ring(drip_x, drip_y, music.hue(drip_note), false, 500.0);
        self.setStage(.dawn);
    }

    fn stepStage(self: *World, in: Input, dt: f32, db: f32) void {
        const since: f32 = @floatCast(self.beat - self.stage_beat);
        self.idle += dt;
        self.said_left = @max(0.0, self.said_left - dt);
        self.drip_hop = @max(0.0, self.drip_hop - dt * 1.5);
        var want: []const u8 = "";

        // Drip answers a call, a beat and a half after it
        if (self.answer_at >= 0.0 and self.beat >= self.answer_at) {
            self.answer_at = -1.0;
            self.ring(drip_x, drip_y, music.hue(drip_note), false, 900.0);
            self.drip_seen = 1.0;
            const c = @as(f32, @floatCast(self.feel.day_hz));
            self.play(.{ .table = .soft, .hz = c * 2.0 / 3.0, .gain = 0.16, .attack = 0.05, .hold = 0.25, .decay = 0.25 });
        }
        self.drip_seen = @max(0.25, self.drip_seen - dt * 0.12);

        const ddx = drip_x - self.x;
        const ddy = drip_y - self.y;
        const to_drip = @sqrt(ddx * ddx + ddy * ddy);

        switch (self.stage) {
            .dark_call => {
                if (self.idle > 4.0) want = "R1";
            },
            .dark_find => {
                if (to_drip < 130.0 and self.still_beats > 1.5) self.setStage(.phase);
                if (to_drip < 130.0 and self.still_beats <= 1.5 and since > 8.0) want = "STAND STILL";
            },
            .phase => {
                self.lean_in += (1.0 - self.lean_in) * @min(1.0, dt * 3.0);
                want = "HOLD R2. LET GO ON A TICK";
                if (to_drip > 190.0) {
                    self.setStage(.dark_find);
                    self.together = 0;
                }
                // letting go beside a tick is one breath together
                if (self.r2_was and !in.r2) {
                    const off = self.toBeat();
                    self.flam = @abs(off);
                    if (@abs(off) <= self.feel.tick_window) {
                        self.together += 1;
                        self.play(.{ .table = .bell, .hz = @floatCast(self.feel.day_hz * 2.0), .gain = 0.05 + 0.02 * @as(f32, @floatFromInt(self.together)), .decay = 0.4 });
                    } else if (self.together > 0) {
                        self.together -= 1;
                    }
                    if (self.together >= 4) self.becomeIn();
                }
            },
            .dawn => {
                self.lean_in += (0.0 - self.lean_in) * @min(1.0, dt * 2.0);
                self.light = @min(1.0, self.light + db / 10.0);
                if (since > 12.0) {
                    // three small knots come off the big one
                    for (0..3) |k| {
                        const a = @as(f32, @floatFromInt(k)) * 2.1 + 0.4;
                        self.spawn(.{ .state = .roam, .knot = true, .note = 0, .other = 3, .x = knot_x + @cos(a) * 26.0, .y = knot_y + @sin(a) * 26.0 });
                    }
                    self.setStage(.knots);
                }
            },
            .knots => {
                self.light = @min(1.0, self.light + db / 10.0);
                var open: usize = 0;
                var grey = false;
                for (self.creatures) |c| {
                    if (c.state == .open) open += 1;
                    if (c.state == .grey) grey = true;
                }
                if (grey) self.taught.hold = true;
                if (self.wheel_opens == 0 and since > 6.0) {
                    want = "HOLD R1";
                } else if (self.wheel_open and self.home != drip_note) {
                    want = "POINT WHERE THEY MEET";
                } else if (grey) {
                    want = "HOLD R2. LET GO ON THE ONE";
                } else if (self.home == drip_note and open < 3) {
                    want = "STRIKE ON THE ONE";
                }
                if (open == 3) {
                    self.setStage(.waking);
                    self.wake_step = 0;
                    self.say("", 0.0);
                    // water
                    for (0..9) |k| {
                        const t = self.beat + 0.3 * @as(f64, @floatFromInt(k)) + 0.2 * @as(f64, self.random());
                        self.play(.{ .at_beat = t, .table = .soft, .hz = 700.0 + 900.0 * self.random(), .gain = 0.05, .decay = 0.05, .bend = 1.6 });
                    }
                }
            },
            .waking => {
                self.water = @min(1.0, self.water + db / 12.0);
                // three more wedges wake, one each bar, each saying its chord
                const due: u8 = @intFromFloat(@min(3.0, @floor(since / 4.0)));
                while (self.wake_step < due) : (self.wake_step += 1) {
                    const n: Note = @as(Note, self.wake_step) + 1; // drive, cool soul, tenderness
                    self.awake[@intCast(n + 1)] = true;
                    const root = self.homeHz(n, 261.0);
                    const tones = music.chordRatios(music.quality(n));
                    for (tones, 0..) |r, k| {
                        self.play(.{ .at_beat = self.beat + 0.14 * @as(f64, @floatFromInt(k)), .table = .bell, .hz = root * @as(f32, @floatCast(r)), .gain = 0.12, .decay = 0.6 });
                    }
                }
                if (since > 16.0) {
                    const from = [3][2]f32{ .{ 520, -40 }, .{ 110, -250 }, .{ 420, 110 } };
                    const notes = [3]Note{ 3, 2, 1 }; // orange, yellow, yellow-green: a run of fifths
                    for (notes, 0..) |n, k| self.spawn(.{ .state = .roam, .note = n, .x = from[k][0], .y = from[k][1] });
                    self.setStage(.run);
                }
            },
            .run => {
                self.water = @min(1.0, self.water + db / 12.0);
                var grey = false;
                var others = false;
                for (self.creatures) |c| {
                    if (c.knot) continue;
                    if (c.state == .grey) grey = true else if (c.live()) others = true;
                }
                if (grey and others and !self.taught.nudge) want = if (self.swell) "NUDGE LEFT ON THE ONE" else "HOLD R2";
                if (self.best_walk >= 2) self.taught.nudge = true;
                if (self.liveCount() == 0) {
                    self.awake = @splat(true);
                    self.rest = 8.0;
                    self.setStage(.garden);
                }
            },
            .garden => {
                if (self.liveCount() == 0) {
                    self.rest -= db;
                    if (self.rest <= 0.0) self.spawnPack();
                }
            },
        }
        self.r2_was = in.r2;

        if (!std.mem.eql(u8, want, self.prompt)) {
            self.prompt_show -= dt * 4.0;
            if (self.prompt_show <= 0.0) {
                self.prompt = want;
                self.prompt_show = 0.0;
            }
        } else if (want.len > 0) {
            self.prompt_show = @min(1.0, self.prompt_show + dt * 2.0);
        }
    }

    fn spawnPack(self: *World) void {
        self.pack += 1;
        const count: usize = @min(6, 3 + self.pack / 2);
        // old sleepers and followers beyond a few make room
        var followers: usize = 0;
        for (&self.creatures) |*c| {
            if (c.state == .asleep) c.state = .none;
            if (c.state == .follow) {
                followers += 1;
                if (followers > 5) c.state = .none;
            }
        }
        // a pack is a run of neighbouring wedges, so there is always a walk in it to find
        const start: Note = @as(Note, @intFromFloat(self.random() * 4.0));
        for (0..count) |k| {
            const n: Note = start + @as(Note, @intCast(k % 4)) - (if (self.random() < 0.25) @as(Note, 1) else 0);
            const a = self.random() * 6.283;
            self.spawn(.{ .state = .roam, .note = std.math.clamp(n, -1, 5), .x = self.x + @cos(a) * 330.0, .y = self.y + @sin(a) * 330.0 });
        }
        self.rest = 8.0;
    }

    fn stepCreatures(self: *World, db: f32) void {
        const f = self.feel;
        var follower: f32 = 0.0;
        for (&self.creatures) |*c| {
            if (c.state == .none) continue;
            c.flash = @max(0.0, c.flash - db * 1.5);
            c.meet_flash = @max(0.0, c.meet_flash - db * 1.2);
            c.rung = @max(0.0, c.rung - db);
            c.cooldown = @max(0.0, c.cooldown - db);

            // its own pulse: its interval to home, slowed down
            const p1 = music.pair(self.home, c.note);
            const rate1 = @as(f32, @floatFromInt(p1[0])) / @as(f32, @floatFromInt(p1[1]));
            c.pulse += db * rate1;
            if (c.pulse >= 1.0) {
                c.pulse -= @floor(c.pulse);
                if (c.live()) self.pulseSound(c, c.note);
            }
            if (c.knot) {
                const p2 = music.pair(self.home, c.other);
                c.pulse2 += db * @as(f32, @floatFromInt(p2[0])) / @as(f32, @floatFromInt(p2[1]));
                if (c.pulse2 >= 1.0) {
                    c.pulse2 -= @floor(c.pulse2);
                    if (c.live()) self.pulseSound(c, c.other);
                }
            }
            c.spin += db * 0.35;

            const dx = self.x - c.x;
            const dy = self.y - c.y;
            const d = @max(@sqrt(dx * dx + dy * dy), 0.001);
            switch (c.state) {
                .roam, .recover => {
                    if (c.state == .recover) {
                        c.timer -= db;
                        if (c.timer <= 0.0) {
                            c.state = .roam;
                            c.cooldown = 6.0 + 2.0 * @as(f32, @floatFromInt(c.id % 3));
                        }
                    }
                    // circle Hum at a little distance; knots lurch on their strands
                    c.orbit += db * (if (c.id % 2 == 0) @as(f32, 0.22) else -0.22);
                    // How near it keeps is what it is to you: what leans in comes close, kin
                    // stays beside you, and what is straight across keeps its distance.
                    const want_r: f32 = if (c.knot)
                        (if (self.home == meetingPlace(c)) @as(f32, 62.0) else 84.0)
                    else switch (music.relation(self.home, c.note)) {
                        .leans_in => 54.0,
                        .kin => 62.0,
                        .lean_to => 76.0,
                        .warm => 84.0,
                        .passing, .half_step => 110.0,
                        .far => 160.0,
                    };
                    const tx = self.x + @cos(c.orbit) * want_r;
                    const ty = self.y + @sin(c.orbit) * want_r;
                    var speed = f.creature_speed * (if (c.state == .recover) @as(f32, 0.4) else 1.0);
                    if (c.knot) speed *= 0.55 + 0.9 * (1.0 - c.pulse) * (1.0 - c.pulse);
                    const ex = tx - c.x;
                    const ey = ty - c.y;
                    const e = @max(@sqrt(ex * ex + ey * ey), 0.001);
                    const go = @min(speed, e * 2.0);
                    c.x += ex / e * go * db;
                    c.y += ey / e * go * db;
                },
                .windup => {
                    // it draws back, away from Hum, until its beat
                    c.x -= dx / d * 14.0 * db;
                    c.y -= dy / d * 14.0 * db;
                },
                .lunge => {
                    c.timer -= db;
                    c.x += c.vx * db;
                    c.y += c.vy * db;
                    if (!c.hit_hum and d < 24.0 and self.invuln <= 0.0) {
                        c.hit_hum = true;
                        self.lash(c);
                    }
                    if (c.timer <= 0.0) {
                        c.state = .recover;
                        c.timer = 2.0;
                        c.vx = 0.0;
                        c.vy = 0.0;
                    }
                },
                .grey => {
                    c.timer -= db;
                    if (c.timer <= 0.0) {
                        c.colour = 0.67;
                        c.state = .roam;
                        c.cooldown = 4.0;
                    }
                    // it drifts toward Hum a little and stays near
                    if (d > 90.0) {
                        c.x += dx / d * 12.0 * db;
                        c.y += dy / d * 12.0 * db;
                    }
                },
                .homing => {
                    c.timer -= db;
                    if (c.timer <= 0.0) c.state = if (c.knot) .open else .follow;
                },
                .follow => {
                    const a = @as(f32, @floatCast(self.beat)) * 0.4 + follower * 1.3;
                    const r = 30.0 + follower * 7.0;
                    const tx = self.x + @cos(a) * r;
                    const ty = self.y + @sin(a) * r;
                    c.x += (tx - c.x) * @min(1.0, db * 2.2);
                    c.y += (ty - c.y) * @min(1.0, db * 2.2);
                    follower += 1.0;
                },
                .open, .asleep => {
                    c.timer = @max(0.0, c.timer - db);
                },
                .none => {},
            }
            // what the fork's push left over
            if (c.state != .lunge) {
                c.x += c.vx * db;
                c.y += c.vy * db;
                const drag = @exp(-db * 5.0);
                c.vx *= drag;
                c.vy *= drag;
            }
        }
    }

    fn pulseSound(self: *World, c: *const Creature, note: Note) void {
        // With the wheel open each pulse is a clear note you can count. Otherwise it is only
        // just there.
        const loud: f32 = if (self.wheel_open) 0.10 else if (c.rung > 0.0) 0.03 else 0.012;
        const dx = c.x - self.x;
        const dy = c.y - self.y;
        if (dx * dx + dy * dy > 420.0 * 420.0) return;
        self.play(.{ .table = .bell, .hz = self.noteHz(note, 523.0), .gain = loud, .decay = 0.07 });
    }

    fn lash(self: *World, c: *Creature) void {
        self.steady = @max(0.0, self.steady - 0.25);
        self.hurt = 1.0;
        self.invuln = 1.5;
        self.play(.{ .table = .soft, .hz = 70.0, .gain = 0.30, .decay = 0.12, .bend = 2.0 });
        self.play(.{ .table = .reed, .hz = self.noteHz(c.note, 196.0), .gain = 0.10, .decay = 0.2 });
        self.note_event(.lash, c.note, self.steady);
        if (self.swell) self.release(true);
        if (self.steady <= 0.0) {
            // nothing dies: they draw off, and Hum gathers itself
            self.steady = 1.0;
            self.note_event(.dusk, 0, 0.0);
            for (&self.creatures) |*o| {
                if (!o.live()) continue;
                o.cooldown = 12.0;
                o.state = if (o.state == .grey) .grey else .recover;
                o.timer = @max(o.timer, 4.0);
            }
        }
    }

    fn stepLight(self: *World, dt: f32, db: f32) void {
        // rings of light run out from a call and light what they pass
        for (&self.rings) |*r| {
            if (!r.alive) continue;
            const before = r.r;
            r.r += r.speed * db;
            r.life = 1.0 - r.r / r.reach;
            if (r.life <= 0.0) {
                r.alive = false;
                continue;
            }
            for (things, 0..) |t, i| {
                const dx = t.x - r.x;
                const dy = t.y - r.y;
                const d = @sqrt(dx * dx + dy * dy);
                if (d >= before and d < r.r) self.lit[i] = @max(self.lit[i], r.life);
            }
            if (!r.call) continue;
            // a call rings every creature it reaches, in that creature's own note
            for (&self.creatures) |*c| {
                if (!c.live()) continue;
                const dx = c.x - r.x;
                const dy = c.y - r.y;
                const d = @sqrt(dx * dx + dy * dy);
                if (d >= before and d < r.r) {
                    c.rung = 12.0;
                    c.flash = 0.7;
                    self.play(.{ .table = .bell, .hz = self.noteHz(c.note, 392.0), .gain = 0.10 * r.life, .decay = 0.5 });
                }
            }
        }
        for (&self.lit) |*l| l.* = @max(0.0, l.* - dt * 0.22);
        for (&self.sparks) |*s| {
            if (s.life <= 0.0) continue;
            s.life -= dt * 1.6;
            s.x += s.vx * dt;
            s.y += s.vy * dt;
            s.vx *= 0.94;
            s.vy *= 0.94;
        }
        // steadiness comes back in quiet
        if (self.liveCount() == 0) self.steady = @min(1.0, self.steady + db / 16.0);
    }
};

// ---------------------------------------------------------------- tests

const Rig = struct {
    sound: *synth.Shared,
    world: World,
    beat: f64 = 0.0,

    fn make() !*Rig {
        const rig = try std.testing.allocator.create(Rig);
        const sound = try std.testing.allocator.create(synth.Shared);
        sound.* = .{};
        rig.* = .{ .sound = sound, .world = World.init(sound) };
        return rig;
    }

    fn free(self: *Rig) void {
        std.testing.allocator.destroy(self.sound);
        std.testing.allocator.destroy(self);
    }

    /// One sixtieth of a second, with the clock running at the pace the world asked for.
    fn tick(self: *Rig, in: Input) void {
        self.beat += @as(f64, self.sound.scale) * @as(f64, self.sound.bps) / 60.0;
        self.world.step(in, 1.0 / 60.0, self.beat);
        // nothing is listening, so empty the queue
        self.sound.tail = self.sound.head;
    }

    fn until(self: *Rig, beat: f64, in: Input) void {
        while (self.beat < beat) self.tick(in);
    }
};

test "a knot meets you on the one only when home is where its strands cross" {
    const rig = try Rig.make();
    defer rig.free();
    const w = &rig.world;
    const knot = Creature{ .state = .roam, .knot = true, .note = 0, .other = 3, .id = 1 };
    try std.testing.expectEqual(@as(Note, -1), World.meetingPlace(&knot));
    w.home = -1;
    try std.testing.expect(w.meets(&knot, 8));
    try std.testing.expect(!w.meets(&knot, 9));
    try std.testing.expect(!w.meets(&knot, 10));
    w.home = 0; // on sunny home it comes round every three beats, drifting across the bar
    var on_ones: usize = 0;
    var total: usize = 0;
    for (0..24) |b| {
        if (w.meets(&knot, @intCast(b))) {
            total += 1;
            if (b % 4 == 0) on_ones += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 8), total);
    try std.testing.expectEqual(@as(usize, 2), on_ones);
}

test "the doors: home on its left brings it home, on its right sings it to sleep" {
    const rig = try Rig.make();
    defer rig.free();
    const w = &rig.world;
    const g = Creature{ .state = .grey, .note = 1 }; // G
    w.home = 0; // C, one to its left
    try std.testing.expectEqual(@as(u8, 1), w.door(&g));
    w.home = 2; // D, one to its right
    try std.testing.expectEqual(@as(u8, 2), w.door(&g));
    w.home = 3;
    try std.testing.expectEqual(@as(u8, 0), w.door(&g));
}

test "home the long way: three creatures on a run of fifths, one breath" {
    const rig = try Rig.make();
    defer rig.free();
    const w = &rig.world;
    w.stage = .run;
    w.light = 1.0;
    w.awake = @splat(true);
    w.spawn(.{ .state = .grey, .note = 3, .x = 40, .y = 0, .timer = 400 }); // A, already grey
    w.spawn(.{ .state = .roam, .note = 2, .x = 0, .y = 60, .cooldown = 999 }); // D
    w.spawn(.{ .state = .roam, .note = 1, .x = -50, .y = 0, .cooldown = 999 }); // G
    for (&w.creatures) |*c| c.cooldown = 999;
    w.home = 2; // stand beside the grey one: D
    rig.until(1.0, .{});
    rig.until(3.2, .{ .r2 = true }); // the swell
    rig.until(3.99, .{ .r2 = true });
    rig.tick(.{ .r2 = true, .aim_x = -1.0 }); // nudge left on the one
    try std.testing.expectEqual(@as(Note, 1), w.home);
    try std.testing.expectEqual(CreatureState.homing, w.creatures[0].state);
    try std.testing.expectEqual(CreatureState.grey, w.creatures[1].state);
    rig.until(7.99, .{ .r2 = true });
    rig.tick(.{ .r2 = true, .aim_x = -1.0 }); // and again
    try std.testing.expectEqual(@as(Note, 0), w.home);
    try std.testing.expectEqual(CreatureState.grey, w.creatures[2].state);
    rig.until(11.99, .{ .r2 = true });
    rig.tick(.{}); // let go on the one
    try std.testing.expect(!w.creatures[2].live());
    try std.testing.expectEqual(@as(u8, 3), w.best_walk);
    try std.testing.expectEqual(@as(f32, 4.0), w.breath_cap); // the breath grew to hold one more
}

test "a nudge off the one only moves home" {
    const rig = try Rig.make();
    defer rig.free();
    const w = &rig.world;
    w.stage = .run;
    w.light = 1.0;
    w.awake = @splat(true);
    w.spawn(.{ .state = .grey, .note = 3, .x = 40, .y = 0, .timer = 400 });
    w.home = 2;
    rig.until(1.0, .{});
    rig.until(2.4, .{ .r2 = true });
    rig.tick(.{ .r2 = true, .aim_x = -1.0 });
    try std.testing.expectEqual(@as(Note, 1), w.home);
    try std.testing.expectEqual(CreatureState.grey, w.creatures[0].state);
}

test "a strike is placed on the beat, and only a meeting drains" {
    const rig = try Rig.make();
    defer rig.free();
    const w = &rig.world;
    w.stage = .knots;
    w.light = 1.0;
    w.home = -1; // where the strands cross
    w.spawn(.{ .state = .roam, .knot = true, .note = 0, .other = 3, .x = 30, .y = 0 });
    w.creatures[0].cooldown = 999;
    rig.until(5.2, .{});
    rig.tick(.{ .strike = true }); // just after beat 5: lands now, on beat 5, which is no meeting
    rig.until(5.6, .{});
    try std.testing.expectEqual(@as(f32, 1.0), w.creatures[0].colour);
    rig.until(7.8, .{});
    w.creatures[0].x = w.x + 30.0;
    w.creatures[0].y = w.y;
    rig.tick(.{ .strike = true }); // early for the one: the game holds it until beat 8
    try std.testing.expect(w.strike_beat == 8.0);
    rig.until(8.1, .{});
    try std.testing.expect(w.creatures[0].colour < 1.0);
}
