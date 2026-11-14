# Architecture

Everything in the game is built in code. `scenes/main.tscn` holds a single node with `scripts/main.gd` attached: a
small flow controller that owns the 3D world and the UI root and switches screens. Each screen is its own script in
`scripts/screens/`, so several people can build different screens without touching the same file. Checked against the
code on 2026-11-14.

## Files and roles

| File | Lines | Role |
|---|---|---|
| `project.godot` | | Main scene `res://scenes/main.tscn`; autoloads `GameData` then `GameState`; renderer `gl_compatibility` (also for mobile); window 1600x900, stretch mode `canvas_items`, aspect `expand`; `run/flush_stdout_on_print=true` |
| `scripts/main.gd` | 127 | Flow controller: creates the world and the UI root (theme, fade layer), keeps the registry of screens and overlays (`SCREENS`, `OVERLAYS`), and switches them: `go(id, args)`, `go_faded(id, out, in, args)`, `overlay(id)`, `fade()`, `launch()`. Each frame it updates the world, then the current screen |
| `scripts/game_state.gd` | 134 | Autoload `GameState`: the shared state of the game being played (below) and its rules: `start_solo`, `set_team`, `start_mission`, `can_launch`, `begin_flight`, `approve_all`, the local ranking, `trace()` |
| `scripts/world.gd` | 277 | The 3D world every screen shares: sky, lights, the orbital camera (mouse drag and wheel), and the stage. Ready stages: `stage_menu`, `stage_design` with `rebuild_ship`, `stage_orbit`, `stage_earth`; `clear_stage()` for a screen that builds its own; `lose_ship()`; `cam_free` |
| `scripts/ui/kit.gd` | 256 | The UI kit, all static: colors `C_*`, fonts `FONT_R/B/T`, `build_theme()`, `flat()` style boxes, `place()` anchors, `lbl`, `btn`, `accent_btn`, `panel_box`, `vbox`, `hbox`, `spacer`, `card`, `toast`, `overlay`, and number formatting `pct`, `money`, `kg`, `watts`, `gb`, `mins` |
| `scripts/screens/screen.gd` | 51 | The base every screen and overlay extends: `enter(args)`, `exit()`, `process(delta)`, `go()`, `clear()`, `toast()`; the members `main`, `world`, `mission` and the constants `Kit`, `World` |
| `scripts/screens/menu.gd` | 42 | Main menu: one player or a team, difficulty, how to play, ranking |
| `scripts/screens/team.gd` | 75 | Team setup: number of players, then names and roles (`ROLE_SPLIT`). `args.players` opens the names step |
| `scripts/screens/missions.gd` | 51 | Choice of the scenario (CML 1) |
| `scripts/screens/design.gd` | 378 | The eight design steps (CML 2-4), the review with the team's approvals, the mission dashboard, the "why it matters" box. `args.step` is the step |
| `scripts/screens/launch.gd` | 121 | Countdown, liftoff from the pad, ascent or the launcher's failure; it drives the camera itself |
| `scripts/screens/operation.gd` | 133 | Month-by-month playback of `GameState.last_sim`: mission log, time and science bars, speed controls |
| `scripts/screens/report.gd` | 143 | Grade, score, what happened and why, real missions like it; redesign, fly again, new mission, save to the ranking |
| `scripts/screens/ranking.gd`, `howto.gd` | 26, 33 | Overlays: the local ranking, how to play |
| `scripts/game_data.gd` | 250 | Catalogs and balance (autoload `GameData`, extends `Node`): scenarios, buses (platforms), instruments, panels, batteries, comms, ADCS (attitude control), propulsion, orbits, launchers, roles, design steps with CML level, difficulty, CML names. Units are in the file header: kg, W, Wh, millions of USD, GB/day, Mbps, m/s |
| `scripts/mission.gd` | 563 | `Mission` model (extends `RefCounted`). Holds the player's choices; `compute()` returns mass, power, battery, data, delta-v, lifetime, cost, pointing, objectives, expected science, review checks (`fatal`, `warn`, `ok`) and role goals; `science_rate()`; `simulate(seed)` runs the month-by-month events; `score()` gives objectives 400, science 300, efficiency 200, team 100; `real_missions()` |
| `scripts/ship_builder.gd` | 230 | Modular 3D spacecraft from primitives, changing with the chosen parts |
| `scripts/space_builder.gd` | 282 | Sky, Earth (texture and an Ecuador marker), procedural Moon, orbit rings, rocket, launch pad with Andean volcanoes, particles, `Label3D` |
| `shaders/` | | `earth`, `clouds`, `atmosphere`, `moon`, `sky`, `solar_cell`, `engine_glow`, and the include `noise.gdshaderinc` |
| `fonts/` | | Inter Regular, SemiBold and Display Bold, with `FONTS_LICENSE.txt` |
| `textures/` | | `earth_albedo.jpg` |
| `tests/fuzz.gd` | 34 | 600 random designs across all scenarios (see below) |
| `tests/autoshot.gd`, `tests/autoshot.tscn` | 97, 6 | Automatic walkthrough that saves screenshots |

