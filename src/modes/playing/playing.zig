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
const PathAsset = @import("../../assets/path_asset.zig").PathAsset;

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
    drawn_paths: std.AutoArrayHashMap(PathAsset, void),

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
            .stage_manager = StageManager.init(allocator, &level_def.stage_debug),
            .debug_mode = DebugMode.init(),
            .player_id = null,
            .drawn_paths = std.AutoArrayHashMap(PathAsset, void).init(allocator),
        };
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32, state: *GameState) !?GameMode {
        // Update debug mode controls
        self.debug_mode.update(ctx);

        // Only update game logic if not paused or stepping one frame
        if (!self.debug_mode.shouldUpdate()) {
            return null;
        }

        // Update stage manager (spawns enemies)
        try self.stage_manager.update(ctx, &state.entity_manager, dt);

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

        // Update path following for enemies
        try self.path_following_system.update(state.entity_manager.getAll(), ctx, dt);

        // Update movement for all entities
        MovementSystem.update(state.entity_manager.getAll(), dt);

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

    fn drawPath(self: *Self, path: arcade_lib.PathDefinition, ctx: *Context) void {
        _ = self;
        const segments = 300;
        const step = 1.0 / @as(f32, @floatFromInt(segments));

        var i: usize = 0;
        while (i < segments) : (i += 1) {
            const t1 = @as(f32, @floatFromInt(i)) * step;
            const t2 = @as(f32, @floatFromInt(i + 1)) * step;

            const pos1 = path.getPosition(t1);
            const pos2 = path.getPosition(t2);

            const p1 = engine.types.Vec2{
                .x = pos1.x,
                .y = pos1.y,
            };

            const p2 = engine.types.Vec2{
                .x = pos2.x,
                .y = pos2.y,
            };

            ctx.renderer.drawLine(p1, p2, 2, engine.types.Color.red);
        }
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
                self.drawn_paths.clearRetainingCapacity();

                const path_asset = entity.current_path orelse continue;
                if (ctx.assets.paths.get(path_asset)) |path| {
                    if (!self.drawn_paths.contains(path_asset)) {
                        self.drawPath(path.definition, ctx);
                        try self.drawn_paths.put(path_asset, {});
                    }
                }

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

        // Draw debug info
        if (self.debug_mode.enabled and self.debug_mode.show_angles) {
            self.drawDebugInfo(ctx, state);
        }
    }

    fn drawDebugInfo(self: *Self, ctx: *Context, state: *GameState) void {
        _ = self;

        var buffer: [256]u8 = undefined;
        var y_offset: f32 = 0.15;

        // Draw debug instructions
        const instructions = "P=Pause\nSPACE=Step\nA=Toggle Angles";
        ctx.renderer.text.drawText(instructions, .{ .x = 0.02, .y = y_offset }, 6, engine.types.Color.yellow);
        y_offset += 0.03;

        // Draw entity info for each enemy
        for (state.entity_manager.getAll()) |entity| {
            if (!entity.active) continue;
            if (entity.type == .player or entity.type == .projectile) continue;

            // Draw angle info next to entity
            const text = std.fmt.bufPrint(&buffer, "Angle: {d:.1}\nBehavior: {s}\nPathT: {d:.2}", .{
                entity.angle,
                @tagName(entity.behavior),
                entity.path_t,
            }) catch "Error";

            const text_pos = engine.types.Vec2{
                .x = entity.position.x + 0.05,
                .y = entity.position.y,
            };
            const cyan = engine.types.Color{ .r = 0, .g = 255, .b = 255, .a = 255 };
            ctx.renderer.text.drawText(text, text_pos, 6, cyan);

            // Draw direction line
            const line_length: f32 = 0.10;
            const angle_rad = entity.angle * std.math.pi / 180.0;
            const end_pos = engine.types.Vec2{
                .x = entity.position.x + @cos(angle_rad) * line_length,
                .y = entity.position.y + @sin(angle_rad) * line_length,
            };
            ctx.renderer.drawLine(entity.position, end_pos, 2, engine.types.Color.red);
        }
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = ctx;
        self.collision_system.deinit();
        self.explosion_system.deinit();
        self.sprite_explosion_system.deinit();
        self.path_following_system.deinit();
        self.stage_manager.deinit();
        self.drawn_paths.deinit();
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
