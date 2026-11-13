//! Drawing the meadow. Everything is lit per vertex and coloured from the vertices, so the
//! fragment shaders stay a few operations long: that is what lets a small GPU fill the screen
//! several times over. The only textures are two small noise tiles (ground grain, clouds).
const std = @import("std");
const common = @import("common");
const math = @import("math.zig");
const noise = @import("noise.zig");
const land = @import("land.zig");
const shapes = @import("mesh.zig");
const platform = common.platform;
const c = platform.c;
const gl = platform.gl;
const Vec3 = math.Vec3;
const Mat4 = math.Mat4;

// ------------------------------------------------------------------ light

/// Everything that changes with the hour.
pub const Palette = struct {
    zenith: [3]f32,
    horizon: [3]f32,
    haze: [3]f32,
    sun_color: [3]f32,
    sky_light: [3]f32,
    ground_light: [3]f32,
    cloud: [3]f32,
    water: [3]f32,
    /// Where haze begins, how far it takes to reach full strength, and that strength.
    haze_start: f32,
    haze_range: f32,
    haze_most: f32,
    /// How much petals, caps and eyes shine by their own light.
    glow: f32,

    pub fn blend(a: Palette, b: Palette, t: f32) Palette {
        var out: Palette = undefined;
        inline for (.{ "zenith", "horizon", "haze", "sun_color", "sky_light", "ground_light", "cloud", "water" }) |name| {
            const x = @field(a, name);
            const y = @field(b, name);
            @field(out, name) = .{ math.lerp(x[0], y[0], t), math.lerp(x[1], y[1], t), math.lerp(x[2], y[2], t) };
        }
        inline for (.{ "haze_start", "haze_range", "haze_most", "glow" }) |name| {
            @field(out, name) = math.lerp(@field(a, name), @field(b, name), t);
        }
        return out;
    }
};

/// The garden at noon.
pub const noon = Palette{
    .zenith = .{ 0.19, 0.46, 0.86 },
    .horizon = .{ 0.74, 0.88, 0.90 },
    .haze = .{ 0.70, 0.85, 0.83 },
    .sun_color = .{ 0.92, 0.84, 0.68 },
    .sky_light = .{ 0.42, 0.52, 0.62 },
    .ground_light = .{ 0.27, 0.31, 0.19 },
    .cloud = .{ 1.0, 1.0, 1.0 },
    .water = .{ 0.05, 0.21, 0.21 },
    .haze_start = 45.0,
    .haze_range = 520.0,
    .haze_most = 0.93,
    .glow = 0.0,
};

/// The same place at two in the morning: black is the field, and flowers earn their light.
pub const small_hours = Palette{
    .zenith = .{ 0.010, 0.010, 0.026 },
    .horizon = .{ 0.060, 0.050, 0.105 },
    .haze = .{ 0.040, 0.036, 0.070 },
    .sun_color = .{ 0.30, 0.32, 0.42 },
    .sky_light = .{ 0.050, 0.055, 0.090 },
    .ground_light = .{ 0.028, 0.028, 0.045 },
    .cloud = .{ 0.11, 0.10, 0.16 },
    .water = .{ 0.015, 0.025, 0.055 },
    .haze_start = 18.0,
    .haze_range = 280.0,
    .haze_most = 0.97,
    .glow = 1.0,
};

/// Direction toward the sun (and, at night, the moon).
pub const sun_dir = Vec3.init(-0.48, 0.60, -0.64).normalize();

// ------------------------------------------------------------------ shaders

const vertex_head =
    \\#version 300 es
    \\layout(location = 0) in vec3 a_pos;
    \\layout(location = 1) in vec4 a_normal;
    \\layout(location = 2) in vec4 a_color;
    \\layout(location = 3) in vec4 a_extra;
    \\uniform mat4 u_viewproj;
    \\uniform vec3 u_eye;
    \\uniform vec3 u_sun;
    \\uniform vec3 u_sun_color;
    \\uniform vec3 u_sky_light;
    \\uniform vec3 u_ground_light;
    \\uniform vec4 u_fog;   // start, 1/range, strongest, glow
    \\uniform vec4 u_wind;  // direction x, z; strength; time
    \\
;

const ground_vs = vertex_head ++
    \\out mediump vec3 v_color;
    \\out mediump float v_fog;
    \\out highp vec2 v_uv;
    \\void main() {
    \\    vec3 n = a_normal.xyz;
    \\    vec3 light = mix(u_ground_light, u_sky_light, n.y * 0.5 + 0.5) + u_sun_color * max(dot(n, u_sun), 0.0);
    \\    v_color = a_color.rgb * light;
    \\    v_uv = a_pos.xz * 0.11;
    \\    v_fog = clamp((distance(a_pos, u_eye) - u_fog.x) * u_fog.y, 0.0, 1.0) * u_fog.z;
    \\    gl_Position = u_viewproj * vec4(a_pos, 1.0);
    \\}
;

const ground_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in mediump vec3 v_color;
    \\in mediump float v_fog;
    \\in highp vec2 v_uv;
    \\uniform sampler2D u_detail;
    \\uniform vec3 u_fog_color;
    \\out vec4 o;
    \\void main() {
    \\    vec3 col = v_color * (0.76 + 0.48 * texture(u_detail, v_uv).r);
    \\    o = vec4(mix(col, u_fog_color, v_fog), 1.0);
    \\}
;