Node tree at run time: `Main` (main.gd) holds `World` (world.gd: environment, lights, camera, `stage`), the UI
`CanvasLayer` with the themed root `Control`, and a top `CanvasLayer` with the fade rectangle. The current screen is a
full-window `Control` under the UI root; an overlay is a child of the current screen.

Data flow: a screen edits `GameState.mission`; every design change calls `compute()`, redraws the design screen and
rebuilds the 3D craft (`world.rebuild_ship()`); `main.launch()` calls `GameState.begin_flight()`, which runs
`simulate()`; the operation screen plays back `GameState.last_sim`; the report reads its `score`. The numbers all come
from `GameData`.

## Screens

A screen is a script in `scripts/screens/` that extends `screen.gd`. `main.go(id, args)` frees the current screen (and
with it all of its UI: widgets, toasts, overlays), resets `world.cam_free` to true, creates the new screen, sets
`GameState.phase = id` and calls `enter(args)`. Every frame `main.gd` calls `world.update(delta)` and then the current
screen's `process(delta)`. `exit()` is called just before a screen is freed.

What a screen can use:
- `Kit` for every widget and number format, so all screens look alike (`Kit.lbl`, `Kit.btn`, `Kit.C_ACCENT`...).
- `world` for the 3D view: pick a ready stage (`world.stage_orbit()`) or `world.clear_stage()` and add nodes to
  `world.stage`. A screen that moves the camera itself sets `world.cam_free = false` in `enter()`.
- `main` for the flow: `go(id, args)` or the screen's own `go()`, `main.go_faded(id, out, in)` for a fade to black,
  `main.overlay(id)`, `main.launch()`.
- `GameState` for everything that outlives a screen; `mission` is a shortcut for `GameState.mission`.

How to add a screen:
1. Create `scripts/screens/<id>.gd` starting with `extends "res://scripts/screens/screen.gd"` and a `##` comment that
   says what the player does there and which `args` it takes.
2. Build its UI in `enter(args)` with `add_child()` and `Kit`; to redraw, call `clear()` and build again. Put per-frame
   work in `process(delta)`.
3. Register it: one line in `SCREENS` (or `OVERLAYS` for an overlay) in `scripts/main.gd`. That `preload` also makes a
   parse error in the screen fail `tools/check.sh` at once.
4. Reach it from another screen with `go("<id>", {...})`; keep what other screens need in `GameState`, not in the
   screen, since the screen is freed when the player leaves it.
5. Add it to `tests/autoshot.gd` with a screenshot, run the walkthrough and look at the picture.

Rules that keep screens apart:
- A screen owns its file(s) and its UI; it never reaches into another screen. Shared values go through `GameState`;
  shared widgets go into `Kit`; shared 3D scenes go into `world.gd`.
- Content and balance stay in data (`GameData`), not in screens.
- Do not `await` in a screen after a call that may change screen: the screen is freed at the end of that frame. To act
  on the next frame, connect to `get_tree().process_frame` with `CONNECT_ONE_SHOT` (see `operation.gd`); the
  connection is dropped if the screen is freed first.

