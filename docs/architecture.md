# Architecture

Everything in the game is built in code. `scenes/main.tscn` holds a single node with `scripts/main.gd` attached: a
small flow controller that owns the 3D world and the UI root and switches screens. Each screen is its own script in
`scripts/screens/`, so several people can build different screens without touching the same file. Checked against the
code on 2026-11-14.

## Files and roles

| File | Lines | Role |
|---|---|---|
| `project.godot` | | Project name Farpoint HORIZON; main scene `res://scenes/main.tscn`; English fallback locale and the Spanish translation table; autoloads `GameData` then `GameState`; renderer `gl_compatibility` (also for mobile); window 1600x900, stretch mode `canvas_items`, aspect `expand`; `run/flush_stdout_on_print=true` |
| `scripts/main.gd` | 127 | Flow controller: creates the world and the UI root (theme, fade layer), keeps the registry of screens and overlays (`SCREENS`, `OVERLAYS`), and switches them: `go(id, args)`, `go_faded(id, out, in, args)`, `overlay(id)`, `fade()`, `launch()`. Each frame it updates the world, then the current screen |
| `scripts/game_state.gd` | 134 | Autoload `GameState`: the shared state of the game being played (below) and its rules: `start_solo`, `set_team`, `start_mission`, `can_launch`, `begin_flight`, `approve_all`, the local ranking, `trace()` |
| `scripts/world.gd` | 277 | The 3D world every screen shares: sky, lights, the orbital camera (mouse drag and wheel), and the stage. Ready stages: `stage_menu`, `stage_design` with `rebuild_ship`, `stage_orbit`, `stage_earth`; `clear_stage()` for a screen that builds its own; `lose_ship()`; `cam_free` |
| `scripts/ui/kit.gd` | 256 | The UI kit, all static: colors `C_*`, fonts `FONT_R/B/T`, `build_theme()`, `flat()` style boxes, `place()` anchors, `lbl`, `btn`, `accent_btn`, `panel_box`, `vbox`, `hbox`, `spacer`, `card`, `toast`, `overlay`, and number formatting `pct`, `money`, `kg`, `watts`, `gb`, `mins` |
| `scripts/screens/screen.gd` | 51 | The base every screen and overlay extends: `enter(args)`, `exit()`, `process(delta)`, `go()`, `clear()`, `toast()`; the members `main`, `world`, `mission` and the constants `Kit`, `World` |
| `scripts/screens/menu.gd` | 42 | Main menu: one player or a team, difficulty, how to play, ranking |
| `scripts/screens/team.gd` | 270 | The lobby: Solo (pick a station), Same screen (names and who holds which station) and Online (create or join a room, then the room view with the four stations). `args.view` or `args.players` |
| `scripts/net/room.gd`, `room_local.gd`, `room_online.gd` | | The Room (below) |
| `scripts/net/transport_web.gd`, `transport_memory.gd` | | The online room's two links: Firebase through the page (`web/room_bridge.js`), and an in-memory one for tests |
| `scripts/crew/bots.gd` | | The crew's bots (below) |
| `web/room_bridge.js`, `web/build_head.py` | | The page's JavaScript for Firebase; `build_head.py` writes it into the Web preset's `html/head_include` (Godot's export copies only `index.html`) |
| `database.rules.json` | | Realtime Database rules: only `rooms/<code>` |
| `scripts/screens/missions.gd` | 51 | Choice of the scenario (CML 1) |
| `scripts/screens/design.gd` | 378 | The eight design steps (CML 2-4), the review with the team's approvals, the mission dashboard, the "why it matters" box. `args.step` is the step |
| `scripts/screens/launch.gd` | 121 | Countdown, liftoff from the pad, ascent or the launcher's failure; it drives the camera itself |
| `scripts/screens/operation.gd` | 133 | Month-by-month playback of `GameState.last_sim`: mission log, time and science bars, speed controls |
| `scripts/screens/report.gd` | 143 | Grade, score, what happened and why, real missions like it; redesign, fly again, new mission, save to the ranking |
| `scripts/screens/ranking.gd`, `howto.gd` | 26, 33 | Overlays: the local ranking, how to play |
| `scripts/game_data.gd` | 150 | Loader of the catalogs (autoload `GameData`, extends `Node`). Reads `data/*.json` at startup and keeps the same public names as before: `SCENARIOS`, `BUSES`, `INSTRUMENTS`, `PANELS`, `BATTERIES`, `COMMS`, `ADCS`, `PROPULSION`, `ORBITS`, `LAUNCHERS`, `ROLES`, `ROLE_ORDER`, `STEPS`, `DIFFICULTY`, `CML_NAMES`, `SIZE_NAMES` (static variables). Translates the text fields, remembers the language in `user://settings.cfg`. No content lives in it |
| `data/*.json`, `i18n/translations.csv` | | The content (see "Data and translation") and the Spanish texts |
| `scripts/mission.gd` | 563 | `Mission` model (extends `RefCounted`). Holds the player's choices; `compute()` returns mass, power, battery, data, delta-v, lifetime, cost, pointing, objectives, expected science, review checks (`fatal`, `warn`, `ok`) and role goals; `science_rate()`; `simulate(seed)` runs the month-by-month events; `score()` gives objectives 400, science 300, efficiency 200, team 100; `real_missions()` |
| `scripts/ship_builder.gd` | 230 | Modular 3D spacecraft from primitives, changing with the chosen parts |
| `scripts/space_builder.gd` | 282 | Sky, Earth (texture and an Ecuador marker), procedural Moon, orbit rings, rocket, launch pad with Andean volcanoes, particles, `Label3D` |
| `shaders/` | | `earth`, `clouds`, `atmosphere`, `moon`, `sky`, `solar_cell`, `engine_glow`, and the include `noise.gdshaderinc` |
| `fonts/` | | Inter Regular, SemiBold and Display Bold, with `FONTS_LICENSE.txt` |
| `textures/` | | `earth_day/night/relief/clouds.jpg`, `moon_color/normal.jpg`, `terrain_cotopaxi.png` (NASA data, made by `assets/source/planet_textures.py` and `terrain_cotopaxi.py`) |
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

## Data and translation

Content and balance live in `data/*.json`, never in code. `GameData` reads the files once at startup (and again when
the language changes) and keeps them in static variables under the names in the table above, so
`GameData.LAUNCHERS["light"].cost` works anywhere, including in a script started with `-s` (which compiles before the
autoloads exist, so it reaches `GameData` through `const GD := preload("res://scripts/game_data.gd")`, see
`tests/fuzz.gd`). JSON numbers load as floats; the fields in `GameData.INT_FIELDS` become integers; `color` (three
numbers 0 to 1) becomes a `Color` and `dims` a `Vector3`.

Every file is an object `{"doc": "...", "entries": {id: entry}}` and every entry carries:
- `source`: a list of IDs of `docs/sources.md` the numbers come from (`["S14"]`).
- `simplified` (where the numbers are our own rounding): one sentence that says so and names what it simplifies.
- `value_notes` (optional): `{field: sentence}` for one value that has a different source or a stricter caveat.
Ids (`volcanes`, `cam_basic`) are stable keys, never shown to players. To add content: add an entry with the same
fields as its neighbors, cite the source, and run `tools/check.sh`. New sources go at the end of their section in
`docs/sources.md` with a word ID. Text fields hold English; the Spanish goes in `i18n/translations.csv`.

| File | Entry fields (units in the game header: kg, W, Wh, M$ = millions of USD, GB/day, Mbps, m/s) |
|---|---|
| `scenarios.json` | `name`, `type`, `desc`, `real` (text); `budget` (M$), `min_years`, `science_target` (points), `body` (`tierra` or `luna`), `needs` (list of `{any: [instrument tags], label}`: a goal is met when an instrument has one of the tags), `relevance` (tag to 0..1.1 value of that kind of instrument), `default_relevance` (optional, for tags not listed), `orbit_mult` (orbit id to science multiplier, 0 means it cannot serve), `color` |
| `buses.json` | `name`, `desc`; `dry`, `max` (kg), `cost` (M$), `base_power` (W), `slots`, `max_size` (largest instrument size), `ep_power` (W an electric engine draws), `ops_mult` (operations cost factor), `cots` (commercial electronics, radiation risk), `dims` (3D size) |
| `instruments.json` | `name`, `desc`; `tags` (what it observes), `size` (1 CubeSat, 2 small, 3 medium, 4 giant), `mass`, `power`, `cost`, `data` (GB/day), `sci` (science points per month), `pointing` (accuracy needed, 0 to 3), `shape` (how the 3D craft draws it) |
| `panels.json`, `batteries.json` | `name`, `desc`, `mass`, `cost`; panels `power` (W) and `span` (3D width); batteries `wh` |
| `comms.json` | `name`, `desc`, `rate` (Mbps), `mass`, `power`, `cost`, `dish` (3D size) |
| `adcs.json` | `name`, `desc`, `level` (pointing it gives, 1 to 3), `mass_pct`, `power_pct`, `cost_pct` (share of the platform's) |
| `propulsion.json` | `name`, `desc`, `dv` (m/s the craft carries), `mass_pct`, `cost_pct` (of the dry craft), `electric` |
| `orbits.json` | `name`, `short`, `desc`; `period_min`, `eclipse_min`, `eclipse_frac`, `contact_min` (per day), `comm_factor` (signal loss), `insert_dv`, `maint_dv` (per year), `drag_life` (years without propulsion, 999 means no drag), `radiation` (1 to 3), `body`, `radius`, `incl` (3D drawing), `ops` (operations cost per year) |
| `launchers.json` | `name`, `desc`; `cap` (orbit id to kg it can carry, 0 means it cannot go), `cost`, `cost_per_kg`, `min_cost` (M$), `fail`, `delay` (chances), `height` (3D) |
| `roles.json` | The four stations: `order` (engineer, scientist, pilot, ground) and entries with `name`, `goal`, `why`, `color` |
| `steps.json` | `entries` is a list: `id`, `title`, `role` (the station that decides it), `cml` (the maturity level the step reaches) |
| `difficulty.json` | `name`, `desc`, `budget`, `events`, `launch_fail` (multipliers) |
| `labels.json` | `size_names` and `cml_names` (number to name) |

Not in data yet: the numbers inside `scripts/mission.gd` (the 10 % and 20 % costs of redundancy, event chances,
score weights), cited in its comments, and the missions of `data/nasa/` (another package).

Translation. English is the default and the source text: every text a player sees is written once in English, in a
data file or in the code. Spanish lives in `i18n/translations.csv` (columns `keys,es`; the key is the exact English
text, quotes doubled in CSV). Godot imports it into `i18n/translations.es.translation` (listed in `project.godot`,
git ignores `*.translation`; the import creates it). To add a string: write it in English, wrap it in `tr("...")` in
code (static functions use `TranslationServer.translate`), or put it in a data text field (`name`, `type`, `desc`,
`real`, `goal`, `why`, `title`, `label`, `short`; `GameData` translates those itself), then add a row with its
Spanish. A text with numbers is translated before it is formatted: `tr("Budget %s") % x`. Never join pieces of a
sentence, translate it whole. The language switch is on the menu (`GameData.set_language("es")`, saved in
`user://settings.cfg`); screens already drawn must be drawn again, the menu does `go("menu")`.
`tools/godot.sh --headless --path . -s res://tests/i18n.gd` plays every screen in both languages and lists the texts
that look the same in both, which have no Spanish row.

## GameState

The autoload `GameState` (`scripts/game_state.gd`) holds what lives across screens:

| Member | What it is |
|---|---|
| `mission` | The `Mission` being designed (`scripts/mission.gd`); `start_mission(scenario)` replaces it with the scenario's starting parts and keeps the difficulty |
| `difficulty` | The difficulty id of `GameData.DIFFICULTY`; it is stored in `mission.difficulty` because the numbers use it |
| `room` | The shared state of the crew (the Room, below). Every screen reads and changes crew state through it |
| `players`, `team_mode` | The people (not bots) as `[{"name", "roles"}]`, rebuilt from the room; `team_mode` is true with two or more people or online. `start_solo(station)`, `start_crew(mode, humans)`, `new_online_room()`, `player_for_role(station)` |
| `approvals` | Station id to true once that station signed off (the room's state); setting `{}` clears it; any design change clears it. `crew_ready()`, `all_approved()`, `approve_all()` |
| `phase` | The id of the current screen, set by `main.go()` |
| `last_report`, `last_sim` | `mission.compute()` and `mission.simulate()` of the last launch (`begin_flight(r, seed)`); the sim holds events, timeline, months and `score` |
| `ranking`, `saved_to_ranking` | Local ranking in `user://ranking.json`, best first; `add_ranking()` saves it |

It emits `changed` whenever its methods or setters change something; a screen that edits `mission` directly emits it
after the edit (`design.gd` does in `on_change()`). The room's `changed` makes `GameState` copy the shared design into `mission`.

## The room and the stations

**Stations.** Four, in `data/roles.json`: engineer (platform, power, launcher), scientist (instruments), pilot (orbit,
control and propulsion, the review's launch call) and ground control (communications). `data/steps.json` gives each
step its `role`. A station is held by a person or by its bot (Rivet, Quark, Skip, Echo).

**The Room** (`scripts/net/room.gd`) is the one interface for shared state. Screens call `submit(op)` (shortcuts:
`take`, `release`, `sign`, `design_edited(step)`, `enter_step(step)`, `start_design`, `request_launch`) and read
`state`, whose shape is at the top of `room.gd`; `changed(by_me)` fires after every change. Two implementations:
`RoomLocal` (same screen and solo, no network, always used in the editor and on desktop) and `RoomOnline`
(Firebase Realtime Database; `TransportWeb` in the browser, `TransportMemory` in tests).

**Authority.** The host (the room's creator; the only machine in a local room) runs `apply_op`, the bots and the
rules, and is the only one that writes `rooms/<code>/state`. A guest writes its op under `rooms/<code>/ops` and
mirrors `state`; the host reads the op, applies it and deletes it. A guest's edit therefore shows up after a round trip
(about 0.2 s measured with the emulator). Members are `rooms/<code>/members/<pid>` with `onDisconnect().remove()`: when a
guest's tab closes, the host hands its stations back to the bots. If the host leaves, the room stops (guests keep their
last state). On a launch, the room carries one seed, so every machine flies the same random events; the flight itself
runs locally on each machine (the pilot's inputs are not shared yet).

**Rules** (`database.rules.json`, deployed by the lead with `firebase deploy --only database`): nothing readable or
writable except `rooms/<code>` (code 4 to 6 capitals or digits, so rooms cannot be listed), `state` a string of at most
20,000 characters, `host` write-once, `members` and `ops` with fixed fields and sizes, no other child. What they cannot
prevent without sign-in: anyone who knows a code can read and write that room (a guest could publish a false state or
delete the room), and ops are not limited in number. The code is the only key; rooms are not secret.

**Bots** (`scripts/crew/bots.gd`). When a step is shown (`room.enter_step`), the host's bot of that step's station plans
the design from that step on over a copy, using `Mission.compute()` as the judge (the smallest platform on which the
plan closes with 10 % reserve, the cheapest panels, radio, propulsion and rocket that meet the numbers), adopts only
its own fields, and records one line in `state.bot_lines`. A step a person edited is never touched again. At the review
every bot signs unless something is red, with a line. Lines are English msgids with id arguments, translated by each
reader. Data is in `data/*.json`; the bot adds no numbers of its own except the margins it asks for (20 % power, 15 %
data, 10 % reserve), which are our own game choices.

**Testing online.** `tests/room.gd` (host and guest over the in-memory transport, bots, sign-off, launch) and
`tests/crew.gd` (the bots launch every scenario). Against the real database code: start `firebase emulators:start
--only database --project demo-farpoint`, serve `build/web`, and open two pages with `?emulator=127.0.0.1:9000`
(done with Playwright and headless Edge, `--use-angle=swiftshader`).

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
