#!/usr/bin/env python3
"""Builds the pitch deck as editable PowerPoint files, from the same text as the HTML and PDF (spaceapps/local-pitch/source/<lang>.md).

    python tools/content/deck/pitch_pptx.py          # build/deck/deck-en.pptx and deck-es.pptx
    python tools/content/deck/pitch_pptx.py es       # one language

Every title, bullet, card, chip and caption is a real text box or shape (gradients are PowerPoint's own), the
speaker notes are the slide notes, and the backgrounds (spaceapps/local-pitch/source/art, tools/content/deck/pitch_art.py) are pictures sent to the
back, so the deck can be edited by hand in PowerPoint or Google Slides. A screenshot frame is a dashed shape: delete it
and insert the picture in its place. Type: Segoe UI (on every Windows PC; the HTML uses Inter, close in width).
Needs python-pptx and Pillow (pip install python-pptx pillow). The text is the source: edit <lang>.md and rebuild
when you can, so the PDF and the PPTX stay the same.
"""
import re
import sys
from pathlib import Path

from PIL import Image, ImageFont
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.dml import MSO_LINE
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, MSO_AUTO_SIZE, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.oxml import parse_xml
from pptx.util import Emu, Pt

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pitch  # noqa: E402  (parse, the rules and the paths are shared with the HTML build)

ROOT, PITCH, BUILD = pitch.ROOT, pitch.PITCH, pitch.BUILD
EMU = 6350                        # the slide is drawn on the HTML's 1920 x 1080 grid: 12192000 EMU / 1920 px
TEXT, MUTED, BLUE, GOLD, ICE, PALE, DEEP = "EFF4FF", "A9B9D4", "78B8FF", "FFA842", "9EE6FF", "FFDB9E", "1447A8"
FONT, SEMI = "Segoe UI", "Segoe UI Semibold"
WINFONTS = Path("C:/Windows/Fonts")
LEFT, TOP, BOTTOM, COL, GAP, FIGX, FIGW = 120, 104, 950, 820, 72, 1012, 788
NS = 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'


def px(v):
    return Emu(int(round(v * EMU)))


def font(bold=False, size=28):
    name = "seguisb.ttf" if bold else "segoeui.ttf"
    for p in (WINFONTS / name, ROOT / "assets" / "fonts" / ("Inter-SemiBold.otf" if bold else "Inter-Regular.otf")):
        if p.exists():
            return ImageFont.truetype(str(p), int(size))
    return ImageFont.load_default()


def plain(text):
    return re.sub(r"\*\*(.+?)\*\*|`(.+?)`|\[(.+?)\]\((.+?)\)", lambda m: m.group(1) or m.group(2) or m.group(3), text)


def lines_of(text, size, width, bold=False):
    """How many lines `text` takes at `size` px in a box `width` px wide (Segoe UI, with a little slack)."""
    f, n, line = font(bold, size), 0, ""
    for para in plain(text).split("\n"):
        n += 1
        line = ""
        for word in para.split(" "):
            test = (line + " " + word).strip()
            if f.getlength(test) * 1.04 > width and line:
                n += 1
                line = word
            else:
                line = test
    return max(n, 1)


def runs(text):
    """The inline subset as (text, kind, url): **bold**, `code`, [label](url), TODO."""
    out, pos = [], 0
    for m in re.finditer(r"\*\*(.+?)\*\*|`(.+?)`|\[(.+?)\]\((.+?)\)|TODO", text):
        if m.start() > pos:
            out.append((text[pos:m.start()], "n", None))
        if m.group(1):
            out.append((m.group(1), "b", None))
        elif m.group(2):
            out.append((m.group(2), "c", None))
        elif m.group(3):
            out.append((m.group(3), "a", m.group(4)))
        else:
            out.append(("TODO", "t", None))
        pos = m.end()
    if pos < len(text):
        out.append((text[pos:], "n", None))
    return out


def alpha_color(hexrgb, alpha):
    return f'<a:srgbClr {NS} val="{hexrgb}"><a:alpha val="{int(alpha * 100000)}"/></a:srgbClr>'


