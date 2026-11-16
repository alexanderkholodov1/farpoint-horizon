#!/usr/bin/env python3
"""Builds the pitch deck from its text sources and checks the event's rules.

    python tools/content/deck/pitch.py            # both languages: build/deck/deck-en.{html,pdf}, deck-es.{html,pdf}
    python tools/content/deck/pitch.py en         # one language
    python tools/content/deck/pitch.py --no-pdf   # HTML only (no browser needed)

The slides are written in spaceapps/local-pitch/source/<lang>.md (format in spaceapps/local-pitch/source/README.md). The PDF is printed by a headless
Chrome or Edge (set CHROME to its path if it is not found). Standard library only.

Rules checked (sources: spaceapps/rules/local-event.md, spaceapps/rules/event-and-judging.md):
- at most 7 slides, cover and closing included (8 or more costs a point locally and global eligibility);
- both languages have the same number of slides;
- every image exists;
- placeholders (`TODO` in the text, `shot:` images) are counted and listed, so nothing unfinished goes out unseen.
Exit code 1 when a rule fails; placeholders only warn, or fail with --final.
"""
import html
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PITCH = ROOT / "spaceapps" / "local-pitch" / "source"
BUILD = ROOT / "build" / "deck"   # drafts, not committed (the presented decks are in spaceapps/local-pitch)
MAX_SLIDES = 7
ART = {True: "spaceapps/local-pitch/source/art/cover.jpg", False: "spaceapps/local-pitch/source/art/space.png"}  # drawn by tools/content/deck/pitch_art.py
LANGS = ["en", "es"]


def inline(text):
    """The inline subset: **bold**, `code`, [label](url)."""
    t = html.escape(text, quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"`(.+?)`", r"<code>\1</code>", t)
    t = re.sub(r"\[(.+?)\]\((.+?)\)", r'<a href="\2">\1</a>', t)
    t = t.replace("TODO", '<mark>TODO</mark>')
    return t


def parse(path):
    """Returns (front matter dict, list of slides). A slide: {key: [values]} plus 'body' and 'notes' line lists."""
    text = path.read_text(encoding="utf-8")
    blocks = re.split(r"^---\s*$", text, flags=re.M)
    front = {}
    for line in blocks[0].splitlines():
        if ":" in line and not line.startswith("<!--"):
            k, v = line.split(":", 1)
            front[k.strip()] = v.strip()
    slides = []
    for block in blocks[1:]:
        lines = block.strip("\n").splitlines()
        if not any(l.strip() for l in lines):
            continue
        s = {"body": [], "notes": []}
        i = 0
        while i < len(lines) and re.match(r"^[a-z_]+:\s", lines[i]):  # header: key: value lines
            k, v = lines[i].split(":", 1)
            s.setdefault(k.strip(), []).append(v.strip())
            i += 1
        target = s["body"]
        for line in lines[i:]:
            if line.strip().lower() in ("notes:", "notas:"):
                target = s["notes"]
                continue
            target.append(line)
        slides.append(s)
    return front, slides


def body_html(lines, cover=False):
    """A `### heading` opens a card that holds what follows it, up to the next one or the end."""
    out, in_list, in_card = [], False, False
    for raw in lines:
        line = raw.rstrip()
        if line.startswith("<!--"):
            continue
        if line.startswith("- "):
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(line[2:])}</li>")
            continue
        if in_list:
            out.append("</ul>")
            in_list = False
        if not line.strip():
            continue
        if line.startswith("flow: "):
            out.append(flow_html(line[6:]))
        elif line.startswith("### "):
            if in_card:
                out.append("</div>")
            out.append(f'<div class="card"><p class="caps">{inline(line[4:])}</p>')
            in_card = True
        elif line.startswith("## "):
            out.append(f"<h2>{inline(line[3:])}</h2>")
        elif line.startswith("# "):
            first, _, rest = line[2:].partition(" ")
            title = f"{inline(first)} <span>{inline(rest)}</span>" if cover and rest else inline(line[2:])
            out.append(f"<h1>{title}</h1>")
        elif line.startswith("> "):
            out.append(f'<p class="big">{inline(line[2:])}</p>')
        else:
            out.append(f"<p>{inline(line)}</p>")
    if in_list:
        out.append("</ul>")
    if in_card:
        out.append("</div>")
    return "\n".join(out)


