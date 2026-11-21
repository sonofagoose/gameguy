//! The platform: SDL2 and OpenGL ES, loaded at run time with dlopen. The binary links only libc,
//! so it runs on whatever SDL2 and GPU driver the handheld's firmware ships, and on the laptop.
//! Taken from toys/common/platform.zig, with what the game's renderer and loop need added.
const std = @import("std");
pub const c = @import("c");
const keys = @import("keys.zig");

fn SdlFn(comptime name: []const u8) type {
    return *const @TypeOf(@field(c, "SDL_" ++ name));
}

/// The SDL2 functions the toy calls. Each is `SDL_<name>`, filled in by `loadSdl`.
pub const sdl = struct {
    pub var Init: SdlFn("Init") = undefined;
    pub var SetHint: SdlFn("SetHint") = undefined;
    pub var Quit: SdlFn("Quit") = undefined;
    pub var GetError: SdlFn("GetError") = undefined;
    pub var GL_SetAttribute: SdlFn("GL_SetAttribute") = undefined;
    pub var GL_ResetAttributes: SdlFn("GL_ResetAttributes") = undefined;
    pub var CreateWindow: SdlFn("CreateWindow") = undefined;
    pub var DestroyWindow: SdlFn("DestroyWindow") = undefined;
    pub var GL_CreateContext: SdlFn("GL_CreateContext") = undefined;
    pub var GL_DeleteContext: SdlFn("GL_DeleteContext") = undefined;
    pub var GL_MakeCurrent: SdlFn("GL_MakeCurrent") = undefined;
    pub var GL_SetSwapInterval: SdlFn("GL_SetSwapInterval") = undefined;
    pub var GL_SwapWindow: SdlFn("GL_SwapWindow") = undefined;
    pub var GL_GetProcAddress: SdlFn("GL_GetProcAddress") = undefined;
    pub var GL_GetDrawableSize: SdlFn("GL_GetDrawableSize") = undefined;
    pub var GetDesktopDisplayMode: SdlFn("GetDesktopDisplayMode") = undefined;
    pub var ShowCursor: SdlFn("ShowCursor") = undefined;
    pub var PollEvent: SdlFn("PollEvent") = undefined;
    pub var GetKeyboardState: SdlFn("GetKeyboardState") = undefined;
    pub var OpenAudioDevice: SdlFn("OpenAudioDevice") = undefined;
    pub var PauseAudioDevice: SdlFn("PauseAudioDevice") = undefined;
    pub var CloseAudioDevice: SdlFn("CloseAudioDevice") = undefined;
    pub var GetCurrentAudioDriver: SdlFn("GetCurrentAudioDriver") = undefined;
    pub var GetCurrentVideoDriver: SdlFn("GetCurrentVideoDriver") = undefined;
    pub var NumJoysticks: SdlFn("NumJoysticks") = undefined;
    pub var IsGameController: SdlFn("IsGameController") = undefined;
    pub var GameControllerOpen: SdlFn("GameControllerOpen") = undefined;
    pub var GameControllerClose: SdlFn("GameControllerClose") = undefined;
    pub var GameControllerGetAttached: SdlFn("GameControllerGetAttached") = undefined;
    pub var GameControllerName: SdlFn("GameControllerName") = undefined;
    pub var GameControllerGetButton: SdlFn("GameControllerGetButton") = undefined;
    pub var GameControllerGetAxis: SdlFn("GameControllerGetAxis") = undefined;
    pub var GameControllerGetJoystick: SdlFn("GameControllerGetJoystick") = undefined;
    pub var JoystickName: SdlFn("JoystickName") = undefined;
    pub var JoystickGetButton: SdlFn("JoystickGetButton") = undefined;
    pub var JoystickNumButtons: SdlFn("JoystickNumButtons") = undefined;
    pub var GetTicks: SdlFn("GetTicks") = undefined;
    pub var Delay: SdlFn("Delay") = undefined;
    pub var GetNumDisplayModes: SdlFn("GetNumDisplayModes") = undefined;
    pub var GetDisplayMode: SdlFn("GetDisplayMode") = undefined;
    pub var SetWindowDisplayMode: SdlFn("SetWindowDisplayMode") = undefined;
    pub var SetWindowFullscreen: SdlFn("SetWindowFullscreen") = undefined;
    pub var GetWindowDisplayMode: SdlFn("GetWindowDisplayMode") = undefined;
};

fn GlFn(comptime name: []const u8) type {
    const upper = comptime blk: {
        var buf: [name.len]u8 = undefined;
        for (name, 0..) |ch, i| buf[i] = std.ascii.toUpper(ch);
        break :blk buf;
    };
    return @typeInfo(@field(c, "PFNGL" ++ upper ++ "PROC")).optional.child;
}

