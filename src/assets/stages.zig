const StageDefinition = @import("../mod.zig").StageDefinition;

pub const Stages = struct {};

pub const stage_1 = StageDefinition{
    .stage_number = 1,
    .stage_type = .normal,
    .waves = &.{
        .{
            .groups = &.{
                .{
                    .enemies = &.{
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 0, .col = 3 }, .spawn_delay = 0.0 },
                        .{ .enemy_type = .boss, .grid_pos = .{ .row = 0, .col = 4 }, .spawn_delay = 0.3 },
                    },
                    .entry_path = .boss_entry_left,
                    .exit_path = null, // join formation
                    .group_delay = 0.0,
                },
            },
            .wave_delay = 2.0,
        },
    },
    .can_shoot_during_entry = true,
    .attack_delay = 2.0,
    .attack_frequency = 0.8,
    .speed_multiplier = 1.0,
};
