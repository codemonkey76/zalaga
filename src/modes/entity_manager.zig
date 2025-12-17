const std = @import("std");
const engine = @import("engine");

const SpriteType = @import("../assets/sprites.zig").SpriteType;
const SpriteId = @import("../assets/sprites.zig").SpriteId;

pub const EntityType = enum {
    player,
    boss,
    goei,
    zako,
    projectile,
};

pub const DemoEntity = struct {
    id: u32,
    entity_type: EntityType,
    sprite_type: SpriteType,
    position: engine.types.Vec2,
    sprite_id: SpriteId = .idle_1,
    angle: f32 = 0.0,
    active: bool = true,

    // Movement state
    velocity: engine.types.Vec2 = .{ .x = 0, .y = 0 },
    target_pos: ?engine.types.Vec2 = null,
    move_speed: f32 = 0,
    path_index: usize = 0,
    path_t: f32 = 0.0,

    pub fn isMoving(self: DemoEntity) bool {
        return self.target_pos != null or self.velocity.x != 0 or self.velocity.y != 0;
    }
};

pub const Projectile = struct {
    position: engine.types.Vec2,
    velocity: engine.types.Vec2,
    active: bool = true,
};

pub const EntityRef = union(enum) {
    id: u32,
    tag: EntityType,
};

pub const EntityManager = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(DemoEntity),
    projectiles: std.ArrayList(Projectile),
    next_entitty_id: u32 = 1,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .entities = std.ArrayList(DemoEntity).empty,
            .projectiles = std.ArrayList(Projectile).empty,
        };
    }

    pub fn spawn(self: *Self, entity_type: EntityType, sprite_type: SpriteType, position: engine.types.Vec2) !u32 {
        const id = self.next_entitty_id;
        self.next_entitty_id += 1;
        try self.entities.append(self.allocator, .{
            .id = id,
            .entity_type = entity_type,
            .sprite_type = sprite_type,
            .position = position,
        });

        return id;
    }

    pub fn spawnProjectile(self: *Self, position: engine.types.Vec2, velocity: engine.types.Vec2) !void {
        try self.projectiles.append(self.allocator, .{
            .position = position,
            .velocity = velocity,
        });
    }

    pub fn find(self: *Self, ref: EntityRef) ?*DemoEntity {
        return switch (ref) {
            .id => |id| self.findById(id),
            .tag => |tag| self.findByType(tag),
        };
    }

    pub fn findById(self: *Self, id: u32) ?*DemoEntity {
        for (self.entities.items) |*entity| {
            if (entity.id == id and entity.active) return entity;
        }
        return null;
    }

    pub fn findByType(self: *Self, entity_type: EntityType) ?*DemoEntity {
        for (self.entities.items) |*entity| {
            if (entity.entity_type == entity_type and entity.active) return entity;
        }

        return null;
    }

    pub fn reset(self: *Self) void {
        self.entities.clearRetainingCapacity();
        self.projectiles.clearRetainingCapacity();
        self.next_entitty_id = 1;
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit(self.allocator);
        self.projectiles.deinit(self.allocator);
    }
};
