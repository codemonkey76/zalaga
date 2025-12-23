const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const EntityType = @import("../entities/entity.zig").EntityType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const StageManager = @import("../gameplay/stage_manager.zig").StageManager;

// Animation parameters
const BREATHE_SPEED: f32 = 0.2; // Cycles per second
const BREATHE_AMOUNT: f32 = 0.20; // Max scale change (20%)
const SWAY_SPEED: f32 = 0.09; // Cycles per second
const SWAY_AMOUNT: f32 = 0.13; // Max horizontal movement (normalized coords)
const TRANSITION_TIME: f32 = 0.5; // Time to blend between modes (seconds)
const IDLE_ANIM_SPEED: f32 = 2.0;

/// Manages formation behavior for enemy groups
/// - In 'sway' mode: enemies gently move side to side
/// - In 'breathe' mode: formation expands/contracts from center
/// - Smoothly transitions between modes when stage state changes
pub const FormationSystem = struct {
    // Separate phase timers for each animation type
    // These run independently so animations don't reset when switching modes
    sway_time: f32,
    breathe_time: f32,

    // Current animation mode
    mode: Mode,

    // Transition progress (0 = just started, TRANSITION_TIME = fully settled)
    transition: f32,

    idle_anim_time: f32,

    const Self = @This();

    const Mode = enum {
        sway, // Gentle side-to-side motion (stage inactive)
        breathe, // Pulsing scale motion (stage active)
    };

    pub fn init() Self {
        return .{
            .sway_time = 0,
            .breathe_time = 0,
            .mode = .sway,
            .transition = TRANSITION_TIME, // Start fully settled in sway mode
            .idle_anim_time = 0,
        };
    }

    pub fn update(self: *Self, entities: []Entity, stage_mgr: *StageManager, dt: f32) void {
        // Update idle animation timer
        self.idle_anim_time += dt;

        // Check if we need to switch modes based on stage state
        const target_mode: Mode = if (stage_mgr.state == .active) .breathe else .sway;

        if (target_mode != self.mode) {
            // Start transition to new mode
            self.mode = target_mode;
            self.transition = 0;

            // Reset the incoming mode's timer to start at neutral position
            // This prevents jarring jumps when switching modes
            if (target_mode == .breathe) {
                self.breathe_time = (3.0 * std.math.pi / 2.0) / (BREATHE_SPEED * std.math.tau);
            } else {
                self.sway_time = 0; // sin(0) = 0 → offset = 0 (centered)
            }
        }

        // Advance transition timer
        self.transition += dt;

        // Calculate blend factor (0 to 1) with smoothstep easing
        var blend = @min(self.transition / TRANSITION_TIME, 1.0);
        blend = blend * blend * (3.0 - 2.0 * blend); // Smoothstep formula

        // Calculate amplitude for each animation based on mode and blend
        // - Active mode fades IN (0 → full amplitude)
        // - Inactive mode fades OUT (full amplitude → 0)
        const sway_amp: f32 = if (self.mode == .sway)
            SWAY_AMOUNT * blend
        else
            SWAY_AMOUNT * (1.0 - blend);

        const breathe_amp: f32 = if (self.mode == .breathe)
            BREATHE_AMOUNT * blend
        else
            BREATHE_AMOUNT * (1.0 - blend);

        // Keep both timers running so they're ready when needed
        self.sway_time += dt;
        self.breathe_time += dt;

        // Apply the blended motion to all formation entities
        self.applyFormationMotion(entities, sway_amp, breathe_amp);
    }

    /// Calculate where a formation position currently is (with sway/breathe applied)
    pub fn getCurrentFormationPosition(self: *const Self, base_pos: engine.types.Vec2) engine.types.Vec2 {
        const center_x: f32 = 0.5;
        const center_y: f32 = 0.29;

        // Calculate current sway and breathe
        const sway_phase = self.sway_time * SWAY_SPEED * std.math.tau;
        const breathe_phase = self.breathe_time * BREATHE_SPEED * std.math.tau;

        var blend = @min(self.transition / TRANSITION_TIME, 1.0);
        blend = blend * blend * (3.0 - 2.0 * blend);

        const sway_amp: f32 = if (self.mode == .sway)
            SWAY_AMOUNT * blend
        else
            SWAY_AMOUNT * (1.0 - blend);

        const breathe_amp: f32 = if (self.mode == .breathe)
            BREATHE_AMOUNT * blend
        else
            BREATHE_AMOUNT * (1.0 - blend);

        const sway_x: f32 = std.math.sin(sway_phase) * sway_amp;
        const scale = 1.0 + std.math.sin(breathe_phase) * breathe_amp;

        const off_x = base_pos.x - center_x;
        const off_y = base_pos.y - center_y;

        return .{
            .x = center_x + (off_x * scale) + sway_x,
            .y = center_y + (off_y * scale),
        };
    }
    /// Apply sway and breathe animations to formation entities
    fn applyFormationMotion(self: *Self, entities: []Entity, sway_amp: f32, breathe_amp: f32) void {
        // Formation center point (normalized coordinates)
        const center_x: f32 = 0.5;
        const center_y: f32 = 0.29;

        // Calculate sway offset (horizontal oscillation)
        const sway_phase = self.sway_time * SWAY_SPEED * std.math.tau;
        const sway_x: f32 = std.math.sin(sway_phase) * sway_amp;

        // Calculate breathe scale (radial expansion/contraction)
        // Use (sin + 1) / 2 to map from [-1, 1] to [0, 1]
        // This makes scale go from 1.0 (original) to 1.0 + breathe_amp (expanded)
        const breathe_phase = self.breathe_time * BREATHE_SPEED * std.math.tau;
        const breathe_factor = (std.math.sin(breathe_phase) + 1.0) / 2.0; // 0 to 1
        const scale = 1.0 + (breathe_factor * breathe_amp);

        const frame_index = @as(usize, @intFromFloat(self.idle_anim_time * IDLE_ANIM_SPEED)) % 2;
        const idle_frame: SpriteId = if (frame_index == 0) .idle_1 else .idle_2;

        for (entities) |*entity| {
            if (!entity.active) continue;

            // ONLY apply formation motion to entities in formation_idle state
            // Skip entities that are still transitioning
            if (entity.behavior != .formation_idle) continue;

            entity.sprite_id = idle_frame;

            const base = entity.formation_pos orelse continue;

            // Calculate offset from formation center
            const off_x = base.x - center_x;
            const off_y = base.y - center_y;

            // Apply both animations:
            entity.position.x = center_x + (off_x * scale) + sway_x;
            entity.position.y = center_y + (off_y * scale);
        }
    }
};
