//! One camera for the page and the place.
//!
//! The rules live on a plane: `x` to the right, `y` toward the viewer. The page is that plane
//! seen from straight above, with everything that could stand lying on it, pointing away from the
//! viewer, the way a flower lies in a book. The place is the same plane seen from low behind Hum,
//! with everything standing. `deep` goes from 0 (page) to 1 (place) and moves both at once: the
//! camera comes down and the things come up, on one hinge.
//!
//! From straight above, with nothing standing, every point is the same distance from the eye, so
//! the picture is exactly the flat one: `screen = centre + (ground - focus) * zoom`.
const std = @import("std");

pub const width: f32 = 640.0;
pub const height: f32 = 480.0;

pub const V3 = [3]f32;

fn dot(a: V3, b: V3) f32 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

/// Where a point lands on the screen, how far it is from the eye, and how many pixels one world
/// unit covers there.
pub const Seen = struct {
    x: f32,
    y: f32,
    depth: f32,
    scale: f32,
    /// In front of the eye.
    ok: bool,
};

/// How the camera sits in the place.
pub const Pose = struct {
    /// Degrees below level.
    pitch: f32,
    /// Units from the eye to the point it looks at.
    back: f32,
    /// Units past Hum, along the heading, to the point it looks at.
    ahead: f32,
};

pub const calm = Pose{ .pitch = 12.0, .back = 520.0, .ahead = 250.0 };
/// A little higher and further back, so the ground on the viewer's side of Hum can be seen and
/// creatures at different distances come apart. It keeps a strip of sky.
pub const fight = Pose{ .pitch = 19.0, .back = 440.0, .ahead = 120.0 };

