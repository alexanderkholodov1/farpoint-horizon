# Sources

The bibliography of Farpoint HORIZON: every outside source of a number, formula, fact, dataset, model, image or sound
used in the game or its documents, once, with an ID. Wherever a value is used (a data field, a code comment, a
document), it cites the ID here: `[S3]`. The README and the game's credits are built from this list.

Format of an entry: **ID**, who published it, title, year, link, and what we use it for. A value we simplified says
so where it is used and cites what it simplifies. Research notes in `kb/` keep their own links; a value moves here
when the game or the pitch uses it.

New entries go at the end of their section with a short unique word as ID (`S-horizons`, `S-gibs-viirs`), never a
new number: branches built in parallel would collide on numbers. S1-S15 keep theirs. Git keeps both sides when two
branches add entries at the same place (`.gitattributes`).

## Challenge and NASA resources
- **S1** NASA Space Apps Challenge. *Space Mission Design Game* (challenge statement and resources). 2026.
  https://www.spaceappschallenge.org/2026/challenges/space-mission-design-game/ (copy in `docs/challenge/`). The brief.
- **S2** NASA. *Design and Develop Science Missions*. 2025.
  https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf. The four mission
  segments (launch, space, ground, user) and the path from need to mission.
- **S3** Wessen, R. R., Borden, C., Ziemer, J., Kwok, J. (NASA Jet Propulsion Laboratory). *Space Mission Concept Development Using Concept Maturity
  Levels*. https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299. The game's stages follow CML 1-4.
- **S4** NASA CubeSat Launch Initiative. *CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers*.
  https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf. CubeSat platforms, rideshare,
  constraints.
- **S5** NASA Goddard Space Flight Center. *Mission Design Lab*.
  https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/. Inspiration for the design
  stations.
- **S6** NASA. *Build It Yourself: Webb Telescope* (game). https://science.nasa.gov/mission/webb/game-build-it-yourself/.
  Inspiration: incompatible options shown greyed with the reason; the real mission shown after the design.

## Spacecraft and physics
- **S7** Cal Poly CubeSat Program. *CubeSat Design Specification, Rev. 14*. 2022.
  https://www.nasa.gov/wp-content/uploads/2018/01/cubesatdesignspecificationrev14_12022-02-09.pdf. The 3U envelope
  (100 x 100 x 340.5 mm) and rails of the CubeSat model.
- **S8** NASA Space Science Data Coordinated Archive. *Earth Fact Sheet*.
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html. Earth's radius, gravitational parameter, solar
  constant.
- **S9** NASA Orbital Debris Program Office. *Frequently Asked Questions*. https://orbitaldebris.jsc.nasa.gov/faq/.
  Orbital lifetime against altitude.
- **S10** NASA Glenn Research Center. *Ideal Rocket Equation*.
  https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/ideal-rocket-equation/. Fuel needed for a change of
  velocity.

- **S-nasa-soa** NASA Small Spacecraft Systems Virtual Institute. *State-of-the-Art of Small Spacecraft Technology*.
  https://www.nasa.gov/smallsat-institute/sst-soa/. Typical mass, power, data rate, pointing and delta-v of small
  spacecraft platforms, solar arrays, batteries, radios, attitude control and propulsion (chapters on platforms,
  power, communications, guidance and navigation, in-space propulsion). The game's parts are rounded from it.
- **S-eoportal** European Space Agency. *eoPortal, Satellite Missions Directory*. https://www.eoportal.org/satellite-missions.
  Mass, power and data of the real instruments (Landsat 8 OLI and TIRS, Sentinel-2 MSI, Sentinel-1, TROPOMI, ICESat-2,
  TESS and others, listed in `kb/data/reference.json`, category instrument) that the game's instrument archetypes round.
- **S-gsfc-std-1000** NASA Goddard Space Flight Center. *GSFC-STD-1000 Rev I, Rules for the Design, Development,
  Verification and Operation of Flight Systems*, Rule 1.06 and Table 1.06-1.
  https://standards.nasa.gov/system/files/tmp/GSFC-STD-1000RevI_Approved_0.pdf. Mass margin above 10 % and power margin
  above 15 %, the margins of the Systems Engineer's goal.
