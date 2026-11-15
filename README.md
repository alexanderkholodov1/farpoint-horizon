# Farpoint HORIZON

Entry of team **SK Horizon** (Quito, Ecuador) to the NASA Space Apps Challenge 2026, challenge
[Space Mission Design Game](https://www.spaceappschallenge.org/2026/challenges/space-mission-design-game/).

**Play it in the browser: https://farpoint-horizon.web.app**. It works on a computer, a tablet or a phone held
sideways, in English or Spanish.

## Resumen (español)

Farpoint HORIZON es un juego 3D en el que una persona, o un equipo de hasta cuatro, diseña, lanza y opera una
misión científica real.
- Se elige una necesidad: los volcanes del Ecuador, El Niño, cartografiar la Luna, un telescopio en L2 o el hielo del
  polo sur lunar.
- Luego se elige la órbita, la plataforma, los instrumentos, la energía, la radio, el control de actitud, la
  propulsión y el cohete, cada uno con su costo en masa, energía, datos, delta-v, presupuesto y tiempo.
- Después se vuela la misión: el ascenso con física real, el viaje a la Luna, el alunizaje en el polo sur con el
  relieve LOLA de la NASA, el control de tierra con la Red de Espacio Profundo, y los meses de operación con
  tormentas solares según las escalas de NOAA.
- Un informe califica el resultado.

Todos los valores reales están citados en [`docs/sources.md`](docs/sources.md).

## What the game is

A 3D game built in Godot 4.7 where one player, or a team of up to four, designs, launches and operates a complete
space mission. Every choice trades off mass, power, data, delta-v, budget and time: the orbit, the spacecraft
platform, the instruments, power, communications, attitude control, propulsion, the launch vehicle and the lifetime.
The player learns that there is no perfect design.

**Current state.** Version v0.2.2 (release candidate). It is playable from the menu to the final report, in English
and Spanish, on the web and on a desktop.

## How to play

- **Web link:** https://farpoint-horizon.web.app
- **Run it locally:**
  1. Install Godot 4.7 (the Steam build or the official build from [godotengine.org](https://godotengine.org)).
  2. In the Project Manager choose Import, select `project.godot`, then Import and Edit.
  3. Press F5. The project uses the Compatibility renderer (`gl_compatibility`), which also suits integrated GPUs.

## How a mission flows

Stages follow the Concept Maturity Levels (CML) of NASA's Jet Propulsion Laboratory.

| Stage | What the player does | Maturity level |
|---|---|---|
| Objective | Picks the need: Ecuador's volcanoes, El Niño, the Moon's map, a space telescope at L2, ice at the Moon's south pole, or free mode | CML 1, idea |
| Design | A guided design: orbit, platform (from a 3U CubeSat to a large observatory), instruments, power, communications, attitude control, propulsion, rocket and lifetime. The player can also build their own rocket stage by stage | CML 2 to 3 |
| Review | Mass against the rocket, budget, power, data, delta-v; in a team, every role signs off | CML 4, point design |
| Flight | A 3D ascent with real physics (gravity, thrust, drag, staging), the trip to the Moon planned by the player and flown by the flight computer, and a landing at the south pole on NASA LOLA ground. Ground control solves failures in flight, such as finding the carrier through the Deep Space Network or the Apollo 11 "1202" alarm | none |
| Operation | The mission runs month by month: space weather alerts the player answers, debris, failures and discoveries | none |
| Report | Score out of 1000, why the mission succeeded or failed, the photos it sent home and similar real missions | none |

## How it answers the challenge

- **Design, manage and simulate a full mission:** the stages above, from the objective to the report.
- **Constraints of budget, mass, power, communications, data and lifetime:** live bars updated at every choice.
  The review blocks a launch that cannot work and says where each problem is fixed.
- **Up to four players with roles:** solo, or a team with four roles (director, scientist, engineer, operations).
  The team plays together on one shared screen, and bots take the empty roles. Online play is planned for v0.3.0.
- **Scenarios and difficulty:** 6 scenarios, including a sandbox, and 3 difficulties.
- **Plain-language learning:** every option says why it matters, a cited glossary explains the words, and the
  report explains the outcome.
- **NASA data:** the Earth, the Moon, the landing ground, the planets' positions and the photos each mission returns
  are NASA data (see below).

## The simplified model

Orders of magnitude are realistic, values are simplified. All values live in `data/*.json`, each with its source
note, and the formulas are in `scripts/mission.gd`.

- **Power.** Average generation = panel power x (1 - fraction of time in eclipse). If the load exceeds generation, instruments take turns and science drops.
- **Battery.** It must cover the load during the eclipse using only 60 % of its capacity (needed Wh = load x eclipse minutes / 60 / 0.6).
- **Data.** Downlink per day (GB) = link rate (Mbps) x distance factor x contact minutes x 60 / 8 / 1000. Data not sent is lost science.
- **Delta-v.** Orbit insertion (GEO 1500 m/s, Moon 900 m/s, L2 60 m/s, LEO and SSO 0) plus station keeping per year. In low orbit without propulsion, atmospheric drag ends the mission (about 2 years in LEO at 400 km, 25 in SSO at 700 km).
- **Space weather.** Storms on NOAA's scales: geomagnetic (G4, G5) near the Earth, solar radiation (S3, S4) at the Moon and L2. The player chooses safe mode (half of the month's data lost, a fifth of the risk) or keeps working, and low orbits lose life to drag.
- **Risk.** Radiation depends on the orbit. CubeSats use commercial electronics, which are more vulnerable. Shielding and redundancy reduce failures. Redundancy adds 10 % dry mass and 20 % hardware cost; shielding adds 4 % mass and 5 % cost.
- **Science.** Each instrument's yield is scaled by its relevance to the scenario, by pointing accuracy, and by the orbit; it is limited by the data link, power and battery.
- **Score.** Objectives 400 (200 for covering the needs, 200 for surviving the minimum years), science 300, efficiency 200 (budget 100, mass margin 50, power margin 50), team goals 100 (25 per role). Grades: S from 900, A from 750, B from 600, C from 400, otherwise D.

Every formula and value is cited at its definition in the code or the data, with a tag listed in
[`docs/sources.md`](docs/sources.md).

## NASA data and resources used

PDFs are in `docs/challenge/`.

- [Design and Develop Science Missions](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf) (NASA Small Spacecraft Systems Virtual Institute): the launch, space, ground and user segments.
- [Concept Maturity Levels](https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299) (JPL): the game stages follow CML 1 to 4.
- [CubeSat 101](https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf) (NASA CSLI): CubeSat platforms, rideshare and constraints.
- Inspiration: NASA [Mission Design Lab](https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/) (GSFC) and [Build It Yourself: Webb Telescope](https://science.nasa.gov/mission/webb/game-build-it-yourself/).
- [NASA GIBS](https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi) (Earthdata, Worldview): Blue Marble, shaded relief and VIIRS imagery of the Earth and of the region under the launch.
- [CGI Moon Kit](https://svs.gsfc.nasa.gov/4720) (NASA GSFC Scientific Visualization Studio, LRO LROC and LOLA): the Moon's colour and relief.
- [LOLA LDEM_875S_20M](https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/img/ldem_875s_20m.lbl) (NASA PDS, Lunar Reconnaissance Orbiter): the ground of the landing at the south pole and Shackleton's rim.
- [JPL Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html): the planets' orbital elements and the Moon's position.
- [NASA Earth Observatory](https://science.nasa.gov/earth/earth-observatory/) (Landsat 8 OLI and others): the photos each mission sends home, such as Sangay's ash and Cotopaxi.
- [NASA Deep Space Network](https://www.jpl.nasa.gov/news/eight-essential-facts-about-nasas-deep-space-network/) (JPL): the ground stations of ground control.
- [NSSDC fact sheets](https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html): the radius, GM and solar constant.
- Partner data: NOAA Space Weather Prediction Center [scales](https://www.swpc.noaa.gov/noaa-scales-explanation) for the space weather.
- Real missions named in the reports: Landsat 9, Sentinel-2, Sentinel-5P, ASTER, Sentinel-6 Michael Freilich, SMAP, Jason, Lunar Reconnaissance Orbiter, Chandrayaan-2, Hubble, James Webb, CAPSTONE, NEE-01 Pegaso.

## Sources

Every formula and value is cited where it is used and listed once in [`docs/sources.md`](docs/sources.md), the
project's bibliography. The main sources so far:

- NASA Space Science Data Coordinated Archive, [Earth fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html) (radius, GM, solar constant).
- NASA Orbital Debris Program Office [FAQ](https://orbitaldebris.jsc.nasa.gov/faq/) (orbital lifetime against altitude) and the NASA 25-year disposal guideline.
- NASA Glenn [ideal rocket equation](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/ideal-rocket-equation/) and Hohmann transfer relations.
- Landsat 9 ([NASA](https://science.nasa.gov/mission/landsat-9)) and Sentinel-2 ([SentiWiki](https://sentiwiki.copernicus.eu/web/s2-mission)) orbit and coverage data.
- Launch vehicle data (Falcon 9, Falcon Heavy, Electron and others) from manufacturer guides and public references, listed with links in the file.

## Use of AI

Artificial intelligence (AI) tools helped build this project, as the challenge rules ask us to disclose. The game idea, the
design decisions and the balance are the team's.

- **Claude Code** (Anthropic), models Claude Opus 5.5 and Claude Sonnet: code, documents and research notes.
- **Cursor**, model Composer 2.5: a feasibility test of the web build (kept outside this repository).
- **Meshy** and **TRELLIS** (Microsoft, run on Hugging Face): 3D drafts the team used as references for the four cuy
  crew models; Rumi's body is a TRELLIS mesh, the heads and the other three cuyes were modelled in Blender by script
  (`assets/source/crew_*.py`). The story portraits are renders of those models.
- **Claude** (Anthropic): the game's music (`audio/music_horizon.ogg`, `audio/music_horizon_drive.ogg`) was generated with AI. Its files say so in their metadata and the in-game credits say so too.

No AI-generated images or videos are used, so no watermark is needed: models come from our scripts and from the cited
libraries, imagery from NASA. Every source (information, formula, data) is cited where it is used and in
`docs/sources.md`.

## Credits

- Engine: [Godot Engine](https://godotengine.org) (MIT).
- Font: Inter by Rasmus Andersson, [SIL Open Font License 1.1](https://rsms.me/inter/) (see `fonts/FONTS_LICENSE.txt`).
- Earth and Moon textures: NASA Blue Marble, Black Marble, VIIRS and the SVS CGI Moon Kit, made by `assets/source/planet_textures.py` (sources S-gibs-earth and S-moon-kit in `docs/sources.md`).
- 3D modeling: [Blender](https://www.blender.org) (GPL), driven by our scripts in `assets/source/`. The craft, the launchers, the tanks, fairings and interstages, the craft components and the launch site are our own models.
- Outside 3D models: Merlin Engine by hoahluke, Merlin 1D Vacuum by MartianDays, Rocket Nozzle Part by Zachary (corncob_127), all Sketchfab, CC BY 4.0; the Space Shuttle Solid Rocket Booster of NASA 3D Resources (public domain). Sources S-merlin-model, S-mvac-model, S-nozzle-model and S-srb-model in `docs/sources.md`.
- NASA data in the game: Earth and Moon imagery, the Andes relief under the launch site, the Moon's south pole ground, the photos each mission returns, positions and constants; every item in `docs/sources.md`.
- Sounds: synthesized in code by the game (`scripts/ui/ui_sound.gd`, `scripts/flight/sound.gd`); no recorded or outside sounds.

## Team

Team SK Horizon, Quito, Ecuador.

- **Alexander Kholodov**: team lead; the flight's real physics, the Moon landing, ground control, the crew room and the NASA data. [GitHub](https://github.com/alexanderkholodov1)
- **Sebastián Amaguaya**: the rocket builder, the 3D models, the visual identity, the guided design, the music and every sound. [GitHub](https://github.com/XebaxCode)

## License

MIT, see LICENSE.

## Demo and pitch

- **Demo video (29 s):** [`docs/demo/farpoint_horizon_30s.mp4`](docs/demo/farpoint_horizon_30s.mp4), recorded from the game itself.
- **Live game:** https://farpoint-horizon.web.app
- **Pitch deck (7 slides):** in Spanish, [`docs/pitch/build/deck-es.pdf`](docs/pitch/build/deck-es.pdf), and in English, [`docs/pitch/build/deck-en.pdf`](docs/pitch/build/deck-en.pdf).
