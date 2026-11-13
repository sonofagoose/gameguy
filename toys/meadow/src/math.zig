//! Small 3D math: vectors, 4x4 matrices (column-major, as OpenGL wants them) and the view
//! frustum. Right-handed, y up, the camera looks down -z.
const std = @import("std");

pub const Vec3 = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }
    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }
    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }
    pub fn scale(a: Vec3, k: f32) Vec3 {
        return .{ .x = a.x * k, .y = a.y * k, .z = a.z * k };
    }
    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.y * b.z - a.z * b.y, .y = a.z * b.x - a.x * b.z, .z = a.x * b.y - a.y * b.x };
    }
    pub fn length(a: Vec3) f32 {
        return @sqrt(a.dot(a));
    }
    pub fn normalize(a: Vec3) Vec3 {
        const len = a.length();
        if (len < 1e-8) return .{ .x = 0.0, .y = 1.0, .z = 0.0 };
        return a.scale(1.0 / len);
    }
    pub fn lerp(a: Vec3, b: Vec3, t: f32) Vec3 {
        return a.add(b.sub(a).scale(t));
    }
};

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn clamp01(x: f32) f32 {
    return std.math.clamp(x, 0.0, 1.0);
}

/// 0 at or below `edge0`, 1 at or above `edge1`, smooth between. `edge0` may exceed `edge1`.
pub fn smoothstep(edge0: f32, edge1: f32, x: f32) f32 {
    const t = clamp01((x - edge0) / (edge1 - edge0));
    return t * t * (3.0 - 2.0 * t);
}

/// Move `current` toward `target` so that the gap halves every `half_life` seconds.
pub fn approach(current: f32, target: f32, half_life: f32, dt: f32) f32 {
    return target + (current - target) * @exp2(-dt / half_life);
}

/// The shortest signed difference between two angles, in (-pi, pi].
pub fn angleDelta(from: f32, to: f32) f32 {
    var d = @mod(to - from, 2.0 * std.math.pi);
    if (d > std.math.pi) d -= 2.0 * std.math.pi;
    return d;
}

pub const Mat4 = struct {
    /// Column-major: element (row, column) is m[column * 4 + row].
    m: [16]f32,

    pub const identity = Mat4{ .m = .{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 } };

    /// a * b: applying the result applies `b` first, then `a`.
    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var out: Mat4 = undefined;
        for (0..4) |col| {
            for (0..4) |row| {
                var sum: f32 = 0.0;
                for (0..4) |k| sum += a.m[k * 4 + row] * b.m[col * 4 + k];
                out.m[col * 4 + row] = sum;
            }
        }
        return out;
    }

    pub fn perspective(fov_y: f32, aspect: f32, near: f32, far: f32) Mat4 {
        const f = 1.0 / @tan(fov_y * 0.5);
        var out = Mat4{ .m = @splat(0.0) };
        out.m[0] = f / aspect;
        out.m[5] = f;
        out.m[10] = (far + near) / (near - far);
        out.m[11] = -1.0;
        out.m[14] = 2.0 * far * near / (near - far);
        return out;
    }

    pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
        const f = target.sub(eye).normalize();
        const s = f.cross(up).normalize();
        const u = s.cross(f);
        return .{ .m = .{
            s.x,         u.x,         -f.x,       0.0,
            s.y,         u.y,         -f.y,       0.0,
            s.z,         u.z,         -f.z,       0.0,
            -s.dot(eye), -u.dot(eye), f.dot(eye), 1.0,
        } };
    }

    pub fn translation(t: Vec3) Mat4 {
        var out = identity;
        out.m[12] = t.x;
        out.m[13] = t.y;
        out.m[14] = t.z;
        return out;
    }

    pub fn scaling(sx: f32, sy: f32, sz: f32) Mat4 {
        var out = identity;
        out.m[0] = sx;
        out.m[5] = sy;
        out.m[10] = sz;
        return out;
    }

    /// Rotation about the y axis; positive turns +z toward +x.
    pub fn rotationY(angle: f32) Mat4 {
        const co = @cos(angle);
        const si = @sin(angle);
        var out = identity;
        out.m[0] = co;
        out.m[2] = -si;
        out.m[8] = si;
        out.m[10] = co;
        return out;
    }

    /// Rotation about the x axis.
    pub fn rotationX(angle: f32) Mat4 {
        const co = @cos(angle);
        const si = @sin(angle);
        var out = identity;
        out.m[5] = co;
        out.m[6] = si;
        out.m[9] = -si;
        out.m[10] = co;
        return out;
    }

    /// Rotation about the z axis.
    pub fn rotationZ(angle: f32) Mat4 {
        const co = @cos(angle);
        const si = @sin(angle);
        var out = identity;
        out.m[0] = co;
        out.m[1] = si;
        out.m[4] = -si;
        out.m[5] = co;
        return out;
    }

    pub fn transformPoint(self: Mat4, p: Vec3) Vec3 {
        return .{
            .x = self.m[0] * p.x + self.m[4] * p.y + self.m[8] * p.z + self.m[12],
            .y = self.m[1] * p.x + self.m[5] * p.y + self.m[9] * p.z + self.m[13],
            .z = self.m[2] * p.x + self.m[6] * p.y + self.m[10] * p.z + self.m[14],
        };
    }
};

