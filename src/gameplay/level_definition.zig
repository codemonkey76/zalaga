const SpriteType = @import("../assets/sprites.zig").SpriteType;
const arcade_lib = @import("arcade_lib");

pub const StageType = enum {
    standard,
    challenge,
};

pub const StageDefinition = struct {
    number: u8,
    type: StageType,
    waves: []Wave,
};

pub const Wave = struct {
    group1: EnemyGroup,
    group2: ?EnemyGroup = null,
};

pub const EnemyGroup = struct {
    enemies: []const EnemySpawn,
    pattern: arcade_lib.PathDefinition,
};

pub const EnemySpawn = struct {
    type: SpriteType,
};

pub const Position = struct {
    col: u8,
    row: u8,
};
