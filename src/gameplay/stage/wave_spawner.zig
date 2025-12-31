const std = @import("std");
const engine = @import("engine");
const z = @import("../../mod.zig");
const level_def = @import("../level_definition.zig");

const Context = z.Context;
const EntityManager = z.EntityManager;
const StageDefinition = level_def.StageDefinition;
const Wave = level_def.Wave;
const SpawnGroup = level_def.SpawnGroup;
const EnemySpawn = level_def.EnemySpawn;

const GroupState = struct {
    current_enemy: usize = 0,
    enemy_timer: f32 = 0,
};

/// Wave spawning handler
pub const WaveSpawner = struct {
    allocator: std.mem.Allocator,
    stage_def: *const StageDefinition,

    current_wave: usize = 0,
    group_states: []GroupState,
    wave_timer: f32 = 0,

    enemies_spawned: u32 = 0,
    wave_enemies_spawned: u32 = 0,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, stage_def: *const StageDefinition) Self {
        return .{
            .allocator = allocator,
            .stage_def = stage_def,
            .group_states = &[_]GroupState{},
        };
    }

    /// Update spawning, returns true if all waves are complete
    pub fn update(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !bool {
        if (self.current_wave >= self.stage_def.waves.len) {
            return true; // All waves complete
        }

        const wave = &self.stage_def.waves[self.current_wave];

        // Initialize group states for this wave
        if (self.group_states.len == 0) {
            self.group_states = try self.allocator.alloc(GroupState, wave.groups.len);
            for (self.group_states) |*gs| {
                gs.* = .{};
            }
            self.wave_enemies_spawned = 0;
            return false;
        }

        self.wave_timer += dt;
        if (self.wave_timer < wave.wave_delay) {
            return false;
        }

        // Process spawn groups
        const all_complete = try self.processSpawnGroups(ctx, entity_mgr, wave, dt);

        if (all_complete) {
            self.advanceToNextWave();
        }

        return false;
    }

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

            if (gs.current_enemy >= group.enemies.len) continue;

            all_complete = false;

            const enemy_spawn = &group.enemies[gs.current_enemy];
            gs.enemy_timer += dt;

            if (gs.enemy_timer < enemy_spawn.spawn_delay) continue;

            try spawnEnemy(ctx, entity_mgr, enemy_spawn, group);

            self.enemies_spawned += 1;
            self.wave_enemies_spawned += 1;
            gs.current_enemy += 1;
        }

        return all_complete;
    }

    fn advanceToNextWave(self: *Self) void {
        self.allocator.free(self.group_states);
        self.group_states = &[_]GroupState{};
        self.current_wave += 1;
        self.wave_timer = 0;
    }

    pub fn reset(self: *Self) void {
        if (self.group_states.len > 0) {
            self.allocator.free(self.group_states);
            self.group_states = &[_]GroupState{};
        }
        self.current_wave = 0;
        self.wave_timer = 0;
        self.enemies_spawned = 0;
        self.wave_enemies_spawned = 0;
    }

    pub fn deinit(self: *Self) void {
        if (self.group_states.len > 0) {
            self.allocator.free(self.group_states);
        }
    }
};

fn spawnEnemy(
    ctx: *Context,
    entity_mgr: *EntityManager,
    enemy_spawn: *const EnemySpawn,
    group: *const SpawnGroup,
) !void {
    const path = ctx.assets.getPath(group.entry_path) orelse {
        return error.PathNotLoaded;
    };

    const arcade_start = path.definition.getPosition(0.0);
    const start_pos = engine.types.Vec2{
        .x = arcade_start.x,
        .y = arcade_start.y,
    };

    const entity_type = spriteTypeToEntityType(enemy_spawn.enemy_type);
    const enemy_id = try entity_mgr.spawnEnemy(
        entity_type,
        enemy_spawn.enemy_type,
        start_pos,
    );

    if (entity_mgr.get(enemy_id)) |enemy| {
        enemy.behavior = .path_following;
        enemy.current_path = group.entry_path;
        enemy.path_t = 0;

        if (enemy_spawn.grid_pos) |grid_pos| {
            enemy.formation_pos = gridToWorldPosition(grid_pos);
        }
    }
}

fn spriteTypeToEntityType(sprite_type: z.assets.SpriteType) z.EntityType {
    return switch (sprite_type) {
        .player, .player_alt => .player,
        .boss, .boss_alt => .boss,
        .goei => .goei,
        .zako => .zako,
        else => .zako,
    };
}

fn gridToWorldPosition(grid_pos: level_def.GridPosition) engine.types.Vec2 {
    const GRID_COLUMNS: f32 = 10.0;
    const GRID_HORIZONTAL_MARGIN: f32 = 0.13;
    const GRID_TOP_OFFSET: f32 = 0.10;
    const BOSS_ROW_HEIGHT: f32 = 0.055;
    const ENEMY_ROW_HEIGHT: f32 = 0.040;

    const cell_width = (1.0 - GRID_HORIZONTAL_MARGIN * 2.0) / GRID_COLUMNS;

    const y_pos = if (grid_pos.row <= 1)
        GRID_TOP_OFFSET + @as(f32, @floatFromInt(grid_pos.row)) * BOSS_ROW_HEIGHT
    else
        GRID_TOP_OFFSET + (2.0 * BOSS_ROW_HEIGHT) + @as(f32, @floatFromInt(grid_pos.row - 2)) * ENEMY_ROW_HEIGHT;

    return engine.types.Vec2{
        .x = GRID_HORIZONTAL_MARGIN + (@as(f32, @floatFromInt(grid_pos.col)) - 0.5) * cell_width,
        .y = y_pos,
    };
}
