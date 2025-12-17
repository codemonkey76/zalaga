const std = @import("std");
const engine = @import("engine");
const DemoEntity = @import("entity_manager.zig").DemoEntity;
const Projectile = @import("entity_manager.zig").Projectile;

const DISTANCE_THRESHOLD: f32 = 0.01;
const OFFSCREEN_MARGIN: f32 = 0.1;

pub const MovementSystem = struct {
    pub fn updateEntities(entities: []DemoEntity, dt: f32) void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            updateEntity(entity, dt);
        }
    }

    pub fn updateProjectiles(projectiles: []Projectile, dt: f32) void {
        for (projectiles) |*proj| {
            if (!proj.active) continue;
            updateProjectile(proj, dt);
        }
    }

    fn updateEntity(entity: *DemoEntity, dt: f32) void {
        // Apply velocity
        entity.position.x += entity.velocity.x * dt;
        entity.position.y += entity.velocity.y * dt;

        // Move toward target if set
        if (entity.target_pos) |target| {
            updateTargetMovement(entity, target);
        }
    }

    fn updateTargetMovement(entity: *DemoEntity, target: engine.types.Vec2) void {
        const dir = normalizeDirection(entity.position, target);

        if (dir.dist < DISTANCE_THRESHOLD) {
            // Reached target
            entity.position = target;
            entity.target_pos = null;
            entity.velocity = .{ .x = 0, .y = 0 };
        } else {
            // Move toward target
            entity.velocity.x = (dir.dx / dir.dist) * entity.move_speed;
            entity.velocity.y = (dir.dy / dir.dist) * entity.move_speed;
            entity.angle = angleFromDirection(dir.dx, dir.dy);
        }
    }

    fn updateProjectile(proj: *Projectile, dt: f32) void {
        proj.position.x += proj.velocity.x * dt;
        proj.position.y += proj.velocity.y * dt;

        // Deactivate if of-screen
        if (proj.position.y < -OFFSCREEN_MARGIN or proj.position.y > 1.0 + OFFSCREEN_MARGIN) {
            proj.active = false;
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
