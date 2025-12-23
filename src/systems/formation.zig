const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const EntityType = @import("../entities/entity.zig").EntityType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const StageManager = @import("../gameplay/stage_manager.zig").StageManager;

const BREATHE_SPEED: f32 = 0.2;
const BREATHE_AMOUNT: f32 = 0.20;
const SWAY_SPEED: f32 = 0.2;
const SWAY_AMOUNT: f32 = 0.15;

const TRANSITION_TIME: f32 = 0.35; // seconds

pub const FormationSystem = struct {
    idle_anim_time: f32,

    // separate phase timers
    sway_time: f32,
    breathe_time: f32,

    // mode + transition
    mode: Mode,
    transition: f32,

    const Self = @This();
    const Mode = enum { sway, breathe };

    pub fn init() Self {
        return .{
            .idle_anim_time = 0,
            .sway_time = 0,
            .breathe_time = 0,
            .mode = .sway,
            .transition = TRANSITION_TIME, // start "settled"
        };
    }

    pub fn update(self: *Self, entities: []Entity, stage_mgr: *StageManager, dt: f32) void {
        self.updateIdle(entities, dt);

        const target: Mode = if (stage_mgr.state == .active) .breathe else .sway;

        if (target != self.mode) {
            self.mode = target;
            self.transition = 0;

            // optional: start the incoming mode at neutral
            if (target == .breathe) self.breathe_time = 0; // sin(0)=0 => scale=1
            if (target == .sway) self.sway_time = 0; // sin(0)=0 => sway=0
        }

        self.transition += dt;

        // 0..1 blend, eased
        var t = self.transition / TRANSITION_TIME;
        if (t > 1) t = 1;
        const blend = t * t * (3.0 - 2.0 * t); // smoothstep

        // crossfade amplitudes depending on target mode
        const sway_amp: f32 = if (self.mode == .sway) SWAY_AMOUNT * blend else SWAY_AMOUNT * (1.0 - blend);
        const breathe_amp: f32 = if (self.mode == .breathe) BREATHE_AMOUNT * blend else BREATHE_AMOUNT * (1.0 - blend);

        // advance both timers (or just the ones you care about)
        self.sway_time += dt;
        self.breathe_time += dt;

        self.applyFormationMotion(entities, sway_amp, breathe_amp);
    }

    fn applyFormationMotion(self: *Self, entities: []Entity, sway_amp: f32, breathe_amp: f32) void {
        const sway_phase = self.sway_time * SWAY_SPEED * std.math.tau;
        const sway_x: f32 = std.math.sin(sway_phase) * sway_amp;

        const breathe_phase = self.breathe_time * BREATHE_SPEED * std.math.tau;
        const scale = 1.0 + std.math.sin(breathe_phase) * breathe_amp;

        const center_x: f32 = 0.5;
        const center_y: f32 = 0.3;

        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.behavior != .formation_idle) continue;
            const base = entity.formation_pos orelse continue;

            const off_x = base.x - center_x;
            const off_y = base.y - center_y;

            // breathing (around center) + sway (additive)
            entity.position.x = center_x + (off_x * scale) + sway_x;
            entity.position.y = center_y + (off_y * scale);
        }
    }

    fn updateIdle(self: *Self, entities: []Entity, dt: f32) void {
        // your existing idle code...
        _ = self;
        _ = entities;
        _ = dt;
    }
};