/// The OpenGL ES 3 functions the toy calls. Each is `gl<name>`, filled in by `openWindow`.
pub const gl = struct {
    pub var GetString: GlFn("GetString") = undefined;
    pub var GetError: GlFn("GetError") = undefined;
    pub var Viewport: GlFn("Viewport") = undefined;
    pub var ClearColor: GlFn("ClearColor") = undefined;
    pub var Clear: GlFn("Clear") = undefined;
    pub var Enable: GlFn("Enable") = undefined;
    pub var Disable: GlFn("Disable") = undefined;
    pub var BlendFunc: GlFn("BlendFunc") = undefined;
    pub var CreateShader: GlFn("CreateShader") = undefined;
    pub var ShaderSource: GlFn("ShaderSource") = undefined;
    pub var CompileShader: GlFn("CompileShader") = undefined;
    pub var GetShaderiv: GlFn("GetShaderiv") = undefined;
    pub var GetShaderInfoLog: GlFn("GetShaderInfoLog") = undefined;
    pub var CreateProgram: GlFn("CreateProgram") = undefined;
    pub var AttachShader: GlFn("AttachShader") = undefined;
    pub var BindAttribLocation: GlFn("BindAttribLocation") = undefined;
    pub var LinkProgram: GlFn("LinkProgram") = undefined;
    pub var GetProgramiv: GlFn("GetProgramiv") = undefined;
    pub var GetProgramInfoLog: GlFn("GetProgramInfoLog") = undefined;
    pub var DeleteShader: GlFn("DeleteShader") = undefined;
    pub var UseProgram: GlFn("UseProgram") = undefined;
    pub var GetUniformLocation: GlFn("GetUniformLocation") = undefined;
    pub var Uniform1i: GlFn("Uniform1i") = undefined;
    pub var Uniform1f: GlFn("Uniform1f") = undefined;
    pub var Uniform2f: GlFn("Uniform2f") = undefined;
    pub var Uniform3f: GlFn("Uniform3f") = undefined;
    pub var Uniform4f: GlFn("Uniform4f") = undefined;
    pub var Uniform4fv: GlFn("Uniform4fv") = undefined;
    pub var GenBuffers: GlFn("GenBuffers") = undefined;
    pub var BindBuffer: GlFn("BindBuffer") = undefined;
    pub var BufferData: GlFn("BufferData") = undefined;
    pub var VertexAttribPointer: GlFn("VertexAttribPointer") = undefined;
    pub var EnableVertexAttribArray: GlFn("EnableVertexAttribArray") = undefined;
    pub var DrawArrays: GlFn("DrawArrays") = undefined;
    pub var GenTextures: GlFn("GenTextures") = undefined;
    pub var BindTexture: GlFn("BindTexture") = undefined;
    pub var TexImage2D: GlFn("TexImage2D") = undefined;
    pub var TexParameteri: GlFn("TexParameteri") = undefined;
    pub var ActiveTexture: GlFn("ActiveTexture") = undefined;
    pub var PixelStorei: GlFn("PixelStorei") = undefined;
    pub var ReadPixels: GlFn("ReadPixels") = undefined;
    pub var Finish: GlFn("Finish") = undefined;
    pub var GenVertexArrays: GlFn("GenVertexArrays") = undefined;
    pub var BindVertexArray: GlFn("BindVertexArray") = undefined;
    pub var GenFramebuffers: GlFn("GenFramebuffers") = undefined;
    pub var BindFramebuffer: GlFn("BindFramebuffer") = undefined;
    pub var FramebufferTexture2D: GlFn("FramebufferTexture2D") = undefined;
    pub var CheckFramebufferStatus: GlFn("CheckFramebufferStatus") = undefined;
    // depth, culling and indexed drawing, for the 3D toys
    pub var GetIntegerv: GlFn("GetIntegerv") = undefined;
    pub var DepthFunc: GlFn("DepthFunc") = undefined;
    pub var DepthMask: GlFn("DepthMask") = undefined;
    pub var ClearDepthf: GlFn("ClearDepthf") = undefined;
    pub var CullFace: GlFn("CullFace") = undefined;
    pub var PolygonOffset: GlFn("PolygonOffset") = undefined;
    pub var DrawElements: GlFn("DrawElements") = undefined;
    pub var UniformMatrix4fv: GlFn("UniformMatrix4fv") = undefined;
    pub var Uniform3fv: GlFn("Uniform3fv") = undefined;
    pub var GenerateMipmap: GlFn("GenerateMipmap") = undefined;
    pub var GenRenderbuffers: GlFn("GenRenderbuffers") = undefined;
    pub var BindRenderbuffer: GlFn("BindRenderbuffer") = undefined;
    pub var RenderbufferStorage: GlFn("RenderbufferStorage") = undefined;
    pub var FramebufferRenderbuffer: GlFn("FramebufferRenderbuffer") = undefined;
    // instanced lines, tables sent each frame
    pub var VertexAttribDivisor: GlFn("VertexAttribDivisor") = undefined;
    pub var DrawArraysInstanced: GlFn("DrawArraysInstanced") = undefined;
    pub var BufferSubData: GlFn("BufferSubData") = undefined;
    pub var ColorMask: GlFn("ColorMask") = undefined;
    pub var TexSubImage2D: GlFn("TexSubImage2D") = undefined;
    pub var BlendEquation: GlFn("BlendEquation") = undefined;
};

