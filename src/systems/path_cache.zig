const std = @import("std");
const arcade_lib = @import("arcade_lib");
const PathAsset = @import("../assets/path_asset.zig").PathAsset;
const Context = @import("../mod.zig").Context;

/// Helper for accessing PathDefinitions from loaded path assets
/// Note: No longer caches anything since Path assets already contain the PathDefinition
pub const PathCache = struct {
    const Self = @This();
    
    pub fn init(_: std.mem.Allocator) Self {
        return .{};
    }
    
    pub fn deinit(_: *Self) void {}
    
    /// Get PathDefinition for the given path asset
    pub fn getPathDefinition(_: *Self, ctx: *Context, path_asset: PathAsset) !arcade_lib.PathDefinition {
        // Load the path from asset manager (it already has a PathDefinition built)
        const path = ctx.assets.getPath(path_asset) orelse {
            return error.PathNotFound;
        };
        
        return path.definition;
    }
};
