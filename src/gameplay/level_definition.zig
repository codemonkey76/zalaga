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
        // Wave 1: First wave 4 x Goei and 4 x zako enter from left and right
        .{
            .groups = &.{
                // Left side - 4 zako
                .{
                    .enemies = &.{
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 5 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 6 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 5 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 6 }, .spawn_delay = 0.6 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
                // Right side - 4 goei
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 5 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 6 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 5 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 6 }, .spawn_delay = 0.6 },
                    },
                    .entry_path = .level_1_1_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 2: 4 x boss + 4 x Goei
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 1, .col = 5 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 4 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 1, .col = 6 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 7 }, .spawn_delay = 0.6 },
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 1, .col = 4 }, .spawn_delay = 0.8 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 4 }, .spawn_delay = 1.0 },
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 1, .col = 7 }, .spawn_delay = 1.2 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 7 }, .spawn_delay = 1.4 },
                    },
                    .entry_path = .level_1_2_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 3: 8 x Goei
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 3 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 8 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 3 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 8 }, .spawn_delay = 0.6 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 2 }, .spawn_delay = 0.8 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 2, .col = 9 }, .spawn_delay = 1.0 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 2 }, .spawn_delay = 1.2 },
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 3, .col = 9 }, .spawn_delay = 1.4 },
                    },
                    .entry_path = .level_1_2_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 4: 8 x zako
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 4 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 7 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 4 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 7 }, .spawn_delay = 0.6 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 3 }, .spawn_delay = 0.8 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 8 }, .spawn_delay = 1.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 3 }, .spawn_delay = 1.2 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 8 }, .spawn_delay = 1.4 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
        // Wave 4: 8 x zako
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 2 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 9 }, .spawn_delay = 0.2 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 2 }, .spawn_delay = 0.4 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 9 }, .spawn_delay = 0.6 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 1 }, .spawn_delay = 0.8 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 4, .col = 10 }, .spawn_delay = 1.0 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 1 }, .spawn_delay = 1.2 },
                        .{ .enemy_type = .zako, .grid_pos = .{ .row = 5, .col = 10 }, .spawn_delay = 1.4 },
                    },
                    .entry_path = .level_1_1_right,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
    },
    .can_shoot_during_entry = true,
    .attack_delay = 2.0,
    .attack_frequency = 0.8,
    .speed_multiplier = 1.0,
};

// Debug stage - Single enemy for testing rotation
pub const stage_debug = StageDefinition{
    .stage_number = 0,
    .stage_type = .normal,
    .waves = &.{
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .goei, .grid_pos = .{ .row = 1, .col = 3 }, .spawn_delay = 0.0 },
                    },
                    .entry_path = .level_1_1_left,
                    .exit_path = null,
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 0.0,
        },
    },
    .can_shoot_during_entry = false,
    .attack_delay = 99999.0,
    .attack_frequency = 0.0,
    .speed_multiplier = 1.0,
};
