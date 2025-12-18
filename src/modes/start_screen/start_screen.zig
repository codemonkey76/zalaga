const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;

pub const StartScreen = struct {
    const Self = @This();

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !?GameMode {
        _ = self;
        _ = ctx;
        _ = dt;
        return null;
    }

    pub fn draw(self: *Self, ctx: *engine.Context, state: *GameState) !void {
        _ = self;
        _ = ctx;
        _ = state;
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = self;
        _ = ctx;
    }

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        _ = allocator;
        _ = ctx;
        return .{};
    }
};
