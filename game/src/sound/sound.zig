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
pub const Family = enum(u8) { bell, string, stopped_pipe, bar, skin, tone, fork, fork_octave, open_pipe };

pub const Recipe = struct {
    mult: [8]f32,
    gain: [8]f32,
    /// For a partial that carries a lower one's sound to the speaker: the lower one's place, so it
    /// rings as long. Nought: its own.
    rings_as: [8]f32 = @splat(0.0),
};

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
        // a pipe open at both ends: every overtone (spec/laws.md, "The families")
        .open_pipe => .{ .mult = .{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 }, .gain = .{ 1.0, 0.50, 0.33, 0.25, 0.20, 0.16, 0.14, 0.12 } },
        // a strike you timed yourself: the same note with its octave, fuller (SPEC.md 10)
        .fork_octave => .{ .mult = .{ 1.0, 2.0, 6.27, 12.54, 0.0, 0.0, 0.0, 0.0 }, .gain = .{ 1.0, 0.6, 0.22, 0.12, 0.0, 0.0, 0.0, 0.0 } },
        // one standing shape alone: a single tone
        .tone => .{ .mult = .{ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }, .gain = .{ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } },
    };
}

/// Whose a cue is (Cue.own).
/// The world's: counted late if it comes after its sample.
pub const own_world: u8 = 0;
/// Hum's call, hum or let-go, which the hands may already have started (ownNow).
pub const own_hands: u8 = 1;
/// Hum's clap, which the hands may already have started. It chokes a call begun just before it:
/// the two were one gesture.
pub const own_clap: u8 = 2;
/// Hum's own, on the hands' stamp, which only the world starts: a strike, the pocket, the swell's
/// step. Never taken for a sound the hands started.
pub const own_only: u8 = 3;
/// Hum's strike, timed by the hands within the beat's window, which the hands may already have
/// started.
pub const own_strike: u8 = 4;
/// How long after a call a clap still chokes it, in samples: the clap's window and a step.
pub const clap_chokes: u64 = 5600;

