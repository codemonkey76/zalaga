const std = @import("std");
const engine = @import("engine");
const GameMode = @import("../game_mode.zig").GameMode;
const GameState = @import("../game_state.zig").GameState;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const SpriteType = @import("../assets/sprites.zig").SpriteType;
const Sprites = @import("../assets/sprites.zig").Sprites;

const ActionType = enum {
    move_to, // Move entity to position,
    shoot_at, // Fire projectile at target
    spawn_entity, // Create entity at position
    wait, // Pause timeline
    set_animation, // Change sprite animation
    despawn_entity, // Remove entity
    path_follow, // Follow bezier curve (using arcade_lib)
};

const EntityType = enum {
    player,
    boss,
    goei,
    zako,
    projectile,
};

const EntityRef = union(enum) {
    id: u32, // Specific entity ID
    tag: EntityType, // First entity of this type
};

const ActionData = union(ActionType) {
    move_to: struct {
        target: EntityRef,
        position: engine.types.Vec2,
        speed: f32,
        ease: Easing = .linear,
    },
    shoot_at: struct {
        shooter: EntityRef,
        target: EntityRef,
        projectile_speed: f32,
    },
    spawn_entity: struct {
        entity_type: EntityType,
        sprite_type: SpriteType,
        position: engine.types.Vec2,
        out_id: ?*u32 = null, // Optional: store generated ID
    },
    wait: struct {
        // Duration handled by DemoAction.duration
    },
    set_animation: struct {
        target: EntityRef,
        sprite_id: SpriteId,
    },
    despawn_entity: struct {
        target: EntityRef,
    },
    path_follow: struct {
        target: EntityRef,
        path: []const engine.types.Vec2, // Or use arcade_lib curve
    },
};

const Easing = enum {
    linear,
    ease_in,
    ease_out,
    ease_in_out,
};

pub const DemoAction = struct {
    start_time: f32,
    duration: f32,
    action: ActionData,

    pub fn isActive(self: DemoAction, time: f32) bool {
        return time >= self.start_time and time < (self.start_time + self.duration);
    }

    pub fn progress(self: DemoAction, time: f32) f32 {
        if (time < self.start_time) return 0.0;
        if (time >= self.start_time + self.duration) return 1.0;
        return (time - self.start_time) / self.duration;
    }
};

const DemoEntity = struct {
    id: u32,
    entity_type: EntityType,
    sprite_type: SpriteType,
    position: engine.types.Vec2,
    sprite_id: SpriteId = .idle_1,
    angle: f32 = 0.0,
    active: bool = true,

    // Movement state
    velocity: engine.types.Vec2 = .{ .x = 0, .y = 0 },
    target_pos: ?engine.types.Vec2 = null,
    move_speed: f32 = 0,
    path_index: usize = 0,
    path_t: f32 = 0.0,
};

const Projectile = struct {
    position: engine.types.Vec2,
    velocity: engine.types.Vec2,
    active: bool = true,
};

