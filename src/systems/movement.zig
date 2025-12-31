const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const StageManager = @import("../gameplay/stage/stage_manager.zig").StageManager;
const c = @import("../constants.zig");

pub const MovementSystem = struct {
    /// Update all entities
    pub fn update(entities: []Entity, stage_mgr: *StageManager, dt: f32) void {
        for (entities) |*entity| {
            if (!entity.active) continue;

            if (entity.behavior == .formation_transition) continue;
            updateEntity(entity, stage_mgr, dt);
        }
    }

    fn updateEntity(entity: *Entity, stage_mgr: *StageManager, dt: f32) void {
        // Apply velocity
        entity.position.x += entity.velocity.x * dt;
        entity.position.y += entity.velocity.y * dt;

        // Move toward target if set
        if (entity.target_pos) |target| {
            updateTargetMovement(entity, stage_mgr, target);
        }

        // Deactivate projectiles that go offscreen
        if (entity.type == .projectile and entity.isOffscreen(c.movement.OFFSCREEN_MARGIN)) {
            entity.active = false;
        }
    }

    fn updateTargetMovement(entity: *Entity, stage_mgr: *StageManager, target: engine.types.Vec2) void {
        const dir = normalizeDirection(entity.position, target);

        if (dir.dist < c.movement.DISTANCE_THRESHOLD) {
            // Reached target
            entity.position = target;
            entity.target_pos = null;
            entity.velocity = .{ .x = 0, .y = 0 };

            // If moving to formation, switch to formation_idle and reset sprite
            if (entity.behavior == .move_to_target and entity.formation_pos != null) {
                entity.behavior = .formation_idle;
                entity.sprite_id = .idle_1;
                entity.angle = 0;

                stage_mgr.notifyEnemyInFormation();
            }
        } else {
            // Move toward target
            entity.velocity.x = (dir.dx / dir.dist) * entity.move_speed;
            entity.velocity.y = (dir.dy / dir.dist) * entity.move_speed;
            entity.angle = angleFromDirection(dir.dx, dir.dy);
        }
    }

    fn normalizeDirection(from: engine.types.Vec2, to: engine.types.Vec2) struct { dx: f32, dy: f32, dist: f32 } {
        const dx = to.x - from.x;
        const dy = to.y - from.y;
        const dist = @sqrt(dx * dx + dy * dy);

        return .{
            .dx = dx,
            .dy = dy,
            .dist = dist,
        };
    }

    fn angleFromDirection(dx: f32, dy: f32) f32 {
        return std.math.radiansToDegrees(std.math.atan2(dy, dx)) + 90.0;
    }
};
