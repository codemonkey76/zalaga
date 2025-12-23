const std = @import("std");
const engine = @import("engine");

const Context = @import("../mod.zig").Context;
const g = engine.graphics;

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
    rotation_270,
    rotation_285,
    rotation_300,
    rotation_315,
    rotation_330,
    rotation_345,
    rotation_0,
    idle_1,
    idle_2,
};

pub const BulletSpriteId = enum {
    player_bullet,
    enemy_bullet,
};

pub const ExplosionSpriteId = enum {
    player_frame_1,
    player_frame_2,
    player_frame_3,
    player_frame_4,
    enemy_frame_1,
    enemy_frame_2,
    enemy_frame_3,
    enemy_frame_4,
    enemy_frame_5,
};

pub const Sprites = struct {
    allocator: std.mem.Allocator,

    layouts: std.AutoHashMap(SpriteType, g.SpriteLayout(SpriteId)),
    rotations: std.AutoHashMap(SpriteType, g.RotationSet(SpriteId)),
    bullet_layout: g.SpriteLayout(BulletSpriteId),
    explosion_layout: g.SpriteLayout(ExplosionSpriteId),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *Context) !Self {
        const sprite_sheet = try ctx.assets.loadTexture(.sprite_sheet);
        var layouts = std.AutoHashMap(SpriteType, g.SpriteLayout(SpriteId)).init(allocator);
        var rotations = std.AutoHashMap(SpriteType, g.RotationSet(SpriteId)).init(allocator);

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

        const bullet_layout = try initBullets(allocator, sprite_sheet);
        const explosion_layout = try initExplosions(allocator, sprite_sheet);

        return .{
            .allocator = allocator,
            .layouts = layouts,
            .rotations = rotations,
            .bullet_layout = bullet_layout,
            .explosion_layout = explosion_layout,
        };
    }

    pub fn initSprite(
        allocator: std.mem.Allocator,
        texture: g.Texture,
        layouts: *std.AutoHashMap(SpriteType, g.SpriteLayout(SpriteId)),
        rotations: *std.AutoHashMap(SpriteType, g.RotationSet(SpriteId)),
        sprite_type: SpriteType,
        row: f32,
    ) !void {
        var builder = g.SpriteLayoutBuilder(SpriteId).init(allocator, texture);

        try builder.addSprite(.rotation_270, 1 + (0 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_285, 1 + (1 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_300, 1 + (2 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_315, 1 + (3 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_330, 1 + (4 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_345, 1 + (5 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        try builder.addSprite(.rotation_0, 1 + (6 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);

        try builder.addSprite(.idle_1, 1 + (6 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);
        if (sprite_type == .boss or sprite_type == .boss_alt or sprite_type == .goei or sprite_type == .zako) try builder.addSprite(.idle_2, 1 + (7 * (16 + 2)), 1 + (row * (16 + 2)), 16, 16);

        const layout = builder.build();

        const rot_frames = try allocator.alloc(g.RotationFrame(SpriteId), 7);
        rot_frames[0] = .{ .id = .rotation_270, .angle = 270.0 };
        rot_frames[1] = .{ .id = .rotation_285, .angle = 285.0 };
        rot_frames[2] = .{ .id = .rotation_300, .angle = 300.0 };
        rot_frames[3] = .{ .id = .rotation_315, .angle = 315.0 };
        rot_frames[4] = .{ .id = .rotation_330, .angle = 330.0 };
        rot_frames[5] = .{ .id = .rotation_345, .angle = 345.0 };
        rot_frames[6] = .{ .id = .rotation_0, .angle = 0.0 };

        try layouts.put(sprite_type, layout);
        try rotations.put(sprite_type, g.RotationSet(SpriteId){
            .layout = layout,
            .frames = rot_frames,
            .allow_horizontal_flip = true,
            .allow_vertical_flip = true,
        });
    }

    fn initBullets(allocator: std.mem.Allocator, texture: g.Texture) !g.SpriteLayout(BulletSpriteId) {
        var builder = g.SpriteLayoutBuilder(BulletSpriteId).init(allocator, texture);

        // Bullet at x=307, y=118
        try builder.addSprite(.player_bullet, 307, 118, 16, 16);
        try builder.addSprite(.enemy_bullet, 307, 136, 16, 16);

        return builder.build();
    }

    fn initExplosions(allocator: std.mem.Allocator, texture: g.Texture) !g.SpriteLayout(ExplosionSpriteId) {
        var builder = g.SpriteLayoutBuilder(ExplosionSpriteId).init(allocator, texture);

        // Player explosion: 4 frames, 32x32, starting at x=145, y=1
        try builder.addSprite(.player_frame_1, 145, 1, 32, 32);
        try builder.addSprite(.player_frame_2, 145 + 34, 1, 32, 32); // 32 + 2 spacing
        try builder.addSprite(.player_frame_3, 145 + 68, 1, 32, 32);
        try builder.addSprite(.player_frame_4, 145 + 102, 1, 32, 32);

        // Enemy explosion: 5 frames, 32x32, starting at x=289, y=1
        try builder.addSprite(.enemy_frame_1, 289, 1, 32, 32);
        try builder.addSprite(.enemy_frame_2, 289 + 34, 1, 32, 32);
        try builder.addSprite(.enemy_frame_3, 289 + 68, 1, 32, 32);
        try builder.addSprite(.enemy_frame_4, 289 + 102, 1, 32, 32);
        try builder.addSprite(.enemy_frame_5, 289 + 136, 1, 32, 32);

        return builder.build();
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
    pub fn getLayout(self: *Self, sprite_type: SpriteType) ?g.SpriteLayout(SpriteId) {
        return self.layouts.get(sprite_type);
    }

    /// Get rotation set for a sprite type
    pub fn getRotationSet(self: *Self, sprite_type: SpriteType) ?g.RotationSet(SpriteId) {
        return self.rotations.get(sprite_type);
    }

    /// Get a bullet sprite by ID
    pub fn getBulletSprite(self: *Self, bullet_id: BulletSpriteId) ?g.Sprite {
        return self.bullet_layout.getSprite(bullet_id);
    }

    /// Get an explosion sprite by ID
    pub fn getExplosionSprite(self: *Self, explosion_id: ExplosionSpriteId) ?g.Sprite {
        return self.explosion_layout.getSprite(explosion_id);
    }
};