/// The six planes of a view-projection matrix, for culling boxes that cannot be seen.
pub const Frustum = struct {
    planes: [6][4]f32,

    pub fn init(view_proj: Mat4) Frustum {
        const m = view_proj.m;
        var rows: [4][4]f32 = undefined;
        for (0..4) |r| rows[r] = .{ m[r], m[4 + r], m[8 + r], m[12 + r] };
        var out: Frustum = undefined;
        for (0..3) |axis| {
            for (0..4) |k| {
                out.planes[axis * 2][k] = rows[3][k] + rows[axis][k];
                out.planes[axis * 2 + 1][k] = rows[3][k] - rows[axis][k];
            }
        }
        return out;
    }

    /// False only when the box is entirely outside one of the planes.
    pub fn seesBox(self: *const Frustum, lo: Vec3, hi: Vec3) bool {
        for (self.planes) |p| {
            const x = if (p[0] >= 0.0) hi.x else lo.x;
            const y = if (p[1] >= 0.0) hi.y else lo.y;
            const z = if (p[2] >= 0.0) hi.z else lo.z;
            if (p[0] * x + p[1] * y + p[2] * z + p[3] < 0.0) return false;
        }
        return true;
    }
};

test "matrix multiplication applies the right-hand matrix first" {
    const move = Mat4.translation(Vec3.init(10.0, 0.0, 0.0));
    const grow = Mat4.scaling(2.0, 2.0, 2.0);
    const p = move.mul(grow).transformPoint(Vec3.init(1.0, 1.0, 1.0));
    try std.testing.expectApproxEqAbs(@as(f32, 12.0), p.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), p.y, 1e-5);
}

test "lookAt puts the target straight ahead on -z" {
    const view = Mat4.lookAt(Vec3.init(0.0, 0.0, 5.0), Vec3.init(0.0, 0.0, 0.0), Vec3.init(0.0, 1.0, 0.0));
    const p = view.transformPoint(Vec3.init(0.0, 0.0, 0.0));
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), p.x, 1e-5);
    try std.testing.expectApproxEqAbs(@as(f32, -5.0), p.z, 1e-5);
}

test "the frustum sees what is ahead and not what is behind" {
    const proj = Mat4.perspective(1.0, 4.0 / 3.0, 0.1, 100.0);
    const view = Mat4.lookAt(Vec3.init(0.0, 0.0, 0.0), Vec3.init(0.0, 0.0, -1.0), Vec3.init(0.0, 1.0, 0.0));
    const frustum = Frustum.init(proj.mul(view));
    try std.testing.expect(frustum.seesBox(Vec3.init(-1.0, -1.0, -11.0), Vec3.init(1.0, 1.0, -9.0)));
    try std.testing.expect(!frustum.seesBox(Vec3.init(-1.0, -1.0, 9.0), Vec3.init(1.0, 1.0, 11.0)));
    try std.testing.expect(!frustum.seesBox(Vec3.init(500.0, -1.0, -11.0), Vec3.init(502.0, 1.0, -9.0)));
}

test "angleDelta takes the short way round" {
    try std.testing.expectApproxEqAbs(@as(f32, 0.2), angleDelta(3.1, -3.1 + 0.2 - 0.0831853), 1e-3);
    try std.testing.expectApproxEqAbs(@as(f32, -0.5), angleDelta(0.25, -0.25), 1e-5);
}
