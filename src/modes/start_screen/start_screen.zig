const std = @import("std");
const engine = @import("engine");
const Context = @import("../../context.zig").Context;
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;

pub const StartScreen = struct {
    const Self = @This();

    pub fn update(self: *Self, ctx: *Context, dt: f32) !?GameMode {
        _ = self;
        _ = dt;

        // Press 1 to start 1-player game
        if (ctx.input.isKeyPressed(.one)) {
            ctx.audio.playSound(.intro);
            return .playing;
        }

        return null;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *GameState) !void {
        _ = self;
        _ = state;

        // Show instructions
        ctx.renderer.text.drawTextCentered("PRESS 1 TO START", 0.4, 10, engine.types.Color.white);
        ctx.renderer.text.drawTextCentered("MOVE: ARROW KEYS OR WASD", 0.5, 8, engine.types.Color.gray);
        ctx.renderer.text.drawTextCentered("SHOOT: SPACE OR Z", 0.55, 8, engine.types.Color.gray);
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = self;
        _ = ctx;
    }

    pub fn init(allocator: std.mem.Allocator, ctx: *Context) !Self {
        _ = allocator;
        _ = ctx;
        return .{};
    }
};
