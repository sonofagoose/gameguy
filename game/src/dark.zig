//! The scenes the workshop has: the dark and the call, and the proof field of asters.
//!
//! The dark: black. You call (R1) and a ring of light runs out over the ground. It lights what it
//! passes, and whatever is kin to your note answers, late by its distance. Hold R2 and Hum hums.
//!
//! The asters: the place, standing. Asters as tall as cathedrals (world/asters.zig), one to a
//! hundred. A call runs out over the ground and climbs every stalk it meets; the bells of a crown
//! are heard late by their height. Stand still at a foot and the view leans back.
//!
//! The loop here is the game's loop (spec/engine.md): the sound card's sample count is the only
//! clock, a step of the world is 800 samples, and each frame runs the steps that are due. With no
//! sound card (a run with no screen) the loop renders the sound itself, one step at a time.
const std = @import("std");
const plat = @import("plat/plat.zig");
const png = @import("plat/png.zig");
const lines = @import("draw/lines.zig");
const aster_lines = @import("draw/aster_lines.zig");
const colour = @import("draw/colour.zig");
const m = @import("m.zig");
const world_mod = @import("world/world.zig");
const sound_mod = @import("sound/sound.zig");
const Script = @import("bot/script.zig").Script;
const Walker = @import("bot/walker.zig").Walker;
const take = @import("keep/take.zig");
const Type = @import("room.zig").Type;
const c = plat.c;
const sdl = plat.sdl;
const gl = plat.gl;
const log = plat.log;

const World = world_mod.World;
const Hands = world_mod.Hands;

var snd: sound_mod.Sound = undefined;
var audio_channels: usize = 2;
var audio_realtime: i32 = -1;
var audio_slowest_us: u32 = 0;

fn audioCallback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.c) void {
    _ = userdata;
    const frames = @as(usize, @intCast(len)) / (@sizeOf(f32) * audio_channels);
    const out: [*]f32 = @ptrCast(@alignCast(stream));
    if (@atomicLoad(i32, &audio_realtime, .monotonic) < 0) {
        // 0 means "this thread": ahead of everything that is not real-time
        var param = std.mem.zeroes(c.struct_sched_param);
        param.sched_priority = 30;
        const granted = c.sched_setscheduler(0, c.SCHED_FIFO, &param) == 0;
        @atomicStore(i32, &audio_realtime, if (granted) 1 else 0, .monotonic);
    }
    const began = plat.now();
    var mono: [512]f32 = undefined;
    var done: usize = 0;
    while (done < frames) {
        const n = @min(mono.len, frames - done);
        snd.render(mono[0..n]);
        for (0..n) |i| {
            for (0..audio_channels) |ch| out[(done + i) * audio_channels + ch] = mono[i];
        }
        done += n;
    }
    const us: u32 = @intFromFloat(@min((plat.now() - began) * 1e6, 4e9));
    if (us > @atomicLoad(u32, &audio_slowest_us, .monotonic)) @atomicStore(u32, &audio_slowest_us, us, .monotonic);
}

fn openAudio() c.SDL_AudioDeviceID {
    var want = std.mem.zeroes(c.SDL_AudioSpec);
    want.freq = @intFromFloat(sound_mod.rate);
    want.format = c.AUDIO_F32SYS;
    want.channels = 2;
    want.samples = 128;
    want.callback = &audioCallback;
    var have = std.mem.zeroes(c.SDL_AudioSpec);
    const device = sdl.OpenAudioDevice(null, 0, &want, &have, c.SDL_AUDIO_ALLOW_SAMPLES_CHANGE | c.SDL_AUDIO_ALLOW_CHANNELS_CHANGE);
    if (device == 0) {
        log("sound: none ({s})", .{std.mem.span(sdl.GetError())});
        return 0;
    }
    audio_channels = have.channels;
    @atomicStore(i32, &audio_realtime, -1, .monotonic);
    @atomicStore(u32, &audio_slowest_us, 0, .monotonic);
    log("sound: {s}, {d} Hz, {d} channels, {d}-frame buffer ({d:.2} ms)", .{
        std.mem.span(sdl.GetCurrentAudioDriver()),
        have.freq,
        have.channels,
        have.samples,
        @as(f64, @floatFromInt(have.samples)) / @as(f64, @floatFromInt(have.freq)) * 1000.0,
    });
    sdl.PauseAudioDevice(device, 0);
    return device;
}

/// Mono 16-bit WAV, for listening to (or measuring) a run with no sound card.
const Wav = struct {
    file: *c.FILE,
    frames: u32 = 0,

    fn open(path: [*:0]const u8) ?Wav {
        const file = c.fopen(path, "wb") orelse return null;
        const blank: [44]u8 = @splat(0);
        _ = c.fwrite(&blank, 1, blank.len, file);
        return .{ .file = file };
    }

    fn write(self: *Wav, samples: []const f32) void {
        var block: [800]i16 = undefined;
        for (samples, 0..) |x, i| block[i] = @intFromFloat(std.math.clamp(x, -1.0, 1.0) * 32767.0);
        _ = c.fwrite(&block, 2, samples.len, self.file);
        self.frames += @intCast(samples.len);
    }

    fn close(self: *Wav) void {
        const data: u32 = self.frames * 2;
        var h: [44]u8 = undefined;
        @memcpy(h[0..4], "RIFF");
        std.mem.writeInt(u32, h[4..8], 36 + data, .little);
        @memcpy(h[8..16], "WAVEfmt ");
        std.mem.writeInt(u32, h[16..20], 16, .little);
        std.mem.writeInt(u16, h[20..22], 1, .little);
        std.mem.writeInt(u16, h[22..24], 1, .little);
        std.mem.writeInt(u32, h[24..28], 48000, .little);
        std.mem.writeInt(u32, h[28..32], 96000, .little);
        std.mem.writeInt(u16, h[32..34], 2, .little);
        std.mem.writeInt(u16, h[34..36], 16, .little);
        @memcpy(h[36..40], "data");
        std.mem.writeInt(u32, h[40..44], data, .little);
        _ = c.fseek(self.file, 0, c.SEEK_SET);
        _ = c.fwrite(&h, 1, h.len, self.file);
        _ = c.fclose(self.file);
    }
};

