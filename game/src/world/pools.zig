//! Pools (spec/laws.md, law 4; spec/world.md, the Garden's fourth wonder, "the puddle bridge").
//!
//! A puddle from the storm is a round skin of water. Hum near it, and whichever of its shapes has
//! a note among Hum's overtones builds up while Hum holds the note (law 7) and dies away when Hum
//! stops. A standing shape has still lines, spokes and rings where the water doesn't move, and
//! bellies between them that heave. The pollen on the water is thrown onto the still lines, as
//! sand on a sounding plate is, and stays there when the water stills, so a puddle keeps the
//! figure of the last note that stood in it. Hum is held on the still lines and thrown back off
//! the bellies; still water holds nothing, and floats Hum back to the shore. A bigger pool is
//! lower, so one note stands as a different figure in a pool of another size.
//!
//! No platforms: only sums that every machine agrees on.
const std = @import("std");

/// The shapes a round skin stands in, lowest first: `m` still spokes through the middle (as `m`
/// diameters) and `n - 1` still rings, at the `n`th zero `j` of the Bessel function of order `m`.
/// Every shape up to a little more than an octave above the eighth.
pub const Mode = struct { m: u8, n: u8, j: f32 };
pub const modes = [_]Mode{
    .{ .m = 0, .n = 1, .j = 2.40483 },
    .{ .m = 1, .n = 1, .j = 3.83171 },
    .{ .m = 2, .n = 1, .j = 5.13562 },
    .{ .m = 0, .n = 2, .j = 5.52008 },
    .{ .m = 3, .n = 1, .j = 6.38016 },
    .{ .m = 1, .n = 2, .j = 7.01559 },
    .{ .m = 4, .n = 1, .j = 7.58834 },
    .{ .m = 2, .n = 2, .j = 8.41724 },
    .{ .m = 0, .n = 3, .j = 8.65373 },
    .{ .m = 5, .n = 1, .j = 8.77148 },
    .{ .m = 3, .n = 2, .j = 9.76102 },
    .{ .m = 6, .n = 1, .j = 9.93611 },
    .{ .m = 1, .n = 3, .j = 10.17347 },
    .{ .m = 4, .n = 2, .j = 11.06471 },
    .{ .m = 7, .n = 1, .j = 11.08637 },
    .{ .m = 2, .n = 3, .j = 11.61984 },
    .{ .m = 0, .n = 4, .j = 11.79153 },
    .{ .m = 8, .n = 1, .j = 12.22509 },
    .{ .m = 5, .n = 2, .j = 12.33860 },
    .{ .m = 3, .n = 3, .j = 13.01520 },
    .{ .m = 1, .n = 4, .j = 13.32369 },
    .{ .m = 9, .n = 1, .j = 13.35430 },
    .{ .m = 6, .n = 2, .j = 13.58929 },
    .{ .m = 4, .n = 3, .j = 14.37254 },
    .{ .m = 10, .n = 1, .j = 14.47550 },
    .{ .m = 2, .n = 4, .j = 14.79595 },
    .{ .m = 7, .n = 2, .j = 14.82127 },
    .{ .m = 0, .n = 5, .j = 14.93092 },
    .{ .m = 11, .n = 1, .j = 15.58985 },
    .{ .m = 5, .n = 3, .j = 15.70017 },
    .{ .m = 8, .n = 2, .j = 16.03777 },
    .{ .m = 3, .n = 4, .j = 16.22347 },
    .{ .m = 1, .n = 5, .j = 16.47063 },
    .{ .m = 12, .n = 1, .j = 16.69825 },
    .{ .m = 6, .n = 3, .j = 17.00382 },
};

