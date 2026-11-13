//! How the creature moves and how the camera follows it. No platform code. Every number that
//! decides how it feels is in `Feel`, so it can be tuned after someone has held it.
const std = @import("std");
const math = @import("math.zig");
const land = @import("land.zig");
const Vec3 = math.Vec3;
const Mat4 = math.Mat4;

pub const Feel = struct {
    run_speed: f32 = 9.0,
    dash_speed: f32 = 14.5,
    swim_speed: f32 = 5.0,
    /// Units per second per second: how quickly it reaches speed, and how quickly it stops.
    ground_accel: f32 = 75.0,
    ground_stop: f32 = 60.0,
    air_accel: f32 = 24.0,
    /// How fast the body turns to face where it is going, in radians per second.
    turn_rate: f32 = 13.0,
    /// A full jump rises about three body heights; letting go early cuts it short.
    jump_speed: f32 = 13.5,
    gravity_up: f32 = 30.0,
    gravity_down: f32 = 46.0,
    jump_cut: f32 = 0.45,
    /// Grace: a jump still counts this long after walking off an edge, or this long before landing.
    coyote_s: f32 = 0.10,
    buffer_s: f32 = 0.12,
    /// Holding jump while falling opens the sprout's leaves: a slow, far glide.
    glide_fall: f32 = 2.3,
    glide_speed: f32 = 11.5,
    glide_accel: f32 = 16.0,
    /// A mushroom cap throws the creature above the grass tips; holding jump adds a little.
    bounce_speed: f32 = 33.0,
    bounce_held: f32 = 1.15,
    max_fall: f32 = 40.0,
    /// Ledges up to this high are walked over; higher ones are walls.
    step_height: f32 = 0.9,
};

pub const Input = struct {
    /// Left stick, -1..1; y is negative when pushed away (up).
    move_x: f32 = 0.0,
    move_y: f32 = 0.0,
    jump: bool = false,
    dash: bool = false,
};

pub const EventKind = enum { step, jump, land, glide, bounce, splash };

pub const Event = struct {
    kind: EventKind,
    /// 0..1, how hard.
    strength: f32,
    /// bounce: the mushroom's index among the plants.
    index: usize = 0,
};

