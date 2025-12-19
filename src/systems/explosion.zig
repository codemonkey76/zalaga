const std = @import("std");
const engine = @import("engine");
const Context = @import("../context.zig").Context;
const Entity = @import("../entities/entity.zig").Entity;

pub const ExplosionParticle = struct {
    position: engine.types.Vec2,
    velocity: engine.types.Vec2,
    lifetime: f32,
    max_lifetime: f32,
    color: engine.types.Color,
    size: f32,
};

pub const ExplosionSystem = struct {
    allocator: std.mem.Allocator,
    particles: std.ArrayList(ExplosionParticle),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .particles = std.ArrayList(ExplosionParticle){},
        };
    }

    pub fn deinit(self: *Self) void {
        self.particles.deinit(self.allocator);
    }

    /// Spawn explosion at position
    pub fn spawnExplosion(
        self: *Self,
        position: engine.types.Vec2,
        color: engine.types.Color,
        particle_count: u32,
    ) !void {
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp() + @as(i64, @intCast(self.particles.items.len))));
        const random = prng.random();

        var i: u32 = 0;
        while (i < particle_count) : (i += 1) {
            const angle = random.float(f32) * std.math.pi * 2.0;
            const speed = 0.1 + random.float(f32) * 0.2;
            
            const velocity = engine.types.Vec2{
                .x = @cos(angle) * speed,
                .y = @sin(angle) * speed,
            };

            const lifetime = 0.3 + random.float(f32) * 0.4;

            try self.particles.append(self.allocator, .{
                .position = position,
                .velocity = velocity,
                .lifetime = lifetime,
                .max_lifetime = lifetime,
                .color = color,
                .size = 0.005 + random.float(f32) * 0.005,
            });
        }
    }

    pub fn update(self: *Self, dt: f32) void {
        var i: usize = 0;
        while (i < self.particles.items.len) {
            var particle = &self.particles.items[i];
            
            particle.lifetime -= dt;
            if (particle.lifetime <= 0) {
                _ = self.particles.swapRemove(i);
                continue;
            }

            // Update position
            particle.position.x += particle.velocity.x * dt;
            particle.position.y += particle.velocity.y * dt;

            // Apply gravity/deceleration
            particle.velocity.y += 0.3 * dt;
            particle.velocity.x *= 0.98;
            particle.velocity.y *= 0.98;

            i += 1;
        }
    }

    pub fn draw(self: *Self, ctx: *Context) void {
        for (self.particles.items) |particle| {
            // Fade out over lifetime
            const alpha_factor = particle.lifetime / particle.max_lifetime;
            var color = particle.color;
            color.a = @intFromFloat(@as(f32, @floatFromInt(color.a)) * alpha_factor);

            ctx.renderer.drawFilledCircle(particle.position, particle.size, color);
        }
    }

    pub fn clear(self: *Self) void {
        self.particles.clearRetainingCapacity();
    }
};
