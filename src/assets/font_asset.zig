pub const FontAsset = enum {
    main_font,

    pub fn filename(self: FontAsset) []const u8 {
        return switch (self) {
            .main_font => "fonts/Cousine-Regular.ttf",
        };
    }

    pub fn size(self: FontAsset) ?i32 {
        _ = self;
        return 18;
    }
};