pub const Player = struct {
    feel: Feel = .{},
    /// Position of the feet.
    pos: Vec3 = .{},
    vel: Vec3 = .{},
    /// Facing: 0 looks toward -z, positive turns toward +x.
    yaw: f32 = 0.0,
    grounded: bool = false,
    gliding: bool = false,
    swimming: bool = false,
    coyote: f32 = 0.0,
    buffer: f32 = 0.0,
    jump_was_held: bool = false,
    cut_done: bool = true,
    air_time: f32 = 0.0,

    // how the body is drawn
    /// Negative: flattened by a landing. Positive: stretched by a jump.
    squash: f32 = 0.0,
    squash_vel: f32 = 0.0,
    /// Phase of the hop cycle while running.
    stride: f32 = 0.0,
    /// How open the sprout's leaves are, 0..1.
    spread: f32 = 0.0,

    events: [16]Event = undefined,
    event_count: usize = 0,

    pub fn init(things: *const land.Things, x: f32, z: f32) Player {
        var self = Player{};
        self.pos = Vec3.init(x, things.standingHeight(x, z), z);
        self.grounded = true;
        return self;
    }

    fn emit(self: *Player, kind: EventKind, strength: f32, index: usize) void {
        if (self.event_count == self.events.len) return;
        self.events[self.event_count] = .{ .kind = kind, .strength = math.clamp01(strength), .index = index };
        self.event_count += 1;
    }

    pub fn drainEvents(self: *Player, out: []Event) usize {
        const n = @min(out.len, self.event_count);
        @memcpy(out[0..n], self.events[0..n]);
        self.event_count = 0;
        return n;
    }

    /// Height of what the creature can stand on at (x, z): ground, stone, or the pond's surface.
    fn floor(self: *Player, things: *const land.Things, x: f32, z: f32) f32 {
        _ = self;
        return @max(things.standingHeight(x, z), land.waterLevel() - 0.55);
    }

    /// Advance by `dt` seconds. `camera_yaw` turns the stick into a direction in the world.
    pub fn step(self: *Player, things: *const land.Things, in: Input, camera_yaw: f32, dt: f32) void {
        const feel = self.feel;

        // the stick, as a direction on the ground relative to the camera
        const forward = Vec3.init(@sin(camera_yaw), 0.0, -@cos(camera_yaw));
        const right = Vec3.init(@cos(camera_yaw), 0.0, @sin(camera_yaw));
        var wish = right.scale(in.move_x).add(forward.scale(-in.move_y));
        const push = @min(wish.length(), 1.0);
        if (push > 0.001) wish = wish.normalize().scale(push);

        // run, dash, swim or glide: accelerate toward the wished velocity
        const top = if (self.swimming) feel.swim_speed else if (self.gliding) feel.glide_speed else if (in.dash) feel.dash_speed else feel.run_speed;
        const want_x = wish.x * top;
        const want_z = wish.z * top;
        var rate = if (self.grounded) (if (push > 0.001) feel.ground_accel else feel.ground_stop) else if (self.gliding) feel.glide_accel else feel.air_accel;
        // in the air with no input, keep what momentum there is
        if (!self.grounded and push <= 0.001) rate = 2.0;
        const dvx = want_x - self.vel.x;
        const dvz = want_z - self.vel.z;
        const gap = @sqrt(dvx * dvx + dvz * dvz);
        if (gap > 0.0001) {
            const change = @min(rate * dt, gap);
            self.vel.x += dvx / gap * change;
            self.vel.z += dvz / gap * change;
        }

        // jump: remembered briefly before landing, allowed briefly after leaving an edge
        const pressed = in.jump and !self.jump_was_held;
        self.jump_was_held = in.jump;
        if (pressed) self.buffer = feel.buffer_s;
        if (self.buffer > 0.0 and (self.grounded or self.coyote > 0.0)) {
            self.vel.y = feel.jump_speed;
            self.grounded = false;
            self.coyote = 0.0;
            self.buffer = 0.0;
            self.cut_done = false;
            self.squash_vel += 7.0;
            self.emit(.jump, 0.6, 0);
        }
        if (!in.jump and !self.cut_done and self.vel.y > 0.0) {
            self.vel.y *= feel.jump_cut;
            self.cut_done = true;
        }

        // gravity, and the glide
        const was_gliding = self.gliding;
        self.gliding = false;
        if (!self.grounded) {
            if (in.jump and self.vel.y < 0.0 and self.air_time > 0.12) {
                // the open leaves hold it up: the fall settles to a slow drift
                self.gliding = true;
                self.vel.y = math.approach(self.vel.y, -feel.glide_fall, 0.07, dt);
            } else {
                const g = if (self.vel.y > 0.0) feel.gravity_up else feel.gravity_down;
                self.vel.y = @max(self.vel.y - g * dt, -feel.max_fall);
            }
        }
        if (self.gliding and !was_gliding) self.emit(.glide, 0.5, 0);

        // move, sliding along what cannot be climbed
        const before_y = self.pos.y;
        var nx = self.pos.x + self.vel.x * dt;
        var nz = self.pos.z + self.vel.z * dt;
        const reach = self.pos.y + feel.step_height;
        if (self.floor(things, nx, nz) > reach) {
            if (self.floor(things, nx, self.pos.z) <= reach) {
                nz = self.pos.z;
                self.vel.z = 0.0;
            } else if (self.floor(things, self.pos.x, nz) <= reach) {
                nx = self.pos.x;
                self.vel.x = 0.0;
            } else {
                nx = self.pos.x;
                nz = self.pos.z;
                self.vel.x = 0.0;
                self.vel.z = 0.0;
            }
        }
        // the trunk is a wall
        const tx = nx - land.tree.x;
        const tz = nz - land.tree.z;
        const trunk_r = land.trunkRadius(self.pos.y - (land.groundHeight(land.tree.x, land.tree.z) - 2.0)) + 0.5;
        const from_trunk = @sqrt(tx * tx + tz * tz);
        if (from_trunk < trunk_r and from_trunk > 0.001) {
            nx = land.tree.x + tx / from_trunk * trunk_r;
            nz = land.tree.z + tz / from_trunk * trunk_r;
        }
        self.pos.x = std.math.clamp(nx, land.margin, land.size - land.margin);
        self.pos.z = std.math.clamp(nz, land.margin, land.size - land.margin);
        self.pos.y += self.vel.y * dt;

        // mushroom caps are springboards
        if (self.vel.y < 0.0) {
            if (things.mushroomAt(self.pos.x, self.pos.z)) |index| {
                const cap = land.Things.capHeight(things.plants[index]);
                if (self.pos.y <= cap and before_y >= cap - 0.6) {
                    self.pos.y = cap;
                    self.vel.y = feel.bounce_speed * (if (in.jump) feel.bounce_held else 1.0);
                    self.cut_done = true;
                    self.grounded = false;
                    self.air_time = 0.0;
                    self.squash_vel += 12.0;
                    self.emit(.bounce, 1.0, index);
                }
            }
        }

        // the ground
        const under = self.floor(things, self.pos.x, self.pos.z);
        const wet = things.standingHeight(self.pos.x, self.pos.z) < land.waterLevel() - 0.55;
        if (self.grounded) {
            if (under < self.pos.y - feel.step_height and self.vel.y <= 0.0) {
                // walked off an edge
                self.grounded = false;
                self.coyote = feel.coyote_s;
            } else {
                self.pos.y = under;
                self.vel.y = 0.0;
            }
        } else if (self.pos.y <= under and self.vel.y <= 0.0) {
            const impact = -self.vel.y;
            self.pos.y = under;
            self.vel.y = 0.0;
            self.grounded = true;
            self.squash_vel -= @min(impact * 0.45, 14.0);
            self.emit(if (wet) .splash else .land, impact / 30.0, 0);
        }
        if (wet and self.grounded and !self.swimming) self.emit(.splash, 0.4, 0);
        self.swimming = wet and self.grounded;

        // timers
        self.air_time = if (self.grounded) 0.0 else self.air_time + dt;
        self.coyote = @max(self.coyote - dt, 0.0);
        self.buffer = @max(self.buffer - dt, 0.0);

        // the body: face where it is going, hop while running, wobble after jumps and landings
        const speed = @sqrt(self.vel.x * self.vel.x + self.vel.z * self.vel.z);
        if (speed > 0.6) {
            const heading = std.math.atan2(self.vel.x, -self.vel.z);
            self.yaw += math.angleDelta(self.yaw, heading) * math.clamp01(feel.turn_rate * dt);
        }
        if (self.grounded and speed > 0.6) {
            const before = self.stride;
            self.stride += speed * dt * 0.55;
            if (@floor(self.stride) != @floor(before)) self.emit(.step, speed / feel.dash_speed, 0);
        }
        // a damped spring pulls the squash back to rest
        self.squash_vel += (-self.squash * 180.0 - self.squash_vel * 14.0) * dt;
        self.squash = std.math.clamp(self.squash + self.squash_vel * dt, -0.5, 0.6);
        self.spread = math.approach(self.spread, if (self.gliding) 1.0 else 0.0, 0.06, dt);
    }

    /// Where and how to draw the body.
    pub fn model(self: *const Player) Mat4 {
        const speed = @sqrt(self.vel.x * self.vel.x + self.vel.z * self.vel.z);
        const hop = if (self.grounded) @abs(@sin(self.stride * std.math.pi)) * 0.22 * math.clamp01(speed / 4.0) else 0.0;
        const tall = 1.0 + self.squash * 0.55;
        const wide = 1.0 / @sqrt(@max(tall, 0.3));
        // lean into the run, and forward into a glide
        const tilt = if (self.gliding) 0.55 else math.clamp01(speed / self.feel.dash_speed) * 0.22;
        return Mat4.translation(Vec3.init(self.pos.x, self.pos.y + hop, self.pos.z))
            .mul(Mat4.rotationY(std.math.pi - self.yaw))
            .mul(Mat4.rotationX(tilt))
            .mul(Mat4.scaling(wide, tall, wide));
    }
};