## GameState

The autoload `GameState` (`scripts/game_state.gd`) holds what lives across screens:

| Member | What it is |
|---|---|
| `mission` | The `Mission` being designed (`scripts/mission.gd`); `start_mission(scenario)` replaces it with the scenario's starting parts and keeps the difficulty |
| `difficulty` | The difficulty id of `GameData.DIFFICULTY`; it is stored in `mission.difficulty` because the numbers use it |
| `players`, `team_mode` | The team: `[{"name", "roles"}]`; `team_mode` is true for 2 to 4 players. `start_solo()`, `set_team(list)`, `player_for_role(role)` |
| `approvals` | Role id to true once that role signed off the design; any design change clears it. `all_approved()`, `approve_all()` |
| `phase` | The id of the current screen, set by `main.go()` |
| `last_report`, `last_sim` | `mission.compute()` and `mission.simulate()` of the last launch (`begin_flight(r)`); the sim holds events, timeline, months and `score` |
| `ranking`, `saved_to_ranking` | Local ranking in `user://ranking.json`, best first; `add_ranking()` saves it |

It emits `changed` whenever its methods or setters change something; a screen that edits `mission` directly emits it
after the edit (`design.gd` does in `on_change()`). Nothing listens yet; the shared room (plan step B3) will.

## GDScript notes

- Do not use `class_name`. Scripts are loaded with `preload`, which avoids depending on the editor's class cache.
  Screens extend their base by path: `extends "res://scripts/screens/screen.gd"`.
- Avoid `:=` when the value is a `Variant` (for example a value read from a dictionary, or from the untyped `main`
  and `mission`): it gives a parse error. Use an explicit type.
- `get_node()` returns `Node`. Type it as `Node3D` before using `.visible`, `.scale` or `.rotate_y`.
- The Inter fonts have no glyphs for the pencil and the heavy X (`✎`, `✕`). They do have the check mark, ballot X, warning sign, star, circle, play triangle and subscript two (`✓ ✗ ⚠ ★ ● ▶ ₂`).
- Startup prints trace lines tagged `[SKH]` (`GameState.trace()`, called from `main.gd` and `world.gd`); remove them before the final delivery if desired.
- A script run with `-s` from outside the project cannot name autoloads at compile time; get them with `root.get_node("GameState")`.

## Tests

- **Logic fuzz test.** `godot --headless -s res://tests/fuzz.gd` builds 600 random designs with seed 42, calls `compute()` and `simulate(i)` on each, and prints `ok 600 launchable grades {...}`. It fails if any call errors. It asserts no values, only that nothing crashes.
- **Autoshot walkthrough.** Run `tests/autoshot.tscn` with a window (not headless): `tools/shots.sh`, or Godot with `--path . --position 4000,4000 --resolution 1600x900 res://tests/autoshot.tscn` to keep the window off screen. It drives the game as the buttons do (`GameState` for the choices, `go()` and `overlay()` for the flow) through menu, scenarios, design, review, launch, operation, report, Moon, L2 telescope, a forced launch failure, the team screen and how to play, and saves 16 PNG screenshots, `01_menu` to `16_howto`, to `shots/` in the project (created if missing; ignored by git and by the web export). It is for development only.

## Renderer notes

- The project uses `gl_compatibility`, with no 3D MSAA. The first version (Forward+ with Vulkan) crashed on an AMD integrated GPU; see `docs/STATE.md`.
- Rendering features in use that matter when debugging a crash: `Environment` glow (`space_builder.gd`), a `DirectionalLight3D` with shadows (`world.gd`), transparent clouds and atmosphere shaders, a star-loop sky shader (`shaders/sky.gdshader`), and `CPUParticles3D` flames.
- Godot 4.5.1 and 4.7.1 on Linux, and 4.7.2 Steam on Windows (lead's laptop), are the versions on which the project has run.
- The game log is at `%APPDATA%\Godot\app_userdata\SK Horizon - Mission Architect\logs\godot.log`.