/// The zeros of the Bessel functions of orders 0 to 12, for the still rings: the rings of shape
/// (m, n) are at `zeros[m][i] / j` for i below n - 1. Worked out to sixty places and rounded.
pub const zeros = [13][6]f32{
    .{ 2.40483, 5.52008, 8.65373, 11.79153, 14.93092, 18.07106 },
    .{ 3.83171, 7.01559, 10.17347, 13.32369, 16.47063, 19.61586 },
    .{ 5.13562, 8.41724, 11.61984, 14.79595, 17.95982, 21.11700 },
    .{ 6.38016, 9.76102, 13.01520, 16.22347, 19.40942, 22.58273 },
    .{ 7.58834, 11.06471, 14.37254, 17.61597, 20.82693, 24.01902 },
    .{ 8.77148, 12.33860, 15.70017, 18.98013, 22.21780, 25.43034 },
    .{ 9.93611, 13.58929, 17.00382, 20.32079, 23.58608, 26.82015 },
    .{ 11.08637, 14.82127, 18.28758, 21.64154, 24.93493, 28.19119 },
    .{ 12.22509, 16.03777, 19.55454, 22.94517, 26.26681, 29.54566 },
    .{ 13.35430, 17.24122, 20.80705, 24.23389, 27.58375, 30.88538 },
    .{ 14.47550, 18.43346, 22.04699, 25.50945, 28.88738, 32.21186 },
    .{ 15.58985, 19.61597, 23.27585, 26.77332, 30.17906, 33.52636 },
    .{ 16.69825, 20.78991, 24.49489, 28.02671, 31.45996, 34.82999 },
};

/// The highest each Bessel function reaches (at its first crest), so every shape heaves to one at
/// its highest belly.
const peaks = [13]f32{ 1.0, 0.58187, 0.48650, 0.43439, 0.39965, 0.37409, 0.35414, 0.33793, 0.32438, 0.31280, 0.30274, 0.29388, 0.28599 };

/// One skin of water: a pool's lowest note times its radius, in hertz-metres. With it a puddle
/// 110 metres in radius stands in a ring and a cross on middle C. An estimate, to tune by eye and
/// by ear.
pub const skin_k: f32 = 8210.0;

/// How big a pool must be for `note` to stand in it as shape `shape`.
pub fn radiusFor(shape: usize, note: f32) f32 {
    return skin_k * modes[shape].j / (modes[0].j * note);
}

/// A puddle on a land's ground: where it is, and which shape it stands in for the note it is sized
/// for, as a part of the land's own note (one for the land's note itself).
pub const Puddle = struct { x: f32, z: f32, shape: u8, note: f32 = 1.0 };

/// The Garden's puddles from the storm, south of where Hum wakes. On the garden's note the first
/// stands as a ring and a cross, the second as one spoke (and as a cross with home on wonder), the
/// third as one ring with no way to it, and the fourth as three spokes. The fifth is sized for the
/// F a fifth below: silent to the garden's own note, it stands as a ring and a cross when home is
/// moved to wonder, whose law is standing waves (spec/laws.md, "Home over the laws").
pub const garden = blk: {
    // where they lie and what they are sized for comes from the Garden's score
    const land = @import("land.zig");
    var out: [land.puddles.len]Puddle = undefined;
    for (land.puddles, 0..) |p, k| out[k] = .{ .x = p.x, .z = p.z, .shape = p.shape, .note = p.note };
    break :blk out;
};

/// The overtones of Hum's closed "mm" on middle C, each against the first: measured from its vowel
/// (sound.zig, the resonances at 280, 1050 and 2300 hertz). Hum's hum is nearly a pure note.
pub const hum_overtones = [4]f32{ 1.0, 0.099, 0.025, 0.067 };

/// How near a note must come to a shape's to drive it: half as strongly this many cents off.
pub const width_cents: f32 = 10.0;
/// How fast a driven shape builds (a part of the way to full, each step: about a second and a
/// half), and how slowly a free one dies (about two and a half seconds to a third).
pub const build: f32 = 0.012;
pub const dies: f32 = 0.993355; // e to the minus one over 150: 2.5 seconds
/// The water holds Hum where it heaves less than this part of its highest, while it stands.
pub const hold_band: f32 = 0.12;
/// It stands, and holds, while its shapes together are at least this loud.
pub const stands_at: f32 = 0.25;
/// How hard a belly throws, as the part of the way to the still line covered each second, at
/// full loudness; and the fastest anything is thrown, metres a second.
pub const throw_rate: f32 = 2.5;
pub const throw_most: f32 = 7.0;
/// How fast still water floats Hum back to the shore, metres a second.
pub const float_speed: f32 = 2.5;
/// How fast Hum paddles in water that is not standing, at a full push of the stick: its legs do
/// little there, whatever its run.
pub const paddle: f32 = 1.2;
/// How high the bellies heave, in metres at full loudness, and how slowly they are shown heaving:
/// at the note eight octaves down, about once a second for middle C.
pub const heave_m: f32 = 5.0;
pub const heave_octaves: f32 = 256.0;

pub const max_motes = 420;
const radial_steps = 128;

