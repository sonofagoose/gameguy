//! The music: the note, the wheel, the day, the chord and the change (docs/engine.md, "The note"
//! and "The harmony"). Pure arithmetic. It knows no world, no thing and no platform, and every
//! table in it has a test. `direction.zig` holds the arithmetic of the three design documents as
//! tests, so the design and the code cannot drift apart.
pub const note = @import("note.zig");
pub const wheel = @import("wheel.zig");
pub const chord = @import("chord.zig");
pub const key = @import("key.zig");
pub const change = @import("change.zig");

pub const Note = note.Note;
pub const Cell = wheel.Cell;
pub const Chord = chord.Chord;
pub const Voice = chord.Voice;
pub const Day = key.Day;
pub const Ring = key.Ring;
pub const Change = change.Change;

test {
    _ = note;
    _ = wheel;
    _ = chord;
    _ = key;
    _ = change;
    _ = @import("direction.zig");
}
