const std = @import("std");
const engine = @import("engine");
const z = @import("../../mod.zig");
const level_def = @import("../level_definition.zig");

const Context = z.Context;
const EntityManager = z.EntityManager;
const StageDefinition = level_def.StageDefinition;

const IntroSequence = @import("intro_sequence.zig").IntroSequence;
const WaveSpawner = @import("wave_spawner.zig").WaveSpawner;
const FormationTracker = @import("formation_tracker.zig").FormationTracker;

pub const EntityId = @import("../../entities/entity.zig").EntityId;
const LevelSpriteId = @import("../../assets/sprites.zig").LevelSpriteId;

/// Main stage state
pub const StageState = enum {
    intro,
    gameplay,
    complete,
};

/// Main stage manager - coordinates sub-components
pub const StageManager = struct {
    allocator: std.mem.Allocator,
    stage_def: *const StageDefinition,
    state: StageState = .intro,

    // Sub-components
    intro: IntroSequence,
    spawner: WaveSpawner,
    formation: FormationTracker,

    // Gameplay state
    ready_timer: f32 = 0,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, stage_def: *const StageDefinition) Self {
        return .{
            .allocator = allocator,
            .stage_def = stage_def,
            .intro = IntroSequence.init(allocator),
            .spawner = WaveSpawner.init(allocator, stage_def),
            .formation = FormationTracker{},
        };
    }

    pub fn update(self: *Self, ctx: *Context, state: *z.GameState, dt: f32) !void {
        switch (self.state) {
            .intro => {
                const intro_complete = try self.intro.update(ctx, state, dt);
                if (intro_complete) {
                    self.state = .gameplay;
                }
            },
            .gameplay => try self.updateGameplay(ctx, state, dt),
            .complete => {},
        }
    }

    fn updateGameplay(self: *Self, ctx: *Context, state: *z.GameState, dt: f32) !void {
        // Spawn waves
        const waves_complete = try self.spawner.update(ctx, &state.entity_manager, dt);

        // Check formation
        if (waves_complete and self.formation.isFormationComplete(&state.entity_manager)) {
            // All enemies in formation - wait for attack delay
            self.ready_timer += dt;
        }

        // Check if all enemies dead - restart
        if (self.formation.areAllEnemiesDead(&state.entity_manager)) {
            self.resetWaves();
        }
    }

    fn resetWaves(self: *Self) void {
        self.spawner.reset();
        self.formation.reset();
        self.ready_timer = 0;
    }

    pub fn draw(self: *const Self, ctx: *Context, state: *z.GameState) void {
        switch (self.state) {
            .intro => self.intro.draw(ctx, state),
            .gameplay => {
                // Draw gameplay HUD/indicators
            },
            .complete => {
                // Draw "STAGE COMPLETE" or similar
            },
        }
    }

    pub fn getLevelMarkers(allocator: std.mem.Allocator, stage_number: u8) ![]const LevelSpriteId {
        if (stage_number == 0) {
            return &[_]LevelSpriteId{};
        }

        var markers = std.ArrayList(LevelSpriteId).empty;
        errdefer {
            markers.deinit(allocator);
        }

        var remaining = stage_number;

        // Add 50-Markers
        while (remaining >= 50) : (remaining -= 50) {
            try markers.append(allocator, .level_50);
        }

        // Add 30-Markers
        while (remaining >= 30) : (remaining -= 30) {
            try markers.append(allocator, .level_30);
        }

        // Add 20-Markers
        while (remaining >= 20) : (remaining -= 20) {
            try markers.append(allocator, .level_20);
        }

        // Add 10-Markers
        while (remaining >= 10) : (remaining -= 10) {}

        // Add 5-Markers
        while (remaining >= 5) : (remaining -= 5) {
            try markers.append(allocator, .level_5);
        }

        // Add 1-Markers
        while (remaining > 0) : (remaining -= 1) {
            try markers.append(allocator, .level_1);
        }

        return markers.toOwnedSlice(allocator);
    }

    // Public API
    pub fn getState(self: Self) StageState {
        return self.state;
    }

    pub fn canEnemiesAttack(self: Self) bool {
        return self.state == .gameplay and
            self.ready_timer >= self.stage_def.attack_delay;
    }

    pub fn canShootDuringEntry(self: Self) bool {
        return self.stage_def.can_shoot_during_entry;
    }

    pub fn notifyEnemyInFormation(self: *Self) void {
        self.formation.notifyEnemyInFormation();
    }

    pub fn notifyEnemyDied(self: *Self, was_in_formation: bool) void {
        self.formation.notifyEnemyDied(was_in_formation);
    }

    pub fn getPlayerId(self: Self) ?EntityId {
        return self.intro.getPlayerId();
    }

    pub fn deinit(self: *Self) void {
        self.intro.deinit();
        self.spawner.deinit();
    }
};

test "getLevelMarkers stage 0" {
    const allocator = std.testing.allocator;
    const markers = try StageManager.getLevelMarkers(allocator, 0);
    defer allocator.free(markers);

    try std.testing.expectEqual(@as(usize, 0), markers.len);
}

test "getLevelMarkers stage 1" {
    const allocator = std.testing.allocator;
    const markers = try StageManager.getLevelMarkers(allocator, 1);
    defer allocator.free(markers);

    try std.testing.expectEqual(@as(usize, 1), markers.len);
    try std.testing.expectEqual(LevelSpriteId.level_1, markers[0]);
}

test "getLevelMarkers stage 5" {
    const allocator = std.testing.allocator;
    const markers = try StageManager.getLevelMarkers(allocator, 5);
    defer allocator.free(markers);

    try std.testing.expectEqual(@as(usize, 1), markers.len);
    try std.testing.expectEqual(LevelSpriteId.level_5, markers[0]);
}

test "getLevelMarkers stage 255" {
    const allocator = std.testing.allocator;
    const markers = try StageManager.getLevelMarkers(allocator, 255);
    defer allocator.free(markers);

    // 255 = 50*5 + 5 = 250 + 5
    try std.testing.expectEqual(@as(usize, 6), markers.len);
    try std.testing.expectEqual(LevelSpriteId.level_50, markers[0]);
    try std.testing.expectEqual(LevelSpriteId.level_50, markers[1]);
    try std.testing.expectEqual(LevelSpriteId.level_50, markers[2]);
    try std.testing.expectEqual(LevelSpriteId.level_50, markers[3]);
    try std.testing.expectEqual(LevelSpriteId.level_50, markers[4]);
    try std.testing.expectEqual(LevelSpriteId.level_5, markers[5]);
}

test "getLevelMarkers wrapping behavior" {
    const allocator = std.testing.allocator;

    // Test wrapping: stage wraps at u8 boundary
    var stage: u8 = 255;
    const markers_255 = try StageManager.getLevelMarkers(allocator, stage);
    defer allocator.free(markers_255);

    stage +%= 1; // Wrapping add, results in 0
    const markers_0 = try StageManager.getLevelMarkers(allocator, stage);
    defer allocator.free(markers_0);

    stage +%= 1; // Results in 1
    const markers_1 = try StageManager.getLevelMarkers(allocator, stage);
    defer allocator.free(markers_1);

    try std.testing.expectEqual(@as(usize, 0), markers_0.len);
    try std.testing.expectEqual(@as(usize, 1), markers_1.len);
}
