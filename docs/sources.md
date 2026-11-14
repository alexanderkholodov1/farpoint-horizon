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

## Real missions
- **S11** NASA. *Landsat 9*. https://science.nasa.gov/mission/landsat-9. Orbit and coverage of an Earth-imaging twin.
- **S12** European Space Agency, Copernicus. *Sentinel-2 mission*. https://sentiwiki.copernicus.eu/web/s2-mission.
  Orbit and coverage of an Earth-imaging twin.

## Still to add
- Every value in the game's catalogs (`scripts/game_data.gd` today, `data/*.json` after step B2), from
  `kb/data/reference.json` and `kb/data/missions.json`, checked against agency pages where they came from secondary
  sources.
- The source and license of `textures/earth_albedo.jpg`.
- The fonts, the engine and every library, model, image and sound, with their licenses.

## NASA data used by the mission photos and the route numbers (issue 19; pipeline in `tools/data/`)
All checked 2026-11-14. NASA media are used under the NASA Media Usage Guidelines
(https://www.nasa.gov/nasa-brand-center/images-and-media/): no NASA logo or insignia, no implied endorsement.
- **S-gibs** NASA ESDIS, Global Imagery Browse Services (GIBS), NASA Worldview. Layers
  `VIIRS_SNPP_CorrectedReflectance_TrueColor` and `VIIRS_SNPP_Thermal_Anomalies_375m_All` (instrument VIIRS on Suomi NPP,
  a real twin of Volcano Watch), WMS https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi. Photos of Sangay,
  Reventador and Cotopaxi, 2024-08-31, in `assets/mission_photos/volcano_watch/`. Credit: "NASA GIBS / Worldview,
  VIIRS Suomi NPP". Our processing: hot-spot pixels enlarged and drawn in red.
- **S-lroc-wac** NASA/GSFC/Arizona State University, Lunar Reconnaissance Orbiter Camera (LROC) Wide Angle Camera global
  mosaic (100 m), served by NASA Moon Trek, https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0/WMTSCapabilities.xml.
  Photos in `assets/mission_photos/moon_south_pole/`. Credit: "NASA/GSFC/Arizona State University, LRO". Our processing:
  tiles joined and re-projected to a view from above the south pole.
- **S-nasa-images** NASA Image and Video Library, https://images.nasa.gov (API https://images-api.nasa.gov), records
  PIA00022 (Jupiter, Voyager 1), PIA01374 (Saturn, Voyager 1), PIA18182 (Uranus, Voyager 2), PIA00049 (Neptune,
  Voyager 2); catalogued by NASA/JPL Photojournal. Photos in `assets/mission_photos/grand_tour/`. Credit: "NASA/JPL-Caltech".
  Our processing: resized.
- **S-horizons** NASA/JPL Solar System Dynamics. *Horizons System API*. https://ssd-api.jpl.nasa.gov/doc/horizons.html
  (endpoint https://ssd.jpl.nasa.gov/api/horizons.api). Orbital elements of the eight planets at 2026-11-15 and the Moon
  around the Earth for a month, in `data/nasa/horizons_*.json`. Credit: "NASA/JPL Horizons".
- **S-nssdc-planets** NASA Space Science Data Coordinated Archive. *Planetary Fact Sheets*.
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/ . Mass, radius, gravity, escape velocity, orbit radius and day length
  of the planets and the Moon, in `data/nasa/nssdc_factsheets.json`. Credit: "NASA NSSDC Planetary Fact Sheets".
