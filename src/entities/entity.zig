const std = @import("std");
const engine = @import("engine");
const PathAsset = @import("../assets/path_asset.zig").PathAsset;

pub const EntityId = u32;

/// Entity movement behavior
pub const MovementBehavior = enum {
    idle,
    path_following,
    formation_transition,
    move_to_target,
    formation_idle,
};

/// Entity type classification
pub const EntityType = enum {
    player,
    boss,
    goei,
    zako,
    projectile,
};

/// Collision layers for filtering
pub const CollisionLayer = enum {
    player,
    player_projectile,
    enemy,
    enemy_projectile,
};

/// Base entity - all game objects are entities
pub const Entity = struct {
    id: EntityId,
    type: EntityType,
    active: bool,

    // Transform
    position: engine.types.Vec2,
    velocity: engine.types.Vec2,
    angle: f32,

    // Rendering
    sprite_type: ?SpriteType,
    sprite_id: ?SpriteId,
    bullet_sprite_id: ?BulletSpriteId,

    // Collision
    collision_radius: f32,
    collision_layer: CollisionLayer,
    collision_enabled: bool,

    // Gameplay
    health: i32,

    // Movement state
    behavior: MovementBehavior,
    current_path: ?PathAsset,
    formation_pos: ?engine.types.Vec2,
    target_pos: ?engine.types.Vec2,
    move_speed: f32,
    path_t: f32,

    formation_transition_start: ?engine.types.Vec2 = null,
    formation_transition_t: f32 = 0,
    formation_transition_start_angle: f32 = 0,

    const Self = @This();

    pub fn isMoving(self: Self) bool {
        return self.behavior == .path_following or
            self.behavior == .formation_transition or
            self.behavior == .move_to_target;
    }

    pub fn isOffscreen(self: Self, margin: f32) bool {
        return self.position.x < -margin or
            self.position.x > 1.0 + margin or
            self.position.y < -margin or
            self.position.y > 1.0 + margin;
    }
};

const SpriteType = @import("../assets/sprites.zig").SpriteType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const BulletSpriteId = @import("../assets/sprites.zig").BulletSpriteId;
