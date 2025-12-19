const std = @import("std");
const engine = @import("engine");

const SpriteId = enum {
    player_idle,
};

pub const Assets = struct {
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Assets {
        const texture = try ctx.assets.loadTexture("textures/spritesheet.png", engine.types.Color.black);

        var builder = engine.graphics.SpriteLayoutBuilder(SpriteId).init(allocator, texture);
        try builder.addSprite(.player_idle, 0, 0, 16, 16);
        const layout = builder.build();
        _ = layout;

        return .{};
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = self;
        _ = ctx;
    }

    fn loadSprites(self: *const Self) void {
        _ = self;
        // self.assets.loadSprite();
    }
};
