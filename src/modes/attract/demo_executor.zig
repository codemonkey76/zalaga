const std = @import("std");
const engine = @import("engine");
const z = @import("../../mod.zig");
const Context = @import("../../mod.zig").Context;
const actions = @import("demo_actions.zig");
const EntityManager = @import("../../entities/entity_manager.zig").EntityManager;

// Track active movements with easing
const MovementState = struct {
    entity_id: u32,
    start_pos: engine.types.Vec2,
    target_pos: engine.types.Vec2,
    ease_fn: actions.EasingFn,
};

// Track active text displays
const TextState = struct {
    action_id: usize,
    text: []const u8,
    position: ?engine.types.Vec2,
    y: ?f32,
    font_size: u32,
    color: engine.types.Color,
    centered: bool,
};

pub const ActionExecutor = struct {
    entities: EntityManager,
    allocator: std.mem.Allocator,
    ctx: *z.Context,
    active_movements: std.ArrayList(MovementState),
    active_texts: std.ArrayList(TextState),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, ctx: *z.Context) Self {
        return .{
            .entities = EntityManager.init(allocator, ctx),
            .allocator = allocator,
            .ctx = ctx,
            .active_movements = std.ArrayList(MovementState){},
            .active_texts = std.ArrayList(TextState){},
        };
    }

    pub fn start(self: *Self, action: actions.DemoAction, action_id: usize) !void {
        switch (action.data) {
            .spawn_entity => |data| {
                const id = try self.entities.spawnEnemy(data.entity_type, data.sprite_type, data.position);
                if (data.out_id) |out| {
                    out.* = id;
                }
            },
            .move_to => |data| {
                if (self.entities.find(data.target)) |entity| {
                    try self.active_movements.append(self.allocator, .{
                        .entity_id = entity.id,
                        .start_pos = entity.position,
                        .target_pos = data.position,
                        .ease_fn = data.ease,
                    });
                }
            },
            .shoot_at => |data| {
                const shooter = self.entities.find(data.shooter) orelse return;
                const target = self.entities.find(data.target) orelse return;

                const dx = target.position.x - shooter.position.x;
                const dy = target.position.y - shooter.position.y;
                const dist = @sqrt(dx * dx + dy * dy);

                if (dist > 0) {
                    const vel = engine.types.Vec2{
                        .x = (dx / dist) * data.projectile_speed,
                        .y = (dy / dist) * data.projectile_speed,
                    };
                    _ = try self.entities.spawnProjectile(shooter.position, vel, shooter.collision_layer);
                }
            },
            .set_animation => |data| {
                if (self.entities.find(data.target)) |entity| {
                    entity.sprite_id = data.sprite_id;
                }
            },
            .despawn_entity => |data| {
                if (self.entities.find(data.target)) |entity| {
                    entity.active = false;
                }
            },
            .wait => {},
            .path_follow => {},
            .show_text => |data| {
                try self.active_texts.append(self.allocator, .{
                    .action_id = action_id,
                    .text = data.text,
                    .position = data.position,
                    .y = null,
                    .font_size = data.font_size,
                    .color = data.color,
                    .centered = false,
                });
            },
            .show_text_centered => |data| {
                try self.active_texts.append(self.allocator, .{
                    .action_id = action_id,
                    .text = data.text,
                    .position = null,
                    .y = data.y,
                    .font_size = data.font_size,
                    .color = data.color,
                    .centered = true,
                });
            },
        }
    }

    pub fn stop(self: *Self, action: actions.DemoAction, action_id: usize) void {
        _ = action;

        // Remove text associated with this action
        var i: usize = 0;
        while (i < self.active_texts.items.len) {
            if (self.active_texts.items[i].action_id == action_id) {
                _ = self.active_texts.swapRemove(i);
                continue;
            }
            i += 1;
        }
    }

    pub fn update(self: *Self, action: actions.DemoAction, progress: f32) !void {
        _ = action;

        // Update all active movements with easing
        var i: usize = 0;
        while (i < self.active_movements.items.len) {
            var movement = &self.active_movements.items[i];

            if (self.entities.findById(movement.entity_id)) |entity| {
                // Apply easing function to progress
                const eased_t = movement.ease_fn(progress);

                // Interpolate position
                entity.position.x = movement.start_pos.x + (movement.target_pos.x - movement.start_pos.x) * eased_t;
                entity.position.y = movement.start_pos.y + (movement.target_pos.y - movement.start_pos.y) * eased_t;

                // Update angle based on direction
                const dx = movement.target_pos.x - movement.start_pos.x;
                const dy = movement.target_pos.y - movement.start_pos.y;
                if (dx != 0.0 or dy != 0.0) {
                    entity.angle = std.math.radiansToDegrees(std.math.atan2(dy, dx)) + 90.0;
                }

                // Remove movement when complete
                if (progress >= 1.0) {
                    entity.position = movement.target_pos;
                    entity.velocity = .{ .x = 0, .y = 0 };
                    _ = self.active_movements.swapRemove(i);
                    continue;
                }
            } else {
                // Entity no longer exists, remove movement
                _ = self.active_movements.swapRemove(i);
                continue;
            }

            i += 1;
        }
    }

    pub fn drawTexts(self: *Self, ctx: *Context) void {
        for (self.active_texts.items) |text_state| {
            if (text_state.centered) {
                ctx.renderer.text.drawTextCentered(
                    text_state.text,
                    text_state.y.?,
                    @floatFromInt(text_state.font_size),
                    text_state.color,
                );
            } else {
                ctx.renderer.text.drawText(
                    text_state.text,
                    text_state.position.?,
                    @floatFromInt(text_state.font_size),
                    text_state.color,
                );
            }
        }
    }

    pub fn reset(self: *Self) !void {
        self.entities.clear();
        self.active_movements.clearRetainingCapacity();
        self.active_texts.clearRetainingCapacity();
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit();
        self.active_movements.deinit(self.allocator);
        self.active_texts.deinit(self.allocator);
    }
};
