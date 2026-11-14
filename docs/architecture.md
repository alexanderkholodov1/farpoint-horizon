# Architecture (v0.1.0)

Everything in the game is built in code. `scenes/main.tscn` holds a single node with `scripts/main.gd` attached.
This describes the v0.1.0 sketch; v0.2.0 rebuilds it per `docs/design/vision.md`. Checked against the code on 2026-11-14.

## Files and roles

| File | Lines | Role |
|---|---|---|
| `project.godot` | | Main scene `res://scenes/main.tscn`; autoload `GameData`; renderer `gl_compatibility` (also for mobile); window 1600x900, stretch mode `canvas_items`, aspect `expand`; `run/flush_stdout_on_print=true` |
| `scripts/game_data.gd` | 250 | Catalogs and balance (autoload `GameData`, extends `Node`): scenarios, buses (platforms), instruments, panels, batteries, comms, ADCS (attitude control), propulsion, orbits, launchers, roles, design steps with CML level, difficulty, CML names. Units are in the file header: kg, W, Wh, millions of USD, GB/day, Mbps, m/s |
| `scripts/mission.gd` | 563 | `Mission` model (extends `RefCounted`). Holds the player's choices; `compute()` returns mass, power, battery, data, delta-v, lifetime, cost, pointing, objectives, expected science, review checks (`fatal`, `warn`, `ok`) and role goals; `science_rate()`; `simulate(seed)` runs the month-by-month events; `score()` gives objectives 400, science 300, efficiency 200, team 100; `real_missions()` |
| `scripts/ship_builder.gd` | 230 | Modular 3D spacecraft from primitives, changing with the chosen parts |
| `scripts/space_builder.gd` | 282 | Sky, Earth (texture and an Ecuador marker), procedural Moon, orbit rings, rocket, launch pad with Andean volcanoes, particles, `Label3D` |
| `scripts/main.gd` | 1609 | UI (theme built in code, Inter font), screen flow, orbital camera, launch animation, simulation playback, report, local ranking in `user://ranking.json` |
| `shaders/` | | `earth`, `clouds`, `atmosphere`, `moon`, `sky`, `solar_cell`, `engine_glow`, and the include `noise.gdshaderinc` |
| `fonts/` | | Inter Regular, SemiBold and Display Bold, with `FONTS_LICENSE.txt` |
| `textures/` | | `earth_albedo.jpg` |
| `tests/fuzz.gd` | 34 | 600 random designs across all scenarios (see below) |
| `tests/autoshot.gd`, `tests/autoshot.tscn` | 90, 6 | Automatic walkthrough that saves screenshots |

Data flow: the UI in `main.gd` edits a `Mission`; every change calls `compute()` and refreshes the dashboard and the
3D ship; launch calls `simulate()`; the report calls `score()`. The numbers all come from `GameData`.

## GDScript notes

- Do not use `class_name`. Scripts are loaded with `preload`, which avoids depending on the editor's class cache.
- Avoid `:=` when the value is a `Variant` (for example a value read from a dictionary): it gives a parse error. Use an explicit type.
- `get_node()` returns `Node`. Type it as `Node3D` before using `.visible`, `.scale` or `.rotate_y`.
- The Inter fonts have no glyphs for the pencil and the heavy X (`✎`, `✕`). They do have the check mark, ballot X, warning sign, star, circle, play triangle and subscript two (`✓ ✗ ⚠ ★ ● ▶ ₂`).
- `main.gd` prints trace lines tagged `[SKH]` at each startup step (`trace()`); remove them before the final delivery if desired.

## Tests

- **Logic fuzz test.** `godot --headless -s res://tests/fuzz.gd` builds 600 random designs with seed 42, calls `compute()` and `simulate(i)` on each, and prints `ok 600 launchable grades {...}`. It fails if any call errors. It asserts no values, only that nothing crashes.
- **Autoshot walkthrough.** Run `tests/autoshot.tscn` with a window (not headless). It plays the whole game (menu, scenarios, design, review, launch, simulation, report, Moon, L2 telescope, forced launch failure, team screen, how-to) and saves 16 PNG screenshots, `01_menu` to `16_howto`, to `/tmp/shots`. The script does not create the folder, so create it first (on Windows `/tmp` resolves under the current drive root). It is for development only.

## Renderer notes

- The project uses `gl_compatibility`, with no 3D MSAA. The first version (Forward+ with Vulkan) crashed on an AMD integrated GPU; see `docs/STATE.md`.
- Rendering features in use that matter when debugging a crash: `Environment` glow (`space_builder.gd`), a `DirectionalLight3D` with shadows (`main.gd`), transparent clouds and atmosphere shaders, a star-loop sky shader (`shaders/sky.gdshader`), and `CPUParticles3D` flames.
- Godot 4.5.1 and 4.7.1 on Linux, and 4.7.2 Steam on Windows (lead's laptop), are the versions on which the project has run.
- The game log is at `%APPDATA%\Godot\app_userdata\SK Horizon - Mission Architect\logs\godot.log`.
