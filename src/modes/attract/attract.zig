const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../mode.zig").GameMode;
const GameState = @import("../../core/game_state.zig").GameState;
const SpriteId = @import("../../assets/sprites.zig").SpriteId;
const createDemoScript = @import("demo_script.zig").createDemoScript;
const actions = @import("demo_actions.zig");
const ActionExecutor = @import("demo_executor.zig").ActionExecutor;
const MovementSystem = @import("../../systems/movement.zig").MovementSystem;

const SPITE_FLIP_INTERVAL: f32 = 0.5;
const ATTRACT_MODE_DURATION: f32 = 5.0;

const DemoTimeline = engine.timeline.Timeline(actions.DemoAction, ActionExecutor);

pub const Attract = struct {
    submode: SubMode,
    timer: f32,
    wing_timer: f32 = 0.0,
    sprite_id: SpriteId = .idle_1,
    demo_timeline: ?DemoTimeline = null,
    demo_script: ?[]const actions.DemoAction = null,
    allocator: std.mem.Allocator,

    const Self = @This();

    const SubMode = enum {
        high_score_table,
        game_info,
        demo_gameplay,
    };

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        _ = ctx;

        const script = try createDemoScript(allocator);
        const executor = ActionExecutor.init(allocator);
        const timeline = try DemoTimeline.init(allocator, script, executor, .{ .loop = true });

        return .{
            .submode = .game_info,
            .timer = 0.0,
            .demo_timeline = timeline,
            .demo_script = script,
            .allocator = allocator,
        };
    }

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !?GameMode {
        self.timer += dt;
        self.wing_timer += dt;

        // Cycle through submodes
        if (self.timer > ATTRACT_MODE_DURATION) {
            self.timer = 0;
            self.submode = switch (self.submode) {
                .high_score_table => .game_info,
                .game_info => .demo_gameplay,
                .demo_gameplay => .high_score_table,
            };
        }

        // Animate sprites
        if (self.wing_timer > SPITE_FLIP_INTERVAL) {
            self.sprite_id = if (self.sprite_id == .idle_1) .idle_2 else .idle_1;
            self.wing_timer = 0;
        }

        // Update current submode
        switch (self.submode) {
            .high_score_table => try self.updateHighScores(ctx, dt),
            .game_info => try self.updateInfo(ctx, dt),
            .demo_gameplay => try self.updateDemo(ctx, dt),
        }

        // Check for coin insertion
        if (ctx.input.isKeyPressed(.five)) {
            return .start_screen;
        }

        return null;
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
    pub fn updateDemo(self: *Self, _: *engine.Context, dt: f32) !void {
        if (self.demo_timeline) |*timeline| {
            try timeline.update(dt);
            // Additional per-frame movement update
            MovementSystem.update(timeline.executor.entities.getAll(), dt);
        }
    }

    pub fn draw(self: *Self, ctx: *engine.Context, state: *GameState) !void {
        // Draw demo timeline if in demo mode
        if (self.submode == .demo_gameplay) {
            if (self.demo_timeline) |*timeline| {
                try drawDemoEntities(ctx, &timeline.executor.entities, &state.sprites);
            }
        }

        // Draw title and score info
        ctx.renderer.text.drawTextCentered("GALAGA", 0.15, 16, engine.types.Color.white);
        ctx.renderer.text.drawTextCentered("- SCORE ADVANCE TABLE -", 0.22, 10, engine.types.Color.red);

        // Draw enemy scores with sprites
        if (state.sprites.layouts.get(.goei)) |goei_layout| {
            if (goei_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.32 });
            }
        }
        ctx.renderer.text.drawText("- 50 PTS   - 100 PTS", .{ .x = 0.38, .y = 0.31 }, 10, engine.types.Color.white);

        if (state.sprites.layouts.get(.zako)) |zako_layout| {
            if (zako_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.38 });
            }
        }
        ctx.renderer.text.drawText("- 80 PTS   - 160 PTS", .{ .x = 0.38, .y = 0.37 }, 10, engine.types.Color.white);
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = ctx;

        if (self.demo_timeline) |*timeline| {
            timeline.deinit();
        }
        if (self.demo_script) |script| {
            self.allocator.free(script);
        }
    }
};

fn drawDemoEntities(ctx: *engine.Context, entity_mgr: anytype, sprites: anytype) !void {
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
