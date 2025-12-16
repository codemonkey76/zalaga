const std = @import("std");
const engine = @import("engine");

/// Define sprite IDs for each sprite sheet
pub const PlayerSpriteId = enum {
    rotation_0,
    rotation_270,
    rotation_285,
    rotation_300,
    rotation_315,
    rotation_330,
    rotation_345,
};

pub const Sprites = struct {
    allocator: std.mem.Allocator,

    player_layout: engine.SpriteLayout(PlayerSpriteId),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        const sprite_sheet = try ctx.assets.loadTexture("assets/textures/spritesheet.png");

        var player_builder = engine.SpriteLayoutBuilder(PlayerSpriteId).init(allocator, sprite_sheet);

        try player_builder.addSprite(.rotation_0, 0, 0, 16, 16);
        const player_layout = player_builder.build();
    }
};
