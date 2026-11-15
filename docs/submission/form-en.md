# NASA Space Apps 2026: submission form, every field ready to paste

Challenge: **Space Mission Design Game**. Team: **SK Horizon** (Quito, Ecuador; local event Sangolquí, ESPE).
Fields in the order the form shows them. Text inside the boxes is what goes into the form; notes outside are for us.
The form closes **Sunday 15 November 2026, 23:59 local time**, and only the last "Submit for Judging" counts.
Open every link in a private window before submitting.

---

## Project Name

```
Farpoint HORIZON
```

(The form had "Project SK-Horizons": the team is SK Horizon, the project is Farpoint HORIZON.)

---

## Summary  (limit 1500 characters; they suggest 50-200 words; this one: 198 words, 1,128 characters)

```
You don't read about a space mission in Farpoint HORIZON: you fly one. Students learn orbits, rockets and instruments in separate chapters and never see how one choice pulls on all the others. Our 3D browser game closes that gap with the whole mission in one chain. Choose a science question, from Ecuador's volcanoes to ice at the Moon's south pole. Design the craft and stack your own rocket while live gauges trade mass, power, data, delta-v, budget and lifetime. Then fly it: a real-physics climb from the equator, a trip to the Moon timed to JPL Horizons, and a landing on NASA's LOLA map of Shackleton's rim. Keep it alive from the ground through the Deep Space Network and NOAA's solar storms. Everything moves by real physics, in real time and at true scale, checked against real missions, and every number cites its source. Failing is never a game-over screen: you see why, change one thing and fly again. In v0.3.0, four Andean guinea-pig astronauts (cuyes) guide players through six real NASA missions in order, from Apollo 13 to Artemis I. One player or a team of four can play, in English or Spanish, on any device.
```

---

## Project Demonstration  (a public link: a video of 30 s or less, or at most 7 slides)

```
https://youtu.be/3xZdPJr71bg
```

(29 seconds, recorded from the game itself. Check that it is Public or Unlisted, not Private, and that it opens in a
private window. The deck is the alternative: a public Drive or GitHub link to the 7-slide PDF.)

---

## Project  (a public link to the project)

```
https://farpoint-horizon.web.app
```