const Pad = struct {
    handle: ?*c.SDL_GameController = null,

    fn open() Pad {
        var pad = Pad{};
        const count = sdl.NumJoysticks();
        var i: c_int = 0;
        while (i < count) : (i += 1) {
            if (sdl.IsGameController(i) == c.SDL_FALSE) continue;
            pad.handle = sdl.GameControllerOpen(i);
            if (pad.handle != null) {
                log("controls: {s}", .{std.mem.span(sdl.GameControllerName(pad.handle))});
                break;
            }
        }
        if (pad.handle == null) log("controls: no game controller found ({d} joysticks)", .{count});
        return pad;
    }

    fn stick(handle: *c.SDL_GameController, which: c_int) i8 {
        const raw: i32 = sdl.GameControllerGetAxis(handle, which);
        return @intCast(std.math.clamp(@divTrunc(raw, 258), -127, 127));
    }

    fn read(self: *const Pad) Hands {
        const handle = self.handle orelse return .{};
        var h = Hands{
            .lx = stick(handle, c.SDL_CONTROLLER_AXIS_LEFTX),
            .ly = stick(handle, c.SDL_CONTROLLER_AXIS_LEFTY),
            .rx = stick(handle, c.SDL_CONTROLLER_AXIS_RIGHTX),
            .ry = stick(handle, c.SDL_CONTROLLER_AXIS_RIGHTY),
        };
        // Face buttons are named by position: SDL's A is the bottom one, whatever is printed on it.
        const map = [_]struct { sdl_button: c_int, bit: u16 }{
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_RIGHTSHOULDER, .bit = Hands.call },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_LEFTSHOULDER, .bit = Hands.voice },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_A, .bit = Hands.jump },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_B, .bit = Hands.dodge },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_X, .bit = Hands.strike },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_Y, .bit = Hands.grab },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_BACK, .bit = Hands.select },
            .{ .sdl_button = c.SDL_CONTROLLER_BUTTON_START, .bit = Hands.start },
        };
        for (map) |entry| {
            if (sdl.GameControllerGetButton(handle, entry.sdl_button) != 0) h.buttons |= entry.bit;
        }
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 16000) h.buttons |= Hands.sing;
        if (sdl.GameControllerGetAxis(handle, c.SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 16000) h.buttons |= Hands.guard;
        return h;
    }
};

fn noteColour(hz: f32) [3]f32 {
    return colour.ofNote(world_mod.garden_hz, hz);
}

fn col8(rgb: [3]f32, alpha: f32) [4]u8 {
    return .{
        @intFromFloat(std.math.clamp(rgb[0], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[1], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(rgb[2], 0.0, 1.0) * 255.0),
        @intFromFloat(std.math.clamp(alpha, 0.0, 1.0) * 255.0),
    };
}

const per_thing = 12;
const bone = [3]f32{ 0.886, 0.839, 0.784 };
/// Drip's colour (design/look.md).
const teal = [3]f32{ 0.25, 0.86, 0.80 };

/// What the first evening adds to the picture: Drip, the ripple that shows which way its answer
/// came from, and the figure between its voice and Hum's.
fn eveningLines(w: *const World, out: []lines.Inst) usize {
    if (w.drip == world_mod.no_thing) return 0;
    var n: usize = 0;
    const drip = w.things[w.drip];
    const drip_body: f32 = @floatFromInt(aster_lines.thing_body + w.drip);
    if (w.drip_met) {
        // riding on Hum's head: a drop 40 cm across, which never finished falling
        const rx = @cos(w.look_yaw);
        const rz = @sin(w.look_yaw);
        const tint = col8(teal, 0.95);
        for (0..8) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
            // round below, drawn up to a point above
            const s0 = @sin(a0);
            const s1 = @sin(a1);
            const narrow0: f32 = if (s0 > 0.0) 1.0 - 0.75 * s0 * s0 else 1.0;
            const narrow1: f32 = if (s1 > 0.0) 1.0 - 0.75 * s1 * s1 else 1.0;
            const tall0: f32 = if (s0 > 0.0) 1.7 else 1.0;
            const tall1: f32 = if (s1 > 0.0) 1.7 else 1.0;
            const r0 = 0.2 * narrow0;
            const r1 = 0.2 * narrow1;
            const y0 = 1.25 + 0.2 * s0 * tall0;
            const y1 = 1.25 + 0.2 * s1 * tall1;
            if (n >= out.len) return n;
            out[n] = .{ .a = .{ w.hum_x + rx * r0 * @cos(a0), y0, w.hum_z + rz * r0 * @cos(a0) }, .b = .{ w.hum_x + rx * r1 * @cos(a1), y1, w.hum_z + rz * r1 * @cos(a1) }, .half_width = 1.4, .body = 0.0, .col = tint };
            n += 1;
        }
        return n;
    }
    // out in the dark: a small ring on the ground that is only seen when it ticks or hums
    for (0..8) |k| {
        if (n >= out.len) return n;
        const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
        const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
        out[n] = .{ .a = .{ drip.x + 0.55 * @cos(a0), 0.05, drip.z + 0.55 * @sin(a0) }, .b = .{ drip.x + 0.55 * @cos(a1), 0.05, drip.z + 0.55 * @sin(a1) }, .half_width = 2.2, .body = drip_body, .col = col8(teal, 1.0) };
        n += 1;
    }
    const dx = drip.x - w.hum_x;
    const dz = drip.z - w.hum_z;
    const far = @sqrt(dx * dx + dz * dz);
    // the ripple: for two seconds after its answer arrives, arcs on the ground toward it
    if (w.answered and w.step - w.answered_at < 130 and far > 1.0) {
        const age = @as(f32, @floatFromInt(w.step - w.answered_at)) / 130.0;
        const way = std.math.atan2(dz, dx);
        for (0..3) |arc| {
            const r = 3.0 + 2.2 * @as(f32, @floatFromInt(arc)) + age * 2.0;
            const tint = col8(teal, (1.0 - age) * (0.9 - 0.2 * @as(f32, @floatFromInt(arc))));
            for (0..6) |k| {
                if (n >= out.len) return n;
                const a0 = way - 0.5 + @as(f32, @floatFromInt(k)) * (1.0 / 6.0);
                const a1 = a0 + 1.0 / 6.0;
                out[n] = .{ .a = .{ w.hum_x + r * @cos(a0), 0.05, w.hum_z + r * @sin(a0) }, .b = .{ w.hum_x + r * @cos(a1), 0.05, w.hum_z + r * @sin(a1) }, .half_width = 1.6, .body = 0.0, .col = tint };
                n += 1;
            }
        }
    }
    // the figure between the two voices: three lobes by two, because their notes are as three
    // to two, turning as fast as they beat. It lies on the ground between them.
    if (far < world_mod.beside * 2.0) {
        const held = w.drip_humming or w.step < w.hold_until;
        const locked = w.locked_at != world_mod.never;
        const k_true = @as(f32, @floatFromInt(w.breaths)) / @as(f32, world_mod.breaths_to_lock);
        const tint3 = [3]f32{ teal[0] + (bone[0] - teal[0]) * k_true, teal[1] + (bone[1] - teal[1]) * k_true, teal[2] + (bone[2] - teal[2]) * k_true };
        const shown: f32 = if (locked) 1.0 else if (held) 0.85 else 0.30;
        const tint = col8(tint3, shown);
        const cx = (drip.x + w.hum_x) * 0.5;
        const cz = (drip.z + w.hum_z) * 0.5;
        const r = @min(1.5, far * 0.40);
        const parts = 72;
        const heavy: f32 = if (locked) 2.0 else 1.5;
        for (0..parts) |k| {
            if (n >= out.len) return n;
            const t0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const t1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ cx + r * @sin(3.0 * t0 + w.figure_turn), 0.06, cz + r * @sin(2.0 * t0) },
                .b = .{ cx + r * @sin(3.0 * t1 + w.figure_turn), 0.06, cz + r * @sin(2.0 * t1) },
                .half_width = heavy,
                .body = 0.0,
                .col = tint,
            };
            n += 1;
        }
    }
    return n;
}