/// Print to stdout (the launcher captures it) and to the session log, if one is open.
pub var log_file: ?*c.FILE = null;

pub fn log(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const text = std.mem.printSentinel(&buf, fmt ++ "\n", args, 0) catch return;
    _ = c.fputs(text.ptr, c.stdout);
    _ = c.fflush(c.stdout);
    if (log_file) |file| {
        _ = c.fputs(text.ptr, file);
        _ = c.fflush(file);
    }
}

/// Monotonic time in seconds.
pub fn now() f64 {
    var ts: c.struct_timespec = undefined;
    _ = c.clock_gettime(c.CLOCK_MONOTONIC, &ts);
    return @as(f64, @floatFromInt(ts.tv_sec)) + @as(f64, @floatFromInt(ts.tv_nsec)) * 1e-9;
}

pub fn loadSdl() bool {
    const flags = c.RTLD_NOW | c.RTLD_GLOBAL;
    const lib = c.dlopen("libSDL2-2.0.so.0", flags) orelse c.dlopen("libSDL2.so", flags) orelse {
        log("SDL2 not found: {s}", .{std.mem.span(c.dlerror())});
        return false;
    };
    inline for (@typeInfo(sdl).@"struct".decl_names) |name| {
        const symbol = c.dlsym(lib, "SDL_" ++ name) orelse {
            log("SDL2 is missing SDL_{s}", .{name});
            return false;
        };
        @field(sdl, name) = @ptrCast(@alignCast(symbol));
    }
    return true;
}

pub const Window = struct {
    handle: *c.SDL_Window,
    context: c.SDL_GLContext,
    width: i32,
    height: i32,
};

fn compileShader(kind: c.GLenum, source: [:0]const u8, name: []const u8) ?c.GLuint {
    const shader = gl.CreateShader(kind);
    var text: [*c]const u8 = source.ptr;
    gl.ShaderSource(shader, 1, &text, null);
    gl.CompileShader(shader);
    var ok: c.GLint = 0;
    gl.GetShaderiv(shader, c.GL_COMPILE_STATUS, &ok);
    if (ok == 0) {
        var info: [1024]u8 = @splat(0);
        gl.GetShaderInfoLog(shader, info.len - 1, null, &info);
        log("shader '{s}' ({s}) did not compile: {s}", .{ name, if (kind == c.GL_VERTEX_SHADER) "vertex" else "fragment", std.mem.sliceTo(&info, 0) });
        return null;
    }
    return shader;
}

/// Compile and link a program; logs the driver's message and returns null on failure.
pub fn linkProgram(vs_source: [:0]const u8, fs_source: [:0]const u8, name: []const u8) ?c.GLuint {
    const vs = compileShader(c.GL_VERTEX_SHADER, vs_source, name) orelse return null;
    const fs = compileShader(c.GL_FRAGMENT_SHADER, fs_source, name) orelse return null;
    const program = gl.CreateProgram();
    gl.AttachShader(program, vs);
    gl.AttachShader(program, fs);
    gl.LinkProgram(program);
    gl.DeleteShader(vs);
    gl.DeleteShader(fs);
    var ok: c.GLint = 0;
    gl.GetProgramiv(program, c.GL_LINK_STATUS, &ok);
    if (ok == 0) {
        var info: [1024]u8 = @splat(0);
        gl.GetProgramInfoLog(program, info.len - 1, null, &info);
        log("program '{s}' did not link: {s}", .{ name, std.mem.sliceTo(&info, 0) });
        return null;
    }
    return program;
}

/// Log and clear any pending OpenGL errors. True when there were none.
pub fn checkGl(where: []const u8) bool {
    var clean = true;
    for (0..8) |_| {
        const err = gl.GetError();
        if (err == c.GL_NO_ERROR) break;
        log("OpenGL error 0x{x} at {s}", .{ err, where });
        clean = false;
    }
    return clean;
}

