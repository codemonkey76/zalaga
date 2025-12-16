const std = @import("std");
const engine = @import("engine");
const types = engine.types;
const Gfx = engine.Gfx;

const Star = struct {
    x: f32,
    y: f32,
    speed: f32,
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
    speed: f32 = 60.0,
    shoot_speed: f32 = 1200.0,
    randomness: f32 = 40.0,
    size: u32 = 1,
    twinkle_chance: f32 = 0.3,
    shoot_chance: f32 = 0.01,
    tail_length: f32 = 24.0,
    parallax_strength: f32 = 20.0,
};

pub const Starfield = struct {
    allocator: std.mem.Allocator,
    width: f32,
    height: f32,
    cfg: StarfieldConfig,
    stars: []Star,
    active_stars: usize,
    prng: std.Random.DefaultPrng,
    parallax_phase: f32,

    pub fn init(
        allocator: std.mem.Allocator,
        ctx: *engine.Context,
        cfg: StarfieldConfig,
    ) !@This() {
        const prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp()));
        const width = @as(f32, @floatFromInt(ctx.viewport.virtual_width * ctx.viewport.ssaa_scale));
        const height = @as(f32, @floatFromInt(ctx.viewport.virtual_height * ctx.viewport.ssaa_scale));

        var self = Starfield{
            .allocator = allocator,
            .width = width,
            .height = height,
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

    fn randomStarColor(self: *@This(), is_shooting: bool) types.Color {
        if (is_shooting) {
            return types.Color.white;
        }

        const t = self.rand01();

        if (t < 0.60) {
            // blue-ish white
            return types.Color{
                .r = @intFromFloat(180 + self.randRange(-20, 20)),
                .g = @intFromFloat(180 + self.randRange(-10, 20)),
                .b = @intFromFloat(200 + self.randRange(-10, 40)),
                .a = 255,
            };
        } else if (t < 0.85) {
            // warm yellow-ish
            return types.Color{
                .r = @intFromFloat(200 + self.randRange(-20, 20)),
                .g = @intFromFloat(200 + self.randRange(-20, 20)),
                .b = @intFromFloat(150 + self.randRange(-20, 10)),
                .a = 255,
            };
        } else if (t < 0.95) {
            // slight red tint
            return types.Color{
                .r = @intFromFloat(200 + self.randRange(-10, 20)),
                .g = @intFromFloat(100 + self.randRange(-20, 20)),
                .b = @intFromFloat(100 + self.randRange(-20, 20)),
                .a = 255,
            };
        } else {
            // rare pure white
            return types.Color.white;
        }
    }

    fn randRange(self: *@This(), start: f32, end: f32) f32 {
        return start + self.rand01() * (end - start);
    }

    fn randomizeAll(self: *@This()) void {
        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            self.randomizeStar(&self.stars[i], true);
        }
    }

    pub fn update(self: *@This(), dt: f32, ctx: anytype) void {
        _ = ctx;

        const osc_speed: f32 = 0.5;
        self.parallax_phase += dt * (osc_speed * 2.0 * std.math.pi);

        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            var star = &self.stars[i];

            // Move
            star.y += star.speed * dt;

            if (star.y > self.height) {
                self.randomizeStar(star, false);
                continue;
            }
            // Twinkle: flip visible flag based on timer
            if (star.can_twinkle and (self.cfg.twinkle_min > 0 or self.cfg.twinkle_max > 0)) {
                star.twinkle_timer -= dt;
                if (star.twinkle_timer <= 0) {
                    star.visible = !star.visible;

                    const tw_min = self.cfg.twinkle_min;
                    const tw_max = self.cfg.twinkle_max;

                    const base = if (tw_max > tw_min)
                        self.randRange(tw_min, tw_max)
                    else
                        tw_min;

                    star.twinkle_duration = base;
                    star.twinkle_timer += base;
                }
            } else {
                star.visible = true;
            }
        }
    }

    fn randomizeStar(self: *@This(), star: *Star, start_anywhere: bool) void {
        const x = self.rand01() * self.width;
        const y = if (start_anywhere)
            self.rand01() * self.height
        else
            0.0;

        // Decide if this is a shooting star
        const is_shooting = self.rand01() < self.cfg.shoot_chance;

        // Base speed
        var speed: f32 = if (is_shooting)
            self.cfg.shoot_speed
        else
            self.cfg.speed;

        // Add randomness band
        if (self.cfg.randomness > 0) {
            const delta = self.randRange(-self.cfg.randomness, self.cfg.randomness);
            speed += delta;
            if (speed < 0) speed = 0;
        }

        // Color: normal vs shooting star
        const color = self.randomStarColor(is_shooting);

        // Decide if this star can twinkle at all
        const can_twinkle = (!is_shooting) and (self.rand01() < self.cfg.twinkle_chance);

        const tw_min = self.cfg.twinkle_min;
        const tw_max = self.cfg.twinkle_max;

        var twinkle_duration: f32 = 0;
        var twinkle_timer: f32 = 0;

        if (can_twinkle and (tw_max > 0 or tw_min > 0)) {
            const base = if (tw_max > tw_min)
                self.randRange(tw_min, tw_max)
            else
                tw_min;

            twinkle_duration = base;
            // Random phase so they don't all blink together
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

    pub fn draw(self: *const @This(), ctx: *engine.Context) void {
        _ = ctx;
        const radius: f32 = @floatFromInt(self.cfg.size);
        var px = self.parallax_phase;

        if (px < -1.0) px = -1.0;
        if (px > 1.0) px = 1.0;

        var i: usize = 0;
        while (i < self.active_stars) : (i += 1) {
            const star = self.stars[i];
            if (!star.visible) continue;

            // Depth factor: faster starrs parallax more
            const base_speed = if (self.cfg.shoot_speed > self.cfg.speed)
                self.cfg.shoot_speed
            else
                self.cfg.speed;

            const depth = if (base_speed > 0)
                star.speed / base_speed
            else
                1.0;

            const offset_x = px * self.cfg.parallax_strength * depth;

            const pos = types.Vec2{ .x = star.x + offset_x, .y = star.y };

            if (star.is_shooting) {
                const tail = types.Vec2{ .x = star.x + offset_x, .y = star.y - self.cfg.tail_length };
                Gfx.drawLine(tail, pos, star.color);
            } else {
                Gfx.drawCircle(pos, radius, star.color);
            }
        }
    }
};
