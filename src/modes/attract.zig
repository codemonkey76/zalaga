const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../game_mode.zig").GameMode;
const GameState = @import("../game_state.zig").GameState;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const createDemoScript = @import("demo_script.zig").createDemoScript;
const actions = @import("actions.zig");
const ActionExecutor = @import("action_executor.zig").ActionExecutor;
const MovementSystem = @import("movement_system.zig").MovementSystem;

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
    pub fn updateDemo(self: *Self, ctx: *engine.Context, dt: f32) !void {
        _ = ctx;
        if (self.demo_timeline) |*timeline| {
            try timeline.update(dt);
            // Update movement systems
            MovementSystem.updateEntities(timeline.executor.entities.entities.items, dt);
            MovementSystem.updateProjectiles(timeline.executor.entities.projectiles.items, dt);
        }
    }

    pub fn draw(self: *Self, ctx: *engine.Context, state: *GameState) !void {
        // Draw demo timeline if in demo mode
        if (self.submode == .demo_gameplay) {
            if (self.demo_timeline) |*timeline| {
                try drawDemoEntities(ctx, &timeline.executor.entities, &state.sprites);
            }
        }

        // TODO: Text drawing methods need to be implemented in engine
        // ctx.renderer.drawTextGridCentered("GALAGA", 4, engine.types.Color.sky_blue);
        // ctx.renderer.drawTextGridCentered("--- SCORE ---", 6, engine.types.Color.sky_blue);
        // ctx.renderer.drawText("50      100", .{ .x = 0.45, .y = 0.3 }, engine.types.Color.sky_blue);
        // ctx.renderer.drawText("80      160", .{ .x = 0.45, .y = 0.36 }, engine.types.Color.sky_blue);

        if (state.sprites.layouts.get(.goei)) |goei_layout| {
            if (goei_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.317 });
                // ctx.renderer.drawSprite(sprite, .{ .x = 0.65, .y = 0.677 });
                // ctx.renderer.drawSprite(sprite, .{ .x = 0.73, .y = 0.677 });
                // ctx.renderer.drawSprite(sprite, .{ .x = 0.85, .y = 0.677 });
            }
        }
        if (state.sprites.layouts.get(.zako)) |zako_layout| {
            if (zako_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.377 });
            }
        }

        // if (state.sprites.layouts.get(.boss)) |boss_layout| {
        //     if (boss_layout.getSprite(self.sprite_id)) |sprite| {
        // ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.497 });
        // ctx.renderer.drawSprite(sprite, .{ .x = 0.2, .y = 0.617 });
        // ctx.renderer.drawSprite(sprite, .{ .x = 0.4, .y = 0.617 });
        // ctx.renderer.drawSprite(sprite, .{ .x = 0.6, .y = 0.617 });
        // ctx.renderer.drawSprite(sprite, .{ .x = 0.8, .y = 0.617 });
        //     }
        // }
        // if (state.sprites.layouts.get(.player)) |player_layout| {
        //     if (player_layout.getSprite(.idle_1)) |sprite| {
        //         ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.91 });
        //         // ctx.renderer.drawSpriteAnchored(sprite, .{ .x = 0.0, .y = 1.0 }, .bottom_left);
        //     }
        // }
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

fn drawDemoEntities(ctx: *engine.Context, entities: anytype, sprites: anytype) !void {
    // Draw entities
    for (entities.entities.items) |*entity| {
        if (!entity.active) continue;

        if (sprites.layouts.get(entity.sprite_type)) |layout| {
            if (layout.getSprite(entity.sprite_id)) |sprite| {
                // Use rotation set only if entity is moving
                if (entity.isMoving()) {
                    if (sprites.rotations.get(entity.sprite_type)) |rotation_set| {
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

    // Draw projectiles
    for (entities.projectiles.items) |proj| {
        if (!proj.active) continue;
        ctx.renderer.drawFilledCircle(proj.position, 0.01, engine.types.Color.yellow);
    }
}
