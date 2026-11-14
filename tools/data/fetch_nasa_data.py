#!/usr/bin/env python3
"""Farpoint HORIZON NASA data pipeline: download, process, write game files plus a manifest.

Usage:  python tools/data/fetch_nasa_data.py [photos|numbers|all]
Needs Python 3.9+ and Pillow (pip install pillow). Everything else is the standard library.
Outputs: assets/mission_photos/<mission_id>/*.jpg, data/nasa/*.json, data/nasa/manifest.json.
See tools/data/README.md for what each step does. Source IDs refer to docs/sources.md.
"""
import io, json, math, re, sys, time, datetime, urllib.request, urllib.parse
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
PHOTOS = ROOT / "assets" / "mission_photos"
NUMBERS = ROOT / "data" / "nasa"
CHECKED = datetime.date.today().isoformat()
MAXSIDE = 1024
manifest = []


def http(url, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "FarpointHorizon-data-pipeline/1.0 (student game project)"})
            return urllib.request.urlopen(req, timeout=90).read()
        except Exception:
            if i == tries - 1:
                raise
            time.sleep(2 * (i + 1))


def save_jpeg(img, path, source, query, note, mission=None, quality=85):
    img = img.convert("RGB")
    if max(img.size) > MAXSIDE:
        s = MAXSIDE / max(img.size)
        img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "JPEG", quality=quality, optimize=True)
    manifest.append({"file": str(path.relative_to(ROOT)).replace("\\", "/"), "mission": mission, "source_id": source,
                     "query": query, "date_checked": CHECKED, "processing": note, "bytes": path.stat().st_size})
    print("wrote", path.relative_to(ROOT), path.stat().st_size, "bytes")


# ------------------------------------------------ 1. Volcano watch (NASA GIBS, source S-gibs)
GIBS = "https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi"
VOLCANOES = {  # summit (lon, lat), rounded by us from common maps
    "sangay": (-78.34, -2.00), "cotopaxi": (-78.44, -0.68), "reventador": (-77.656, -0.077)}
# (volcano, date, with thermal layer). Dates picked by scanning 2024 for the clearest sky (README, step 1).
VOLCANO_SHOTS = [("sangay", "2024-08-31", True), ("reventador", "2024-08-31", True), ("cotopaxi", "2024-08-31", False)]


def gibs(layer, bbox, size, date, fmt):
    q = (f"SERVICE=WMS&REQUEST=GetMap&VERSION=1.1.1&LAYERS={layer}&SRS=EPSG:4326&BBOX={bbox}"
         f"&WIDTH={size}&HEIGHT={size}&FORMAT={fmt}&TIME={date}" + ("&TRANSPARENT=TRUE" if "png" in fmt else ""))
    url = GIBS + "?" + q
    return url, Image.open(io.BytesIO(http(url)))


def volcanoes():
    half = 0.35  # degrees: a box about 78 km wide
    for name, date, thermal in VOLCANO_SHOTS:
        lon, lat = VOLCANOES[name]
        bbox = f"{lon-half},{lat-half},{lon+half},{lat+half}"
        url, tc = gibs("VIIRS_SNPP_CorrectedReflectance_TrueColor", bbox, 700, date, "image/jpeg")
        tc = tc.convert("RGB")
        out = PHOTOS / "volcano_watch"
        save_jpeg(tc, out / f"{name}_{date}_truecolor.jpg", "S-gibs", url, "none (as served)", "volcano_watch")
        if thermal:
            url2, th = gibs("VIIRS_SNPP_Thermal_Anomalies_375m_All", bbox, 700, date, "image/png")
            a = th.convert("RGBA").getchannel("A").filter(ImageFilter.MaxFilter(7))  # grow each 375 m hot pixel so it shows
            comp = tc.convert("RGBA")
            comp.paste(Image.new("RGBA", tc.size, (255, 60, 20, 255)), (0, 0), a)
            save_jpeg(comp, out / f"{name}_{date}_thermal.jpg", "S-gibs", url + "  +  " + url2,
                      "hot-spot pixels enlarged 7x and drawn in red over the true-colour image", "volcano_watch")


# ------------------------------------------------ 2. Moon south pole (NASA Moon Trek, LROC WAC mosaic)
TREK = "https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0//default/default028mm/{z}/{r}/{c}.jpg"