- **S-ntrs-dod** NASA Technical Reports Server. *Lithium-ion battery depth of discharge in low Earth orbit*, 2007.
  https://ntrs.nasa.gov/citations/20070022412. Why the game uses 60 % of the battery per eclipse.
- **S-wiki-geo** Wikipedia. *Geostationary orbit*. https://en.wikipedia.org/wiki/Geostationary_orbit. Altitude 35,786 km,
  period 1,436 min, continuous view of one hemisphere.
- **S-wiki-dv** Wikipedia. *Delta-v budget*. https://en.wikipedia.org/wiki/Delta-v_budget. Delta-v from low Earth orbit to
  geostationary and lunar orbits.
- **S-wiki-iss** Wikipedia. *International Space Station*. https://en.wikipedia.org/wiki/International_Space_Station.
  Altitude near 400 km and inclination 51.6 degrees of the low orbit.
- **S-wiki-sso** Wikipedia. *Sun-synchronous orbit*. https://en.wikipedia.org/wiki/Sun-synchronous_orbit. Altitude near
  700 km and inclination near 98 degrees, same local solar time on every pass.
- **S-webb-orbit** NASA. *Webb's orbit*. https://science.nasa.gov/mission/webb/orbit/. The Sun-Earth L2 point, 1.5 million
  km from Earth, and why a telescope sits there.
## Launchers
- **S13** Rocket Lab. *Electron*. https://rocketlabcorp.com/launch/electron/; figures as given in Wikipedia, *Rocket Lab
  Electron* (infobox, checked 2026-11-14), https://en.wikipedia.org/wiki/Rocket_Lab_Electron. Height 18 m, diameter
  1.2 m, nine first-stage engines: the light launcher model.
- **S14** SpaceX. *Falcon 9*. https://www.spacex.com/vehicles/falcon-9/; figures as given in Wikipedia, *Falcon 9*
  (infobox and performance table, checked 2026-11-14), https://en.wikipedia.org/wiki/Falcon_9. Height about 70 m,
  diameter 3.7 m, fairing 5.2 m across and 13 m long, nine first-stage engines: the medium launcher model.
- **S15** SpaceX. *Falcon Heavy*. https://www.spacex.com/vehicles/falcon-heavy/; figures as given in Wikipedia, *Falcon
  Heavy* (infobox, checked 2026-11-14), https://en.wikipedia.org/wiki/Falcon_Heavy. Height 70 m, width 12.2 m, three
  cores of 3.7 m: the heavy launcher model.

- **S-rideshare-price** New Space Economy. *SpaceX rideshare pricing as of February 2026*, 2026.
  https://newspaceeconomy.ca/2026/02/27/spacex-rideshare-pricing-as-of-february-2026-what-it-costs-whats-included-and-how-buyers-budget-a-mission/.
  About 7,000 $/kg for a rideshare to low orbit; the game uses 6,500 $/kg.

## Rocket parts (the builder)
- **S-merlin-model** hoahluke. *Merlin Engine* (3D model). Sketchfab, CC BY 4.0.
  https://sketchfab.com/3d-models/merlin-engine-b6725717165c4c0db0e4e2d744370a51. The sea-level engines of the large
  first stage (`assets/parts/engine_merlin_x9.glb`).
- **S-mvac-model** MartianDays. *Merlin 1D Vacuum* (3D model). Sketchfab, CC BY 4.0.
  https://sketchfab.com/3d-models/merlin-1d-vacuum-f20ebb6e857b405cbdc66568d48d2fcb. The large vacuum engine
  (`assets/parts/engine_merlin_vac.glb`).
- **S-nozzle-model** Zachary (corncob_127). *Rocket Nozzle Part* (3D model). Sketchfab, CC BY 4.0.
  https://sketchfab.com/3d-models/rocket-nozzle-part-e86374e66a4d462684b9826cedafe815. The small engines
  (`assets/parts/engine_small_x9.glb`, `engine_small_vac.glb`).
- **S-srb-model** NASA 3D Resources. *Space Shuttle Parts: Solid Rocket Booster* (3D model). Public domain (NASA media usage
  guidelines). https://github.com/nasa/NASA-3D-Resources/tree/master/3D%20Models/Space%20Shuttle%20Parts. The side
  boosters (`assets/parts/booster_srb.glb`); no insignia on its texture.
