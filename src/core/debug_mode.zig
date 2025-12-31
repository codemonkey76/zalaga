const std = @import("std");
const engine = @import("engine");
const z = @import("../mod.zig");
const arcade_lib = @import("arcade_lib");
const PathAsset = @import("../assets/path_asset.zig").PathAsset;

pub const DebugMode = struct {
    allocator: std.mem.Allocator,
    enabled: bool,
    paused: bool,
    step_one_frame: bool,
    show_angles: bool,
    show_paths: bool,
    drawn_paths: std.AutoArrayHashMap(PathAsset, void),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .enabled = false,
            .paused = false,
            .step_one_frame = false,
            .show_angles = true,
            .show_paths = true,
            .drawn_paths = std.AutoArrayHashMap(PathAsset, void).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.drawn_paths.deinit();
    }

    pub fn update(self: *Self, ctx: anytype, _: *z.GameState) void {
        if (ctx.input.isKeyPressed(.f3)) {
            self.enabled = !self.enabled;
        }

        if (!self.enabled) return;

        // Toggle pause with P key
        if (ctx.input.isKeyPressed(.p)) {
            self.paused = !self.paused;
            std.debug.print("Debug: {s}\n", .{if (self.paused) "PAUSED" else "RUNNING"});
        }

        // Step one frame with Space when paused
        if (self.paused and ctx.input.isKeyPressed(.space)) {
            self.step_one_frame = true;
            std.debug.print("Debug: Step one frame\n", .{});
        }

        // Toggle angle display with A key
        if (ctx.input.isKeyPressed(.a)) {
            self.show_angles = !self.show_angles;
            std.debug.print("Debug: Angle display {s}\n", .{if (self.show_angles) "ON" else "OFF"});
        }
    }

    pub fn shouldUpdate(self: *Self) bool {
        if (!self.enabled) return true;
        if (!self.paused) return true;

        // If paused, only update if stepping one frame
        if (self.step_one_frame) {
            self.step_one_frame = false;
            return true;
        }

        return false;
    }

    pub fn draw(self: *Self, ctx: anytype, state: *z.GameState) !void {
        var buffer: [512]u8 = undefined;
        var y_offset: f32 = 0.15;

        // Draw debug instructions
        const instructions = "P=Pause\nSPACE=Step\nA=Toggle Angles";
        ctx.renderer.text.drawText(instructions, .{ .x = 0.02, .y = y_offset }, 6, engine.types.Color.yellow);
        y_offset += 0.03;

        // Draw entity info for each enemy
        for (state.entity_manager.getAll()) |entity| {
            if (!entity.active) continue;
            if (entity.type == .player or entity.type == .projectile) continue;

            // Get sprite rotation info if entity is moving
            var sprite_info: []const u8 = "";
            var sprite_info_buf: [128]u8 = undefined;
            if (entity.isMoving() and entity.sprite_type != null) {
                if (state.sprites.getRotationSet(entity.sprite_type.?)) |rotation_set| {
                    if (rotation_set.getSpriteForAngle(entity.angle)) |flipped| {
                        const h_flip = if (flipped.flip.horizontal) "H" else "-";
                        const v_flip = if (flipped.flip.vertical) "V" else "-";
                        sprite_info = std.fmt.bufPrint(&sprite_info_buf, "\nSprite: {s}\nFlip: {s}{s}", .{
                            @tagName(flipped.id),
                            h_flip,
                            v_flip,
                        }) catch "";
                    }
                }
            }

            // Draw angle info next to entity
            const text = std.fmt.bufPrint(&buffer, "Angle: {d:.1}\nBehavior: {s}\nPathT: {d:.2}{s}", .{
                entity.angle,
                @tagName(entity.behavior),
                entity.path_t,
                sprite_info,
            }) catch "Error";

            const text_pos = engine.types.Vec2{
                .x = entity.position.x + 0.05,
                .y = entity.position.y,
            };
            const cyan = engine.types.Color{ .r = 0, .g = 255, .b = 255, .a = 255 };
            ctx.renderer.text.drawText(text, text_pos, 6, cyan);

            // Draw direction line
            const line_length: f32 = 0.10;
            const angle_rad = entity.angle * std.math.pi / 180.0;
            const end_pos = engine.types.Vec2{
                .x = entity.position.x + @sin(angle_rad) * line_length,
                .y = entity.position.y - @cos(angle_rad) * line_length,
            };
            ctx.renderer.drawLine(entity.position, end_pos, 2, engine.types.Color.red);

            self.drawn_paths.clearRetainingCapacity();

            const path_asset = entity.current_path orelse continue;
            if (ctx.assets.paths.get(path_asset)) |path| {
                if (!self.drawn_paths.contains(path_asset)) {
                    self.drawPath(path.definition, ctx);
                    try self.drawn_paths.put(path_asset, {});
                }
            }
        }
    }

    fn drawPath(self: *Self, path: arcade_lib.PathDefinition, ctx: anytype) void {
        _ = self;
        const segments = 300;
        const step = 1.0 / @as(f32, @floatFromInt(segments));

        var i: usize = 0;
        while (i < segments) : (i += 1) {
            const t1 = @as(f32, @floatFromInt(i)) * step;
            const t2 = @as(f32, @floatFromInt(i + 1)) * step;

            const pos1 = path.getPosition(t1);
            const pos2 = path.getPosition(t2);

            const p1 = engine.types.Vec2{
                .x = pos1.x,
                .y = pos1.y,
            };

            const p2 = engine.types.Vec2{
                .x = pos2.x,
                .y = pos2.y,
            };

            ctx.renderer.drawLine(p1, p2, 2, engine.types.Color.red);
        }
    }
};
