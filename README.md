
# Zalaga

A modern Galaga clone built with Zig, featuring smooth Bézier curve enemy paths and classic arcade gameplay.

> **Status**: 🚧 Work in Progress - Early development stage

## Overview

Zalaga is a recreation of the classic arcade shooter Galaga, built from the ground up in Zig. The game uses modern techniques like Bézier curve paths for enemy movement while maintaining the classic arcade feel.

## Features

### Currently Implemented
- ✅ **Starfield Background** - Parallax scrolling starfield with:
  - Twinkling stars
  - Shooting stars with trails
  - Configurable speed and density
  - Parallax depth effects
  - Multiple star colors (white, blue-tinted, yellow-tinted, red-tinted)

### Planned Features
- 🚧 **Player Ship** - Controllable spaceship with smooth movement
- 🚧 **Enemy Waves** - Classic Galaga enemy formations
- 🚧 **Bézier Path Movement** - Enemies follow smooth curved paths
- 🚧 **Shooting Mechanics** - Player bullets and enemy projectiles
- 🚧 **Enemy AI** - Dive bomb attacks and formation patterns
- 🚧 **Power-ups** - Dual fighter mode and other bonuses
- 🚧 **Scoring System** - Points and high scores
- 🚧 **Sound Effects** - Classic arcade audio
- 🚧 **Particle Effects** - Explosions and visual feedback

## Requirements

- Zig 0.15.2 or later
- No external dependencies (raylib bundled via engine)

## Building

### Development Build
```bash
# Clone the repository
git clone https://github.com/yourusername/zalaga.git
cd zalaga

# Build and run
zig build run
```

### Release Build
```bash
# Build optimized binary
zig build -Doptimize=ReleaseFast

# Binary will be in zig-out/bin/
```

### Cross-Platform Builds
```bash
# Windows
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall

# Linux
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSmall

# macOS
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSmall
```

## Project Structure
```
zalaga/
├── src/
│   ├── main.zig              # Entry point
│   ├── root.zig              # Module exports
│   ├── game.zig              # Game loop management
│   ├── game_state.zig        # Main game state
│   ├── assets/
│   │   ├── assets.zig        # Asset management
│   │   └── sprites.zig       # Sprite definitions
│   └── graphics/
│       └── starfield.zig     # Starfield implementation
├── assets/
│   └── sprites/              # Game sprites (planned)
│       └── sprites.png       # Sprite sheet
├── build.zig
└── build.zig.zon
```

## Dependencies

