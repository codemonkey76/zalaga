const std = @import("std");
const engine = @import("engine");
const actions = @import("actions.zig");
const EntityManager = @import("entity_manager.zig").EntityManager;
const MovementSystem = @import("movement_system.zig").MovementSystem;

pub const ActionExecutor = struct {
    entities: EntityManager,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .entities = EntityManager.init(allocator),
        };
    }

    pub fn start(self: *Self, action: actions.DemoAction) !void {
        switch (action.data) {
            .spawn_entity => |spawn| {
                _ = try self.entities.spawn(spawn.entity_type, spawn.sprite_type, spawn.position);
            },
            else => {},
        }
    }

    pub fn update(self: *Self, action: actions.DemoAction, progress: f32) !void {
        switch (action.data) {
            .move_to => |move| {
                if (self.entities.find(move.target)) |entity| {
                    entity.target_pos = move.position;
                    entity.move_speed = move.speed;
                }
            },
            .shoot_at => |shoot| {
                // Only shoot once at start of action
                if (progress < 0.01) {
                    try executeShoot(&self.entities, shoot);
                }
            },
            .set_animation => |anim| {
                if (self.entities.find(anim.target)) |entity| {
                    entity.sprite_id = anim.sprite_id;
                }
            },
            .despawn_entity => |despawn| {
                if (self.entities.find(despawn.target)) |entity| {
                    entity.active = false;
                }
            },
            else => {},
        }
    }

    pub fn reset(self: *Self) !void {
        self.entities.reset();
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit();
    }

    fn executeShoot(entities: *EntityManager, shoot: anytype) !void {
        const shooter = entities.find(shoot.shooter) orelse return;

        var target_pos: engine.types.Vec2 = undefined;
        if (entities.find(shoot.target)) |target| {
            target_pos = target.position;
        } else {
            // Shoot upward if no target
            target_pos = shooter.position;
            target_pos.y = -0.1;
        }

        const dx = target_pos.x - shooter.position.x;
        const dy = target_pos.y - shooter.position.y;
        const dist = @sqrt(dx * dx + dy * dy);

        try entities.spawnProjectile(shooter.position, .{
            .x = (dx / dist) * shoot.projectile_speed,
            .y = (dy / dist) * shoot.projectile_speed,
        });
    }
};
