const std = @import("std");
const engine = @import("engine");
const z = @import("../mod.zig");
const level_def = @import("level_definition.zig");
const arcade_lib = @import("arcade_lib");

const Context = z.Context;
const EntityManager = z.EntityManager;
const StageDefinition = level_def.StageDefinition;
const StageState = level_def.StageState;
const Wave = level_def.Wave;
const SpawnGroup = level_def.SpawnGroup;
const EnemySpawn = level_def.EnemySpawn;
const GridPosition = level_def.GridPosition;
pub const EntityId = @import("../entities/entity.zig").EntityId;

/// Stage intro sequence states
pub const IntroState = enum {
    player_ready, // Display "PLAYER 1" text (4 seconds)
    stage_ready, // Display "STAGE 1" with ships/level indicator (2 seconds)
    player_spawn, // Spawn player and wait (2 seconds)
    complete, // Intro finished, gameplay begins
};

/// Per-group spawning state to track progress within a wave
const GroupState = struct {
    current_enemy: usize = 0,
    enemy_timer: f32 = 0,
};

/// Manages stage progression, enemy wave spawning, and intro sequences
///
/// The StageManager orchestrates the entire stage flow:
/// 1. Intro sequence (player ready -> stage ready -> player spawn)
/// 2. Wave-based enemy spawning (forming state)
/// 3. Ready state (all enemies in formation, waiting to attack)
/// 4. Active state (enemies can attack)
pub const StageManager = struct {
    allocator: std.mem.Allocator,
    stage_def: *const StageDefinition,
    state: StageState,

    // Player tracking
    player_id: ?EntityId,

    // Intro sequence
    intro_state: IntroState,
    intro_timer: f32,

    // Wave spawning state
    current_wave: usize,
    group_states: []GroupState,

    // Timers
    wave_timer: f32,
    ready_timer: f32,

    // Enemy tracking (global)
    enemies_spawned: u32,
    enemies_in_formation: u32,
    total_enemies: u32,

    // Enemy tracking (per-wave)
    wave_enemies_spawned: u32,
    wave_enemies_in_formation: u32,

    const Self = @This();

    // Intro timing constants
    const INTRO_PLAYER_READY_DURATION: f32 = 4.0;
    const INTRO_STAGE_READY_DURATION: f32 = 2.0;
    const INTRO_PLAYER_SPAWN_DURATION: f32 = 2.0;

    // Debug logging flag
    const DEBUG_LOGGING = true;

    pub fn init(allocator: std.mem.Allocator, stage_def: *const StageDefinition) Self {
        const total = countTotalEnemies(stage_def);

        if (DEBUG_LOGGING) {
            std.debug.print("\n[StageManager] Initializing stage\n", .{});
            std.debug.print("  Total waves: {d}\n", .{stage_def.waves.len});
            std.debug.print("  Total enemies: {d}\n", .{total});
            std.debug.print("  Attack delay: {d:.1}s\n", .{stage_def.attack_delay});
            std.debug.print("  Can shoot during entry: {}\n\n", .{stage_def.can_shoot_during_entry});
        }

        return .{
            .allocator = allocator,
            .stage_def = stage_def,
            .state = .forming,
            .player_id = null,
            .intro_state = .player_ready,
            .intro_timer = 0,
            .current_wave = 0,
            .group_states = &[_]GroupState{},
            .wave_timer = 0,
            .ready_timer = 0,
            .enemies_spawned = 0,
            .enemies_in_formation = 0,
            .total_enemies = total,
            .wave_enemies_spawned = 0,
            .wave_enemies_in_formation = 0,
        };
    }

    pub fn update(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !void {
        // Handle intro sequence first
        if (self.intro_state != .complete) {
            try self.updateIntro(ctx, entity_mgr, dt);
            return;
        }

        // Then handle stage states
        switch (self.state) {
            .forming => try self.updateFormingState(ctx, entity_mgr, dt),
            .ready => self.updateReadyState(dt),
            .active => self.updateActiveState(dt),
        }
    }

    /// Update the intro sequence (player ready -> stage ready -> player spawn -> complete)
    fn updateIntro(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !void {
        _ = ctx;
        self.intro_timer += dt;

        switch (self.intro_state) {
            .player_ready => {
                if (self.intro_timer >= INTRO_PLAYER_READY_DURATION) {
                    if (DEBUG_LOGGING) {
                        std.debug.print("[StageManager] Intro: player_ready -> stage_ready\n", .{});
                    }
                    self.intro_state = .stage_ready;
                    self.intro_timer = 0;
                }
            },
            .stage_ready => {
                // TODO: Play stage chirp sound here
                if (self.intro_timer >= INTRO_STAGE_READY_DURATION) {
                    if (DEBUG_LOGGING) {
                        std.debug.print("[StageManager] Intro: stage_ready -> player_spawn\n", .{});
                    }
                    self.intro_state = .player_spawn;
                    self.intro_timer = 0;
                }
            },
            .player_spawn => {
                // Spawn player on first frame of this state
                if (self.player_id == null) {
                    self.player_id = try entity_mgr.spawnPlayer(.{ .x = 0.5, .y = 0.92 });
                    if (DEBUG_LOGGING) {
                        std.debug.print("[StageManager] Player spawned: ID={?d}\n", .{self.player_id});
                    }
                }

                if (self.intro_timer >= INTRO_PLAYER_SPAWN_DURATION) {
                    if (DEBUG_LOGGING) {
                        std.debug.print("[StageManager] Intro: player_spawn -> complete\n", .{});
                        std.debug.print("[StageManager] Beginning enemy wave spawning...\n\n", .{});
                    }
                    self.intro_state = .complete;
                    self.intro_timer = 0;
                }
            },
            .complete => {}, // Should never reach here
        }
    }

    /// Get current intro state for rendering
    pub fn getIntroState(self: Self) IntroState {
        return self.intro_state;
    }

    /// Check if intro sequence is complete
    pub fn isIntroComplete(self: Self) bool {
        return self.intro_state == .complete;
    }

    /// Update forming state - spawn enemy waves and wait for formation
    fn updateFormingState(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !void {
        // Check if all waves are complete
        if (self.current_wave >= self.stage_def.waves.len) {
            const alive_enemies = countAliveEnemies(entity_mgr);
            // Wait for all enemies to reach formation before transitioning to ready state
            if (self.enemies_in_formation >= alive_enemies) {
                if (DEBUG_LOGGING) {
                    std.debug.print("\n[StageManager] All enemies in formation!\n", .{});
                    std.debug.print("  Enemies spawned: {d}\n", .{self.enemies_spawned});
                    std.debug.print("  Enemies in formation: {d}\n", .{self.enemies_in_formation});
                    std.debug.print("[StageManager] State: forming -> ready\n\n", .{});
                }
                self.state = .ready;
                self.ready_timer = 0;
            }
            return;
        }

        const wave = &self.stage_def.waves[self.current_wave];

        // Wait for wave delay before spawning (except for first wave)
        self.wave_timer += dt;
        if (self.wave_timer < wave.wave_delay) {
            return;
        }

        // Initialize group states for this wave if needed
        if (self.group_states.len == 0) {
            if (DEBUG_LOGGING) {
                std.debug.print("\n[StageManager] Starting wave {d}/{d}\n", .{
                    self.current_wave + 1,
                    self.stage_def.waves.len,
                });
                std.debug.print("  Groups in wave: {d}\n", .{wave.groups.len});
                std.debug.print("  Wave delay: {d:.1}s\n\n", .{wave.wave_delay});
            }

            self.group_states = try self.allocator.alloc(GroupState, wave.groups.len);
            for (self.group_states) |*gs| {
                gs.* = .{};
            }
            // Reset per-wave counters
            self.wave_enemies_spawned = 0;
            self.wave_enemies_in_formation = 0;
        }

        // Process all spawn groups in parallel
        const all_groups_complete = try self.processSpawnGroups(ctx, entity_mgr, wave, dt);

        const alive_wave_enemies = countAliveWaveEnemies(entity_mgr, self.wave_enemies_spawned);
        if (all_groups_complete and self.wave_enemies_in_formation >= alive_wave_enemies) {
            if (DEBUG_LOGGING) {
                std.debug.print("\n[StageManager] Wave {d} complete!\n", .{self.current_wave + 1});
                std.debug.print("  Wave enemies spawned: {d}\n", .{self.wave_enemies_spawned});
                std.debug.print("  Wave enemies alive: {d}\n", .{alive_wave_enemies});
                std.debug.print("  Wave enemies in formation: {d}\n", .{self.wave_enemies_in_formation});
                std.debug.print("  Total spawned: {d}/{d}\n\n", .{
                    self.enemies_spawned,
                    self.total_enemies,
                });
            }
            self.advanceToNextWave();
        }
    }

    /// Count alive enemies in the entity manager
    fn countAliveEnemies(entity_mgr: *EntityManager) u32 {
        var count: u32 = 0;
        for (entity_mgr.getAll()) |entity| {
            if (entity.active and (entity.type == .boss or entity.type == .goei or entity.type == .zako)) {
                count += 1;
            }
        }
        return count;
    }

    /// Count alive enemies from the current wave (last N spawned)
    fn countAliveWaveEnemies(entity_mgr: *EntityManager, wave_spawned: u32) u32 {
        // This is trickier - we need to track which enemies belong to which wave
        // For now, just count all alive enemies as a simpler approach
        _ = wave_spawned;
        return countAliveEnemies(entity_mgr);
    }

    /// Process all spawn groups in a wave, returning true if all groups are complete
    fn processSpawnGroups(
        self: *Self,
        ctx: *Context,
        entity_mgr: *EntityManager,
        wave: *const Wave,
        dt: f32,
    ) !bool {
        var all_complete = true;

        for (wave.groups, 0..) |*group, group_idx| {
            const gs = &self.group_states[group_idx];

            // Skip if this group finished spawning
            if (gs.current_enemy >= group.enemies.len) {
                continue;
            }

            all_complete = false;

            const enemy_spawn = &group.enemies[gs.current_enemy];

            // Wait for enemy spawn delay
            gs.enemy_timer += dt;
            if (gs.enemy_timer < enemy_spawn.spawn_delay) {
                continue;
            }

            // Spawn the enemy
            try self.spawnEnemy(ctx, entity_mgr, enemy_spawn, group);

            // Update counters
            self.enemies_spawned += 1;
            self.wave_enemies_spawned += 1;
            gs.current_enemy += 1;

            if (DEBUG_LOGGING) {
                std.debug.print("[StageManager] Enemy spawned: wave={d} group={d} enemy={d}/{d} total={d}/{d}\n", .{
                    self.current_wave + 1,
                    group_idx + 1,
                    gs.current_enemy,
                    group.enemies.len,
                    self.enemies_spawned,
                    self.total_enemies,
                });
            }
        }

        return all_complete;
    }

    /// Advance to the next wave
    fn advanceToNextWave(self: *Self) void {
        self.allocator.free(self.group_states);
        self.group_states = &[_]GroupState{};
        self.current_wave += 1;
        self.wave_timer = 0;
    }

    /// Update ready state - wait before allowing enemies to attack
    fn updateReadyState(self: *Self, dt: f32) void {
        self.ready_timer += dt;
        if (self.ready_timer >= self.stage_def.attack_delay) {
            if (DEBUG_LOGGING) {
                std.debug.print("[StageManager] State: ready -> active\n", .{});
                std.debug.print("[StageManager] Enemies can now attack!\n\n", .{});
            }
            self.state = .active;
        }
    }

    /// Update active state - enemies can now attack
    fn updateActiveState(_: *Self, _: f32) void {
        // Attack logic is handled by enemy AI system
    }

    /// Spawn a single enemy and configure its behavior
    fn spawnEnemy(
        _: *Self,
        ctx: *Context,
        entity_mgr: *EntityManager,
        enemy_spawn: *const EnemySpawn,
        group: *const SpawnGroup,
    ) !void {
        // Get the entry path from assets
        const path = ctx.assets.getPath(group.entry_path) orelse {
            return error.PathNotLoaded;
        };

        // Get starting position from path
        const arcade_start = path.definition.getPosition(0.0);
        const start_pos = engine.types.Vec2{
            .x = arcade_start.x,
            .y = arcade_start.y,
        };

        // Convert sprite type to entity type
        const entity_type = spriteTypeToEntityType(enemy_spawn.enemy_type);

        // Spawn the enemy entity
        const enemy_id = try entity_mgr.spawnEnemy(
            entity_type,
            enemy_spawn.enemy_type,
            start_pos,
        );

        // Configure enemy to follow its entry path
        if (entity_mgr.get(enemy_id)) |enemy| {
            enemy.behavior = .path_following;
            enemy.current_path = group.entry_path;
            enemy.path_t = 0;

            // Store formation position if assigned
            if (enemy_spawn.grid_pos) |grid_pos| {
                enemy.formation_pos = gridToWorldPosition(grid_pos);
            }
        }
    }

    /// Notify that an enemy reached its formation position
    pub fn notifyEnemyInFormation(self: *Self) void {
        self.enemies_in_formation += 1;
        self.wave_enemies_in_formation += 1;

        if (DEBUG_LOGGING) {
            std.debug.print("[StageManager] Enemy reached formation: wave={d}/{d} total={d}/{d}\n", .{
                self.wave_enemies_in_formation,
                self.wave_enemies_spawned,
                self.enemies_in_formation,
                self.enemies_spawned,
            });
        }
    }

    /// Check if enemies can shoot during entry (stage-specific setting)
    pub fn canShootDuringEntry(self: Self) bool {
        return self.stage_def.can_shoot_during_entry;
    }

    /// Check if enemies can attack (only in active state)
    pub fn canEnemiesAttack(self: Self) bool {
        return self.state == .active;
    }

    pub fn deinit(self: *Self) void {
        if (self.group_states.len > 0) {
            self.allocator.free(self.group_states);
        }
    }
};

/// Count total number of enemies across all waves
fn countTotalEnemies(stage_def: *const StageDefinition) u32 {
    var count: u32 = 0;
    for (stage_def.waves) |wave| {
        for (wave.groups) |group| {
            count += @intCast(group.enemies.len);
        }
    }
    return count;
}

/// Convert sprite type to entity type
fn spriteTypeToEntityType(sprite_type: z.assets.SpriteType) z.EntityType {
    return switch (sprite_type) {
        .player, .player_alt => .player,
        .boss, .boss_alt => .boss,
        .goei => .goei,
        .zako => .zako,
        else => .zako,
    };
}

/// Convert grid position to world coordinates (normalized 0-1 space)
///
/// The Galaga formation uses a 10-column by 6-row grid centered on screen
/// Rows 0-1 (bosses) have larger spacing, rows 2-5 (enemies) have tighter spacing
fn gridToWorldPosition(grid_pos: GridPosition) engine.types.Vec2 {
    // Grid configuration
    const GRID_COLUMNS: f32 = 10.0;
    const GRID_HORIZONTAL_MARGIN: f32 = 0.13; // Left/right margin for centering
    const GRID_TOP_OFFSET: f32 = 0.10; // Distance from top of screen
    const BOSS_ROW_HEIGHT: f32 = 0.055; // Vertical spacing for boss rows (0-1)
    const ENEMY_ROW_HEIGHT: f32 = 0.040; // Tighter spacing for enemy rows (2-5)

    const cell_width = (1.0 - GRID_HORIZONTAL_MARGIN * 2.0) / GRID_COLUMNS;

    // Calculate Y position with different spacing for boss vs enemy rows
    const y_pos = if (grid_pos.row <= 1)
        // Boss rows (0-1): use larger spacing
        GRID_TOP_OFFSET + @as(f32, @floatFromInt(grid_pos.row)) * BOSS_ROW_HEIGHT
    else
        // Enemy rows (2-5): use tighter spacing, offset by boss row height
        GRID_TOP_OFFSET + (2.0 * BOSS_ROW_HEIGHT) + @as(f32, @floatFromInt(grid_pos.row - 2)) * ENEMY_ROW_HEIGHT;

    return engine.types.Vec2{
        .x = GRID_HORIZONTAL_MARGIN + (@as(f32, @floatFromInt(grid_pos.col)) - 0.5) * cell_width,
        .y = y_pos,
    };
}
