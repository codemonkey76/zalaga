const std = @import("std");
const engine = @import("engine");
const SpriteLayoutBuilder = engine.graphics.SpriteLayoutBuilder;
const SpriteLayout = engine.graphics.SpriteLayout;
const RotationSet = engine.graphics.RotationSet;
const RotationFrame = engine.graphics.RotationFrame;
const Texture = engine.graphics.Texture;

pub const SpriteType = enum {
    player,
    player_alt,
    boss,
    boss_alt,
    goei,
    zako,
    scorpion,
    midori,
    galaxian,
    tombow,
    momji,
    enterprise,
};

pub const SpriteId = enum {
    rotation_180,
    rotation_165,
    rotation_150,
    rotation_135,
    rotation_120,
    rotation_105,
    rotation_90,
    idle_1,
    idle_2,
};

pub const Sprites = struct {
    allocator: std.mem.Allocator,

    layouts: std.AutoHashMap(SpriteType, SpriteLayout(SpriteId)),
    rotations: std.AutoHashMap(SpriteType, RotationSet(SpriteId)),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        const sprite_sheet = try ctx.assets.loadTexture("textures/spritesheet.png");
        var layouts = std.AutoHashMap(SpriteType, SpriteLayout(SpriteId)).init(allocator);
        var rotations = std.AutoHashMap(SpriteType, RotationSet(SpriteId)).init(allocator);

        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .player, 0);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .player_alt, 1);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .boss, 2);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .boss_alt, 3);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .goei, 4);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .zako, 5);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .scorpion, 6);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .midori, 7);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .galaxian, 8);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .tombow, 9);
        // try initSprite(allocator, sprite_sheet, &layouts, &rotations, .momji, 10);
        try initSprite(allocator, sprite_sheet, &layouts, &rotations, .enterprise, 11);

        return .{
            .allocator = allocator,
            .layouts = layouts,
            .rotations = rotations,
        };
    }

    pub fn initSprite(
        allocator: std.mem.Allocator,
        texture: Texture,
        layouts: *std.AutoHashMap(SpriteType, SpriteLayout(SpriteId)),
        rotations: *std.AutoHashMap(SpriteType, RotationSet(SpriteId)),
        sprite_type: SpriteType,
        row: f32,
    ) !void {
        var builder = SpriteLayoutBuilder(SpriteId).init(allocator, texture);

        try builder.addSprite(.rotation_180, 1 + (0 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_165, 1 + (1 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_150, 1 + (2 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_135, 1 + (3 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_120, 1 + (4 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_105, 1 + (5 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_90, 1 + (6 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);

        try builder.addSprite(.idle_1, 1 + (6 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        if (sprite_type == .boss or sprite_type == .boss_alt or sprite_type == .goei or sprite_type == .zako) try builder.addSprite(.idle_2, 1 + (7 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);

        const layout = builder.build();

        const rot_frames = try allocator.alloc(RotationFrame(SpriteId), 7);
        rot_frames[0] = .{ .id = .rotation_180, .angle = 180.0 };
        rot_frames[1] = .{ .id = .rotation_165, .angle = 165.0 };
        rot_frames[2] = .{ .id = .rotation_150, .angle = 150.0 };
        rot_frames[3] = .{ .id = .rotation_135, .angle = 135.0 };
        rot_frames[4] = .{ .id = .rotation_120, .angle = 120.0 };
        rot_frames[5] = .{ .id = .rotation_105, .angle = 105.0 };
        rot_frames[6] = .{ .id = .rotation_90, .angle = 90.0 };

        try layouts.put(sprite_type, layout);
        try rotations.put(sprite_type, RotationSet(SpriteId){
            .layout = layout,
            .frames = rot_frames,
            .allow_horizontal_flip = true,
            .allow_vertical_flip = true,
        });
    }

    pub fn deinit(self: *Self) void {
        var rot_iter = self.rotations.valueIterator();
        while (rot_iter.next()) |rotation_set| {
            self.allocator.free(rotation_set.frames);
        }
        self.rotations.deinit();
        self.layouts.deinit();
    }

    /// Get a sprite by type and ID
    pub fn getSprite(self: *Self, sprite_type: SpriteType, sprite_id: SpriteId) ?engine.graphics.Sprite {
        const layout = self.layouts.get(sprite_type) orelse return null;
        return layout.getSprite(sprite_id);
    }

    /// Get layout for a sprite type
    pub fn getLayout(self: *Self, sprite_type: SpriteType) ?SpriteLayout(SpriteId) {
        return self.layouts.get(sprite_type);
    }

    /// Get rotation set for a sprite type
    pub fn getRotationSet(self: *Self, sprite_type: SpriteType) ?RotationSet(SpriteId) {
        return self.rotations.get(sprite_type);
    }
};
