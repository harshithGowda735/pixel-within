# Pixel Within

**Pixel Within** is a recursive 2D pixel-art puzzle platformer built with **Godot 4.7.2** and GDScript. 

Every colored pixel in the world contains a complete child level inside it. By diving into pixels, collecting pigments, and painting the hearts of child worlds, you transform the matter of the parent world above—turning impassable hazards into swimmable water, climbable vines, and super-bounce launch pads.

---

## Gameplay Mechanics

- **Dive (Z)**: When standing near a colored Chroma Pixel (Red $R$, Blue $B$, Green $G$, Yellow $Y$), press **Z** to dive into its sub-world.
- **Surface (C / Esc)**: Return back to the parent world at any time.
- **Pigment & Heart Painting (X)**: Collect pigment orbs ($r, b, g, y$) inside child worlds and deliver them to a Heart ($H$) of a different color. Painting the heart repaints the world, transforms the corresponding pixel in the parent world, and automatically surfaces you back.
- **Transformations**:
  - **Lava $\to$ Water ($B$)**: Turns lethal lava into swimmable water.
  - **Lava $\to$ Vine ($G$)**: Turns walls or lava into climbable vines.
  - **Lava $\to$ Spark Pad ($Y$)**: Turns ground into a high-velocity launch pad ($-430\text{ px/s}$).
- **Glitchlings ($x$)**: Patrol enemies moving at $30\text{ px/s}$ that reverse on solid walls and platform edges. Stomping on them bounces Pix upward ($-260\text{ px/s}$), while side or bottom contact is lethal.
- **Gems & Stars ($*$)**: Collect pink gems scattered across canvas and child worlds. Earn 1 to 3 stars per level based on completion and gem totals.
- **Genuine Depth Two (Canvas 5)**: Dive from Canvas 5 into Forest Canopy, and dive further into a Lava Pixel inside the Forest Canopy to reach the Lava Cave at depth 2!
- **Finale (Canvas 6)**: The ultimate 4-color puzzle connecting all mechanics, leading to the final canvas restoration and ending reveal.

---

## Controls

| Action | Primary Key | Alternate Key |
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` | Left / Right Arrows |
| **Jump** | `Space` | `W` / Up Arrow |
| **Climb Vines / Swim** | `W` / `S` | Up / Down Arrows |
| **Dive into Pixel** | `Z` | — |
| **Surface to Parent** | `C` | `Escape` |
| **Paint Heart** | `X` | — |
| **Toggle Music Mute** | `M` | — |
| **Menu Select / Confirm** | `Enter` / `Space` | `Z` |

---

## Technical Specifications

- **Engine**: Godot 4.7.2 stable
- **Language**: GDScript
- **Renderer**: GL Compatibility
- **Native Resolution**: $320 \times 180$ (integer scaling enabled)
- **Palette**: Strict 16-color palette (Pico-8 / retro inspired)
- **Audio**: Original 71.1s seamless looping chiptune soundtrack (`audio/pixel_within_theme.wav`)

---

## Project Structure

```
pixel-within/
├── audio/
│   └── pixel_within_theme.wav     # Original 71.1s BGM loop (16-bit PCM WAV)
├── autoload/
│   ├── palette.gd                 # 16-color palette constants & lookup
│   └── game.gd                    # Central state manager, dive stack, & logic
├── levels/
│   ├── canvas_01.txt..06.txt      # Canvas Levels 1 through 6
│   ├── canvas_05_g.txt            # Canvas 5 Forest Canopy child world
│   ├── world_red.txt              # Lava Cave child world
│   ├── world_blue.txt             # Ocean Trench child world
│   ├── world_green.txt            # Forest Canopy child world (Glitchlings)
│   └── world_yellow.txt           # Sun Desert child world
├── scenes/
│   ├── title_screen.tscn / .gd    # Title screen with animated canvas
│   ├── level_select.tscn / .gd    # 6-level select menu with stars & gems
│   └── main.tscn / .gd            # Gameplay scene, camera, HUD, & shaders
├── scripts/
│   ├── background.gd              # Bayer matrix dithering & parallax layers
│   ├── glitchling.gd              # Enemy patrol AI & custom collision
│   ├── level_loader.gd            # Plaintext level parser & serializer
│   ├── music_manager.gd           # Autoload audio player & mute toggle
│   ├── pixel_font.gd              # Custom 5x7 bitmap font renderer
│   ├── player.gd                  # Platforming physics, coyote time, buffer
│   ├── save_manager.gd            # Persistent progress (user://save.cfg)
│   ├── tiles.gd                   # Procedural animated 16x16 tile cache
│   └── validator.gd               # Strict 20x11 format & symbol validator
├── shaders/
│   └── mosaic.gdshader            # Screen-space mosaic pixelation transition
└── tests/
    ├── validate_levels.gd          # Level loader and validator test suite
    ├── test_player_physics.gd      # Platformer physics & collision suite
    ├── test_m3_gamestate.gd        # Game state & dive stack suite
    ├── test_m4_transitions.gd      # Mosaic shader & recolor wave suite
    ├── test_m5_visuals.gd          # Visual assets & palette suite
    ├── simulate_level1_playthrough.gd # Full Canvas 1 playthrough simulation
    ├── test_m6_levels.gd           # Canvas 2-4 and child worlds suite
    └── test_m7_full.gd             # M7 full regression suite (60 tests)
```

---

## Running Automated Tests

All test suites can be executed headlessly using the Godot executable:

```powershell
# Run full M7 comprehensive test suite
godot --headless --script tests/test_m7_full.gd

# Run level validation
godot --headless --script tests/validate_levels.gd

# Run player movement & collision physics tests
godot --headless --script tests/test_player_physics.gd

# Run all test suites
& godot --headless --script tests/validate_levels.gd
& godot --headless --script tests/test_player_physics.gd
& godot --headless --script tests/test_m3_gamestate.gd
& godot --headless --script tests/test_m4_transitions.gd
& godot --headless --script tests/test_m5_visuals.gd
& godot --headless --script tests/simulate_level1_playthrough.gd
& godot --headless --script tests/test_m6_levels.gd
& godot --headless --script tests/test_m7_full.gd
```