def gradient(shape, stops, angle=90):
    """A PowerPoint gradient fill: stops are (position 0..1, hex colour, opacity 0..1); angle in degrees."""
    shape.fill.gradient()
    gf = shape._element.spPr.find(qn("a:gradFill"))
    for c in list(gf):
        gf.remove(c)
    gs = "".join(f'<a:gs pos="{int(p * 100000)}">{alpha_color(c, a).replace(" " + NS, "")}</a:gs>' for p, c, a in stops)
    gf.append(parse_xml(f"<a:gsLst {NS}>{gs}</a:gsLst>"))
    gf.append(parse_xml(f'<a:lin {NS} ang="{int(angle * 60000)}" scaled="0"/>'))
    gf.set("rotWithShape", "1")


def outline(shape, hexrgb, alpha, width_px=1.0, dash=False):
    if hexrgb is None:
        shape.line.fill.background()
        return
    shape.line.width = px(width_px)
    shape.line.fill.solid()
    shape.line.fill.fore_color.rgb = RGBColor.from_string(hexrgb)
    clr = shape._element.spPr.find(qn("a:ln")).find(qn("a:solidFill")).find(qn("a:srgbClr"))
    clr.append(parse_xml(f'<a:alpha {NS} val="{int(alpha * 100000)}"/>'))
    if dash:
        shape.line.dash_style = MSO_LINE.DASH


def rounded(slide, x, y, w, h, radius, name):
    s = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, px(x), px(y), px(w), px(h))
    s.adjustments[0] = min(0.5, radius / max(1, min(w, h)))
    s.name = name
    s.shadow.inherit = False
    return s


def box(slide, x, y, w, h, name, anchor=MSO_ANCHOR.TOP):
    tb = slide.shapes.add_textbox(px(x), px(y), px(w), px(h))
    tb.name = name
    tf = tb.text_frame
    tf.word_wrap = True
    tf.auto_size = MSO_AUTO_SIZE.NONE
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = anchor
    return tf


def para(tf, text, size, color, lh=1.35, semibold=False, align=None, after=0, first=False, card=False,
         spacing=None, caps=False, shadow=False, bullet=None):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    if align:
        p.alignment = align
    p.line_spacing = Pt(size * lh * 0.5)
    p.space_after = Pt(after * 0.5)
    if bullet:
        ppr = p._p.get_or_add_pPr()
        ppr.set("marL", str(int(bullet * EMU)))
        ppr.set("indent", str(int(-bullet * EMU)))
        for xml in (f'<a:buClr {NS}><a:srgbClr val="{GOLD}"/></a:buClr>', f'<a:buFont {NS} typeface="Segoe UI"/>',
                    f'<a:buChar {NS} char="–"/>'):
            ppr.append(parse_xml(xml))
    for t, kind, url in runs(text.upper() if caps else text):
        r = p.add_run()
        r.text = t
        f = r.font
        f.size = Pt(size * 0.5)
        f.name = SEMI if (semibold or kind in "bt") else FONT
        f.color.rgb = RGBColor.from_string({"b": GOLD if card else TEXT, "c": ICE, "a": BLUE, "t": GOLD}.get(kind, color))
        if kind == "c":
            f.name = "Consolas"
            f.size = Pt(size * 0.5 * 0.86)
        if kind == "a":
            r.hyperlink.address = url if "://" in url else "https://" + url
        rpr = r._r.get_or_add_rPr()
        if spacing:
            rpr.set("spc", str(int(spacing)))
        if shadow:
            rpr.append(parse_xml(f'<a:effectLst {NS}><a:outerShdw blurRad="190500" dist="0" algn="ctr" rotWithShape="0">'
                                 f'{alpha_color("000000", 0.85).replace(" " + NS, "")}</a:outerShdw></a:effectLst>'))
    return p


def background(slide, path):
    pic = slide.shapes.add_picture(str(ROOT / path), 0, 0, px(1920), px(1080))
    pic.name = "Background"
    return pic