- **S-merlin** Wikipedia. *SpaceX Merlin* (infobox, checked 2026-11-14). https://en.wikipedia.org/wiki/SpaceX_Merlin.
  Merlin 1D: 845 kN at sea level, Isp 282 s (sea level) and 311 s (vacuum), 470 kg, 0.92 m; Merlin 1D Vacuum: 981 kN,
  348 s, 3.3 m nozzle.
- **S-rutherford** Wikipedia. *Rutherford (rocket engine)* (infobox, checked 2026-11-14).
  https://en.wikipedia.org/wiki/Rutherford_(rocket_engine). 25 kN at sea level, 26 kN in vacuum, Isp 311 s and 343 s,
  35 kg.
- **S-srb** Wikipedia. *Space Shuttle Solid Rocket Booster* (infobox and text, checked 2026-11-14).
  https://en.wikipedia.org/wiki/Space_Shuttle_Solid_Rocket_Booster. 45.46 m by 3.71 m, 91 t empty, 500 t of
  propellant, about 12 MN at liftoff, Isp 242 s (sea level) and 268 s (vacuum), 123 s burn.
- **S-delta-v** Wikipedia. *Delta-v budget* (checked 2026-11-14). https://en.wikipedia.org/wiki/Delta-v_budget. Earth to low
  orbit 9.3-10 km/s with losses; low orbit to the geostationary transfer orbit 2.3 km/s; translunar injection 3.20 km/s.
- [S13] and [S14] also give the stage lengths and masses the parts are cut from: Falcon 9 first stage 25.6 t empty and
  395.7 t of propellant, second stage 3.9 t and 92.67 t, fairing about 1.9 t; Electron 13.0 t at liftoff, stages of
  12.1 m and 2.4 m, fairing 44 kg.

## Real missions
- **S11** NASA. *Landsat 9*. https://science.nasa.gov/mission/landsat-9. Orbit and coverage of an Earth-imaging twin.
- **S12** European Space Agency, Copernicus. *Sentinel-2 mission*. https://sentiwiki.copernicus.eu/web/s2-mission.
  Orbit and coverage of an Earth-imaging twin.

- **S-sentinel5p** European Space Agency, eoPortal. *Copernicus Sentinel-5P*.
  https://www.eoportal.org/satellite-missions/copernicus-sentinel-5p. Measures gases such as SO2 (volcano scenario).
- **S-aster** Wikipedia. *Advanced Spaceborne Thermal Emission and Reflection Radiometer*.
  https://en.wikipedia.org/wiki/Advanced_Spaceborne_Thermal_Emission_and_Reflection_Radiometer. Thermal images (volcano scenario).
- **S-sentinel6** Wikipedia. *Sentinel-6 Michael Freilich*. https://en.wikipedia.org/wiki/Sentinel-6_Michael_Freilich.
  Sea level height and the Jason series it continues (ocean scenario).
- **S-smap** Wikipedia. *Soil Moisture Active Passive*. https://en.wikipedia.org/wiki/Soil_Moisture_Active_Passive.
  Microwave radiometer of the ocean scenario.
- **S-lro** NASA. *Lunar Reconnaissance Orbiter*. https://science.nasa.gov/mission/lro/. Real twin of the lunar scenario.
- **S-chandrayaan2** Wikipedia. *Chandrayaan-2*. https://en.wikipedia.org/wiki/Chandrayaan-2. Real twin of the lunar scenario.
- **S-hubble** ESA and NASA. *Hubble Space Telescope fact sheet*. https://esahubble.org/about/general/fact_sheet/. Low orbit
  telescope of the astronomy scenario.
- **S-pegaso** Wikipedia. *NEE-01 Pegaso*. https://en.wikipedia.org/wiki/NEE-01_Pegaso. The first Ecuadorian satellite, a
  1U CubeSat launched in 2013 (shown in the report of a CubeSat mission).
- **S-capstone** Wikipedia. *CAPSTONE*. https://en.wikipedia.org/wiki/CAPSTONE. A 12U CubeSat in lunar orbit, 2022 (shown in
  the report of a lunar CubeSat mission).

