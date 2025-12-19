const std = @import("std");
const engine = @import("engine");
const types = engine.types;

const Star = struct {
    x: f32, // normalized 0..1
    y: f32, // normalized 0..1
    speed: f32, // virtual px/sec
    color: types.Color,
    twinkle_timer: f32,
    twinkle_duration: f32,
    visible: bool,
    is_shooting: bool,
    can_twinkle: bool,
};

pub const StarfieldConfig = struct {
    max_stars: u32 = 200,
    twinkle_min: f32 = 0.5,
    twinkle_max: f32 = 0.5,
    speed: f32 = 60.0, // virtual px/sec
    shoot_speed: f32 = 1200.0, // virtual px/sec
    randomness: f32 = 40.0, // +/- px/sec
    size: u32 = 1, // virtual px radius
    twinkle_chance: f32 = 0.3,
    shoot_chance: f32 = 0.01,
    tail_length: f32 = 24.0, // virtual px
    parallax_strength: f32 = 20.0, // virtual px
};

pub const Starfield = struct {
    allocator: std.mem.Allocator,
    cfg: StarfieldConfig,
    stars: []Star,
    active_stars: usize,
    prng: std.Random.DefaultPrng,
    parallax_phase: f32, // -1 to 1 based on player position

    pub fn init(
        allocator: std.mem.Allocator,
        _: *engine.Context,
        cfg: StarfieldConfig,
    ) !@This() {
        const prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));

        var self = Starfield{
            .allocator = allocator,
            .cfg = cfg,
            .stars = try allocator.alloc(Star, cfg.max_stars),
            .active_stars = cfg.max_stars,
            .prng = prng,
            .parallax_phase = 0.0,
        };

        self.randomizeAll();
        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.stars);
    }

    fn rand01(self: *@This()) f32 {
        return self.prng.random().float(f32);
    }

    fn randRange(self: *@This(), start: f32, end: f32) f32 {
        return start + self.rand01() * (end - start);
    }

    fn randomStarColor(self: *@This(), is_shooting: bool) types.Color {
        if (is_shooting) return types.Color.white;

        const t = self.rand01();

        if (t < 0.60) {
            return types.Color{
                .r = @intFromFloat(180 + self.randRange(-20, 20)),
                .g = @intFromFloat(180 + self.randRange(-10, 20)),
                .b = @intFromFloat(200 + self.randRange(-10, 40)),
                .a = 255,
            };
        } else if (t < 0.85) {
            return types.Color{
                .r = @intFromFloat(200 + self.randRange(-20, 20)),
                .g = @intFromFloat(200 + self.randRange(-20, 20)),
                .b = @intFromFloat(150 + self.randRange(-20, 10)),
                .a = 255,
            };
        } else if (t < 0.95) {
            return types.Color{
                .r = @intFromFloat(200 + self.randRange(-10, 20)),
                .g = @intFromFloat(100 + self.randRange(-20, 20)),
                .b = @intFromFloat(100 + self.randRange(-20, 20)),
                .a = 255,
            };
        } else {
            return types.Color.white;
        }
    }

    fn randomizeAll(self: *@This()) void {
        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            self.randomizeStar(&self.stars[i], true);
        }
    }

    fn randomizeStar(self: *@This(), star: *Star, start_anywhere: bool) void {
        const x = self.rand01();
        const y = if (start_anywhere) self.rand01() else 0.0;

        const is_shooting = self.rand01() < self.cfg.shoot_chance;

        var speed: f32 = if (is_shooting) self.cfg.shoot_speed else self.cfg.speed;

        if (self.cfg.randomness > 0) {
            speed += self.randRange(-self.cfg.randomness, self.cfg.randomness);
            if (speed < 0) speed = 0;
        }

        const color = self.randomStarColor(is_shooting);
        const can_twinkle = (!is_shooting) and (self.rand01() < self.cfg.twinkle_chance);

        const tw_min = self.cfg.twinkle_min;
        const tw_max = self.cfg.twinkle_max;

        var twinkle_duration: f32 = 0;
        var twinkle_timer: f32 = 0;

        if (can_twinkle and (tw_max > 0 or tw_min > 0)) {
            const base = if (tw_max > tw_min) self.randRange(tw_min, tw_max) else tw_min;
            twinkle_duration = base;
            twinkle_timer = self.randRange(0, base);
        }

        star.* = .{
            .x = x,
            .y = y,
            .speed = speed,
            .color = color,
            .twinkle_timer = twinkle_timer,
            .twinkle_duration = twinkle_duration,
            .visible = true,
            .is_shooting = is_shooting,
            .can_twinkle = can_twinkle,
        };
    }

    pub fn update(self: *@This(), ctx: *engine.Context, dt: f32, player_x: f32) void {
        const vh = @as(f32, @floatFromInt(ctx.viewport.virtual_height));

        // Use player position for parallax (-1 to 1 range, centered at 0.5)
        // Negate so stars move opposite to player movement
        self.parallax_phase = (0.5 - player_x) * 2.0;

        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            var star = &self.stars[i];

            // Move downward: speed is virtual px/sec -> normalized/sec
            star.y += (star.speed / vh) * dt;

            if (star.y > 1.0) {
                self.randomizeStar(star, false);
                continue;
            }

            if (star.can_twinkle and (self.cfg.twinkle_min > 0 or self.cfg.twinkle_max > 0)) {
                star.twinkle_timer -= dt;
                if (star.twinkle_timer <= 0) {
                    star.visible = !star.visible;

                    const tw_min = self.cfg.twinkle_min;
                    const tw_max = self.cfg.twinkle_max;

                    const base = if (tw_max > tw_min) self.randRange(tw_min, tw_max) else tw_min;
                    star.twinkle_duration = base;
                    star.twinkle_timer += base;
                }
            } else {
                star.visible = true;
            }
        }
    }

    pub fn draw(self: *const @This(), ctx: *engine.Context) void {
        const vw = @as(f32, @floatFromInt(ctx.viewport.virtual_width));
        const vh = @as(f32, @floatFromInt(ctx.viewport.virtual_height));

        // Config is in virtual px; renderer expects pixel sizes in RT space.
        const radius_rt: f32 = @as(f32, @floatFromInt(self.cfg.size));
        const tail_len_n: f32 = self.cfg.tail_length / vh;
        const parallax_n: f32 = self.cfg.parallax_strength / vw;

        var px = self.parallax_phase;
        if (px < -1.0) px = -1.0;
        if (px > 1.0) px = 1.0;

        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            const star = self.stars[i];
            if (!star.visible) continue;

            // Shooting stars don't have parallax effect
            const offset_x_n = if (star.is_shooting) 0.0 else blk: {
                const base_speed = if (self.cfg.shoot_speed > self.cfg.speed) self.cfg.shoot_speed else self.cfg.speed;
                const depth = if (base_speed > 0) star.speed / base_speed else 1.0;
                break :blk px * parallax_n * depth;
            };

            const pos_n = types.Vec2{ .x = star.x + offset_x_n, .y = star.y };

            if (star.is_shooting) {
                const tail_n = types.Vec2{ .x = star.x + offset_x_n, .y = star.y - tail_len_n };
                ctx.renderer.drawLine(tail_n, pos_n, 1.0, star.color);
            } else {
                ctx.renderer.drawFilledCircle(pos_n, radius_rt, star.color);
            }
        }
    }
};
