const std = @import("std");
const arcade_lib = @import("arcade_lib");
const PathAsset = @import("../assets/path_asset.zig").PathAsset;
const Context = @import("../mod.zig").Context;

/// Caches converted PathDefinition control points to avoid recreating them every frame
pub const PathCache = struct {
    allocator: std.mem.Allocator,
    cache: std.AutoHashMap(PathAsset, []arcade_lib.Vec2),
    
    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .cache = std.AutoHashMap(PathAsset, []arcade_lib.Vec2).init(allocator),
        };
    }
    
    pub fn deinit(self: *Self) void {
        var iter = self.cache.valueIterator();
        while (iter.next()) |control_points| {
            self.allocator.free(control_points.*);
        }
        self.cache.deinit();
    }
    
    /// Get or create a PathDefinition for the given path asset
    pub fn getPathDefinition(self: *Self, ctx: *Context, path_asset: PathAsset) !arcade_lib.PathDefinition {
        // Check if already cached
        if (self.cache.get(path_asset)) |control_points| {
            return arcade_lib.PathDefinition{
                .control_points = control_points,
            };
        }
        
        // Load the path from asset manager
        const path = ctx.assets.getPath(path_asset) orelse {
            return error.PathNotFound;
        };
        
        // Convert anchors to Vec2 points
        var points = std.ArrayList(arcade_lib.Vec2){};
        defer points.deinit(self.allocator);
        
        for (path.anchors) |anchor| {
            try points.append(self.allocator, .{ .x = anchor.pos.x, .y = anchor.pos.y });
        }
        
        // Convert points to control points
        const control_points = try arcade_lib.PathDefinition.fromPoints(
            self.allocator,
            points.items,
        );
        
        // Cache the control points
        try self.cache.put(path_asset, control_points);
        
        return arcade_lib.PathDefinition{
            .control_points = control_points,
        };
    }
};
