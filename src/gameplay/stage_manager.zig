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

pub const StageManager = struct {
    allocator: std.mem.Allocator,
    stage_def: *const StageDefinition,
    state: StageState,
    
    // Spawning state
    current_wave: usize,
    current_group: usize,
    current_enemy: usize,
    
    // Timers
    wave_timer: f32,
    group_timer: f32,
    enemy_timer: f32,
    ready_timer: f32,
    
    // Tracking
    enemies_spawned: u32,
    enemies_in_formation: u32,
    total_enemies: u32,
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator, stage_def: *const StageDefinition) Self {
        return .{
            .allocator = allocator,
            .stage_def = stage_def,
            .state = .forming,
            .current_wave = 0,
            .current_group = 0,
            .current_enemy = 0,
            .wave_timer = 0,
            .group_timer = 0,
            .enemy_timer = 0,
            .ready_timer = 0,
            .enemies_spawned = 0,
            .enemies_in_formation = 0,
            .total_enemies = countTotalEnemies(stage_def),
        };
    }
    
    pub fn update(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !void {
        switch (self.state) {
            .forming => try self.updateFormingState(ctx, entity_mgr, dt),
            .ready => self.updateReadyState(dt),
            .active => self.updateActiveState(dt),
        }
    }
    
    fn updateFormingState(self: *Self, ctx: *Context, entity_mgr: *EntityManager, dt: f32) !void {
        // Check if all waves complete
        if (self.current_wave >= self.stage_def.waves.len) {
            // All enemies spawned, wait for them to reach formation
            if (self.enemies_in_formation >= self.enemies_spawned) {
                self.state = .ready;
                self.ready_timer = 0;
            }
            return;
        }
        
        const wave = &self.stage_def.waves[self.current_wave];
        
        // Wait for wave delay
        self.wave_timer += dt;
        if (self.wave_timer < wave.wave_delay and self.current_wave > 0) {
            return;
        }
        
        // Check if all groups in wave complete
        if (self.current_group >= wave.groups.len) {
            // Move to next wave
            self.current_wave += 1;
            self.current_group = 0;
            self.current_enemy = 0;
            self.wave_timer = 0;
            return;
        }
        
        const group = &wave.groups[self.current_group];
        
        // Wait for group delay
        self.group_timer += dt;
        if (self.group_timer < group.group_delay and self.current_group > 0) {
            return;
        }
        
        // Check if all enemies in group spawned
        if (self.current_enemy >= group.enemies.len) {
            // Move to next group
            self.current_group += 1;
            self.current_enemy = 0;
            self.group_timer = 0;
            return;
        }
        
        const enemy_spawn = &group.enemies[self.current_enemy];
        
        // Wait for enemy spawn delay
        self.enemy_timer += dt;
        if (self.enemy_timer < enemy_spawn.spawn_delay) {
            return;
        }
        
        // Spawn the enemy!
        try self.spawnEnemy(ctx, entity_mgr, enemy_spawn, group);
        
        self.enemies_spawned += 1;
        self.current_enemy += 1;
        self.enemy_timer = 0;
    }
    
    fn updateReadyState(self: *Self, dt: f32) void {
        self.ready_timer += dt;
        if (self.ready_timer >= self.stage_def.attack_delay) {
            self.state = .active;
        }
    }
    
    fn updateActiveState(self: *Self, dt: f32) void {
        _ = self;
        _ = dt;
        // In active state, enemies can now attack
        // Attack logic will be handled elsewhere (enemy AI system)
    }
    
    fn spawnEnemy(
        _: *Self,
        ctx: *Context,
        entity_mgr: *EntityManager,
        enemy_spawn: *const EnemySpawn,
        group: *const SpawnGroup,
    ) !void {
        // Get the cached entry path (should already be loaded)
        const path = ctx.assets.getPath(group.entry_path) orelse {
            return error.PathNotLoaded;
        };
        
        // Manually build Vec2 array from anchors (workaround for type mismatch)
        var points = std.ArrayList(arcade_lib.Vec2){};
        defer points.deinit(ctx.allocator);
        
        for (path.anchors) |anchor| {
            try points.append(ctx.allocator, .{ .x = anchor.pos.x, .y = anchor.pos.y });
        }
        
        // Get start position from points
        const arcade_start = if (points.items.len > 0) points.items[0] else arcade_lib.Vec2{ .x = 0.5, .y = 0 };
        
        const start_pos = engine.types.Vec2{
            .x = arcade_start.x,
            .y = arcade_start.y,
        };
        
        // Convert enemy type to entity type
        const entity_type = spriteTypeToEntityType(enemy_spawn.enemy_type);
        
        const enemy_id = try entity_mgr.spawnEnemy(
            entity_type,
            enemy_spawn.enemy_type,
            start_pos,
        );
        
        std.debug.print("Spawned enemy {d}: type={s} at ({d:.2}, {d:.2})\n", .{
            enemy_id,
            @tagName(enemy_spawn.enemy_type),
            start_pos.x,
            start_pos.y,
        });
        
        // Configure enemy movement
        if (entity_mgr.get(enemy_id)) |enemy| {
            enemy.behavior = .path_following;
            enemy.current_path = group.entry_path;
            enemy.path_t = 0;
            
            // Store formation position if it has one
            if (enemy_spawn.grid_pos) |grid_pos| {
                enemy.formation_pos = gridToWorldPosition(grid_pos);
            }
        }
    }
    
    /// Notify that an enemy reached its formation position
    pub fn notifyEnemyInFormation(self: *Self) void {
        self.enemies_in_formation += 1;
    }
    
    /// Check if stage allows shooting during formation
    pub fn canShootDuringEntry(self: Self) bool {
        return self.stage_def.can_shoot_during_entry;
    }
    
    /// Check if enemies can attack (active state)
    pub fn canEnemiesAttack(self: Self) bool {
        return self.state == .active;
    }
    
    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

/// Count total enemies in a stage definition
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
        else => .zako, // Default fallback
    };
}

/// Convert grid position to world position (normalized 0-1)
fn gridToWorldPosition(grid_pos: GridPosition) engine.types.Vec2 {
    // Galaga formation grid is typically 8 columns wide
    const grid_width: f32 = 8.0;
    
    // Center the grid horizontally, offset from top
    const grid_left: f32 = 0.2;
    const grid_top: f32 = 0.15;
    const grid_cell_width: f32 = (1.0 - grid_left * 2.0) / grid_width;
    const grid_cell_height: f32 = 0.08;
    
    return engine.types.Vec2{
        .x = grid_left + (@as(f32, @floatFromInt(grid_pos.col)) + 0.5) * grid_cell_width,
        .y = grid_top + @as(f32, @floatFromInt(grid_pos.row)) * grid_cell_height,
    };
}
