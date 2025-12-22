const PathAsset = @import("../assets/path_asset.zig").PathAsset;
const SpriteType = @import("../assets/sprites.zig").SpriteType;

pub const StageType = enum {
    normal,
    challenge,
};

pub const StageState = enum {
    forming,
    ready,
    active,
};

pub const GridPosition = struct { row: u8, col: u8 };

pub const EnemySpawn = struct {
    enemy_type: SpriteType,
    grid_pos: ?GridPosition,
    spawn_delay: f32,
};

pub const SpawnGroup = struct {
    enemies: []const EnemySpawn,
    entry_path: PathAsset,
    exit_path: ?PathAsset,
    group_delay: f32,
};

pub const Wave = struct {
    groups: []const SpawnGroup,
    wave_delay: f32,
};

pub const StageDefinition = struct {
    stage_number: u8,
    stage_type: StageType,
    waves: []const Wave,

    // Behavior modifiers
    can_shoot_during_entry: bool,
    attack_delay: f32,
    attack_frequency: f32,
    speed_multiplier: f32,
};

// Stage 1 - Classic Galaga opening formation
pub const stage_1 = StageDefinition{
    .stage_number = 1,
    .stage_type = .normal,
    .waves = &.{
        // Wave 1: First 4 Goei (butterflies) enter from left and right
        .{
            .groups = &.{
                // Left side - 2 butterflies
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 1, .col = 2 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 1, .col = 3 }, .spawn_delay = 0.4 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
                // Right side - 2 butterflies (simultaneous)
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 1, .col = 4 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 1, .col = 5 }, .spawn_delay = 0.4 },
                    },
                    .entry_path = .level_1_1_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 2: Next 4 Goei
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 1 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 2 }, .spawn_delay = 0.4 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 5 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 6 }, .spawn_delay = 0.4 },
                    },
                    .entry_path = .level_1_1_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 3: Zako (bees) formation
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 0 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 1 }, .spawn_delay = 0.3 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 2 }, .spawn_delay = 0.3 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 3 }, .spawn_delay = 0.3 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
                .{
                    .enemies = &.{
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 4 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 5 }, .spawn_delay = 0.3 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 6 }, .spawn_delay = 0.3 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 3, .col = 7 }, .spawn_delay = 0.3 },
                    },
                    .entry_path = .level_1_1_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 4: Boss Galaga (top row)
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 0, .col = 3 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 0, .col = 4 }, .spawn_delay = 0.5 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 0.0, // Last wave, no delay after
        },
    },
    .can_shoot_during_entry = true,
    .attack_delay = 2.0,
    .attack_frequency = 0.8,
    .speed_multiplier = 1.0,
};