/// One shape standing in a pool, with its radial part worked out once when it starts.
pub const Figure = struct {
    mode: u8 = 0,
    loud: f32 = 0.0,
    /// Which way its spokes lie: a belly is where the note came from.
    turn_c: f32 = 1.0,
    turn_s: f32 = 0.0,
    /// The note it is standing at, in hertz.
    hz: f32 = 0.0,
    driven: bool = false,
    radial: [radial_steps + 1]f32 = @splat(0.0),

    /// The shape at an offset from the pool's middle, as a part of its highest (from -1 to 1), and
    /// nought off the pool. Not yet times its loudness.
    pub fn shape(self: *const Figure, dx: f32, dz: f32, r: f32) f32 {
        const rho = @sqrt(dx * dx + dz * dz);
        const t = rho / r;
        if (t >= 1.0) return 0.0;
        const pos = t * @as(f32, radial_steps);
        const i: usize = @intFromFloat(@floor(pos));
        const f = pos - @floor(pos);
        const radial = self.radial[i] + (self.radial[i + 1] - self.radial[i]) * f;
        const m = modes[self.mode].m;
        if (m == 0) return radial;
        if (rho < 1e-4) return 0.0;
        // cos(m (angle - turn)), by turning a unit pointer m times: no angle is ever taken
        const cx = (dx * self.turn_c + dz * self.turn_s) / rho;
        const sx = (dz * self.turn_c - dx * self.turn_s) / rho;
        var pc: f32 = 1.0;
        var ps: f32 = 0.0;
        var k: u8 = 0;
        while (k < m) : (k += 1) {
            const nc = pc * cx - ps * sx;
            ps = pc * sx + ps * cx;
            pc = nc;
        }
        return radial * pc;
    }

    fn start(self: *Figure, mode: u8, dir_x: f32, dir_z: f32) void {
        self.mode = mode;
        self.loud = 0.0;
        const len = @sqrt(dir_x * dir_x + dir_z * dir_z);
        self.turn_c = if (len > 1e-4) dir_x / len else 1.0;
        self.turn_s = if (len > 1e-4) dir_z / len else 0.0;
        const md = modes[mode];
        for (0..radial_steps + 1) |i| {
            const x: f64 = @as(f64, md.j) * @as(f64, @floatFromInt(i)) / @as(f64, radial_steps);
            self.radial[i] = @floatCast(besselJ(md.m, x) / @as(f64, peaks[md.m]));
        }
        self.radial[radial_steps] = 0.0;
    }
};

