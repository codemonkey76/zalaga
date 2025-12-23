const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const EntityType = @import("../entities/entity.zig").EntityType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;

const BREATHE_SPEED: f32 = 0.2;
const BREATHE_AMOUNT: f32 = 0.20;
const IDLE_ANIM_SPEED: f32 = 4.0;

pub const FormationSystem = struct {
    time: f32,
    idle_anim_time: f32,

    const Self = @This();

    pub fn init() Self {
        return .{
            .time = 0,
            .idle_anim_time = 0,
        };
    }

    pub fn update(self: *Self, entities: []Entity, dt: f32) void {
        self.time += dt;
        self.idle_anim_time += dt;

        // Calculate breathing scale factor using sine wave
        const breathe_cycle = std.math.sin(self.time * BREATHE_SPEED * 2.0 * std.math.pi);
        const scale = 1.0 + (breathe_cycle * BREATHE_AMOUNT);

        // Determine which idle frame to show (alternate between idle_1 and idle_2)
        const idle_frame_index = @as(usize, @intFromFloat(self.idle_anim_time * IDLE_ANIM_SPEED)) % 2;
        const idle_sprite: SpriteId = if (idle_frame_index == 0) .idle_1 else .idle_2;

        // Apply breathing to all entities in formation
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .formation_idle) continue;
            if (entity.formation_pos == null) continue;

            const base_pos = entity.formation_pos.?;

            // Calculate offset from center (0.5, 0.3)
            const center_x: f32 = 0.5;
            const center_y: f32 = 0.3;
            const offset_x = base_pos.x - center_x;
            const offset_y = base_pos.y - center_y;

            // Apply breathing scale
            entity.position.x = center_x + (offset_x * scale);
            entity.position.y = center_y + (offset_y * scale);

            // Update idle animation (only for enemies that have idle_2)
            if (entity.type == .boss or entity.type == .goei or entity.type == .zako) {
                entity.sprite_id = idle_sprite;
            }
        }
    }
};
