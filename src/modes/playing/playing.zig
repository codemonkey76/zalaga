const std = @import("std");
const engine = @import("engine");
const Context = @import("../../context.zig").Context;
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;
const Entity = @import("../../entities/entity.zig").Entity;
const EntityManager = @import("../../entities/entity_manager.zig").EntityManager;
const EntityType = @import("../../entities/entity.zig").EntityType;
const CollisionSystem = @import("../../systems/collision.zig").CollisionSystem;
const CollisionPair = @import("../../systems/collision.zig").CollisionPair;
const PlayerController = @import("../../systems/player_controller.zig").PlayerController;
const ExplosionSystem = @import("../../systems/explosion.zig").ExplosionSystem;
const MovementSystem = @import("../../systems/movement.zig").MovementSystem;

pub const Playing = struct {
    allocator: std.mem.Allocator,
    collision_system: CollisionSystem,
    player_controller: PlayerController,
    explosion_system: ExplosionSystem,
    player_id: ?u32,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *Context) !Self {
        _ = ctx;
        return .{
            .allocator = allocator,
            .collision_system = CollisionSystem.init(allocator),
            .player_controller = PlayerController{},
            .explosion_system = ExplosionSystem.init(allocator),
            .player_id = null,
        };
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32, state: *GameState) !?GameMode {
        // Spawn player if not present
        if (self.player_id == null) {
            self.player_id = try state.entity_manager.spawnPlayer(.{ .x = 0.5, .y = 0.85 });
            state.player_state.is_active = true;
        }

        // Get player entity
        if (state.entity_manager.get(self.player_id.?)) |player| {
            // Update player controller
            try self.player_controller.update(player, &state.entity_manager, ctx, dt);
        }

        // Update movement for all entities
        MovementSystem.update(state.entity_manager.getAll(), dt);

        // Check collisions
        try self.collision_system.checkCollisions(state.entity_manager.getAll());

        // Process collisions
        for (self.collision_system.getCollisions()) |collision| {
            try self.handleCollision(collision, state);
        }

        // Update explosions
        self.explosion_system.update(dt);

        // Clean up dead entities
        state.entity_manager.compact();

        // Check for game over
        if (state.player_state.lives == 0) {
            return .high_score;
        }

        return null;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *GameState) !void {
        // Draw all entities
        for (state.entity_manager.getAll()) |entity| {
            if (!entity.active) continue;

            if (entity.type == .projectile) {
                // Draw projectiles using bullet sprites
                if (entity.bullet_sprite_id) |bullet_id| {
                    if (state.sprites.getBulletSprite(bullet_id)) |sprite| {
                        ctx.renderer.drawSprite(sprite, entity.position);
                    }
                } else {
                    // Fallback to circles if no sprite
                    const color = switch (entity.collision_layer) {
                        .player_projectile => engine.types.Color.yellow,
                        .enemy_projectile => engine.types.Color.red,
                        else => engine.types.Color.white,
                    };
                    ctx.renderer.drawFilledCircle(entity.position, 0.005, color);
                }
            } else if (entity.sprite_type) |sprite_type| {
                // Draw sprite-based entities
                if (entity.sprite_id) |sprite_id| {
                    if (state.sprites.getSprite(sprite_type, sprite_id)) |sprite| {
                        ctx.renderer.drawSprite(sprite, entity.position);
                    }
                }
            }
        }

        // Draw explosions
        self.explosion_system.draw(ctx);
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = ctx;
        self.collision_system.deinit();
        self.explosion_system.deinit();
    }

    fn handleCollision(self: *Self, collision: CollisionPair, state: *GameState) !void {
        var entity_a = state.entity_manager.get(collision.entity_a) orelse return;
        var entity_b = state.entity_manager.get(collision.entity_b) orelse return;

        // Determine what hit what
        const is_player_hit = entity_a.collision_layer == .player or entity_b.collision_layer == .player;
        const is_enemy_hit = entity_a.collision_layer == .enemy or entity_b.collision_layer == .enemy;
        const is_player_projectile = entity_a.collision_layer == .player_projectile or entity_b.collision_layer == .player_projectile;

        entity_a.health -= 1;
        entity_b.health -= 1;

        if (entity_a.health <= 0) {
            try self.spawnExplosionFor(entity_a, state);
            entity_a.active = false;
        }
        if (entity_b.health <= 0) {
            try self.spawnExplosionFor(entity_b, state);
            entity_b.active = false;
        }

        if (is_enemy_hit and is_player_projectile) {
            const enemy = if (entity_a.collision_layer == .enemy) entity_a else entity_b;
            const points: u32 = switch (enemy.type) {
                .boss => 150,
                .goei => 80,
                .zako => 50,
                else => 0,
            };
            state.player_state.score += points;
        }

        if (is_player_hit) {
            if (state.player_state.lives > 0) {
                state.player_state.lives -= 1;
            }
            self.player_id = null;
        }
    }

    fn spawnExplosionFor(self: *Self, entity: *Entity, state: *GameState) !void {
        _ = state;

        const color = switch (entity.type) {
            .player => engine.types.Color.sky_blue,
            .boss, .goei, .zako => engine.types.Color.red,
            .projectile => engine.types.Color.yellow,
        };

        const particle_count: u32 = switch (entity.type) {
            .player => 30,
            .boss => 20,
            .goei, .zako => 15,
            .projectile => 5,
        };

        try self.explosion_system.spawnExplosion(entity.position, color, particle_count);
    }
};
