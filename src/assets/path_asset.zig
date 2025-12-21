pub const PathAsset = enum {
    level1_1_left,

    pub fn filename(self: PathAsset) []const u8 {
        return switch (self) {
            .level_1_1_left => "paths/1-1-l.gpath",
        };
    }
};