pub const Pool = struct {
    x: f32 = 0.0,
    z: f32 = 0.0,
    r: f32 = 1.0,
    /// Its lowest note, the skin's first shape.
    hz: f32 = 0.0,
    /// Which thing of the world it is, so it shines as loud as it sounds.
    thing: u32 = 0,
    figs: [2]Figure = .{ .{}, .{} },
    /// The loudness each figure's tone was last sent at, so a change is sent and silence once.
    sent: [2]f32 = .{ 0.0, 0.0 },
    /// Pollen on the water: where each mote is, from the pool's middle, in metres.
    mote_x: [max_motes]f32 = undefined,
    mote_z: [max_motes]f32 = undefined,
    motes: u32 = 0,

    pub fn init(x: f32, z: f32, r: f32, thing: u32, seed: u32) Pool {
        var p = Pool{ .x = x, .z = z, .r = r, .hz = skin_k / r, .thing = thing };
        // a mote of pollen to every ninety square metres, scattered as it fell
        const area = std.math.pi * r * r;
        p.motes = @min(max_motes, @as(u32, @intFromFloat(area / 90.0)));
        var s: u32 = seed | 1;
        for (0..p.motes) |i| {
            s = xorshift(s);
            const u = @as(f32, @floatFromInt(s >> 8)) * (1.0 / 16777216.0);
            s = xorshift(s);
            const v = @as(f32, @floatFromInt(s >> 8)) * (1.0 / 16777216.0);
            const rr = r * 0.97 * @sqrt(u);
            const a = v * 6.2831853;
            p.mote_x[i] = rr * @cos(a);
            p.mote_z[i] = rr * @sin(a);
        }
        return p;
    }

    pub fn modeHz(self: *const Pool, k: usize) f32 {
        return self.hz * modes[k].j / modes[0].j;
    }

    /// Whether a place is on the water.
    pub fn holds(self: *const Pool, x: f32, z: f32) bool {
        const dx = x - self.x;
        const dz = z - self.z;
        return dx * dx + dz * dz < self.r * self.r;
    }

    /// How loud its shapes are together.
    pub fn loud(self: *const Pool) f32 {
        return self.figs[0].loud + self.figs[1].loud;
    }

    pub fn standing(self: *const Pool) bool {
        return self.loud() >= stands_at;
    }

    /// How much the water heaves at a place, as a part of its highest: the shapes add as powers,
    /// since they are at different notes.
    pub fn amp(self: *const Pool, x: f32, z: f32) f32 {
        const dx = x - self.x;
        const dz = z - self.z;
        var e: f32 = 0.0;
        for (&self.figs) |*f| {
            if (f.loud <= 0.0) continue;
            const s = f.shape(dx, dz, self.r) * f.loud;
            e += s * s;
        }
        return @sqrt(e);
    }

    /// The heave at a place and which way it rises fastest, by its slope over half a metre.
    pub fn ampSlope(self: *const Pool, x: f32, z: f32) [3]f32 {
        const e: f32 = 0.5;
        const gx = (self.amp(x + e, z) - self.amp(x - e, z)) / (2.0 * e);
        const gz = (self.amp(x, z + e) - self.amp(x, z - e)) / (2.0 * e);
        return .{ self.amp(x, z), gx, gz };
    }

    /// Which way, and how far this step, the water throws whatever is at a place: down the slope
    /// of its heaving to the still line, a part of the way each second, as hard as it is loud.
    pub fn throw(self: *const Pool, x: f32, z: f32, dt: f32) [2]f32 {
        const s = self.ampSlope(x, z);
        const slope = @sqrt(s[1] * s[1] + s[2] * s[2]);
        if (s[0] < 1e-5 or slope < 1e-6) return .{ 0.0, 0.0 };
        const to_line = s[0] / slope;
        const speed = @min(throw_rate * @min(self.loud(), 1.0) * to_line, throw_most);
        return .{ -s[1] / slope * speed * dt, -s[2] / slope * speed * dt };
    }

    /// One step of being sung to: `note` is what Hum is humming (nought for nothing), from
    /// (hx, hz). Whichever shapes have a note among Hum's overtones build; the rest die away.
    pub fn drive(self: *Pool, note: f32, hx: f32, hz_: f32, pace: f32) void {
        for (&self.figs) |*f| f.driven = false;
        if (note > 0.0) {
            const dx = hx - self.x;
            const dz = hz_ - self.z;
            const far = @sqrt(dx * dx + dz * dz);
            // heard at full strength anywhere on it or within ten metres of its edge
            const near = std.math.clamp(1.0 - (far - self.r - 10.0) / 30.0, 0.0, 1.0);
            if (near > 0.0) {
                // the two shapes most moved by Hum's overtones
                var best = [2]usize{ 0, 0 };
                var best_d = [2]f32{ 0.0, 0.0 };
                var best_h = [2]f32{ 0.0, 0.0 };
                for (modes, 0..) |_, k| {
                    const f = self.modeHz(k);
                    var d: f32 = 0.0;
                    var at_hz: f32 = 0.0;
                    for (hum_overtones, 0..) |w, h| {
                        const over = note * @as(f32, @floatFromInt(h + 1));
                        const c = 1200.0 * @log2(f / over);
                        const got = w / (1.0 + (c / width_cents) * (c / width_cents));
                        if (got > d) {
                            d = got;
                            at_hz = over;
                        }
                    }
                    d *= near;
                    if (d > best_d[0]) {
                        best_d[1] = best_d[0];
                        best[1] = best[0];
                        best_h[1] = best_h[0];
                        best_d[0] = d;
                        best[0] = k;
                        best_h[0] = at_hz;
                    } else if (d > best_d[1]) {
                        best_d[1] = d;
                        best[1] = k;
                        best_h[1] = at_hz;
                    }
                }
                for (0..2) |b| {
                    // a shape moved less than a twentieth of the way stays still
                    if (best_d[b] < 0.05) continue;
                    const k: u8 = @intCast(best[b]);
                    // already standing in this shape, or a new one in the quieter place
                    var slot: ?usize = null;
                    for (&self.figs, 0..) |*f, i| {
                        if (f.loud > 0.0 and f.mode == k) slot = i;
                    }
                    if (slot == null) {
                        const quiet: usize = if (self.figs[0].loud <= self.figs[1].loud) 0 else 1;
                        if (self.figs[quiet].driven) continue;
                        self.figs[quiet].start(k, dx, dz);
                        slot = quiet;
                    }
                    const f = &self.figs[slot.?];
                    f.driven = true;
                    f.hz = best_h[b];
                    f.loud += (best_d[b] - f.loud) * build * pace;
                }
            }
        }
        for (&self.figs) |*f| {
            if (f.driven or f.loud <= 0.0) continue;
            // free, it rings at its own note and dies away
            f.hz = self.modeHz(f.mode);
            f.loud *= 1.0 - (1.0 - dies) * pace;
            if (f.loud < 0.002) f.loud = 0.0;
        }
    }

    /// Struck by a sound passing over it, such as a call: the one shape with a note most among
    /// its overtones jumps, with a belly toward where the sound came from, and dies away at its
    /// own note.
    pub fn struck(self: *Pool, note: f32, overtones: []const f32, strength: f32, from_x: f32, from_z: f32) void {
        var best: usize = 0;
        var best_d: f32 = 0.0;
        for (modes, 0..) |_, k| {
            const f = self.modeHz(k);
            var d: f32 = 0.0;
            for (overtones, 0..) |w, h| {
                const c = 1200.0 * @log2(f / (note * @as(f32, @floatFromInt(h + 1))));
                d = @max(d, w / (1.0 + (c / width_cents) * (c / width_cents)));
            }
            if (d > best_d) {
                best_d = d;
                best = k;
            }
        }
        if (best_d < 0.05) return;
        var slot: ?usize = null;
        for (&self.figs, 0..) |*f, i| {
            if (f.loud > 0.0 and f.mode == best) slot = i;
        }
        if (slot == null) {
            const quiet: usize = if (self.figs[0].loud <= self.figs[1].loud) 0 else 1;
            if (self.figs[quiet].driven) return;
            self.figs[quiet].start(@intCast(best), from_x - self.x, from_z - self.z);
            self.figs[quiet].hz = self.modeHz(best);
            slot = quiet;
        }
        const f = &self.figs[slot.?];
        f.loud = @min(1.0, f.loud + best_d * strength);
    }

    /// The pollen is thrown toward the still lines while the water stands; on still water it
    /// stays where it was left. Whatever passes through it pushes it aside.
    pub fn stepMotes(self: *Pool, dt: f32, wade_x: f32, wade_z: f32) void {
        const moving = self.loud() > 0.004;
        const wx = wade_x - self.x;
        const wz = wade_z - self.z;
        if (!moving and wx * wx + wz * wz > (self.r + 2.0) * (self.r + 2.0)) return;
        for (0..self.motes) |i| {
            var mx = self.mote_x[i];
            var mz = self.mote_z[i];
            if (moving) {
                const t = self.throw(self.x + mx, self.z + mz, dt);
                mx += t[0];
                mz += t[1];
            }
            // a wake: pushed out of the way of whatever wades through
            const ax = mx - wx;
            const az = mz - wz;
            const d2 = ax * ax + az * az;
            if (d2 < 2.25 and d2 > 1e-6) {
                const d = @sqrt(d2);
                const push = (1.5 - d) * 0.25;
                mx += ax / d * push;
                mz += az / d * push;
            }
            // kept on the water
            const rr = @sqrt(mx * mx + mz * mz);
            const most = self.r * 0.995;
            if (rr > most) {
                mx *= most / rr;
                mz *= most / rr;
            }
            self.mote_x[i] = mx;
            self.mote_z[i] = mz;
        }
    }
};

