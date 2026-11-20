//! The land's tables, written by tools/score.py from scores/garden.txt: do not edit. Change the
//! score and build again (spec/engine.md, "Places and scores").

pub const Puddle = struct { x: f32, z: f32, shape: u8, note: f32 = 1.0 };
/// A knot's strand: its note over the land's, as a numerator and a denominator, and how many
/// times it pulses to the knot's cycle.
pub const Strand = struct { num: f32, den: f32, over: u8 };
pub const AsterRule = struct { across: f32, cells: u32, from: f32, jitter: f32, tall_least: f32, tall_more: f32, skip: u32, seed: u32 };

pub const note: f32 = 261.63;
pub const wake = [2]f32{ 0.0, 0.0 };
pub const great = [2]f32{ 0.0, -150.0 };
pub const great_tall: f32 = 172.0;
pub const clear = [2]f32{ -34.0, -52.0 };
pub const lake = [2]f32{ 1100.0, -2700.0 };
pub const aster_rule = AsterRule{ .across = 1200.0, .cells = 9, .from = 150.0, .jitter = 90.0, .tall_least = 92.0, .tall_more = 76.0, .skip = 11, .seed = 0x51ed270b };
pub const keep_wake: f32 = 45.0;
pub const keep_great: f32 = 60.0;
pub const keep_clear: f32 = 32.0;
pub const keep_puddle: f32 = 25.0;
pub const puddles = [_]Puddle{
    .{ .x = 175.0, .z = 215.0, .shape = 7 },
    .{ .x = -130.0, .z = 160.0, .shape = 1 },
    .{ .x = -10.0, .z = 360.0, .shape = 3 },
    .{ .x = 330.0, .z = 450.0, .shape = 4 },
    .{ .x = -230.0, .z = 330.0, .shape = 7, .note = 4.0 / 3.0 },
};
pub const knots = [_][2]f32{
    .{ -110.0, 440.0 },
    .{ -95.0, 455.0 },
    .{ -125.0, 458.0 },
};
pub const knot_root = [2]f32{ 2.0, 3.0 };
pub const knot_strands = [_]Strand{
    .{ .num = 1.0, .den = 1.0, .over = 3 },
    .{ .num = 5.0, .den = 3.0, .over = 5 },
};
