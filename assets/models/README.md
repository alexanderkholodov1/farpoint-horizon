# Models

glTF binaries made by the team in Blender from the Python sources in `assets/source/`. Rebuild one with
`blender -b --factory-startup --python assets/source/<name>.py` (add `-- --render <dir>` for preview PNGs); nobody
needs Blender just to use them. All are original work under the repository's MIT license.

| Model | Size | What it is | Moving parts |
|---|---|---|---|
| `launcher_light.glb`, `launcher_medium.glb`, `launcher_heavy.glb` | 116, 245, 681 KB | Generic launchers at real proportions, no marks: light Electron-type (18 m, black composite, nine engines) [S13]; medium Falcon 9-type (70.9 m, octaweb, grid fins, landing legs, black interstage, 5.2 m fairing) [S14]; heavy Falcon Heavy-type (three cores, 12.2 m wide) [S15]. Origin at the base of the first stage. A warm ring on each first stage is our accent, not a real marking | None. `Space.make_rocket()` scales them to the launch screen |
| `cubesat_3u.glb` | 105 KB | 3U CubeSat at real scale (0.10 x 0.10 x 0.34 m, Godot +Y is the long axis): anodized rails, seven cropped-corner cells per face, four deployable wings, four UHF tape antennas, gold GPS patch, Earth camera at -Y | `Wing_PX`, `Wing_NX`, `Wing_PY`, `Wing_NY` rotate 90 degrees outward about their hinge (origin on the hinge); `Antenna_0..3` scale on local X from 0.06 to 1. Animation `deploy`, 3 s: antennas unroll, then the wings open one after another |

## Sources
IDs refer to `docs/sources.md`.
- CubeSat envelope and rails: [S7].
- Launcher heights, diameters, fairing and engine counts: [S13], [S14], [S15]. Section lengths inside each launcher
  (tank, interstage, second stage) are our estimates from the published total heights: simplified.
- Cell size, cell count per face, wing hinge and the 17 cm whip (a quarter wave at the 437 MHz amateur band) are
  representative of commercial 3U parts, not one product: simplified values.

## Using one in Godot
```gdscript
var sat := preload("res://assets/models/cubesat_3u.glb").instantiate()
add_child(sat)
sat.get_node("AnimationPlayer").play("deploy")
```
CubeSat checked on 2026-11-14 with Godot 4.7.2, Compatibility renderer, AMD Radeon integrated: imports without errors, one
animation `deploy` of 3.0 s, the deployed pose renders as in Blender.