/// A camera that follows behind and above, turned by the right stick.
pub const Camera = struct {
    yaw: f32 = 0.0,
    /// Height of the camera above the creature's horizon, in radians.
    pitch: f32 = 0.24,
    distance: f32 = 7.5,
    focus: Vec3 = .{},
    eye: Vec3 = .{},
    idle: f32 = 0.0,
    /// How far the picture is slid down the screen, so the creature sits in the lower third.
    pub const lower_third: f32 = 0.34;
    pub const fov: f32 = 1.05;
    pub const near: f32 = 0.3;
    pub const far: f32 = 1400.0;

    pub fn init(player: *const Player) Camera {
        var self = Camera{};
        self.yaw = player.yaw;
        self.focus = player.pos.add(Vec3.init(0.0, 1.0, 0.0));
        self.place(null);
        return self;
    }

    fn place(self: *Camera, things: ?*const land.Things) void {
        const forward = Vec3.init(@sin(self.yaw), 0.0, -@cos(self.yaw));
        const back = self.distance * @cos(self.pitch);
        self.eye = self.focus.sub(forward.scale(back)).add(Vec3.init(0.0, self.distance * @sin(self.pitch), 0.0));
        if (things) |world| {
            const floor_y = @max(world.standingHeight(self.eye.x, self.eye.z), land.waterLevel()) + 0.6;
            if (self.eye.y < floor_y) self.eye.y = floor_y;
        }
    }

    /// `look_x`, `look_y`: right stick, -1..1, y negative when pushed away.
    pub fn update(self: *Camera, player: *const Player, things: *const land.Things, look_x: f32, look_y: f32, dt: f32) void {
        self.yaw += look_x * 2.7 * dt;
        self.pitch = std.math.clamp(self.pitch + look_y * 1.7 * dt, -0.30, 1.25);

        // left alone while the creature runs, the camera drifts round behind it
        const looking = @abs(look_x) > 0.05 or @abs(look_y) > 0.05;
        self.idle = if (looking) 0.0 else self.idle + dt;
        const speed = @sqrt(player.vel.x * player.vel.x + player.vel.z * player.vel.z);
        if (self.idle > 1.2 and speed > 2.0) {
            self.yaw += math.angleDelta(self.yaw, player.yaw) * math.clamp01(0.9 * dt);
        }

        // follow: quick sideways, softer in height so hops do not shake the view
        const want = player.pos.add(Vec3.init(0.0, 1.0, 0.0));
        self.focus.x = math.approach(self.focus.x, want.x, 0.05, dt);
        self.focus.z = math.approach(self.focus.z, want.z, 0.05, dt);
        self.focus.y = math.approach(self.focus.y, want.y, if (player.grounded) 0.12 else 0.07, dt);

        // pull back when it is high in the air, to show where it could land
        const want_distance: f32 = if (player.gliding or player.air_time > 0.5) 12.5 else 7.5;
        self.distance = math.approach(self.distance, want_distance, 0.35, dt);
        self.place(things);
    }

    pub fn view(self: *const Camera) Mat4 {
        return Mat4.lookAt(self.eye, self.focus.add(Vec3.init(0.0, 0.5, 0.0)), Vec3.init(0.0, 1.0, 0.0));
    }

    pub fn projection(aspect: f32) Mat4 {
        var proj = Mat4.perspective(fov, aspect, near, far);
        proj.m[9] = lower_third;
        return proj;
    }
};

