# NASA data pipeline

One script, `fetch_nasa_data.py`, turns open NASA data into the files the game uses. Run it from the repository root:

    pip install pillow
    python tools/data/fetch_nasa_data.py all        # or: photos | numbers

It needs Python 3.9 or newer, the standard library, and Pillow (image cropping and conversion). It needs internet and
takes about a minute. The files it writes are committed, so the game never needs the internet; the script is there so
anyone can check, repeat or update them. Every source ID (`S-...`) is described in `docs/sources.md`.

## What it does, step by step

### 1. Volcano Watch photos (`assets/mission_photos/volcano_watch/`, source S-gibs)
1. Ask NASA's GIBS image service (the service behind NASA Worldview) for a picture of the volcano: a box 0.7 degrees
   wide (about 78 km) around the summit, from the `VIIRS_SNPP_CorrectedReflectance_TrueColor` layer, which is the
   VIIRS camera on Suomi NPP, one of the real satellites our mission copies.
2. The date is not random. Mountains near the equator are almost always under cloud, so we scanned every third day of
   2024 and kept the day with the least cloud and no missing data (2024-08-31 for all three volcanoes).
3. Ask the same service for the `VIIRS_SNPP_Thermal_Anomalies_375m_All` layer, the places the satellite's infrared
   channel sees as unusually hot. Each hot spot is one 375 m pixel, too small to see, so we enlarge it and paint it red
   over the picture (our own processing, said so in the manifest). Sangay and Reventador both show a hot spot on the summit.
4. Save as JPEG.

### 2. Moon south pole photos (`assets/mission_photos/moon_south_pole/`, source S-lroc-wac)
1. NASA Moon Trek serves the LROC Wide Angle Camera mosaic of the whole Moon as small square tiles on a flat map. Near
   the pole a flat map is stretched sideways, so the tiles are useless as they are.
2. Download every tile that touches the pole (128 tiles for the wide view, 512 for the close view).
3. Join them, then redraw the picture as seen from above the pole: for each pixel of the new picture we compute its
   distance and direction from the pole (a polar, "azimuthal equidistant" projection) and copy the matching pixel from
   the flat map. Wide view: 11 degrees (about 330 km) around the pole. Close view: 2.8 degrees (about 85 km), which
   shows the permanently dark craters near Shackleton. The faint straight seams are the edges of the mosaic's own strips.

### 3. Grand Tour photos (`assets/mission_photos/grand_tour/`, source S-nasa-images)
1. For Jupiter, Saturn, Uranus and Neptune we picked one Voyager image each (record numbers in the script) from the
   NASA Image and Video Library.
2. Ask the library which sizes exist and download the biggest; shrink to at most 1024 px; save as JPEG.

### 4. Numbers (`data/nasa/`, sources S-horizons and S-nssdc-planets)
1. Ask JPL Horizons, NASA's own solar-system position service, for the orbit of each planet around the Sun at
   2026-11-15: size, shape and tilt of the orbit and where the planet is on it (six Kepler elements, ecliptic J2000). The
   game can move a planet along its orbit from these. Ask again for the Moon's position and speed around the Earth, one
   per day for a month. Horizons answers a table of text; the script reads the table into JSON.
2. Read NASA's planetary fact sheets (web tables) for mass, radius, surface gravity, escape velocity, distance from the Sun
   and length of day of each planet and the Moon, keeping the name of the fact sheet row next to every value.

### 5. Manifest (`data/nasa/manifest.json`)
Every file written is listed with the source ID, the exact request that produced it, the day we checked it, what we did
to it, and its size.

## Limits we know
- Pictures are what the services serve (VIIRS pixels are 250 m), so they are soft; they are real, not drawn.
- The Voyager pictures are scans of the 1979-1989 encounters; Saturn's is a small crop.
- The tools do not use any image of people, any NASA logo or mission patch.
