//! The little arithmetic the picture needs: points and 4x4 matrices, column-major as OpenGL
//! wants them. None of this is used by the world's rules.
const std = @import("std");

pub const V3 = [3]f32;
pub const M4 = [16]f32;

pub fn sub(a: V3, b: V3) V3 {
    return .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] };
}

pub fn cross(a: V3, b: V3) V3 {
    return .{ a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] };
}

pub fn dot(a: V3, b: V3) f32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

pub fn norm(a: V3) V3 {
    const len = @sqrt(dot(a, a));
    if (len < 1e-9) return .{ 0.0, 0.0, 0.0 };
    return .{ a[0] / len, a[1] / len, a[2] / len };
}

/// A view from `eye` toward `at`, with `up` roughly upward.
pub fn lookAt(eye: V3, at: V3, up: V3) M4 {
    const f = norm(sub(at, eye));
    const s = norm(cross(f, up));
    const u = cross(s, f);
    return .{
        s[0],         u[0],         -f[0],      0.0,
        s[1],         u[1],         -f[1],      0.0,
        s[2],         u[2],         -f[2],      0.0,
        -dot(s, eye), -dot(u, eye), dot(f, eye), 1.0,
    };
}

/// A perspective view: `fovy` is the vertical field of view in degrees.
pub fn perspective(fovy: f32, aspect: f32, near: f32, far: f32) M4 {
    const t = 1.0 / @tan(fovy * std.math.pi / 360.0);
    return .{
        t / aspect, 0.0, 0.0,                               0.0,
        0.0,        t,   0.0,                               0.0,
        0.0,        0.0, (far + near) / (near - far),       -1.0,
        0.0,        0.0, 2.0 * far * near / (near - far),   0.0,
    };
}

/// `a` after `b`: the matrix that does `b` first, then `a`.
pub fn mul(a: M4, b: M4) M4 {
    var out: M4 = undefined;
    for (0..4) |col| {
        for (0..4) |row| {
            var sum: f32 = 0.0;
            for (0..4) |k| sum += a[k * 4 + row] * b[col * 4 + k];
            out[col * 4 + row] = sum;
        }
    }
    return out;
}

test "a point straight ahead lands in the middle of the view" {
    const view = lookAt(.{ 0.0, 0.0, 5.0 }, .{ 0.0, 0.0, 0.0 }, .{ 0.0, 1.0, 0.0 });
    const vp = mul(perspective(50.0, 4.0 / 3.0, 0.1, 100.0), view);
    // the point (0, 0, 0)
    const x = vp[12];
    const y = vp[13];
    const w = vp[15];
    try std.testing.expect(@abs(x / w) < 1e-6);
    try std.testing.expect(@abs(y / w) < 1e-6);
    try std.testing.expect(w > 0.0);
}