fn stepFor(player: *Player, things: *const land.Things, in: Input, seconds: f32) void {
    const dt: f32 = 1.0 / 60.0;
    var t: f32 = 0.0;
    while (t < seconds) : (t += dt) player.step(things, in, 0.0, dt);
}

fn openGround(things: *const land.Things) Player {
    // a spot on the path, away from stones and mushrooms
    return Player.init(things, 150.0, 172.0);
}

test "it stands still when nothing is pressed" {
    const things = land.Things.generate(1);
    var player = openGround(&things);
    const start = player.pos;
    stepFor(&player, &things, .{}, 2.0);
    try std.testing.expectApproxEqAbs(start.x, player.pos.x, 0.01);
    try std.testing.expectApproxEqAbs(start.z, player.pos.z, 0.01);
    try std.testing.expect(player.grounded);
}

test "pushing the stick away runs toward where the camera looks" {
    const things = land.Things.generate(1);
    var player = openGround(&things);
    const start = player.pos;
    stepFor(&player, &things, .{ .move_y = -1.0 }, 1.0);
    try std.testing.expect(player.pos.z < start.z - 6.0);
    try std.testing.expectApproxEqAbs(start.x, player.pos.x, 0.5);
    // and it stops soon after letting go
    stepFor(&player, &things, .{}, 0.5);
    try std.testing.expect(@abs(player.vel.z) < 0.01);
}

