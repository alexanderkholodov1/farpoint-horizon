#!/usr/bin/env python3
"""Draws the pitch deck's backgrounds in the game's look: deep space, sunrise and horizon glows, and the brand's
horizon arc (scripts/ui/horizon.gd: pale core, sunrise orange, deep blue toward the ends).

    python tools/content/deck/pitch_art.py

Writes spaceapps/local-pitch/source/art/space.png (every content slide) and, when the game's own recording is there
(build/video/raw.ogv, the credits film's opening: the Earth at sunrise from NASA Blue Marble and Black Marble
[S-gibs-earth]), spaceapps/local-pitch/source/art/cover.jpg. Both are committed, so the deck builds without the video. Needs numpy and
Pillow; ffmpeg only for the cover. Procedural and from our own game: no AI images.
"""
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
ART = ROOT / "spaceapps" / "local-pitch" / "source" / "art"
W, H = 1920, 1080
WARM = np.array([1.0, 0.58, 0.22])
PALE = np.array([1.0, 0.86, 0.62])
DEEP = np.array([0.08, 0.28, 0.66])
BLUE = np.array([120, 184, 255]) / 255.0


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def glow(img, cx, cy, r, color, strength):
    y, x = np.mgrid[0:H, 0:W]
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
    k = np.exp(-d * d * 2.2)[..., None] * strength
    img += k * color


def stars(img, n, seed):
    rng = np.random.default_rng(seed)
    layer = np.zeros((H, W), np.float32)
    xs, ys = rng.integers(0, W, n), rng.integers(0, H, n)
    b = rng.random(n) ** 3 * 0.9 + 0.08
    layer[ys, xs] = b
    big = Image.fromarray((np.clip(layer, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
    layer = np.maximum(layer * 0.8, np.asarray(big, np.float32) / 255.0 * 2.2)
    tint = np.where(rng.random((H, W, 1)) > 0.5, np.array([0.85, 0.92, 1.0]), np.array([1.0, 0.95, 0.88]))
    img += layer[..., None] * tint


def arc_color(t, sun):
    d = np.abs(t - sun) / max(sun, 1 - sun)
    s1, s2 = smooth(0.0, 0.12, d)[:, None], smooth(0.12, 0.85, d)[:, None]
    c = PALE * (1 - s1) + WARM * s1
    c = c * (1 - s2) + DEEP * s2
    return c, 1 - smooth(0.75, 1.0, d)


def arc(img, x0, x1, base, bulge, sun, width, halo=True):
    """The horizon arc: a flat circular arc from (x0, base) up by bulge in the middle, lit around sun (0..1)."""
    n = 2400
    t = np.linspace(0, 1, n)
    px = x0 + t * (x1 - x0)
    py = base - bulge * (1 - ((t - 0.5) * 2) ** 2)
    col, alpha = arc_color(t, sun)
    line = np.zeros((H, W, 3), np.float32)
    ok = (px >= 0) & (px < W) & (py >= 0) & (py < H)
    for dy in range(-int(width), int(width) + 1):
        yy = (py + dy).astype(int)
        m = ok & (yy >= 0) & (yy < H)
        f = max(0.0, 1 - abs(dy) / (width + 0.5))
        line[yy[m], px[m].astype(int)] = np.maximum(line[yy[m], px[m].astype(int)], (col * alpha[:, None])[m] * f)
    out = line.copy()
    if halo:
        for r, k in ((6, 0.9), (22, 0.7), (70, 0.55)):
            out += np.asarray(Image.fromarray((np.clip(line, 0, 1) * 255).astype(np.uint8))
                              .filter(ImageFilter.GaussianBlur(r)), np.float32) / 255.0 * k * (1 + r / 12)
    img += out
    return px, py


def space():
    y = np.linspace(0, 1, H)[:, None, None]
    img = np.zeros((H, W, 3), np.float32) + (np.array([5, 8, 18]) / 255.0) * (1 - y) + (np.array([10, 18, 36]) / 255.0) * y
    glow(img, 1750, -120, 1100, BLUE * 0.5, 0.22)       # cold light, top right
    glow(img, 560, 1120, 900, WARM, 0.20)               # sunrise below the arc, left of centre
    glow(img, 1400, 1150, 900, DEEP * 1.6, 0.25)
    stars(img, 1600, 7)
    # below the arc: the night side of the planet, darker than space, a thin atmosphere above its limb
    yy, xx = np.mgrid[0:H, 0:W]
    t = xx / W
    limb = 1110 - 130 * (1 - ((t - 0.5) * 2) ** 2)
    below = (yy > limb)[..., None]
    img = np.where(below, img * 0.35 + np.array([6, 10, 22]) / 255.0, img)
    haze = np.exp(-np.clip(limb - yy, 0, None) / 46.0)[..., None] * (yy <= limb)[..., None]
    img += haze * (BLUE * 0.10)
    arc(img, 0, W, 1110, 130, 0.3, 1.6)
    return img


def cover():
    raw = ROOT / "build" / "video" / "raw.ogv"
    if not raw.exists():
        print("cover: no build/video/raw.ogv, cover.jpg kept as it is")
        return
    frame = ART / "_frame.png"
    # the credits film's opening, the Earth at sunrise before the title arrives (mark "open" at 1.0 s, title at 8.0 s)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", "7.0", "-i", str(raw), "-frames:v", "1",
                    "-vf", f"scale={W}:{H}", str(frame)], check=True)
    img = np.asarray(Image.open(frame).convert("RGB"), np.float32) / 255.0
    frame.unlink()
    img[985:1065, 1720:1900] *= 0.0                     # the film's Skip button
    y = np.linspace(0, 1, H)[:, None, None]
    img *= 1 - 0.55 * smooth(0.55, 1.0, y)             # darker toward the bottom, for the team's names
    img *= 1 - 0.35 * smooth(0.25, 0.0, y)             # and toward the top, for the label
    arc(img, 290, 1630, 700, 26, 0.32, 1.4)             # the logo's arc under the title, as in the film
    save(img, ART / "cover.jpg")


def save(img, path):
    im = Image.fromarray((np.clip(img, 0, 1) ** (1 / 1.0) * 255).astype(np.uint8))
    if path.suffix == ".jpg":
        im.save(path, quality=90)
    else:
        im.save(path, optimize=True)
    print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    ART.mkdir(parents=True, exist_ok=True)
    save(space(), ART / "space.png")
    cover()
