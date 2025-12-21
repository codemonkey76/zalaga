const Color = @import("engine").types.Color;

pub const TextureAsset = enum {
    sprite_sheet,

    pub fn filename(self: TextureAsset) []const u8 {
        return switch (self) {
            .sprite_sheet => "textures/spritesheet.png",
        };
    }

    pub fn transparentColor(self: TextureAsset) Color {
        _ = self;
        return Color.black;
    }
};