def picture(slide, path, x, y, w, h, name):
    """A picture cropped to fill its frame, with rounded corners and a thin horizon-blue edge."""
    iw, ih = Image.open(ROOT / path).size
    pic = slide.shapes.add_picture(str(ROOT / path), px(x), px(y), px(w), px(h))
    pic.name = name
    a, b = iw / ih, w / h
    if a > b:
        c = (1 - b / a) / 2
        pic.crop_left = pic.crop_right = c
    else:
        c = (1 - a / b) / 2
        pic.crop_top = pic.crop_bottom = c
    pic.auto_shape_type = MSO_SHAPE.ROUNDED_RECTANGLE
    geom = pic._element.spPr.find(qn("a:prstGeom"))
    av = geom.find(qn("a:avLst"))
    if av is None:
        av = parse_xml(f"<a:avLst {NS}/>")
        geom.append(av)
    av.append(parse_xml(f'<a:gd {NS} name="adj" fmla="val {int(16 / min(w, h) * 100000)}"/>'))
    outline(pic, BLUE, 0.35)
    return pic


def caption(slide, text, x, y, w):
    n = lines_of(text, 18, w)
    tf = box(slide, x, y, w, n * 18 * 1.35 + 4, "Caption")
    para(tf, text, 18, MUTED, first=True)
    return n * 18 * 1.35


def shot_frame(slide, what, x, y, w, h):
    s = rounded(slide, x, y, w, h, 16, "Screenshot frame (replace with the picture)")
    gradient(s, [(0, GOLD, 0.14), (0.6, BLUE, 0.07), (1, "0B1220", 0.4)], 70)
    outline(s, GOLD, 0.75, 2, dash=True)
    tf = s.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = px(24)
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    para(tf, "SCREENSHOT", 17, GOLD, semibold=True, after=10, first=True, spacing=380)
    para(tf, what, 21, MUTED, lh=1.3)


def figures(slide, specs, x, y, w, h, row):
    n = len(specs)
    if not n:
        return
    gap = 24
    cells = []
    if row:
        cw = (w - gap * (n - 1)) / n
        cells = [(x + i * (cw + gap), y, cw, h) for i in range(n)]
    else:
        ch = (h - gap * (n - 1)) / n
        cells = [(x, y + i * (ch + gap), w, ch) for i in range(n)]
    for spec, (cx, cy, cw, ch) in zip(specs, cells):
        part, _, cap = spec.partition("|")
        part, cap = part.strip(), cap.strip()
        caph = lines_of(cap, 18, cw) * 18 * 1.35 + 12 if cap else 0
        if part.startswith("shot:"):
            shot_frame(slide, part[5:].strip(), cx, cy, cw, ch - caph)
        else:
            picture(slide, part, cx, cy, cw, ch - caph, "Picture")
        if cap:
            caption(slide, cap, cx, cy + ch - caph + 12, cw)


def flow(slide, spec, x, y, w):
    steps = [s.strip() for s in spec.split("->")]
    f = font(True, 21)
    cx, cy, hh = x, y, 46
    for i, step in enumerate(steps):
        sw = f.getlength(plain(step)) * 1.06 + 44
        if cx + sw > x + w:
            cx, cy = x, cy + hh + 12
        chip = rounded(slide, cx, cy, sw, hh, hh / 2, "Flow step")
        gradient(chip, [(0, BLUE, 0.24), (1, DEEP, 0.18)], 90)
        outline(chip, BLUE, 0.35)
        tf = chip.text_frame
        tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
        tf.vertical_anchor = MSO_ANCHOR.MIDDLE
        tf.word_wrap = False
        para(tf, step, 21, TEXT, lh=1.2, semibold=True, align=PP_ALIGN.CENTER, first=True)
        cx += sw
        if i < len(steps) - 1:
            if cx + 40 > x + w:
                cx, cy = x, cy + hh + 12
            tf2 = box(slide, cx, cy, 40, hh, "Flow arrow", MSO_ANCHOR.MIDDLE)
            para(tf2, "→", 24, GOLD, lh=1.2, align=PP_ALIGN.CENTER, first=True)
            cx += 40
    return cy + hh - y