Zalaga uses:
- [zig-arcade-engine](../engine) - 2D game engine with virtual resolution
- [arcade-lib](../arcade-lib) - Bézier path system for enemy movement
- [raylib-zig](https://github.com/Not-Nik/raylib-zig) - Zig bindings for raylib (via engine)

All dependencies are managed via Zig's package manager.

## Architecture

### Game Loop
```zig
Game
├── onInit()     - Initialize game state
├── onUpdate()   - Update game logic (60 FPS)
├── onDraw()     - Render frame
└── onShutdown() - Cleanup resources
```

### Rendering System

- **Virtual Resolution**: 224x288 (classic arcade aspect ratio)
- **SSAA**: 2x super-sampling for crisp graphics
- **Viewport**: Automatic scaling and letterboxing

### Starfield System

The starfield creates a dynamic space background:
```zig
const Starfield = struct {
    cfg: StarfieldConfig,
    stars: []Star,
    
    // Configuration
    max_stars: u32 = 200,
    speed: f32 = 60.0,
    shoot_speed: f32 = 1200.0,
    twinkle_chance: f32 = 0.3,
    shoot_chance: f32 = 0.01,
    parallax_strength: f32 = 20.0,
};
```

## Development Roadmap

### Phase 1: Core Mechanics (Current)
- [x] Project setup and engine integration
- [x] Starfield background
- [ ] Player ship sprite and movement
- [ ] Player shooting
- [ ] Basic collision detection

### Phase 2: Enemy System
- [ ] Enemy sprite loading
- [ ] Formation system
- [ ] Path-based movement (using arcade-lib)
- [ ] Enemy shooting patterns
- [ ] Collision with enemies

### Phase 3: Game Loop
- [ ] Wave system
- [ ] Scoring
- [ ] Lives and game over
- [ ] Level progression
- [ ] Boss fights (optional)

### Phase 4: Polish
- [ ] Sound effects
- [ ] Music
- [ ] Particle effects
- [ ] Screen shake
- [ ] UI/HUD
- [ ] High score system

### Phase 5: Extra Features
- [ ] Multiple difficulty levels
- [ ] Power-ups
- [ ] Challenge modes
- [ ] Achievements

## Customization

### Starfield Configuration

Edit `src/game_state.zig` to customize the starfield:
```zig
self.starfield = try Starfield.init(allocator, ctx, .{
    .max_stars = 200,           // Number of stars
    .speed = 60.0,              // Base scroll speed
    .shoot_speed = 1200.0,      // Shooting star speed
    .twinkle_chance = 0.3,      // 30% of stars twinkle
    .shoot_chance = 0.01,       // 1% chance for shooting stars
    .parallax_strength = 20.0,  // Parallax effect intensity
    .tail_length = 24.0,        // Shooting star trail length
});
```

### Window Configuration

Edit `src/game.zig` to change window settings:
```zig
try engine.run(self.allocator, self, callbacks, .{
    .title = "Zalaga",
    .width = 1280,              // Window width
    .height = 720,              // Window height
    .virtual_width = 224,       // Game resolution width
    .virtual_height = 288,      // Game resolution height
    .target_fps = 60,           // Target frame rate
    .resizable = true,          // Allow window resizing
});
```

## Controls (Planned)

- **Arrow Keys / WASD**: Move ship
- **Space / Z**: Shoot
- **Escape**: Pause menu
- **F11**: Toggle fullscreen

## Contributing

This is a learning project, but contributions are welcome! Areas that need work:
- [ ] Sprite artwork
- [ ] Sound effects
- [ ] Enemy AI patterns
- [ ] Level design
- [ ] Testing and bug fixes

Please open an issue or PR if you'd like to contribute.

## Known Issues

- No gameplay yet (sprites/enemies/shooting not implemented)
- Asset loading code is incomplete
- No collision detection
- No sound system

## Development Notes

### Adding Sprites

1. Create sprite sheet in `assets/sprites/`
2. Define sprite IDs in `src/assets/sprites.zig`
3. Load and register sprites in `Assets.init()`
4. Use sprite system from engine:
```zig
const sprite = sprites.player_layout.getSprite(.rotation_0);
ctx.renderer.drawSprite(sprite, position);
```

### Adding Enemy Paths

1. Create paths using [Path Sketcher](https://github.com/codemonkey76/path-sketcher)
2. Save paths to `assets/paths/`
3. Load paths via `arcade.PathRegistry`
4. Use paths for enemy movement:
```zig
const pos = path.getPosition(t); // t: 0.0 to 1.0
enemy.x = pos.x * screen_width;
enemy.y = pos.y * screen_height;
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [Galaga](https://en.wikipedia.org/wiki/Galaga) (1981, Namco)
- Built with [Zig](https://ziglang.org/)
- Uses [raylib](https://www.raylib.com/) for graphics
- Enemy paths powered by [arcade-lib](https://github.com/codemonkey76/arcade-lib)

## Related Projects

- [zig-arcade-engine](https://github.com/codemonkey76/zig-arcade-engine) - The game engine
- [arcade-lib](https://github.com/codemonkey76/arcade-lib) - Path system library
- [Path Sketcher](https://github.com/codemonkey76/path-sketcher) - Visual path editor

## Support

For questions or issues, please [open an issue](https://github.com/yourusername/zalaga/issues) on GitHub.

---

**Status Update**: Currently implementing sprite system and player controls. Check back soon for playable builds!
