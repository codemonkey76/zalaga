const std = @import("std");
const engine = @import("engine");

const Starfield = @import("graphics/starfield.zig").Starfield;
const Assets = @import("assets/assets.zig").Assets;
const Sprites = @import("assets/sprites.zig").Sprites;

pub const GameState = struct {
    starfield: Starfield,
    assets: Assets,
    sprites: Sprites,
    test_angle: f32 = 0.0,
    rotation_timer: f32 = 0.0,

    const Self = @This();

    pub fn init(self: *Self, allocator: std.mem.Allocator, ctx: *engine.Context) !void {
        self.assets = try Assets.init(allocator, ctx);
        self.sprites = try Sprites.init(allocator, ctx);
        self.starfield = try Starfield.init(allocator, ctx, .{});
    }
    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !void {
        self.starfield.update(dt, ctx);

        self.rotation_timer += dt;
        if (self.rotation_timer > 0.01) {
            self.rotation_timer = 0;
            self.test_angle += 1;
            std.debug.print("Testing angle: {}\n", .{self.test_angle});
            if (self.test_angle >= 359.0) self.test_angle = 0.0;
        }
    }
    pub fn draw(self: *Self, ctx: *engine.Context) !void {
        self.starfield.draw(ctx);

        if (self.sprites.player_rotations.getSpriteForAngle(self.test_angle)) |flipped| {
            const pos = engine.types.Vec2{ .x = 0.5, .y = 0.5 };

            ctx.renderer.drawFlippedSprite(flipped, pos);

            const sprite_width = ctx.renderer.flippedSpriteWidth(flipped);
            const gap = 1.0 / @as(f32, @floatFromInt(ctx.viewport.virtual_width));

            for (0..3) |i| {
                const x = (sprite_width + gap) * @as(f32, @floatFromInt(i));
                ctx.renderer.drawFlippedSpriteAnchored(flipped, .{ .x = x, .y = 1 }, .bottom_left);
            }
        }
    }
    pub fn shutdown(self: *Self, ctx: *engine.Context) void {
        self.sprites.deinit();
        self.starfield.deinit();
        self.assets.deinit(ctx);
    }
};
