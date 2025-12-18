const std = @import("std");

pub const HighScoreEntry = struct {
    score: u32,
    initials: [3]u8,
    stage: u32,
};

pub const HighScoreTable = struct {
    entries: [10]HighScoreEntry,

    const Self = @This();

    pub fn load(allocator: std.mem.Allocator) !Self {
        _ = allocator;
        return .{};
    }

    pub fn save(self: *const HighScoreTable) !void {
        _ = self;
    }

    pub fn tryInsert(self: *HighScoreTable, entry: HighScoreEntry) ?usize {
        _ = self;
        _ = entry;

        return null;
    }
};
