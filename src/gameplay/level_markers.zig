const std = @import("std");
const LevelSpriteId = @import("../assets/sprites.zig").LevelSpriteId;

pub const LevelMarkers = struct {
    allocator: std.mem.Allocator,
    markers: std.ArrayList(LevelSpriteId),
    display_index: u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .markers = std.ArrayList(LevelSpriteId).empty,
            .display_index = 0,
        };
    }
};
