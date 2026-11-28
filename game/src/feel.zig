//! Feel: every number a hand, an eye or an ear will want changed, in one place (docs/engine.md,
//! "Feel in one table"). The bench shows these on the pause screen and lets Morgan set them live
//! while playing (ROADMAP.md, step 1.2).
//!
//! Compile-time constants remain for GPU vertex shaders (`rise_unit`, `part_*`) and as the exact
//! defaults of `Table`. Runtime gameplay and reaction loops read `now`, so default runs stay
//! bit-for-bit identical for `same-take` and all tests while live bench tweaks take effect at once.
const std = @import("std");

// ------------------------------------------------------------ how the world answers the chord

/// How fast a thing wakes when its colour comes into the chord, and how fast it rests when it
/// leaves: the part of the way it goes each step. A first guess: about a third of a second.
pub const wake_ease: f32 = 0.12;
/// A thing at rest is this bright against how bright it would be with no chord at all, and a
/// thing awake this bright; and awake it takes this much of its note's own colour.
pub const rest_bright: f32 = 0.6;
pub const wake_bright: f32 = 1.8;
pub const wake_hue: f32 = 0.75;

/// On the lift, what rises goes up this fast, and on the amen it comes down this softly: the part
/// of the way each step.
pub const rise_ease: f32 = 0.10;
pub const settle_ease: f32 = 0.045;
/// One step of a kind's "rises" measure is this many metres at the top of the rise. A fallen
/// leaf rises twelve of them.
pub const rise_unit: f32 = 0.2;
pub const leaf_rises: u4 = 12;

/// On the lean, what tilts leans toward home by this much sideways for each metre of its height,
/// for a kind that tilts wholly (fifteen of fifteen). A blade of grass does; a reed, a little.
pub const tilt_full: f32 = 0.26;
pub const blade_tilts: u4 = 15;
pub const reed_tilts: u4 = 1;
/// The lean winds up: held this many steps it has stored all it can, and tilts this much further.
pub const wind_steps: f32 = 150.0;
pub const wind_more: f32 = 0.45;
/// What tilts is on a spring: how hard it is drawn to where it should be, and how much of its
/// going it loses each step. And how hard the full close throws it back past upright.
pub const tilt_spring: f32 = 0.055;
pub const tilt_damp: f32 = 0.16;
pub const land_kick: f32 = 0.11;

// ------------------------------------------------------------ soft things parting (steps 0.6 & 0.7)

/// Thin soft grass blades bend out of Hum's path within `part_hum_reach` metres (pushing up to
/// `part_hum_push` m sideways), and out of the camera's line of sight within `part_sight_reach`
/// (pushing up to `part_sight_push` m sideways). Their roots stay planted at height 0 and reach
/// full flexibility by `part_flex_height`, drooping gently by `part_droop` of sideways bend.
pub const part_hum_reach: f32 = 2.4;
pub const part_hum_push: f32 = 1.65;
pub const part_sight_reach: f32 = 2.1;
pub const part_sight_push: f32 = 1.55;
pub const part_flex_height: f32 = 2.5;
pub const part_droop: f32 = 0.22;

// ------------------------------------------------------------ live bench table (ROADMAP step 1.2)

/// Every number the Pause/Start Bench can nudge live. Defaults match the compiled constants so
/// untouched runs keep exact `same-take` determinism.
pub const Table = struct {
    /// On the lift Hum is light: ground pull multiplier (try-out 0.55 vs design 2/3 = 0.667).
    lift_pull: f32 = 0.55,
    /// On the lean Hum is drawn forward: leg speed multiplier (try-out 1.30 vs design 4/3 = 1.333).
    lean_speed: f32 = 1.3,
    /// Metres thrown forward by a full close off a wound-up lean.
    launch_far: f32 = 6.0,
    /// Full-stick run speed (m/s) and sprint speed (m/s).
    run_speed: f32 = 12.0,
    sprint_speed: f32 = 20.0,
    /// Full held jump height (m).
    jump_height: f32 = 3.0,
    /// Camera speed-pullback easing per step (prevents rock-impact camera snap).
    view_run_ease: f32 = 0.08,

    /// World harmonic reaction timing and strength (law/react.zig).
    wake_ease: f32 = wake_ease,
    rise_ease: f32 = rise_ease,
    settle_ease: f32 = settle_ease,
    tilt_full: f32 = tilt_full,
    wind_more: f32 = wind_more,
    land_kick: f32 = land_kick,

    /// Hum's R2 vocal hold level (0.34 warm & balanced vs legacy 0.70).
    hum_volume: f32 = 0.34,
    /// Dynamic musical tempo mode: 1.0 = DYNAMIC (calm->peak energy arc), 0.0 = FIXED (`bpm`).
    tempo_dynamic: f32 = 1.0,
    /// Fixed tempo in BPM when `tempo_dynamic < 0.5` (72 default vs 90 snappy A/B).
    bpm: f32 = 72.0,
    /// Calm resting floor in BPM for DYNAMIC tempo mode.
    bpm_calm: f32 = 70.0,
    /// Peak sprint/jump/launch/combat ceiling in BPM for DYNAMIC tempo mode.
    bpm_peak: f32 = 120.0,
    /// Walking camera distance multiplier around the intimate TotK framing (1.0x vs 1.69x classic).
    cam_zoom: f32 = 1.0,
    /// Subtle right-shoulder camera offset in metres during 3D walking (0.42m TotK vs 0.0m center).
    cam_shoulder: f32 = 0.42,
};

pub const defaults = Table{};
pub var now: Table = defaults;

/// Restore every bench parameter to its exact default.
pub fn reset() void {
    now = defaults;
}

/// How many fields differ from `defaults`.
pub fn diffCount(t: Table) usize {
    var n: usize = 0;
    inline for (@typeInfo(Table).@"struct".field_names) |name| {
        if (@field(t, name) != @field(defaults, name)) n += 1;
    }
    return n;
}

pub fn isDefault(t: Table) bool {
    return diffCount(t) == 0;
}

/// Format only modified fields as `name=val ...` for the session log. Empty when all are default.
pub fn formatDiff(t: Table, out: []u8) []const u8 {
    var pos: usize = 0;
    inline for (@typeInfo(Table).@"struct".field_names) |name| {
        const cur = @field(t, name);
        const def = @field(defaults, name);
        if (cur != def) {
            const sep: []const u8 = if (pos > 0) " " else "";
            const piece = std.fmt.bufPrint(out[pos..], "{s}{s}={d:.3}", .{ sep, name, cur }) catch return out[0..pos];
            pos += piece.len;
        }
    }
    return out[0..pos];
}

test "feel defaults start unchanged, track diffs, and reset cleanly" {
    reset();
    try std.testing.expect(isDefault(now));
    try std.testing.expectEqual(@as(usize, 0), diffCount(now));
    now.lift_pull = 2.0 / 3.0;
    now.lean_speed = 4.0 / 3.0;
    try std.testing.expect(!isDefault(now));
    try std.testing.expectEqual(@as(usize, 2), diffCount(now));
    var buf: [256]u8 = undefined;
    const text = formatDiff(now, &buf);
    try std.testing.expect(std.mem.indexOf(u8, text, "lift_pull=0.667") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "lean_speed=1.333") != null);
    reset();
    try std.testing.expect(isDefault(now));
}
