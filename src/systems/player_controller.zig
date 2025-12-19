const std = @import("std");
const engine = @import("engine");
const Context = @import("../context.zig").Context;
const Entity = @import("../entities/entity.zig").Entity;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;
const EntityType = @import("../entities/entity.zig").EntityType;
const CollisionLayer = @import("../entities/entity.zig").CollisionLayer;

pub const PlayerController = struct {
    player_speed: f32 = 0.5, // Normalized units per second
    shoot_cooldown: f32 = 0.01, // Seconds between shots
    current_cooldown: f32 = 0.0,

    const Self = @This();

    pub fn update(
        self: *Self,
        player: *Entity,
        entity_manager: *EntityManager,
        ctx: *Context,
        dt: f32,
    ) !void {
        if (self.current_cooldown > 0) {
            self.current_cooldown -= dt;
        }

        var move_x: f32 = 0;

        if (ctx.input.isKeyDown(.left) or ctx.input.isKeyDown(.a)) {
            move_x -= 1;
        }

        if (ctx.input.isKeyDown(.right) or ctx.input.isKeyDown(.d)) {
            move_x += 1;
        }

        if (move_x != 0) {
            player.position.x += move_x * self.player_speed * dt;

            const margin = 0.025;
            player.position.x = @max(margin, @min(1.0 - margin, player.position.x));
        }

        if (ctx.input.isKeyPressed(.space) or ctx.input.isKeyPressed(.z)) {
            if (self.current_cooldown <= 0) {
                try self.shoot(player, entity_manager, ctx);
                self.current_cooldown = self.shoot_cooldown;
            }
        }
    }

    fn shoot(self: *Self, player: *Entity, entity_manager: *EntityManager, ctx: *Context) !void {
        _ = self;

        var bullet_count: u32 = 0;
        for (entity_manager.getAll()) |entity| {
            if (entity.active and entity.type == .projectile and entity.collision_layer == .player_projectile) {
                bullet_count += 1;
            }
        }

        if (bullet_count >= 2) return;

        ctx.audio.playSound(.shoot);

        const bullet_pos = engine.types.Vec2{
            .x = player.position.x,
            .y = player.position.y,
        };

        const bullet_velocity = engine.types.Vec2{
            .x = 0,
            .y = -0.8,
        };

        _ = try entity_manager.spawnProjectile(
            bullet_pos,
            bullet_velocity,
            .player,
        );
    }
};