/// The dark's things: each a stalk, a ring for a head and three spokes. Its body number is its
/// place in the world's list plus one; body nought is always fully lit.
fn thingLines(w: *const World, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.things[0..w.thing_count], 0..) |thing, index| {
        const body: f32 = @floatFromInt(index + 1);
        const tint = col8(noteColour(thing.hz), 1.0);
        const r = 0.5 + 60.0 / thing.hz * 2.0; // lower notes have bigger heads
        const top = thing.tall;
        out[n] = .{ .a = .{ thing.x, 0.0, thing.z }, .b = .{ thing.x, top, thing.z }, .half_width = 1.3, .body = body, .col = tint };
        n += 1;
        for (0..8) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
            out[n] = .{
                .a = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z },
                .b = .{ thing.x + r * @cos(a1), top + r * @sin(a1), thing.z },
                .half_width = 1.4,
                .body = body,
                .col = tint,
            };
            n += 1;
        }
        for (0..3) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 3.0) + 0.5;
            out[n] = .{ .a = .{ thing.x, top, thing.z }, .b = .{ thing.x + r * @cos(a0), top + r * @sin(a0), thing.z }, .half_width = 1.1, .body = body, .col = tint };
            n += 1;
        }
    }
    return n;
}

/// What changes every frame: the rings on the ground, the band of light a call sends up each
/// stalk, and Hum.
fn movingLines(w: *const World, eye: m.V3, out: []lines.Inst) usize {
    var n: usize = 0;
    for (w.rings) |ring| {
        if (!ring.live) continue;
        const age: f32 = @floatFromInt(w.step - ring.born);
        const reach = age * world_mod.dt * world_mod.sound_speed;
        const fade = std.math.clamp(1.0 - reach / w.ring_reach, 0.0, 1.0);
        const tint = col8(if (ring.own) bone else teal, 0.85 * fade * fade);
        const parts = 64;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ ring.x + reach * @cos(a0), 0.05, ring.z + reach * @sin(a0) },
                .b = .{ ring.x + reach * @cos(a1), 0.05, ring.z + reach * @sin(a1) },
                .half_width = 1.5,
                .body = 0.0,
                .col = tint,
            };
            n += 1;
        }
        // the same call, climbing: where its sphere cuts each stalk
        for (w.towers[0..w.tower_count], 0..) |tower, t| {
            const dx = tower.x - ring.x;
            const dz = tower.z - ring.z;
            const flat2 = dx * dx + dz * dz;
            if (flat2 >= reach * reach) continue;
            const high = @sqrt(reach * reach - flat2);
            if (high > tower.tall) continue;
            const ex = tower.x - eye[0];
            const ez = tower.z - eye[2];
            if (ex * ex + ez * ez > aster_lines.mid_within * aster_lines.mid_within) continue;
            if (n + 8 > out.len) break;
            const at = aster_lines.mastAt(t, high);
            const band = col8(bone, 0.95 * @max(fade, 0.35));
            for (0..8) |k| {
                const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 8.0);
                const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 8.0);
                out[n] = .{
                    .a = .{ at[0] + 1.9 * @cos(a0), high, at[2] + 1.9 * @sin(a0) },
                    .b = .{ at[0] + 1.9 * @cos(a1), high, at[2] + 1.9 * @sin(a1) },
                    .half_width = 1.6,
                    .body = 0.0,
                    .col = band,
                };
                n += 1;
            }
        }
    }

    const hum_tint = col8(bone, 1.0);
    if (w.view == .place and w.stand < 0.5) {
        // on the page Hum is a mark like any other: a small ring, and a tick for where it faces
        for (0..10) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
            out[n] = .{
                .a = .{ w.hum_x + 0.9 * @cos(a0), 0.05, w.hum_z + 0.9 * @sin(a0) },
                .b = .{ w.hum_x + 0.9 * @cos(a1), 0.05, w.hum_z + 0.9 * @sin(a1) },
                .half_width = 2.2,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        out[n] = .{
            .a = .{ w.hum_x, 0.05, w.hum_z },
            .b = .{ w.hum_x + 1.6 * @sin(w.hum_face), 0.05, w.hum_z - 1.6 * @cos(w.hum_face) },
            .half_width = 1.6,
            .body = 0.0,
            .col = hum_tint,
        };
        n += 1;
    } else if (w.view == .page) {
        // seen from above: a small bone-white shape whose outline swells while it sings
        const size: f32 = if (w.singing) 0.75 else 0.5;
        for (0..10) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / 10.0);
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / 10.0);
            out[n] = .{
                .a = .{ w.hum_x + size * @cos(a0), 0.5 + size * @sin(a0), w.hum_z },
                .b = .{ w.hum_x + size * @cos(a1), 0.5 + size * @sin(a1), w.hum_z },
                .half_width = 1.8,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        out[n] = .{
            .a = .{ w.hum_x, 0.5, w.hum_z },
            .b = .{ w.hum_x + 0.9 * @sin(w.hum_face), 0.5, w.hum_z - 0.9 * @cos(w.hum_face) },
            .half_width = 1.2,
            .body = 0.0,
            .col = hum_tint,
        };
        n += 1;
    } else {
        // stood beside: one metre of bone-white, hatched so it reads as the one solid thing
        const swell: f32 = if (w.singing) 1.2 else 1.0;
        const rx = @cos(w.look_yaw);
        const rz = @sin(w.look_yaw);
        const wide = 0.36 * swell;
        const high = 0.5 * swell;
        const parts = 14;
        for (0..parts) |k| {
            const a0 = @as(f32, @floatFromInt(k)) * (6.2831853 / @as(f32, parts));
            const a1 = @as(f32, @floatFromInt(k + 1)) * (6.2831853 / @as(f32, parts));
            out[n] = .{
                .a = .{ w.hum_x + rx * wide * @cos(a0), 0.52 + high * @sin(a0), w.hum_z + rz * wide * @cos(a0) },
                .b = .{ w.hum_x + rx * wide * @cos(a1), 0.52 + high * @sin(a1), w.hum_z + rz * wide * @cos(a1) },
                .half_width = 1.9,
                .body = 0.0,
                .col = hum_tint,
            };
            n += 1;
        }
        // Hum's own light: it flares when Hum calls and holds while it sings
        const fill = col8(bone, 0.40 + 0.60 * w.hum_light);
        for (1..8) |k| {
            const f = @as(f32, @floatFromInt(k)) / 8.0 * 2.0 - 1.0;
            const across = wide * @sqrt(1.0 - f * f);
            out[n] = .{
                .a = .{ w.hum_x - rx * across, 0.52 + high * f, w.hum_z - rz * across },
                .b = .{ w.hum_x + rx * across, 0.52 + high * f, w.hum_z + rz * across },
                .half_width = 2.2,
                .body = 0.0,
                .col = fill,
            };
            n += 1;
        }
    }
    return n;
}