def blocks(lines):
    """Groups the body into blocks: ('p', text) ('big', text) ('ul', [items]) ('flow', spec) ('card', title, blocks)."""
    out, cur = [], None
    target = out
    for raw in lines:
        line = raw.rstrip()
        if not line.strip() or line.startswith("<!--"):
            continue
        if line.startswith("- "):
            if target and target[-1][0] == "ul":
                target[-1][1].append(line[2:])
            else:
                target.append(("ul", [line[2:]]))
        elif line.startswith("### "):
            cur = ("card", line[4:], [])
            out.append(cur)
            target = cur[2]
        elif line.startswith("## "):
            target.append(("h2", line[3:]))
        elif line.startswith("# "):
            target.append(("h1", line[2:]))
        elif line.startswith("> "):
            target.append(("big", line[2:]))
        elif line.startswith("flow: "):
            target.append(("flow", line[6:]))
        else:
            target.append(("p", line))
    return out


def measure(b, w):
    kind = b[0]
    if kind == "h2":
        return lines_of(b[1], 62, w, True) * 62 * 1.08 + 30
    if kind == "big":
        return lines_of(b[1], 38, w, True) * 38 * 1.3 + 20
    if kind == "p":
        return lines_of(b[1], 28, w) * 28 * 1.4 + 16
    if kind == "ul":
        return sum(lines_of(t, 27, w - 34) * 27 * 1.34 + 12 for t in b[1]) + 6
    if kind == "card":
        return 22 + 19 * 1.3 + 10 + sum(measure(x, w - 56) for x in b[2]) + 10 + 18
    return 0


def place(slide, b, x, y, w):
    """Draws one block at (x, y) and returns its height."""
    kind, h = b[0], measure(b, w)
    if kind == "h2":
        tf = box(slide, x, y, w, h, "Title")
        para(tf, b[1], 62, TEXT, lh=1.08, semibold=True, first=True)
    elif kind in ("p", "big"):
        tf = box(slide, x, y, w, h, "Text")
        if kind == "big":
            para(tf, b[1], 38, TEXT, lh=1.3, semibold=True, first=True)
        else:
            para(tf, b[1], 28, MUTED, lh=1.4, first=True, card=b in CARD)
    elif kind == "ul":
        tf = box(slide, x, y, w, h, "Bullets")
        for i, t in enumerate(b[1]):
            para(tf, t, 27, MUTED, lh=1.34, after=12, first=i == 0, bullet=34, card=b in CARD)
    elif kind == "flow":
        h = flow(slide, b[1], x, y + 4, w) + 24
    elif kind == "card":
        card = rounded(slide, x, y + 4, w, h - 4, 18, "Card")
        gradient(card, [(0, BLUE, 0.17), (0.55, DEEP, 0.11), (1, GOLD, 0.09)], 35)
        outline(card, BLUE, 0.3)
        tf = box(slide, x + 28, y + 26, w - 56, 19 * 1.3, "Card heading")
        para(tf, b[1], 19, GOLD, lh=1.3, semibold=True, first=True, spacing=400, caps=True)
        cy = y + 26 + 19 * 1.3 + 10
        for inner in b[2]:
            CARD.append(inner)
            cy += place(slide, inner, x + 28, cy, w - 56)
    return h


CARD = []   # blocks inside a card: their bold text turns sunrise amber, as in the HTML


def label(slide, text, x, y):
    dash = rounded(slide, x, y + 11, 46, 4, 2, "Label mark")
    gradient(dash, [(0, PALE, 1), (0.4, GOLD, 1), (1, BLUE, 0.6)], 0)
    outline(dash, None, 0)
    tf = box(slide, x + 62, y, 1600, 32, "Label")
    para(tf, text, 22, BLUE, lh=1.3, semibold=True, first=True, spacing=300, caps=True)


def footer(slide, text, n, total):
    tf = box(slide, LEFT, 40, 1400, 26, "Footer")
    para(tf, text, 17, MUTED, lh=1.3, first=True, spacing=60)
    tf = box(slide, 1800 - 200, 40, 200, 26, "Slide number")
    para(tf, f"{n} / {total}", 17, MUTED, lh=1.3, first=True, align=PP_ALIGN.RIGHT)


