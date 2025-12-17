const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../game_mode.zig").GameMode;
const GameState = @import("../game_state.zig").GameState;

pub const Attract = struct {
    submode: SubMode,
    timer: f32,

    const Self = @This();

    const SubMode = enum {
        high_score_table,
        game_info,
        demo_gameplay,
    };

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !?GameMode {
        self.timer += dt;

        // Potentially time out to a new mode
        if (self.timer < 5.0) {
            self.timer = 0;
            self.submode = switch (self.submode) {
                .high_score_table => .game_info,
                .game_info => .demo_gameplay,
                .demo_gameplay => .high_score_table,
            };
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
        _ = self;
        ctx.renderer.drawTextGridCentered("GALAGA", 4, engine.types.Color.sky_blue);
        ctx.renderer.drawTextGridCentered("--- SCORE ---", 6, engine.types.Color.sky_blue);

        ctx.renderer.drawText("50      100", .{ .x = 0.45, .y = 0.3 }, engine.types.Color.sky_blue);
        ctx.renderer.drawText("80      160", .{ .x = 0.45, .y = 0.36 }, engine.types.Color.sky_blue);

        if (state.sprites.player_rotations.getSpriteForAngle(90.0)) |flipped| {
            ctx.renderer.drawFlippedSprite(flipped, .{ .x = 0.3, .y = 0.315 });
            ctx.renderer.drawFlippedSprite(flipped, .{ .x = 0.3, .y = 0.375 });
        }
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = self;
        _ = ctx;
    }
};
