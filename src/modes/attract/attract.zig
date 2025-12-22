const std = @import("std");
const engine = @import("engine");
const Context = @import("../../mod.zig").Context;
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;
const SpriteId = @import("../../assets/sprites.zig").SpriteId;
const createInfoScript = @import("info_script.zig").createInfoScript;
const actions = @import("demo_actions.zig");
const ActionExecutor = @import("demo_executor.zig").ActionExecutor;

const SPITE_FLIP_INTERVAL: f32 = 0.5;
const INFO_DURATION: f32 = 23.0;
const DEMO_DURATION: f32 = 60.0;
const HIGH_SCORE_DURATION: f32 = 5.0;

const DemoTimeline = engine.timeline.Timeline(actions.DemoAction, ActionExecutor);

pub const Attract = struct {
    submode: SubMode,
    timer: f32,
    wing_timer: f32 = 0.0,
    sprite_id: SpriteId = .idle_1,
    info_timeline: ?DemoTimeline = null,
    info_script: ?[]const actions.DemoAction = null,
    allocator: std.mem.Allocator,

    const Self = @This();

    const SubMode = enum {
        high_score_table,
        demo,
        info,
    };

    pub fn init(allocator: std.mem.Allocator, ctx: *Context) !Self {
        _ = ctx;

        const script = try createInfoScript(allocator);
        const executor = ActionExecutor.init(allocator);
        const timeline = try DemoTimeline.init(allocator, script, executor, .{ .loop = true });

        return .{
            .submode = .info,
            .timer = 0.0,
            .info_timeline = timeline,
            .info_script = script,
            .allocator = allocator,
        };
    }

    pub fn update(self: *Self, ctx: *Context, dt: f32) !?GameMode {
        self.timer += dt;
        self.wing_timer += dt;

        // Cycle through submodes
        switch (self.submode) {
            .info => {
                if (self.timer > INFO_DURATION) {
                    self.timer = 0;
                    self.submode = .demo;
                }
            },
            .demo => {
                if (self.timer > DEMO_DURATION) {
                    self.timer = 0;
                    self.submode = .high_score_table;
                }
            },
            .high_score_table => {
                if (self.timer > HIGH_SCORE_DURATION) {
                    self.timer = 0;
                    self.submode = .info;
                }
            },
        }

        // Animate sprites
        if (self.wing_timer > SPITE_FLIP_INTERVAL) {
            self.sprite_id = if (self.sprite_id == .idle_1) .idle_2 else .idle_1;
            self.wing_timer = 0;
        }

        // Update current submode
        switch (self.submode) {
            .high_score_table => try self.updateHighScores(ctx, dt),
            .demo => try self.updateDemo(ctx, dt),
            .info => try self.updateInfo(ctx, dt),
        }

        return null;
    }

    pub fn updateHighScores(self: *Self, ctx: *Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }

    pub fn updateInfo(self: *Self, _: *Context, dt: f32) !void {
        if (self.info_timeline) |*timeline| {
            try timeline.update(dt);
        }
    }

    pub fn updateDemo(self: *Self, ctx: *Context, dt: f32) !void {
        _ = self;
        _ = ctx;
        _ = dt;
    }

    pub fn draw(self: *Self, ctx: *Context, state: *GameState) !void {
        // Draw demo timeline if in demo mode
        if (self.submode == .info) {
            if (self.info_timeline) |*timeline| {
                try drawInfoEntities(ctx, &timeline.executor.entities, &state.sprites);
                // Draw timeline texts
                timeline.executor.drawTexts(ctx);
            }
        }
    }

    pub fn deinit(self: *Self, ctx: *Context) void {
        _ = ctx;

        if (self.info_timeline) |*timeline| {
            timeline.deinit();
        }
        if (self.info_script) |script| {
            self.allocator.free(script);
        }
    }
};

fn drawInfoEntities(ctx: *Context, entity_mgr: anytype, sprites: anytype) !void {
    // Draw all entities
    for (entity_mgr.getAll()) |*entity| {
        if (!entity.active) continue;

        const sprite_type = entity.sprite_type orelse continue;
        const sprite_id = entity.sprite_id orelse continue;

        if (sprites.layouts.get(sprite_type)) |layout| {
            if (layout.getSprite(sprite_id)) |sprite| {
                // Use rotation set only if entity is moving
                if (entity.isMoving()) {
                    if (sprites.rotations.get(sprite_type)) |rotation_set| {
                        if (rotation_set.getSpriteForAngle(entity.angle)) |flipped| {
                            ctx.renderer.drawFlippedSprite(flipped, entity.position);
                            continue;
                        }
                    }
                }
                ctx.renderer.drawSprite(sprite, entity.position);
            }
        }
    }
}