const solid_vs = vertex_head ++
    \\uniform mat4 u_model;
    \\uniform vec3 u_lag;         // how loose parts trail behind the body's motion
    \\uniform float u_two_sided;  // 1 for leaves, which are lit from both faces
    \\out mediump vec3 v_base;
    \\out mediump vec3 v_sun;
    \\out mediump float v_ndl;
    \\out mediump float v_fog;
    \\void main() {
    \\    vec4 world = u_model * vec4(a_pos, 1.0);
    \\    vec3 n = normalize(mat3(u_model) * a_normal.xyz);
    \\    float sway = a_normal.w;
    \\    float gust = sin(world.x * 0.09 + world.z * 0.07 - u_wind.w * 1.3) * 0.5 + 0.5;
    \\    world.xz += u_wind.xy * (u_wind.z * (0.3 + 0.7 * gust) * sway * 1.3);
    \\    world.xyz += u_lag * sway;
    \\    float ndl = dot(n, u_sun);
    \\    // a leaf lit from behind still glows, a little dimmer
    \\    v_ndl = mix(max(ndl, 0.0), abs(ndl) * (ndl < 0.0 ? 0.8 : 1.0), u_two_sided);
    \\    v_base = a_color.rgb * (mix(u_ground_light, u_sky_light, n.y * 0.5 + 0.5) + a_color.a * u_fog.w);
    \\    v_sun = a_color.rgb * u_sun_color;
    \\    v_fog = clamp((distance(world.xyz, u_eye) - u_fog.x) * u_fog.y, 0.0, 1.0) * u_fog.z;
    \\    gl_Position = u_viewproj * world;
    \\}
;

const solid_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in mediump vec3 v_base;
    \\in mediump vec3 v_sun;
    \\in mediump float v_ndl;
    \\in mediump float v_fog;
    \\uniform vec3 u_fog_color;
    \\uniform vec2 u_band;   // where light turns to shade, and how soft that edge is
    \\out vec4 o;
    \\void main() {
    \\    float lit = smoothstep(u_band.x, u_band.x + u_band.y, v_ndl);
    \\    o = vec4(mix(v_base + v_sun * (0.28 + 0.72 * lit), u_fog_color, v_fog), 1.0);
    \\}
;

const grass_vs = vertex_head ++
    \\uniform vec4 u_player;  // x, y, z, radius within which blades are shouldered aside
    \\uniform vec4 u_grass;   // fade start, 1/fade range, offset x, z (for drawing a second stand)
    \\uniform float u_grass_open;   // 1: clear the corridor from eye to creature. 0: leave it
    \\out mediump vec3 v_color;
    \\out mediump float v_fog;
    \\void main() {
    \\    vec3 pos = a_pos;
    \\    pos.xz += u_grass.zw;
    \\    float sway = a_normal.w;       // 0 at the root, 1 at the tip
    \\    float rise = sqrt(sway);       // height along the blade
    \\    float tall = a_extra.y * 0.125;
    \\    vec3 to_blade = pos - u_eye;
    \\    float d = length(to_blade);
    \\    // far blades sink into the ground instead of popping in
    \\    float keep = 1.0 - clamp((d - u_grass.x) * u_grass.y, 0.0, 1.0);
    \\    // Blades rooted in the corridor between the eye and the creature shrink into their
    \\    // roots: a wide clearing round the eye, narrowing to a parting round the creature.
    \\    vec2 lean = (a_extra.zw - 128.0) * 0.0625;
    \\    vec3 root = vec3(pos.x - lean.x * sway, pos.y - rise * tall, pos.z - lean.y * sway);
    \\    vec2 ab = u_player.xz - u_eye.xz;
    \\    float along = clamp(dot(root.xz - u_eye.xz, ab) / max(dot(ab, ab), 0.001), 0.0, 1.0);
    \\    float gap = length(root.xz - (u_eye.xz + ab * along));
    \\    float room = mix(5.2, 1.2, along) * u_grass_open;
    \\    keep *= smoothstep(room * 0.6, room * 1.3, gap + 1.0 - u_grass_open);
    \\    pos = root + (pos - root) * keep;
    \\    // one wind: a gust that travels across the meadow, plus each blade's own flutter
    \\    vec2 gp = pos.xz * 0.045 - u_wind.xy * (u_wind.w * 0.5);
    \\    float gust = sin(gp.x * 1.7 + gp.y * 1.3) * 0.5 + sin(gp.x * 0.6 - gp.y * 2.1 + 1.7) * 0.5;
    \\    float bend = u_wind.z * (0.55 + 0.45 * gust) + 0.05 * sin(u_wind.w * 2.7 + a_extra.x * 0.0246);
    \\    pos.xz += u_wind.xy * (bend * sway * tall * 0.42);
    \\    pos.y -= bend * bend * sway * tall * 0.10;
    \\    // the creature shoulders blades aside
    \\    vec2 away = pos.xz - u_player.xz;
    \\    float near = (1.0 - smoothstep(0.0, u_player.w, length(away))) * step(u_player.y - 3.0, a_pos.y);
    \\    pos.xz += normalize(away + vec2(0.0001)) * (near * sway * 1.8);
    \\    pos.y -= near * sway * tall * 0.12;
    \\    // darker at the root, brighter at the tip, glowing when the sun is behind the blade
    \\    float facing = abs(dot(a_normal.xyz, u_sun));
    \\    vec3 light = mix(u_ground_light, u_sky_light, 0.35 + 0.65 * rise)
    \\        + u_sun_color * ((0.30 + 0.50 * facing) * (0.40 + 0.60 * rise));
    \\    float through = max(dot(to_blade / d, u_sun), 0.0);
    \\    through = through * through * through * through * rise;
    \\    v_color = a_color.rgb * (light + u_sun_color * (through * 0.9));
    \\    v_fog = clamp((d - u_fog.x) * u_fog.y, 0.0, 1.0) * u_fog.z;
    \\    gl_Position = u_viewproj * vec4(pos, 1.0);
    \\}
