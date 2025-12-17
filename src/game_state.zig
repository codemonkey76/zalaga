const std = @import("std");
const engine = @import("engine");

const Starfield = @import("graphics/starfield.zig").Starfield;
const Assets = @import("assets/assets.zig").Assets;
const Sprites = @import("assets/sprites.zig").Sprites;
const GameMode = @import("game_mode.zig").GameMode;
const AttractMode = @import("modes/attract.zig").Attract;
const PlayingMode = @import("modes/playing.zig").Playing;
const HighScoreMode = @import("modes/high_score.zig").HighScore;
const StartScreenMode = @import("modes/start_screen.zig").StartScreen;
const PlayerState = @import("player_state.zig").PlayerState;
const HighScoreTable = @import("high_scores.zig").HighScoreTable;
const Hud = @import("hud.zig").Hud;

pub const GameState = struct {
    player1: ?PlayerState,
    player2: ?PlayerState,
    hud: Hud,
    active_player: u8,
    last_player1_score: u32,
    last_player2_score: u32,
    credits: u32,
    high_score: u32,
    high_score_table: HighScoreTable,
    allocator: std.mem.Allocator,
    starfield: Starfield,
    assets: Assets,
    sprites: Sprites,
    mode_state: union(GameMode) {
        attract: AttractMode,
        playing: PlayingMode,
        high_score: HighScoreMode,
        start_screen: StartScreenMode,
    },

    const Self = @This();

    pub fn init(self: *Self, allocator: std.mem.Allocator, ctx: *engine.Context) !void {
        self.assets = try Assets.init(allocator, ctx);
        self.sprites = try Sprites.init(allocator, ctx);
        self.hud = Hud.init(allocator);
        self.starfield = try Starfield.init(allocator, ctx, .{});
        self.allocator = allocator;
        self.player1 = null;
        self.player2 = null;
        self.active_player = 1;
        self.last_player1_score = 0;
        self.last_player2_score = 0;
        self.high_score = 20000;
        self.credits = 0;
        self.mode_state = .{ .attract = try AttractMode.init(allocator, ctx) };
    }

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !void {
        self.starfield.update(ctx, dt);
        try self.hud.update(ctx, dt);

        const new_mode = switch (self.mode_state) {
            inline else => |*mode| try mode.update(ctx, dt),
        };

        if (new_mode) |mode| {
            try self.transitionTo(mode, ctx);
        }
    }

    fn transitionTo(self: *Self, new_mode: GameMode, ctx: *engine.Context) !void {
        switch (self.mode_state) {
            inline else => |*mode| mode.deinit(ctx),
        }

        self.mode_state = switch (new_mode) {
            .attract => .{ .attract = try AttractMode.init(self.allocator, ctx) },
            .playing => .{ .playing = try PlayingMode.init(self.allocator, ctx) },
            .high_score => .{ .high_score = try HighScoreMode.init(self.allocator, ctx) },
            .start_screen => .{ .start_screen = try StartScreenMode.init(self.allocator, ctx) },
        };
    }

    pub fn draw(self: *Self, ctx: *engine.Context) !void {
        self.starfield.draw(ctx);
        try self.hud.draw(ctx, self);

        switch (self.mode_state) {
            inline else => |*mode| try mode.draw(ctx, self),
        }
    }

    pub fn shutdown(self: *Self, ctx: *engine.Context) void {
        switch (self.mode_state) {
            inline else => |*mode| mode.deinit(ctx),
        }
        self.sprites.deinit();
        self.starfield.deinit();
        self.assets.deinit(ctx);
    }
};
