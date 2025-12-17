const std = @import("std");
const engine = @import("engine");
const Color = engine.types.Color;
const GameState = @import("game_state.zig").GameState;
const PlayerState = @import("player_state.zig");

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

    pub fn draw(_: *Self, ctx: *engine.Context, state: *const GameState) !void {
        var buf: [16]u8 = undefined;
        ctx.renderer.drawTextGrid("   1UP", .{ .col = 0, .row = 0 }, Color.red);

        const p1_score = if (state.player1) |p1| p1.score else state.last_player1_score;
        const p1_score_str = try formatScore(p1_score, &buf);
        ctx.renderer.drawTextGrid(p1_score_str, .{ .col = 0, .row = 1 }, Color.white);

        // Player 2 score
        ctx.renderer.drawTextGridAnchored("2UP ", .{ .col = 0, .row = 0 }, Color.red, .top_right);

        const p2_score = if (state.player2) |p2| p2.score else state.last_player2_score;
        const p2_score_str = try formatScore(p2_score, &buf);
        ctx.renderer.drawTextGridAnchored(p2_score_str, .{ .col = 0, .row = 1 }, Color.white, .top_right);

        // High score
        ctx.renderer.drawTextGridCentered("HIGH-SCORE", 0, Color.red);
        const hs_str = try formatScore(state.high_score, &buf);
        ctx.renderer.drawTextGridCentered(hs_str, 1, Color.white);

        const credit_str = try std.fmt.bufPrintZ(&buf, "CREDITS {d}", .{state.credits});
        ctx.renderer.drawTextGridAnchored(credit_str, .{ .col = 0, .row = 0 }, Color.white, .bottom_left);
    }

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }
};

fn formatScore(score: u32, buf: []u8) ![:0]const u8 {
    const padded = @max(score, 0);
    if (padded < 10) {
        return try std.fmt.bufPrintZ(buf, "     0{d}", .{padded});
    }
    return try std.fmt.bufPrintZ(buf, "{d:>7}", .{padded});
}
