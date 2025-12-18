const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const EntityManager = @import("../entities/entity_manager.zig").EntityManager;

pub const PlayerController = struct {
    player_speed: f32 = 0.5, // Normalized units per second
    shoot_cooldown: f32 = 0.2, // Seconds between shots
    current_cooldown: f32 = 0.0,

    const Self = @This();

    pub fn update(
        self: *Self,
        player: *Entity,
        entity_manager: *EntityManager,
        ctx: *engine.Context,
        dt: f32,
    ) !void {
        // Update shoot cooldown
        if (self.current_cooldown > 0) {
            self.current_cooldown -= dt;
        }

        // Movement input
        var move_x: f32 = 0;
        var move_y: f32 = 0;

        if (ctx.input.isKeyDown(.left) or ctx.input.isKeyDown(.a)) {
            move_x -= 1;
        }
        if (ctx.input.isKeyDown(.right) or ctx.input.isKeyDown(.d)) {
            move_x += 1;
        }
        if (ctx.input.isKeyDown(.up) or ctx.input.isKeyDown(.w)) {
            move_y -= 1;
        }
        if (ctx.input.isKeyDown(.down) or ctx.input.isKeyDown(.s)) {
            move_y += 1;
        }

        // Apply movement
        if (move_x != 0 or move_y != 0) {
            // Normalize diagonal movement
            const magnitude = @sqrt(move_x * move_x + move_y * move_y);
            move_x /= magnitude;
            move_y /= magnitude;

            player.position.x += move_x * self.player_speed * dt;
            player.position.y += move_y * self.player_speed * dt;

            // Clamp to screen bounds (with margin for sprite)
            const margin = 0.02;
            player.position.x = @max(margin, @min(1.0 - margin, player.position.x));
            player.position.y = @max(margin, @min(1.0 - margin, player.position.y));
        }

        // Shooting input
        if (ctx.input.isKeyDown(.space) or ctx.input.isKeyDown(.z)) {
            if (self.current_cooldown <= 0) {
                try self.shoot(player, entity_manager);
                self.current_cooldown = self.shoot_cooldown;
            }
        }
    }

    fn shoot(self: *Self, player: *Entity, entity_manager: *EntityManager) !void {
        _ = self;
        
        // Spawn projectile slightly above player
        const bullet_pos = engine.types.Vec2{
            .x = player.position.x,
            .y = player.position.y - 0.03,
        };

        const bullet_velocity = engine.types.Vec2{
            .x = 0,
            .y = -0.8, // Move up at 0.8 normalized units/second
        };

        _ = try entity_manager.spawnProjectile(
            bullet_pos,
            bullet_velocity,
            .player,
        );
    }
};
