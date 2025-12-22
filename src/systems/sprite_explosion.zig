const std = @import("std");
const engine = @import("engine");
const Context = @import("../mod.zig").Context;
const GameState = @import("../core/game_state.zig").GameState;
const ExplosionSpriteId = @import("../assets/sprites.zig").ExplosionSpriteId;

pub const SpriteExplosion = struct {
    position: engine.types.Vec2,
    frame_time: f32,
    current_frame: usize,
    frames: []const ExplosionSpriteId,
    frame_duration: f32,
    finished: bool,
};

pub const SpriteExplosionSystem = struct {
    allocator: std.mem.Allocator,
    explosions: std.ArrayList(SpriteExplosion),
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .explosions = std.ArrayList(SpriteExplosion){},
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.explosions.deinit(self.allocator);
    }
    
    /// Spawn player explosion
    pub fn spawnPlayerExplosion(self: *Self, position: engine.types.Vec2) !void {
        const frames = &[_]ExplosionSpriteId{
            .player_frame_1,
            .player_frame_2,
            .player_frame_3,
            .player_frame_4,
        };
        
        try self.explosions.append(self.allocator, .{
            .position = position,
            .frame_time = 0,
            .current_frame = 0,
            .frames = frames,
            .frame_duration = 0.08, // 80ms per frame
            .finished = false,
        });
    }
    
    /// Spawn enemy explosion
    pub fn spawnEnemyExplosion(self: *Self, position: engine.types.Vec2) !void {
        const frames = &[_]ExplosionSpriteId{
            .enemy_frame_1,
            .enemy_frame_2,
            .enemy_frame_3,
            .enemy_frame_4,
            .enemy_frame_5,
        };
        
        try self.explosions.append(self.allocator, .{
            .position = position,
            .frame_time = 0,
            .current_frame = 0,
            .frames = frames,
            .frame_duration = 0.06, // 60ms per frame (faster)
            .finished = false,
        });
    }
    
    pub fn update(self: *Self, dt: f32) void {
        var i: usize = 0;
        while (i < self.explosions.items.len) {
            var explosion = &self.explosions.items[i];
            
            explosion.frame_time += dt;
            
            // Advance to next frame
            if (explosion.frame_time >= explosion.frame_duration) {
                explosion.frame_time = 0;
                explosion.current_frame += 1;
                
                // Check if animation finished
                if (explosion.current_frame >= explosion.frames.len) {
                    _ = self.explosions.swapRemove(i);
                    continue;
                }
            }
            
            i += 1;
        }
    }
    
    pub fn draw(self: *Self, ctx: *Context, state: *GameState) void {
        for (self.explosions.items) |explosion| {
            if (explosion.current_frame < explosion.frames.len) {
                const sprite_id = explosion.frames[explosion.current_frame];
                if (state.sprites.getExplosionSprite(sprite_id)) |sprite| {
                    ctx.renderer.drawSprite(sprite, explosion.position);
                }
            }
        }
    }
    
    pub fn clear(self: *Self) void {
        self.explosions.clearRetainingCapacity();
    }
};
