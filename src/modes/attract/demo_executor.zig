const std = @import("std");
const engine = @import("engine");
const actions = @import("demo_actions.zig");
const EntityManager = @import("../../entities/entity_manager.zig").EntityManager;
const MovementSystem = @import("../../systems/movement.zig").MovementSystem;

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
            .spawn_entity => |data| {
                const id = try self.entities.spawnEnemy(data.entity_type, data.sprite_type, data.position);
                if (data.out_id) |out| {
                    out.* = id;
                }
            },
            .move_to => |data| {
                if (self.entities.find(data.target)) |entity| {
                    entity.target_pos = data.position;
                    entity.move_speed = data.speed;
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
        }
    }

    pub fn update(self: *Self, _: actions.DemoAction, _: f32) !void {
        // Actions are instant, movement is handled in attract mode's update loop
        _ = self;
    }

    pub fn reset(self: *Self) !void {
        self.entities.clear();
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit();
    }
};
