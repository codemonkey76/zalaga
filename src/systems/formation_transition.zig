const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const Context = @import("../mod.zig").Context;
const StageManager = @import("../gameplay/stage/stage_manager.zig").StageManager;
const FormationSystem = @import("./formation.zig").FormationSystem;
const c = @import("../constants.zig");

/// System for smoothly transitioning enemies from path end to formation position
pub const FormationTransitionSystem = struct {
    const Self = @This();

    pub fn init(_: std.mem.Allocator) Self {
        return .{};
    }

    pub fn deinit(_: *Self) void {}
    pub fn update(_: *Self, entities: []Entity, stage_mgr: *StageManager, formation_system: *const FormationSystem, dt: f32) void {
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .formation_transition) continue;

            const start_pos = entity.formation_transition_start orelse continue;
            const base_target = entity.target_pos orelse continue;

            // Calculate the CURRENT formation position with sway/breathe applied
            const target_pos = formation_system.getCurrentFormationPosition(base_target);

            // Advance transition
            entity.formation_transition_t += dt / c.formation.TRANSITION_TIME;

            if (entity.formation_transition_t >= 1.0) {
                // Transition complete
                entity.behavior = .formation_idle;
                entity.sprite_id = .idle_1;
                entity.angle = 0;
                stage_mgr.notifyEnemyInFormation();
            } else {
                // Smooth interpolation
                const t = entity.formation_transition_t;
                const eased_t = 1.0 - (1.0 - t) * (1.0 - t);

                entity.position.x = start_pos.x + (target_pos.x - start_pos.x) * eased_t;
                entity.position.y = start_pos.y + (target_pos.y - start_pos.y) * eased_t;

                // Normalize the starting angle to [-180, 180] range for shortest path interpolation
                var normalized_start = entity.formation_transition_start_angle;
                if (normalized_start > 180) {
                    normalized_start -= 360;
                }

                // Interpolate the normalized angle to 0
                entity.angle = normalized_start * (1.0 - eased_t);
            }
        }
    }
};
