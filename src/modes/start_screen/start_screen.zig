const std = @import("std");
const engine = @import("engine");
const Context = @import("../../mod.zig").Context;
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;
const c = @import("../../constants.zig");
const PlayerState = @import("../../gameplay/player_state.zig").PlayerState;

pub const StartScreen = struct {
    allocator: std.mem.Allocator,
    const Self = @This();

    pub fn update(self: *Self, ctx: *Context, dt: f32, state: *GameState) !?GameMode {
        _ = dt;

        // Press 1 to start 1-player game
        if (ctx.input.isKeyPressed(.one) and state.credits > 0) {
            state.credits -= 1;
            state.player1 = PlayerState.init(self.allocator);
            state.player2 = null;
            state.active_player = .player1;
            return .playing;
        }

        // Press 2 to start 2-player game
        if (ctx.input.isKeyPressed(.two) and state.credits >= 2) {
            state.credits -= 2;
            state.player1 = PlayerState.init(self.allocator);
            state.player2 = PlayerState.init(self.allocator);
            state.active_player = .player1;
            return .playing;
        }

        return null;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *GameState) !void {
        _ = self;

        ctx.renderer.text.drawTextCentered("PUSH START BUTTON", 0.33, 10, engine.types.Color.sky_blue);

        if (state.sprites.getSprite(.player, .idle_1)) |sprite| {
            ctx.renderer.drawSprite(sprite, .{ .x = 0.15, .y = 0.455 });
            ctx.renderer.drawSprite(sprite, .{ .x = 0.15, .y = 0.535 });
            ctx.renderer.drawSprite(sprite, .{ .x = 0.15, .y = 0.615 });
        }

        ctx.renderer.text.drawText("1ST BONUS for 30000 PTS", .{ .x = 0.23, .y = 0.44 }, 10, engine.types.Color.yellow);
        ctx.renderer.text.drawText("2ND BONUS FOR 100000 PTS", .{ .x = 0.23, .y = 0.52 }, 10, engine.types.Color.yellow);
        ctx.renderer.text.drawText("AND FOR EVERY 100000 PTS", .{ .x = 0.23, .y = 0.60 }, 10, engine.types.Color.yellow);

        ctx.renderer.text.drawTextCentered("© 1981 NAMCO LTD.", 0.8, 10, engine.types.Color.white);
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = self;
        _ = ctx;
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }
};