pub const WindowOptions = struct {
    /// A 640x480 window instead of the whole screen.
    windowed: bool = false,
    /// The window that many times the handheld's screen, for playing on a laptop.
    scale: u8 = 1,
    /// Depth buffer bits (0: none).
    depth_bits: u8 = 0,
    /// Multisampling (0 or 1: none). Falls back to none if the driver refuses.
    samples: u8 = 0,
};

/// A full-screen (or 640x480 windowed) OpenGL ES 3 window, vsynced, with `gl` filled in.
pub fn openWindow(options: WindowOptions) ?Window {
    if (options.samples > 1) {
        if (openWindowWith(options)) |window| return window;
        log("no {d}x multisampled window ({s}); trying without", .{ options.samples, std.mem.span(sdl.GetError()) });
        var plain = options;
        plain.samples = 0;
        return openWindowWith(plain);
    }
    return openWindowWith(options);
}

fn openWindowWith(options: WindowOptions) ?Window {
    const windowed = options.windowed;
    var desktop: c.SDL_DisplayMode = undefined;
    const have_desktop = sdl.GetDesktopDisplayMode(0, &desktop) == 0;
    const width: c_int = if (!windowed and have_desktop and desktop.w > 0) desktop.w else 640 * @as(c_int, options.scale);
    const height: c_int = if (!windowed and have_desktop and desktop.h > 0) desktop.h else 480 * @as(c_int, options.scale);

    sdl.GL_ResetAttributes();
    _ = sdl.GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_ES);
    _ = sdl.GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = sdl.GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 0);
    _ = sdl.GL_SetAttribute(c.SDL_GL_RED_SIZE, 8);
    _ = sdl.GL_SetAttribute(c.SDL_GL_GREEN_SIZE, 8);
    _ = sdl.GL_SetAttribute(c.SDL_GL_BLUE_SIZE, 8);
    _ = sdl.GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, options.depth_bits);
    _ = sdl.GL_SetAttribute(c.SDL_GL_MULTISAMPLEBUFFERS, if (options.samples > 1) 1 else 0);
    _ = sdl.GL_SetAttribute(c.SDL_GL_MULTISAMPLESAMPLES, if (options.samples > 1) options.samples else 0);
    _ = sdl.GL_SetAttribute(c.SDL_GL_STENCIL_SIZE, 0);
    _ = sdl.GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);

    var flags: u32 = c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_SHOWN;
    if (!windowed) flags |= c.SDL_WINDOW_FULLSCREEN_DESKTOP;
    const handle = sdl.CreateWindow("gameguy", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, width, height, flags) orelse {
        if (options.samples <= 1) log("no window: {s}", .{std.mem.span(sdl.GetError())});
        return null;
    };
    const context = sdl.GL_CreateContext(handle);
    if (context == null) {
        if (options.samples <= 1) log("no OpenGL ES 3 context: {s}", .{std.mem.span(sdl.GetError())});
        sdl.DestroyWindow(handle);
        return null;
    }
    _ = sdl.GL_MakeCurrent(handle, context);
    _ = sdl.ShowCursor(c.SDL_DISABLE);
    // The panel offers 58.46 Hz (its default) and 60.02 Hz (docs/hardware-target.md). The world
    // steps sixty times a second, so at 60.02 a frame and a step nearly coincide (spec/engine.md).
    if (!windowed and have_desktop) {
        var best: ?c.SDL_DisplayMode = null;
        const n = sdl.GetNumDisplayModes(0);
        var m: c_int = 0;
        while (m < n) : (m += 1) {
            var mode: c.SDL_DisplayMode = undefined;
            if (sdl.GetDisplayMode(0, m, &mode) != 0) continue;
            if (mode.w != desktop.w or mode.h != desktop.h or mode.refresh_rate < 59 or mode.refresh_rate > 61) continue;
            // the nearest to sixty
            if (best == null or @abs(mode.refresh_rate - 60) < @abs(best.?.refresh_rate - 60)) best = mode;
        }
        if (best) |mode| {
            if (mode.refresh_rate != desktop.refresh_rate) {
                if (sdl.SetWindowDisplayMode(handle, &mode) == 0 and sdl.SetWindowFullscreen(handle, c.SDL_WINDOW_FULLSCREEN) == 0) {
                    log("display: switched from its {d} Hz mode to its {d} Hz mode", .{ desktop.refresh_rate, mode.refresh_rate });
                } else {
                    log("display: could not switch to its {d} Hz mode: {s}", .{ mode.refresh_rate, std.mem.span(sdl.GetError()) });
                }
            }
        }
    }
    _ = sdl.GL_SetSwapInterval(1);

    inline for (@typeInfo(gl).@"struct".decl_names) |name| {
        const symbol = sdl.GL_GetProcAddress("gl" ++ name) orelse {
            log("the GPU driver is missing gl{s}", .{name});
            return null;
        };
        @field(gl, name) = @ptrCast(@alignCast(symbol));
    }

    var w: c_int = 0;
    var h: c_int = 0;
    sdl.GL_GetDrawableSize(handle, &w, &h);
    log("video: {s}, {d}x{d}, {s} / {s}", .{
        std.mem.span(sdl.GetCurrentVideoDriver()),
        w,
        h,
        std.mem.span(@as([*:0]const u8, @ptrCast(gl.GetString(c.GL_RENDERER)))),
        std.mem.span(@as([*:0]const u8, @ptrCast(gl.GetString(c.GL_VERSION)))),
    });
    return .{ .handle = handle, .context = context, .width = w, .height = h };
}

