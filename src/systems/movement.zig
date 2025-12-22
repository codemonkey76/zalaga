const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;

const DISTANCE_THRESHOLD: f32 = 0.01;
const OFFSCREEN_MARGIN: f32 = 0.1;

pub const MovementSystem = struct {
    /// Update all entities
    pub fn update(entities: []Entity, dt: f32) void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            updateEntity(entity, dt);
        }
    }

    fn updateEntity(entity: *Entity, dt: f32) void {
        // Apply velocity
        entity.position.x += entity.velocity.x * dt;
        entity.position.y += entity.velocity.y * dt;

        // Move toward target if set
        if (entity.target_pos) |target| {
            updateTargetMovement(entity, target);
        }
        
        // Deactivate projectiles that go offscreen
        if (entity.type == .projectile and entity.isOffscreen(OFFSCREEN_MARGIN)) {
            entity.active = false;
        }
    }

    fn updateTargetMovement(entity: *Entity, target: engine.types.Vec2) void {
        const dir = normalizeDirection(entity.position, target);

        if (dir.dist < DISTANCE_THRESHOLD) {
            // Reached target
            entity.position = target;
            entity.target_pos = null;
            entity.velocity = .{ .x = 0, .y = 0 };
            
            // If moving to formation, switch to formation_idle and reset sprite
            if (entity.behavior == .move_to_target and entity.formation_pos != null) {
                entity.behavior = .formation_idle;
                entity.sprite_id = .idle_1;
                entity.angle = 0;
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