;

const color_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in mediump vec3 v_color;
    \\in mediump float v_fog;
    \\uniform vec3 u_fog_color;
    \\out vec4 o;
    \\void main() { o = vec4(mix(v_color, u_fog_color, v_fog), 1.0); }
;

const sky_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\uniform vec3 u_forward;
    \\uniform vec3 u_right;
    \\uniform vec3 u_up;
    \\uniform vec3 u_tan;   // half-width, half-height of the view at distance 1; lower-third slide
    \\out highp vec3 v_dir;
    \\void main() {
    \\    v_dir = u_forward + u_right * (a_pos.x * u_tan.x) + u_up * ((a_pos.y + u_tan.z) * u_tan.y);
    \\    gl_Position = vec4(a_pos, 1.0, 1.0);
    \\}
;

const sky_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in highp vec3 v_dir;
    \\uniform vec3 u_zenith;
    \\uniform vec3 u_horizon;
    \\uniform vec3 u_sun;
    \\uniform vec3 u_sun_color;
    \\uniform vec4 u_cloud;        // colour, and how much sky they cover
    \\uniform highp vec2 u_drift;
    \\uniform sampler2D u_noise;
    \\out vec4 o;
    \\void main() {
    \\    highp vec3 d = normalize(v_dir);
    \\    float up = max(d.y, 0.0);
    \\    vec3 col = mix(u_horizon, u_zenith, sqrt(up));
    \\    highp float s = max(dot(d, u_sun), 0.0);
    \\    highp float s8 = s * s; s8 *= s8; s8 *= s8;
    \\    highp float disc = s8 * s8; disc *= disc; disc *= disc; disc *= disc;   // s^512
    \\    col += u_sun_color * (disc * 2.5 + s8 * 0.20);
    \\    // one layer of cloud on a flat ceiling
    \\    highp vec2 uv = d.xz / (d.y + 0.15) * 0.10 + u_drift;
    \\    float c = texture(u_noise, uv).r * 0.62 + texture(u_noise, uv * 2.7 + 0.37).r * 0.38;
    \\    float cover = smoothstep(u_cloud.w, u_cloud.w + 0.20, c) * smoothstep(0.02, 0.22, d.y);
    \\    o = vec4(mix(col, u_cloud.rgb, cover * 0.88), 1.0);
    \\}
;

const water_vs = vertex_head ++
    \\out highp vec3 v_world;
    \\out mediump float v_fog;
    \\void main() {
    \\    v_world = a_pos;
    \\    v_fog = clamp((distance(a_pos, u_eye) - u_fog.x) * u_fog.y, 0.0, 1.0) * u_fog.z;
    \\    gl_Position = u_viewproj * vec4(a_pos, 1.0);
    \\}
;

const water_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in highp vec3 v_world;
    \\in mediump float v_fog;
    \\uniform highp vec3 u_eye;        // shared with the vertex shader, so the same precision
    \\uniform highp vec3 u_sun;
    \\uniform highp vec3 u_sun_color;
    \\uniform vec3 u_horizon;
    \\uniform vec3 u_zenith;
    \\uniform vec3 u_water;
    \\uniform vec3 u_fog_color;
    \\uniform highp float u_time;
    \\uniform sampler2D u_noise;
    \\out vec4 o;
    \\void main() {
    \\    highp vec3 v = normalize(u_eye - v_world);
    \\    highp vec2 uv = v_world.xz * 0.035;
    \\    float n1 = texture(u_noise, uv + vec2(u_time * 0.011, u_time * 0.007)).r;
    \\    float n2 = texture(u_noise, uv * 1.7 - vec2(u_time * 0.009, u_time * -0.013)).r;
    \\    vec3 n = normalize(vec3((n1 - 0.5) * 0.55, 1.0, (n2 - 0.5) * 0.55));
    \\    float fres = 1.0 - max(dot(n, v), 0.0);
    \\    fres = fres * fres * fres;
    \\    vec3 col = mix(u_water, mix(u_horizon, u_zenith, 0.4), 0.22 + 0.78 * fres);
    \\    highp vec3 h = normalize(v + u_sun);
    \\    col += u_sun_color * (step(0.992, dot(n, h)) * 0.9);   // hard glints, like ink on a cel
    \\    o = vec4(mix(col, u_fog_color, v_fog), 0.62 + 0.38 * fres);
    \\}
;

const shadow_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\uniform mat4 u_viewproj;
    \\uniform vec4 u_shadow;   // centre x, y, z; radius
    \\out mediump vec2 v_uv;
    \\void main() {
    \\    v_uv = a_pos;
    \\    gl_Position = u_viewproj * vec4(u_shadow.x + a_pos.x * u_shadow.w, u_shadow.y, u_shadow.z + a_pos.y * u_shadow.w, 1.0);
    \\}
