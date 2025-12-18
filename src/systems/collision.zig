const std = @import("std");
const engine = @import("engine");
const Entity = @import("../entities/entity.zig").Entity;
const EntityId = @import("../entities/entity.zig").EntityId;
const CollisionLayer = @import("../entities/entity.zig").CollisionLayer;

pub const CollisionPair = struct {
    entity_a: EntityId,
    entity_b: EntityId,
    layer_a: CollisionLayer,
    layer_b: CollisionLayer,
};

pub const CollisionSystem = struct {
    allocator: std.mem.Allocator,
    collisions: std.ArrayList(CollisionPair),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .collisions = std.ArrayList(CollisionPair){},
        };
    }

    pub fn deinit(self: *Self) void {
        self.collisions.deinit(self.allocator);
    }

    /// Check all entity collisions and store results
    /// Only checks meaningful collisions:
    /// - Player vs Enemy
    /// - Player vs Enemy Projectile
    /// - Enemy vs Player Projectile
    pub fn checkCollisions(self: *Self, entities: []Entity) !void {
        self.collisions.clearRetainingCapacity();

        // Broad phase: check all entity pairs
        for (entities, 0..) |*entity_a, i| {
            if (!entity_a.active or !entity_a.collision_enabled) continue;

            for (entities[i + 1 ..]) |*entity_b| {
                if (!entity_b.active or !entity_b.collision_enabled) continue;

                // Only check meaningful collision pairs
                if (!shouldCheckCollision(entity_a.collision_layer, entity_b.collision_layer)) {
                    continue;
                }

                // Narrow phase: circle collision
                if (self.checkCircleCollision(entity_a, entity_b)) {
                    try self.collisions.append(self.allocator, .{
                        .entity_a = entity_a.id,
                        .entity_b = entity_b.id,
                        .layer_a = entity_a.collision_layer,
                        .layer_b = entity_b.collision_layer,
                    });
                }
            }
        }
    }

    /// Determine if two collision layers should interact
    fn shouldCheckCollision(layer_a: CollisionLayer, layer_b: CollisionLayer) bool {
        return switch (layer_a) {
            .player => layer_b == .enemy or layer_b == .enemy_projectile,
            .enemy => layer_b == .player or layer_b == .player_projectile,
            .player_projectile => layer_b == .enemy,
            .enemy_projectile => layer_b == .player,
        };
    }

    /// Get all collisions from last check
    pub fn getCollisions(self: *Self) []CollisionPair {
        return self.collisions.items;
    }

    /// Check if two entities overlap (circle collision)
    fn checkCircleCollision(self: *Self, entity_a: *Entity, entity_b: *Entity) bool {
        _ = self;
        
        const dx = entity_a.position.x - entity_b.position.x;
        const dy = entity_a.position.y - entity_b.position.y;
        const distance_sq = dx * dx + dy * dy;

        // Convert radius from pixels to normalized coordinates (assuming 224x288 virtual res)
        const scale = 1.0 / 224.0; // Normalize to screen space
        const radius_a = entity_a.collision_radius * scale;
        const radius_b = entity_b.collision_radius * scale;
        const combined_radius = radius_a + radius_b;

        return distance_sq < (combined_radius * combined_radius);
    }

    /// Check if specific entity collides with any in layer
    pub fn checkEntityVsLayer(
        self: *Self,
        entity: *Entity,
        entities: []Entity,
        target_layer: CollisionLayer,
    ) ?EntityId {
        _ = self;
        
        if (!entity.collision_enabled) return null;
        if (!shouldCheckCollision(entity.collision_layer, target_layer)) return null;

        for (entities) |*other| {
            if (!other.active or !other.collision_enabled) continue;
            if (other.collision_layer != target_layer) continue;
            if (other.id == entity.id) continue;

            const dx = entity.position.x - other.position.x;
            const dy = entity.position.y - other.position.y;
            const distance_sq = dx * dx + dy * dy;

            const scale = 1.0 / 224.0;
            const radius_a = entity.collision_radius * scale;
            const radius_b = other.collision_radius * scale;
            const combined_radius = radius_a + radius_b;

            if (distance_sq < (combined_radius * combined_radius)) {
                return other.id;
            }
        }

        return null;
    }
};