fn xorshift(v: u32) u32 {
    var s = v;
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return s;
}

/// The Bessel function of the first kind of order `m`, by its series, in double precision so
/// that the terms' cancelling leaves enough for arguments up to about twenty.
pub fn besselJ(m: u32, x: f64) f64 {
    const half = x * 0.5;
    var top: f64 = 1.0; // (x/2)^m / m!
    var i: u32 = 1;
    while (i <= m) : (i += 1) top = top * half / @as(f64, @floatFromInt(i));
    var term = top;
    var sum = term;
    var k: u32 = 1;
    while (k < 60) : (k += 1) {
        term = -term * half * half / (@as(f64, @floatFromInt(k)) * @as(f64, @floatFromInt(k + m)));
        sum += term;
        if (@abs(term) < 1e-17) break;
    }
    return sum;
}

test "a round skin's still rings and spokes are where the Bessel functions are nought" {
    // the series is right: every zero in the table is a zero of it, and every shape's j is one
    // (the series holds to arguments of about twenty: every shape the table holds is below it)
    for (zeros, 0..) |row, m| {
        for (row) |j| {
            if (j < 17.2) try std.testing.expect(@abs(besselJ(@intCast(m), j)) < 3e-5);
        }
    }
    try std.testing.expect(modes[modes.len - 1].j < 17.2);
    for (modes) |md| try std.testing.expectEqual(md.j, zeros[md.m][md.n - 1]);
    // and the table is in order, lowest first, with every shape below its top
    for (modes[1..], 0..) |md, i| try std.testing.expect(md.j > modes[i].j);
    // the round skin in the sound has the same overtones as the water's shapes (spec/laws.md)
    const skin = @import("../sound/sound.zig").recipe(.skin);
    for (skin.mult, 0..) |mult, k| try std.testing.expect(@abs(mult - modes[k].j / modes[0].j) < 0.002);
}