;

const shadow_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in mediump vec2 v_uv;
    \\uniform float u_time;   // reused here as the shadow's darkness
    \\out vec4 o;
    \\void main() {
    \\    float a = max(1.0 - dot(v_uv, v_uv), 0.0);
    \\    o = vec4(0.02, 0.04, 0.03, a * a * u_time);
    \\}
;

const blit_vs =
    \\#version 300 es
    \\layout(location = 0) in vec2 a_pos;
    \\out vec2 v_uv;
    \\void main() { v_uv = a_pos * 0.5 + 0.5; gl_Position = vec4(a_pos, 0.0, 1.0); }
;

const blit_fs =
    \\#version 300 es
    \\precision mediump float;
    \\in vec2 v_uv;
    \\uniform sampler2D u_tex;
    \\out vec4 o;
    \\void main() { o = texture(u_tex, v_uv); }
;

/// Every uniform any of the programs uses. A program simply lacks the ones it does not declare.
const U = enum(usize) {
    viewproj,
    model,
    eye,
    sun,
    sun_color,
    sky_light,
    ground_light,
    fog,
    fog_color,
    wind,
    player,
    clear,
    grass,
    band,
    two_sided,
    lag,
    detail,
    noise,
    zenith,
    horizon,
    cloud,
    drift,
    forward,
    right,
    up,
    tan,
    water,
    time,
    shadow,
    tex,
};
const uniform_names = [_][:0]const u8{
    "u_viewproj",     "u_model",   "u_eye",   "u_sun",   "u_sun_color", "u_sky_light",
    "u_ground_light", "u_fog",     "u_fog_color", "u_wind",  "u_player",    "u_grass_open",
    "u_grass",        "u_band",    "u_two_sided", "u_lag",   "u_detail",    "u_noise",
    "u_zenith",       "u_horizon", "u_cloud", "u_drift", "u_forward",   "u_right",
    "u_up",           "u_tan",     "u_water", "u_time",  "u_shadow",    "u_tex",
};
comptime {
    std.debug.assert(@intFromEnum(U.tex) + 1 == uniform_names.len);
}

const Program = struct {
    id: c.GLuint = 0,
    at: [uniform_names.len]c.GLint = @splat(-1),

    fn build(vs: [:0]const u8, fs: [:0]const u8, name: []const u8) ?Program {
        var self = Program{ .id = platform.linkProgram(vs, fs, name) orelse return null };
        for (uniform_names, 0..) |uniform, i| self.at[i] = gl.GetUniformLocation(self.id, uniform.ptr);
        return self;
    }
    fn use(self: *const Program) void {
        gl.UseProgram(self.id);
    }
    fn f1(self: *const Program, u: U, x: f32) void {
        gl.Uniform1f(self.at[@intFromEnum(u)], x);
    }
    fn int(self: *const Program, u: U, x: c.GLint) void {
        gl.Uniform1i(self.at[@intFromEnum(u)], x);
    }
    fn f2(self: *const Program, u: U, x: f32, y: f32) void {
        gl.Uniform2f(self.at[@intFromEnum(u)], x, y);
    }
    fn f3(self: *const Program, u: U, v: [3]f32) void {
        gl.Uniform3f(self.at[@intFromEnum(u)], v[0], v[1], v[2]);
    }
    fn v3(self: *const Program, u: U, v: Vec3) void {
        gl.Uniform3f(self.at[@intFromEnum(u)], v.x, v.y, v.z);
    }
    fn f4(self: *const Program, u: U, x: f32, y: f32, z: f32, w: f32) void {
        gl.Uniform4f(self.at[@intFromEnum(u)], x, y, z, w);
    }
    fn mat(self: *const Program, u: U, m: Mat4) void {
        gl.UniformMatrix4fv(self.at[@intFromEnum(u)], 1, c.GL_FALSE, &m.m);
    }
};

// ------------------------------------------------------------------ geometry on the GPU

const Batch = struct {
    vao: c.GLuint = 0,
    count: c.GLsizei = 0,
    /// Grass: how many indices draw an evenly spread half of the blades.
    half: c.GLsizei = 0,
    lo: Vec3 = .{},
    hi: Vec3 = .{},

    fn upload(mesh: *const shapes.Mesh) Batch {
        var self = Batch{ .count = @intCast(mesh.indices.len), .half = @intCast(mesh.half), .lo = mesh.lo, .hi = mesh.hi };
        if (self.count == 0) return self;
        var buffers: [2]c.GLuint = undefined;
        gl.GenVertexArrays(1, &self.vao);
        gl.BindVertexArray(self.vao);
        gl.GenBuffers(2, &buffers);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, buffers[0]);
        gl.BufferData(c.GL_ARRAY_BUFFER, @intCast(mesh.verts.len * @sizeOf(shapes.Vertex)), mesh.verts.items.ptr, c.GL_STATIC_DRAW);
        gl.BindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
        gl.BufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(mesh.indices.len * @sizeOf(u16)), mesh.indices.items.ptr, c.GL_STATIC_DRAW);
        const stride = @sizeOf(shapes.Vertex);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, stride, null);
        gl.EnableVertexAttribArray(1);
        gl.VertexAttribPointer(1, 4, c.GL_BYTE, c.GL_TRUE, stride, @ptrFromInt(12));
        gl.EnableVertexAttribArray(2);
        gl.VertexAttribPointer(2, 4, c.GL_UNSIGNED_BYTE, c.GL_TRUE, stride, @ptrFromInt(16));
        gl.EnableVertexAttribArray(3);
        gl.VertexAttribPointer(3, 4, c.GL_UNSIGNED_BYTE, c.GL_FALSE, stride, @ptrFromInt(20));
        gl.BindVertexArray(0);
        return self;
    }

    fn draw(self: *const Batch, tally: *Tally) void {
        self.drawSome(self.count, tally);
    }

    fn drawSome(self: *const Batch, indices: c.GLsizei, tally: *Tally) void {
        if (indices == 0) return;
        gl.BindVertexArray(self.vao);
        gl.DrawElements(c.GL_TRIANGLES, indices, c.GL_UNSIGNED_SHORT, null);
        tally.draws += 1;
        tally.triangles += @intCast(@divTrunc(indices, 3));
    }

    fn centre(self: *const Batch) Vec3 {
        return self.lo.add(self.hi).scale(0.5);
    }
};

