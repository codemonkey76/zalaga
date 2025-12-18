const std = @import("std");
const engine = @import("engine");
const EntityRef = @import("../../entities/entity_manager.zig").EntityRef;
const EntityType = @import("../../entities/entity_manager.zig").EntityType;
const SpriteType = @import("../../assets/sprites.zig").SpriteType;
const SpriteId = @import("../../assets/sprites.zig").SpriteId;

pub const ActionType = enum {
    move_to,
    shoot_at,
    spawn_entity,
    wait,
    set_animation,
    despawn_entity,
    path_follow,
    show_text,
    show_text_centered,
};

// Easing function type from engine
pub const EasingFn = *const fn (f32) f32;

pub const ActionData = union(ActionType) {
    move_to: struct {
        target: EntityRef,
        position: engine.types.Vec2,
        duration: f32,
        ease: EasingFn = engine.timeline.easing.linear,
    },
    shoot_at: struct {
        shooter: EntityRef,
        target: EntityRef,
        projectile_speed: f32,
    },
    spawn_entity: struct {
        entity_type: EntityType,
        sprite_type: SpriteType,
        position: engine.types.Vec2,
        out_id: ?*u32 = null,
    },
    wait: struct {},
    set_animation: struct {
        target: EntityRef,
        sprite_id: SpriteId,
    },
    despawn_entity: struct {
        target: EntityRef,
    },
    path_follow: struct {
        target: EntityRef,
        path: []const engine.types.Vec2,
    },
    show_text: struct {
        text: []const u8,
        position: engine.types.Vec2,
        font_size: u32,
        color: engine.types.Color,
    },
    show_text_centered: struct {
        text: []const u8,
        y: f32,
        font_size: u32,
        color: engine.types.Color,
    },
};

// Action that matches engine's Timeline expectations (has .base field)
pub const DemoAction = struct {
    base: engine.timeline.ActionBase,
    data: ActionData,
};