def moon_polar(zoom, half_deg, name):
    cols, rows_total = 2 ** (zoom + 1), 2 ** zoom
    nrows = max(1, math.ceil(half_deg / (180 / rows_total)))
    rows = list(range(rows_total - nrows, rows_total))
    strip = Image.new("L", (cols * 256, nrows * 256))
    jobs = [(r, c) for r in rows for c in range(cols)]
    with ThreadPoolExecutor(8) as ex:
        tiles = list(ex.map(lambda rc: http(TREK.format(z=zoom, r=rc[0], c=rc[1])), jobs))
    for (r, c), t in zip(jobs, tiles):
        strip.paste(Image.open(io.BytesIO(t)).convert("L"), (c * 256, (r - rows[0]) * 256))
    deg_per_px = 360 / (cols * 256)
    top_lat = -90 + nrows * 180 / rows_total
    size = 1000
    out = Image.new("L", (size, size), 0)
    px, src = out.load(), strip.load()
    c0 = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            dx, dy = x - c0, y - c0
            rr = math.hypot(dx, dy)
            if rr > size / 2:
                continue
            colat = rr / (size / 2) * half_deg           # azimuthal equidistant, south pole at the centre
            lon = math.degrees(math.atan2(dx, -dy))       # 0 deg up, east clockwise (seen from outside, over the pole)
            sx = min(strip.width - 1, int((lon + 180) / deg_per_px))
            sy = min(strip.height - 1, int((top_lat - (-90 + colat)) / deg_per_px))
            px[x, y] = src[sx, sy]
    q = f"{TREK.format(z=zoom, r='{row}', c='{col}')} for row {rows[0]}..{rows[-1]}, column 0..{cols-1}"
    save_jpeg(out, PHOTOS / "moon_south_pole" / name, "S-lroc-wac", q,
              f"tiles joined, re-projected to a view from above the south pole (azimuthal equidistant, {half_deg} deg radius)",
              "moon_south_pole")


def moon():
    moon_polar(5, 11.0, "south_pole_wide_lroc_wac.jpg")
    moon_polar(7, 2.8, "south_pole_shackleton_lroc_wac.jpg")


# ------------------------------------------------ 3. Grand Tour (NASA Image and Video Library, Voyager)
VOYAGER = [("PIA00022", "jupiter_voyager1_1979.jpg", "Jupiter's Great Red Spot, Voyager 1, March 1979"),
           ("PIA01374", "saturn_voyager1_1980.jpg", "Saturn's limb and ring shadow, Voyager 1, 9 Nov 1980"),
           ("PIA18182", "uranus_voyager2_1986.jpg", "Uranus, Voyager 2, 1986"),
           ("PIA00049", "neptune_voyager2_1989.jpg", "Neptune and its Great Dark Spot, Voyager 2, 1989")]


def voyager():
    for pia, fname, desc in VOYAGER:
        meta = json.loads(http("https://images-api.nasa.gov/search?nasa_id=" + pia))["collection"]["items"][0]["data"][0]
        # the library lists which sizes exist for each record; take the biggest of large/medium, else the original
        hrefs = [i["href"].replace("http://", "https://") for i in json.loads(http("https://images-api.nasa.gov/asset/" + pia))["collection"]["items"]]
        url = next(h for suf in ("~large.jpg", "~medium.jpg", "~orig.jpg") for h in hrefs if h.endswith(suf))
        img = Image.open(io.BytesIO(http(url)))
        save_jpeg(img, PHOTOS / "grand_tour" / fname, "S-nasa-images", url,
                  f"resized to at most {MAXSIDE} px; {desc}; library record {pia}, credit {meta.get('secondary_creator')}", "grand_tour")


# ------------------------------------------------ 4. Numbers: JPL Horizons and NSSDC fact sheets
HORIZONS = "https://ssd.jpl.nasa.gov/api/horizons.api"
BODIES = {"mercury": 199, "venus": 299, "earth": 399, "mars": 499, "jupiter": 599, "saturn": 699, "uranus": 799, "neptune": 899}
EPOCH = "2026-11-15"


def horizons(command, center, kind, start, stop, step):
    p = {"format": "json", "COMMAND": f"'{command}'", "OBJ_DATA": "'NO'", "MAKE_EPHEM": "'YES'", "EPHEM_TYPE": f"'{kind}'",
         "CENTER": f"'{center}'", "START_TIME": f"'{start}'", "STOP_TIME": f"'{stop}'", "STEP_SIZE": f"'{step}'",
         "REF_SYSTEM": "'ICRF'", "REF_PLANE": "'ECLIPTIC'", "OUT_UNITS": "'KM-S'", "CSV_FORMAT": "'YES'"}
    url = HORIZONS + "?" + urllib.parse.urlencode(p, safe="',@")
    res = json.loads(http(url))["result"]
    body = res.split("$$SOE")[1].split("$$EOE")[0].strip().splitlines()
    return url, [[v.strip() for v in line.split(",")] for line in body]


WANTED = {"mass_1e24_kg": r"^Mass", "equatorial_radius_km": r"^Equatorial radius", "mean_radius_km": r"^Volumetric mean radius",
          "gravity_m_s2": r"^(Surface g|G)ravity", "escape_velocity_km_s": r"^Escape [Vv]elocity", "gm_1e6_km3_s2": r"^GM",
          "semi_major_axis_1e6_km": r"^Semimajor axis", "sidereal_rotation_h": r"^Sidereal rotation period",
          "length_of_day_h": r"^Length of day"}


