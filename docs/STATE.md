# Project state

Last update: 2026-11-14. Version v0.1.0 (first playable sketch). Next: v0.2.0, see `docs/design/vision.md`.

## What works today

- The game is playable from start to finish: menu, team, objective, 8-step design, review, launch, month-by-month operation, report, ranking.
- The teammate reports that it ran without errors on Godot 4.5.1 and 4.7.1 (Linux, Compatibility renderer) using `tests/autoshot.tscn` and `tests/fuzz.gd`. Not re-run by us on Linux.
- Five scenarios, three difficulties, six platforms, 15 instruments, five orbits, four launchers, four team roles. Details in `README.md` and `docs/architecture.md`.

## Verified on 2026-11-14 (lead's laptop)

Godot 4.7.2 Steam, Windows, Compatibility renderer: the autoshot walkthrough ran end to end and produced all 16
screenshots; the only messages were GPU texture-leak warnings at exit. `tools/check.sh` passed: import, the main scene
for 120 frames headless with no script errors, the fuzz test (600 random designs, all simulated), and the web export
(`index.pck` 1.8 MB, `index.wasm` 37.7 MB raw, about 9.7 MB compressed).

## Open problem (teammate's laptop)

Asus VivoBook Go, integrated AMD Radeon, Windows, Godot 4.7.2 Steam. Version 1 (Forward+ with Vulkan) closed on start
and the editor then asked for recovery mode. The project now uses `gl_compatibility` without 3D MSAA. **Not yet
confirmed that the current version reaches the menu on that laptop.**

How to investigate:
- Log: `%APPDATA%\Godot\app_userdata\SK Horizon - Mission Architect\logs\godot.log`.
- `main.gd` prints `[SKH]` trace lines at each startup step (stdout is flushed on every print). The last line shows where it stops.
- If it still crashes, suspects in order: the sky shader (`shaders/sky.gdshader`, star loops); clouds and atmosphere (transparency); `Environment` glow; `DirectionalLight3D` shadows; `CPUParticles3D`. Disable them one by one. A "safe mode" that turns them all off would help.

## Who owns what

The two team members agree on it and write it here; until then, coordinate in GitHub issues before touching the same
files. The shared contracts (`scripts/game_data.gd` formats, `scripts/mission.gd`'s model, `project.godot`,
`AGENTS.md`) change only by agreement.

## Pending

- Confirm the open problem above, or implement the safe mode.
- Rebuild as v0.2.0 per `docs/design/vision.md`: stronger plot and game design, better 3D models, a more distinctive UI, web export, Firebase hosting and online multiplayer, complete mission (build, orbit, reach target, land), several mission types.
- Cite every formula and value at its definition in `scripts/game_data.gd` and `scripts/mission.gd`, and in `kb/data/reference.json`.
- Interface language: v0.1.0 text is Spanish; the team decided that the game and every material are in English (`kb/decisions.md`).
- Source and license of `textures/earth_albedo.jpg` (the teammate must confirm).
- AI disclosure: the teammate adds the agents he used in `README.md`.
- Deploy the web build to Firebase Hosting once the Firebase project exists (it is created when the game's name is settled).
- Pitch deck of at most 7 slides, a 30-second video, and the submission form: see `docs/team/pitch-outline.md` and `kb/challenge/event-and-judging.md`.
- Optionally remove the `[SKH]` traces before the final delivery.
- Deadline: everything frozen by 07:00 on Sunday 2026-11-15 (team decision); pitch and repository upload close at 09:00.