test "a held jump rises about three body heights and a tap much less" {
    const things = land.Things.generate(1);
    var held = openGround(&things);
    const ground = held.pos.y;
    var peak: f32 = 0.0;
    for (0..40) |_| {
        held.step(&things, .{ .jump = true }, 0.0, 1.0 / 60.0);
        peak = @max(peak, held.pos.y - ground);
    }
    try std.testing.expect(peak > 2.6 and peak < 3.4);

    var tapped = openGround(&things);
    var low: f32 = 0.0;
    for (0..40) |i| {
        tapped.step(&things, .{ .jump = i < 3 }, 0.0, 1.0 / 60.0);
        low = @max(low, tapped.pos.y - ground);
    }
    try std.testing.expect(low < peak * 0.6);
}

test "holding jump while falling glides" {
    const things = land.Things.generate(1);
    var player = openGround(&things);
    player.pos.y += 30.0;
    player.grounded = false;
    stepFor(&player, &things, .{ .jump = true }, 1.5);
    try std.testing.expect(player.gliding);
    try std.testing.expect(player.vel.y > -3.0);

    var stone = openGround(&things);
    stone.pos.y += 30.0;
    stone.grounded = false;
    stepFor(&stone, &things, .{}, 0.8);
    try std.testing.expect(stone.vel.y < -20.0);
}

test "a mushroom cap throws the creature far higher than a jump" {
    const things = land.Things.generate(1);
    var index: usize = 0;
    for (things.plants[0..things.plant_count], 0..) |plant, i| {
        if (plant.kind == .mushroom) {
            index = i;
            break;
        }
    }
    const cap = things.plants[index];
    var player = Player.init(&things, cap.x, cap.z);
    player.pos.y = land.Things.capHeight(cap) + 3.0;
    player.grounded = false;
    var peak: f32 = 0.0;
    var bounced = false;
    for (0..180) |_| {
        player.step(&things, .{}, 0.0, 1.0 / 60.0);
        peak = @max(peak, player.pos.y - land.Things.capHeight(cap));
        var events: [16]Event = undefined;
        for (events[0..player.drainEvents(&events)]) |event| {
            if (event.kind == .bounce) bounced = true;
        }
    }
    try std.testing.expect(bounced);
    try std.testing.expect(peak > 14.0);
}

test "it never leaves the meadow or sinks through the floor" {
    const things = land.Things.generate(1);
    var player = openGround(&things);
    var seed: u32 = 99;
    for (0..12000) |i| {
        if (i % 45 == 0) seed = seed *% 1664525 +% 1013904223;
        const mx = @as(f32, @floatFromInt(seed >> 8 & 0xff)) / 127.5 - 1.0;
        const my = @as(f32, @floatFromInt(seed >> 16 & 0xff)) / 127.5 - 1.0;
        player.step(&things, .{ .move_x = mx, .move_y = my, .jump = (seed >> 24) & 3 == 0, .dash = true }, 0.7, 1.0 / 60.0);
        try std.testing.expect(player.pos.x >= land.margin - 0.01 and player.pos.x <= land.size - land.margin + 0.01);
        try std.testing.expect(player.pos.z >= land.margin - 0.01 and player.pos.z <= land.size - land.margin + 0.01);
        try std.testing.expect(player.pos.y >= land.groundHeight(player.pos.x, player.pos.z) - 0.6);
    }
}

test "the camera stays behind the creature and above the ground" {
    const things = land.Things.generate(1);
    var player = openGround(&things);
    var camera = Camera.init(&player);
    for (0..240) |_| {
        player.step(&things, .{ .move_y = -1.0 }, camera.yaw, 1.0 / 60.0);
        camera.update(&player, &things, 0.0, 0.0, 1.0 / 60.0);
        try std.testing.expect(camera.eye.y > things.standingHeight(camera.eye.x, camera.eye.z));
    }
    const gap = camera.eye.sub(player.pos);
    try std.testing.expect(gap.length() > 4.0 and gap.length() < 16.0);
    // behind: the creature runs toward -z, so the camera's z is greater
    try std.testing.expect(camera.eye.z > player.pos.z);
}
