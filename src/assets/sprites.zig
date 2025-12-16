const std = @import("std");
const engine = @import("engine");

/// Define sprite IDs for each sprite sheet
pub const PlayerSpriteId = enum {
    rotation_270,
    rotation_285,
    rotation_300,
    rotation_315,
    rotation_330,
    rotation_345,
    rotation_0,
};

pub const Sprites = struct {
    allocator: std.mem.Allocator,

    player_layout: engine.graphics.SpriteLayout(PlayerSpriteId),
    player_rotations: engine.graphics.RotationSet(PlayerSpriteId),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        const sprite_sheet = try ctx.assets.loadTexture("textures/spritesheet.png");

        // === PLAYER SETUP ===
        var player_builder = engine.graphics.SpriteLayoutBuilder(PlayerSpriteId).init(allocator, sprite_sheet);

        try player_builder.addSprite(.rotation_180, 1 + (0 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_165, 1 + (1 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_150, 1 + (2 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_135, 1 + (3 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_120, 1 + (4 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_105, 1 + (5 * (16 + 2)), 1, 16, 16);
        try player_builder.addSprite(.rotation_90, 1 + (6 * (16 + 2)), 1, 16, 16);

        const player_layout = player_builder.build();

        const player_rot_frames = try allocator.alloc(engine.graphics.RotationFrame(PlayerSpriteId), 7);
        player_rot_frames[0] = .{ .id = .rotation_180, .angle = 180.0 };
        player_rot_frames[1] = .{ .id = .rotation_165, .angle = 165.0 };
        player_rot_frames[2] = .{ .id = .rotation_150, .angle = 150.0 };
        player_rot_frames[3] = .{ .id = .rotation_135, .angle = 135.0 };
        player_rot_frames[4] = .{ .id = .rotation_120, .angle = 120.0 };
        player_rot_frames[5] = .{ .id = .rotation_105, .angle = 105.0 };
        player_rot_frames[6] = .{ .id = .rotation_90, .angle = 90.0 };

        const player_rotations = engine.graphics.RotationSet(PlayerSpriteId){
            .layout = player_layout,
            .frames = player_rot_frames,
            .allow_horizontal_flip = true,
            .allow_vertical_flip = true,
        };

        return .{
            .allocator = allocator,
            .player_layout = player_layout,
            .player_rotations = player_rotations,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.player_rotations.frames);
    }
};
