const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../game_mode.zig").GameMode;
const GameState = @import("../game_state.zig").GameState;
const SpriteId = @import("../assets/sprites.zig").SpriteId;

pub const Attract = struct {
    submode: SubMode,
    timer: f32,
    wing_timer: f32 = 0.0,
    sprite_id: SpriteId = .idle_1,

    const Self = @This();

    const SubMode = enum {
        high_score_table,
        game_info,
        demo_gameplay,
    };

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !?GameMode {
        self.timer += dt;
        self.wing_timer += dt;

        // Potentially time out to a new mode
        if (self.timer < 5.0) {
            self.timer = 0;
            self.submode = switch (self.submode) {
                .high_score_table => .game_info,
                .game_info => .demo_gameplay,
                .demo_gameplay => .high_score_table,
            };
        }

        if (self.wing_timer > 0.5) {
            if (self.sprite_id == .idle_1) {
                self.sprite_id = .idle_2;
            } else {
                self.sprite_id = .idle_1;
            }
            self.wing_timer = 0;
        }

        // Update current submode
        switch (self.submode) {
            .high_score_table => try self.updateHighScores(ctx, dt),
            .game_info => try self.updateInfo(ctx, dt),
            .demo_gameplay => try self.updateDemo(ctx, dt),
        }

        if (ctx.input.isKeyPressed(.five)) {
            return .start_screen;
        }

        return null;
    }

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        _ = allocator;
        _ = ctx;

        return .{
            .submode = .game_info,
            .timer = 0.0,
        };
    }

    pub fn updateHighScores(self: *Self, ctx: *engine.Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }
    pub fn updateInfo(self: *Self, ctx: *engine.Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }
    pub fn updateDemo(self: *Self, ctx: *engine.Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }

    pub fn draw(self: *Self, ctx: *engine.Context, state: *GameState) !void {
        ctx.renderer.drawTextGridCentered("GALAGA", 4, engine.types.Color.sky_blue);
        ctx.renderer.drawTextGridCentered("--- SCORE ---", 6, engine.types.Color.sky_blue);

        ctx.renderer.drawText("50      100", .{ .x = 0.45, .y = 0.3 }, engine.types.Color.sky_blue);
        ctx.renderer.drawText("80      160", .{ .x = 0.45, .y = 0.36 }, engine.types.Color.sky_blue);

        if (state.sprites.layouts.get(.goei)) |goei_layout| {
            if (goei_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.317 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.65, .y = 0.677 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.73, .y = 0.677 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.85, .y = 0.677 });
            }
        }
        if (state.sprites.layouts.get(.zako)) |zako_layout| {
            if (zako_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.377 });
            }
        }

        if (state.sprites.layouts.get(.boss)) |boss_layout| {
            if (boss_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.497 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.2, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.4, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.6, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.8, .y = 0.617 });
            }
        }
        if (state.sprites.layouts.get(.player)) |player_layout| {
            if (player_layout.getSprite(.idle_1)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.91 });
                // ctx.renderer.drawSpriteAnchored(sprite, .{ .x = 0.0, .y = 1.0 }, .bottom_left);
            }
        }
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = self;
        _ = ctx;
    }
};
