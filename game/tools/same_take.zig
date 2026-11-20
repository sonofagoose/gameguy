//! Does one take play out the same on every machine? And what did the scripted player meet?
//!
//! Runs the world and the sound with no screen and no sound card, from the scripted hands, and
//! prints a fingerprint of each after every minute, with the loudest sample so far so that silence
//! can't pass for a match. Build it for two machines and compare the lines. Two takes: the dark,
//! for as many minutes as asked, and the walk to the great aster.
//!
//! It also prints what the promise book asks of the build (spec/promises.md): `fact` lines, which
//! are numbers the game reports about itself, and `witness` lines, one for each promise's moment
//! that the scripted player met by playing.
//!
//!   game/build.sh            builds it for the laptop and the handheld, and runs the laptop's
//!   build/same-take-x86_64 [minutes]
const std = @import("std");
const rules = @import("rules");
const world_mod = rules.world;
const sound_mod = rules.sound;

extern "c" fn fopen(path: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
extern "c" fn fwrite(ptr: [*]const u8, size: usize, count: usize, file: *anyopaque) usize;
extern "c" fn fclose(file: *anyopaque) c_int;

var walk_changes: [4096]rules.take.Change = undefined;
/// The world kept in the middle of the walk, to be opened again and played on to the end.
var middle_save: [rules.save.size]u8 = undefined;
const middle_step: u64 = 3 * 60 * world_mod.steps_per_second;
var walk_bytes: [rules.take.header_size + 4096 * rules.take.change_size]u8 = undefined;

// ------------------------------------------------------------------ ears
//
// Nobody building this can hear it. So the tool listens for them: it keeps stretches of the
// evening's sound and measures what a person would hear in them.

/// How much sound there is at one pitch in a stretch of samples, and its phase.
fn tone(samples: []const f32, hz: f64) struct { size: f64, phase: f64 } {
    var re: f64 = 0.0;
    var im: f64 = 0.0;
    const n: f64 = @floatFromInt(samples.len);
    for (samples, 0..) |sample, i| {
        // a raised-cosine window, so that neighbouring pitches don't leak in
        const t: f64 = @floatFromInt(i);
        const window = 0.5 - 0.5 * @cos(2.0 * std.math.pi * t / n);
        const a = 2.0 * std.math.pi * hz * t / 48000.0;
        re += sample * window * @cos(a);
        im -= sample * window * @sin(a);
    }
    return .{ .size = @sqrt(re * re + im * im) / n, .phase = std.math.atan2(im, re) };
}

/// The pitch of a steady voice near `near_hz`: how far the phase there moves between two
/// stretches a known time apart.
fn pitchNear(samples: []const f32, near_hz: f64) f64 {
    const span = 9600; // a fifth of a second
    const hop = 4800;
    if (samples.len < span + hop) return 0.0;
    var sum: f64 = 0.0;
    var count: f64 = 0.0;
    var at: usize = 2400;
    while (at + span + hop <= samples.len) : (at += hop) {
        const a = tone(samples[at..][0..span], near_hz);
        const b = tone(samples[at + hop ..][0..span], near_hz);
        var turn = b.phase - a.phase - 2.0 * std.math.pi * near_hz * @as(f64, hop) / 48000.0;
        while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
        while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
        sum += near_hz + turn * 48000.0 / (2.0 * std.math.pi * @as(f64, hop));
        count += 1.0;
    }
    return if (count > 0.0) sum / count else 0.0;
}

/// A stretch of sound kept to be listened to.
const Stretch = struct {
    samples: [48000 * 4]f32 = undefined,
    n: usize = 0,

    fn hear(self: *Stretch, buf: []const f32) void {
        const room = self.samples.len - self.n;
        const take_n = @min(room, buf.len);
        @memcpy(self.samples[self.n..][0..take_n], buf[0..take_n]);
        self.n += take_n;
    }
};
var breaths_heard: [4]Stretch = undefined;
var hold_heard: Stretch = undefined;
var quiet_heard: Stretch = undefined;
/// Hum humming at the bridge puddle's edge before the water has answered, and once it stands.
var pool_alone: Stretch = undefined;
var pool_standing: Stretch = undefined;

var world: world_mod.World = undefined;
var snd: sound_mod.Sound = undefined;

const Take = struct {
    sound_print: u64 = 0xcbf29ce484222325,
    loudest: f32 = 0.0,
    cue_total: u64 = 0,
    refused: u64 = 0,

    /// The samples of the step just made, for the ears.
    last: [world_mod.samples_per_step]f32 = undefined,

    fn step(self: *Take, hands: world_mod.Hands) void {
        var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
        const buf = &self.last;
        const n = world.stepOnce(hands, &cues);
        for (cues[0..n]) |cue| {
            if (!snd.push(cue)) self.refused += 1;
        }
        self.cue_total += n;
        snd.render(buf);
        for (buf) |x| {
            self.sound_print ^= @as(u32, @bitCast(x));
            self.sound_print *%= 0x100000001b3;
            self.loudest = @max(self.loudest, @abs(x));
        }
    }

    fn line(self: *const Take, label: []const u8, number: u64) void {
        std.debug.print("{s} {d:>2}: world {x:0>16}  sound {x:0>16}  loudest {d:.3}  calls {d}  answers {d}  cues {d}  late {d}  refused {d}\n", .{
            label,
            number,
            world.fingerprint(),
            self.sound_print,
            self.loudest,
            world.calls,
            world.answers,
            self.cue_total,
            snd.late,
            self.refused + world.dropped,
        });
    }
};

fn witnesses() void {
    for (world_mod.witness.names, 0..) |name, i| {
        const mark = world.seen.marks[i];
        if (mark.met) std.debug.print("witness {s} first={d} held={d}\n", .{ name, mark.first, mark.held });
    }
}

fn fact(key: []const u8, value: f64) void {
    std.debug.print("fact {s} {d:.3}\n", .{ key, value });
}

pub export fn main(argc: c_int, argv: [*][*:0]u8) c_int {
    var minutes: u32 = 10;
    if (argc > 1) minutes = std.fmt.parseInt(u32, std.mem.span(argv[1]), 10) catch 10;
    const per_minute: u64 = 60 * world_mod.steps_per_second;

    // the dark, from the scripted hands
    world = world_mod.World.init();
    snd.init();
    var script = rules.script.Script{};
    var dark = Take{};
    const steps: u64 = @as(u64, minutes) * per_minute;
    var step: u64 = 0;
    while (step < steps) : (step += 1) {
        dark.step(script.hands(step));
        if ((step + 1) % per_minute == 0) dark.line("minute", (step + 1) / per_minute);
    }
    witnesses();

    // the first evening and the walk to the great aster, by a player that plays by rules
    world.initEvening();
    snd.init();
    var bot = rules.walker.Walker{};
    var walk = Take{};
    var recorder = rules.take.Recorder{ .changes = &walk_changes };
    for (&breaths_heard) |*stretch| stretch.n = 0;
    hold_heard.n = 0;
    quiet_heard.n = 0;
    pool_alone.n = 0;
    pool_standing.n = 0;
    step = 0;
    while (step < 14 * per_minute and !bot.done) : (step += 1) {
        const hands = bot.hands(&world);
        recorder.note(step, hands);
        // which stretch of the evening this step belongs to, judged before it is made
        const breath_now: ?usize = if (world.drip_humming and world.locked_at == world_mod.never and world.breaths < 4) world.breaths else null;
        const holding = world.locked_at != world_mod.never and world.step > world.locked_at + 30 and world.step + 20 < world.hold_until;
        const quiet = world.step > 100 and world.step < 200;
        const at_pool = bot.phase == 10 and world.singing and world.pool_count > 0;
        const pool_quiet = at_pool and world.pools[0].loud() < 0.12;
        const pool_full = at_pool and world.pools[0].loud() > 0.97;
        if (world.step == middle_step) _ = rules.save.write(&world, &middle_save);
        walk.step(hands);
        if (pool_quiet) pool_alone.hear(&walk.last);
        if (pool_full) pool_standing.hear(&walk.last);
        if (breath_now) |b| breaths_heard[b].hear(&walk.last);
        if (holding) hold_heard.hear(&walk.last);
        if (quiet) quiet_heard.hear(&walk.last);
        if ((step + 1) % per_minute == 0) walk.line("evening minute", (step + 1) / per_minute);
    }
    walk.line("evening end, minute", step / per_minute + 1);
    witnesses();
    const walk_end = world.fingerprint();

    // the same walk, written down as a take and played back from its bytes alone
    const size = recorder.write(.evening, &walk_bytes);
    var same_again = false;
    if (rules.take.Player.open(walk_bytes[0..size])) |opened| {
        var player = opened;
        world.initEvening();
        snd.init();
        var back = Take{};
        var at: u64 = 0;
        while (!player.done(at)) : (at += 1) back.step(player.hands(at));
        same_again = world.fingerprint() == walk_end and back.sound_print == walk.sound_print;
    }
    // the world kept at minute three, opened again and played on by the same hands: the same end
    var same_end = false;
    if (rules.take.Player.open(walk_bytes[0..size])) |opened| {
        var player = opened;
        if (rules.save.read(&middle_save, &world)) |_| {
            var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
            var at: u64 = middle_step;
            while (!player.done(at)) : (at += 1) _ = world.stepOnce(player.hands(at), &cues);
            same_end = world.fingerprint() == walk_end;
        } else |_| {}
    }
    if (argc > 3) {
        if (fopen(argv[3], "wb")) |file| {
            _ = fwrite(&middle_save, 1, middle_save.len, file);
            _ = fclose(file);
        }
    }
    fact("save.bytes", @floatFromInt(rules.save.size));
    fact("save.middle_same_end", if (same_end) 1.0 else 0.0);
    fact("take.changes", @floatFromInt(recorder.count));
    fact("take.bytes", @floatFromInt(size));
    fact("take.replays_same", if (same_again) 1.0 else 0.0);
    if (argc > 2) {
        if (fopen(argv[2], "wb")) |file| {
            _ = fwrite(&walk_bytes, 1, size, file);
            _ = fclose(file);
        }
    }

    // what the game says of itself
    var tallest: f32 = 0.0;
    var shortest: f32 = 1e9;
    var bells: u32 = 0;
    for (world.towers[0..world.tower_count]) |tower| {
        tallest = @max(tallest, tower.tall);
        shortest = @min(shortest, tower.tall);
        bells += tower.count - world_mod.asters.segments;
    }
    const great = world.towers[0];
    fact("scale.one_to", world_mod.one_to);
    fact("scale.hum_tall_m", world_mod.hum_tall);
    fact("sound.speed_m_s", world_mod.sound_speed);
    fact("dark.first_backlight", world_mod.first_dark_backlight);
    fact("evening.breaths_to_lock", @floatFromInt(world_mod.breaths_to_lock));
    fact("evening.answered_s", @as(f64, @floatFromInt(world.answered_at)) / 60.0);
    fact("evening.locked_s", if (world.locked_at == world_mod.never) -1.0 else @as(f64, @floatFromInt(world.locked_at)) / 60.0);
    // what a person would hear. Drip's note, read back from the sound of each breath: how flat
    // of a true fifth it is, in hundredths of a semitone, and so how fast the two beat.
    const true_fifth: f64 = @as(f64, world_mod.garden_hz) * 1.5;
    for (0..4) |b| {
        var key: [40]u8 = undefined;
        const heard = pitchNear(breaths_heard[b].samples[0..breaths_heard[b].n], true_fifth);
        const flat = if (heard > 0.0) 1200.0 * @log2(heard / true_fifth) else 99.0;
        fact(std.fmt.bufPrint(&key, "ears.breath{d}_cents", .{b + 1}) catch "ears.breath", flat);
        fact(std.fmt.bufPrint(&key, "ears.breath{d}_beats", .{b + 1}) catch "ears.beats", if (heard > 0.0) @abs(3.0 * @as(f64, world_mod.garden_hz) - 2.0 * heard) else 99.0);
    }
    const held = pitchNear(hold_heard.samples[0..hold_heard.n], true_fifth);
    fact("ears.hold_cents", if (held > 0.0) 1200.0 * @log2(held / true_fifth) else 99.0);
    fact("ears.hold_beats", if (held > 0.0) @abs(3.0 * @as(f64, world_mod.garden_hz) - 2.0 * held) else 99.0);
    // the third note: the octave under Hum, which neither voice sings, while both hold; and in
    // a quiet stretch before they met
    const third_hz: f64 = @as(f64, world_mod.garden_hz) * 0.5;
    const third = tone(hold_heard.samples[0..@min(hold_heard.n, 48000)], third_hz).size;
    const before = tone(quiet_heard.samples[0..@min(quiet_heard.n, 48000)], third_hz).size;
    const hum_itself = tone(hold_heard.samples[0..@min(hold_heard.n, 48000)], world_mod.garden_hz).size;
    fact("ears.third_note_db_under_hum", if (third > 0.0 and hum_itself > 0.0) 20.0 * @log10(third / hum_itself) else -200.0);
    fact("ears.third_note_db_over_quiet", if (third > 0.0) 20.0 * @log10(third / @max(before, 1e-9)) else -200.0);
    // the bridge puddle sings Hum's note back: how much louder the note is once the water
    // stands, and how fast the two beat (nought, if the water sings the very note it is sung)
    const c4: f64 = world_mod.garden_hz;
    if (pool_alone.n > 4800 and pool_standing.n > 48000) {
        const alone = tone(pool_alone.samples[0..pool_alone.n], c4).size;
        const both = tone(pool_standing.samples[0..48000], c4).size;
        fact("ears.pool_adds_db", 20.0 * @log10(both / @max(alone, 1e-12)));
        fact("ears.pool_beats_hz", @abs(pitchNear(pool_standing.samples[0..pool_standing.n], c4) - c4));
        // and anything a little off the note, which would be heard as roughness: the strongest
        // pitch within a semitone either side, below the note itself
        var rough: f64 = 0.0;
        var cents: f64 = -100.0;
        while (cents <= 100.0) : (cents += 10.0) {
            if (@abs(cents) < 15.0) continue;
            rough = @max(rough, tone(pool_standing.samples[0..48000], c4 * std.math.pow(f64, 2.0, cents / 1200.0)).size);
        }
        fact("ears.pool_near_note_db", 20.0 * @log10(@max(rough, 1e-12) / @max(both, 1e-12)));
    } else {
        fact("ears.pool_adds_db", -200.0);
        fact("ears.pool_beats_hz", 99.0);
        fact("ears.pool_near_note_db", 0.0);
    }
    fact("evening.stood_s", if (world.stand_from == world_mod.never) -1.0 else @as(f64, @floatFromInt(world.stand_from)) / 60.0);
    fact("asters.count", @floatFromInt(world.tower_count));
    fact("asters.tallest_m", tallest);
    fact("asters.shortest_m", shortest);
    fact("asters.bells", @floatFromInt(bells));
    fact("asters.field_m", world_mod.asters.field_across);
    fact("asters.great_tall_m", great.tall);
    fact("asters.great_bells", @floatFromInt(great.count - world_mod.asters.segments));
    fact("asters.great_climb_s", great.tall / world_mod.sound_speed);
    fact("asters.walk_s", @as(f64, @floatFromInt(bot.arrived_at)) / 60.0);
    // walking at its foot, is the crown above the top of the screen? The eye is cam_back behind
    // Hum, who is at_foot from the stalk, and the frame's top edge is half the view above the gaze.
    const top_edge = world_mod.walk_pitch + world_mod.place_fov * 0.5 * std.math.pi / 180.0;
    const crown = std.math.atan2(great.tall * 0.74 - world_mod.cam_up, world_mod.at_foot + world_mod.cam_back);
    fact("asters.top_out_of_frame", if (crown > top_edge) 1.0 else 0.0);
    // leaned back with the gaze at the crown, how many dots across is the smallest bell?
    world.hum_x = great.x;
    world.hum_z = great.z + 9.0;
    world.look_yaw = 0.0;
    world.look_tilt = 0.0;
    world.near_tower = 0;
    world.near_far = 9.0;
    world.lean = 1.0;
    world.gaze = great.tall * 0.86;
    const cam = world.camera();
    const up_there = great.tall * 0.86 - cam.eye[1];
    const away = @sqrt(up_there * up_there + (9.0 + world_mod.lean_back) * (9.0 + world_mod.lean_back));
    fact("asters.leaned_fov", cam.fov);
    fact("asters.leaned_bell_px", 2.0 * 1.3 / away / (cam.fov * std.math.pi / 180.0) * 480.0);
    fact("asters.hum_px_walking", world_mod.hum_tall / world_mod.cam_back / (world_mod.place_fov * std.math.pi / 180.0) * 480.0);
    return 0;
}
