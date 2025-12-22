const engine = @import("engine");
pub const Game = @import("game.zig").Game;
pub const GameState = @import("core/game_state.zig").GameState;
pub const PlayerState = @import("gameplay/player_state.zig").PlayerState;
pub const StageState = @import("gameplay/stage.zig").StageState;
pub const StageDefinition = @import("gameplay/stage.zig").StageDefinition;

pub const assets = struct {
    pub const Sprites = @import("assets/sprites.zig").Sprites;
    pub const SpriteType = @import("assets/sprites.zig").SpriteType;
    pub const TextureAsset = @import("assets/texture_asset.zig").TextureAsset;
    pub const FontAsset = @import("assets/font_asset.zig").FontAsset;
    pub const PathAsset = @import("assets/path_asset.zig").PathAsset;
    pub const SoundAsset = @import("assets/sound_asset.zig").SoundAsset;

    pub const MyAssetManager = engine.assets.AssetManager(
        TextureAsset,
        FontAsset,
        PathAsset,
        SoundAsset,
    );
};

pub const Context = engine.Context(
    assets.TextureAsset,
    assets.FontAsset,
    assets.PathAsset,
    assets.SoundAsset,
);
pub const GameVTable = engine.GameVTable(Context);

pub const rendering = struct {
    pub const Starfield = @import("rendering/starfield.zig").Starfield;
    pub const Hud = @import("rendering/hud.zig").Hud;
};

pub const modes = struct {
    pub const GameMode = @import("modes/mode.zig").GameMode;
    pub const AttractMode = @import("modes/attract/attract.zig").Attract;
    pub const PlayingMode = @import("modes/playing/playing.zig").Playing;
    pub const HighScoreMode = @import("modes/high_score/high_score.zig").HighScore;
    pub const StartScreenMode = @import("modes/start_screen/start_screen.zig").StartScreen;
    pub const HighScoreTable = @import("modes/high_score/high_score_table.zig").HighScoreTable;
};

pub const EntityManager = @import("entities/entity_manager.zig").EntityManager;
pub const EntityType = @import("entities/entity.zig").EntityType;
