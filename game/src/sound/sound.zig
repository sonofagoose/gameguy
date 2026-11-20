//! The sound: one bank of resonators that renders everything.
//!
//! Every overtone of every sounding thing is one two-pole filter, y = a1*y1 + a2*y2 + g*x, four
//! abreast in one vector (measured: about 2,100 fit in half a buffer on one core of the purple;
//! game/bench/modes.zig). A rung thing is a short burst into its overtones. A sung voice is a
//! stream of pulses through a few resonators that are its vowel.
//!
//! Nothing here touches the platform or keeps a beat of its own. The world sends cues stamped with
//! the sample they are due at, and `render` is a function of those cues alone, so the same cues
//! make the same samples on every machine. Multiplies and adds are never fused.
const std = @import("std");

pub const rate: f32 = 48000.0;
const V = @Vector(4, f32);

/// The shapes things come in, each with the overtones of that shape (spec/laws.md).
pub const Family = enum(u8) { bell, string, stopped_pipe, bar, skin, tone, fork };

pub const Recipe = struct { mult: [8]f32, gain: [8]f32 };

pub fn recipe(family: Family) Recipe {
    return switch (family) {
        // a made bell: its third is the land's own, pure here
        .bell => .{ .mult = .{ 0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0 }, .gain = .{ 0.30, 1.0, 0.45, 0.35, 0.55, 0.20, 0.22, 0.10 } },
        .string => .{ .mult = .{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 }, .gain = .{ 1.0, 0.50, 0.33, 0.25, 0.20, 0.16, 0.14, 0.12 } },
        .stopped_pipe => .{ .mult = .{ 1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0 }, .gain = .{ 1.0, 0.33, 0.20, 0.14, 0.11, 0.09, 0.07, 0.06 } },
        .bar => .{ .mult = .{ 1.0, 2.756, 5.404, 8.933, 13.34, 18.64, 0.0, 0.0 }, .gain = .{ 1.0, 0.45, 0.25, 0.12, 0.06, 0.03, 0.0, 0.0 } },
        .skin => .{ .mult = .{ 1.0, 1.593, 2.136, 2.295, 2.653, 2.917, 3.156, 3.501 }, .gain = .{ 1.0, 0.55, 0.40, 0.30, 0.25, 0.18, 0.12, 0.10 } },
        // Hum's tuning fork: nearly a pure tone (spec/laws.md, "The families")
        .fork => .{ .mult = .{ 1.0, 6.27, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, .gain = .{ 1.0, 0.22, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
        // one standing shape alone: a single tone
        .tone => .{ .mult = .{ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, .gain = .{ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
    };
}

/// What the world asks of the sound. `at` is the sample it is due.
pub const Cue = extern struct {
    at: u64,
    kind: Kind,
    family: Family = .bell,
    /// For a held voice: whose it is. 0 is Hum.
    voice: u8 = 0,
    /// 1: Hum's own call or hum, for a press or a let-go, which the hands may already have started
    /// on this very sample (ownNow). Then it is not sounded twice, and not counted late.
    own: u8 = 0,
    /// The lowest note of the thing, in hertz.
    hz: f32 = 0.0,
    /// How hard, 0 to 1.
    gain: f32 = 0.0,
    /// How long its lowest note rings, in seconds.
    ring: f32 = 1.0,
    /// How much of its brightness the way here has taken: nought for near, more for far. Each
    /// overtone above the first is quieter by it (spec/engine.md: "softer and duller with
    /// distance").
    dull: f32 = 0.0,

    /// `tone`: a held pure note that is not a voice, such as standing water. `voice` is which of
    /// them; `gain` is how loud it should now be, and nought ends it.
    /// `tempo`: the world's pace changed (time thickens while the wheel is open): what is ringing
    /// rings longer by as much, a held chord, and lets go when the pace comes back. `gain` is the
    /// pace.
    pub const Kind = enum(u8) { strike, hum_on, hum_off, tone, tempo };
};

/// A held voice: Hum's closed "mm", Drip's "oh", and room for two more.
pub const max_voices = 4;
const Voice = struct {
    a1: V = @splat(0.0),
    a2: V = @splat(0.0),
    gain: V = @splat(0.0),
    y1: V = @splat(0.0),
    y2: V = @splat(0.0),
    phase: f32 = 0.0,
    step: f32 = 0.0,
    level: f32 = 0.0,
    target: f32 = 0.0,
    noise: u32 = 0x1234_5678,
};
/// Held pure notes that are not voices: water standing in a shape sings its note for as long as
/// it stands (world/pools.zig).
pub const max_tones = 8;
const Tone = struct {
    phase: f32 = 0.0,
    step: f32 = 0.0,
    level: f32 = 0.0,
    target: f32 = 0.0,
};

/// A sine of a whole turn's part, by a parabola made true to within a thousandth: the same sum on
/// every machine, and no library's.
fn sineOfTurn(p: f32) f32 {
    // the parabola for sin(2 pi p - pi) = -sin(2 pi p), on x from -1 to 1
    const x = 2.0 * p - 1.0;
    const y = 4.0 * x * (1.0 - @abs(x));
    return -(0.225 * (y * @abs(y) - y) + y);
}

/// How much of the voices' sum squared is added back. Two voices together then make a third
/// note between them, the difference of the two, which neither is singing (spec/laws.md).
const third_voice: f32 = 0.70;

const max_things = 192; // 8 overtones each: 1,536 overtones, two groups a thing
const burst_len = 96; // 2 ms: what a strike is

const Thing = struct {
    left: u32 = 0, // samples of its burst still to come
    level: f32 = 0.0,
    /// Its own noise, so that what one thing sounds like never depends on what else is sounding.
    noise: u32 = 1,
    asleep: bool = true,
};

fn rnd(state: *u32) f32 {
    state.* ^= state.* << 13;
    state.* ^= state.* >> 17;
    state.* ^= state.* << 5;
    return @as(f32, @floatFromInt(@as(i32, @bitCast(state.*)) >> 8)) * (1.0 / 8388608.0);
}

pub const Sound = struct {
    // the bank: two groups of four for each thing
    a1: [max_things * 2]V = @splat(@splat(0.0)),
    a2: [max_things * 2]V = @splat(@splat(0.0)),
    gain: [max_things * 2]V = @splat(@splat(0.0)),
    y1: [max_things * 2]V = @splat(@splat(0.0)),
    y2: [max_things * 2]V = @splat(@splat(0.0)),
    things: [max_things]Thing = @splat(.{}),
    next_thing: u32 = 0,

    // held voices: each is pulses through three resonators that are its vowel
    voices: [max_voices]Voice = @splat(.{}),
    tones: [max_tones]Tone = @splat(.{}),
    /// What the voices' sum has just been, to take the standing part out of its square.
    bus_dc: f32 = 0.0,
    /// Samples rendered so far: the only clock there is.
    sample: u64 = 0,
    /// Cues that arrived after their sample had passed. They sound at once, and are counted.
    late: u32 = 0,
    /// The world's pace, as the sound was last told it: one, or thick while the wheel is open.
    pace: f32 = 1.0,
    /// Where the hands last started Hum's own call, hum and let-go before the world told them.
    own_call_at: u64 = std.math.maxInt(u64),
    own_on_at: u64 = std.math.maxInt(u64),
    own_off_at: u64 = std.math.maxInt(u64),
    /// How many of the world's own cues found their sound already started by the hands.
    own_met: u32 = 0,

    // cues from the world, one writer and one reader
    queue: [256]Cue = undefined,
    head: u32 = 0,
    tail: u32 = 0,

    pub fn init(self: *Sound) void {
        self.* = .{};
        // each voice's vowel: three resonances (hertz, width, level)
        const vowels = [max_voices][3][3]f32{
            .{ .{ 280.0, 70.0, 1.0 }, .{ 1050.0, 110.0, 0.22 }, .{ 2300.0, 160.0, 0.08 } }, // mm: Hum
            .{ .{ 520.0, 80.0, 1.0 }, .{ 860.0, 100.0, 0.45 }, .{ 2500.0, 170.0, 0.10 } }, // oh: Drip
            .{ .{ 720.0, 90.0, 1.0 }, .{ 1120.0, 110.0, 0.50 }, .{ 2600.0, 180.0, 0.12 } }, // ah
            .{ .{ 320.0, 70.0, 1.0 }, .{ 800.0, 100.0, 0.30 }, .{ 2300.0, 160.0, 0.06 } }, // oo
        };
        for (&self.voices, 0..) |*voice, which| {
            var a1: [4]f32 = @splat(0.0);
            var a2: [4]f32 = @splat(0.0);
            var g: [4]f32 = @splat(0.0);
            for (0..3) |i| {
                const r = @exp(-std.math.pi * vowels[which][i][1] / rate);
                a1[i] = 2.0 * r * @cos(2.0 * std.math.pi * vowels[which][i][0] / rate);
                a2[i] = -(r * r);
                g[i] = vowels[which][i][2] * (1.0 - r);
            }
            voice.a1 = a1;
            voice.a2 = a2;
            voice.gain = g;
            voice.noise = 0x1234_5678 +% @as(u32, @intCast(which)) *% 0x9e37_79b9;
        }
    }

    /// The world's side: ask for a sound. False if the queue is full.
    pub fn push(self: *Sound, cue: Cue) bool {
        const head = @atomicLoad(u32, &self.head, .monotonic);
        const tail = @atomicLoad(u32, &self.tail, .acquire);
        if (head -% tail >= self.queue.len) return false;
        self.queue[head % self.queue.len] = cue;
        @atomicStore(u32, &self.head, head +% 1, .release);
        return true;
    }

    fn apply(self: *Sound, cue: Cue) void {
        switch (cue.kind) {
            .hum_on => {
                const voice = &self.voices[@min(cue.voice, max_voices - 1)];
                voice.step = cue.hz / rate;
                voice.target = cue.gain;
            },
            .hum_off => self.voices[@min(cue.voice, max_voices - 1)].target = 0.0,
            .tone => {
                const tone = &self.tones[cue.voice % max_tones];
                tone.step = cue.hz / rate;
                tone.target = cue.gain;
            },
            .tempo => self.restretch(cue.gain),
            .strike => {
                const slot = self.next_thing % max_things;
                self.next_thing +%= 1;
                const rec = recipe(cue.family);
                var a1: [8]f32 = undefined;
                var a2: [8]f32 = undefined;
                var g: [8]f32 = undefined;
                for (0..8) |i| {
                    const hz = cue.hz * rec.mult[i];
                    if (rec.mult[i] <= 0.0 or hz > rate * 0.45) {
                        a1[i] = 0.0;
                        a2[i] = 0.0;
                        g[i] = 0.0;
                        continue;
                    }
                    // higher overtones die sooner; while time is thick everything rings longer
                    const ring = @max(0.05, cue.ring / @sqrt(@max(rec.mult[i], 0.5) * 2.0)) / self.pace;
                    const r = @exp(-6.91 / (ring * rate));
                    a1[i] = 2.0 * r * @cos(2.0 * std.math.pi * hz / rate);
                    a2[i] = -(r * r);
                    const duller = 1.0 / (1.0 + cue.dull * (@max(rec.mult[i], 1.0) - 1.0));
                    g[i] = rec.gain[i] * @sin(2.0 * std.math.pi * hz / rate) * 0.5 * duller;
                }
                self.a1[slot * 2] = a1[0..4].*;
                self.a1[slot * 2 + 1] = a1[4..8].*;
                self.a2[slot * 2] = a2[0..4].*;
                self.a2[slot * 2 + 1] = a2[4..8].*;
                self.gain[slot * 2] = g[0..4].*;
                self.gain[slot * 2 + 1] = g[4..8].*;
                // a thing struck again keeps ringing; a slot taken from an old thing starts clean
                self.y1[slot * 2] = @splat(0.0);
                self.y1[slot * 2 + 1] = @splat(0.0);
                self.y2[slot * 2] = @splat(0.0);
                self.y2[slot * 2 + 1] = @splat(0.0);
                self.things[slot] = .{ .left = burst_len, .level = cue.gain, .noise = 0x9e3779b9 ^ (self.next_thing *% 2654435761), .asleep = false };
            },
        }
    }

    /// Render the next `out.len` samples (one channel). Cues due inside them start on their sample.
    pub fn render(self: *Sound, out: []f32) void {
        var done: usize = 0;
        while (done < out.len) {
            // take every cue that is due, and find how far we can go before the next one
            var until: usize = out.len;
            while (true) {
                const tail = @atomicLoad(u32, &self.tail, .monotonic);
                const head = @atomicLoad(u32, &self.head, .acquire);
                if (tail == head) break;
                const cue = self.queue[tail % self.queue.len];
                const now = self.sample + done;
                if (cue.at <= now) {
                    if (cue.at < now and cue.own == 0) self.late += 1;
                    if (!self.startedByHands(cue)) self.apply(cue);
                    @atomicStore(u32, &self.tail, tail +% 1, .release);
                    continue;
                }
                const gap = cue.at - now;
                if (gap < out.len - done) until = done + @as(usize, @intCast(gap));
                break;
            }
            self.renderPart(out[done..until], self.sample + done);
            done = until;
        }
        @atomicStore(u64, &self.sample, self.sample + out.len, .release);
    }

    /// The hands start Hum's own sound now, on the next sample to be rendered, before the world has
    /// stepped: called on the sound's own thread, just before it renders. The return is the sample
    /// it starts on, which is the hands' stamp.
    pub fn ownNow(self: *Sound, cue: Cue) u64 {
        const at = self.sample;
        switch (cue.kind) {
            .strike => self.own_call_at = at,
            .hum_on => self.own_on_at = at,
            .hum_off => self.own_off_at = at,
            .tone, .tempo => {},
        }
        self.apply(cue);
        return at;
    }

    /// The pace changed: every resonator still ringing decays by as much more slowly (or quickly
    /// again), its note unchanged. A resonator's pull back is r per sample, so r to the power of the
    /// ratio of the paces rings that much longer.
    fn restretch(self: *Sound, pace: f32) void {
        if (pace <= 0.0 or pace == self.pace) return;
        const ratio: V = @splat(pace / self.pace);
        self.pace = pace;
        for (&self.things, 0..) |*thing, slot| {
            if (thing.asleep) continue;
            inline for (0..2) |half| {
                const g = slot * 2 + half;
                const r = @sqrt(@max(-self.a2[g], @as(V, @splat(0.0))));
                const live = r > @as(V, @splat(1e-6));
                const safe = @select(f32, live, r, @as(V, @splat(1.0)));
                const r_new = @exp(@log(safe) * ratio);
                const c = self.a1[g] / (safe * @as(V, @splat(2.0)));
                self.a1[g] = @select(f32, live, @as(V, @splat(2.0)) * r_new * c, self.a1[g]);
                self.a2[g] = @select(f32, live, -(r_new * r_new), self.a2[g]);
            }
        }
    }

    /// Whether the world's cue is one the hands have already started on its very sample.
    fn startedByHands(self: *Sound, cue: Cue) bool {
        if (cue.own == 0) return false;
        const slot = switch (cue.kind) {
            .strike => &self.own_call_at,
            .hum_on => &self.own_on_at,
            .hum_off => &self.own_off_at,
            .tone, .tempo => return false,
        };
        // the same press, if the hands started it within a step of where the world tells it (two
        // buttons changing in one step share a stamp); used once, so a later press is not missed
        const at = slot.*;
        if (at == std.math.maxInt(u64)) return false;
        const apart = if (at > cue.at) at - cue.at else cue.at - at;
        if (apart > 800) return false;
        slot.* = std.math.maxInt(u64);
        self.own_met += 1;
        return true;
    }

    /// How many samples have been rendered, for the loop on another thread to count steps by.
    pub fn played(self: *const Sound) u64 {
        return @atomicLoad(u64, &self.sample, .acquire);
    }

    /// `from` is the sample `out` starts at. The work is cut at every 128th sample counted from the
    /// very first, never from wherever a buffer happens to begin, so the samples are the same
    /// whatever size of buffer asks for them.
    fn renderPart(self: *Sound, out: []f32, from: u64) void {
        @setRuntimeSafety(false);
        if (out.len == 0) return;
        var acc: [128]V = undefined;
        var at: usize = 0;
        while (at < out.len) {
            const into: usize = @intCast((from + at) % 128);
            const n = @min(128 - into, out.len - at);
            @memset(acc[0..n], @as(V, @splat(0.0)));

            // rung things
            for (&self.things, 0..) |*thing, slot| {
                if (thing.asleep) continue;
                var x: [128]f32 = undefined;
                for (0..n) |i| {
                    if (thing.left > 0) {
                        // a short burst that fades: the mallet
                        const fade = @as(f32, @floatFromInt(thing.left)) * (1.0 / @as(f32, burst_len));
                        x[i] = rnd(&thing.noise) * fade * thing.level;
                        thing.left -= 1;
                    } else x[i] = 0.0;
                }
                var still: f32 = 0.0;
                inline for (0..2) |half| {
                    const g = slot * 2 + half;
                    const ca1 = self.a1[g];
                    const ca2 = self.a2[g];
                    const cg = self.gain[g];
                    var p1 = self.y1[g];
                    var p2 = self.y2[g];
                    for (0..n) |i| {
                        const xin: V = @splat(x[i]);
                        const y0 = ca1 * p1 + ca2 * p2 + cg * xin;
                        acc[i] += y0;
                        p2 = p1;
                        p1 = y0;
                    }
                    still = @max(still, @reduce(.Max, @abs(p1)) + @reduce(.Max, @abs(p2)));
                    self.y1[g] = p1;
                    self.y2[g] = p2;
                }
                // A thing that has rung down to nothing is set to nothing, so no machine ever
                // computes with the very small numbers processors treat differently.
                if (thing.left == 0 and still < 1e-7) {
                    inline for (0..2) |half| {
                        self.y1[slot * 2 + half] = @splat(0.0);
                        self.y2[slot * 2 + half] = @splat(0.0);
                    }
                    thing.asleep = true;
                }
            }

            // the held voices, summed on a line of their own
            var bus: [128]f32 = @splat(0.0);
            for (&self.voices) |*voice| {
                if (voice.level == 0.0 and voice.target == 0.0) continue;
                var p1 = voice.y1;
                var p2 = voice.y2;
                for (0..n) |i| {
                    voice.level += (voice.target - voice.level) * 0.0015;
                    var x: f32 = 0.0;
                    if (voice.step > 0.0) {
                        voice.phase += voice.step;
                        if (voice.phase >= 1.0) {
                            voice.phase -= 1.0;
                            x = 1.0;
                        }
                    }
                    const xin: V = @splat((x + rnd(&voice.noise) * 0.004) * voice.level);
                    const y0 = voice.a1 * p1 + voice.a2 * p2 + voice.gain * xin;
                    bus[i] += ((y0[0] + y0[1]) + (y0[2] + y0[3])) * 6.0;
                    p2 = p1;
                    p1 = y0;
                }
                if (voice.level < 1e-6 and voice.target == 0.0) {
                    const size = @reduce(.Max, @abs(p1)) + @reduce(.Max, @abs(p2));
                    if (size < 1e-7) {
                        p1 = @splat(0.0);
                        p2 = @splat(0.0);
                        voice.level = 0.0;
                    }
                }
                voice.y1 = p1;
                voice.y2 = p2;
            }
            // Where two voices sound together, the air between them adds a third: the square of
            // their sum holds the difference of their notes. Its standing part is taken out.
            for (0..n) |i| {
                const squared = bus[i] * bus[i];
                self.bus_dc += (squared - self.bus_dc) * 0.002;
                if (@abs(self.bus_dc) < 1e-9) self.bus_dc = 0.0;
                bus[i] += third_voice * (squared - self.bus_dc);
            }

            // held pure notes, eased toward the loudness last asked for so no step is heard
            var tones: [128]f32 = @splat(0.0);
            for (&self.tones) |*tone| {
                if (tone.level == 0.0 and tone.target == 0.0) continue;
                for (0..n) |i| {
                    tone.level += (tone.target - tone.level) * 0.0004;
                    tone.phase += tone.step;
                    if (tone.phase >= 1.0) tone.phase -= 1.0;
                    tones[i] += sineOfTurn(tone.phase) * tone.level;
                }
                if (tone.target == 0.0 and tone.level < 1e-6) {
                    tone.level = 0.0;
                    tone.phase = 0.0;
                }
            }

            for (0..n) |i| {
                const s = ((acc[i][0] + acc[i][1]) + (acc[i][2] + acc[i][3])) + bus[i] + tones[i];
                // a soft limit: straight up to 0.7, then bending toward 1
                const a = @abs(s);
                out[at + i] = if (a <= 0.7) s else std.math.copysign(0.7 + 0.3 * (1.0 - 1.0 / (1.0 + (a - 0.7) * 3.3333)), s);
            }
            at += n;
        }
    }
};

test "the same cues make the same samples" {
    var a: Sound = undefined;
    var b: Sound = undefined;
    a.init();
    b.init();
    const cues = [_]Cue{
        .{ .at = 100, .kind = .strike, .hz = 261.63, .gain = 0.8, .ring = 1.5 },
        .{ .at = 4000, .kind = .hum_on, .hz = 261.63, .gain = 0.5 },
        .{ .at = 9000, .kind = .strike, .family = .bar, .hz = 392.44, .gain = 0.6, .ring = 0.8 },
        .{ .at = 20000, .kind = .hum_off },
    };
    for (cues) |cue| {
        try std.testing.expect(a.push(cue));
        try std.testing.expect(b.push(cue));
    }
    var out_a: [48000]f32 = undefined;
    var out_b: [48000]f32 = undefined;
    // one renders in buffers of 128, the other in buffers of 800: the samples must not care
    var at: usize = 0;
    while (at < out_a.len) : (at += 128) a.render(out_a[at..@min(at + 128, out_a.len)]);
    at = 0;
    while (at < out_b.len) : (at += 800) b.render(out_b[at..@min(at + 800, out_b.len)]);
    var loudest: f32 = 0.0;
    for (out_a, out_b) |x, y| {
        try std.testing.expectEqual(x, y);
        loudest = @max(loudest, @abs(x));
    }
    try std.testing.expect(loudest > 0.05);
    try std.testing.expect(loudest <= 1.0);
    try std.testing.expectEqual(@as(u32, 0), a.late);
}

test "two voices together make a third between them, and one alone makes none" {
    // how much sound there is at one pitch in a stretch of samples
    const at = struct {
        fn f(samples: []const f32, hz: f32) f32 {
            var re: f32 = 0.0;
            var im: f32 = 0.0;
            for (samples, 0..) |x, i| {
                const a = 2.0 * std.math.pi * hz * @as(f32, @floatFromInt(i)) / rate;
                re += x * @cos(a);
                im += x * @sin(a);
            }
            return @sqrt(re * re + im * im) / @as(f32, @floatFromInt(samples.len));
        }
    }.f;
    const allocator = std.testing.allocator;
    const out = try allocator.alloc(f32, 48000 * 2);
    defer allocator.free(out);
    const snd = try allocator.create(Sound);
    defer allocator.destroy(snd);
    // 1,300 and 1,950 hertz: a pure fifth, and nothing either voice sings is at 650
    const low: f32 = 1300.0;
    const high: f32 = 1950.0;
    snd.init();
    _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 0, .hz = low, .gain = 0.35 });
    snd.render(out);
    const alone = at(out[48000..], high - low);
    snd.init();
    _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 0, .hz = low, .gain = 0.35 });
    _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 1, .hz = high, .gain = 0.35 });
    snd.render(out);
    const together = at(out[48000..], high - low);
    try std.testing.expect(together > alone * 8.0);
    try std.testing.expect(together > 1e-5);
}

