//! Feel: every number a hand, an eye or an ear will want changed, in one place (docs/engine.md,
//! "Feel in one table"). The bench will show these on the pause screen and let Morgan set them
//! (ROADMAP.md, step 1.2). Until then they are first guesses, each said to be one.
//!
//! Numbers that were in the rules before this file was begun are still where they were; they move
//! here as each part of the rules is taken up.

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
