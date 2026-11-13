//! Shared by every toy: the platform layer (SDL2 and OpenGL ES loaded at run time), a PNG
//! writer for frame dumps, the label font, and a heads-up layer for labels.
pub const platform = @import("platform.zig");
pub const png = @import("png.zig");
pub const font = @import("font.zig");
pub const hud = @import("hud.zig");
