pub const PathAsset = enum {
    level_1_1_left,
    level_1_1_right,
    level_1_2_left,
    level_1_2_right,

    pub fn filename(self: PathAsset) []const u8 {
        return switch (self) {
            .level_1_1_left => "paths/1-1-l.gpath",
            .level_1_1_right => "paths/1-1-r.gpath",
            .level_1_2_left => "paths/1-2-l.gpath",
            .level_1_2_right => "paths/1-2-r.gpath",
        };
    }
};
