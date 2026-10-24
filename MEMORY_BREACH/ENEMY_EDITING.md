# Enemy editing reference

This guide describes the original drone and stalker systems. See
EXPANSION_GUIDE.md for Rail Sentinel, EMP Wisp, gems and story additions.
The project now contains four enemy types in every sector.

## Original enemy systems

Open project.godot with Godot 4.3+. Use a new extracted folder so your earlier
project remains intact. This package is source, not an EXE/APK.

## What changed

The original simple drone drawing has been replaced with animated cyberpunk
hover-drone artwork. It chooses random tile routes, turns toward its movement,
and fires plasma only when it has a clear line of sight. Nearby walls and
closed gates block both movement and firing. Hover and attack use separate
animation sequences. Drones sleep when the existing sleep command is run.

Cyber Stalker is a second enemy: a four-legged robotic predator with violet
lighting. It patrols at random, chases the player when visible inside its
patrol bounds, displays a magenta warning ring and direction, then lunges.
It pauses to recover after attacking. Shooting damages/stuns it; Aegis blocks
its melee hit at an energy cost. The sleep command disables both enemy types.

All ten sectors retain the original drone count plus one stalker; sectors
6-10 include two stalkers. Each sector now also contains a Rail Sentinel and EMP Wisp. Spawn positions are adjusted to the nearest valid
patrol cell if the scene marker is inside a wall/forbidden cell. The original
campaign paths, gates, camera controls and tile editing remain available.

## Separate background and movement layers

Open worlds/Sector_01.tscn, click 2D, and select the desired layer:

| Layer | Meaning |
|---|---|
| FloorTiles | Background floor art; now includes grates, circuit panels and warning accents |
| DecorationTiles | Non-solid environmental art on top of the floor |
| WallTiles | Solid walls; painting/erasing updates collision |
| EnemyPatrolTiles | Enemy movement permission; paint cells where enemies may travel |

EnemyPatrolTiles appears as a translucent green overlay in the world editor.
It is automatically hidden by the gameplay controller. Any tile painted on
this layer means ALLOWED; the chosen atlas picture does not change its meaning.
An erased cell is forbidden to enemies. Removing every patrol tile freezes
patrol movement. It does not prevent the player from walking there.

Enemies also require an existing floor tile, clearance from walls/gates, and
an appropriate Patrol Bounds rectangle. A clear route is required between
waypoints, so isolated patrol islands do not teleport an enemy between them.

To let a drone explore more of the map, expand BOTH its Patrol Bounds in the
Inspector and the painted EnemyPatrolTiles area. The default drone bounds
retain their original sector rooms; stalkers have wider bounds. Random targets
are chosen within bounds and valid routes remain inside those bounds.
The navigation grid currently covers the 960x600 map on a 24px grid. Expanding
the world beyond this size requires changing the grid region in
scripts/enemy_navigation.gd, in addition to the camera/world bounds.

## Enemy placement and settings

Expand World > Drones or World > Stalkers to select an enemy.

- Patrol Speed / Speed Gain Per Sector: random patrol speed and progression.
- Retarget Min / Max: how often random patrol goals can change.
- Patrol Bounds: allowed waypoint/route rectangle, in world-local coordinates.
- Base Health: hull before sector scaling.
- Detection Range: distance for detecting the player.
- Shot Damage / Fire Interval / Projectile Speed: hover-drone combat settings.
- Chase Speed / Attack Range: stalker pursuit and attack triggering.
- Windup Time / Lunge Speed / Lunge Duration / Recovery Time: stalker attack feel.
- Melee Damage: stalker strike strength.
- Body Radius: movement clearance; stay at or below the navigation clearance
  of 14 unless you also update clearance logic in enemy_navigation.gd.

Patrol Velocity is a retained legacy property; random movement now uses Patrol
Speed and the waypoint system. Background appearance does not control AI speed.

To add enemies, drag scenes/entities/Drone.tscn into the Drones group or
scenes/entities/CyberStalker.tscn into Stalkers. Set its position, bounds and
properties. You may duplicate an existing enemy in its group instead.

## Edit graphics and animation

Open scenes/entities/Drone.tscn or CyberStalker.tscn. Select EnemySprite to
inspect AnimatedSprite2D. Its SpriteFrames resource is assets/EnemyFrames.tres:

- drone_hover: four hover frames.
- drone_fire: four firing/recoil frames.
- stalker_walk: four crawling frames.
- stalker_attack: four charge/swipe/recovery frames.

Frames reference the untouched generated assets/cyberpunk_enemies.png through
AtlasTexture regions. Both creatures face right in the source; sprites rotate
toward movement/attack direction. The sheet is generated art and may need
manual alignment/edge polish after graphical animation review.

The Use Tile Art toggle is a fallback for using the object's environment Tile
property; leave it off for the new animated enemy sprites.

## Code locations

- scripts/enemy.gd: exposed settings, sprite animation and warning effects.
- scripts/enemy_navigation.gd: shared AStarGrid2D, random destinations, mask
  permission, clearance and collision-safe movement.
- scripts/game.gd: enemy state transitions, drone shooting, stalker melee,
  damage and existing game coordination.

Opening a gate or rebuilding painted wall collision rebuilds navigation. If
custom code paints EnemyPatrolTiles at runtime, call enemy_nav.rebuild(game)
afterward. Editor changes are picked up when the saved world is loaded.
No autonomous runtime level editor or networking is included.

## Verification

For current test results, see README.md. The original enemy tests have been
extended for the additional enemy types.
Enemy-specific checks simulate six seconds in each of ten maps, verify no
wall/gate overlaps and no forbidden patrol cells, confirm varied random goals,
and cover both graphics resources, mask removal, sleep, gate navigation
updates, line of sight, stalker warning/lunge/recovery and shield blocking.

The background, camera view and animation still need a graphical playthrough.
A full campaign difficulty/solvability pass and phone testing remain necessary.