/// What the world asks of the sound. `at` is the sample it is due.
pub const Cue = extern struct {
    at: u64,
    kind: Kind,
    family: Family = .bell,
    /// For a held voice: whose it is. 0 is Hum.
    voice: u8 = 0,
    /// Whose sound it is: the world's (`own_world`), or Hum's own, which starts on the hands' stamp
    /// and is never counted late. Hum's call, hum and clap the hands may already have started on
    /// this very sample (ownNow), and then they are not sounded twice.
    own: u8 = own_world,
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
pub const max_tones = 16;
const Tone = struct {
    phase: f32 = 0.0,
    step: f32 = 0.0,
    level: f32 = 0.0,
    target: f32 = 0.0,
    /// A pure note, or a pipe held sounding: stopped (its odd overtones) or open (all of them).
    family: Family = .tone,
};

/// A held note's overtones, as the speaker or headphones are given them: which multiples of the
/// note and how strong each is. A pure note is one; a stopped pipe its odd overtones, each the
/// weaker for being higher; an open pipe all of them. Under the speaker's floor a partial is softer
/// and its octave carries what it lost (the fundamental's twelfth a share too); a stopped pipe has
/// no octaves, so its fifth partial carries what the speaker could have said of the ones under the
/// floor, and it stays hollow.
pub const Held = struct { mult: [6]f32 = @splat(0.0), gain: [6]f32 = @splat(0.0), n: usize = 0 };

/// How much softer a pipe moved two octaves up for the speaker is made: ten decibels.
const pipe_up_softer: f32 = 0.316;

pub fn heldParts(family: Family, hz: f32, speaker: bool) Held {
    var h = Held{};
    switch (family) {
        .stopped_pipe => {
            h.n = 6;
            for (0..6) |k| {
                const m: f32 = @floatFromInt(2 * k + 1);
                h.mult[k] = m;
                h.gain[k] = 1.0 / m;
            }
        },
        .open_pipe => {
            h.n = 6;
            for (0..6) |k| {
                const m: f32 = @floatFromInt(k + 1);
                h.mult[k] = m;
                h.gain[k] = 1.0 / m;
            }
        },
        else => {
            h.n = 3;
            h.mult = .{ 1.0, 2.0, 3.0, 0.0, 0.0, 0.0 };
            h.gain = .{ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
        },
    }
    if (!speaker) return h;
    // a pipe too low for the speaker to say at all (the hose's, two octaves under the garden) is
    // heard there two octaves up, whole: its note keeps its name and its shape, and stopped or open
    // it stays an octave from itself. Its own partials, so far under the floor, would leave only its
    // highest odd overtones, out of tune with everything near
    const pipe = family == .stopped_pipe or family == .open_pipe;
    if (pipe and hz < speaker_floor * 0.5) {
        // and as soft as it was heard down there: a note two octaves under the floor sounds about
        // ten decibels softer than the same level two octaves up, so moved up it is that much softer
        for (0..h.n) |k| h.mult[k] *= 4.0;
        for (0..h.n) |k| h.gain[k] *= underFloor(hz * h.mult[k]) * pipe_up_softer;
        return h;
    }
    if (family == .stopped_pipe) {
        // hollow it stays, and in its own key, and no louder than it would be heard: a partial far
        // under the floor is heard far softer than its energy says, so it hands up only as much
        // as the speaker could have said of it, and to the fifth partial, the lowest the speaker
        // says that sounds with the pipe's own note (its major third, two octaves up). Passed up
        // twelfth by twelfth it piled onto the ninth partial, a whole step above the pipe's note,
        // louder than everything else in the garden
        var given: f32 = 0.0;
        for (0..h.n) |k| {
            const w = underFloor(hz * h.mult[k]);
            if (w >= 1.0) continue;
            given += h.gain[k] * h.gain[k] * (1.0 - w * w) * w;
            h.gain[k] *= w;
        }
        for (0..h.n) |k| {
            if (h.mult[k] == 5.0) h.gain[k] = @sqrt(h.gain[k] * h.gain[k] + given);
        }
        return h;
    }
    var k: usize = 0;
    while (k < h.n) : (k += 1) {
        const w = underFloor(hz * h.mult[k]);
        if (w >= 1.0) continue;
        const lost = h.gain[k] * h.gain[k] * (1.0 - w * w);
        h.gain[k] *= w;
        // up the octave, which keeps the note's name; and from the fundamental, its twelfth, the fifth
        const from_root = h.mult[k] <= 1.01;
        const ups = [2]f32{ 2.0, 3.0 };
        const shares = if (from_root) [2]f32{ to_octave, to_twelfth } else [2]f32{ 1.0, 0.0 };
        for (ups, shares) |up, share| {
            if (share == 0.0) continue;
            for (0..h.n) |j| {
                if (@abs(h.mult[j] - h.mult[k] * up) < 0.01) h.gain[j] = @sqrt(h.gain[j] * h.gain[j] + share * lost);
            }
        }
    }
    return h;
}

/// A sine of a whole turn's part, by a parabola made true to within a thousandth: the same sum on
/// every machine, and no library's.
fn sineOfTurn(p: f32) f32 {
    // the parabola for sin(2 pi p - pi) = -sin(2 pi p), on x from -1 to 1
    const x = 2.0 * p - 1.0;
    const y = 4.0 * x * (1.0 - @abs(x));
    return -(0.225 * (y * @abs(y) - y) + y);
}

/// The speaker is the floor (SPEC.md, "The speaker is the floor"; spec/engine.md, "The end of the
/// chain"). The handheld's one small speaker speaks from about 400 Hz (spec/laws.md, "For the
/// ears"). Below it a partial is played softer the lower it is, twelve decibels an octave, and
/// what it loses is given to its own octave and twelfth, so a low voice is rebuilt from its upper
/// overtones and the ear supplies the root. With headphones in (plat/jack.zig) the sound has its
/// full range; tests, takes and the same-take test are always shaped for the speaker.
pub const speaker_floor: f32 = 400.0;
/// Of what a partial below the floor loses, how much goes to its octave, and how much to its twelfth.
const to_octave: f32 = 0.6;
const to_twelfth: f32 = 0.4;
/// The last of the chain: below this the speaker moves air it cannot sound, and spends the soft
/// limit's room on it. Taken out, two poles.
const speaker_cut_hz: f32 = 180.0;

/// How much of a partial at this pitch the speaker is given: all of it from the floor up.
pub fn underFloor(hz: f32) f32 {
    if (hz >= speaker_floor) return 1.0;
    const r = hz / speaker_floor;
    return r * r;
}

// the speaker's cut: a Butterworth high pass at speaker_cut_hz, worked out once
const cut_k: f32 = @tan(std.math.pi * speaker_cut_hz / 48000.0);
const cut_norm: f32 = 1.0 / (1.0 + std.math.sqrt2 * cut_k + cut_k * cut_k);
const cut_b0: f32 = cut_norm;
const cut_b1: f32 = -2.0 * cut_norm;
const cut_b2: f32 = cut_norm;
const cut_a1: f32 = 2.0 * (cut_k * cut_k - 1.0) * cut_norm;
const cut_a2: f32 = (1.0 - std.math.sqrt2 * cut_k + cut_k * cut_k) * cut_norm;

/// A family's partials for a note, as the speaker is given them: each under the floor softer, and
/// what it loses added to the partial an octave above it, and for the fundamental to the one a
/// twelfth above it too, or to new partials there in the slots the family leaves empty. The energy
/// is kept wherever there is a slot for it.
pub fn forSpeaker(rec: Recipe, hz: f32) Recipe {
    var out = rec;
    for (0..8) |i| {
        if (rec.mult[i] <= 0.0) continue;
        const f = hz * rec.mult[i];
        const w = underFloor(f);
        if (w >= 1.0) continue;
        const lost = rec.gain[i] * rec.gain[i] * (1.0 - w * w);
        out.gain[i] = rec.gain[i] * w;
        // an octave never changes what a note is called, and the fundamental's twelfth is its
        // fifth; a higher partial's twelfth would be a new note (the third partial's is the ninth,
        // a whole step above the note's own name), so above the fundamental all of it goes up the
        // octave
        const ups = [2]f32{ 2.0, 3.0 };
        const from_root = rec.mult[i] <= 1.01;
        const shares = if (from_root) [2]f32{ to_octave, to_twelfth } else [2]f32{ 1.0, 0.0 };
        for (ups, shares) |up, share| {
            if (share == 0.0) continue;
            const want = rec.mult[i] * up;
            var at: ?usize = null;
            for (0..8) |j| {
                if (out.mult[j] > 0.0 and @abs(out.mult[j] - want) < 0.01 * want) at = j;
            }
            if (at == null) {
                for (0..8) |j| {
                    if (out.mult[j] <= 0.0 and at == null) {
                        out.mult[j] = want;
                        out.gain[j] = 0.0;
                        at = j;
                    }
                }
            }
            if (at) |j| {
                // a partial given more than it had rings as long as the one it stands for
                if (share * lost > out.gain[j] * out.gain[j]) out.rings_as[j] = rec.mult[i];
                out.gain[j] = @sqrt(out.gain[j] * out.gain[j] + share * lost);
            }
        }
    }
    return out;
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
    /// Shaped for the speaker (the floor), or the full range for headphones; and what the main
    /// thread last asked for, taken up at the start of a buffer.
    speaker: bool = true,
    speaker_wanted: u8 = 1,
    /// The speaker's cut at the end of the chain: what went in and came out the last two samples.
    cut_x1: f32 = 0.0,
    cut_x2: f32 = 0.0,
    cut_y1: f32 = 0.0,
    cut_y2: f32 = 0.0,
    /// The world's pace, as the sound was last told it: one, or thick while the wheel is open.
    pace: f32 = 1.0,
    /// Where the hands last started Hum's own call, hum and let-go before the world told them.
    own_call_at: u64 = std.math.maxInt(u64),
    own_on_at: u64 = std.math.maxInt(u64),
    own_off_at: u64 = std.math.maxInt(u64),
    own_clap_at: u64 = std.math.maxInt(u64),
    own_strike_at: u64 = std.math.maxInt(u64),
    /// The thing the last call rang, the count of things when it took it, and the sample it began:
    /// a clap just after chokes it.
    call_slot: u32 = std.math.maxInt(u32),
    call_serial: u32 = 0,
    call_began: u64 = 0,
    /// How many calls a clap has choked.
    choked: u32 = 0,
    /// How many of the world's own cues found their sound already started by the hands.
    own_met: u32 = 0,

    // cues from the world, one writer and one reader
    queue: [256]Cue = undefined,
    head: u32 = 0,
    tail: u32 = 0,

    pub fn init(self: *Sound) void {
        self.* = .{};
        for (&self.voices, 0..) |*voice, which| voice.noise = 0x1234_5678 +% @as(u32, @intCast(which)) *% 0x9e37_79b9;
        self.voicing();
    }

    /// Shape the sound for the speaker, or give headphones the full range: from the main thread,
    /// taken up at the start of the next buffer.
    pub fn setSpeaker(self: *Sound, on: bool) void {
        @atomicStore(u8, &self.speaker_wanted, @intFromBool(on), .monotonic);
    }

    /// The voices' vowels, for the speaker or for headphones; the voices keep ringing through it.
    fn voicing(self: *Sound) void {
        // each voice's vowel: three resonances (hertz, width, level), and a fourth for the speaker.
        // Hum's mm and the oo are mostly their first resonance, under the speaker's floor: there
        // the first is softened by as much as the floor takes, and the fourth, a wide one round
        // the second and third harmonics of the notes they sing, carries what it lost
        const for_speaker = [max_voices][4][3]f32{
            .{ .{ 280.0, 70.0, 1.0 * underFloor(280.0) }, .{ 1050.0, 110.0, 0.22 }, .{ 2300.0, 160.0, 0.08 }, .{ 640.0, 300.0, 0.85 } }, // mm: Hum
            .{ .{ 520.0, 80.0, 1.0 }, .{ 860.0, 100.0, 0.45 }, .{ 2500.0, 170.0, 0.10 }, .{ 0.0, 0.0, 0.0 } }, // oh: Drip
            .{ .{ 720.0, 90.0, 1.0 }, .{ 1120.0, 110.0, 0.50 }, .{ 2600.0, 180.0, 0.12 }, .{ 0.0, 0.0, 0.0 } }, // ah
            .{ .{ 320.0, 70.0, 1.0 * underFloor(320.0) }, .{ 800.0, 100.0, 0.30 }, .{ 2300.0, 160.0, 0.06 }, .{ 660.0, 300.0, 0.75 } }, // oo
        };
        const for_headphones = [max_voices][4][3]f32{
            .{ .{ 280.0, 70.0, 1.0 }, .{ 1050.0, 110.0, 0.22 }, .{ 2300.0, 160.0, 0.08 }, .{ 0.0, 0.0, 0.0 } }, // mm: Hum
            .{ .{ 520.0, 80.0, 1.0 }, .{ 860.0, 100.0, 0.45 }, .{ 2500.0, 170.0, 0.10 }, .{ 0.0, 0.0, 0.0 } }, // oh: Drip
            .{ .{ 720.0, 90.0, 1.0 }, .{ 1120.0, 110.0, 0.50 }, .{ 2600.0, 180.0, 0.12 }, .{ 0.0, 0.0, 0.0 } }, // ah
            .{ .{ 320.0, 70.0, 1.0 }, .{ 800.0, 100.0, 0.30 }, .{ 2300.0, 160.0, 0.06 }, .{ 0.0, 0.0, 0.0 } }, // oo
        };
        const vowels = if (self.speaker) for_speaker else for_headphones;
        for (&self.voices, 0..) |*voice, which| {
            var a1: [4]f32 = @splat(0.0);
            var a2: [4]f32 = @splat(0.0);
            var g: [4]f32 = @splat(0.0);
            for (0..4) |i| {
                if (vowels[which][i][2] == 0.0) continue;
                const r = @exp(-std.math.pi * vowels[which][i][1] / rate);
                a1[i] = 2.0 * r * @cos(2.0 * std.math.pi * vowels[which][i][0] / rate);
                a2[i] = -(r * r);
                g[i] = vowels[which][i][2] * (1.0 - r);
            }
            voice.a1 = a1;
            voice.a2 = a2;
            voice.gain = g;
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
                tone.family = cue.family;
            },
            .tempo => self.restretch(cue.gain),
            .strike => {
                const slot = self.next_thing % max_things;
                self.next_thing +%= 1;
                const rec = if (self.speaker) forSpeaker(recipe(cue.family), cue.hz) else recipe(cue.family);
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
                    const as = if (rec.rings_as[i] > 0.0) rec.rings_as[i] else rec.mult[i];
                    const ring = @max(0.05, cue.ring / @sqrt(@max(as, 0.5) * 2.0)) / self.pace;
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
                if (cue.own == own_hands) {
                    self.call_slot = slot;
                    self.call_serial = self.next_thing;
                    self.call_began = cue.at;
                }
                // a clap just after a call: the call was its first half, and stops
                if (cue.own == own_clap and self.call_slot != std.math.maxInt(u32) and self.next_thing -% self.call_serial < max_things and cue.at >= self.call_began and cue.at - self.call_began <= clap_chokes) {
                    self.choke(self.call_slot);
                    self.call_slot = std.math.maxInt(u32);
                    self.choked += 1;
                }
            },
        }
    }

    /// Render the next `out.len` samples (one channel). Cues due inside them start on their sample.
    pub fn render(self: *Sound, out: []f32) void {
        const want = @atomicLoad(u8, &self.speaker_wanted, .monotonic) != 0;
        if (want != self.speaker) {
            self.speaker = want;
            self.voicing();
        }
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
        if (cue.own == own_clap) {
            self.own_clap_at = at;
        } else if (cue.own == own_strike) {
            self.own_strike_at = at;
        } else switch (cue.kind) {
            .strike => self.own_call_at = at,
            .hum_on => self.own_on_at = at,
            .hum_off => self.own_off_at = at,
            .tone, .tempo => {},
        }
        var now = cue;
        now.at = at;
        self.apply(now);
        return at;
    }

    /// A thing stopped short, a hand on a ringing string: its burst ends and everything it rings
    /// dies away within a few milliseconds, its notes unchanged.
    fn choke(self: *Sound, slot: usize) void {
        self.things[slot].left = 0;
        const r_new: V = @splat(@exp(-6.91 / (0.012 * rate)));
        inline for (0..2) |half| {
            const g = slot * 2 + half;
            const r = @sqrt(@max(-self.a2[g], @as(V, @splat(0.0))));
            const live = r > @as(V, @splat(1e-6));
            const safe = @select(f32, live, r, @as(V, @splat(1.0)));
            const c = self.a1[g] / (safe * @as(V, @splat(2.0)));
            self.a1[g] = @select(f32, live, @as(V, @splat(2.0)) * r_new * c, self.a1[g]);
            self.a2[g] = @select(f32, live, -(r_new * r_new), self.a2[g]);
        }
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
        const slot = switch (cue.own) {
            own_hands => switch (cue.kind) {
                .strike => &self.own_call_at,
                .hum_on => &self.own_on_at,
                .hum_off => &self.own_off_at,
                .tone, .tempo => return false,
            },
            own_clap => &self.own_clap_at,
            own_strike => &self.own_strike_at,
            else => return false,
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
                // its overtones as the speaker or headphones are given them (heldParts): under the
                // speaker's floor a note is rebuilt from its own overtones, so the ear supplies it
                const held = heldParts(tone.family, tone.step * rate, self.speaker);
                for (0..n) |i| {
                    tone.level += (tone.target - tone.level) * 0.0004;
                    tone.phase += tone.step;
                    if (tone.phase >= 1.0) tone.phase -= 1.0;
                    var sum: f32 = 0.0;
                    for (0..held.n) |k| {
                        if (held.gain[k] == 0.0) continue;
                        var pk = tone.phase * held.mult[k];
                        pk -= @floor(pk);
                        sum += sineOfTurn(pk) * held.gain[k];
                    }
                    tones[i] += sum * tone.level;
                }
                if (tone.target == 0.0 and tone.level < 1e-6) {
                    tone.level = 0.0;
                    tone.phase = 0.0;
                }
            }

            for (0..n) |i| {
                const dry = ((acc[i][0] + acc[i][1]) + (acc[i][2] + acc[i][3])) + bus[i] + tones[i];
                // what the speaker cannot sound, taken out (a two-pole high pass, Butterworth)
                const cut = cut_b0 * dry + cut_b1 * self.cut_x1 + cut_b2 * self.cut_x2 - cut_a1 * self.cut_y1 - cut_a2 * self.cut_y2;
                self.cut_x2 = self.cut_x1;
                self.cut_x1 = dry;
                self.cut_y2 = self.cut_y1;
                self.cut_y1 = if (@abs(cut) < 1e-20) 0.0 else cut;
                const s = if (self.speaker) self.cut_y1 else dry;
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
    var ratio: [2]f32 = undefined;
    // with headphones in, the chain's own physics in its full range; then on the speaker, where
    // Hum's breath is lifted toward the speaker's resonance and the third voice must still stand out
    for ([2]bool{ false, true }, 0..) |speaker, k| {
        snd.init();
        snd.setSpeaker(speaker);
        _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 0, .hz = low, .gain = 0.35 });
        snd.render(out);
        const alone = at(out[48000..], high - low);
        snd.init();
        snd.setSpeaker(speaker);
        _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 0, .hz = low, .gain = 0.35 });
        _ = snd.push(.{ .at = 0, .kind = .hum_on, .voice = 1, .hz = high, .gain = 0.35 });
        snd.render(out);
        const together = at(out[48000..], high - low);
        try std.testing.expect(together > 1e-5);
        ratio[k] = together / alone;
    }
    try std.testing.expect(ratio[0] > 8.0);
    try std.testing.expect(ratio[1] > 3.0);
}

