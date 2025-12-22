const std = @import("std");
const StageState = @import("../mod.zig").StageState;
const StageDefinition = @import("../mod.zig").StageDefinition;

pub const PlayerState = struct {
    score: u32 = 0,
    lives: u8 = 3,
    is_active: bool = false,
    double: bool = false,

    stage: StageState = undefined,
    definition: StageDefinition = undefined,

    const Self = @This();
};
