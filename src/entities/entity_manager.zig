const std = @import("std");
const engine = @import("engine");

const Entity = @import("entity.zig").Entity;
const EntityId = @import("entity.zig").EntityId;
const SpriteType = @import("../assets/sprites.zig").SpriteType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;
const BulletSpriteId = @import("../assets/sprites.zig").BulletSpriteId;

// Re-export types from entity.zig for convenience
pub const EntityType = @import("entity.zig").EntityType;
pub const CollisionLayer = @import("entity.zig").CollisionLayer;

pub const EntityRef = union(enum) {
    id: EntityId,
    tag: EntityType,
};

pub const EntityManager = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(Entity),
    next_entity_id: EntityId,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .entities = std.ArrayList(Entity){},
            .next_entity_id = 1,
        };
    }

    /// Spawn a player entity
    pub fn spawnPlayer(self: *Self, position: engine.types.Vec2) !EntityId {
        return try self.spawn(.{
            .id = self.next_entity_id,
            .type = .player,
            .active = true,
            .position = position,
            .velocity = .{ .x = 0, .y = 0 },
            .angle = 0,
            .sprite_type = .player,
            .sprite_id = .idle_1,
            .bullet_sprite_id = null,
            .collision_radius = 8.0,
            .collision_layer = .player,
            .collision_enabled = true,
            .health = 1,
            .behavior = .idle,
            .current_path = null,
            .formation_pos = null,
            .target_pos = null,
            .move_speed = 0,
            .path_t = 0,
        });
    }

    /// Spawn an enemy entity
    pub fn spawnEnemy(
        self: *Self,
        entity_type: EntityType,
        sprite_type: SpriteType,
        position: engine.types.Vec2,
    ) !EntityId {
        return try self.spawn(.{
            .id = self.next_entity_id,
            .type = entity_type,
            .active = true,
            .position = position,
            .velocity = .{ .x = 0, .y = 0 },
            .angle = 0,
            .sprite_type = sprite_type,
            .sprite_id = .idle_1,
            .bullet_sprite_id = null,
            .collision_radius = 8.0,
            .collision_layer = .enemy,
            .collision_enabled = true,
            .health = 1,
            .behavior = .idle,
            .current_path = null,
            .formation_pos = null,
            .target_pos = null,
            .move_speed = 0.3,
            .path_t = 0,
        });
    }

    /// Spawn a projectile entity
    pub fn spawnProjectile(
        self: *Self,
        position: engine.types.Vec2,
        velocity: engine.types.Vec2,
        owner_layer: CollisionLayer,
    ) !EntityId {
        const projectile_layer: CollisionLayer = switch (owner_layer) {
            .player => .player_projectile,
            .enemy => .enemy_projectile,
            else => .player_projectile,
        };

        const bullet_sprite: BulletSpriteId = switch (owner_layer) {
            .player => .player_bullet,
            .enemy => .enemy_bullet,
            else => .player_bullet,
        };

        return try self.spawn(.{
            .id = self.next_entity_id,
            .type = .projectile,
            .active = true,
            .position = position,
            .velocity = velocity,
            .angle = 0,
            .sprite_type = null,
            .sprite_id = null,
            .bullet_sprite_id = bullet_sprite,
            .collision_radius = 2.0,
            .collision_layer = projectile_layer,
            .collision_enabled = true,
            .health = 1,
            .behavior = .idle,
            .current_path = null,
            .formation_pos = null,
            .target_pos = null,
            .move_speed = 0,
            .path_t = 0,
        });
    }

    /// Internal spawn function
    fn spawn(self: *Self, entity: Entity) !EntityId {
        const id = self.next_entity_id;
        self.next_entity_id += 1;
        try self.entities.append(self.allocator, entity);
        return id;
    }

    /// Get entity by ID
    pub fn get(self: *Self, id: EntityId) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.id == id and entity.active) {
                return entity;
            }
        }
        return null;
    }

    /// Find entity by ID (even if inactive - for internal use)
    pub fn findById(self: *Self, id: EntityId) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.id == id) {
                return entity;
            }
        }
        return null;
    }

    /// Find entity by reference (id or tag)
    pub fn find(self: *Self, ref: EntityRef) ?*Entity {
        return switch (ref) {
            .id => |id| self.get(id),
            .tag => |tag| self.findByType(tag),
        };
    }

    /// Find first entity of type
    pub fn findByType(self: *Self, entity_type: EntityType) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.type == entity_type and entity.active) {
                return entity;
            }
        }
        return null;
    }

    /// Get all entities (mutable slice)
    pub fn getAll(self: *Self) []Entity {
        return self.entities.items;
    }

    /// Get all entities of a specific type
    pub fn getAllOfType(self: *Self, allocator: std.mem.Allocator, entity_type: EntityType) ![]Entity {
        var result = std.ArrayList(Entity).init(allocator);
        for (self.entities.items) |entity| {
            if (entity.type == entity_type and entity.active) {
                try result.append(entity);
            }
        }
        return result.toOwnedSlice();
    }

    /// Deactivate an entity
    pub fn destroy(self: *Self, id: EntityId) void {
        if (self.get(id)) |entity| {
            entity.active = false;
        }
    }

    /// Remove inactive entities
    pub fn compact(self: *Self) void {
        var i: usize = 0;
        while (i < self.entities.items.len) {
            if (!self.entities.items[i].active) {
                _ = self.entities.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    /// Clear all entities
    pub fn clear(self: *Self) void {
        self.entities.clearRetainingCapacity();
        self.next_entity_id = 1;
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit(self.allocator);
    }
};
