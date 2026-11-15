#!/usr/bin/env python3
"""Builds the pitch deck from its text sources and checks the event's rules.

    python tools/pitch.py            # both languages: docs/pitch/build/deck-en.{html,pdf}, deck-es.{html,pdf}
    python tools/pitch.py en         # one language
    python tools/pitch.py --no-pdf   # HTML only (no browser needed)

The slides are written in docs/pitch/<lang>.md (format in docs/pitch/README.md). The PDF is printed by a headless
Chrome or Edge (set CHROME to its path if it is not found). Standard library only.

Rules checked (sources: kb/challenge/local-event.md, kb/challenge/event-and-judging.md):
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

ROOT = Path(__file__).resolve().parent.parent
PITCH = ROOT / "docs" / "pitch"
BUILD = PITCH / "build"
MAX_SLIDES = 7
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


def body_html(lines):
    out, in_list = [], False
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
            out.append(f'<p class="caps">{inline(line[4:])}</p>')
        elif line.startswith("## "):
            out.append(f"<h2>{inline(line[3:])}</h2>")
        elif line.startswith("# "):
            out.append(f"<h1>{inline(line[2:])}</h1>")
        elif line.startswith("> "):
            out.append(f'<p class="big">{inline(line[2:])}</p>')
        else:
            out.append(f"<p>{inline(line)}</p>")
    if in_list:
        out.append("</ul>")
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
        body = body_html(s["body"])
        todos += [f"slide {n}: {l.strip()}" for l in s["body"] if "TODO" in l]
        foot = (f'<footer><span>{inline(front.get("footer", ""))}</span>'
                f'<span>{n} / {len(slides)}</span></footer>')
        head = f'<p class="label">{inline(label)}</p>' if label else ""
        bg = s.get("background", [""])[0]
        style = ""
        if bg:
            if not (ROOT / bg).exists():
                problems.append(f"missing background {bg}")
            rel = os.path.relpath(ROOT / bg, BUILD).replace(os.sep, "/")
            style = f' style="background-image:url(\'{html.escape(rel)}\')"'
        sections.append(
            f'<section class="slide {layout}"{style}><div class="text">{head}{body}</div>'
            f'<div class="figs n{len(s.get("image", []))}">{figs}</div>{foot}</section>')
    fonts = os.path.relpath(ROOT / "fonts", BUILD).replace(os.sep, "/")
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
/* Colours are the game's horizon arc (scripts/ui/kit.gd): navy, horizon blue, sunrise amber. Type: Inter (fonts/). */
@font-face { font-family: Inter; src: url("{FONTS}/Inter-Regular.otf"); font-weight: 400; }
@font-face { font-family: Inter; src: url("{FONTS}/Inter-SemiBold.otf"); font-weight: 600; }
@font-face { font-family: InterDisplay; src: url("{FONTS}/InterDisplay-Bold.otf"); font-weight: 700; }
@page { size: 1920px 1080px; margin: 0; }
:root { --bg: #0b1220; --panel: #111b2e; --text: #eff4ff; --muted: #9fb0cc; --blue: #78b8ff; --gold: #ffa842;
        --ice: #9ee6ff; --line: #24324d; }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { background: #05080f; }
body { font-family: Inter, system-ui, sans-serif; color: var(--text); -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.slide { width: 1920px; height: 1080px; position: relative; overflow: hidden; background: var(--bg) center/cover no-repeat;
         display: grid; grid-template-columns: 820px 1fr; grid-template-rows: minmax(0, 1fr); gap: 72px; padding: 104px 120px 120px; page-break-after: always;
         margin: 0 auto 24px; }
@media print { .slide { margin: 0; } }
.slide.cover, .slide.full { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.slide.full .text { align-self: end; }
.slide.full::before { content: ""; position: absolute; inset: 0;
         background: linear-gradient(90deg, rgba(5,8,15,.92) 0%, rgba(5,8,15,.6) 50%, rgba(5,8,15,.1) 100%); }
.slide.wide { grid-template-columns: 1fr; grid-template-rows: auto minmax(0, 1fr); gap: 40px; }
.text, .figs, footer { position: relative; }
.text, .figs { min-height: 0; overflow: hidden; }
.slide.cover::after { content: ""; position: absolute; left: -10%; right: -10%; top: 170px; height: 1400px; border-radius: 50%;
         border-top: 3px solid rgba(255,168,66,.85); box-shadow: 0 -30px 120px rgba(120,184,255,.35), inset 0 40px 120px rgba(120,184,255,.18); }
.slide.cover .text { z-index: 1; align-self: end; }
.label { font-size: 22px; font-weight: 600; letter-spacing: .22em; text-transform: uppercase; color: var(--blue); margin-bottom: 28px; }
h1 { font-family: InterDisplay, Inter, sans-serif; font-weight: 700; font-size: 132px; line-height: .95; letter-spacing: -.02em; margin-bottom: 28px; }
h2 { font-family: InterDisplay, Inter, sans-serif; font-weight: 700; font-size: 64px; line-height: 1.05; letter-spacing: -.01em; margin-bottom: 36px; }
p { font-size: 30px; line-height: 1.4; color: var(--muted); margin-bottom: 20px; }
p.big { font-size: 40px; line-height: 1.3; color: var(--text); }
p.caps { font-size: 20px; font-weight: 600; letter-spacing: .2em; text-transform: uppercase; color: var(--gold); margin: 28px 0 12px; }
ul { list-style: none; margin-bottom: 20px; }
li { font-size: 28px; line-height: 1.38; color: var(--muted); padding-left: 32px; position: relative; margin-bottom: 14px; }
li::before { content: ""; position: absolute; left: 0; top: .62em; width: 14px; height: 2px; background: var(--gold); }
strong { color: var(--text); font-weight: 600; }
em { color: var(--ice); font-style: normal; }
code { font-family: Consolas, monospace; font-size: .85em; color: var(--ice); }
a { color: var(--blue); text-decoration: none; }
mark { background: var(--gold); color: #1a1000; padding: 0 .2em; border-radius: 3px; }
.figs { display: grid; gap: 24px; align-content: center; }
.figs.n0 { display: none; }
.figs.n1 { grid-template-rows: minmax(0, 1fr); }
.figs.n2 { grid-template-rows: minmax(0, 1fr) minmax(0, 1fr); }
.figs.n3 { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }
.figs.n3 figure:first-child { grid-column: span 2; }
.wide .figs { grid-template-rows: minmax(0, 1fr); grid-template-columns: repeat(var(--cols, 3), 1fr); grid-template-rows: none; }
.wide .figs.n2 { --cols: 2; } .wide .figs.n4 { --cols: 4; }
.wide .figs.n3 figure:first-child { grid-column: auto; }
figure { min-height: 0; display: flex; flex-direction: column; }
figure img { width: 100%; height: 100%; min-height: 0; object-fit: cover; border-radius: 10px; border: 1px solid var(--line); flex: 1; }
figcaption { font-size: 18px; color: var(--muted); margin-top: 10px; line-height: 1.35; }
.todo .hole { flex: 1; min-height: 200px; border: 3px dashed var(--gold); border-radius: 10px; display: flex; flex-direction: column;
              justify-content: center; padding: 32px; font-size: 24px; color: var(--muted); background: rgba(255,168,66,.05); }
.todo .hole span { font-size: 18px; font-weight: 600; letter-spacing: .2em; color: var(--gold); margin-bottom: 12px; }
.cover .figs, .full .figs { display: none; }
.flow { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin: 12px 0 24px; }
.flow b { font-size: 22px; font-weight: 600; color: var(--text); background: var(--panel); border: 1px solid var(--line);
          border-radius: 8px; padding: 10px 16px; }
.flow i { font-style: normal; color: var(--gold); font-size: 26px; }
footer { position: absolute; left: 120px; right: 120px; bottom: 44px; display: flex; justify-content: space-between;
         font-size: 18px; color: var(--muted); border-top: 1px solid var(--line); padding-top: 16px; }
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
