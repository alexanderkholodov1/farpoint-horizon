# Models (C7)

- `assets/models/cubesat_3u.glb`: a 3U CubeSat at real scale with four wings and four antennas that deploy (animation
  `deploy`), built from `assets/source/cubesat_3u.py`. Not yet used by any screen; see `assets/models/README.md`.
- `assets/models/launcher_light|medium|heavy.glb`: modeled launchers at real proportions [S13-S15], built from
  `assets/source/launchers.py`, now on the launch screen (`Space.make_rocket()`), replacing the primitive rocket at the
  same size on the pad. Checked: `tools/check.sh` green, `tools/shots.sh` launch screenshots, and all three rendered
  in Godot through `make_rocket()` (heights 3.84, 6.24, 7.2 as before; flames 2, 2, 4).