(The game itself. The repository, https://github.com/alexanderkholodov1/farpoint-horizon, is linked from the Details
and from the game's credits. If the form allows only one link, the live game is the stronger one.)

---

## Project Details

```
WHAT IT IS
Farpoint HORIZON is a 3D space-mission game that runs in any browser, with no install. One player, or a team of up to four, takes a mission from a science question to data coming home, and lives every trade-off a real mission team faces along the way.

THE PROBLEM WE SOLVE
A space mission is one system: a better instrument is heavier, a heavier craft needs a bigger rocket, a bigger rocket eats the budget, more data needs more power and a faster radio. Students meet these ideas one at a time, in separate classes and tools (an orbit calculator here, a rocket simulator there), and almost never see how they pull on each other. The challenge asks for a game that closes that gap. Ours puts the whole chain in the player's hands.

HOW IT WORKS
1. Ask a question. Every mission starts with a need: watch Ecuador's volcanoes, follow El Niño, map the Moon, look at distant galaxies, find ice at the lunar south pole. The steps follow NASA JPL's Concept Maturity Levels.
2. Design. Choose the orbit (5, each explained in plain words), the platform (from a 3U CubeSat to a large observatory, 6 in all), 16 instruments, solar panels, battery, radio, attitude control, propulsion and lifetime. Live gauges show mass, power, data, delta-v, cost and years at every choice. The craft is assembled in 3D, and the part causing a problem glows on it.
3. Build the rocket. Stack real engines, tanks and boosters; the rocket equation decides what reaches orbit. With no tuning, the presets match the real vehicles: an Electron-type rocket carries 313 kg to low orbit (real: 300 kg), a Falcon 9-type 17.2 t (real: about 17.5 t). The review blocks a launch that cannot work and says where to fix it.
4. Fly it. The launch is about eight minutes of real climb from the equator, over the Andes and Cotopaxi, with gravity, drag, Max-Q and staging. The trip to the Moon uses the pull of both the Earth and the Moon, with the Moon where JPL Horizons puts it on the flight day. Mission control times the departure so the craft meets the Moon where it will be. Then a mid-course correction, braking into lunar orbit on the far side with no radio (as Apollo's crews did), and a powered landing on NASA LOLA elevation data at Shackleton crater's rim.
5. Ground control. Find the craft's faint carrier through the Deep Space Network (as engineers did for Voyager 2 in 2023), answer the computer's 1202 alarm (as Apollo 11 did), and decide how to ride out a solar storm forecast on NOAA's scales.
6. The report. A score out of 1000, a grade, extra goals, why the mission worked or not, the real photos a mission like yours sends home (Cotopaxi from Landsat 8, Shackleton crater from LRO and ShadowCam), and the real missions that made the same choices. Redesign and fly again in one click.

NEW IN v0.3.0: THE CUYES WHO WERE THERE
NASA learned by failing, bouncing and crashing, and it always came back. A crew of four cuy astronauts (the Andean guinea pig) takes the player through six real NASA missions in the order they happened. History stays exactly as NASA tells it; the cuyes help, panic and joke, while the real numbers decide what happens. Each crew member is one of the game's four stations: Rumi the engineer, Killa the scientist, Inti the pilot, Wayra ground control.
- Apollo 13 (1970): build the CO2 adapter from bags, cardboard and tape before the air runs out.
- STS-61 (1993): five spacewalks against their clocks to fix Hubble, then bring galaxy M100 into focus.
- Mars Pathfinder (1997): the real descent, the airbag bounces, and Sojourner's first wheel on Mars.
- LCROSS (2009), DART (2022) and Artemis I (2022) complete the campaign.

WHY IT IS DIFFERENT
- The whole system in one game. Each choice shows up everywhere downstream, which is exactly what the challenge asks players to understand.
- Real behaviour, never a drawing. Nothing moves along a hand-drawn curve. Paths come from gravity with real constants and ephemerides. Time runs in real time, faster time is a visible control, and sizes and distances keep their true proportions.
- Checked against reality. Automated tests fly the game and compare it with real values: a 87.7-minute low orbit, a coast to the Moon of about 82 h (Apollo 11: 76 h), a lunar orbit of about 110 km. Our simplifications are written where they are made.
- NASA data is the ground you fly over and land on, not decoration.
- Failure teaches instead of punishing. Missing something is never a game-over screen; achieving more is rewarded.
- Built for everyone. A guided first mission, a cited glossary, one-line explanations, English and Spanish, and it runs on school computers, tablets and phones.
- Made to be played together. Four stations each own their decisions, like a real mission team, and bots that follow the same rules take any empty station.

BENEFITS AND INTENDED IMPACT
Students, teachers and space fans get an environment where they can try a whole mission, fail safely and understand why. Teachers can run a mission as a class activity in a browser. Because it is made in Ecuador, launches from the equator and opens with a mission that watches our own volcanoes, it brings space engineering close to Latin American students in their own language.

TOOLS AND TECHNOLOGY
Godot 4.7 (GL Compatibility renderer, single-threaded web export, so it runs on integrated GPUs and any static host), GDScript, Python (data pipelines and 3D model scripts), Blender driven by scripts for every model of ours, Firebase Hosting, GitHub Actions CI that runs the physics tests and builds the web version on every push. Content and balance live in JSON data files apart from the code, and every entry carries its source. More than 80 sources are cited in docs/sources.md and in the in-game credits. MIT license.

CREATIVITY AND FACTORS WE CONSIDERED
We chose real physics over scripted animation so that what players learn is true. We chose true scale with readable markers, real time with a visible clock, and a campaign told only from NASA's own pages. The cuyes bring humor and an Andean identity without changing history. We designed for low-end school hardware, for players who have never heard the word delta-v, for two languages, and for the challenge's rules: no NASA logos or insignia, and every AI use disclosed.

Repository: https://github.com/alexanderkholodov1/farpoint-horizon
Team SK Horizon, Quito, Ecuador: Alexander Kholodov (lead), Sebastián Amaguaya.
```

---

## Use of Super Intelligence (SI)  (checkboxes; not seen by the judges)

Tick every option that matches. The form's exact labels are not in our copy; pick by meaning:

- **Code:** yes (Claude Code, Antigravity, Cursor).
- **Text / documentation:** yes (Claude Code: documents and research notes).
- **Audio / music:** yes (the game's music was generated with Claude; the files' metadata and the in-game credits
  say so).
- **3D models**, or "Images" if there is no 3D option: yes, as drafts (Meshy and TRELLIS gave references for the
  cuy crew; Rumi's body is a TRELLIS mesh). If the options include it, say it is a 3D model and not an image.
- **Images and video:** no AI-generated images or videos are used.

If the form has a text box for details, paste:

```
Code and documents: Claude Code (Anthropic, Claude Opus 5.5 and Sonnet), Antigravity and Cursor (Composer 2.5). Music: generated with Claude (Anthropic), declared in the audio files' metadata and the in-game credits. 3D: Meshy and TRELLIS (Microsoft, via Hugging Face) drafts as references for the four cuy crew models; Rumi's body is a TRELLIS mesh, the rest modelled in Blender by our scripts. No AI-generated images or videos; no NASA logos, insignia or mission identifiers anywhere. The idea, design, story and balance are the team's. Full disclosure in the README.
```

---

## NASA Data  (one row per resource: Link Text | Link Url)

| Link Text | Link Url |
|---|---|
| LRO LOLA south polar elevation map LDEM_875S_20M (NASA PDS) | https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/img/ldem_875s_20m.lbl |
| JPL Horizons API (Moon and planet positions) | https://ssd-api.jpl.nasa.gov/doc/horizons.html |
| NASA GIBS (Blue Marble, Black Marble, VIIRS, shaded relief) | https://nasa-gibs.github.io/gibs-api-docs/ |
| NASA Worldview | https://worldview.earthdata.nasa.gov |
| CGI Moon Kit (NASA SVS, LRO LROC and LOLA) | https://svs.gsfc.nasa.gov/4720 |
| SRTM elevation (the Andes under the launch site) | https://www.earthdata.nasa.gov/data/instruments/srtm |
| NSSDC Planetary Fact Sheets | https://nssdc.gsfc.nasa.gov/planetary/factsheet/ |
| NASA Earth Observatory (Landsat 8 and ASTER images of Cotopaxi and Sangay) | https://science.nasa.gov/earth/earth-observatory/ |
| Shackleton crater from ShadowCam (NASA Science) | https://science.nasa.gov/image-article/apod-2023-may-5-shackleton-from-shadowcam/ |
| NASA Deep Space Network | https://www.nasa.gov/communicating-with-missions/dsn/ |
| Apollo Flight Journal | https://www.nasa.gov/history/afj/ |
| Apollo Lunar Surface Journal (Apollo 11 program alarms) | https://www.nasa.gov/history/alsj/ |
| Apollo 13 Mission Details (NASA) | https://www.nasa.gov/missions/apollo/apollo-13-mission-details/ |
| Design and Develop Science Missions (NASA S3VI) | https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf |
| Concept Maturity Levels (JPL) | https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299 |
| CubeSat 101 (NASA CSLI) | https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf |
| Ideal Rocket Equation (NASA Glenn) | https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/ideal-rocket-equation/ |
| NASA Orbital Debris Program Office FAQ | https://orbitaldebris.jsc.nasa.gov/faq/ |
| NASA 3D Resources (Space Shuttle Solid Rocket Booster model) | https://github.com/nasa/NASA-3D-Resources/tree/master/3D%20Models/Space%20Shuttle%20Parts |
| Full bibliography (every NASA source, with what it is used for) | https://github.com/alexanderkholodov1/farpoint-horizon/blob/main/docs/sources.md |

(Add the STS-61 and Mars Pathfinder pages from `docs/sources.md`, entries `S-sts61*` and `S-mpf*`, if there is room.)

---

## Space Agency Partner & Other Data

| Link Text | Link Url |
|---|---|
| NOAA Space Weather Prediction Center: space weather scales | https://www.swpc.noaa.gov/noaa-scales-explanation |
| Godot Engine (MIT) | https://godotengine.org |
| Blender (GPL) | https://www.blender.org |
| Inter typeface, Rasmus Andersson (SIL OFL 1.1) | https://rsms.me/inter/ |
| Merlin Engine 3D model, hoahluke (Sketchfab, CC BY 4.0) | https://sketchfab.com/3d-models/merlin-engine-b6725717165c4c0db0e4e2d744370a51 |
| Merlin 1D Vacuum 3D model, MartianDays (Sketchfab, CC BY 4.0) | https://sketchfab.com/3d-models/merlin-1d-vacuum-f20ebb6e857b405cbdc66568d48d2fcb |
| Rocket Nozzle Part 3D model, corncob_127 (Sketchfab, CC BY 4.0) | https://sketchfab.com/3d-models/rocket-nozzle-part-e86374e66a4d462684b9826cedafe815 |
| Launch vehicle and engine figures (Falcon 9, Electron, Merlin, J-2 and others) | https://github.com/alexanderkholodov1/farpoint-horizon/blob/main/docs/sources.md |
| Copernicus SentiWiki: Sentinel-2 mission | https://sentiwiki.copernicus.eu/web/s2-mission |
| U.S. Naval Observatory: Greenwich sidereal time | https://aa.usno.navy.mil/faq/GAST |
| NIST CODATA: speed of light | https://physics.nist.gov/cgi-bin/cuu/Value?c |
| Firebase Hosting (Google) | https://firebase.google.com/products/hosting |

---

## Project Submission Verification

- **Agree to Terms and Conditions:** tick it.
- **Confirm All Work is Original:** tick it. Everything outside is listed above and in `docs/sources.md`, and the
  outside models are CC BY 4.0 with credit.

## Before "Submit for Judging"

1. Every link opens in a private window: the game, the video, the repository, the sources page.
2. The YouTube video is Public or Unlisted.
3. The repository is public with `LICENSE` at the root (it is: MIT).
4. Save Progress first, then Submit for Judging. Only the last submit counts.