test "a pool's figure is still on its spokes and rings, and heaves to one at its highest" {
    // a pool sized so middle C stands as a ring and a cross
    var p = Pool.init(0.0, 0.0, radiusFor(7, 261.63), 0, 7);
    try std.testing.expect(@abs(p.modeHz(7) - 261.63) < 0.01);
    var w: u32 = 0;
    // sung at from the west, until it stands
    while (w < 600) : (w += 1) p.drive(261.63, -p.r - 2.0, 0.0, 1.0);
    const f = &p.figs[0];
    try std.testing.expectEqual(@as(u8, 7), f.mode);
    try std.testing.expect(f.loud > 0.99);
    // a belly toward where it was sung from; the spokes at forty-five degrees to it
    try std.testing.expect(@abs(f.shape(-30.0, 0.0, p.r)) > 0.5);
    try std.testing.expect(@abs(f.shape(-30.0, 30.0, p.r)) < 1e-3);
    try std.testing.expect(@abs(f.shape(30.0, 30.0, p.r)) < 1e-3);
    // the ring, at 5.13562 / 8.41724 of the way out
    const ring = p.r * 5.13562 / 8.41724;
    try std.testing.expect(@abs(f.shape(-ring, 0.0, p.r)) < 2e-3);
    // nothing else on middle C moves it: Hum's octave is too far from any other shape
    try std.testing.expect(p.figs[1].loud < 0.02);
    // heaving to one at its highest, nowhere more
    var most: f32 = 0.0;
    var x: f32 = -p.r;
    while (x < p.r) : (x += 1.0) most = @max(most, @abs(f.shape(x, 0.0, p.r)));
    try std.testing.expect(most > 0.97 and most < 1.01);
}

test "pollen on a standing pool gathers on its still lines, and stays there when it stills" {
    var p = Pool.init(0.0, 0.0, radiusFor(7, 261.63), 0, 11);
    try std.testing.expect(p.motes > 300);
    var heaving_before: f32 = 0.0;
    for (0..p.motes) |i| heaving_before += p.figs[0].shape(p.mote_x[i], p.mote_z[i], p.r);
    var w: u32 = 0;
    while (w < 60 * 20) : (w += 1) {
        p.drive(261.63, -p.r - 2.0, 0.0, 1.0);
        p.stepMotes(1.0 / 60.0, 1e6, 1e6);
    }
    // after twenty seconds nine motes in ten are where the water heaves less than a tenth
    var on_lines: u32 = 0;
    for (0..p.motes) |i| {
        if (@abs(p.figs[0].shape(p.mote_x[i], p.mote_z[i], p.r)) < 0.1) on_lines += 1;
    }
    try std.testing.expect(on_lines * 10 >= p.motes * 9);
    // the note stops: the water stills and the pollen stays in the figure
    const kept_x = p.mote_x[17];
    w = 0;
    while (w < 60 * 30) : (w += 1) {
        p.drive(0.0, 0.0, 0.0, 1.0);
        p.stepMotes(1.0 / 60.0, 1e6, 1e6);
    }
    try std.testing.expect(p.loud() == 0.0);
    try std.testing.expect(@abs(p.mote_x[17] - kept_x) < 0.5);
}