/// What one frame cost in geometry.
pub const Tally = struct {
    draws: u32 = 0,
    triangles: u32 = 0,
};

/// Which parts of the scene to draw; the benchmark turns them on one at a time.
pub const Layers = struct {
    sky: bool = true,
    ground: bool = true,
    solids: bool = true,
    grass: bool = true,
    creature: bool = true,
    water: bool = true,
};

/// Everything that changes from frame to frame.
pub const View = struct {
    view: Mat4,
    proj: Mat4,
    eye: Vec3,
    creature_pos: Vec3,
    creature_model: Mat4,
    /// How the sprout trails: opposite to the creature's velocity.
    creature_lag: Vec3 = .{},
    time: f32,
    /// 0 noon, 1 the small hours.
    night: f32 = 0.0,
    wind: f32 = 0.55,
    layers: Layers = .{},
    /// Draw the grass this many times, offset, to measure a denser meadow.
    grass_passes: u8 = 1,
};

const terrain_side = 10;
const grass_side = 20;
const prop_side = 5;

pub const Scene = struct {
    width: i32 = 0,
    height: i32 = 0,
    /// Percent of full resolution at which the 3D view is drawn (100, 75, 50).
    scale: u8 = 100,
    /// How far grass is drawn, and where it starts to sink away before that.
    grass_far: f32 = 85.0,
    /// Beyond this distance a stand of grass is drawn with half its blades.
    grass_thin: f32 = 46.0,

    ground: Program = .{},
    solid: Program = .{},
    blades: Program = .{},
    sky: Program = .{},
    pond: Program = .{},
    blob: Program = .{},
    blit: Program = .{},

    terrain: [terrain_side * terrain_side]Batch = @splat(.{}),
    grass: [grass_side * grass_side]Batch = @splat(.{}),
    stones: [prop_side * prop_side]Batch = @splat(.{}),
    plants: [prop_side * prop_side]Batch = @splat(.{}),
    trunk: Batch = .{},
    canopy: Batch = .{},
    backdrop: Batch = .{},
    water: Batch = .{},
    creature: Batch = .{},
    world_triangles: usize = 0,
    blade_count: usize = 0,

    flat_vao: c.GLuint = 0,
    detail_tex: c.GLuint = 0,
    cloud_tex: c.GLuint = 0,
    target_fbo: c.GLuint = 0,
    target_tex: c.GLuint = 0,
    target_depth: c.GLuint = 0,
    target_w: i32 = 0,
    target_h: i32 = 0,

    pub fn init(self: *Scene, gpa: std.mem.Allocator, width: i32, height: i32, things: *const land.Things, grass_spacing: f32) bool {
        self.* = .{ .width = width, .height = height };
        self.ground = Program.build(ground_vs, ground_fs, "ground") orelse return false;
        self.solid = Program.build(solid_vs, solid_fs, "solid") orelse return false;
        self.blades = Program.build(grass_vs, color_fs, "grass") orelse return false;
        self.sky = Program.build(sky_vs, sky_fs, "sky") orelse return false;
        self.pond = Program.build(water_vs, water_fs, "water") orelse return false;
        self.blob = Program.build(shadow_vs, shadow_fs, "shadow") orelse return false;
        self.blit = Program.build(blit_vs, blit_fs, "blit") orelse return false;

        for (0..terrain_side) |j| {
            for (0..terrain_side) |i| {
                var mesh = shapes.terrain(gpa, @as(f32, @floatFromInt(i)) * shapes.terrain_chunk, @as(f32, @floatFromInt(j)) * shapes.terrain_chunk);
                defer mesh.deinit(gpa);
                self.terrain[j * terrain_side + i] = Batch.upload(&mesh);
                self.world_triangles += mesh.triangles();
            }
        }
        for (0..grass_side) |j| {
            for (0..grass_side) |i| {
                var mesh = shapes.grass(gpa, @as(f32, @floatFromInt(i)) * shapes.grass_chunk, @as(f32, @floatFromInt(j)) * shapes.grass_chunk, grass_spacing);
                defer mesh.deinit(gpa);
                self.grass[j * grass_side + i] = Batch.upload(&mesh);
                self.world_triangles += mesh.triangles();
                self.blade_count += mesh.triangles() / 5;
            }
        }
        for (0..prop_side) |j| {
            for (0..prop_side) |i| {
                const x0 = @as(f32, @floatFromInt(i)) * shapes.prop_cell;
                const z0 = @as(f32, @floatFromInt(j)) * shapes.prop_cell;
                var rocks = shapes.stonesIn(gpa, things, x0, z0);
                defer rocks.deinit(gpa);
                self.stones[j * prop_side + i] = Batch.upload(&rocks);
                var growth = shapes.plantsIn(gpa, things, x0, z0);
                defer growth.deinit(gpa);
                self.plants[j * prop_side + i] = Batch.upload(&growth);
                self.world_triangles += rocks.triangles() + growth.triangles();
            }
        }
        inline for (.{ "trunk", "canopy", "backdrop", "water", "creature" }) |name| {
            var mesh = @field(shapes, name)(gpa);
            defer mesh.deinit(gpa);
            @field(self, name) = Batch.upload(&mesh);
            self.world_triangles += mesh.triangles();
        }

        // two flat shapes: a triangle that covers the screen, and a square for the creature's shadow
        gl.GenVertexArrays(1, &self.flat_vao);
        gl.BindVertexArray(self.flat_vao);
        var buffer: c.GLuint = 0;
        gl.GenBuffers(1, &buffer);
        gl.BindBuffer(c.GL_ARRAY_BUFFER, buffer);
        const flat = [_]f32{ -1, -1, 3, -1, -1, 3, -1, -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1 };
        gl.BufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(flat)), &flat, c.GL_STATIC_DRAW);
        gl.EnableVertexAttribArray(0);
        gl.VertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);
        gl.BindVertexArray(0);

        self.detail_tex = noiseTexture(gpa, 64, 8.0, 17, true);
        self.cloud_tex = noiseTexture(gpa, 128, 6.0, 29, false);
        return platform.checkGl("scene init");
    }

    /// A square tile of noise that repeats without a seam.
    fn noiseTexture(gpa: std.mem.Allocator, side: usize, cells: f32, seed: u32, mipmapped: bool) c.GLuint {
        const pixels = gpa.alloc(u8, side * side) catch @panic("out of memory");
        defer gpa.free(pixels);
        const period: i32 = @intFromFloat(cells);
        for (0..side) |y| {
            for (0..side) |x| {
                var sum: f32 = 0.0;
                var amplitude: f32 = 0.5;
                var total: f32 = 0.0;
                var octave: u5 = 0;
                while (octave < 4) : (octave += 1) {
                    const scale = cells * @as(f32, @floatFromInt(@as(u32, 1) << octave)) / @as(f32, @floatFromInt(side));
                    sum += amplitude * tileValue(@as(f32, @floatFromInt(x)) * scale, @as(f32, @floatFromInt(y)) * scale, period << octave, seed + octave);
                    total += amplitude;
                    amplitude *= 0.5;
                }
                pixels[y * side + x] = @intFromFloat(std.math.clamp(sum / total, 0.0, 1.0) * 255.0);
            }
        }
        var texture: c.GLuint = 0;
        gl.GenTextures(1, &texture);
        gl.BindTexture(c.GL_TEXTURE_2D, texture);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8, @intCast(side), @intCast(side), 0, c.GL_RED, c.GL_UNSIGNED_BYTE, pixels.ptr);
        gl.PixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        if (mipmapped) {
            gl.GenerateMipmap(c.GL_TEXTURE_2D);
            gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_NEAREST);
        } else {
            gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        }
        return texture;
    }

    fn tileValue(x: f32, y: f32, period: i32, seed: u32) f32 {
        const fx = @floor(x);
        const fy = @floor(y);
        const ix: i32 = @intFromFloat(fx);
        const iy: i32 = @intFromFloat(fy);
        const tx = x - fx;
        const ty = y - fy;
        const sx = tx * tx * (3.0 - 2.0 * tx);
        const sy = ty * ty * (3.0 - 2.0 * ty);
        const a = noise.cell(@mod(ix, period), @mod(iy, period), seed);
        const b = noise.cell(@mod(ix + 1, period), @mod(iy, period), seed);
        const d = noise.cell(@mod(ix, period), @mod(iy + 1, period), seed);
        const e = noise.cell(@mod(ix + 1, period), @mod(iy + 1, period), seed);
        const top = a + (b - a) * sx;
        const bottom = d + (e - d) * sx;
        return top + (bottom - top) * sy;
    }

    /// Draw the 3D view at `percent` of full resolution and stretch it to the screen.
    pub fn setScale(self: *Scene, percent: u8) bool {
        self.scale = percent;
        if (percent >= 100) return true;
        const w = @divTrunc(self.width * percent, 100);
        const h = @divTrunc(self.height * percent, 100);
        if (self.target_fbo != 0 and w == self.target_w and h == self.target_h) return true;
        if (self.target_fbo == 0) {
            gl.GenFramebuffers(1, &self.target_fbo);
            gl.GenTextures(1, &self.target_tex);
            gl.GenRenderbuffers(1, &self.target_depth);
        }
        self.target_w = w;
        self.target_h = h;
        gl.BindTexture(c.GL_TEXTURE_2D, self.target_tex);
        gl.TexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA8, w, h, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
        gl.TexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
        gl.BindRenderbuffer(c.GL_RENDERBUFFER, self.target_depth);
        gl.RenderbufferStorage(c.GL_RENDERBUFFER, c.GL_DEPTH_COMPONENT24, w, h);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, self.target_fbo);
        gl.FramebufferTexture2D(c.GL_FRAMEBUFFER, c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, self.target_tex, 0);
        gl.FramebufferRenderbuffer(c.GL_FRAMEBUFFER, c.GL_DEPTH_ATTACHMENT, c.GL_RENDERBUFFER, self.target_depth);
        const status = gl.CheckFramebufferStatus(c.GL_FRAMEBUFFER);
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        if (status != c.GL_FRAMEBUFFER_COMPLETE) {
            platform.log("scaled target incomplete: 0x{x}", .{status});
            self.scale = 100;
            return false;
        }
        return true;
    }

    fn light(program: *const Program, v: *const View, palette: Palette, view_proj: Mat4) void {
        program.use();
        program.mat(.viewproj, view_proj);
        program.v3(.eye, v.eye);
        program.v3(.sun, sun_dir);
        program.f3(.sun_color, palette.sun_color);
        program.f3(.sky_light, palette.sky_light);
        program.f3(.ground_light, palette.ground_light);
        program.f4(.fog, palette.haze_start, 1.0 / palette.haze_range, palette.haze_most, palette.glow);
        program.f3(.fog_color, palette.haze);
        // the wind blows from the pond toward the tree, and never quite steadily
        program.f4(.wind, 0.78, -0.62, v.wind, v.time);
    }

    /// Draw one frame of the 3D view into the current target. Labels go on afterwards.
    pub fn draw(self: *Scene, v: *const View) Tally {
        var tally = Tally{};
        const palette = Palette.blend(noon, small_hours, v.night);
        const scaled = self.scale < 100 and self.target_fbo != 0;
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, if (scaled) self.target_fbo else 0);
        gl.Viewport(0, 0, if (scaled) self.target_w else self.width, if (scaled) self.target_h else self.height);
        gl.DepthMask(c.GL_TRUE);
        gl.ClearColor(palette.haze[0], palette.haze[1], palette.haze[2], 1.0);
        gl.ClearDepthf(1.0);
        gl.Clear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        gl.Enable(c.GL_DEPTH_TEST);
        gl.DepthFunc(c.GL_LEQUAL);
        gl.Disable(c.GL_BLEND);

        const view_proj = v.proj.mul(v.view);
        const frustum = math.Frustum.init(view_proj);

        // nearest things first, so what is hidden behind them is never shaded
        if (v.layers.creature or v.layers.solids) {
            light(&self.solid, v, palette, view_proj);
        }
        if (v.layers.creature) {
            gl.Disable(c.GL_CULL_FACE);
            self.solid.mat(.model, v.creature_model);
            self.solid.v3(.lag, v.creature_lag);
            self.solid.f1(.two_sided, 0.0);
            self.solid.f2(.band, 0.30, 0.05);
            self.creature.draw(&tally);
        }
        if (v.layers.solids) {
            self.solid.mat(.model, Mat4.identity);
            self.solid.v3(.lag, Vec3.init(0.0, 0.0, 0.0));
            // stones and the trunk: closed shapes, soft shading
            gl.Enable(c.GL_CULL_FACE);
            gl.CullFace(c.GL_BACK);
            self.solid.f1(.two_sided, 0.0);
            self.solid.f2(.band, 0.05, 0.55);
            for (&self.stones) |*batch| {
                if (batch.count != 0 and frustum.seesBox(batch.lo, batch.hi)) batch.draw(&tally);
            }
            if (frustum.seesBox(self.trunk.lo, self.trunk.hi)) self.trunk.draw(&tally);
            // leaves and petals: seen from both sides
            gl.Disable(c.GL_CULL_FACE);
            self.solid.f1(.two_sided, 1.0);
            self.solid.f2(.band, 0.10, 0.45);
            for (&self.plants) |*batch| {
                if (batch.count != 0 and frustum.seesBox(batch.lo, batch.hi)) batch.draw(&tally);
            }
            if (frustum.seesBox(self.canopy.lo, self.canopy.hi)) self.canopy.draw(&tally);
        }

        if (v.layers.grass) {
            gl.Disable(c.GL_CULL_FACE);
            light(&self.blades, v, palette, view_proj);
            self.blades.f4(.player, v.creature_pos.x, v.creature_pos.y, v.creature_pos.z, 2.2);
            self.blades.f1(.clear, 1.0);
            // which stands are near enough and in view, nearest first
            var order: [grass_side * grass_side]u16 = undefined;
            var keys: [grass_side * grass_side]f32 = undefined;
            var visible: usize = 0;
            const reach = self.grass_far + shapes.grass_chunk;
            for (&self.grass, 0..) |*batch, i| {
                if (batch.count == 0) continue;
                const gap = batch.centre().sub(v.eye);
                const flat = @sqrt(gap.x * gap.x + gap.z * gap.z);
                if (flat > reach or !frustum.seesBox(batch.lo, batch.hi)) continue;
                var slot = visible;
                while (slot > 0 and keys[slot - 1] > flat) : (slot -= 1) {
                    keys[slot] = keys[slot - 1];
                    order[slot] = order[slot - 1];
                }
                keys[slot] = flat;
                order[slot] = @intCast(i);
                visible += 1;
            }
            var pass: u8 = 0;
            while (pass < v.grass_passes) : (pass += 1) {
                const shift = @as(f32, @floatFromInt(pass)) * 0.47;
                self.blades.f4(.grass, self.grass_far * 0.72, 1.0 / (self.grass_far * 0.28), shift, shift * 0.6);
                for (order[0..visible], keys[0..visible]) |index, flat| {
                    // beyond the near stands, every other blade is enough
                    const batch = &self.grass[index];
                    batch.drawSome(if (flat > self.grass_thin) batch.half else batch.count, &tally);
                }
            }
        }

        if (v.layers.ground) {
            gl.Enable(c.GL_CULL_FACE);
            gl.CullFace(c.GL_BACK);
            light(&self.ground, v, palette, view_proj);
            gl.ActiveTexture(c.GL_TEXTURE0);
            gl.BindTexture(c.GL_TEXTURE_2D, self.detail_tex);
            self.ground.int(.detail, 0);
            for (&self.terrain) |*batch| {
                if (frustum.seesBox(batch.lo, batch.hi)) batch.draw(&tally);
            }
            // the far growth beyond the rim: plain colour and haze
            gl.Disable(c.GL_CULL_FACE);
            light(&self.blades, v, palette, view_proj);
            self.blades.f4(.player, 0.0, -1000.0, 0.0, 0.01);
            self.blades.f1(.clear, 0.0);
            self.blades.f4(.grass, 1.0e6, 1.0, 0.0, 0.0);
            self.backdrop.draw(&tally);
        }

        gl.BindVertexArray(self.flat_vao);
        if (v.layers.sky) {
            // drawn last at the far plane: only the pixels nothing else covered are shaded
            gl.DepthMask(c.GL_FALSE);
            self.sky.use();
            const m = v.view.m;
            self.sky.f3(.right, .{ m[0], m[4], m[8] });
            self.sky.f3(.up, .{ m[1], m[5], m[9] });
            self.sky.f3(.forward, .{ -m[2], -m[6], -m[10] });
            self.sky.f3(.tan, .{ 1.0 / v.proj.m[0], 1.0 / v.proj.m[5], v.proj.m[9] });
            self.sky.f3(.zenith, palette.zenith);
            self.sky.f3(.horizon, palette.horizon);
            self.sky.v3(.sun, sun_dir);
            self.sky.f3(.sun_color, palette.sun_color);
            self.sky.f4(.cloud, palette.cloud[0], palette.cloud[1], palette.cloud[2], 0.50);
            self.sky.f2(.drift, v.time * 0.0016, v.time * -0.0011);
            gl.ActiveTexture(c.GL_TEXTURE0);
            gl.BindTexture(c.GL_TEXTURE_2D, self.cloud_tex);
            self.sky.int(.noise, 0);
            gl.DrawArrays(c.GL_TRIANGLES, 0, 3);
            tally.draws += 1;
        }

        // what is see-through goes on last, without writing depth
        gl.DepthMask(c.GL_FALSE);
        gl.Enable(c.GL_BLEND);
        gl.BlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
        if (v.layers.creature) {
            // a soft round shadow where the creature would land
            const floor_y = @max(land.groundHeight(v.creature_pos.x, v.creature_pos.z), land.waterLevel()) + 0.08;
            const lift = math.clamp01((v.creature_pos.y - floor_y) / 14.0);
            gl.Enable(c.GL_POLYGON_OFFSET_FILL);
            gl.PolygonOffset(-2.0, -2.0);
            self.blob.use();
            self.blob.mat(.viewproj, view_proj);
            self.blob.f4(.shadow, v.creature_pos.x, floor_y, v.creature_pos.z, 0.75 + 0.9 * lift);
            self.blob.f1(.time, (0.55 - 0.3 * lift) * (1.0 - 0.6 * v.night));
            gl.DrawArrays(c.GL_TRIANGLES, 3, 6);
            gl.Disable(c.GL_POLYGON_OFFSET_FILL);
            tally.draws += 1;
        }
        if (v.layers.water and frustum.seesBox(self.water.lo, self.water.hi)) {
            light(&self.pond, v, palette, view_proj);
            self.pond.f3(.horizon, palette.horizon);
            self.pond.f3(.zenith, palette.zenith);
            self.pond.f3(.water, palette.water);
            self.pond.f1(.time, v.time);
            gl.ActiveTexture(c.GL_TEXTURE0);
            gl.BindTexture(c.GL_TEXTURE_2D, self.cloud_tex);
            self.pond.int(.noise, 0);
            self.water.draw(&tally);
        }
        gl.Disable(c.GL_BLEND);
        gl.DepthMask(c.GL_TRUE);

        if (scaled) {
            gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
            gl.Viewport(0, 0, self.width, self.height);
            gl.Disable(c.GL_DEPTH_TEST);
            gl.Disable(c.GL_CULL_FACE);
            self.blit.use();
            gl.ActiveTexture(c.GL_TEXTURE0);
            gl.BindTexture(c.GL_TEXTURE_2D, self.target_tex);
            self.blit.int(.tex, 0);
            gl.BindVertexArray(self.flat_vao);
            gl.DrawArrays(c.GL_TRIANGLES, 0, 3);
        }
        gl.BindVertexArray(0);
        return tally;
    }

    /// Read the finished frame (bottom row first, RGBA) into `out`.
    pub fn readFrame(self: *Scene, out: []u8) void {
        gl.BindFramebuffer(c.GL_FRAMEBUFFER, 0);
        gl.ReadPixels(0, 0, self.width, self.height, c.GL_RGBA, c.GL_UNSIGNED_BYTE, out.ptr);
    }
};
