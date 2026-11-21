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
pub const clear = [2]f32{ 70.0, 22.0 };
pub const lake = [2]f32{ 1100.0, -2700.0 };
pub const aster_rule = AsterRule{ .across = 1560.0, .cells = 12, .from = 955.0, .jitter = 90.0, .tall_least = 92.0, .tall_more = 76.0, .skip = 11, .seed = 0x51ed270b };
pub const keep_wake: f32 = 45.0;
pub const keep_great: f32 = 60.0;
pub const keep_clear: f32 = 32.0;
pub const keep_puddle: f32 = 25.0;
pub const keep_pool: f32 = 10.0;
pub const keep_hose: f32 = 25.0;
pub const keep_spigot: f32 = 50.0;
/// The Mirror Pool: its middle, its radius, and the band of reeds round it.
pub const pool = [4]f32{ 0.0, 175.0, 150.0, 45.0 };
/// The bowl's rim: its middle and radius.
pub const rim = [3]f32{ 0.0, 175.0, 740.0 };
/// The bowl's ground: how far it rises from the pool to the rim, and the beds above that.
pub const bowl_depth: f32 = 0.0;
pub const bowl_beds: f32 = 0.0;
/// The spigot's rise: where, how high above the rim, how far across.
pub const rise = [4]f32{ 80.0, -560.0, 0.0, 130.0 };
/// The spigot: where, and how tall.
pub const spigot = [3]f32{ 80.0, -560.0, 10.0 };
/// The hose: the points its curve passes through, from the spigot to its end; its bore; how far
/// back from its end it is knotted.
pub const hose = [_][2]f32{
    .{ 80.0, -560.0 },
    .{ 250.0, -530.0 },
    .{ 450.0, -420.0 },
    .{ 590.0, -220.0 },
    .{ 640.0, 0.0 },
    .{ 520.0, 120.0 },
    .{ 380.0, 100.0 },
    .{ 260.0, 50.0 },
    .{ 150.0, 30.0 },
    .{ 70.0, 22.0 },
};
pub const hose_bore: f32 = 1.8;
pub const hose_knot: f32 = 300.0;
pub const puddles = [_]Puddle{
    .{ .x = -200.0, .z = -80.0, .shape = 7 },
    .{ .x = -320.0, .z = 60.0, .shape = 1 },
    .{ .x = -300.0, .z = 230.0, .shape = 3 },
    .{ .x = 360.0, .z = 300.0, .shape = 4 },
    .{ .x = 210.0, .z = -110.0, .shape = 7, .note = 4.0 / 3.0 },
};
pub const knots = [_][2]f32{
    .{ 0.0, 0.0 },
    .{ 15.0, 15.0 },
    .{ -15.0, 18.0 },
};
pub const knot_root = [2]f32{ 2.0, 3.0 };
pub const knot_strands = [_]Strand{
    .{ .num = 1.0, .den = 1.0, .over = 3 },
    .{ .num = 5.0, .den = 3.0, .over = 5 },
};
