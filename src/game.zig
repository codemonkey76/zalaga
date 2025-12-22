const std = @import("std");
const engine = @import("engine");

const z = @import("mod.zig");
const GameState = z.GameState;

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
        try engine.run(
            z.assets.TextureAsset,
            z.assets.FontAsset,
            z.assets.PathAsset,
            z.assets.SoundAsset,
            self.allocator,
            self,
            z.GameVTable{
                .init = Self.onInit,
                .update = Self.onUpdate,
                .draw = Self.onDraw,
                .shutdown = Self.onShutdown,
            },
            .{
                .title = "Zalaga",
                .width = 1280,
                .height = 720,
                .virtual_width = 207,
                .virtual_height = 282,
                .ssaa_scale = 3,
                .target_fps = 155,
                .log_level = .warning,
                .asset_root = "assets",
            },
        );
    }

    fn onInit(ptr: *anyopaque, ctx: *z.Context) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.init(self.allocator, ctx);
    }

    fn onUpdate(ptr: *anyopaque, ctx: *z.Context, dt: f32) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.update(ctx, dt);
    }

    fn onDraw(ptr: *anyopaque, ctx: *z.Context) !void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        try self.state.draw(ctx);
    }

    fn onShutdown(ptr: *anyopaque, ctx: *z.Context) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        self.state.shutdown(ctx);
    }
};
