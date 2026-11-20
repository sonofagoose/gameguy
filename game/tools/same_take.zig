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
var walk_bytes: [rules.take.header_size + 4096 * rules.take.change_size]u8 = undefined;

var world: world_mod.World = undefined;
var snd: sound_mod.Sound = undefined;

const Take = struct {
    sound_print: u64 = 0xcbf29ce484222325,
    loudest: f32 = 0.0,
    cue_total: u64 = 0,
    refused: u64 = 0,

    fn step(self: *Take, hands: world_mod.Hands) void {
        var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
        var buf: [world_mod.samples_per_step]f32 = undefined;
        const n = world.stepOnce(hands, &cues);
        for (cues[0..n]) |cue| {
            if (!snd.push(cue)) self.refused += 1;
        }
        self.cue_total += n;
        snd.render(&buf);
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
    step = 0;
    while (step < 8 * per_minute and !bot.done) : (step += 1) {
        const hands = bot.hands(&world);
        recorder.note(step, hands);
        walk.step(hands);
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
