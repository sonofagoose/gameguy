//! Every cue twice (SPEC.md, rule 8): anything that sounds is seen, and anything the player is
//! shown by light is heard.
//!
//! A cue is one thing happening, declared once, with its two faces. Its light is the sound's own
//! numbers put through one fixed mapping: the note is the colour, the loudness is the brightness,
//! the ring is how long it fades. `World.tell` is the only way anything in the world can make a
//! sound, and it takes a cue, so a sound with no light can't be made; and the light is put on the
//! thing in the same call that sends the sound on its way, so the two can't be mistimed: the
//! light is at the thing at once, and the sound reaches the ears when it has travelled.
const std = @import("std");
const sound = @import("../sound/sound.zig");

/// What is heard of it.
pub const Sound = struct {
    kind: sound.Cue.Kind,
    family: sound.Family = .bell,
    hz: f32,
    /// How hard, at the thing itself, 0 to 1.
    strength: f32,
    /// How long its lowest note rings, in seconds.
    ring: f32,
};

/// What is seen of it.
pub const Light = struct {
    /// Its colour is this note's, by fifths round the wheel.
    hz: f32,
    /// How bright, at the thing itself, 0 to 1.
    brightness: f32,
    /// How long it takes to fade, in seconds.
    fades: f32,
    shape: Shape,

    pub const Shape = enum {
        /// The thing itself shines, and a halo round it beats at its note.
        glow,
        /// A ring runs out over the ground and up whatever stands on it: a call.
        ring_on_the_ground,
        /// The singer swells: a held voice begins.
        swell,
        /// The singer settles: a held voice ends.
        dims,
    };
};

/// One thing the player is told. Neither field has a default, so there is no way to write one
/// with a sound and no light, or a light and no sound: it does not compile.
pub const Cue = struct {
    sound: Sound,
    light: Light,

    /// The one mapping from a sound to its light: the same note, as bright as it is loud (by
    /// the square root, which is how loudness and brightness are both felt), fading for as long
    /// as it rings.
    pub fn of(s: Sound, shape: Light.Shape) Cue {
        return .{ .sound = s, .light = .{ .hz = s.hz, .brightness = @sqrt(@max(s.strength, 0.0)), .fades = s.ring, .shape = shape } };
    }
};

test "a cue can't be made with a sound and no light, or a light and no sound" {
    // both fields must be given: neither has a default to fall back on
    const attrs = @typeInfo(Cue).@"struct".field_attrs;
    inline for (attrs) |attr| {
        try std.testing.expect(attr.default_value_ptr == null);
    }
    try std.testing.expectEqual(@as(usize, 2), attrs.len);
    // and the light is the sound's own numbers
    const c = Cue.of(.{ .kind = .strike, .hz = 392.0, .strength = 0.25, .ring = 3.0 }, .glow);
    try std.testing.expectEqual(c.sound.hz, c.light.hz);
    try std.testing.expectEqual(c.sound.ring, c.light.fades);
    try std.testing.expectEqual(@as(f32, 0.5), c.light.brightness);
}
