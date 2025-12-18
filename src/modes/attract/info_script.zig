const std = @import("std");
const engine = @import("engine");
const actions = @import("demo_actions.zig");
const EntityType = @import("../../entities/entity_manager.zig").EntityType;
const EntityRef = @import("../../entities/entity_manager.zig").EntityRef;
const SpriteType = @import("../../assets/sprites.zig").SpriteType;

const easing = engine.timeline.easing;

pub fn createInfoScript(allocator: std.mem.Allocator) ![]const actions.DemoAction {
    var builder = engine.timeline.ScriptBuilder(actions.ActionData).init(allocator);
    defer builder.deinit();

    try builder.add(1.0, 23.0, .{
        .show_text_centered = .{
            .text = "ZALAGA",
            .y = 0.15,
            .font_size = 10,
            .color = engine.types.Color.sky_blue,
        },
    });

    try builder.add(2.0, 23.0, .{
        .show_text_centered = .{
            .text = "--- SCORE ---",
            .y = 0.22,
            .font_size = 10,
            .color = engine.types.Color.sky_blue,
        },
    });

    try builder.add(3.0, 0.1, .{
        .spawn_entity = .{
            .entity_type = .goei,
            .sprite_type = .goei,
            .position = .{ .x = 0.3, .y = 0.32 },
        },
    });

    try builder.add(3.0, 23.0, .{
        .show_text = .{
            .text = "50    100",
            .position = .{ .x = 0.52, .y = 0.31 },
            .font_size = 10,
            .color = engine.types.Color.sky_blue,
        },
    });

    try builder.add(4.0, 0.1, .{
        .spawn_entity = .{
            .entity_type = .zako,
            .sprite_type = .zako,
            .position = .{ .x = 0.3, .y = 0.38 },
        },
    });

    try builder.add(4.0, 23.0, .{
        .show_text = .{
            .text = "80    160",
            .position = .{ .x = 0.52, .y = 0.37 },
            .font_size = 10,
            .color = engine.types.Color.sky_blue,
        },
    });

    try builder.add(5.0, 0.1, .{
        .spawn_entity = .{
            .entity_type = .boss,
            .sprite_type = .boss,
            .position = .{ .x = 0.5, .y = 0.497 },
        },
    });

    try spawnBossFormation(&builder, 5.5);
    try spawnGoeiFormation(&builder, 5.5);

    try builder.add(5.5, 0.1, .{
        .spawn_entity = .{
            .entity_type = .player,
            .sprite_type = .player,
            .position = .{ .x = 0.5, .y = 0.9 },
        },
    });

    try builder.add(5.7, 0.0, .{
        .move_to = .{
            .target = .{ .tag = .player },
            .position = .{ .x = 0.7, .y = 0.9 },
            .duration = 1.5,
            .ease = easing.linear,
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
        .{ .x = 0.2, .y = 0.617 },
        .{ .x = 0.4, .y = 0.617 },
        .{ .x = 0.6, .y = 0.617 },
        .{ .x = 0.8, .y = 0.617 },
    };

    for (positions) |pos| {
        try builder.add(start_time, 0.1, .{
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

    for (positions) |pos| {
        try builder.add(start_time, 0.1, .{
            .spawn_entity = .{
                .entity_type = .goei,
                .sprite_type = .goei,
                .position = pos,
            },
        });
    }
}
