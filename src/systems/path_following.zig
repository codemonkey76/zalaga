const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const MovementBehavior = @import("../entities/entity.zig").MovementBehavior;
const Context = @import("../mod.zig").Context;
const arcade_lib = @import("arcade_lib");

pub const PathFollowingSystem = struct {
    pub fn update(entities: []Entity, ctx: *Context, dt: f32) void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .path_following) continue;
            
            const path_asset = entity.current_path orelse continue;
            
            // Load the path (cached by asset manager)
            const path = ctx.assets.getPath(path_asset) orelse {
                std.debug.print("Warning: Path {s} not loaded for entity {d}\n", .{
                    @tagName(path_asset),
                    entity.id,
                });
                continue;
            };
            
            // Manually build Vec2 array from anchors (workaround for type mismatch)
            var points = std.ArrayList(arcade_lib.Vec2){};
            defer points.deinit(ctx.allocator);
            
            for (path.anchors) |anchor| {
                points.append(ctx.allocator, .{ .x = anchor.pos.x, .y = anchor.pos.y }) catch continue;
            }
            
            // Convert points to control points
            const control_points = arcade_lib.PathDefinition.fromPoints(
                ctx.allocator,
                points.items,
            ) catch |err| {
                std.debug.print("Error converting path {s}: {any}\n", .{ @tagName(path_asset), err });
                continue;
            };
            defer ctx.allocator.free(control_points);
            
            const path_def = arcade_lib.PathDefinition{
                .control_points = control_points,
            };
            
            // Advance along path
            entity.path_t += entity.move_speed * dt;
            
            // Check if path complete
            if (entity.path_t >= 1.0) {
                // Path complete - transition to next behavior
                if (entity.formation_pos) |form_pos| {
                    // Move to formation position
                    entity.behavior = .move_to_target;
                    entity.target_pos = form_pos;
                    entity.path_t = 0;
                } else {
                    // No formation position, go idle (will despawn if offscreen)
                    entity.behavior = .idle;
                }
                continue;
            }
            
            // Get position along path
            const arcade_pos = path_def.getPosition(entity.path_t);
            entity.position = engine.types.Vec2{
                .x = arcade_pos.x,
                .y = arcade_pos.y,
            };
            
            // Calculate angle based on movement direction
            if (entity.path_t > 0.01) {
                const prev_arcade_pos = path_def.getPosition(entity.path_t - 0.01);
                const prev_pos = engine.types.Vec2{
                    .x = prev_arcade_pos.x,
                    .y = prev_arcade_pos.y,
                };
                
                const dx = entity.position.x - prev_pos.x;
                const dy = entity.position.y - prev_pos.y;
                
                if (dx != 0 or dy != 0) {
                    entity.angle = std.math.atan2(dy, dx) * 180.0 / std.math.pi;
                }
            }
        }
    }
};