def take(store, cells):
    """If cells = [label, value, ...] matches a wanted field, store its first number."""
    if len(cells) < 2:
        return
    for key, pat in WANTED.items():
        if key in store or not re.match(pat, cells[0]):
            continue
        m = re.search(r"-?[\d,]*\.?\d+", cells[1])
        if m:
            store[key] = {"label": cells[0], "value": float(m.group().replace(",", ""))}


def numbers():
    NUMBERS.mkdir(parents=True, exist_ok=True)
    # a) orbital elements around the Sun at EPOCH (ecliptic J2000). Columns: JDTDB, Calendar, EC, QR, IN, OM, W, Tp, N, MA, TA, A, AD, PR
    planets, urls = {}, {}
    nxt = (datetime.date.fromisoformat(EPOCH) + datetime.timedelta(days=1)).isoformat()
    for n, code in BODIES.items():
        url, rows = horizons(code, "500@10", "ELEMENTS", EPOCH, nxt, "1d")
        r = rows[0]
        planets[n] = {"horizons_id": code, "jd_tdb": float(r[0]), "eccentricity": float(r[2]), "perihelion_km": float(r[3]),
                      "inclination_deg": float(r[4]), "ascending_node_deg": float(r[5]), "arg_perihelion_deg": float(r[6]),
                      "mean_anomaly_deg": float(r[9]), "semi_major_axis_km": float(r[11]), "period_s": float(r[13])}
        urls[n] = url
    # b) the Moon around the Earth: one lunar month of position vectors, one a day
    murl, rows = horizons(301, "500@399", "VECTORS", "2026-11-15", "2026-12-15", "1d")
    moon = [{"date": r[1].replace("A.D. ", ""), "x_km": float(r[2]), "y_km": float(r[3]), "z_km": float(r[4]),
             "vx_km_s": float(r[5]), "vy_km_s": float(r[6]), "vz_km_s": float(r[7])} for r in rows]
    meta = {"source_id": "S-horizons", "date_checked": CHECKED, "frame": "ICRF axes, ecliptic plane J2000",
            "epoch": EPOCH + " 00:00 TDB", "units": "km, km/s, degrees, seconds"}
    (NUMBERS / "horizons_planets.json").write_text(json.dumps({"meta": {**meta, "centre": "Sun (500@10)", "queries": urls}, "planets": planets}, indent=1))
    (NUMBERS / "horizons_moon.json").write_text(json.dumps({"meta": {**meta, "centre": "Earth (500@399)", "query": murl}, "moon": moon}, indent=1))
    for f, q in (("horizons_planets.json", "; ".join(urls.values())), ("horizons_moon.json", murl)):
        manifest.append({"file": f"data/nasa/{f}", "mission": "grand_tour", "source_id": "S-horizons", "query": q,
                         "date_checked": CHECKED, "processing": "CSV rows parsed to JSON", "bytes": (NUMBERS / f).stat().st_size})
    # c) NSSDC planetary fact sheets
    facts, furls = {}, {}
    for n in list(BODIES) + ["moon"]:
        url = f"https://nssdc.gsfc.nasa.gov/planetary/factsheet/{n}fact.html"
        html = http(url).decode("latin-1")
        facts[n] = {}
        for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S | re.I):
            cells = [re.sub(r"\s+", " ", re.sub(r"<[^>]*>|&nbsp;", " ", c)).strip() for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", tr, re.S | re.I)]
            take(facts[n], cells)
        if not facts[n]:  # the Earth sheet is plain text lines, not a table: "label    value"
            for line in re.sub(r"<[^>]*>|&nbsp;", " ", html).splitlines():
                ch = [c.strip() for c in re.split(r"	|\s{2,}", line.strip())]
                take(facts[n], [ch[0], ch[-1]])
        furls[n] = url
    (NUMBERS / "nssdc_factsheets.json").write_text(json.dumps({"meta": {"source_id": "S-nssdc-planets", "date_checked": CHECKED,
        "note": "values as printed on the fact sheets, each with its row label; the first column after the label is the body itself",
        "urls": furls}, "bodies": facts}, indent=1))
    manifest.append({"file": "data/nasa/nssdc_factsheets.json", "mission": None, "source_id": "S-nssdc-planets",
                     "query": "; ".join(furls.values()), "date_checked": CHECKED, "processing": "HTML table rows parsed to JSON",
                     "bytes": (NUMBERS / "nssdc_factsheets.json").stat().st_size})


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("photos", "all"):
        volcanoes(); moon(); voyager()
    if what in ("numbers", "all"):
        numbers()
    NUMBERS.mkdir(parents=True, exist_ok=True)
    mf = NUMBERS / "manifest.json"
    old = json.loads(mf.read_text()) if mf.exists() else []
    new_files = {x["file"] for x in manifest}
    mf.write_text(json.dumps([m for m in old if m["file"] not in new_files] + manifest, indent=1))
    print("manifest entries:", len(old) + len(manifest))
