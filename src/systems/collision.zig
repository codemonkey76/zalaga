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

                // Use engine's collision detection
                if (engine.collision.checkCollision(
                    entity_a.position,
                    entity_a.collision_bounds,
                    entity_b.position,
                    entity_b.collision_bounds,
                )) {
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

    /// Check if specific entity collides with any in layer
    pub fn checkEntityVsLayer(
        self: *Self,
        entity: *const Entity,
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

            if (engine.collision.checkCollision(
                entity.position,
                entity.collision_bounds,
                other.position,
                other.collision_bounds,
            )) {
                return other.id;
            }
        }

        return null;
    }
};