pub const Cam = struct {
    /// Pixels to the screen for a ray at 45 degrees: 240 / tan(half the vertical field of view).
    focal: f32 = 240.0 / @tan(25.0 * std.math.pi / 180.0),
    near: f32 = 6.0,

    // set by `aim`
    eye: V3 = .{ 0, 600, 0 },
    right: V3 = .{ 1, 0, 0 },
    up: V3 = .{ 0, 0, -1 },
    fwd: V3 = .{ 0, -1, 0 },
    /// The heading on the ground (unit): away from the viewer.
    hx: f32 = 0.0,
    hy: f32 = -1.0,
    /// The hinge: cos and sin of the angle everything stands at (0 lying, a quarter turn standing).
    lie: f32 = 1.0,
    stand: f32 = 0.0,
    deep: f32 = 0.0,
    /// Pixels per unit where Hum is, for marks that keep their size on the screen.
    ref: f32 = 1.0,
    /// The row of the screen the far edge of the ground reaches (off the top when looking down).
    horizon: f32 = -1e6,
    /// Hum's place on the ground, for fading with distance.
    fx: f32 = 0.0,
    fy: f32 = 0.0,

    /// Place the camera. `x`, `y`: Hum on the ground. `yaw`: radians the heading is turned
    /// clockwise from "up the page". `zoom`: pixels per unit on the page. `deep`: 0 page, 1 place.
    /// `pose`: how it sits when deep.
    pub fn aim(self: *Cam, x: f32, y: f32, yaw: f32, zoom: f32, deep: f32, pose: Pose) void {
        const d = std.math.clamp(deep, 0.0, 1.0);
        self.deep = d;
        self.hx = @sin(yaw);
        self.hy = -@cos(yaw);
        const turn = d * std.math.pi / 2.0;
        self.lie = @cos(turn);
        self.stand = @sin(turn);

        const page_back = self.focal / zoom;
        const page_ahead = 52.0 / zoom; // Hum sits 52 pixels below the middle of the page
        const pitch = (90.0 + (pose.pitch - 90.0) * d) * std.math.pi / 180.0;
        const back = page_back + (pose.back - page_back) * d;
        const ahead = page_ahead + (pose.ahead - page_ahead) * d;

        const tx = x + self.hx * ahead;
        const ty = y + self.hy * ahead;
        const cp = @cos(pitch);
        const sp = @sin(pitch);
        // world axes: X right on the page, Y up off it, Z toward the viewer
        self.fwd = .{ self.hx * cp, -sp, self.hy * cp };
        self.up = .{ self.hx * sp, cp, self.hy * sp };
        self.right = .{ -self.hy, 0.0, self.hx };
        self.eye = .{ tx - self.fwd[0] * back, -self.fwd[1] * back, ty - self.fwd[2] * back };
        self.fx = x;
        self.fy = y;
        self.horizon = if (cp > 0.001) height / 2.0 - self.focal * sp / cp else -1e6;
        self.ref = 1.0;
        self.ref = self.see(self.ground(x, y)).scale;
    }

    /// A point on the ground.
    pub fn ground(self: *const Cam, x: f32, y: f32) V3 {
        _ = self;
        return .{ x, 0.0, y };
    }

    /// A point of something that stands. Its foot is on the ground at (`x`, `y`); the point is
    /// `side` units to the viewer's right of the foot and `along` units up it. `hover` lifts the
    /// whole thing clear of the ground once it stands (a body that is a disc on the page).
    pub fn standing(self: *const Cam, x: f32, y: f32, side: f32, along: f32, hover: f32) V3 {
        return self.solid(x, y, side, along, 0.0, hover);
    }

    /// The same, with `depth` units away from the viewer as well: only a standing thing has any.
    pub fn solid(self: *const Cam, x: f32, y: f32, side: f32, along: f32, depth: f32, hover: f32) V3 {
        const reach = along * self.lie + depth * self.stand;
        return .{
            x + self.right[0] * side + self.hx * reach,
            (along + hover) * self.stand,
            y + self.right[2] * side + self.hy * reach,
        };
    }

    pub fn see(self: *const Cam, p: V3) Seen {
        const v = V3{ p[0] - self.eye[0], p[1] - self.eye[1], p[2] - self.eye[2] };
        const z = dot(v, self.fwd);
        if (z < self.near) return .{ .x = 0, .y = 0, .depth = z, .scale = 0, .ok = false };
        const s = self.focal / z;
        return .{
            .x = width / 2.0 + dot(v, self.right) * s,
            .y = height / 2.0 - dot(v, self.up) * s,
            .depth = z,
            .scale = s,
            .ok = true,
        };
    }

    /// The point as the graphics card wants it (x, y, z, w), so that a shape lying on the ground
    /// is cut correctly where it passes behind the eye.
    pub fn clip(self: *const Cam, p: V3) [4]f32 {
        const v = V3{ p[0] - self.eye[0], p[1] - self.eye[1], p[2] - self.eye[2] };
        const z = dot(v, self.fwd);
        return .{
            dot(v, self.right) * self.focal / (width / 2.0),
            dot(v, self.up) * self.focal / (height / 2.0),
            z - 2.0 * self.near,
            z,
        };
    }

    /// The part of the segment a-b that is in front of the eye, or null if none is.
    pub fn cut(self: *const Cam, a: V3, b: V3) ?[2]V3 {
        const za = dot(.{ a[0] - self.eye[0], a[1] - self.eye[1], a[2] - self.eye[2] }, self.fwd);
        const zb = dot(.{ b[0] - self.eye[0], b[1] - self.eye[1], b[2] - self.eye[2] }, self.fwd);
        const n = self.near * 1.01;
        if (za < n and zb < n) return null;
        if (za >= n and zb >= n) return .{ a, b };
        const t = (n - za) / (zb - za);
        const m = V3{ a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };
        return if (za < n) .{ m, b } else .{ a, m };
    }

    /// How much of its light a thing at (`x`, `y`) keeps: the far distance fades out.
    pub fn haze(self: *const Cam, x: f32, y: f32) f32 {
        const dx = x - self.fx;
        const dy = y - self.fy;
        const d = @sqrt(dx * dx + dy * dy);
        const t = std.math.clamp((d - 900.0) / 2100.0, 0.0, 1.0);
        return 1.0 - t * t * (3.0 - 2.0 * t);
    }

    /// Turn what the stick says (screen directions) into directions on the ground.
    pub fn steer(self: *const Cam, sx: f32, sy: f32) [2]f32 {
        // stick right is the camera's right; stick up (negative y) is the heading
        return .{ -self.hy * sx - self.hx * sy, self.hx * sx - self.hy * sy };
    }
};

