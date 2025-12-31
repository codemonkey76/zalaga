const std = @import("std");
const engine = @import("engine");
const z = @import("../../mod.zig");
const c = @import("../../constants.zig");
const Context = z.Context;
const EntityManager = z.EntityManager;
pub const EntityId = @import("../../entities/entity.zig").EntityId;
const StageManager = @import("stage_manager.zig").StageManager;

/// Stage intro sequence handler
pub const IntroSequence = struct {
    allocator: std.mem.Allocator,
    state: enum {
        player_ready,
        stage_ready,
        player_spawn,
        complete,
    } = .player_ready,
    timer: f32 = 0,
    player_id: ?EntityId = null,
    chirps_to_play: u8 = 0,
    chirps_played: u8 = 0,
    next_chirp_time: f32 = 0,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn update(self: *Self, ctx: *Context, state: *z.GameState, dt: f32) !bool {
        const player = state.getActivePlayerMut() orelse return false;
        const stage_num = player.stage.stage_number;

        self.timer += dt;

        switch (self.state) {
            .player_ready => {
                if (self.timer >= c.stage.PLAYER_READY_DURATION) {
                    // ctx.assets.playSound(.intro);
                    self.state = .stage_ready;
                    self.timer = 0;
                    self.chirps_played = 0;
                    const markers = try StageManager.getLevelMarkers(self.allocator, stage_num);
                    player.level_markers.markers.clearRetainingCapacity();
                    try player.level_markers.markers.appendSlice(self.allocator, markers);
                    std.debug.print("Adding markers to player state, count: {}\n", .{markers.len});
                    std.debug.print("Player markers after append: {}\n", .{player.level_markers.markers.items.len});
                    defer self.allocator.free(markers);
                    self.chirps_to_play = @intCast(markers.len);
                    self.next_chirp_time = 0;
                }
            },
            .stage_ready => {
                if (self.chirps_played < self.chirps_to_play and self.timer >= self.next_chirp_time) {
                    ctx.assets.playSound(.level_marker);
                    self.chirps_played += 1;
                    self.next_chirp_time = self.timer + 0.1; // 0.1 seconds between chirps
                }

                if (self.timer >= c.stage.STAGE_READY_DURATION) {
                    self.state = .player_spawn;
                    self.timer = 0;
                }
            },
            .player_spawn => {
                if (self.player_id == null) {
                    self.player_id = try state.entity_manager.spawnPlayer(.{ .x = 0.5, .y = 0.91 });
                }
                if (self.timer >= c.stage.PLAYER_SPAWN_DURATION) {
                    self.state = .complete;
                    self.timer = 0;
                }
            },
            .complete => return true,
        }

        return false; // Not complete yet
    }

    pub fn draw(self: *const Self, ctx: *Context, _: *z.GameState) void {
        switch (self.state) {
            .player_ready => {
                ctx.renderer.text.drawTextCentered("PLAYER 1", 0.5, 10, engine.types.Color.sky_blue);
            },
            .stage_ready => {
                ctx.renderer.text.drawTextCentered("STAGE 1", 0.5, 10, engine.types.Color.sky_blue);
            },
            .player_spawn => {
                ctx.renderer.text.drawTextCentered("PLAYER 1", 0.45, 10, engine.types.Color.sky_blue);
                ctx.renderer.text.drawTextCentered("STAGE 1", 0.5, 10, engine.types.Color.sky_blue);
            },
            .complete => {},
        }
    }

    pub fn getPlayerId(self: Self) ?EntityId {
        return self.player_id;
    }

    pub fn isComplete(self: Self) bool {
        return self.state == .complete;
    }
};
