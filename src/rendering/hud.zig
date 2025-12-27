const std = @import("std");
const engine = @import("engine");
const Context = @import("../mod.zig").Context;
const Color = engine.types.Color;
const GameState = @import("../core/game_state.zig").GameState;
const PlayerState = @import("../gameplay/player_state.zig");

pub const Hud = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn draw(_: *Self, ctx: *Context, state: *const GameState) !void {
        var buf: [16]u8 = undefined;

        // Player 1 score (top left)
        ctx.renderer.text.drawText("1UP", .{ .x = 0.05, .y = 0.02 }, 10, Color.red);

        const p1_score = state.player_state.score;
        const p1_score_str = try formatScore(p1_score, &buf);
        ctx.renderer.text.drawText(p1_score_str, .{ .x = 0.05, .y = 0.05 }, 10, Color.white);

        // High score (centered)
        ctx.renderer.text.drawTextCentered("HIGH SCORE", 0.02, 10, Color.red);
        const hs_str = try formatScore(state.high_score, &buf);
        ctx.renderer.text.drawTextCentered(hs_str, 0.05, 10, Color.white);

        // Player 2 score (top right)
        ctx.renderer.text.drawTextRightAligned("2UP", .{ .x = 0.95, .y = 0.02 }, 10, Color.red);

        const p2_score = if (state.player2) |p2| p2.score else state.last_player2_score;
        const p2_score_str = try formatScore(p2_score, &buf);
        ctx.renderer.text.drawTextRightAligned(p2_score_str, .{ .x = 0.95, .y = 0.05 }, 10, Color.white);

        // Credits (bottom left)

        switch (state.mode_state) {
            .playing => {},
            else => {
                const credit_str = try std.fmt.bufPrint(&buf, "CREDIT {d}", .{state.credits});
                ctx.renderer.text.drawText(credit_str, .{ .x = 0.05, .y = 0.95 }, 10, Color.white);
            },
        }
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }
};

fn formatScore(score: u32, buf: []u8) ![]const u8 {
    const padded = @max(score, 0);
    if (padded < 10) {
        return try std.fmt.bufPrint(buf, "     0{d}", .{padded});
    }
    return try std.fmt.bufPrint(buf, "{d:>7}", .{padded});
}
