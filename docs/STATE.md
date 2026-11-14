# Project state

Last update: 2026-11-14. Released: v0.1.0 (first playable sketch). In progress on branch `v0.2.0`, following
`docs/plan/v0.2.0.md` and `docs/design/vision.md`.

## What works today

- The game is playable from start to finish: menu, team, objective, 8-step design, review, launch, month-by-month operation, report, ranking.
- The teammate reports that it ran without errors on Godot 4.5.1 and 4.7.1 (Linux, Compatibility renderer) using `tests/autoshot.tscn` and `tests/fuzz.gd`. Not re-run by us on Linux.
- Five scenarios, three difficulties, six platforms, 15 instruments, five orbits, four launchers, four team roles. Details in `README.md` and `docs/architecture.md`.

## Verified on 2026-11-14 (lead's laptop)

Godot 4.7.2 Steam, Windows, Compatibility renderer: the autoshot walkthrough ran end to end and produced all 16
screenshots; the only messages were GPU texture-leak warnings at exit. `tools/check.sh` passed: import, the main scene
for 120 frames headless with no script errors, the fuzz test (600 random designs, all simulated), and the web export
(`index.pck` 1.8 MB, `index.wasm` 37.7 MB raw, about 9.7 MB compressed).

## Resolved: the teammate's laptop runs the game

Asus VivoBook Go, integrated AMD Radeon, Windows, Godot 4.7.2 Steam (in `Program Files (x86)`, now found by
`tools/godot.sh`). Version 1 (Forward+ with Vulkan) closed on start; with `gl_compatibility` and no 3D MSAA it works.
Checked on 2026-11-14 on branch `v0.2.0`: Godot reports `OpenGL API 3.3.0 Core Profile ... AMD Radeon(TM) Graphics`,
every `[SKH]` startup step through `menu listo` and the first frames print, 600 frames in a window end with exit 0;
`tools/shots.sh` produced all 16 screenshots (menu and launch looked at); `tools/check.sh` passed. The only messages are
the same texture-leak warnings at exit as on the lead's laptop. The safe mode is no longer needed for this laptop.

## Models (C7)

- `assets/models/cubesat_3u.glb`: a 3U CubeSat at real scale with four wings and four antennas that deploy (animation
  `deploy`), built from `assets/source/cubesat_3u.py`. Not yet used by any screen; see `assets/models/README.md`.

## The skeleton (Phase B of the plan)

- **B1 done:** every screen in its own script under `scripts/screens/`, a small flow controller (`scripts/main.gd`),
  the 3D world in `scripts/world.gd`, shared state in the `GameState` autoload, the UI kit in `scripts/ui/kit.gd`.
  How to add a screen: `docs/architecture.md`. Verified: `tools/check.sh` green, the 16 walkthrough screenshots match
  v0.1.0 except where events are random.
- **Next:** B2 (catalogs to `data/*.json`, every value cited in `docs/sources.md`, English text with Spanish as an
  option, the game's name), then B3 (the shared room: one screen and Firebase).
- Known bugs kept from the sketch: in `GameState.start_mission` the telescope's orbit is set to L2 and then overwritten
  to LEO; a double click on the launch button during the fade launches twice.

## How work is shared

Nobody owns a part: each piece is claimed through its GitHub issue, built on its own work branch
(`work/<issue>-<name>`) and integrated into `v0.2.0` through a pull request (`AGENTS.md`, `tools/integrate.sh`). The shared contracts
(data formats, the mission model, `GameState`, `project.godot`, `AGENTS.md`) change only by agreement of both team
members.

## Pending

- Rebuild as v0.2.0 per `docs/design/vision.md`: stronger plot and game design, better 3D models, a more distinctive UI, web export, Firebase hosting and online multiplayer, complete mission (build, orbit, reach target, land), several mission types.
- Cite every formula and value at its definition in `scripts/game_data.gd` and `scripts/mission.gd`, and in `kb/data/reference.json`.
- Interface language: v0.1.0 text is Spanish; the team decided that the game and every material are in English (`kb/decisions.md`).
- Source and license of `textures/earth_albedo.jpg` (the teammate must confirm).
- AI disclosure: the teammate adds the agents he used in `README.md`.
- Deploy the web build to Firebase Hosting once the Firebase project exists (it is created when the game's name is settled).
- Pitch deck of at most 7 slides, a 30-second video, and the submission form: see `docs/team/pitch-outline.md` and `kb/challenge/event-and-judging.md`.
- Optionally remove the `[SKH]` traces before the final delivery.
- Deadline: everything frozen by 07:00 on Sunday 2026-11-15 (team decision); pitch and repository upload close at 09:00.