test "a held tone is a clean sine at its note, and eases in and out" {
    var s: Sound = undefined;
    s.init();
    _ = s.push(.{ .at = 0, .kind = .tone, .voice = 3, .hz = 261.63, .gain = 0.2 });
    var out: [48000]f32 = undefined;
    s.render(&out);
    // eased in: quiet at first, at its level by a tenth of a second
    try std.testing.expect(@abs(out[10]) < 0.01);
    var most: f32 = 0.0;
    for (out[24000..]) |v| most = @max(most, @abs(v));
    try std.testing.expect(most > 0.19 and most < 0.21);
    // its sine: nothing above it louder than a thousandth of it
    const e = sineOfTurn(0.25);
    try std.testing.expect(@abs(e + 1.0) < 0.0015 or @abs(e - 1.0) < 0.0015);
    var worst: f32 = 0.0;
    var k: u32 = 0;
    while (k < 1000) : (k += 1) {
        const p = @as(f32, @floatFromInt(k)) / 1000.0;
        worst = @max(worst, @abs(sineOfTurn(p) - @sin(2.0 * std.math.pi * p)));
    }
    try std.testing.expect(worst < 0.0011);
    // and nought ends it
    _ = s.push(.{ .at = 48000, .kind = .tone, .voice = 3, .hz = 261.63, .gain = 0.0 });
    s.render(&out);
    try std.testing.expect(@abs(out[47999]) < 0.001);
}
