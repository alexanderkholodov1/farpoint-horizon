# NASA data found for the game (issue 19)

## CHECKPOINT (2026-11-14)
Done: mission photos for the three missions, Horizons elements and Moon vectors, NSSDC fact sheets, pipeline
`tools/data/fetch_nasa_data.py` with README, manifest, `docs/sources.md` entries, texture recommendation (below).
Not done: nothing replaces any texture (recommendation only); the Moon texture file was not downloaded; the
Blue Marble source site (eoimages.gsfc.nasa.gov) timed out from this machine, so the GIBS copy was tested instead.

All queries were run on 2026-11-14 and returned data. Source IDs are in `docs/sources.md` (end of file).

## 1. Photos each mission returns
Reasoning for the game: the photos are what the craft "saw"; the game picks by instrument (true color = camera,
thermal = infrared sensor). Output: 11 JPEG, 834 KB in total.

| Mission | File | Source and request |
|---|---|---|
| volcano_watch | `sangay_2024-08-31_truecolor.jpg`, `_thermal.jpg`; same for `reventador`; `cotopaxi_2024-08-31_truecolor.jpg` | GIBS WMS 1.1.1, layer `VIIRS_SNPP_CorrectedReflectance_TrueColor`, e.g. Sangay: `https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi?SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&LAYERS=VIIRS_SNPP_CorrectedReflectance_TrueColor&SRS=EPSG:4326&BBOX=-78.69,-2.35,-77.99,-1.65&WIDTH=700&HEIGHT=700&FORMAT=image/jpeg&TIME=2024-08-31`; thermal layer `VIIRS_SNPP_Thermal_Anomalies_375m_All`, FORMAT=image/png&TRANSPARENT=TRUE. The exact URLs are in `data/nasa/manifest.json`. |
| moon_south_pole | `south_pole_wide_lroc_wac.jpg`, `south_pole_shackleton_lroc_wac.jpg` | Moon Trek WMTS tiles `https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0//default/default028mm/{zoom}/{row}/{col}.jpg` (zoom 5 and 7, last rows), re-projected by us |
| grand_tour | `jupiter_voyager1_1979`, `saturn_voyager1_1980`, `uranus_voyager2_1986`, `neptune_voyager2_1989` | NASA Image and Video Library, `https://images-api.nasa.gov/asset/<PIA id>` (PIA00022, PIA01374, PIA18182, PIA00049) |

Findings and honest limits:
- Equatorial Andes are nearly always cloudy: of three volcanoes, the single clearest 2024 day found by scanning (every 3rd
  day) was 2024-08-31 for all three; Sangay and Reventador show a VIIRS hot spot on the summit that day; Cotopaxi none
  (the image is true color only). The dates are real days of satellite passes, not documented eruption dates; Sangay and
  Reventador are persistently active (we have not cited the activity record; the thermal hot spot in the data is the evidence).
- VIIRS is 250 m per pixel, so images are soft. Landsat: GIBS layer `HLS_L30_Nadir_BRDF_Adjusted_Reflectance` (Landsat 8/9
  at 30 m) returned no usable tile for the test dates in July-August 2024 (not pursued further). Landsat from USGS
  EarthExplorer needs a login; not tried. FIRMS needs a key; GIBS carries the same hot-spot layer without one.
- Moon: the polar mosaic works and shows real permanently shadowed craters; faint seams are the mosaic's own strips.
  NASA SVS pages were not needed.
- Voyager Saturn is small (500 px) and black and white. All images are of planets or terrain, none of people, none with a
  NASA logo.
- License for all: NASA media, free to use with credit, no endorsement implied (https://www.nasa.gov/nasa-brand-center/images-and-media/).
  LROC credit: "NASA/GSFC/Arizona State University". Voyager: "NASA/JPL-Caltech". GIBS: "NASA GIBS / Worldview, VIIRS Suomi NPP".
  No non-NASA partner terms found for these items (Suomi NPP is a NASA/NOAA satellite; the imagery is served by NASA).

## 2. Positions and constants
- JPL Horizons API, endpoint `https://ssd.jpl.nasa.gov/api/horizons.api` (docs: https://ssd-api.jpl.nasa.gov/doc/horizons.html).
  Planets: `format=json&COMMAND='599'&OBJ_DATA='NO'&MAKE_EPHEM='YES'&EPHEM_TYPE='ELEMENTS'&CENTER='500@10'&START_TIME='2026-11-15'&STOP_TIME='2026-11-16'&STEP_SIZE='1d'&REF_SYSTEM='ICRF'&REF_PLANE='ECLIPTIC'&OUT_UNITS='KM-S'&CSV_FORMAT='YES'`
  with COMMAND 199, 299, ... 899. The game reads: eccentricity, semi-major axis, inclination, node, argument of perihelion,
  mean anomaly, period, to place each planet on a Kepler orbit (our simplification of Horizons' full ephemeris).
  Moon: `COMMAND='301'`, `EPHEM_TYPE='VECTORS'`, `CENTER='500@399'`, 2026-11-15 to 2026-12-15, step 1d; 31 rows of x,y,z,vx,vy,vz.
  For a route date other than today, change START_TIME; the script holds `EPOCH`.
- NSSDC fact sheets `https://nssdc.gsfc.nasa.gov/planetary/factsheet/<body>fact.html` for mercury, venus, earth, mars, jupiter,
  saturn, uranus, neptune, moon: mass, equatorial and mean radius, gravity (surface; at 1 bar for the giants), escape velocity,
  GM, semi-major axis, sidereal rotation, length of day (not published for the Moon). Earth values equal `kb/data/reference.json`
  (radius 6378.137, escape 11.186); gravity of gas giants is at the 1 bar level, not a surface.
- License: NASA data, cite as "NASA/JPL Horizons" and "NASA NSSDC Planetary Fact Sheets".

## 3. Textures: recommendation only
Today `textures/earth_albedo.jpg` (2048x1024, 214 KB) has no known source or license.
- Earth option A, reproducible and tested: GIBS layer `BlueMarble_NextGeneration`, one request
  `.../wms.cgi?SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&LAYERS=BlueMarble_NextGeneration&SRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=2048&HEIGHT=1024&FORMAT=image/jpeg&TIME=2004-08-01`
  returned a 2048x1024 world map, 209 KB, seamless, no clouds, no logos. Origin: Blue Marble Next Generation (NASA Earth
  Observatory, Reto Stockli and team, MODIS), shown on NASA Visible Earth (visibleearth.nasa.gov, record 73909 family);
  that site was unreachable from here (timeout), so the credit wording must be checked on the Visible Earth page before
  use. Suggested credit: "NASA Earth Observatory, Blue Marble Next Generation, MODIS". The GIBS tile set is the same
  data pipeline the volcano photos use, so one source ID serves both.
- Moon option: NASA SVS "CGI Moon Kit" (https://svs.gsfc.nasa.gov/4720; LRO camera and laser altimeter teams); color map
  `http://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/lroc_color_2k.jpg` (reachable, HTTP 200). NASA media license, credit
  "NASA/GSFC/Scientific Visualization Studio, LRO". The kit also has elevation maps for normal/bump.
- For: fixes the "no known source" gap that costs points; real data (judges can read the layer name); one reproducible script
  line; the same look as the photos. Against: Blue Marble is the 2004 look (no clouds, flat lighting, Antarctic white, dark
  oceans) and may look plainer than the current texture; the current image might actually be a Blue Marble derivative,
  unproven. The Moon kit color map is a processed rendering (color enhanced from LROC and Kaguya), say so in the credit.
  Recommendation: switch both. The cost is one image import each, 2K size is enough.
