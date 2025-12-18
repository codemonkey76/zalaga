const std = @import("std");
const engine = @import("engine");

pub const EntityId = u32;

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
    
    // Collision
    collision_radius: f32,
    collision_layer: CollisionLayer,
    collision_enabled: bool,
    
    // Gameplay
    health: i32,
    
    // Movement state
    target_pos: ?engine.types.Vec2,
    move_speed: f32,
    path_index: usize,
    path_t: f32,
    
    const Self = @This();
    
    pub fn isMoving(self: Self) bool {
        return self.target_pos != null or self.velocity.x != 0 or self.velocity.y != 0;
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
