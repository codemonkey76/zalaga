const std = @import("std");
const engine = @import("engine");
const z = @import("../mod.zig");

pub const GameState = struct {
    player1: ?z.PlayerState,
    player2: ?z.PlayerState,
    player_state: z.PlayerState,
    hud: z.rendering.Hud,
    active_player: u8,
    last_player1_score: u32,
    last_player2_score: u32,
    credits: u32,
    high_score: u32,
    high_score_table: z.modes.HighScoreTable,
    allocator: std.mem.Allocator,
    starfield: z.rendering.Starfield,
    sprites: z.assets.Sprites,
    entity_manager: z.EntityManager,
    mode_state: union(z.modes.GameMode) {
        attract: z.modes.AttractMode,
        playing: z.modes.PlayingMode,
        high_score: z.modes.HighScoreMode,
        start_screen: z.modes.StartScreenMode,
    },

    const Self = @This();

    pub fn init(self: *Self, allocator: std.mem.Allocator, ctx: *z.Context) !void {
        // Preload all sounds
        inline for (@typeInfo(z.assets.SoundAsset).@"enum".fields) |field| {
            const sound_asset = @field(z.assets.SoundAsset, field.name);
            _ = try ctx.assets.loadSound(sound_asset);
        }
        self.sprites = try z.assets.Sprites.init(allocator, ctx);
        self.hud = z.rendering.Hud.init(allocator);
        self.starfield = try z.rendering.Starfield.init(allocator, ctx, .{ .parallax_strength = 400.0 });
        self.allocator = allocator;
        self.entity_manager = z.EntityManager.init(allocator);
        self.player_state = z.PlayerState{};
        self.player1 = null;
        self.player2 = null;
        self.active_player = 1;
        self.last_player1_score = 0;
        self.last_player2_score = 0;
        self.high_score = 20000;
        self.credits = 0;
        self.mode_state = .{ .attract = try z.modes.AttractMode.init(allocator, ctx) };

        // Load Cousine-Regular font
        const font = try ctx.assets.loadFont(.main_font);
        ctx.setFont(font.handle);
        ctx.assets.playSound(.die_boss);
    }

    pub fn update(self: *Self, ctx: *z.Context, dt: f32) !void {
        // Get player x position for starfield parallax
        var player_x: f32 = 0.5; // Default to center
        if (self.mode_state == .playing) {
            if (self.mode_state.playing.player_id) |player_id| {
                if (self.entity_manager.get(player_id)) |player| {
                    player_x = player.position.x;
                }
            }
        }

        self.starfield.update(ctx, dt, player_x);
        try self.hud.update(ctx, dt);

        const new_mode = switch (self.mode_state) {
            .playing => |*mode| try mode.update(ctx, dt, self),
            inline else => |*mode| try mode.update(ctx, dt),
        };

        if (new_mode) |mode| {
            try self.transitionTo(mode, ctx);
        }
    }

    fn transitionTo(self: *Self, new_mode: z.modes.GameMode, ctx: *z.Context) !void {
        switch (self.mode_state) {
            inline else => |*mode| mode.deinit(ctx),
        }

        // Clear entities on mode transition
        self.entity_manager.clear();

        self.mode_state = switch (new_mode) {
            .attract => .{ .attract = try z.modes.AttractMode.init(self.allocator, ctx) },
            .playing => .{ .playing = try z.modes.PlayingMode.init(self.allocator, ctx) },
            .high_score => .{ .high_score = try z.modes.HighScoreMode.init(self.allocator, ctx) },
            .start_screen => .{ .start_screen = try z.modes.StartScreenMode.init(self.allocator, ctx) },
        };
    }

    pub fn draw(self: *Self, ctx: *z.Context) !void {
        self.starfield.draw(ctx);
        try self.hud.draw(ctx, self);

        switch (self.mode_state) {
            inline else => |*mode| try mode.draw(ctx, self),
        }
    }

    pub fn shutdown(self: *Self, ctx: *z.Context) void {
        switch (self.mode_state) {
            inline else => |*mode| mode.deinit(ctx),
        }
        self.entity_manager.deinit();
        self.sprites.deinit();
        self.starfield.deinit();
    }
};
