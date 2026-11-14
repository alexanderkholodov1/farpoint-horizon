# SK Horizon, Mission Architect

Entry of team **SK Horizon** (Quito, Ecuador) to the NASA Space Apps Challenge 2026, challenge
[Space Mission Design Game](https://www.spaceappschallenge.org/2026/challenges/space-mission-design-game/).

## What the game is

A 3D game built in Godot 4.7 where one player, or a team of up to four, designs, launches and operates a complete
space mission. Every choice (orbit, spacecraft platform, instruments, power, communications, attitude control,
propulsion, launch vehicle, lifetime) trades off mass, power, data, delta-v, budget and time, and the player learns
that there is no perfect design.

**Current state.** Version v0.1.0 is the first playable sketch: it runs from menu to final report. The next version,
v0.2.0, rebuilds it as described in [`docs/design/vision.md`](docs/design/vision.md). Where the project stands today
is in [`docs/STATE.md`](docs/STATE.md). The interface text of v0.1.0 is in Spanish.

## How to play

- **Web link:** link coming with v0.2.0 (the game will be hosted on Firebase Hosting).
- **Run it locally:**
  1. Install Godot 4.7 (the Steam build or the official build from [godotengine.org](https://godotengine.org)).
  2. In the Project Manager choose Import, select `project.godot`, then Import and Edit.
  3. Press F5. The project uses the Compatibility renderer (`gl_compatibility`), which also suits integrated GPUs.

## How a mission flows today

Stages follow the Concept Maturity Levels (CML) of NASA's Jet Propulsion Laboratory.

| Stage | What the player does | Maturity level |
|---|---|---|
| Objective | Picks the science question: Ecuador's volcanoes, El Nino, the Moon, a space telescope, or free mode | CML 1, idea |
| Design | Picks orbit, platform (from a 3U CubeSat to a large observatory), instruments, power, communications, attitude control, propulsion, launch vehicle and lifetime, in 8 steps | CML 2 to 3 |
| Review | Checks compatibility (mass against rocket, budget, power, data, delta-v); in team mode every role must approve | CML 4, point design |
| Launch | 3D launch animation with the chosen vehicle; it can fail | none |
| Operation | The mission runs month by month with solar storms, space debris, failures and discoveries | none |
| Report | Score out of 1000, why the mission succeeded or failed, and similar real missions | none |

## How it answers the challenge

Requirement IDs are defined in [`kb/challenge/requirements.md`](kb/challenge/requirements.md). Each claim below was
checked against the code of v0.1.0.

| Requirement | How v0.1.0 meets it |
|---|---|
| C1, C2, F5 | Playable game with a 3D scene and an interactive spacecraft that changes with each chosen part (`scripts/ship_builder.gd`) |
| C7, M1, S1, O1, O3 | Objective first, then orbit, platform, instruments, power, communications, attitude control, propulsion, launcher and lifetime |
| C3, C8, M2, M4, R1, R2, F6 | Live dashboard of budget, mass, power, eclipse battery, data, delta-v, lifetime and expected science, updated at every change |
| O4, S2 | Review blocks launch if instruments do not fit, mass exceeds platform or rocket, the rocket cannot reach the orbit, the budget is exceeded, or the orbit is useless for the objective |
| C5, F2, F8 | Month-by-month simulation with random events; final mission report |
| C6, G6 | Score: objectives 400, science 300, resource efficiency 200, team goals 100 |
| C4, C9, G2, G3, T1, T2, F10 | Solo mode, and team mode for 2 to 4 players with four roles (director, scientist, engineer, operations). Team mode is local: one shared screen with roles split among the players. Every role must approve the design, and any change resets the approvals. Online multiplayer is not implemented yet |
| M3, G5 | Cheap and expensive designs can meet the same objective; the player can redesign or fly again with different luck |
| G7, F1, F3, F12 | 5 scenarios (including a sandbox) and 3 difficulties (easy, normal, hard) |
| G4, E1, E3, E4, F13 | A "why does it matter" box explains every option, the review explains each problem, and the report explains the outcome |
| F7 | Local ranking saved in the browser or device (`user://ranking.json`) |
| O2 | Orbit changes eclipse time, contact time, radiation, lifetime and science yield (5 orbits) |

Not yet met: F9 (save and share designs), F11 (competitive scenarios), online multiplayer. Not verified: whether the
text is understandable to players with no space knowledge (G1), which needs playtesting.

## The simplified model

Orders of magnitude are realistic, values are simplified. All values live in `scripts/game_data.gd` and can be tuned
without touching the rest of the code; the formulas are in `scripts/mission.gd`.

- **Power.** Average generation = panel power x (1 - fraction of time in eclipse). If the load exceeds generation, instruments take turns and science drops.
- **Battery.** It must cover the load during the eclipse using only 60 % of its capacity (needed Wh = load x eclipse minutes / 60 / 0.6).
- **Data.** Downlink per day (GB) = link rate (Mbps) x distance factor x contact minutes x 60 / 8 / 1000. Data not sent is lost science.
- **Delta-v.** Orbit insertion (GEO 1500 m/s, Moon 900 m/s, L2 60 m/s, LEO and SSO 0) plus station keeping per year. In low orbit without propulsion, atmospheric drag ends the mission (about 2 years in LEO at 400 km, 25 in SSO at 700 km).
- **Risk.** Radiation depends on the orbit. CubeSats use commercial electronics, which are more vulnerable. Shielding and redundancy reduce failures. Redundancy adds 10 % dry mass and 20 % hardware cost; shielding adds 4 % mass and 5 % cost.
- **Science.** Each instrument's yield is scaled by its relevance to the scenario, by pointing accuracy, and by the orbit; it is limited by the data link, power and battery.
- **Score.** Objectives 400 (200 for covering the needs, 200 for surviving the minimum years), science 300, efficiency 200 (budget 100, mass margin 50, power margin 50), team goals 100 (25 per role). Grades: S from 900, A from 750, B from 600, C from 400, otherwise D.

v0.1.0 values are not yet cited one by one to their sources. From v0.2.0 on, every formula and value is cited at its
definition in the code and recorded in [`kb/data/reference.json`](kb/data/reference.json) with its source link.

## NASA data and resources used

PDFs are in `docs/challenge/`.

- [Design and Develop Science Missions](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf) (NASA Small Spacecraft Systems Virtual Institute): the launch, space, ground and user segments.
- [Concept Maturity Levels](https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299) (JPL): the game stages follow CML 1 to 4.
- [CubeSat 101](https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf) (NASA CSLI): CubeSat platforms, rideshare and constraints.
- Inspiration: NASA [Mission Design Lab](https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/) (GSFC) and [Build It Yourself: Webb Telescope](https://science.nasa.gov/mission/webb/game-build-it-yourself/).
- Real missions named in the reports: Landsat 9, Sentinel-2, Sentinel-5P, ASTER, Sentinel-6 Michael Freilich, SMAP, Jason, Lunar Reconnaissance Orbiter, Chandrayaan-2, Hubble, James Webb, CAPSTONE, NEE-01 Pegaso.

## Sources

Every formula and value is cited at its definition and in [`kb/data/reference.json`](kb/data/reference.json). The main
sources already collected there include:

- NASA Space Science Data Coordinated Archive, [Earth fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html) (radius, GM, solar constant).
- NASA Orbital Debris Program Office [FAQ](https://orbitaldebris.jsc.nasa.gov/faq/) (orbital lifetime against altitude) and the NASA 25-year disposal guideline.
- NASA Glenn [ideal rocket equation](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/ideal-rocket-equation/) and Hohmann transfer relations.
- Landsat 9 ([NASA](https://science.nasa.gov/mission/landsat-9)) and Sentinel-2 ([SentiWiki](https://sentiwiki.copernicus.eu/web/s2-mission)) orbit and coverage data.
- Launch vehicle data (Falcon 9, Falcon Heavy, Electron and others) from manufacturer guides and public references, listed with links in the file.

## Use of AI

Super Intelligence (AI) tools helped build this project, as the challenge rules ask us to disclose. The game idea, the
design decisions and the balance are the team's.

- **Claude Code** (Anthropic), models Claude Opus 5.5 and Claude Sonnet: code, documents and research notes.
- **Cursor**, model Composer 2.5: a feasibility test of the web build (kept outside this repository).
- **TODO (teammate):** add here the other AI agents and models you used.

No watermarks are used. Instead, every source (information, formula, data) is cited where it is used and in
`kb/data/reference.json`.

## Credits

- Engine: [Godot Engine](https://godotengine.org) (MIT).
- Font: Inter by Rasmus Andersson, [SIL Open Font License 1.1](https://rsms.me/inter/) (see `fonts/FONTS_LICENSE.txt`).
- Earth texture (`textures/earth_albedo.jpg`): the previous README says the team generated it from a public land and ocean mask (the `global-land-mask` package, NOAA GLOBE data). No file in the repository states this, so it is **TODO: confirm the source and license with the teammate**.
- Spacecraft and space scenes are built in code from Godot primitives and shaders (`scripts/`, `shaders/`); this was not independently checked for third-party assets.

## Team

Team SK Horizon, Quito, Ecuador.

## License

MIT, see LICENSE.
