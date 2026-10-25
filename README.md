# MEMORY//BREACH

MEMORY//BREACH is a 2D cyberpunk action game built in Godot. You play as PATCH, exploring a memory archive that has been sealed off by corporate security. The corporation behind the lockdown is trying to erase evidence of what it has done, and the memory shards scattered through the archive are your way of finding the truth.

Elena Vance guides you through the sectors, while AETHER, the system protecting the archive, has its own part in the story. As you recover more fragments, you begin to understand why the archive was locked, who gave the orders, and what is at stake if the memories are lost.

[Play the game](https://aryany-art.github.io/syntax-error-MEMORY-BREACH-/)

## Why MEMORY//BREACH?

The name brings together the two main parts of the game. **Memory** refers to the fragments you recover and the lives recorded inside the archive. **Breach** refers to breaking through its security: opening locked gates, disabling enemies, and finding a route through the network.

The double slash gives the title the feel of a command or a file path, which fits the game's terminals and computer-system setting.

## How the game plays

Each sector asks you to explore its rooms, recover the violet memory shards, unlock the route, and reach extraction before time runs out. Patrols, laser grids, locked gates, and security terminals stand between you and the exit.

You can shoot enemies, use the Aegis shield to block and reflect incoming projectiles, or hack nearby threats. Shield energy is limited and recovers slowly when the shield is lowered, so keeping it raised throughout a fight is not an option.

There are **ten sectors**. The first introduces the controls and basic security systems. Later sectors bring more enemy types, stronger attacks, and routes that require more planning. Your weapons improve as you progress, including faster firing and additional projectiles.

## Hacking with Python

The hacking terminal is part of the game. A protocol gives you two values, `a` and `b`, together with a rule to solve. Challenges include arithmetic progressions, geometric progressions, XOR, and other bitwise operations.

For example, an XOR challenge can be solved with:

```python
print(a ^ b)
```

A correct answer breaches the selected target. The terminal supports Python expressions, printed output, variables, and standard-library imports such as `math`. You can also enter the numeric answer directly.

Python works in the browser through a runtime that loads on first use. Combat and the sector timer wait during that initial download. Once loaded, the interpreter keeps your variables for the session.

## Enemies

Different enemies need different responses:

- **Hover Drones** patrol the sector and fire plasma projectiles.
- **Cyber Stalkers** chase you, wind up, and lunge into close-range attacks.
- **Rail Sentinels** charge a rail shot, giving you a warning before they fire.
- **EMP Wisps** fire spreads that threaten both your health and shield energy.

## KAVYA

KAVYA guards the final sector. She has a large health pool, moves through the arena, and summons drones and bots during the fight. Her reinforcement waves become more frequent below half health.

Defeating her, or successfully breaching her system, releases the final memory shard at her position. You still need to collect it and reach extraction to complete the rescue and see the ending.

## Shards and gems

Violet memory shards are required for progression and reveal the story. The other collectibles help you survive:

- **Repair gems** restore health.
- **Overdrive gems** temporarily increase damage and firing speed.
- **Chrono gems** add time to the sector countdown.

The game also includes animated characters and enemies, a following camera, background music, drone destruction sounds, a victory cue for KAVYA, and red damage and death effects.

## Playing on phone or laptop

The browser version works on supported phones and laptops. Use landscape orientation on a phone. The layout adjusts to different screen shapes, with a movement joystick on the left and separate Fire, Hack, and Shield buttons on the right. Multiple fingers can control movement and combat together.

On a laptop, use WASD or the arrow keys to move, the mouse to aim, and click or Space to fire. Shift or the right mouse button raises the shield, E opens hacking, and R restarts the sector. Fullscreen is available from the browser start screen.

A Windows download is also available on the game's landing page. Windows players need Python 3 installed to run Python commands in the terminal; numeric hacking answers work without it.

## The project

The game is single-player. Its levels use editable tile layers, and the characters, enemies, camera, interface, and gameplay settings can be changed in Godot. The main game uses GDScript, with Python handling the terminal and Pyodide providing Python support in the browser.
