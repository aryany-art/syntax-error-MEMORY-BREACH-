# Camera setup

Open Main.tscn -> expand CameraRig -> select Camera2D -> click 2D.

The blue camera frame shows the viewport area. In the Inspector, change:
- Zoom: larger numbers bring the world closer (default 1.5).
- Camera Mode: Follow, Fixed or Free.
- Position Smoothing Enabled / Speed: follow responsiveness.
- Look Ahead: aim lead (use 0 for a centered view).
- Shake Enabled: turn camera shake on/off.

Save, press F5, and test. F1 free camera, F2 overview, F3 follow.
I/J/K/L or middle-drag pans free camera. Mouse wheel adjusts zoom.

For shared defaults, open scenes/CameraRig.tscn.
For level limits, open a worlds/Sector_XX.tscn file and select its World root.
Camera Bounds is editable there. UI remains fixed on screen during camera motion.

This project is 2D; Zoom is the equivalent framing control instead of 3D FOV.
