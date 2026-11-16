"""The submission form's two link lists, made from the bibliography (docs/sources.md) and checked one by one.

The Space Apps form asks for every NASA resource used ("NASA Data") and every other resource, code, image or tool
("Space Agency Partner & Other Data"), as Link Text + Link Url. Writing them by hand let wrong and missing links in,
so this script reads every entry of docs/sources.md (the list of what the game really uses), sorts it into the two
lists, opens each URL and writes spaceapps/global-submission/links.md with the result of the check beside each row.

Usage: python tools/content/submission_links.py            (checks every URL; about a minute)
       python tools/content/submission_links.py --no-check
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ROOT / "docs" / "sources.md"
OUT = ROOT / "spaceapps" / "global-submission" / "links.md"

# Hosts whose content is NASA's (NASA centres, JPL, NASA archives and the NASA-hosted journals and repositories).
NASA_HOSTS = ("nasa.gov", "pds-geosciences.wustl.edu", "apollojournals.org", "github.com/nasa/")
# Links in the bibliography that are rules we follow, not resources we use (NASA's media guidelines).
SKIP = ("nasa-brand-center",)
# Tools and libraries the game is made with: not in docs/sources.md, which lists what the game's content uses.
TOOLS = [
    ("Godot Engine (MIT license): the game engine", "https://godotengine.org"),
    ("Blender (GPL): our 3D models, built by our scripts", "https://www.blender.org"),
    ("Inter typeface by Rasmus Andersson (SIL Open Font License 1.1)", "https://rsms.me/inter/"),
    ("Firebase Hosting (Google): hosts the web version", "https://firebase.google.com/products/hosting"),
]


def _trim(u):
    u = u.rstrip(".,;:`")
    while u.endswith(")") and u.count("(") < u.count(")"):
        u = u[:-1].rstrip(".,;:")
    return u


def entries():
    text = SOURCES.read_text(encoding="utf-8")
    for block in re.split(r"\n(?=- \*\*S)", text):
        m = re.match(r"- \*\*(S[-\w]+)\*\* (.*)", block, re.S)
        if not m:
            continue
        sid, body = m.group(1), " ".join(m.group(2).split())
        body = body.split("\n## ")[0]
        urls = list(dict.fromkeys(_trim(u) for u in re.findall(r"https?://\S+", body)))
        if not urls:
            continue   # an entry without its own link (our simplification, or a layer of another entry)
        t = re.search(r"\*([^*]+)\*", body)
        who = body.split(". *")[0] if ". *" in body else ""
        name = t.group(1) if t else body[:60]
        label = f"{name} ({who})" if who and len(who) < 70 else name
        urls = [u for u in urls if not any(x in u for x in SKIP)]
        for k, u in enumerate(urls):
            yield sid, label.replace("|", "/") + ("" if k == 0 else f" [{k + 1}]"), u


def check(url):
    try:
        r = subprocess.run(["curl", "-s", "-o", "/dev/null", "-L", "--max-time", "25", "-A",
                            "Mozilla/5.0 (Windows NT 10.0; Win64; x64)", "-w", "%{http_code}", url],
                           capture_output=True, text=True, timeout=40)
        return r.stdout.strip() or "000"
    except Exception:
        return "000"


def main():
    do_check = "--no-check" not in sys.argv
    nasa, other = [], []
    for sid, label, url in entries():
        (nasa if any(h in url for h in NASA_HOSTS) else other).append((sid, label, url))
    lines = ["# Submission links, made from docs/sources.md", "",
             "Written by `python tools/content/submission_links.py`; do not edit by hand. Each row is one entry of",
             "`docs/sources.md` (the resources the game really uses), with the HTTP status found when it was opened.",
             "200 means it opens; 403 or 000 means the site refuses scripts or was slow: open those by hand in a private",
             "window before pasting.", ""]
    for title, rows in (("NASA Data", nasa), ("Space Agency Partner & Other Data", other)):
        lines += [f"## {title} ({len(rows)})", "", "| Link Text | Link Url | Source | Opens |", "|---|---|---|---|"]
        for sid, label, url in rows:
            code = check(url) if do_check else "not checked"
            lines.append(f"| {label} | {url} | {sid} | {code} |")
            print(code, sid, url, flush=True)
        if title != "NASA Data":
            for label, url in TOOLS:
                code = check(url) if do_check else "not checked"
                lines.append(f"| {label} | {url} | tool | {code} |")
        lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print("wrote", OUT, len(nasa), "NASA,", len(other), "other")


if __name__ == "__main__":
    main()
