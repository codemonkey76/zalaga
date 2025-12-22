const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const MovementBehavior = @import("../entities/entity.zig").MovementBehavior;
const Context = @import("../mod.zig").Context;
const arcade_lib = @import("arcade_lib");
const PathCache = @import("path_cache.zig").PathCache;

pub const PathFollowingSystem = struct {
    path_cache: PathCache,
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .path_cache = PathCache.init(allocator),
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.path_cache.deinit();
    }
    
    pub fn update(self: *Self, entities: []Entity, ctx: *Context, dt: f32) !void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .path_following) continue;
            
            const path_asset = entity.current_path orelse continue;
            
            // Get cached PathDefinition
            const path_def = self.path_cache.getPathDefinition(ctx, path_asset) catch |err| {
                std.debug.print("Error getting path definition for {s}: {any}\n", .{ @tagName(path_asset), err });
                continue;
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
            
            // Calculate angle based on movement direction (look ahead)
            if (entity.path_t < 0.99) {
                const next_arcade_pos = path_def.getPosition(entity.path_t + 0.01);
                const next_pos = engine.types.Vec2{
                    .x = next_arcade_pos.x,
                    .y = next_arcade_pos.y,
                };
                
                // Direction vector pointing where we're going
                const dx = next_pos.x - entity.position.x;
                const dy = next_pos.y - entity.position.y;
                
                if (dx != 0 or dy != 0) {
                    // Reverse direction - enemies face opposite of travel initially
                    entity.angle = std.math.radiansToDegrees(std.math.atan2(-dy, -dx)) + 90.0;
                }
            }
        }
    }
};
