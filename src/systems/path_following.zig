const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const MovementBehavior = @import("../entities/entity.zig").MovementBehavior;
const Context = @import("../mod.zig").Context;
const arcade_lib = @import("arcade_lib");
const PathDefinition = arcade_lib.PathDefinition;
const PathAsset = @import("../assets/path_asset.zig").PathAsset;

/// System responsible for moving entities along predefined paths.
///
/// Entities following paths use a normalized parameter `t` (0.0 to 1.0) to track
/// their progress. The system uses arc-length parameterization to maintain roughly
/// constant visual speed regardless of how the path is mathematically defined.
pub const PathFollowingSystem = struct {
    const Self = @This();

    // Arc-length parameterization constants
    const DERIVATIVE_SAMPLE_DELTA: f32 = 0.01; // Distance in t-space to sample for derivative
    const MIN_DERIVATIVE_THRESHOLD: f32 = 0.01; // Minimum derivative to prevent division by near-zero
    const MAX_SPEED_MULTIPLIER: f32 = 5.0; // Cap on how much we can speed up t advancement

    pub fn init(_: std.mem.Allocator) Self {
        return .{};
    }

    pub fn deinit(_: *Self) void {}

    pub fn update(_: *Self, entities: []Entity, ctx: *Context, dt: f32) !void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .path_following) continue;

            const path_asset = entity.current_path orelse continue;

            // Get path from asset manager (already cached there)
            const path = ctx.assets.getPath(path_asset) orelse {
                std.debug.print("Path not found: {s}\n", .{@tagName(path_asset)});
                continue;
            };

            try updateEntityOnPath(entity, &path.definition, dt);
        }
    }

    /// Update a single entity following a path
    fn updateEntityOnPath(entity: *Entity, path_def: *const PathDefinition, dt: f32) !void {
        // Sample path at current position
        const current_pos = path_def.getPosition(entity.path_t);
        entity.position = engine.types.Vec2{
            .x = current_pos.x,
            .y = current_pos.y,
        };

        // Calculate how much to advance along the path
        const path_delta = calculatePathAdvancement(path_def, entity.path_t, entity.move_speed, dt);
        entity.path_t += path_delta;

        // Check if we've reached the end of the path
        if (entity.path_t >= 1.0) {
            handlePathCompletion(entity);
            return;
        }

        // Update entity rotation to face the direction of movement
        updateEntityRotation(entity, path_def);
    }

    /// Calculate how much to advance the path parameter t, using arc-length
    /// parameterization to maintain roughly constant visual speed
    fn calculatePathAdvancement(
        path_def: *const PathDefinition,
        current_t: f32,
        move_speed: f32,
        dt: f32,
    ) f32 {
        // Sample a point slightly ahead to estimate the curve's derivative
        const next_t = @min(current_t + DERIVATIVE_SAMPLE_DELTA, 1.0);
        const current_pos = path_def.getPosition(current_t);
        const next_pos = path_def.getPosition(next_t);

        // Calculate the arc length derivative (how much world-space distance per unit of t)
        const dx = next_pos.x - current_pos.x;
        const dy = next_pos.y - current_pos.y;
        const arc_length_derivative = @sqrt(dx * dx + dy * dy) / DERIVATIVE_SAMPLE_DELTA;

        // Adjust dt to compensate for varying curve speed
        // If the curve is "moving fast" (high derivative), we slow down the t advancement
        // If the curve is "moving slow" (low derivative), we speed up the t advancement
        const adjusted_dt = if (arc_length_derivative > MIN_DERIVATIVE_THRESHOLD)
            @min(dt / arc_length_derivative, dt * MAX_SPEED_MULTIPLIER)
        else
            dt;

        return move_speed * adjusted_dt;
    }

    /// Handle what happens when an entity reaches the end of its path
    fn handlePathCompletion(entity: *Entity) void {
        if (entity.formation_pos) |form_pos| {
            // Store the path end position for smooth transition
            entity.formation_transition_start = entity.position;
            entity.formation_transition_start_angle = entity.angle;
            entity.formation_transition_t = 0;
            entity.behavior = .formation_transition;
            entity.target_pos = form_pos;
            entity.path_t = 0;
        } else {
            // No formation position - become idle (will be cleaned up if offscreen)
            entity.behavior = .idle;
        }
    }

    /// Update entity's rotation angle to face the direction of movement
    fn updateEntityRotation(entity: *Entity, path_def: *const PathDefinition) void {
        if (entity.path_t >= 0.99) return; // Near the end, don't update rotation

        // Look slightly ahead to determine movement direction
        const lookahead_t = entity.path_t + 0.01;
        const next_pos = path_def.getPosition(lookahead_t);

        const dir_x = next_pos.x - entity.position.x;
        const dir_y = next_pos.y - entity.position.y;

        // Only update angle if there's actual movement
        if (dir_x != 0 or dir_y != 0) {
            const angle_rad = std.math.atan2(dir_y, dir_x);
            const angle_deg = std.math.radiansToDegrees(angle_rad);

            // Offset by 90 degrees so sprite "up" direction points along the path
            entity.angle = @mod(angle_deg + 90.0, 360.0);
        }
    }
};
