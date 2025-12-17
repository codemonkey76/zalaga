const std = @import("std");
const StageState = @import("stage_state.zig").StageState;

pub const PlayerState = struct {
    score: u32 = 0,
    lives: u8 = 3,
    is_active: bool = false,
    double: bool = false,

    stage: StageState = undefined,

    const Self = @This();
};
