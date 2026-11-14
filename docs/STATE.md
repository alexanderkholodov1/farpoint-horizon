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
- `assets/models/launcher_light|medium|heavy.glb`: modeled launchers at real proportions [S13-S15], built from
  `assets/source/launchers.py`, now on the launch screen (`Space.make_rocket()`), replacing the primitive rocket at the
  same size on the pad. Checked: `tools/check.sh` green, `tools/shots.sh` launch screenshots, and all three rendered
  in Godot through `make_rocket()` (heights 3.84, 6.24, 7.2 as before; flames 2, 2, 4).

## The rocket builder (C1, issue #6, branch `work/6-builder`)

- From the launcher step ("Build your own rocket"), the player stacks real parts (`data/parts.json`, models in
  `assets/parts/`): engines, tanks, stage separators, fairings and a pair of side boosters. Gauges update live: payload
  to the mission's orbit against the craft's mass, delta-v per stage, thrust to weight at liftoff, cost, and what still
  stops it from flying. "Fly this rocket" makes it the mission's launcher (`custom`), which the mission model reads like
  any catalog launcher (`scripts/craft/rocket_design.gd`).
- The launch screen flies the assembled rocket: the boosters fall away, then the first stage separates and the second
  stage's engine takes over.
- Checked against the real vehicles, with no tuning: the Electron-type preset carries 313 kg to low orbit (real
  300 kg), the Falcon 9-type 17.2 t (real about 17.5 t reusable) and 5.3 t toward GEO (real about 5.5 t).
- The builder's text is English; the rest of the game is still Spanish until B2.

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

Nobody owns a part: each piece is claimed through its GitHub issue and built on its own branch; a lead agent
integrates it into `v0.2.0` with `tools/integrate.sh`, which checks the merged result before pushing and adds a line to
the list below (`AGENTS.md`, "The cycle of a version"). Pull requests into branches other than `main` are optional;
`main` takes only the version pull request, merged by a person. The shared contracts (data formats, the mission model,
`GameState`, `project.godot`, `AGENTS.md`) change only by agreement of both team members.

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

## Steps on v0.2.0

Every piece integrated into the version branch, oldest first. `tools/integrate.sh` adds a line here at each
integration; nobody edits this list by hand on a work branch.

- 0.1.1: The plan of v0.2.0 (skeleton first, then parallel packages, priority tiers)
- 0.1.2: Knowledge base, the mission catalog with real twins and the in-flight failures that become mini-games
- (no number) The teammate's laptop runs the game; `tools/godot.sh` finds Steam in Program Files (x86)
- (no number) C7: 3U CubeSat model with deploying wings and antennas (glTF from a Blender script)
- 0.1.3: The name Farpoint HORIZON, no owners, everything cited in one bibliography, the venue's rules and rubric,
  English by default with Spanish, no AI images, the service key kept out of git
- 0.1.4: Skeleton B1, every screen in its own script, a small flow controller, `GameState` and the UI kit
- 0.1.5: Parallel work: each piece on its own branch, pull requests allowed except into main, integration that checks the merged result before pushing; four stations with bots, NASA data and the look decided (`work/15-parallel-work`, 2026-11-14)
- 0.1.6: Modeled launchers on the pad, light, medium and heavy, at real proportions and cited (`c7-launchers`, 2026-11-14)
- 0.1.7: NASA data pipeline: the photos each mission returns (GIBS, LROC, Voyager), planet positions from JPL Horizons and NSSDC constants, every item cited (`work/19-nasa-data`, 2026-11-14)
- 0.1.8: Data apart and in English: the catalogs in data files with their sources, English by default with Spanish as an option, the name Farpoint HORIZON in the game; the telescope starts in L2 and launch fires once (`work/4-data`, 2026-11-14)
- 0.1.9: Sharper photos the mission returns: Ecuadorian volcanoes from Landsat 8, EO-1 and ASTER, Shackleton crater from LRO and ShadowCam (`work/19-nasa-data`, 2026-11-14)
- 0.1.10: The mission photos' import files committed, so branches never collide on them (`work/19-photo-imports`, 2026-11-14)
- 0.1.11: Honest citations: three values the cross-vendor review found unsupported are labeled as our game estimates (`work/4-honest-citations`, 2026-11-14)
- 0.1.12: Rocket builder: assemble the launcher from real parts that snap together, gauges that react to each part, and the rocket you build is the one that flies and separates its stages (`work/6-builder`, 2026-11-14)
- 0.1.13: Firebase Hosting: a temporary preview page for every pull request, production deployed only when the version pull request is merged (`work/13-firebase`, 2026-11-14)
- 0.1.14: The room: four stations with bots on the free ones, a lobby for solo, same screen and online with a code, crew sign-off (`work/5-room`, 2026-11-14)
- 0.1.15: A visual pass toward realism: NASA Earth and Moon, a modeled craft, the launch site on the real relief of Cotopaxi (`work/12-look`, 2026-11-14)
- 0.1.16: The Moon's south pole mission with random extra objectives, and the launch flown by the pilot with throttle, guidance marker and staging; real LOLA terrain data for the landing (`work/8-pilot`, 2026-11-14)
- 0.1.17: CI also runs the translation, flight, room and crew tests (`work/13-more-checks`, 2026-11-14)
- 0.1.18: The flight to the Moon's south pole: the burn the pilot cuts by hand, the coast, and the landing on NASA's LOLA ground with long shadows, the 1202 alarm and touchdown grades; the extra objectives are settled at touchdown (`work/8-pilot`, 2026-11-14)
- 0.1.19: No shared lists: screens, translations and tests are found by folder, and translations merge by union, so pieces built in parallel never conflict on them (`work/26-found-by-folder`, 2026-11-14)