test "the page is the flat picture, exactly" {
    var cam = Cam{};
    for ([_]f32{ 1.0, 1.5 }) |zoom| {
        cam.aim(120.0, -40.0, 0.0, zoom, 0.0, calm);
        // Hum sits at (320, 292)
        const hum = cam.see(cam.ground(120.0, -40.0));
        try std.testing.expectApproxEqAbs(@as(f32, 320.0), hum.x, 0.01);
        try std.testing.expectApproxEqAbs(@as(f32, 292.0), hum.y, 0.01);
        try std.testing.expectApproxEqAbs(zoom, hum.scale, 0.001);
        // a point 100 right and 60 toward the viewer
        const p = cam.see(cam.ground(220.0, 20.0));
        try std.testing.expectApproxEqAbs(320.0 + 100.0 * zoom, p.x, 0.01);
        try std.testing.expectApproxEqAbs(292.0 + 60.0 * zoom, p.y, 0.01);
        // a reed's tip, 30 up it: on the page it lies 30 up the screen
        const tip = cam.see(cam.standing(220.0, 20.0, 4.0, 30.0, 9.0));
        try std.testing.expectApproxEqAbs(320.0 + 104.0 * zoom, tip.x, 0.01);
        try std.testing.expectApproxEqAbs(292.0 + 30.0 * zoom, tip.y, 0.01);
        // depth is nothing on the page
        const flat = cam.see(cam.solid(220.0, 20.0, 4.0, 30.0, 25.0, 9.0));
        try std.testing.expectApproxEqAbs(tip.x, flat.x, 0.01);
        try std.testing.expectApproxEqAbs(tip.y, flat.y, 0.01);
    }
}

test "in the place things stand, the sky shows, and Hum is in the lower third" {
    var cam = Cam{};
    cam.aim(0.0, 0.0, 0.0, 1.0, 1.0, calm);
    const foot = cam.standing(50.0, -100.0, 0.0, 0.0, 0.0);
    const tip = cam.standing(50.0, -100.0, 0.0, 40.0, 0.0);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), foot[1], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 40.0), tip[1], 0.001);
    try std.testing.expectApproxEqAbs(foot[0], tip[0], 0.001);
    try std.testing.expectApproxEqAbs(foot[2], tip[2], 0.001);
    try std.testing.expect(cam.horizon > 100.0 and cam.horizon < 160.0);
    const hum = cam.see(cam.ground(0.0, 0.0));
    try std.testing.expect(hum.y > 300.0 and hum.y < 350.0);
    try std.testing.expectApproxEqAbs(@as(f32, 320.0), hum.x, 0.01);
    // further away is higher on the screen and smaller
    const far = cam.see(cam.ground(0.0, -400.0));
    try std.testing.expect(far.y < hum.y and far.scale < hum.scale);
    try std.testing.expect(far.y > cam.horizon);
}

test "the stick steers along the heading" {
    var cam = Cam{};
    cam.aim(0.0, 0.0, 0.0, 1.0, 1.0, calm);
    const up = cam.steer(0.0, -1.0);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), up[0], 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, -1.0), up[1], 0.0001);
    // a quarter turn to the right: stick up now walks to the right of the page
    cam.aim(0.0, 0.0, std.math.pi / 2.0, 1.0, 1.0, calm);
    const turned = cam.steer(0.0, -1.0);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), turned[0], 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), turned[1], 0.0001);
}

test "a line that passes behind the eye is cut in front of it" {
    var cam = Cam{};
    cam.aim(0.0, 0.0, 0.0, 1.0, 1.0, calm);
    const behind = cam.ground(0.0, 900.0);
    const ahead = cam.ground(0.0, -100.0);
    try std.testing.expect(!cam.see(behind).ok);
    const part = cam.cut(behind, ahead).?;
    try std.testing.expect(cam.see(part[0]).ok);
    try std.testing.expect(cam.cut(behind, cam.ground(10.0, 950.0)) == null);
}
