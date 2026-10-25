# Browser Python update
The hosted browser terminal now runs actual Python in a lazy-loaded Pyodide module worker.
Use print(a ^ b) for an XOR puzzle, or the expression shown by the current protocol.
Imports such as math and session variables work. Invalid names produce normal Python errors.
The first runtime download waits with combat and the timer paused; code execution is limited to five seconds.
A timeout resets session variables. input() is unavailable.
The worker executes on the player's device; GitHub Pages does not execute submitted code.
Browser builds are produced by tools/build_pages.py, which copies the worker and evaluator beside the game.

# MEMORY//BREACH
Open project.godot in Godot 4.3 or newer and press F5.

Audio update:
- Original 35.6-second looping cyberpunk background theme during sectors.
- Drone destruction effect only on a lethal hit, including reflected shots.
- Original victory fanfare once when KAVYA is defeated or legitimately breached and releases the final shard.
- Existing KAVYA entrance music retained; background music ducks during the entrance and victory fanfare.
- Music stops on game over and extraction. Retry/sector transitions reset playback.
- Select settings/Gameplay.tres to adjust Music Volume Db and Effects Volume Db.

The source project is fully editable. Earlier guides below may mention previous project names.

# Dialogue cleanup
Sector briefings now contain mission summaries only. Arrival dialogue plays in the story panel, and the hint appears once below the summary. This removes the repeated final line in Sector 1 and the duplicated opening conversations across all ten sectors.
Story transmissions are suppressed when triggered again during the same campaign, including sector retries. Choosing NEW CAMPAIGN clears the history so the story can be experienced again. Ordinary controls, objectives and gameplay notifications can still repeat when needed.
Scene story text and reference JSON are synchronized.

# Final shard and walking update
KAVYA releases a glowing final memory shard at her defeat position. It is reserved in the shard counter but cannot be collected before defeating her. A legitimate protocol breach also counts as defeating her. Collect every shard including this one, then reach extraction to see the finale. Restarting the sector resets the drop.
Walking now preserves the selected eight-frame pose instead of resetting it every render frame. Gait follows actual distance travelled, with speed-blended bob and sway, smoother stops, and directional facing. Feet stop cycling when blocked by walls.
Previous enemy range/HP changes and mobile KAVYA are included.
Open project.godot in Godot 4.3+. Play_Sector_10.tscn launches the final sector.
The following earlier notes may contain superseded details.

# Enemy movement and range update
- All enemy detection ranges and rail range increased 25%, including saved scene overrides.
- Stalker lunge range and duration increased 25%, retaining its windup and recovery.
- Drone and stalker HP increased exactly 25% relative to the previous rebalance.
- KAVYA retains her previous HP. She now patrols and pursues through valid arena tiles at 85 / 115 pixels per second.
- KAVYA uses her existing artwork with procedural hover, banking, breathing pulse, firing recoil, and animated thrusters.
- Reinforcement health follows its own enemy type.
- Longer-lived enemy projectiles support the increased engagement range.
- Walls, locked gates, and editable EnemyPatrolTiles still restrict movement.
Open project.godot with Godot 4.3+. Run Main.tscn or Play_Sector_10.tscn to try KAVYA.
This is the complete project; extract into a fresh folder first.
Earlier guides below may describe superseded balance values.

# MEMORY//BREACH — balance update

Extract into a NEW folder, import project.godot in Godot 4.3+, press F5.
Use Play_Sector_07.tscn or Play_Sector_10.tscn with F6 for direct sector tests.

CURRENT BALANCE
- Player hull: 200 (previously 100), displayed as current/max HP in the HUD.
- Every enemy starts with half the previous build's health. KAVYA is also
  halved and remains 20 times the current final-sector drone health.
- Weapon upgrades automatically progress across all ten sectors again:
  damage and bullet speed increase, cooldown shortens, two shots begin at
  sector 4, three at sector 8. The previous tier-three cap is removed.
- Shield regenerates at 6 energy/second when not raised, versus the earlier
  original 27/second. Active shield still drains energy. Initial shield is
  still 50%; sector transitions restore it fully.
- Shield-restoring crystals are removed from all saved maps. Older imported
  Aegis gem objects are ignored at runtime. Repair, overdrive, chrono and
  required memory collectibles remain.

SECRET DEVELOPER COMMAND
While the game has focus, press Ctrl+Shift+F12 to toggle developer commands.
Then press E and enter:
  drone.mode = sleep

All non-boss robots/enemies are disabled. KAVYA is unaffected. This command
needs no puzzle and is handled as a game command, not executed as Python.
Press Ctrl+Shift+F12 again to disable developer commands. You may alternatively
set Developer Cheats Enabled on the Main root Inspector. It defaults to OFF.
KAVYA may still be disabled through the existing legitimate one-protocol boss
breach; immunity here applies specifically to the developer global sleep cheat.
Other existing developer commands are retained when developer mode is enabled.

The actual Python interpreter, one-protocol hacking, 50-lock green visuals,
editable tiles, camera controls, story, death effect and Sector 7/10 fixes are
retained. Python 3 must be installed for actual Python statements. Numeric
puzzle answers work without Python startup. Code executes with normal local
user permissions, so use trusted code only.

VERIFICATION
Godot 4.3 import and 117 rebalance assertions passed across all ten sectors.
Sector 7/10 tests passed 2036 collision/loading/hacking/completion checks.
Actual-Python imports, persistent variables, stdout/errors and gate breach
integration test passed. Graphical playtesting and difficulty tuning remain.
Other included guides/test counts describe previous versions; this README is
current for balance and cheat behaviour.

Validation: Godot 4.3 headless import; 195 movement/range/health checks; 117 balance checks; 2036 sector regression checks; actual Python terminal checks. Visual and Windows playtesting still required.

Current validation: Godot 4.3 import, 18 final-shard/walking checks, 195 enemy checks, 117 balance checks, 2036 sector checks, and real Python terminal checks passed. Graphical playtesting remains.