test "a held tone is a clean sine at its note, and eases in and out" {
    var s: Sound = undefined;
    s.init();
    // with headphones in: the speaker would rebuild a note this low from its overtones
    s.setSpeaker(false);
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

test "the hands' clap sounds once and chokes the call begun just before it; a strike is never taken for a call" {
    const s = try std.testing.allocator.create(Sound);
    defer std.testing.allocator.destroy(s);
    s.* = .{};
    s.init();
    var out: [800]f32 = undefined;
    s.render(&out);
    // the hands start a call; the world tells the same call, and a strike, on the same sample
    const at = s.ownNow(.{ .at = 0, .kind = .strike, .family = .string, .own = own_hands, .hz = 261.63, .gain = 0.8, .ring = 0.35 });
    const call = s.call_slot;
    try std.testing.expect(s.push(.{ .at = at, .kind = .strike, .family = .fork, .own = own_only, .hz = 523.25, .gain = 0.6, .ring = 0.5 }));
    try std.testing.expect(s.push(.{ .at = at, .kind = .strike, .family = .string, .own = own_hands, .hz = 261.63, .gain = 0.8, .ring = 0.35 }));
    s.render(&out);
    // the call sounded once, the strike sounded too: two things
    try std.testing.expectEqual(@as(u32, 1), s.own_met);
    try std.testing.expectEqual(@as(u32, 2), s.next_thing);
    // forty milliseconds on, the clap: the call's thing dies away
    var more: [1120]f32 = undefined;
    s.render(&more);
    const energy = struct {
        fn of(snd: *const Sound, slot: usize) f32 {
            var e: f32 = 0.0;
            for (0..2) |half| {
                const y1 = snd.y1[slot * 2 + half];
                const y2 = snd.y2[slot * 2 + half];
                e += @reduce(.Add, y1 * y1 + y2 * y2);
            }
            return e;
        }
    };
    const before = energy.of(s, call);
    try std.testing.expect(before > 0.0);
    const clapped = s.ownNow(.{ .at = 0, .kind = .strike, .family = .bar, .own = own_clap, .hz = 1046.5, .gain = 0.7, .ring = 0.15 });
    var after_clap: [960]f32 = undefined;
    s.render(&after_clap);
    try std.testing.expect(energy.of(s, call) < before * 0.001);
    try std.testing.expectEqual(@as(u32, 1), s.choked);
    // and the world's clap, told on the hands' sample, is not sounded twice
    try std.testing.expect(s.push(.{ .at = clapped, .kind = .strike, .family = .bar, .own = own_clap, .hz = 1046.5, .gain = 0.7, .ring = 0.15 }));
    s.render(&out);
    try std.testing.expectEqual(@as(u32, 2), s.own_met);
    try std.testing.expectEqual(@as(u32, 3), s.next_thing);
}

test "a strike the hands timed sounds once, with its octave" {
    const s = try std.testing.allocator.create(Sound);
    defer std.testing.allocator.destroy(s);
    s.* = .{};
    s.init();
    var out: [800]f32 = undefined;
    s.render(&out);
    const at = s.ownNow(.{ .at = 0, .kind = .strike, .family = .fork_octave, .own = own_strike, .hz = 523.25, .gain = 0.6, .ring = 0.5 });
    try std.testing.expect(s.push(.{ .at = at, .kind = .strike, .family = .fork_octave, .own = own_strike, .hz = 523.25, .gain = 0.6, .ring = 0.5 }));
    s.render(&out);
    try std.testing.expectEqual(@as(u32, 1), s.own_met);
    try std.testing.expectEqual(@as(u32, 1), s.next_thing);
    // its octave rings as well as its note
    try std.testing.expect(recipe(.fork_octave).mult[1] == 2.0);
}

test "for the speaker a low note gives what it loses to its octave and twelfth, and keeps its energy" {
    // Hum's call at the garden's note: a string's first partial is under the floor
    const low = forSpeaker(recipe(.string), 261.63);
    const plain = recipe(.string);
    var before: f32 = 0.0;
    var after: f32 = 0.0;
    for (0..8) |i| {
        before += plain.gain[i] * plain.gain[i];
        after += low.gain[i] * low.gain[i];
    }
    try std.testing.expect(@abs(after - before) < 1e-4);
    try std.testing.expect(low.gain[0] < 0.5 * plain.gain[0]);
    try std.testing.expect(low.gain[1] > plain.gain[1]);
    // a pure fork under the floor grows an octave and a twelfth of its own
    const fork = forSpeaker(recipe(.fork), 261.63);
    var octave = false;
    var twelfth = false;
    for (0..8) |i| {
        if (@abs(fork.mult[i] - 2.0) < 0.01 and fork.gain[i] > 0.3) octave = true;
        if (@abs(fork.mult[i] - 3.0) < 0.01 and fork.gain[i] > 0.2) twelfth = true;
    }
    try std.testing.expect(octave and twelfth);
    // and from the floor up nothing changes
    const high = forSpeaker(recipe(.string), 523.25);
    for (0..8) |i| try std.testing.expectEqual(plain.gain[i], high.gain[i]);
}

test "with headphones in the sound has its full range, and back on the speaker it is shaped again" {
    const s = try std.testing.allocator.create(Sound);
    defer std.testing.allocator.destroy(s);
    s.* = .{};
    s.init();
    try std.testing.expect(s.speaker);
    const shaped = s.voices[0].gain;
    s.setSpeaker(false);
    var out: [128]f32 = undefined;
    s.render(&out);
    try std.testing.expect(!s.speaker);
    // Hum's mm has no fourth resonance for headphones, and its first at full strength
    try std.testing.expectEqual(@as(f32, 0.0), s.voices[0].gain[3]);
    try std.testing.expect(s.voices[0].gain[0] > shaped[0]);
    s.setSpeaker(true);
    s.render(&out);
    try std.testing.expect(s.speaker);
    try std.testing.expectEqual(shaped[3], s.voices[0].gain[3]);
}

test "on the speaker a low held tone is rebuilt from its octave and twelfth, its energy kept" {
    const at = struct {
        fn f(samples: []const f32, hz: f32) f32 {
            var re: f32 = 0.0;
            var im: f32 = 0.0;
            for (samples, 0..) |x, i| {
                const a = 2.0 * std.math.pi * hz * @as(f32, @floatFromInt(i)) / rate;
                re += x * @cos(a);
                im += x * @sin(a);
            }
            // a sine's size, from its share of the sum
            return 2.0 * @sqrt(re * re + im * im) / @as(f32, @floatFromInt(samples.len));
        }
    }.f;
    const s = try std.testing.allocator.create(Sound);
    defer std.testing.allocator.destroy(s);
    s.init();
    const c: f32 = 261.63;
    _ = s.push(.{ .at = 0, .kind = .tone, .voice = 3, .hz = c, .gain = 0.2 });
    const out = try std.testing.allocator.alloc(f32, 48000);
    defer std.testing.allocator.free(out);
    s.render(out);
    // 130 of its periods, so its overtones fall on whole cycles too
    const span = out[24000 .. 24000 + 23850];
    const note = at(span, c);
    const octave = at(span, 2.0 * c);
    const twelfth = at(span, 3.0 * c);
    try std.testing.expect(octave > note);
    try std.testing.expect(twelfth > 0.5 * note);
    const energy = note * note + octave * octave + twelfth * twelfth;
    try std.testing.expect(@abs(energy - 0.04) < 0.004);
}

test "a pipe stopped at one end sounds only its odd overtones, an octave under the same pipe open" {
    const at = struct {
        fn f(samples: []const f32, hz: f32) f32 {
            var re: f32 = 0.0;
            var im: f32 = 0.0;
            for (samples, 0..) |x, i| {
                const a = 2.0 * std.math.pi * hz * @as(f32, @floatFromInt(i)) / rate;
                re += x * @cos(a);
                im += x * @sin(a);
            }
            return 2.0 * @sqrt(re * re + im * im) / @as(f32, @floatFromInt(samples.len));
        }
    }.f;
    const s = try std.testing.allocator.create(Sound);
    defer std.testing.allocator.destroy(s);
    const out = try std.testing.allocator.alloc(f32, 48000);
    defer std.testing.allocator.free(out);
    // with headphones, the pipe's own sum in its full range: the open pipe at C3, the stopped at C2
    const open_hz: f32 = 130.8128;
    s.init();
    s.setSpeaker(false);
    _ = s.push(.{ .at = 0, .kind = .tone, .voice = 15, .family = .stopped_pipe, .hz = open_hz * 0.5, .gain = 0.3 });
    s.render(out);
    // thirty of the stopped note's periods, so every overtone falls on whole cycles
    const span = out[24000 .. 24000 + 22016];
    const f0 = open_hz * 0.5;
    try std.testing.expect(at(span, f0) > 0.2);
    try std.testing.expect(at(span, 3.0 * f0) > 0.06);
    // no even overtone: hollow
    try std.testing.expect(at(span, 2.0 * f0) < 0.01);
    try std.testing.expect(at(span, 4.0 * f0) < 0.01);
    // open: an octave up, and the even overtones come back
    s.init();
    s.setSpeaker(false);
    _ = s.push(.{ .at = 0, .kind = .tone, .voice = 15, .family = .open_pipe, .hz = open_hz, .gain = 0.3 });
    s.render(out);
    const span2 = out[24000 .. 24000 + 22016];
    try std.testing.expect(at(span2, open_hz) > 0.2);
    try std.testing.expect(at(span2, 2.0 * open_hz) > 0.1);
    try std.testing.expect(at(span2, f0) < 0.01);
    // and on the speaker the stopped pipe stays hollow: its octaves are not made up for it
    const sp = heldParts(.stopped_pipe, f0, true);
    for (0..sp.n) |k| try std.testing.expect(@mod(sp.mult[k] / sp.mult[0], 2.0) == 1.0);
}

test "on the speaker a pipe too low to be heard sounds two octaves up, whole, and stays an octave from itself opened" {
    const hz: f32 = 261.63 / 4.0;
    const stopped = heldParts(.stopped_pipe, hz, true);
    const open = heldParts(.open_pipe, hz * 2.0, true);
    // the stopped hose: hollow, its lowest partial the garden's own C, two octaves up
    for (0..stopped.n) |k| try std.testing.expectEqual(@as(f32, @floatFromInt(4 * (2 * k + 1))), stopped.mult[k]);
    // opened: an octave above that, with every overtone
    try std.testing.expectEqual(2.0 * hz * stopped.mult[0], hz * 2.0 * open.mult[0]);
    for (0..open.n) |k| try std.testing.expectEqual(@as(f32, @floatFromInt(4 * (k + 1))), open.mult[k]);
    // and no partial louder than the pipe has it
    const plain = heldParts(.stopped_pipe, hz, false);
    for (0..stopped.n) |k| try std.testing.expect(stopped.gain[k] <= plain.gain[k]);
}

test "on the speaker a stopped pipe it can nearly say stays hollow and in its own key: no partial piles up" {
    // A under the garden's C
    const hz: f32 = 220.0;
    const h = heldParts(.stopped_pipe, hz, true);
    const plain = heldParts(.stopped_pipe, hz, false);
    var energy_in: f32 = 0.0;
    var energy_out: f32 = 0.0;
    for (0..plain.n) |k| energy_in += plain.gain[k] * plain.gain[k];
    for (0..h.n) |k| energy_out += h.gain[k] * h.gain[k];
    // no louder than the pipe, as a partial under the floor is heard softer than its energy says
    try std.testing.expect(energy_out <= energy_in);
    // odd partials only; what the floor took goes to the fifth partial, and nothing above it rises
    for (0..h.n) |k| try std.testing.expectEqual(@as(f32, @floatFromInt(2 * k + 1)), h.mult[k]);
    try std.testing.expect(h.gain[2] > plain.gain[2]);
    for (3..h.n) |k| try std.testing.expectEqual(plain.gain[k], h.gain[k]);
}