def figure_html(spec, problems, todos):
    """`path | caption` shows a picture; `shot: what to capture | caption` a dashed frame waiting for it."""
    part, _, caption = spec.partition("|")
    part, caption = part.strip(), caption.strip()
    cap = f"<figcaption>{inline(caption)}</figcaption>" if caption else ""
    if part.startswith("shot:"):
        todos.append("screenshot: " + part[5:].strip())
        return f'<figure class="todo"><div class="hole"><span>SCREENSHOT</span>{inline(part[5:].strip())}</div>{cap}</figure>'
    src = ROOT / part
    if not src.exists():
        problems.append(f"missing image {part}")
    rel = os.path.relpath(src, BUILD).replace(os.sep, "/")
    return f'<figure><img src="{html.escape(rel)}" alt="">{cap}</figure>'


def flow_html(spec):
    steps = [s.strip() for s in spec.split("->")]
    return '<div class="flow">' + '<i>→</i>'.join(f"<b>{inline(s)}</b>" for s in steps) + "</div>"


def render(lang):
    src = PITCH / f"{lang}.md"
    front, slides = parse(src)
    problems, todos = [], []
    if len(slides) > MAX_SLIDES:
        problems.append(f"{len(slides)} slides; the event allows {MAX_SLIDES} at most, cover and closing included")
    sections = []
    for n, s in enumerate(slides, 1):
        layout = s.get("layout", ["split"])[0]
        label = s.get("label", [""])[0]
        figs = "".join(figure_html(x, problems, todos) for x in s.get("image", []))
        body = body_html(s["body"], cover=layout == "cover")
        todos += [f"slide {n}: {l.strip()}" for l in s["body"] if "TODO" in l]
        foot = (f'<footer><span>{inline(front.get("footer", ""))}</span>'
                f'<span>{n} / {len(slides)}</span></footer>')
        head = f'<p class="label">{inline(label)}</p>' if label else ""
        bg = s.get("background", [""])[0] or ART[layout == "cover"]
        style = ""
        if bg:
            if not (ROOT / bg).exists():
                problems.append(f"missing background {bg}")
            rel = os.path.relpath(ROOT / bg, BUILD).replace(os.sep, "/")
            style = f' style="background-image:url(\'{html.escape(rel)}\')"'
        sections.append(
            f'<section class="slide {layout}"{style}><div class="text">{head}{body}</div>'
            f'<div class="figs n{len(s.get("image", []))}">{figs}</div>{foot}</section>')
    fonts = os.path.relpath(ROOT / "assets" / "fonts", BUILD).replace(os.sep, "/")
    page = TEMPLATE.replace("{FONTS}", fonts).replace("{LANG}", lang) \
        .replace("{TITLE}", html.escape(front.get("title", "Pitch"))).replace("{SLIDES}", "\n".join(sections))
    BUILD.mkdir(parents=True, exist_ok=True)
    out = BUILD / f"deck-{lang}.html"
    out.write_text(page, encoding="utf-8")
    notes = [f"# {front.get('title', '')} ({lang}): speaker notes\n"]
    for n, s in enumerate(slides, 1):
        notes.append(f"## {n}. {s.get('label', [''])[0]}\n" + "\n".join(s["notes"]).strip() + "\n")
    (BUILD / f"notes-{lang}.md").write_text("\n".join(notes), encoding="utf-8")
    return out, len(slides), problems, todos


def find_browser():
    if os.environ.get("CHROME"):
        return os.environ["CHROME"]
    for name in ("chrome", "google-chrome", "chromium", "msedge"):
        if shutil.which(name):
            return shutil.which(name)
    for p in (r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
              "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"):
        if Path(p).exists():
            return p
    return None


def to_pdf(html_path):
    browser = find_browser()
    if not browser:
        return "no Chrome or Edge found (set CHROME); PDF skipped"
    pdf = html_path.with_suffix(".pdf")
    subprocess.run([browser, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--allow-file-access-from-files",
                    f"--print-to-pdf={pdf}", html_path.resolve().as_uri()],
                   check=False, capture_output=True, timeout=120)
    return None if pdf.exists() else "the browser wrote no PDF"


def main(argv):
    langs = [a for a in argv if a in LANGS] or LANGS
    failed, counts = False, {}
    for lang in langs:
        out, count, problems, todos = render(lang)
        counts[lang] = count
        msg = None if "--no-pdf" in argv else to_pdf(out)
        print(f"{lang}: {count} slides -> {out.relative_to(ROOT)}" + ("" if "--no-pdf" in argv or msg else " + .pdf"))
        if msg:
            print(f"  note: {msg}")
        for p in problems:
            print(f"  FAIL {p}")
            failed = True
        for t in todos:
            print(f"  todo {t}")
        if todos and "--final" in argv:
            failed = True
    if len(set(counts.values())) > 1:
        print(f"FAIL the languages differ in slide count: {counts}")
        failed = True
    return 1 if failed else 0


