# Echoes of AETHER — new content and editing guide

Extract into a NEW folder, import project.godot with Godot 4.3+, then press F5.
This is the editable project source, not an EXE/APK. The previous ten-sector
campaign layout, camera, UI, random patrol navigation and hacking are retained.

## Four enemy types

| Enemy | Behaviour | Player response |
|---|---|---|
| Hover Drone | Random patrol and plasma fire | Shoot, reflect bolts, or sleep |
| Cyber Stalker | Chase, visible warning, committed lunge, recovery | Dodge or shield |
| Rail Sentinel | Stationary turret, orange aim warning, locked rail shot | Move out of the warning line; shield blocks at an energy cost |
| EMP Wisp | Random patrol, three-way cyan EMP bursts | Dodge or reflect; EMP hits drain hull and shield energy |

Each sector has a Sentinel and Wisp as well as the previous drone/stalker
population. Rail Sentinel does not wander; its stationary placement is
intentional. Its aim locks during charge, giving you time to dodge. Its beam
stops at walls or closed gates. Aegis blocks the rail shot rather than reflecting
it. EMP bolts reflect normally, with an additional shield-energy cost.

Open scenes/entities/RailSentinel.tscn or EMPWisp.tscn to edit graphics.
EnemySprite uses assets/AdvancedEnemyFrames.tres and threats_and_gems.png.
Select the enemy root for Rail Charge Time, Damage, Range, Cooldown or EMP
Damage, Energy Drain and Cooldown. Add these scenes inside the matching
Sentinels or Wisps group in a world. The existing enemy scripts and navigation
remain separate from world floor art.

## Five collectible styles

| Collectible | Default benefit | Required to finish? |
|---|---|---|
| Violet memory shard | Recovers a mission memory; first one reveals story | Yes, all violet shards |
| Green repair gem | +25 hull, capped at maximum hull | No |
| Cyan Aegis gem | +35 shield energy, capped at maximum | No |
| Amber overdrive gem | +2 weapon damage and 30% shorter fire interval for 10 seconds | No |
| Pale-blue chrono gem | +20 seconds on the sector timer | No |

Optional gems disappear once collected and cannot be collected twice. They are
consumed on contact, even if a resource is already full. Overdrive expires and
is cleared between sectors. Picking up another overdrive gem refreshes to at
least its configured duration. Optional gems do not unlock extraction; violet
memory shards still do that.

Open a world, expand Gems, select a collectible, and change Gem Type, Pickup
Amount or Buff Duration. Move or duplicate it as desired. The reusable scene
is scenes/entities/Gem.tscn; the behaviour is scripts/gem.gd. Keep optional gems
inside Gems and required violet memories inside Shards. Required shards use
the existing environment art; optional gems use the new atlas.

## Red death and damage effects

When the run fails, a red vignette fades over the full screen and the character
turns red and falls. Smaller damage flashes use the same screen effect. The
retry menu is drawn above it and remains clickable. Restarting clears the tint
and creates a fresh player. Timeout also uses the failure tint.

Open scenes/ui/GameUI.tscn, select DeathOverlay, and adjust Maximum Opacity or
Fade Speed. Set Maximum Opacity to 0 to disable the screen tint if desired.
The shader is assets/death_vignette.gdshader; behaviour is death_effect.gd.
No rapid strobe is used; the sustained tint has a small slow intensity pulse.

## Edit every world tile

1. Open worlds/Sector_01.tscn in FileSystem.
2. Click the 2D workspace.
3. Select FloorTiles, WallTiles, DecorationTiles or EnemyPatrolTiles.
4. Open TileMap at the bottom and select an atlas tile.
5. Paint with the brush; erase with the eraser/right mouse button.
6. Ctrl+S saves the world. F5 tests the campaign.

FloorTiles and DecorationTiles change the background. Every tile painted on
WallTiles is solid; erasing removes collision. EnemyPatrolTiles specifies where
mobile enemies may travel, and is hidden during play. A patrol tile grants
permission; an erased patrol cell forbids it. Patrol Bounds on each enemy also
limit its routes. All layers share a 24px world grid and expose all 64 atlas
tiles. Leave the layer scales unchanged to keep them aligned.

Gates, terminals, gems, enemies and extraction are interactive scene nodes
rather than floor tiles. Select them in the Scene tree to move them and change
properties. Main.tscn is a launcher: save layout changes in worlds/ scenes,
not overrides on its World instance. sectors/Sector_XX.tscn are runnable sector
wrappers for F6. Enlarging maps beyond the current 960x600 area still requires
updating navigation region and camera bounds.

## Story and authoring

The player is PATCH, a maintenance intelligence awakened inside a city memory
archive. Elena Vance guides the escape, AETHER appears hostile, and corporate
executive Yarrow insists the archive is dangerous. Memory fragments gradually
show whose orders caused the crisis. The arc links consent, identity and rescue
with the existing hacking actions. It ends with Elena's restoration into
Bot_404 and a new role for PATCH. Full spoilers are in STORY.md.

There are three delivery moments per sector:
- Arrival: a non-blocking transmission after ENTER SECTOR.
- Memory: a revelation when the first required violet shard is recovered.
- Completion: the chapter conclusion in the sector-clear modal.

Select a World root to edit Briefing, Arrival Message, Memory Fragment and
Completion Text. These saved scene fields are used at runtime. assets/story.json
is a reference copy of the authored script; modifying that file alone does not
replace the World Inspector values. StoryPanel in GameUI.tscn controls the
transmission layout. This is text dialogue; no recorded voice-over or branching
ending system is included.

## Validation

Official Godot 4.3 headless import and launch passed. 625 assertions passed:
170 campaign, 86 tile/movement, 30 camera/UI, 166 enemy and 173 expansion checks.
These cover four enemy types, rail warning/dodge/blocking, EMP drain/reflection,
four optional gems, temporary boost expiry, one-time pickups, required shards,
full-viewport death overlay, reset, retry layering, story triggers, saved scene
fields and all 40 optional gems reachable with gates open.

Graphical review of art, shaders and animation, difficulty balancing, a complete
puzzle playthrough and phone testing are still needed. Passing headless checks
does not replace those reviews. All required tests are in tests/.
