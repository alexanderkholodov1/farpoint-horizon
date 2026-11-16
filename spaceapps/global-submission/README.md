# The global submission (spaceapps.org, closes 15 November 2026 at 23:59)

What goes into each field of NASA's form. The rules behind it: `../rules/global-demo-guide.pdf` and
`../rules/event-and-judging.md`.

| Form field | What goes in | Where |
|---|---|---|
| Project Name, Summary, Project Details, Use of SI | The texts, ready to paste | [form-en.md](form-en.md) |
| Link to Project Demo | The 7-slide English deck v2 (PDF), not the video | [deck/Farpoint-HORIZON_NASA-Space-Apps-2026_Demo_EN.pdf](deck/Farpoint-HORIZON_NASA-Space-Apps-2026_Demo_EN.pdf), linked from the form pinned to its commit |
| Link to Final Project | The live game | https://farpoint-horizon.web.app |
| NASA Data; Space Agency Partner & Other Data | Every source of `docs/sources.md`, each opened and read | [links.md](links.md), also inside `form-en.md` |

- [form-es.md](form-es.md): the same texts in Spanish, for the venue and the pitch.
- `deck/`: the deck v2 (`.pptx` editable, `.pdf` linked) and its images (`img/`: in-game captures and the crew's
  portraits). It is built from the presented deck by `tools/content/deck/build_v2.py` and exported to PDF by PowerPoint.
- `video/farpoint-horizon-30s.mp4`: the 29-second gameplay video (also https://youtu.be/3xZdPJr71bg); it belongs
  inside the deck, not in the demo field.

Regenerate the links after a new source: `python tools/content/submission_links.py`. A link that answers is checked
again by reading it (see `docs/guides/testing.md`, Sources).