def cover(slide, s):
    background(slide, s.get("background", [pitch.ART[True]])[0])
    if s.get("label"):
        tf = box(slide, 120, 92, 1680, 34, "Label")
        para(tf, s["label"][0], 22, BLUE, lh=1.3, semibold=True, first=True, spacing=300, caps=True,
             align=PP_ALIGN.CENTER)
    bl = blocks(s["body"])
    title = next((b[1] for b in bl if b[0] == "h1"), "")
    first, _, rest = title.partition(" ")
    tb = slide.shapes.add_textbox(px(120), px(440), px(1680), px(170))
    tb.name = "Title"
    tf = tb.text_frame
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    for t, color, name, spc in ((first + " ", TEXT, "Segoe UI", 0), (rest, BLUE, SEMI, 900)):
        r = p.add_run()
        r.text = t
        r.font.size, r.font.name, r.font.bold = Pt(75), name, color == TEXT
        r.font.color.rgb = RGBColor.from_string(color)
        rpr = r._r.get_or_add_rPr()
        if spc:
            rpr.set("spc", str(spc))
        rpr.append(parse_xml(f'<a:effectLst {NS}><a:outerShdw blurRad="254000" dist="0" algn="ctr" rotWithShape="0">'
                             f'{alpha_color("000000", 0.7).replace(" " + NS, "")}</a:outerShdw></a:effectLst>'))
    big = next((b[1] for b in bl if b[0] == "big"), "")
    if big:
        tf = box(slide, 340, 738, 1240, 110, "Tagline")
        para(tf, big, 38, TEXT, lh=1.3, semibold=True, first=True, align=PP_ALIGN.CENTER, shadow=True)
    rest_lines = [b[1] for b in bl if b[0] == "p"]
    if rest_lines:
        tf = box(slide, 120, 1016 - 40 * len(rest_lines), 1680, 40 * len(rest_lines), "Team")
        for i, t in enumerate(rest_lines):
            para(tf, t, 28, TEXT, lh=1.35, first=i == 0, align=PP_ALIGN.CENTER, shadow=True)


def build(lang):
    front, slides = pitch.parse(PITCH / f"{lang}.md")
    prs = Presentation()
    prs.slide_width, prs.slide_height = px(1920), px(1080)
    blank = prs.slide_layouts[6]
    warn = []
    for n, s in enumerate(slides, 1):
        slide = prs.slides.add_slide(blank)
        layout = s.get("layout", ["split"])[0]
        if layout == "cover":
            cover(slide, s)
        else:
            background(slide, s.get("background", [pitch.ART[False]])[0])
            footer(slide, front.get("footer", ""), n, len(slides))
            w = 1680 if layout in ("wide", "full") else COL
            y = TOP
            if s.get("label"):
                label(slide, s["label"][0], LEFT, y)
                y += 32 + 24
            for b in blocks(s["body"]):
                y += place(slide, b, LEFT, y, w)
            if y > BOTTOM + 8:
                warn.append(f"slide {n}: the text runs {int(y - BOTTOM)} px past the bottom; cut words")
            imgs = s.get("image", [])
            if layout == "wide":
                if BOTTOM - (y + 20) < 200:
                    warn.append(f"slide {n}: too little room left for the pictures")
                figures(slide, imgs, LEFT, y + 20, 1680, BOTTOM - y - 20, row=True)
            elif layout == "split":
                figures(slide, imgs, FIGX, TOP, FIGW, BOTTOM - TOP, row=False)
        notes = "\n".join(s["notes"]).strip()
        if notes:
            slide.notes_slide.notes_text_frame.text = notes
    BUILD.mkdir(parents=True, exist_ok=True)
    out = BUILD / f"deck-{lang}.pptx"
    prs.save(out)
    return out, warn


def main(argv):
    failed = False
    for lang in [a for a in argv if a in pitch.LANGS] or pitch.LANGS:
        out, warn = build(lang)
        print(f"{lang}: -> {out.relative_to(ROOT)}")
        for w in warn:
            print("  FAIL", w)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
