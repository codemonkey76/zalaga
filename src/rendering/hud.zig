const std = @import("std");
const engine = @import("engine");
const Context = @import("../mod.zig").Context;
const Color = engine.types.Color;
const GameState = @import("../core/game_state.zig").GameState;
const PlayerState = @import("../gameplay/player_state.zig").PlayerState;

pub const Hud = struct {
    allocator: std.mem.Allocator,
    flash_timer: f32 = 0,
    flash_on: bool = true,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *const GameState) !void {
        self.draw_p1_score(ctx, state);
        self.draw_high_score(ctx, state);
        self.draw_p2_score(ctx, state);

        switch (state.mode_state) {
            .playing => {
                self.drawLives(ctx, state);
                self.drawLevelMarkers(ctx, state);
            },
            else => {
                self.draw_credits(ctx, state);
            },
        }
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32) !void {
        _ = ctx;
        self.flash_timer += dt;

        if (self.flash_timer > 0.5) {
            self.flash_on = !self.flash_on;
            self.flash_timer = 0;
        }
    }

    fn draw_p1_score(self: *Self, ctx: *Context, state: *const GameState) void {
        var buf: [16]u8 = undefined;

        if (state.mode_state != .playing or
            (state.active_player == .player1 and self.flash_on and state.mode_state == .playing) or
            (state.mode_state == .playing and state.active_player != .player1))
        {
            ctx.renderer.text.drawText("  1UP ", .{ .x = 0.0, .y = 0.02 }, 10, Color.red);
        }

        const p1_score = getDisplayScore(state.player1, state.last_player1_score, state.mode_state == .playing);
        const p1_score_str = formatScore(p1_score, &buf, 6) catch "00";
        ctx.renderer.text.drawText(p1_score_str, .{ .x = 0.0, .y = 0.05 }, 10, Color.white);
    }

    fn draw_p2_score(self: *Self, ctx: *Context, state: *const GameState) void {
        var buf: [16]u8 = undefined;

        if (state.mode_state != .playing or
            (state.active_player == .player2 and self.flash_on and state.mode_state == .playing) or
            (state.mode_state == .playing and state.active_player != .player2))
        {
            ctx.renderer.text.drawTextRightAligned("  2UP ", .{ .x = 0.95, .y = 0.02 }, 10, Color.red);
        }

        const p2_score = getDisplayScore(state.player2, state.last_player2_score, state.mode_state == .playing);
        const p2_score_str = formatScore(p2_score, &buf, 7) catch "00";
        ctx.renderer.text.drawTextRightAligned(p2_score_str, .{ .x = 0.95, .y = 0.05 }, 10, Color.white);
    }

    fn draw_high_score(_: *Self, ctx: *Context, state: *const GameState) void {
        var buf: [16]u8 = undefined;

        ctx.renderer.text.drawTextCentered("HIGH SCORE", 0.02, 10, Color.red);
        const hs_str = formatScore(state.high_score, &buf, 7) catch "20000";
        ctx.renderer.text.drawTextCentered(hs_str, 0.05, 10, Color.white);
    }

    fn draw_credits(_: *Self, ctx: *Context, state: *const GameState) void {
        var buf: [16]u8 = undefined;

        const credit_str = std.fmt.bufPrint(&buf, "CREDIT {d}", .{state.credits}) catch "CREDIT 0";
        ctx.renderer.text.drawText(credit_str, .{ .x = 0.05, .y = 0.95 }, 10, Color.white);
    }

    fn drawLives(self: *Self, ctx: *Context, state: *const GameState) void {
        _ = self;

        const player_sprite = state.sprites.getSprite(.player, .idle_1) orelse return;
        const player = state.getActivePlayer() orelse return;
        const lives = player.lives;
        const width = ctx.renderer.spriteWidth(player_sprite);

        for (0..lives) |i| {
            ctx.renderer.drawSpriteAnchored(player_sprite, .{ .x = 0.0 + @as(f32, @floatFromInt(i)) * width, .y = 1.0 }, .bottom_left);
        }
    }

    fn drawLevelMarkers(self: *Self, ctx: *Context, state: *const GameState) void {
        _ = self;
        std.debug.print("Drawing level markers\n", .{});

        const player = state.getActivePlayer() orelse return;
        const markers = player.level_markers;

        const active = if (state.active_player == .player1) "Player 1" else "Player 2";
        std.debug.print("Active player: {s}\n", .{active});

        // Measure the width
        var width: f32 = 0;
        for (0..markers.markers.items.len) |i| {
            if (state.sprites.level_marker_layout.getSprite(markers.markers.items[i])) |sprite| {
                width += ctx.renderer.spriteWidth(sprite);
            }
        }
        std.debug.print("Level marker width: {}\n", .{width});
        std.debug.print("Total markers: {}\n", .{markers.markers.items.len});

        var x_offset: f32 = 1.0 - width;
        const y_pos: f32 = 1.0;

        for (0..markers.display_index) |i| {
            if (state.sprites.level_marker_layout.getSprite(markers.markers.items[i])) |sprite| {
                ctx.renderer.drawSpriteAnchored(sprite, .{ .x = x_offset, .y = y_pos }, .bottom_right);
                x_offset -= ctx.renderer.spriteWidth(sprite);
            }
        }
    }

    fn getDisplayScore(player: ?PlayerState, last_score: u32, is_playing: bool) u32 {
        if (is_playing) {
            return if (player) |p| p.score else 0;
        }
        return last_score;
    }

    fn formatScore(score: u32, buf: []u8, width: u32) ![]const u8 {
        const padded = @max(score, 0);
        if (padded < 10) {
            return try std.fmt.bufPrint(buf, "    0{d}", .{padded});
        }
        return try std.fmt.bufPrint(buf, "{[0]d:>[1]}", .{ padded, width });
    }
};
