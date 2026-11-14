# Models

glTF binaries made by the team in Blender from the Python sources in `assets/source/`. Rebuild one with
`blender -b --factory-startup --python assets/source/<name>.py` (add `-- --render <dir>` for preview PNGs); nobody
needs Blender just to use them. All are original work under the repository's MIT license.

| Model | Size | What it is | Moving parts |
|---|---|---|---|
| `cubesat_3u.glb` | 105 KB | 3U CubeSat at real scale (0.10 x 0.10 x 0.34 m, Godot +Y is the long axis): anodized rails, seven cropped-corner cells per face, four deployable wings, four UHF tape antennas, gold GPS patch, Earth camera at -Y | `Wing_PX`, `Wing_NX`, `Wing_PY`, `Wing_NY` rotate 90 degrees outward about their hinge (origin on the hinge); `Antenna_0..3` scale on local X from 0.06 to 1. Animation `deploy`, 3 s: antennas unroll, then the wings open one after another |

## Sources
- Envelope and rails: CubeSat Design Specification Rev 14, Cal Poly, 2022
  (https://www.nasa.gov/wp-content/uploads/2018/01/cubesatdesignspecificationrev14_12022-02-09.pdf, also cited in
  `kb/data/reference.json`).
- Cell size, cell count per face, wing hinge and the 17 cm whip (a quarter wave at the 437 MHz amateur band) are
  representative of commercial 3U parts, not one product: simplified values.

## Using one in Godot
```gdscript
var sat := preload("res://assets/models/cubesat_3u.glb").instantiate()
add_child(sat)
sat.get_node("AnimationPlayer").play("deploy")
```
Checked on 2026-11-14 with Godot 4.7.2, Compatibility renderer, AMD Radeon integrated: imports without errors, one
animation `deploy` of 3.0 s, the deployed pose renders as in Blender.