const DemoTimeline = struct {
    allocator: std.mem.Allocator,
    actions: []const DemoAction,
    entities: std.ArrayList(DemoEntity),
    projectiles: std.ArrayList(Projectile),
    next_entity_id: u32 = 1,
    elapsed_time: f32 = 0.0,
    active_actions: std.AutoHashMap(usize, void), // Track in progress actions

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, actions: []const DemoAction) !Self {
        return .{
            .allocator = allocator,
            .actions = actions,
            .entities = std.ArrayList(DemoEntity){},
            .projectiles = std.ArrayList(Projectile){},
            .active_actions = std.AutoHashMap(usize, void).init(allocator),
        };
    }

    pub fn update(self: *Self, dt: f32) !void {
        self.elapsed_time += dt;

        // Check for new actions to start
        for (self.actions, 0..) |action, idx| {
            if (action.start_time <= self.elapsed_time and
                action.start_time + action.duration > self.elapsed_time)
            {
                if (!self.active_actions.contains(idx)) {
                    try self.startAction(action);
                    try self.active_actions.put(idx, {});
                }

                try self.updateAction(action, dt);
            }
        }

        // Update all entities
        for (self.entities.items) |*entity| {
            if (!entity.active) continue;

            // Apply velocity
            entity.position.x += entity.velocity.x * dt;
            entity.position.y += entity.velocity.y * dt;

            // Move toward target if set
            if (entity.target_pos) |target| {
                const dx = target.x - entity.position.x;
                const dy = target.y - entity.position.y;
                const dist = @sqrt(dx * dx + dy * dy);

                if (dist < 0.01) {
                    entity.position = target;
                    entity.target_pos = null;
                    entity.velocity = .{ .x = 0, .y = 0 };
                } else {
                    entity.velocity.x = (dx / dist) * entity.move_speed;
                    entity.velocity.y = (dy / dist) * entity.move_speed;

                    // Update angle based on direction
                    entity.angle = std.math.radiansToDegrees(std.math.atan2(dy, dx)) + 90.0;
                }
            }
        }

        // Update projectiles
        for (self.projectiles.items) |*proj| {
            if (!proj.active) continue;
            proj.position.x += proj.velocity.x * dt;
            proj.position.y += proj.velocity.y * dt;

            // Deactivate if off-screen
            if (proj.position.y < -0.1 or proj.position.y > 1.1) {
                proj.active = false;
            }
        }

        // Loop demo when finished
        if (self.elapsed_time > self.getTotalDuration()) {
            try self.reset();
        }
    }

    fn startAction(self: *Self, action: DemoAction) !void {
        switch (action.action) {
            .spawn_entity => |spawn| {
                const id = self.next_entity_id;
                self.next_entity_id += 1;

                try self.entities.append(self.allocator, .{
                    .id = id,
                    .entity_type = spawn.entity_type,
                    .sprite_type = spawn.sprite_type,
                    .position = spawn.position,
                });
            },
            else => {},
        }
    }

    fn updateAction(self: *Self, action: DemoAction, dt: f32) !void {
        _ = dt;
        const t = action.progress(self.elapsed_time);

        switch (action.action) {
            .move_to => |move| {
                if (self.findEntity(move.target)) |entity| {
                    entity.target_pos = move.position;
                    entity.move_speed = move.speed;
                }
            },
            .shoot_at => |shoot| {
                // Only shoot once at start of action
                if (t < 0.01) {
                    if (self.findEntity(shoot.shooter)) |shooter| {
                        var target_pos: engine.types.Vec2 = undefined;

                        if (self.findEntity(shoot.target)) |target| {
                            target_pos = target.position;
                        } else {
                            target_pos = shooter.position;
                            target_pos.y = -0.1;
                        }

                        const dx = target_pos.x - shooter.position.x;
                        const dy = target_pos.y - shooter.position.y;
                        const dist = @sqrt(dx * dx + dy * dy);

                        try self.projectiles.append(self.allocator, .{ .position = shooter.position, .velocity = .{
                            .x = (dx / dist) * shoot.projectile_speed,
                            .y = (dy / dist) * shoot.projectile_speed,
                        } });
                    }
                }
            },
            .set_animation => |anim| {
                if (self.findEntity(anim.target)) |entity| {
                    entity.sprite_id = anim.sprite_id;
                }
            },
            .despawn_entity => |despawn| {
                if (self.findEntity(despawn.target)) |entity| {
                    entity.active = false;
                }
            },
            else => {},
        }
    }

    fn findEntity(self: *Self, ref: EntityRef) ?*DemoEntity {
        return switch (ref) {
            .id => |id| {
                for (self.entities.items) |*entity| {
                    if (entity.id == id and entity.active) return entity;
                }
                return null;
            },
            .tag => |tag| {
                for (self.entities.items) |*entity| {
                    if (entity.entity_type == tag and entity.active) return entity;
                }
                return null;
            },
        };
    }

    fn getTotalDuration(self: Self) f32 {
        var max: f32 = 0;
        for (self.actions) |action| {
            const end = action.start_time + action.duration;
            if (end > max) max = end;
        }
        return max;
    }

    pub fn reset(self: *Self) !void {
        self.elapsed_time = 0;
        self.entities.clearRetainingCapacity();
        self.projectiles.clearRetainingCapacity();
        self.active_actions.clearRetainingCapacity();
        self.next_entity_id = 1;
    }

    pub fn draw(self: *Self, ctx: *engine.Context, sprites: *Sprites) !void {
        // Draw entities
        for (self.entities.items) |*entity| {
            if (!entity.active) continue;

            if (sprites.layouts.get(entity.sprite_type)) |layout| {
                if (layout.getSprite(entity.sprite_id)) |sprite| {
                    // use rotation set if moving
                    if (sprites.rotations.get(entity.sprite_type)) |rotation_set| {
                        if (rotation_set.getSpriteForAngle(entity.angle)) |flipped| {
                            ctx.renderer.drawFlippedSprite(flipped, entity.position);
                            continue;
                        }
                    }
                    ctx.renderer.drawSprite(sprite, entity.position);
                }
            }
        }

        // Draw projectiles (simple colored circles for now)
        for (self.projectiles.items) |proj| {
            if (!proj.active) continue;
            ctx.renderer.drawFilledCircle(proj.position, 0.01, engine.types.Color.yellow);
        }
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit(self.allocator);
        self.projectiles.deinit(self.allocator);
        self.active_actions.deinit();
        self.allocator.free(self.actions);
    }
};