const backlight_path = "/sys/class/backlight/backlight/brightness";

/// The backlight is the sun: nearly off in the dark, up with whatever is shining.
const Backlight = struct {
    level: f32 = world_mod.first_dark_backlight,
    written: i32 = -1,

    fn follow(self: *Backlight, light: f32) void {
        const want = world_mod.first_dark_backlight + 150.0 * std.math.clamp(light, 0.0, 1.0);
        self.level += (want - self.level) * 0.12;
        const now: i32 = @intFromFloat(self.level);
        if (now == self.written) return;
        const file = c.fopen(backlight_path, "w") orelse return;
        var text: [8]u8 = undefined;
        const s = std.mem.printSentinel(&text, "{d}", .{now}, 0) catch return;
        _ = c.fputs(s.ptr, file);
        _ = c.fclose(file);
        self.written = now;
    }
};

// ------------------------------------------------------------------ the ground remembers
//
// One picture of the light that has been left on the ground (spec/size.md): wherever something
// sounds, it leaves its light beneath it in its note's colour. This is a first proof: one picture
// for the whole field, 62 cm to a dot, where the specification asks for one for each piece of
// land at 25 cm. It is kept in a file between sessions, so the ground still holds yesterday.
const ground_size = 2048;
const ground_from = [2]f32{ -640.0, -1090.0 };
const ground_span: f32 = 1280.0;
const ground_block = 64;
const ground_blocks = ground_size / ground_block;
const ground_file = "keep/asters-ground.rgb";
var ground: [ground_size * ground_size * 3]u8 = undefined;
var ground_dirty: [ground_blocks * ground_blocks]bool = @splat(false);
var ground_cursor: usize = 0;

/// Leave light on the ground round a point: `amount` of `rgb` at the middle, falling away.
fn leaveLight(x: f32, z: f32, radius: f32, rgb: [3]f32, amount: f32) void {
    const scale = @as(f32, ground_size) / ground_span;
    const cx = (x - ground_from[0]) * scale;
    const cz = (z - ground_from[1]) * scale;
    const r = @max(radius * scale, 1.0);
    const x0: i32 = @intFromFloat(@floor(cx - r * 1.6));
    const x1: i32 = @intFromFloat(@ceil(cx + r * 1.6));
    const z0: i32 = @intFromFloat(@floor(cz - r * 1.6));
    const z1: i32 = @intFromFloat(@ceil(cz + r * 1.6));
    var iz = @max(z0, 0);
    while (iz <= @min(z1, ground_size - 1)) : (iz += 1) {
        var ix = @max(x0, 0);
        while (ix <= @min(x1, ground_size - 1)) : (ix += 1) {
            const dx = (@as(f32, @floatFromInt(ix)) + 0.5 - cx) / r;
            const dz = (@as(f32, @floatFromInt(iz)) + 0.5 - cz) / r;
            // a soft round edge with no exponential in it: this runs for every dot of every light
            const edge = 1.0 - (dx * dx + dz * dz) * (1.0 / 2.56);
            if (edge <= 0.0) continue;
            const fall = edge * edge;
            const at: usize = @intCast((iz * ground_size + ix) * 3);
            for (0..3) |k| {
                const more = amount * fall * rgb[k] * 255.0;
                const now = @as(f32, @floatFromInt(ground[at + k])) + more;
                ground[at + k] = @intFromFloat(@min(now, 255.0));
            }
            ground_dirty[@intCast(@divTrunc(iz, ground_block) * ground_blocks + @divTrunc(ix, ground_block))] = true;
        }
    }
}

/// Send the GPU a few of the squares that have changed: never more than three a frame.
fn sendGround() void {
    var sent: u32 = 0;
    var looked: usize = 0;
    while (looked < ground_dirty.len and sent < 3) : (looked += 1) {
        const i = ground_cursor;
        ground_cursor = (ground_cursor + 1) % ground_dirty.len;
        if (!ground_dirty[i]) continue;
        ground_dirty[i] = false;
        const bx: i32 = @intCast(i % ground_blocks);
        const bz: i32 = @intCast(i / ground_blocks);
        renderer.updateGround(bx * ground_block, bz * ground_block, ground_block, ground_block, &ground);
        sent += 1;
        ground_cursor = i; // so that a square made dirty again at once is not a whole lap away
    }
}

fn loadGround() bool {
    const file = c.fopen(ground_file, "rb") orelse return false;
    defer _ = c.fclose(file);
    return c.fread(&ground, 1, ground.len, file) == ground.len;
}

