# MEMORY//BREACH

MEMORY//BREACH is a cyberpunk action and hacking game built in Godot. Play as PATCH,
recover stolen memories, breach security systems, and face KAVYA.

[Play in your browser](https://aryany-art.github.io/syntax-error-MEMORY-BREACH-/)

Phones use landscape orientation and on-screen touch controls. Laptops support
keyboard and mouse. The landing page also provides a Windows download.

## Deployment
GitHub Actions builds the browser and Windows versions from MEMORY_BREACH/.
Enable **Settings > Pages > Source: GitHub Actions** once. The included workflow
then publishes the site after changes to the game, build tools, or workflow on main.
No continuously running PC or tunnel is needed once Pages deployment completes.

## Development
Import MEMORY_BREACH/project.godot into Godot 4.3 or newer.
All ten sectors, graphics, scripts, music and sound effects are editable.
Browser builds accept numeric hacking answers. Actual Python commands work in
the Windows download when the player has Python 3 installed.

The build preserves the original WAV music in the source and converts it to Ogg
in a temporary build copy. Mobile multi-touch and navigation optimizations are included.

## Screen and touch controls
The game expands its 16:9 base viewport to fit different screen shapes without
stretching sprites. Click **Play fullscreen** on the browser start screen, or use
the Fullscreen button during play. Native Windows builds support F11.

On phones, use the left analog joystick to move. FIRE is at the bottom right,
SHIELD is beside it, and HACK is above. Separate fingers can move, fire and shield
at once. Controls account for display cutouts; the hacking input moves above the
on-screen keyboard. Rotate to landscape; the sector timer waits in portrait.