fn createDemoScript(allocator: std.mem.Allocator) ![]const DemoAction {
    var script = std.ArrayList(DemoAction){};

    // 0.0s: spawn player at bottom center
    try script.append(allocator, .{ .start_time = 0.0, .duration = 0.5, .action = .{ .spawn_entity = .{
        .entity_type = .player,
        .sprite_type = .player,
        .position = .{ .x = 0.5, .y = 0.9 },
    } } });

    // 0.5s Spawn bosses at top
    try script.append(allocator, .{ .start_time = 0.5, .duration = 0.1, .action = .{
        .spawn_entity = .{
            .entity_type = .boss,
            .sprite_type = .boss,
            .position = .{ .x = 0.3, .y = 0.15 },
        },
    } });
    try script.append(allocator, .{
        .start_time = 0.6,
        .duration = 0.1,
        .action = .{
            .spawn_entity = .{
                .entity_type = .boss,
                .sprite_type = .boss,
                .position = .{ .x = 0.7, .y = 0.15 },
            },
        },
    });
    // 1.0s: Player moves right
    try script.append(allocator, .{
        .start_time = 1.0,
        .duration = 2.0,
        .action = .{ .move_to = .{
            .target = .{ .tag = .player },
            .position = .{ .x = 0.7, .y = 0.9 },
            .speed = 0.15,
        } },
    });

    // 2.5s: Player shoots first boss
    try script.append(allocator, .{
        .start_time = 2.5,
        .duration = 0.1,
        .action = .{
            .shoot_at = .{
                .shooter = .{ .tag = .player },
                .target = .{ .id = 2 }, // First boss
                .projectile_speed = 0.5,
            },
        },
    });

    // 3.0s: Wait for projectile to hit
    try script.append(allocator, .{
        .start_time = 3.0,
        .duration = 0.5,
        .action = .{ .wait = .{} },
    });
    // 3.5s: Despawn first boss
    try script.append(allocator, .{
        .start_time = 3.5,
        .duration = 0.1,
        .action = .{ .despawn_entity = .{
            .target = .{ .id = 2 },
        } },
    });

    // 4.0s: Player shoots second boss
    try script.append(allocator, .{
        .start_time = 4.0,
        .duration = 0.1,
        .action = .{
            .shoot_at = .{
                .shooter = .{ .tag = .player },
                .target = .{ .id = 3 }, // Second boss
                .projectile_speed = 0.5,
            },
        },
    });

    // 5.0s: Despawn second boss
    try script.append(allocator, .{
        .start_time = 5.0,
        .duration = 0.1,
        .action = .{ .despawn_entity = .{
            .target = .{ .id = 3 },
        } },
    });
    // 6.0s: Spawn enemies at top corners
    try script.append(allocator, .{
        .start_time = 6.0,
        .duration = 0.1,
        .action = .{ .spawn_entity = .{
            .entity_type = .goei,
            .sprite_type = .goei,
            .position = .{ .x = 0.2, .y = -0.1 },
        } },
    });
    try script.append(allocator, .{
        .start_time = 6.1,
        .duration = 0.1,
        .action = .{ .spawn_entity = .{
            .entity_type = .zako,
            .sprite_type = .zako,
            .position = .{ .x = 0.8, .y = -0.1 },
        } },
    });

    // 6.5s: Enemies swoop down toward player
    try script.append(allocator, .{
        .start_time = 6.5,
        .duration = 3.0,
        .action = .{
            .move_to = .{
                .target = .{ .id = 4 }, // First enemy
                .position = .{ .x = 0.4, .y = 0.8 },
                .speed = 0.3,
            },
        },
    });
    try script.append(allocator, .{
        .start_time = 6.7,
        .duration = 3.0,
        .action = .{
            .move_to = .{
                .target = .{ .id = 5 }, // Second enemy
                .position = .{ .x = 0.6, .y = 0.8 },
                .speed = 0.3,
            },
        },
    });

    // 10.0s: Demo ends, loops

    return try script.toOwnedSlice(allocator);
}
pub const Attract = struct {
    submode: SubMode,
    timer: f32,
    wing_timer: f32 = 0.0,
    sprite_id: SpriteId = .idle_1,
    demo_timeline: ?DemoTimeline = null,

    const Self = @This();

    const SubMode = enum {
        high_score_table,
        game_info,
        demo_gameplay,
    };

    pub fn update(self: *Self, ctx: *engine.Context, dt: f32) !?GameMode {
        self.timer += dt;
        self.wing_timer += dt;

        // Potentially time out to a new mode
        if (self.timer > 5.0) {
            self.timer = 0;
            self.submode = switch (self.submode) {
                .high_score_table => .game_info,
                .game_info => .demo_gameplay,
                .demo_gameplay => .high_score_table,
            };
        }

        if (self.wing_timer > 0.5) {
            if (self.sprite_id == .idle_1) {
                self.sprite_id = .idle_2;
            } else {
                self.sprite_id = .idle_1;
            }
            self.wing_timer = 0;
        }

        // Update current submode
        switch (self.submode) {
            .high_score_table => try self.updateHighScores(ctx, dt),
            .game_info => try self.updateInfo(ctx, dt),
            .demo_gameplay => try self.updateDemo(ctx, dt),
        }

        if (ctx.input.isKeyPressed(.five)) {
            return .start_screen;
        }

        return null;
    }

    pub fn init(allocator: std.mem.Allocator, ctx: *engine.Context) !Self {
        _ = ctx;

        const script = try createDemoScript(allocator);
        const timeline = try DemoTimeline.init(allocator, script);
        return .{
            .submode = .game_info,
            .timer = 0.0,
            .demo_timeline = timeline,
        };
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
        }
    }

    pub fn draw(self: *Self, ctx: *engine.Context, state: *GameState) !void {
        // Draw demo timeline if in demo mode
        if (self.submode == .demo_gameplay) {
            if (self.demo_timeline) |*timeline| {
                try timeline.draw(ctx, &state.sprites);
                return; // Skip static attract screen when showing demo
            }
        }

        ctx.renderer.drawTextGridCentered("GALAGA", 4, engine.types.Color.sky_blue);
        ctx.renderer.drawTextGridCentered("--- SCORE ---", 6, engine.types.Color.sky_blue);

        ctx.renderer.drawText("50      100", .{ .x = 0.45, .y = 0.3 }, engine.types.Color.sky_blue);
        ctx.renderer.drawText("80      160", .{ .x = 0.45, .y = 0.36 }, engine.types.Color.sky_blue);

        if (state.sprites.layouts.get(.goei)) |goei_layout| {
            if (goei_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.317 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.65, .y = 0.677 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.73, .y = 0.677 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.85, .y = 0.677 });
            }
        }
        if (state.sprites.layouts.get(.zako)) |zako_layout| {
            if (zako_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.3, .y = 0.377 });
            }
        }

        if (state.sprites.layouts.get(.boss)) |boss_layout| {
            if (boss_layout.getSprite(self.sprite_id)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.497 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.2, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.4, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.6, .y = 0.617 });
                ctx.renderer.drawSprite(sprite, .{ .x = 0.8, .y = 0.617 });
            }
        }
        if (state.sprites.layouts.get(.player)) |player_layout| {
            if (player_layout.getSprite(.idle_1)) |sprite| {
                ctx.renderer.drawSprite(sprite, .{ .x = 0.5, .y = 0.91 });
                // ctx.renderer.drawSpriteAnchored(sprite, .{ .x = 0.0, .y = 1.0 }, .bottom_left);
            }
        }
    }

    pub fn deinit(self: *Self, ctx: *engine.Context) void {
        _ = ctx;

        if (self.demo_timeline) |*timeline| {
            timeline.deinit();
        }
    }
};
