const std = @import("std");
const engine = @import("engine");
const actions = @import("demo_actions.zig");
const EntityType = @import("../../entities/entity_manager.zig").EntityType;
const EntityRef = @import("../../entities/entity_manager.zig").EntityRef;
const SpriteType = @import("../../assets/sprites.zig").SpriteType;

pub fn createDemoScript(allocator: std.mem.Allocator) ![]const actions.DemoAction {
    var builder = engine.timeline.ScriptBuilder(actions.ActionData).init(allocator);
    defer builder.deinit();

    // 0.0s: Spawn player
    try builder.add(0.0, 0.1, .{
        .spawn_entity = .{
            .entity_type = .player,
            .sprite_type = .player,
            .position = .{ .x = 0.5, .y = 0.9 },
        },
    });

    // 1.0s: Spawn boss formation
    try spawnBossFormation(&builder, 1.0);

    // 1.5s: Spawn goei formation
    try spawnGoeiFormation(&builder, 1.5);

    // 3.0s: Player moves right
    try builder.add(3.0, 2.0, .{
        .move_to = .{
            .target = .{ .tag = .player },
            .position = .{ .x = 0.7, .y = 0.9 },
            .speed = 0.15,
        },
    });

    // 4.5s: Player shoots first boss
    try builder.add(4.5, 0.1, .{
        .shoot_at = .{
            .shooter = .{ .tag = .player },
            .target = .{ .id = 2 },
            .projectile_speed = 0.5,
        },
    });

    // 5.5s: Despawn first boss
    try builder.add(5.5, 0.1, .{
        .despawn_entity = .{
            .target = .{ .id = 2 },
        },
    });

    const script = try builder.build();

    // Convert to DemoAction format (with .base field)
    var demo_actions = try allocator.alloc(actions.DemoAction, script.len);
    for (script, 0..) |action, i| {
        demo_actions[i] = .{
            .base = action.base,
            .data = action.data,
        };
    }
    allocator.free(script);

    return demo_actions;
}

fn spawnBossFormation(builder: anytype, start_time: f32) !void {
    const positions = [_]engine.types.Vec2{
        .{ .x = 0.5, .y = 0.497 },
        .{ .x = 0.2, .y = 0.617 },
        .{ .x = 0.4, .y = 0.617 },
        .{ .x = 0.6, .y = 0.617 },
        .{ .x = 0.8, .y = 0.617 },
    };

    for (positions, 0..) |pos, i| {
        const time = start_time + @as(f32, @floatFromInt(i)) * 0.1;
        try builder.add(time, 0.1, .{
            .spawn_entity = .{
                .entity_type = .boss,
                .sprite_type = .boss,
                .position = pos,
            },
        });
    }
}

fn spawnGoeiFormation(builder: anytype, start_time: f32) !void {
    const positions = [_]engine.types.Vec2{
        .{ .x = 0.65, .y = 0.677 },
        .{ .x = 0.73, .y = 0.677 },
        .{ .x = 0.85, .y = 0.677 },
    };

    for (positions, 0..) |pos, i| {
        const time = start_time + @as(f32, @floatFromInt(i)) * 0.1;
        try builder.add(time, 0.1, .{
            .spawn_entity = .{
                .entity_type = .goei,
                .sprite_type = .goei,
                .position = pos,
            },
        });
    }
}