/// The four face buttons, named by where they are on the handheld (SPEC.md, section 10), never by
/// what is printed on them.
pub const Face = enum(u2) { bottom, right, left, top };

/// Which of a joystick's own buttons each face button is.
///
/// The kernel names a gamepad's face buttons by where they sit: BTN_SOUTH (0x130) is the bottom
/// one, BTN_EAST (0x131) the right, BTN_NORTH (0x133) the top and BTN_WEST (0x134) the left,
/// whatever letters are printed on them. SDL numbers a joystick's buttons in the order of the
/// kernel's codes, from 0x120 up. So the joystick's list of codes in /proc/bus/input/devices says
/// which of its buttons is where. Controller databases don't agree: PortMaster's for the R36S's
/// "GO-Super Gamepad" names SDL's buttons after the printed letters (its "A" is the right button),
/// where SDL's own convention is by position (its "A" is the bottom one). Measured on the purple,
/// 2026-11-20: bottom 0, right 1, top 2, left 3.
pub const Faces = struct {
    raw: [4]i32 = .{ -1, -1, -1, -1 },
    joystick: ?*c.SDL_Joystick = null,

    pub fn find(handle: *c.SDL_GameController) Faces {
        var faces = Faces{};
        const joystick = sdl.GameControllerGetJoystick(handle) orelse return faces;
        faces.joystick = joystick;
        const name_ptr = sdl.JoystickName(joystick) orelse return faces;
        const name = std.mem.span(name_ptr);
        var buf: [32768]u8 = undefined;
        const file = c.fopen("/proc/bus/input/devices", "r") orelse return faces;
        const got = c.fread(&buf, 1, buf.len, file);
        _ = c.fclose(file);
        const codes = keys.keysOf(buf[0..got], name) orelse return faces;
        const wanted = [4]u32{ 0x130, 0x131, 0x134, 0x133 }; // bottom, right, left, top
        const count: i32 = sdl.JoystickNumButtons(joystick);
        for (wanted, 0..) |code, i| {
            if (!codes.has(code)) continue;
            // SDL counts the codes the joystick has from 0x120 up
            var index: i32 = 0;
            var k: u32 = 0x120;
            while (k < code) : (k += 1) {
                if (codes.has(k)) index += 1;
            }
            if (index < count) faces.raw[i] = index;
        }
        return faces;
    }

    pub fn down(self: Faces, handle: *c.SDL_GameController, which: Face) bool {
        const raw = self.raw[@intFromEnum(which)];
        if (self.joystick) |joystick| {
            if (raw >= 0) return sdl.JoystickGetButton(joystick, raw) != 0;
        }
        // nothing better known: SDL's own convention, which is by position
        const button: c_int = switch (which) {
            .bottom => c.SDL_CONTROLLER_BUTTON_A,
            .right => c.SDL_CONTROLLER_BUTTON_B,
            .left => c.SDL_CONTROLLER_BUTTON_X,
            .top => c.SDL_CONTROLLER_BUTTON_Y,
        };
        return sdl.GameControllerGetButton(handle, button) != 0;
    }

    /// For the session log.
    pub fn describe(self: Faces, out: []u8) []const u8 {
        if (self.raw[0] < 0 and self.raw[1] < 0) return "face buttons by SDL's own names";
        return std.fmt.bufPrint(out, "face buttons by the kernel's codes: bottom {d}, right {d}, left {d}, top {d}", .{ self.raw[0], self.raw[1], self.raw[2], self.raw[3] }) catch "face buttons by the kernel's codes";
    }
};