fn saveGround() void {
    _ = c.mkdir("keep", 0o755);
    const file = c.fopen(ground_file ++ ".new", "wb") orelse return;
    const wrote = c.fwrite(&ground, 1, ground.len, file);
    _ = c.fclose(file);
    if (wrote == ground.len) _ = c.rename(ground_file ++ ".new", ground_file);
}

/// What sounded this step, and so what light it leaves: Hum where it walks, calls and hums, and
/// every bell that is ringing, on the ground beneath it.
fn groundStep(w: *const World, called: bool) void {
    const home = colour.ofNote(world_mod.garden_hz, world_mod.garden_hz);
    if (called) leaveLight(w.hum_x, w.hum_z, 4.5, home, 0.55);
    if (w.singing) leaveLight(w.hum_x, w.hum_z, 3.0, home, 0.0015);
    if (w.still == 0) leaveLight(w.hum_x, w.hum_z, 1.2, .{ 0.886, 0.839, 0.784 }, 0.016);
    // each ringing bell, one step in sixty-four, taken in turn: a crown of them ringing at once
    // must not cost a frame
    // the sky's rungs are last in the list, and their light is the day's, not left on the ground
    const land_end = if (w.rung_first == world_mod.no_thing) w.thing_count else w.rung_first;
    for (w.things[0..land_end], 0..) |thing, i| {
        if (!thing.sounds or thing.loud < 0.06 or (i + w.step) % 64 != 0) continue;
        leaveLight(thing.x, thing.z, 4.0 + thing.tall * 1.5, noteColour(thing.hz), thing.loud * 0.12);
    }
}

/// The dark: the first toy of a scene, kept for its long scripted take. The evening: the first
/// evening from its first second. The asters: the same place at dawn, already standing.
pub const Scene = enum { dark, evening, asters };

pub const Options = struct {
    scene: Scene = .dark,
    headless: bool = false,
    frames: u32 = 0,
    dump: ?[*:0]const u8 = null,
    dump_every: u32 = 30,
    wav: ?[*:0]const u8 = null,
    /// Real sound and the real clock, but the scripted hands: for measuring on the handheld.
    bot: bool = false,
    /// The promise a person was sent here to feel, from the room's walk.
    promise: ?[]const u8 = null,
    /// A take to play back in place of anyone's hands.
    replay: ?[*:0]const u8 = null,
};

/// What a person did on a visit from the room's walk.
pub const Visit = struct {
    /// Whether the world has a witness for the promise at all.
    witnessed: bool = false,
    met: bool = false,
    stayed_s: f32 = 0.0,
    calls: u32 = 0,
    seconds: f32 = 0.0,
};
pub var last_visit: Visit = .{};

var world: World = undefined;
var words: Type = undefined;
var renderer: lines.Renderer = undefined;
var renderer_ready = false;
var pixels: []u8 = &.{};
var static_lines: [36_000]lines.Inst = undefined;
/// Each body's share of its own light, by the total length of the lines it is drawn with.
var spread: [lines.max_bodies]f32 = @splat(1.0);
var body_len: [lines.max_bodies]f32 = @splat(0.0);
/// A thing whose lines add up to no more than this carries its whole light in each.
const spread_ref: f32 = 24.0;

/// A thing's own light is its loudness spread over all its lines (spec/texture.md).
fn spreadLight(insts: []const lines.Inst) void {
    @memset(&body_len, 0.0);
    for (insts) |inst| {
        const body: usize = @intFromFloat(inst.body);
        if (body < aster_lines.thing_body or body >= lines.max_bodies) continue;
        const dx = inst.b[0] - inst.a[0];
        const dy = inst.b[1] - inst.a[1];
        const dz = inst.b[2] - inst.a[2];
        body_len[body] += @sqrt(dx * dx + dy * dy + dz * dz);
    }
    for (&spread, body_len) |*s, len| s.* = if (len <= spread_ref) 1.0 else @max(0.06, spread_ref / len);
}

fn byte(v: f32) u8 {
    return @intFromFloat(std.math.clamp(v, 0.0, 1.0) * 255.0);
}

fn shine(sounding: f32, lit: f32, share: f32, gives: f32) lines.Shine {
    return .{ .sounding = byte(sounding), .lit = byte(lit), .spread = byte(share), .gives = byte(gives) };
}
var static_occ: [40_000][3]f32 = undefined;
var moving: [9_000]lines.Inst = undefined;
/// A person's hands, as they play: room for an hour of a thumb that never rests.
var take_changes: [216_000]take.Change = undefined;
var take_bytes: [take.header_size + 216_000 * take.change_size]u8 = undefined;

/// Write a person's take to the card: keep/takes/SCENE-NUMBER.take, the first number not used.
fn keepTake(recorder: *const take.Recorder, scene: Scene) void {
    if (recorder.count == 0) return;
    _ = c.mkdir("keep", 0o755);
    _ = c.mkdir("keep/takes", 0o755);
    var path: [96]u8 = undefined;
    var number: u32 = 1;
    while (number < 100_000) : (number += 1) {
        const p = std.mem.printSentinel(&path, "keep/takes/{s}-{d:0>5}.take", .{ @tagName(scene), number }, 0) catch return;
        if (c.access(p.ptr, 0) != 0) break;
    }
    const p = std.mem.printSentinel(&path, "keep/takes/{s}-{d:0>5}.take", .{ @tagName(scene), number }, 0) catch return;
    const size = recorder.write(switch (scene) {
        .dark => .dark,
        .evening => .evening,
        .asters => .asters,
    }, &take_bytes);
    const file = c.fopen(p.ptr, "wb") orelse return;
    const wrote = c.fwrite(&take_bytes, 1, size, file);
    _ = c.fclose(file);
    log("the take: {d} changes of the hands over {d} steps, {d} bytes, kept as {s}{s}", .{ recorder.count, recorder.steps, wrote, p, if (recorder.lost > 0) " (NOT WHOLE: it ran out of room)" else "" });
}

fn loadTake(path: [*:0]const u8) ?take.Player {
    const file = c.fopen(path, "rb") orelse return null;
    defer _ = c.fclose(file);
    const n = c.fread(&take_bytes, 1, take_bytes.len, file);
    return take.Player.open(take_bytes[0..n]);
}

