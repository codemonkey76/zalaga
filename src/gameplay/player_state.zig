const std = @import("std");
const StageState = @import("../mod.zig").StageState;
const StageDefinition = @import("../mod.zig").StageDefinition;
const c = @import("../constants.zig");
const LevelMarkers = @import("../gameplay/level_markers.zig").LevelMarkers;
const level_def = @import("../gameplay/level_definition.zig");

pub const PlayerState = struct {
    allocator: std.mem.Allocator,
    entity_id: ?u32 = null,
    score: u32 = 0,
    lives: u8 = c.player.START_LIVES,
    is_active: bool = false,
    double: bool = false,
    level_markers: LevelMarkers,

    stage: level_def.StageDefinition = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .level_markers = LevelMarkers.init(allocator),
            .stage = level_def.stage_1,
        };
    }
};
