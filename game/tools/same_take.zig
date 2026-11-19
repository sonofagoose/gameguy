//! Does one take play out the same on every machine?
//!
//! Runs the world and the sound with no screen and no sound card, from the scripted hands, and
//! prints a fingerprint of each after every minute, with the loudest sample so far so that silence
//! can't pass for a match. Build it for two machines and compare the lines.
//!
//!   game/build.sh            builds it for the laptop and the handheld, and runs the laptop's
//!   build/same-take-x86_64 [minutes]
const std = @import("std");
const rules = @import("rules");
const world_mod = rules.world;
const sound_mod = rules.sound;

var world: world_mod.World = undefined;
var snd: sound_mod.Sound = undefined;

pub export fn main(argc: c_int, argv: [*][*:0]u8) c_int {
    var minutes: u32 = 10;
    if (argc > 1) minutes = std.fmt.parseInt(u32, std.mem.span(argv[1]), 10) catch 10;
    world = world_mod.World.init();
    snd.init();
    var script = rules.script.Script{};
    var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
    var buf: [world_mod.samples_per_step]f32 = undefined;
    var sound_print: u64 = 0xcbf29ce484222325;
    var loudest: f32 = 0.0;
    var cue_total: u64 = 0;
    var refused: u64 = 0;

    const steps: u64 = @as(u64, minutes) * 60 * world_mod.steps_per_second;
    var step: u64 = 0;
    while (step < steps) : (step += 1) {
        const n = world.stepOnce(script.hands(step), &cues);
        for (cues[0..n]) |cue| {
            if (!snd.push(cue)) refused += 1;
        }
        cue_total += n;
        snd.render(&buf);
        for (buf) |x| {
            sound_print ^= @as(u32, @bitCast(x));
            sound_print *%= 0x100000001b3;
            loudest = @max(loudest, @abs(x));
        }
        if ((step + 1) % (60 * world_mod.steps_per_second) == 0) {
            std.debug.print("minute {d:>2}: world {x:0>16}  sound {x:0>16}  loudest {d:.3}  calls {d}  answers {d}  cues {d}  late {d}  refused {d}\n", .{
                (step + 1) / (60 * world_mod.steps_per_second),
                world.fingerprint(),
                sound_print,
                loudest,
                world.calls,
                world.answers,
                cue_total,
                snd.late,
                refused + world.dropped,
            });
        }
    }
    return 0;
}
