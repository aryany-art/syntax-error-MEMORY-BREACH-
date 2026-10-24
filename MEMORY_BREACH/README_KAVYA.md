KAVYA PROTOCOL — HARD MODE

Import project.godot in Godot 4.3+. Enemy hull is 4x the previous edition.
Starting shield is 50%; later sector transitions restore it fully. There is no passive energy regeneration: use Aegis crystals.
Weapon damage, rate and projectile-speed scaling stop after tier 3; multishot is capped at two barrels (temporary overdrive remains available).

HACKING: read a terminal, press E, choose BREACH. Solve one numeric challenge using Python if desired: arithmetic, XOR, then bitwise logic. Wrong answers reset the sequence. Nearby enemies expose BREACH buttons too; one protocol must pass and the target must remain within 140 units. No arbitrary Python code executes in the game.

Developer cheats are OFF by default. Select the Main root and enable Developer Cheats Enabled to use drone.mode = sleep, heal and overclock. Sleep includes KAVYA. Valid protocol breaches can also disable enemies without developer mode.

Final sector: KAVYA has 20 times the actual final-sector drone hull. She summons drones and stalkers, faster below half health. Defeat or protocol-disable her, collect required memories and extract. Her original synthesized 16-second entry score plays on sector start.

All prior tile layers and editable scenes remain available. Godot 4.3 import and 12 focused hard-mode assertions passed. Older regression tests assume direct commands and previous balance, so are not valid unchanged. Full graphical playtesting and difficulty tuning remain. The final-sector timer is 900 seconds to accommodate the new boss hull.