fn dumpNamed(dir: [*:0]const u8, comptime fmt: []const u8, args: anytype) void {
    renderer.readFrame(pixels);
    var path: [512]u8 = undefined;
    var name: [128]u8 = undefined;
    const leaf = std.fmt.bufPrint(&name, fmt, args) catch return;
    if (std.mem.printSentinel(&path, "{s}/{s}.png", .{ std.mem.span(dir), leaf }, 0)) |text| {
        _ = png.writeFromGl(text.ptr, @intCast(renderer.fb_w), @intCast(renderer.fb_h), pixels);
    } else |_| {}
}

pub fn run(window: plat.Window, options: Options) bool {
    if (!renderer_ready) {
        if (!renderer.init(window.width, window.height)) return false;
        if (!words.init(window.width, window.height)) return false;
        const n: usize = @intCast(window.width * window.height * 4);
        const p: [*]u8 = @ptrCast(c.malloc(n) orelse return false);
        pixels = p[0..n];
        renderer_ready = true;
    }
    renderer.base = .{ 0.0, 0.0, 0.0 };
    const aspect = @as(f32, @floatFromInt(window.width)) / @as(f32, @floatFromInt(window.height));
    const name: []const u8 = @tagName(options.scene);
    var proj: m.M4 = undefined;
    switch (options.scene) {
        .dark => {
            world = World.init();
            renderer.keep = 0.82;
            renderer.stand = 1.0;
            renderer.fade = 70.0;
            renderer.far_floor = 0.12;
            renderer.heft = 0.0;
            renderer.sky = .{ 0.0, 0.0, 0.0 };
            proj = m.perspective(50.0, aspect, 0.3, 400.0);
            const static_n = thingLines(&world, &static_lines);
            renderer.setLand(static_lines[0..static_n], static_lines[0..0], &.{});
            renderer.setGround(0, .{ 0.0, 0.0 }, .{ 0.0, 0.0 }, null);
            log("the dark: R1 calls, R2 hums, the left stick walks; Select and Start together leave", .{});
        },
        .evening, .asters => {
            if (options.scene == .evening) world.initEvening() else world.initAsters();
            aster_lines.build(&world);
            renderer.keep = 0.55;
            renderer.fade = 70.0;
            renderer.far_floor = 0.05;
            renderer.heft = 0.55;
            renderer.sky = .{ 0.0, 0.0, 0.0 };
            proj = m.perspective(world_mod.place_fov, aspect, 0.4, 5000.0);
            // the ground starts black, or as it was left: a run with no screen always starts black,
            // so its frames are the same every time
            @memset(&ground, 0);
            const remembered = !options.headless and loadGround();
            @memset(&ground_dirty, false);
            // the square under Hum is sent again in the first frames, so the first real change
            // to the picture is not the first time this GPU is asked to change one
            ground_dirty[((0 - @as(i32, @intFromFloat(ground_from[1]))) * ground_size / @as(i32, @intFromFloat(ground_span)) / ground_block) * ground_blocks + ((0 - @as(i32, @intFromFloat(ground_from[0]))) * ground_size / @as(i32, @intFromFloat(ground_span)) / ground_block)] = true;
            renderer.setGround(ground_size, ground_from, .{ ground_from[0] + ground_span, ground_from[1] + ground_span }, &ground);
            log("the ground: {s}", .{if (remembered) "as it was left" else "black: nothing has been sung on it yet"});
            log("the {s}: {d} asters, {d} things; R1 calls (held, the place lies down), R2 hums, the left stick walks, the right stick looks; stand still at a foot and the gaze climbs; Select and Start together leave", .{ name, world.tower_count, world.thing_count });
        },
    }
    snd.init();
    var loud: [lines.max_bodies]lines.Shine = @splat(.{});
    loud[0] = .{ .lit = 255 };

    const device: c.SDL_AudioDeviceID = if (options.headless) 0 else openAudio();
    defer if (device != 0) sdl.CloseAudioDevice(device);
    var wav: ?Wav = if (options.wav) |path| Wav.open(path) else null;
    const pad = if (options.headless) Pad{} else Pad.open();
    var replay: ?take.Player = null;
    if (options.replay) |path| {
        replay = loadTake(path);
        if (replay) |r| {
            log("playing back a take: {d} steps, {d} changes of the hands", .{ r.steps, r.count });
        } else {
            log("that is not a take: {s}", .{std.mem.span(path)});
            return false;
        }
    }
    const scripted = options.headless or options.bot or replay != null;
    var recorder = take.Recorder{ .changes = &take_changes };
    var script = Script{};
    var walker = Walker{};
    var backlight = Backlight{};
    var cues: [world_mod.max_cues]sound_mod.Cue = undefined;
    var buf: [world_mod.samples_per_step]f32 = undefined;

    var frame: u32 = 0;
    var late: u32 = 0;
    var steps_run: u64 = 0;
    var double_steps: u32 = 0;
    var refused: u32 = 0;
    var leaving: u32 = 0;
    var work_sum: f64 = 0.0;
    var work_worst: f64 = 0.0;
    var last_swap = plat.now();
    var running = true;
    var picked_x: f32 = 1e9;
    var picked_z: f32 = 1e9;
    var picked = aster_lines.Picked{ .lines = 0, .occ = 0, .near = 0, .mid = 0, .far = 0 };
    var cover_grid = [2]i32{ 0, 0 };
    var most_lines: usize = 0;
    var worst_at: u32 = 0;
    var worst_step: u64 = 0;
    var worst_why: []const u8 = "";
    var repicked = false;
    var parts: [5]f64 = @splat(0.0);
    var worst_parts: [6]f64 = @splat(0.0);
    var ring_dumped = false;
    var done_at: ?u32 = null;

    while (running) : (frame += 1) {
        const began = plat.now();
        var event: c.SDL_Event = undefined;
        while (sdl.PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) running = false;
        }

        // the steps that are due
        var mark: ?[]const u8 = null;
        if (device == 0) {
            const hands = if (replay) |*r| r.hands(world.step) else if (options.scene != .dark) walker.hands(&world) else script.hands(world.step);
            if (replay == null) mark = walker.mark;
            if (replay) |*r| {
                if (r.done(world.step + 1)) running = false;
            }
            const calls_before = world.calls;
            const n = world.stepOnce(hands, &cues);
            if (options.scene != .dark) groundStep(&world, world.calls != calls_before);
            for (cues[0..n]) |cue| {
                if (!snd.push(cue)) refused += 1;
            }
            snd.render(&buf);
            if (wav) |*w| w.write(&buf);
            steps_run += 1;
        } else {
            const held = pad.read();
            if (held.held(Hands.select) and held.held(Hands.start)) leaving += 1 else leaving = 0;
            if (leaving > 30) running = false;
            const due = snd.played() / world_mod.samples_per_step;
            var ran: u32 = 0;
            while (world.step < due and ran < 3) : (ran += 1) {
                const hands = if (replay) |*r| r.hands(world.step) else if (!scripted) held else if (options.scene != .dark) walker.hands(&world) else script.hands(world.step);
                if (!scripted) recorder.note(world.step, hands);
                if (replay) |*r| {
                    if (r.done(world.step + 1)) running = false;
                }
                const calls_before = world.calls;
                const n = world.stepOnce(hands, &cues);
                if (options.scene != .dark) groundStep(&world, world.calls != calls_before);
                for (cues[0..n]) |cue| {
                    if (!snd.push(cue)) refused += 1;
                }
                steps_run += 1;
            }
            if (ran > 1) double_steps += 1;
        }
        if (scripted and options.scene != .dark and walker.done and done_at == null) done_at = frame;
        if (done_at) |at| {
            if (options.frames == 0 and frame > at + 30) running = false;
        }

        // the picture
        parts[0] = (plat.now() - began) * 1000.0;
        repicked = false;
        var eye: m.V3 = undefined;
        var view: m.M4 = undefined;
        var brightest: f32 = 0.0;
        if (options.scene == .dark) {
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                brightest = @max(brightest, World.light(thing));
                loud[i + 1] = shine(thing.loud, thing.lit * 0.55, 1.0, 1.0);
            }
            for (world.rings) |ring| {
                if (ring.live) brightest = @max(brightest, 0.5);
            }
            eye = .{ world.hum_x, 40.0, world.hum_z + 36.0 };
            view = m.lookAt(eye, .{ world.hum_x, 0.0, world.hum_z - 3.0 }, .{ 0.0, 1.0, 0.0 });
        } else {
            // A thing shines with its own sound, spread over its lines, and gives back the light
            // that falls on it: the day, once the dawn has reached it, or a passing call. In the
            // dark a silent thing is seen only when a call passes it (spec/texture.md).
            const sky_level = world.skyLevel();
            loud[1] = shine(0.0, sky_level, 1.0, 1.0);
            // before the dawn's edge reaches a place, the sky's own light falls on it faintly
            const twilight = 0.4 * sky_level;
            const rung_end = if (world.rung_first == world_mod.no_thing) 0 else world.rung_first + world_mod.rungs;
            for (world.things[0..world.thing_count], 0..) |thing, i| {
                const body = aster_lines.thing_body + i;
                if (i >= world.rung_first and i < rung_end) {
                    // the sky's rungs shine only with the sun's held overtones
                    loud[body] = shine(thing.loud, 0.0, 1.0, 0.0);
                    continue;
                }
                const day = @max(world.dayAt(thing.x, thing.z), twilight);
                const dim: f32 = if (thing.sounds) 0.30 else 0.26;
                const own: f32 = if (thing.sounds) thing.loud else 0.0;
                if (thing.sounds) brightest = @max(brightest, World.light(thing));
                loud[body] = shine(own, @max(dim * day, thing.lit * 0.55), spread[body], 0.9);
            }
            // the ground's cover, a square at a time: the day where the dawn has reached it, and
            // the edge of any ring crossing it, given back as its cover gives
            for (0..@as(usize, @intCast(aster_lines.cover_side * aster_lines.cover_side))) |cell| {
                const gx: f32 = @floatFromInt(@as(i32, @intCast(cell % @as(usize, @intCast(aster_lines.cover_side)))) + cover_grid[0]);
                const gz: f32 = @floatFromInt(@as(i32, @intCast(cell / @as(usize, @intCast(aster_lines.cover_side)))) + cover_grid[1]);
                const cx = (gx + 0.5) * 16.0;
                const cz = (gz + 0.5) * 16.0;
                var band: f32 = 0.0;
                for (world.rings) |ring| {
                    if (!ring.live) continue;
                    const dx = cx - ring.x;
                    const dz = cz - ring.z;
                    const behind = @as(f32, @floatFromInt(world.step - ring.born)) * world_mod.dt * world_mod.sound_speed - @sqrt(dx * dx + dz * dz);
                    if (behind < 0.0 or behind > 110.0) continue;
                    const fall = 1.0 - behind / 110.0;
                    band = @max(band, fall * fall);
                }
                loud[aster_lines.cover_body + cell] = shine(0.0, @max(world.dayAt(cx, cz), twilight) + band * 1.6, 1.0, aster_lines.coverGives(aster_lines.coverAt(cx, cz)));
            }
            const cam = world.camera();
            renderer.stand = cam.stand;
            eye = cam.eye;
            view = m.lookAt(cam.eye, cam.at, .{ 0.0, 1.0, 0.0 });
            proj = m.perspective(cam.fov, aspect, 0.4, 9000.0);
            const fx = @sin(world.look_yaw);
            const fz = -@cos(world.look_yaw);
            renderer.ground_eye = .{ eye[0], eye[2] };
            renderer.ground_look = .{ fx, fz };
            // where on the screen the horizon is, and where the sun will come up
            const dy = (cam.at[1] - cam.eye[1]) / 10.0;
            const pitch = std.math.asin(std.math.clamp(dy, -1.0, 1.0));
            const half = cam.fov * 0.5 * std.math.pi / 180.0;
            const sun_at = world.sunPlace();
            var turn: f32 = std.math.atan2(sun_at[0] - eye[0], -(sun_at[2] - eye[2])) - world.look_yaw;
            while (turn > std.math.pi) turn -= 2.0 * std.math.pi;
            while (turn < -std.math.pi) turn += 2.0 * std.math.pi;
            const across: f32 = if (@abs(turn) < 1.3) 0.5 + @tan(turn) / (2.0 * @tan(half) * aspect) else 9.0;
            renderer.dawn = .{ across, 0.5 - @tan(pitch) / (2.0 * @tan(half)) };
            const glow = [3]f32{ 0.16, 0.10, 0.075 };
            renderer.sky = .{ glow[0] * sky_level, glow[1] * sky_level, glow[2] * sky_level };
            // each aster at the detail its distance asks for, picked again every twenty metres
            const moved_x = eye[0] - picked_x;
            const moved_z = eye[2] - picked_z;
            if (moved_x * moved_x + moved_z * moved_z > 20.0 * 20.0) {
                picked = aster_lines.pick(world.hum_x, world.hum_z, static_lines[0..26_000], static_occ[0..24_000]);
                picked.lines += aster_lines.fallen(&world, static_lines[picked.lines..]);
                picked.lines += aster_lines.ground(world.hum_x, world.hum_z, static_lines[picked.lines..], &static_occ, &picked.occ, &cover_grid);
                picked.lines += aster_lines.horn(&world, static_lines[picked.lines..]);
                spreadLight(static_lines[0..picked.lines]);
                renderer.setLand(static_lines[0..picked.lines], static_lines[0..0], static_occ[0..picked.occ]);
                picked_x = eye[0];
                picked_z = eye[2];
                repicked = true;
            }
        }
        parts[1] = (plat.now() - began) * 1000.0;
        var moving_n: usize = 0;
        if (options.scene != .dark) {
            moving_n = aster_lines.sun(&world, eye, &moving);
            moving_n += aster_lines.stars(&world, eye, moving[moving_n..]);
            moving_n += aster_lines.dawnEdge(&world, moving[moving_n..]);
            if (world.stand > 0.6) moving_n += aster_lines.halos(&world, eye, moving[moving_n..]);
            moving_n += eveningLines(&world, moving[moving_n..]);
        }
        moving_n += movingLines(&world, eye, moving[moving_n..]);
        most_lines = @max(most_lines, picked.lines + moving_n);
        parts[2] = (plat.now() - began) * 1000.0;
        renderer.setDynamic(moving[0..moving_n]);
        if (options.scene != .dark) sendGround();
        const vp = m.mul(proj, view);
        parts[3] = (plat.now() - began) * 1000.0;
        renderer.frame(&vp, &loud);
        if (options.scene == .evening and world.step >= world.stand_from and world.step < world.stand_from + 330) {
            // the first words anyone says in it, as the page stands up: the one line of text
            const since: f32 = @floatFromInt(world.step - world.stand_from);
            const shown = std.math.clamp(@min(since / 40.0, (330.0 - since) / 70.0), 0.0, 1.0);
            const line = "Oh. You're in.";
            const scale: f32 = 2.6;
            const wide = @as(f32, @floatFromInt(line.len)) * 9.6 * scale;
            words.line((@as(f32, @floatFromInt(window.width)) - wide) * 0.5, @as(f32, @floatFromInt(window.height)) * 0.17, scale, .{ 0.886 * shown, 0.839 * shown, 0.784 * shown, shown }, line);
            words.flush();
        }
        parts[4] = (plat.now() - began) * 1000.0;
        // the backlight is the sun: down in the dark, where only what sounds is lit, and up with the day
        if (!options.headless) backlight.follow(if (options.scene == .dark) brightest else world.dawn * 0.38 + (0.25 + 0.37 * world.dawn) * brightest);
        const work = (plat.now() - began) * 1000.0;
        work_sum += work;
        if (frame > 30 and work > work_worst) {
            work_worst = work;
            worst_at = frame;
            worst_step = world.step;
            worst_why = if (repicked) "the land was picked again" else "nothing was picked";
            worst_parts = .{ parts[0], parts[1], parts[2], parts[3], parts[4], work };
        }

        if (options.dump) |dir| {
            if (options.promise == null) {
                if (options.dump_every > 0 and frame % options.dump_every == 0) dumpNamed(dir, "{s}-{d:0>5}", .{ name, frame });
                if (mark) |what| dumpNamed(dir, "promise-{s}-{s}", .{ name, what });
                if (options.scene == .dark and !ring_dumped) {
                    for (world.rings) |ring| {
                        // a ring just over half a second old: 36 m out, with what it passed lit and the rest dark
                        if (ring.live and world.step - ring.born == 36 and world.calls >= 2) {
                            dumpNamed(dir, "promise-dark-ring", .{});
                            ring_dumped = true;
                        }
                    }
                }
            }
        }
        sdl.GL_SwapWindow(window.handle);
        const swapped = plat.now();
        if (frame > 30 and (swapped - last_swap) * 1000.0 > 25.0) late += 1;
        last_swap = swapped;
        if (options.frames > 0 and frame + 1 >= options.frames) running = false;
    }

    if (wav) |*w| w.close();
    if (options.scene != .dark and !options.headless and !scripted) saveGround();
    if (!scripted) keepTake(&recorder, options.scene);
    last_visit = .{ .calls = world.calls, .seconds = @as(f32, @floatFromInt(world.step)) / 60.0 };
    if (options.promise) |promise| {
        if (world_mod.witness.Table.find(promise)) |id| {
            const seen = world.seen.get(id);
            last_visit.witnessed = true;
            last_visit.met = seen.met;
            last_visit.stayed_s = @as(f32, @floatFromInt(seen.held)) / 60.0;
        }
    }
    log("the {s}: {d} frames, {d} late, {d:.2} ms of work a frame (worst {d:.2}); {d} steps, {d} frames ran two; {d} calls, {d} answers; cues late {d}, refused {d}; slowest sound buffer {d:.2} ms; real-time sound {s}; most lines in a frame {d}", .{
        name,
        frame,
        late,
        work_sum / @as(f64, @floatFromInt(@max(frame, 1))),
        work_worst,
        steps_run,
        double_steps,
        world.calls,
        world.answers,
        snd.late,
        refused + world.dropped,
        @as(f64, @floatFromInt(@atomicLoad(u32, &audio_slowest_us, .monotonic))) / 1000.0,
        if (@atomicLoad(i32, &audio_realtime, .monotonic) == 1) "yes" else "no",
        most_lines,
    });
    log("the slowest frame was {d} (step {d}): steps done by {d:.2} ms, the land by {d:.2}, the moving lines by {d:.2}, sent to the GPU by {d:.2}, drawn by {d:.2}, the backlight set by {d:.2}; {s}", .{ worst_at, worst_step, worst_parts[0], worst_parts[1], worst_parts[2], worst_parts[3], worst_parts[4], worst_parts[5], worst_why });
    for (world_mod.witness.names, 0..) |promise, i| {
        const seen = world.seen.marks[i];
        if (seen.met) log("witness {s} first={d} held={d}", .{ promise, seen.first, seen.held });
    }
    return plat.checkGl("the scene");
}
