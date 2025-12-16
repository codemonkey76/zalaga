const std = @import("std");
const GameState = @import("game_state.zig").GameState;
const engine = @import("engine");

pub const Game = struct {
    allocator: std.mem.Allocator,
    state: GameState,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .state = undefined,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn run(self: *Self) !void {
        try engine.run(self.allocator, self, .{
            .init = Self.onInit,
            .update = Self.onUpdate,
            .draw = Self.onDraw,
            .shutdown = Self.onShutdown,
        }, .{
            .title = "Zalaga",
            .width = 1280,
            .height = 720,
            .target_fps = 60,
        });
    }

    fn onInit(ptr: *anyopaque, ctx: *engine.Context) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.init(self.allocator, ctx);
    }

    fn onUpdate(ptr: *anyopaque, ctx: *engine.Context, dt: f32) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.update(ctx, dt);
    }

    fn onDraw(ptr: *anyopaque, ctx: *engine.Context) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.draw(ctx);
    }

    fn onShutdown(ptr: *anyopaque, ctx: *engine.Context) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        self.state.shutdown(ctx);
    }
};
