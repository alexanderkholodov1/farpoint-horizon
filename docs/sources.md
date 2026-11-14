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
