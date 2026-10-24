# MEMORY//BREACH — Editable World Edition

Godot 4.3+ source project. All ten worlds have real, editable FloorTiles,
WallTiles and DecorationTiles layers. Character motion now has acceleration,
braking, gradual turning, eight walk frames per direction, a distance-driven
gait, subtle lean, breathing and firing recoil.

## Start here

1. Extract this ZIP into a NEW folder.
2. Open Godot Project Manager, choose Import, select project.godot.
3. Wait for assets to import. Press F5 to play.
4. To edit your world, double-click **worlds/Sector_01.tscn** in FileSystem.
5. Click the **2D** workspace at the top.
6. Select FloorTiles, WallTiles or DecorationTiles in the Scene tree.
7. Open the TileMap panel at the bottom, choose an atlas tile, and paint with
   the left mouse button. Use the eraser/right mouse button to remove cells.
8. Press Ctrl+S to save, then F5 to test your changes.

The actual map cells are 24 x 24 world units. FloorTiles and WallTiles share
one aligned grid. All 64 atlas tiles are available on each layer.

- FloorTiles: floor appearance. Paint, replace or erase any floor tile.
- WallTiles: solid obstacles. EVERY tile painted here blocks movement,
  bullets and lasers, regardless of its picture. Erasing removes collision.
- DecorationTiles: paint any image over the floor without adding collision.

Walls are no longer stretched rectangular objects. They are individual tiles
with native collision polygons. Walls have been snapped onto the 24px grid,
so their precise edges differ slightly from the earlier rectangle version.
The supplied generated art has slight source-grid irregularities; a few edges
may need art polish. The tile layer scale converts 156px atlas cells to 24px
world cells; leave that transform unchanged to keep the grids aligned.

Use the SELECT tool in TileMap to move a painted selection. To paint floor
and walls, select their layer in the Scene tree; clicking a wall in the scene
is not how individual TileMap cells are selected. Select FloorTiles and press
F if you need to frame the map in the 2D viewport.

Interactive gates, terminals, shards, receivers, drones, lasers and extraction
remain separate editable nodes. Expand their groups to move or duplicate
objects. Their Tile property selects which atlas image they display; their
Command, Sensor, Label and other properties control gameplay. Gate collision
remains active until that gate is unlocked. Keep group names and the Player
and Extraction node names unchanged.

Main.tscn is the game launcher, with a World instance shown in the editor.
For persistent map edits, always open worlds/Sector_XX.tscn itself. The game
loads these saved scenes; avoid making layout overrides on the launcher.

For a quick standalone run of sector 2 (etc.), open sectors/Sector_02.tscn
and press F6. Those files are playable wrappers; worlds/ holds editable map
assets. Running a raw world asset with F6 displays it without the controller.

## Player movement

Open scenes/Player.tscn and select Player. In the Inspector, adjust:

- Movement Speed: 210 world units per second.
- Shield Speed: 140.
- Acceleration: 1250, about 0.17 seconds to reach normal speed.
- Braking: 1800, about 0.12 seconds to stop from normal speed.
- Turn Speed: 12, visual facing smoothing.
- Stride Length: 92 world units per eight-frame walk loop.

The body follows movement while walking and turns toward aim when stationary,
shielding, hacking or firing. Actual distance travelled advances the walk
cycle, so standing against a wall does not keep cycling the feet. There are
four art-facing directions with turn smoothing and diagonal hysteresis; this
is stylized 2D motion, not a 3D skeletal or motion-capture character.

scripts/player.gd holds movement and presentation. Movement uses a manual
circle/rectangle resolver matching the campaign, with native wall tile
collision also configured for Godot. It does not use move_and_slide.
assets/HackerFrames.tres references 32 new generated walk frames; idle uses a
single pose with a subtle breathing offset. The original character sheet is
retained as a backup. Generated frames can still benefit from manual art QA.

## Controls and gameplay

WASD/arrows move; mouse aims; left click/Space fires; Shift/right mouse holds
Aegis; Q toggles Aegis; E opens the laptop; Escape closes it or pauses;
R retries the current sector. Read amber terminals, run command chips, gather
purple shards, then reach the extraction pad. Shoot R1/R2 receivers to open
linked gates. Aegis reflects enemy bolts and blocks lasers, while consuming
energy. The laptop stops the player but does not pause enemies or the timer.
Touch controls are included; physical phone testing is still needed.

All ten sectors, hacking commands, drones, weapon progression, shield
reflection, laser controls, audio, story and saved campaign progress remain.
Campaign titles/hints/timers come from assets/campaign.json. Scene nodes and
tile layers are authoritative for world geometry and object placement.

## Code and assets

- worlds/Sector_XX.tscn: paintable worlds.
- sectors/Sector_XX.tscn: playable sector wrappers.
- scripts/player.gd: acceleration, braking, collision, gait and sprite motion.
- scripts/game.gd: input, combat, commands, campaign, and wall collision cache.
- scripts/entity.gd: interactive object art, properties and gate collision.
- assets/FuturisticTileSet.tres: non-solid floor/decor atlas.
- assets/SolidWallTileSet.tres: same atlas with collision on every tile.
- assets/HackerFrames.tres: eight-frame walk and idle animation resources.
- assets/hacker_walk_8frames.png: new character sheet.

Saving tile edits in the editor and starting the game rebuilds the game's
wall collision cache from the wall tiles. In-game developer scripts which
change wall cells at runtime should call game.rebuild_wall_collision().
No runtime level editor is included: world editing happens in Godot.

## Verification

Tested with official Godot 4.3 Linux, headless:

- Clean import and scene launch.
- 135 regression assertions across all ten sectors.
- 86 checks for tile painting/erasure, native tile collision, scene save/reload,
  eight-frame resources, acceleration, capped speed, braking, stopping, gait
  distance and no walk cycle when obstructed.
- 41 geometric reachability checks for shards and extraction, with gates open.
  This is not a full puzzle-solution or graphical playthrough test.

Run tests:
  godot --headless --path . --script res://tests/smoke.gd
  godot --headless --path . --script res://tests/tile_movement.gd

Graphical animation review, complete campaign playtesting and phone testing
remain. This ZIP is the editable project, not an EXE or APK.
