const PathAsset = @import("../mod.zig").assets.PathAsset;
const SpriteType = @import("../mod.zig").assets.SpriteType;

pub const StageType = enum {
    normal,
    challenge,
};

pub const StageState = enum {
    forming,
    ready,
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
    groups: []SpawnGroup,
    wave_delay: f32,
};

pub const StageDefinition = struct {
    stage_number: u8,
    stage_type: StageType,
    waves: []Wave,

    // Modifiers,
    can_shoot_during_entry: bool,
    speed_multiplier: f32,
};
