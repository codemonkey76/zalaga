const std = @import("std");
const engine = @import("engine");
const arcade_lib = @import("arcade_lib");
const Context = @import("../../mod.zig").Context;
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;
const Entity = @import("../../entities/entity.zig").Entity;
const EntityManager = @import("../../entities/entity_manager.zig").EntityManager;
const EntityType = @import("../../entities/entity.zig").EntityType;
const CollisionSystem = @import("../../systems/collision.zig").CollisionSystem;
const CollisionPair = @import("../../systems/collision.zig").CollisionPair;
const PlayerController = @import("../../systems/player_controller.zig").PlayerController;
const ExplosionSystem = @import("../../systems/explosion.zig").ExplosionSystem;
const SpriteExplosionSystem = @import("../../systems/sprite_explosion.zig").SpriteExplosionSystem;
const MovementSystem = @import("../../systems/movement.zig").MovementSystem;
const PathFollowingSystem = @import("../../systems/path_following.zig").PathFollowingSystem;
const FormationSystem = @import("../../systems/formation.zig").FormationSystem;
const StageManager = @import("../../gameplay/stage_manager.zig").StageManager;
const DebugMode = @import("../../core/debug_mode.zig").DebugMode;
const level_def = @import("../../gameplay/level_definition.zig");

pub const Playing = struct {
    allocator: std.mem.Allocator,
    collision_system: CollisionSystem,
    player_controller: PlayerController,
    explosion_system: ExplosionSystem,
    sprite_explosion_system: SpriteExplosionSystem,
    path_following_system: PathFollowingSystem,
    formation_system: FormationSystem,
    stage_manager: StageManager,
    debug_mode: DebugMode,
    player_id: ?u32,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *Context) !Self {
        _ = ctx;
        return .{
            .allocator = allocator,
            .collision_system = CollisionSystem.init(allocator),
            .player_controller = PlayerController{},
            .explosion_system = ExplosionSystem.init(allocator),
            .sprite_explosion_system = SpriteExplosionSystem.init(allocator),
            .path_following_system = PathFollowingSystem.init(allocator),
            .formation_system = FormationSystem.init(),
            .stage_manager = StageManager.init(allocator, &level_def.stage_1),
            .debug_mode = DebugMode.init(allocator),
            .player_id = null,
        };
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32, state: *GameState) !?GameMode {
        self.debug_mode.update(ctx);

        if (!self.debug_mode.shouldUpdate()) {
            return null;
        }

        try self.stage_manager.update(ctx, &state.entity_manager, dt);

        if (self.stage_manager.isIntroComplete()) {
            if (self.player_id == null) {
                self.player_id = self.stage_manager.player_id;
            }

            // Get player entity and update
            if (self.player_id) |player_id| {
                if (state.entity_manager.get(player_id)) |player| {
                    // Update player controller
                    try self.player_controller.update(player, &state.entity_manager, ctx, dt);
                }
            }
        }

        // Update path following for enemies
        try self.path_following_system.update(state.entity_manager.getAll(), ctx, dt);

        // Update movement for all entities
        MovementSystem.update(state.entity_manager.getAll(), &self.stage_manager, dt);

        // Update formation breathing
        self.formation_system.update(state.entity_manager.getAll(), dt);

        // Check collisions
        try self.collision_system.checkCollisions(state.entity_manager.getAll());

        // Process collisions
        for (self.collision_system.getCollisions()) |collision| {
            try self.handleCollision(collision, state, ctx);
        }

        // Update explosions
        self.explosion_system.update(dt);
        self.sprite_explosion_system.update(dt);

        // Clean up dead entities
        state.entity_manager.compact();

        // Check for game over
        if (state.player_state.lives == 0) {
            return .high_score;
        }

        return null;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *GameState) !void {
        if (!self.stage_manager.isIntroComplete()) {
            switch (self.stage_manager.getIntroState()) {
                .player_ready => {
                    const text = "PLAYER 1";
                    ctx.renderer.text.drawTextCentered(text, 0.5, 10, engine.types.Color.sky_blue);
                },
                .stage_ready => {
                    const stage_text = "STAGE 1";
                    ctx.renderer.text.drawTextCentered(stage_text, 0.5, 10, engine.types.Color.sky_blue);
                },
                .player_spawn => {
                    // Player is spawned, draw normally but no enemies yet
                    // Fall through to normal entity rendering
                },
                .complete => {
                    // Should never reach here, but fall through to normal rendering
                },
            }
        }

        // Only draw entities during player_spawn and after intro is complete
        if (self.stage_manager.getIntroState() == .player_spawn or
            self.stage_manager.isIntroComplete())
        {
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
                            // Use rotation set if entity is moving
                            if (entity.isMoving()) {
                                if (state.sprites.getRotationSet(sprite_type)) |rotation_set| {
                                    if (rotation_set.getSpriteForAngle(entity.angle)) |flipped| {
                                        ctx.renderer.drawFlippedSprite(flipped, entity.position);
                                        continue;
                                    }
                                }
                            }
                            ctx.renderer.drawSprite(sprite, entity.position);
                        }
                    }
                }
            }
            // Draw explosions
            self.explosion_system.draw(ctx);
            self.sprite_explosion_system.draw(ctx, state);
        }

        // Draw debug info (always available)
        if (self.debug_mode.enabled and self.debug_mode.show_angles) {
            try self.debug_mode.draw(ctx, state);
        }
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = ctx;
        self.collision_system.deinit();
        self.explosion_system.deinit();
        self.sprite_explosion_system.deinit();
        self.path_following_system.deinit();
        self.stage_manager.deinit();
        self.debug_mode.deinit();
    }

    fn handleCollision(self: *Self, collision: CollisionPair, state: *GameState, ctx: *Context) !void {
        var entity_a = state.entity_manager.get(collision.entity_a) orelse return;
        var entity_b = state.entity_manager.get(collision.entity_b) orelse return;

        // Determine what hit what
        const is_player_hit = entity_a.collision_layer == .player or entity_b.collision_layer == .player;
        const is_enemy_hit = entity_a.collision_layer == .enemy or entity_b.collision_layer == .enemy;
        const is_player_projectile = entity_a.collision_layer == .player_projectile or entity_b.collision_layer == .player_projectile;

        entity_a.health -= 1;
        entity_b.health -= 1;

        if (entity_a.health <= 0) {
            try self.spawnExplosionFor(entity_a, state, ctx);
            entity_a.active = false;
        }
        if (entity_b.health <= 0) {
            try self.spawnExplosionFor(entity_b, state, ctx);
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

    fn spawnExplosionFor(self: *Self, entity: *Entity, _: *GameState, ctx: *Context) !void {
        // Play death sound based on entity type
        switch (entity.type) {
            .player => ctx.assets.playSound(.die_player),
            .boss => ctx.assets.playSound(.die_boss),
            .goei => ctx.assets.playSound(.die_goei),
            .zako => ctx.assets.playSound(.die_zako),
            .projectile => {}, // No sound for projectiles
        }

        // Spawn sprite explosion
        switch (entity.type) {
            .player => try self.sprite_explosion_system.spawnPlayerExplosion(entity.position),
            .boss, .goei, .zako => try self.sprite_explosion_system.spawnEnemyExplosion(entity.position),
            .projectile => {
                // Projectiles just get particle effects
                const particle_count: u32 = 5;
                try self.explosion_system.spawnExplosion(entity.position, engine.types.Color.yellow, particle_count);
            },
        }
    }
};