## Still to add
- The sources of `data/*.json` are listed above. Each value of an entry that mixes sources still has to be checked
  against the agency page (the catalogs cite the family of sources and say what they simplify; the values are rounded
  and not yet checked one by one).
- The source and license of `textures/earth_albedo.jpg`.
- The fonts, the engine and every library, model, image and sound, with their licenses.

## NASA data used by the mission photos and the route numbers (issue 19; pipeline in `tools/data/`)
All checked 2026-11-14. NASA media are used under the NASA Media Usage Guidelines
(https://www.nasa.gov/nasa-brand-center/images-and-media/): no NASA logo or insignia, no implied endorsement.
- **S-gibs** NASA ESDIS, Global Imagery Browse Services (GIBS), NASA Worldview, WMS
  https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi. Tested for the volcano photos (VIIRS 250 m) and replaced by
  S-eo for being soft; kept as the source of the Earth texture recommended in `kb/research/nasa-data.md`
  (layer `BlueMarble_NextGeneration`). Credit: "NASA GIBS / Worldview".
- **S-eo** NASA Earth Observatory (science.nasa.gov/earth/earth-observatory), image pages with their full-size files:
  Sangay (Landsat 8 OLI, 5 Nov 2022, https://science.nasa.gov/earth/earth-observatory/a-line-of-ash-from-sangay-150650/),
  Cotopaxi (Landsat 8 OLI, 15 Sep 2015, https://science.nasa.gov/earth/earth-observatory/cotopaxi-volcano-ecuador-86618/),
  Tungurahua (EO-1 ALI natural and short-wave infrared, 1 Jan 2011,
  https://science.nasa.gov/earth/earth-observatory/ongoing-eruption-of-tungurahua-ecuador-48337/). In
  `assets/mission_photos/volcano_watch/`. Credits as the pages print them: "NASA Earth Observatory images by Lauren
  Dauphin / Jesse Allen, using Landsat data from the U.S. Geological Survey" (Landsat data are public domain, USGS);
  "NASA Earth Observatory image created by Jesse Allen, using EO-1 ALI data provided courtesy of the NASA EO-1 team and
  the U.S. Geological Survey". Our processing: cropped to the volcano, resized.
- **S-nasa-science** NASA Science (science.nasa.gov) resource and image pages, for the Moon: Shackleton crater rim,
  credit "NASA/GSFC/Arizona State University" (https://science.nasa.gov/resource/shackleton-craters-illuminated-rim-shadowed-interior/);
  Shackleton floor seen by ShadowCam, a NASA instrument on the Korean KPLO orbiter, credit as printed "NASA, ShadowCam,
  Korea Aerospace Research Institute, Arizona State University" (https://science.nasa.gov/image-article/apod-2023-may-5-shackleton-from-shadowcam/;
  the Korean partner is named in the credit; no separate terms found). In `assets/mission_photos/moon_south_pole/`.
- **S-lroc-wac** NASA/GSFC/Arizona State University, Lunar Reconnaissance Orbiter Camera (LROC) Wide Angle Camera global
  mosaic (100 m), served by NASA Moon Trek, https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0/WMTSCapabilities.xml.
  Photos in `assets/mission_photos/moon_south_pole/`. Credit: "NASA/GSFC/Arizona State University, LRO". Our processing:
  tiles joined and re-projected to a view from above the south pole.
- **S-nasa-images** NASA Image and Video Library, https://images.nasa.gov (API https://images-api.nasa.gov), records
  PIA00022 (Jupiter, Voyager 1), PIA01374 (Saturn, Voyager 1), PIA18182 (Uranus, Voyager 2), PIA00049 (Neptune,
  Voyager 2); catalogued by NASA/JPL Photojournal. Photos in `assets/mission_photos/grand_tour/`. Credit: "NASA/JPL-Caltech".
  Our processing: resized. Also the ASTER pictures in `assets/mission_photos/volcano_watch/`: PIA23914 (Sangay, night
  thermal infrared, 11 Jun 2020, credit "NASA/METI/AIST/Japan Space Systems, and U.S./Japan ASTER Science Team") and
  PIA15151 (Cotopaxi, false colour, 22 Aug 2015, credit "NASA/GSFC/METI/ERSDAC/JAROS, and U.S./Japan ASTER Science
  Team"); ASTER is a joint Japanese (METI) and NASA instrument on Terra, hence the credit.
- **S-horizons** NASA/JPL Solar System Dynamics. *Horizons System API*. https://ssd-api.jpl.nasa.gov/doc/horizons.html
  (endpoint https://ssd.jpl.nasa.gov/api/horizons.api). Orbital elements of the eight planets at 2026-11-15 and the Moon
  around the Earth for a month, in `data/nasa/horizons_*.json`. Credit: "NASA/JPL Horizons".
- **S-nssdc-planets** NASA Space Science Data Coordinated Archive. *Planetary Fact Sheets*.
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/ . Mass, radius, gravity, escape velocity, orbit radius and day length
  of the planets and the Moon, in `data/nasa/nssdc_factsheets.json`. Credit: "NASA NSSDC Planetary Fact Sheets".

## The pilot's flight and the Moon's south pole (issue 8)
All checked 2026-11-14.
- **S-lola** Smith, D. E., et al. (NASA Goddard Space Flight Center), Lunar Orbiter Laser Altimeter (LOLA) on the Lunar
  Reconnaissance Orbiter. *LRO-L-LOLA-4-GDR-V1.0, product LDEM_875S_20M* (south polar elevation map, 20 m per pixel,
  version 2.0, 2017), NASA Planetary Data System, Geosciences Node.
  https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/img/ldem_875s_20m.lbl.
  The ground of the landing: a 12 km square around the south pole and Shackleton's rim, averaged to 60 m, in
  `data/nasa/lola_south_pole.json` (made by `tools/data/fetch_lola_terrain.py`). Credit: "NASA/GSFC LOLA team, NASA PDS".
- **S-svs-south-pole** NASA Scientific Visualization Studio. *Shadows near the Moon's South Pole*, 2021.
  https://svs.gsfc.nasa.gov/4893. At the poles the Sun is never more than 1.5 degrees above or below the horizon;
  places it never reaches are permanently shadowed and trap water ice.
- **S-chandrayaan3** Wikipedia. *Chandrayaan-3* (infobox and text). https://en.wikipedia.org/wiki/Chandrayaan-3.
  Launched 14 July 2023 on LVM3 M4, landed 23 August 2023 at 69.373 S; lander Vikram 1,726 kg; the hop of about 40 cm
  (ISRO, 4 September 2023, as cited there). Real twin of the south pole mission.
- **S-im1** Wikipedia. *IM-1* (text). https://en.wikipedia.org/wiki/IM-1. Intuitive Machines' Odysseus, launched
  15 February 2024 on Falcon 9, landed 22 February 2024 at Malapert A (80.13 S); landed faster than planned on a
  12-degree slope, broke a leg, tipped onto its side and kept returning data until the lunar night, about a week.
  Real twin of the south pole mission; the game's tipping slope.
- **S-apollo11** Wikipedia. *Apollo 11* (mission timeline). https://en.wikipedia.org/wiki/Apollo_11. Launched
  16 July 1969 13:32 UTC, entered lunar orbit 19 July 17:21 UTC (about 76 hours), landed 20 July; the 1201 and 1202
  alarms began about five minutes into the descent burn. The trip time of the coast to the Moon.
- **S-alsj-1202** Adler, P. *Apollo 11 Program Alarms*, Apollo Lunar Surface Journal (NASA), 1998.
  https://www.nasa.gov/wp-content/uploads/static/history/alsj/a11/a11.1201-pa.html. What the 1202 alarm meant (no free
  core sets for new jobs), why the computer kept steering after its restarts, and why Mission Control could call go.
  The descent alarm the pilot and ground control face.
- **S-apollo-gear** Rogers, W. F. (NASA Johnson Space Center). *Apollo Lunar Module Landing Gear*, 1972. NASA Technical
  Reports Server 19730010151, https://ntrs.nasa.gov/citations/19730010151. A landing is decided mainly by the touchdown
  speed and the slope of the ground under the legs; the game's touchdown bands use those two (their values are ours).
