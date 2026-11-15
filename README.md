# Farpoint HORIZON

**You don't read about a space mission. You fly one.**

Farpoint HORIZON is a 3D space-mission game made in Quito, Ecuador, for the NASA Space Apps Challenge 2026
([Space Mission Design Game](https://www.spaceappschallenge.org/2026/challenges/space-mission-design-game/)). You
design a spacecraft and the rocket that carries it. You fly the climb from the equator, the burn to the Moon and the
landing on NASA's own map of the lunar south pole. Then you keep the craft alive from the ground. A crew of four
Andean guinea pigs, the *cuyes*, takes you through six real NASA missions, in the order they happened. Every number
on screen comes from real physics or from a cited NASA source.

**▶ Play in the browser: https://farpoint-horizon.web.app**: no install, on a computer, a tablet or a phone held
sideways, in English or Spanish.
**▶ Watch 30 seconds of it: https://youtu.be/3xZdPJr71bg**

---

## The problem

A space mission is one system. A better camera is heavier. A heavier craft needs a bigger rocket, and a bigger
rocket eats the budget. More data needs a faster radio, which needs more power and larger solar wings, and those add
mass again. NASA's mission designers live inside this web of trade-offs.

Students almost never get to touch it. Classes teach orbits in one chapter, rockets in another and instruments in a
third. The tools that exist each cover one slice: an orbit calculator, a rocket simulator, a quiz. Nobody gets to
take one idea all the way from "what do we want to learn?" to "the data is coming home", and see how every choice
pulls on all the others. That is the gap the challenge asks us to close.

## Our answer

**The whole mission, in one game, in real time and at true scale.**

1. **Ask a question.** Every mission starts with a need: watch Ecuador's volcanoes, follow El Niño off our coast, map
   the Moon, look at distant galaxies, find ice at the lunar south pole. The steps follow NASA JPL's Concept Maturity
   Levels.
2. **Design it.** You choose the orbit, the craft's size (from a shoebox CubeSat to a great observatory), the
   instruments, the solar wings, the battery, the radio, the pointing control, the propulsion and the lifetime. Every
   choice moves the live gauges: mass, power, data, delta-v, cost, years. The craft is assembled in front of you, and
   the part that causes a problem glows on it.
3. **Build the rocket.** Stack real engines, tanks and boosters. The rocket equation decides what reaches orbit. The
   presets match the real vehicles with no tuning: an Electron-type rocket carries 313 kg to low orbit (real: 300 kg),
   a Falcon 9-type 17.2 t (real: about 17.5 t).
4. **Fly it.** The launch is about eight minutes of real climb from the equator: gravity, drag, Max-Q, staging. The
   trip to the Moon uses the pull of the Earth and of the Moon, with the Moon where JPL Horizons puts it on the day.
   Mission control times the departure so you meet the Moon where it will be. Then a correction, the braking on the
   far side with no radio (as Apollo's crews did), and a landing on NASA LOLA elevation data at Shackleton's rim.
5. **Keep it alive.** From the ground you find the craft's faint carrier through the Deep Space Network, as engineers
   did for Voyager 2 in 2023. You answer the computer's 1202 alarm, as Apollo 11 did. You decide what to do when NOAA
   forecasts a solar storm.
6. **See what you achieved.** The report explains why the mission worked or did not, shows the real photos a mission
   like yours sends home (Cotopaxi seen by Landsat 8, Shackleton crater seen by LRO and ShadowCam) and names the real
   missions that made the same choices.

**Missing something is never a "game over" screen.** A craft that reaches a lower orbit still does science. A rough
landing still sends data. You see why, change one thing and fly again. Achieving more is rewarded with extra goals
and a grade.

## New in v0.3.0: the cuyes who were there

NASA learned by failing, bouncing and crashing, and it always came back. Version 0.3.0 tells that story through four
cuy astronauts who were slipped into six real missions. History stays exactly as NASA tells it: the cuyes help,
panic and joke, while the real numbers decide what happens.

| The crew | Station | In one line |
|---|---|---|
| **Rumi** (stone) | Engineer | Fixes anything with what is at hand. |
| **Killa** (moon) | Scientist | Wants the data, even if it means crashing. |
| **Inti** (sun) | Pilot | Calm until the airbags. |
| **Wayra** (wind) | Ground control | The voice on the radio. |

| # | Mission | What you do | Status |
|---|---|---|---|
| 1 | **Apollo 13**, April 1970: *"Square peg, round hole"* | Oxygen tank 2 has exploded. Build the CO₂ adapter from bags, cardboard and tape before the air runs out. NASA's photo of the real "mailbox" closes it. | Playable |
| 2 | **STS-61**, December 1993: *"Glasses for a telescope"* | Five spacewalks against their clocks (35 h 28 min in all): bolts, rails, solar blankets, COSTAR's mirrors. Then turn the correction until galaxy M100 comes sharp. | Playable |
| 3 | **Mars Pathfinder**, July 1997: *"Land by bouncing"* | The real descent: the bridle, the rockets at 98 m, cut at 21.5 m, land at about 18 m/s on airbags, bounce past the rocks, then roll Sojourner down the ramp for the first wheel on Mars. | Playable |
| 4 | **LCROSS**, October 2009: *"The plan is to crash?" "Yes." "OK."* | Aim the spent Centaur at Cabeus, fly through the plume and read the instruments in the four minutes before your own impact. | In production |
| 5 | **DART**, September 2022: *"Push an asteroid"* | Aim on the camera images as Dimorphos grows from a dot, then find from a light curve that its orbit shrank by 32 minutes. | In production |
| 6 | **Artemis I**, Nov-Dec 2022: *"Everything we learned"* | Everything before comes together: the launch from Pad 39B, the trip around the Moon, the record distance and the return at Mach 32. | In production |

The designer's free missions stay open beside the campaign, and each chapter's mission is being made playable on
its own as well.

## Why it works

- **The whole system, not one slice.** The objective, the craft, the rocket, the launch, the trip, the landing, the
  ground control and the operation are one chain. A choice in one place shows up everywhere downstream.
- **Real behaviour, never a drawing of it.** Nothing moves along a hand-drawn curve. Paths come from gravity, real
  constants and ephemerides. Time runs in real time, and speeding it up is a visible control. Sizes and distances keep
  their true proportions.
- **Checked against reality.** The tests fly the game and compare it with the real values: a low orbit of 87.7 min, a
  coast to the Moon of about 82 h (Apollo 11: 76 h), a lunar orbit of about 110 km, rockets that carry what the real
  ones carry. Our own simplifications are written where they are made.
- **NASA data you can touch.** The landing ground is LOLA. The Earth is Blue Marble and VIIRS through GIBS. The Moon
  is LRO. Its position is JPL Horizons. The photos are Landsat, ASTER and LRO. The ground stations are the Deep Space
  Network. NASA data is the ground you fly over and land on, not decoration.
- **Plain words.** Every concept a player meets is explained in a sentence inside the game. A cited glossary, a
  guided first mission and a crew member at every station help a 12-year-old and an engineering student alike.
- **Made to be played together.** Four stations (engineer, scientist, pilot, ground control) each own their decisions,
  like a real mission team. Bots that follow the same rules take any station nobody holds.
- **Fun first.** Kerbal Space Program's joy of watching your own craft lift off, without its punishing retry loop.
  Humor, music composed for the game, and the pride of a landing you flew yourself.
- **From the equator.** It is made in Quito: you launch over the Andes and Cotopaxi, and the first mission watches our
  own volcanoes.

## How it answers the challenge

| The challenge asks for | In Farpoint HORIZON |
|---|---|
| Design, manage and simulate a complete mission | Objective → design → rocket → review → launch → flight → landing → operation → report |
| Trade-offs of budget, mass, power, communications, data, lifetime | Live gauges at every choice. The review blocks a launch that cannot work and says where to fix it |
| Spacecraft components and instruments with mass, power, cost, data, value | 6 platforms, 16 instruments, panels, batteries, radios, attitude control and propulsion, each from cited real hardware |
| Orbits and launch vehicles, and checking they are compatible | 5 orbits explained in plain words. Catalog launchers or your own rocket, with capacity computed for the chosen orbit |
| One player or a team of up to four, with roles | Four stations with their own decisions. Bots fill the empty ones |
| Feedback, scoring, several runs | A score out of 1000, a grade, extra goals, a report that explains why. Redesign and fly again in one click |
| Difficulty levels and scenarios | 3 difficulties, 6 free missions including a sandbox, and the six-chapter campaign |
| Accessible to different levels | Guided first mission, a glossary, one-line explanations, English and Spanish, runs in any browser |

## NASA data and resources

| Resource | What it is in the game |
|---|---|
| [LRO LOLA LDEM_875S_20M](https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/img/ldem_875s_20m.lbl) (NASA PDS) | The ground you land on at the Moon's south pole, at Shackleton's rim |
| [JPL Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html) | Where the Moon and the planets are on the day you fly; the trip is timed to it |
| [NASA GIBS](https://nasa-gibs.github.io/gibs-api-docs/) / [Worldview](https://worldview.earthdata.nasa.gov) | The Earth: Blue Marble, Black Marble, VIIRS, shaded relief, the region under the launch |
| [CGI Moon Kit](https://svs.gsfc.nasa.gov/4720) (NASA SVS, LRO LROC and LOLA) | The Moon's colour and relief |
| [SRTM](https://www.earthdata.nasa.gov/data/instruments/srtm) | The Andes and Cotopaxi under the launch site |
| [NSSDC planetary fact sheets](https://nssdc.gsfc.nasa.gov/planetary/factsheet/) | Radius, GM and gravity of every body; the solar constant |
| [NASA Earth Observatory](https://science.nasa.gov/earth/earth-observatory/) (Landsat 8, ASTER) | The photos a volcano mission sends home: Cotopaxi, Sangay |
| [LRO LROC](https://www.lroc.asu.edu/) and ShadowCam ([NASA Science](https://science.nasa.gov/image-article/apod-2023-may-5-shackleton-from-shadowcam/)) | The photos from the Moon's south pole |
| [NASA Deep Space Network](https://www.nasa.gov/communicating-with-missions/dsn/) | Ground control's stations (Goldstone, Madrid, Canberra) and its mini-games |
| [Apollo Flight Journal](https://www.nasa.gov/history/afj/) and [Apollo Lunar Surface Journal](https://www.nasa.gov/history/alsj/) | The far-side braking without radio, the 1202 alarm, Apollo 13's adapter |
| NASA mission pages of Apollo 13, STS-61, Mars Pathfinder, LCROSS, DART and Artemis I | Every date and figure of the story; NASA photos close each chapter |
| [Design and Develop Science Missions](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf), [Concept Maturity Levels](https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299) (JPL), [CubeSat 101](https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf) | The structure of the design and its stages |
| Partner: [NOAA Space Weather Prediction Center](https://www.swpc.noaa.gov/noaa-scales-explanation) | The space weather alerts of the operation, on NOAA's G and S scales |

Every number, formula, dataset, image and model from outside is cited where it is used and listed once, with its
link, in [`docs/sources.md`](docs/sources.md) (more than 80 sources). The in-game credits are built from that list.

## Play it, or run it yourself

- **In the browser:** https://farpoint-horizon.web.app
- **On your computer:** install [Godot 4.7](https://godotengine.org), import `project.godot` and press F5. It uses
  the Compatibility renderer, so integrated GPUs work.
- **Controls:** the mouse for everything. In flight, the arrows steer, `W`/`S` set the throttle, `Space` acts, and
  `,` and `.` slow or speed up time.

## How it is built

Godot 4.7 (GL Compatibility, one web build that runs on any static host), GDScript, Firebase Hosting. Every 3D model
of ours is made by a Python script in Blender (`assets/source/`). The sounds are synthesized in code. The content
(parts, missions, orbits, the story) lives in `data/*.json`, apart from the logic, and every entry carries its
source. Automated tests fly the launch, the trip and the landing and check them against real values. Every push runs
them on CI. See [`docs/architecture.md`](docs/architecture.md).

## Use of AI

AI tools helped build this project, as the challenge rules ask us to disclose. The idea, the design decisions, the
story and the balance are the team's.

- **Claude Code** (Anthropic), models Claude Opus 5.5 and Claude Sonnet: code, documents and research notes.
- **Antigravity** and **Cursor** (model Composer 2.5): code help and a feasibility test of the web build.
- **Meshy** and **TRELLIS** (Microsoft, run on Hugging Face): 3D drafts used as references for the four cuy crew
  models. Rumi's body is a TRELLIS mesh. The heads and the other three cuyes were modelled in Blender by our scripts
  (`assets/source/crew_*.py`).
- **Claude** (Anthropic): the game's music (`audio/music_horizon*.ogg`) was generated with AI. Its files say so in
  their metadata, and the in-game credits say so too.

No AI-generated images or videos are used: imagery is NASA's and models come from our scripts and cited libraries.
No NASA logos, insignia or mission patches appear anywhere in the game.

## Credits

- Engine: [Godot Engine](https://godotengine.org) (MIT). 3D: [Blender](https://www.blender.org) (GPL), driven by
  our scripts.
- Font: Inter by Rasmus Andersson, [SIL Open Font License 1.1](https://rsms.me/inter/).
- Outside 3D models: Merlin Engine by hoahluke, Merlin 1D Vacuum by MartianDays, Rocket Nozzle Part by Zachary
  (corncob_127), all Sketchfab, CC BY 4.0; the Space Shuttle Solid Rocket Booster from NASA 3D Resources.
- NASA imagery and data: see above and [`docs/sources.md`](docs/sources.md).

## Team SK Horizon (Quito, Ecuador)

- **Alexander Kholodov**: team lead. The real physics of the flight, the Moon landing, ground control, the crew room
  and the NASA data. [GitHub](https://github.com/alexanderkholodov1)
- **Sebastián Amaguaya**: the rocket builder, the 3D models and the cuy crew, the visual identity, the story missions,
  the music and every sound. [GitHub](https://github.com/XebaxCode)

## Demo, pitch and license

- Demo video (29 s): https://youtu.be/3xZdPJr71bg (also in [`docs/demo/`](docs/demo/))
- Pitch deck (7 slides, English and Spanish): [`docs/pitch/build/`](docs/pitch/build/)
- Submission texts, ready to paste (English and Spanish): [`docs/submission/`](docs/submission/)
- License: MIT, see [LICENSE](LICENSE).

---

## Resumen en español

**No lees sobre una misión espacial: la vuelas.** Farpoint HORIZON es un juego 3D hecho en Quito para el NASA
Space Apps Challenge 2026. Diseñas una nave y el cohete que la lleva, vuelas el ascenso desde la línea ecuatorial, el
encendido hacia la Luna y el alunizaje sobre el mapa real del polo sur lunar de la NASA (LOLA), y luego mantienes viva
la misión desde tierra. Cada decisión pesa sobre las demás: masa, energía, datos, delta-v, presupuesto y vida útil.
En la versión 0.3.0, cuatro cuyes astronautas te llevan por seis misiones reales de la NASA en orden (Apollo 13,
STS-61, Mars Pathfinder, LCROSS, DART y Artemis I), con la historia tal como la cuenta la NASA. Todo lo que se mueve
sigue la física real, en tiempo real y a escala verdadera, y cada número está citado en
[`docs/sources.md`](docs/sources.md). Fallar no es una pantalla de derrota: entiendes por qué, cambias algo y vuelves
a volar. Juega en https://farpoint-horizon.web.app.
