const std = @import("std");
const engine = @import("engine");

pub const DebugMode = struct {
    enabled: bool,
    paused: bool,
    step_one_frame: bool,
    show_angles: bool,
    show_paths: bool,

    const Self = @This();

    pub fn init() Self {
        return .{
            .enabled = true,
            .paused = false,
            .step_one_frame = false,
            .show_angles = true,
            .show_paths = true,
        };
    }

    pub fn update(self: *Self, ctx: anytype) void {
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
};