TEMPLATE = """<!doctype html>
<html lang="{LANG}"><head><meta charset="utf-8"><title>{TITLE}</title>
<style>
/* The game's look (scripts/ui/kit.gd, scripts/ui/horizon.gd): deep space, the horizon arc from sunrise amber to deep
   blue, horizon-blue glass panels. Backgrounds: spaceapps/local-pitch/source/art (tools/content/deck/pitch_art.py). Type: Inter (assets/fonts/). */
@font-face { font-family: Inter; src: url("{FONTS}/Inter-Regular.otf"); font-weight: 400; }
@font-face { font-family: Inter; src: url("{FONTS}/Inter-SemiBold.otf"); font-weight: 600; }
@font-face { font-family: InterDisplay; src: url("{FONTS}/InterDisplay-Bold.otf"); font-weight: 700; }
@page { size: 1920px 1080px; margin: 0; }
:root { --bg: #0b1220; --text: #eff4ff; --muted: #a9b9d4; --blue: #78b8ff; --gold: #ffa842; --pale: #ffdb9e;
        --deep: #1447a8; --ice: #9ee6ff; --glass: rgba(120,184,255,.10); --edge: rgba(120,184,255,.30); }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { background: #03050b; }
body { font-family: Inter, system-ui, sans-serif; color: var(--text); -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.slide { width: 1920px; height: 1080px; position: relative; overflow: hidden; background: var(--bg) center/cover no-repeat;
         display: grid; grid-template-columns: 820px 1fr; grid-template-rows: minmax(0, 1fr); gap: 72px;
         padding: 104px 120px 130px; page-break-after: always; margin: 0 auto 24px; }
@media print { .slide { margin: 0; } }
.slide.full { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.slide.full .text { align-self: end; }
.slide.wide { grid-template-columns: 1fr; grid-template-rows: auto minmax(0, 1fr); gap: 36px; }
.text, .figs, footer { position: relative; }
.text, .figs { min-height: 0; overflow: hidden; }

/* cover: the film's opening, the title over the Earth and the arc under it, as the game shows it */
.slide.cover { grid-template-columns: 1fr; grid-template-rows: 1fr; padding: 92px 120px 64px; }
.slide.cover .text { display: flex; flex-direction: column; align-items: center; text-align: center; }
.cover .label { margin: 0; }
.cover .label::before { display: none; }
.cover h1 { font-size: 150px; margin: 318px 0 0; line-height: 1; text-shadow: 0 0 40px rgba(0,0,0,.65); }
.cover h1 span { color: var(--blue); font-family: Inter, sans-serif; font-weight: 600; letter-spacing: .1em; }
.cover .text > p.big { margin-top: 112px; max-width: 1240px; font-size: 38px; text-shadow: 0 2px 18px rgba(0,0,0,.9); }
.cover p:not(.big) { color: var(--text); font-size: 28px; margin-bottom: 8px; text-shadow: 0 2px 12px #000; }
.cover p.big + p { margin-top: auto; }

.label { font-size: 22px; font-weight: 600; letter-spacing: .24em; text-transform: uppercase; margin-bottom: 24px; color: var(--blue); }
.label::before { content: ""; display: inline-block; width: 46px; height: 10px; margin-right: 16px; vertical-align: .12em;
         border-top: 3px solid var(--gold); border-radius: 50% 50% 0 0 / 100% 100% 0 0;
         filter: drop-shadow(0 0 6px rgba(255,168,66,.8)); }
h1 { font-family: InterDisplay, Inter, sans-serif; font-weight: 700; font-size: 132px; line-height: .95; letter-spacing: -.02em; margin-bottom: 28px; }
h2 { font-family: InterDisplay, Inter, sans-serif; font-weight: 700; font-size: 62px; line-height: 1.06; letter-spacing: -.01em;
     margin-bottom: 34px; text-shadow: 0 0 36px rgba(120,184,255,.25); }
p { font-size: 28px; line-height: 1.4; color: var(--muted); margin-bottom: 18px; }
p.big { font-size: 38px; line-height: 1.3; color: var(--text); font-weight: 600; }
.text > p.big { margin-top: 10px; }
p.caps { font-size: 19px; font-weight: 600; letter-spacing: .22em; text-transform: uppercase; color: var(--gold); margin: 0 0 10px; }
ul { list-style: none; margin-bottom: 18px; }
li { font-size: 27px; line-height: 1.34; color: var(--muted); padding-left: 34px; position: relative; margin-bottom: 14px; }
li::before { content: ""; position: absolute; left: 0; top: .6em; width: 16px; height: 3px; border-radius: 2px;
             background: linear-gradient(90deg, var(--gold), var(--blue)); }
strong { color: var(--text); font-weight: 600; }
code { font-family: Consolas, monospace; font-size: .85em; color: var(--ice); }
a { color: var(--blue); text-decoration: none; }
mark { background: linear-gradient(90deg, var(--gold), #ffc477); color: #1a1000; padding: 0 .25em; border-radius: 4px; }
.card { margin-top: 22px; padding: 22px 28px 8px; border-radius: 18px; border: 1px solid var(--edge);
        background: linear-gradient(135deg, rgba(120,184,255,.16), rgba(20,71,168,.10) 55%, rgba(255,168,66,.08));
        box-shadow: 0 0 0 1px rgba(255,255,255,.03) inset, 0 18px 50px rgba(0,0,0,.35); }
.card strong { color: var(--gold); }
.card ul { margin-bottom: 8px; }

.figs { display: grid; gap: 24px; align-content: center; }
.figs.n0 { display: none; }
.figs.n1 { grid-template-rows: minmax(0, 1fr); }
.figs.n2 { grid-template-rows: minmax(0, 1fr) minmax(0, 1fr); }
.figs.n3 { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }
.figs.n3 figure:first-child { grid-column: span 2; }
.wide .figs { grid-template-columns: repeat(var(--cols, 3), 1fr); grid-template-rows: minmax(0, 1fr); }
.wide .figs.n2 { --cols: 2; } .wide .figs.n4 { --cols: 4; }
.wide .figs.n3 figure:first-child { grid-column: auto; }
figure { min-height: 0; display: flex; flex-direction: column; }
figure img { width: 100%; height: 100%; min-height: 0; object-fit: cover; border-radius: 16px; flex: 1;
             border: 1px solid var(--edge); box-shadow: 0 0 60px rgba(120,184,255,.18), 0 24px 60px rgba(0,0,0,.5); }
figcaption { font-size: 18px; color: var(--muted); margin-top: 12px; line-height: 1.35; }
.todo .hole { flex: 1; min-height: 200px; border: 2px dashed rgba(255,168,66,.75); border-radius: 16px; display: flex; flex-direction: column;
              justify-content: center; padding: 28px; font-size: 22px; color: var(--muted);
              background: linear-gradient(160deg, rgba(255,168,66,.12), rgba(120,184,255,.06) 60%, rgba(11,18,32,.4)); }
.todo .hole span { font-size: 17px; font-weight: 600; letter-spacing: .22em; color: var(--gold); margin-bottom: 12px; }
.cover .figs, .full .figs { display: none; }
.flow { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin: 6px 0 24px; }
.flow b { font-size: 21px; font-weight: 600; color: var(--text); border: 1px solid var(--edge); border-radius: 999px; padding: 10px 20px;
          background: linear-gradient(180deg, rgba(120,184,255,.22), rgba(20,71,168,.14)); }
.flow i { font-style: normal; color: var(--gold); font-size: 24px; }
footer { position: absolute; left: 120px; right: 120px; top: 40px; display: flex; justify-content: space-between;
         font-size: 17px; letter-spacing: .04em; color: rgba(169,185,212,.75); }
.cover footer { display: none; }
.overflow::after { content: "TOO MUCH TEXT: cut this slide"; position: absolute; top: 24px; right: 24px; background: #ff7366;
         color: #200; font: 600 22px Inter, sans-serif; padding: 8px 14px; border-radius: 6px; }
</style></head><body>
{SLIDES}
<script>
/* Marks a slide whose text or pictures do not fit, so the PDF itself shows it (agents: look at every page). */
for (const s of document.querySelectorAll(".slide")) {
  for (const box of s.querySelectorAll(".text, .figs")) {
    if (box.scrollHeight > box.clientHeight + 2 || box.scrollWidth > box.clientWidth + 2) s.classList.add("overflow");
  }
}
</script>
</body></html>
"""

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
