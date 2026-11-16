# What we deliver: NASA Space Apps 2026

Team **SK-Horizons** (Quito, Ecuador; local event Sangolquí, ESPE), challenge **Space Mission Design Game**, project
**Farpoint HORIZON**. Everything we hand in, in one place. The rules behind each piece are in
[`../challenge/`](../challenge/) (the global demo guide and the venue's delivery guide) and summarized in
[`../../kb/challenge/event-and-judging.md`](../../kb/challenge/event-and-judging.md).

## The global submission form (spaceappschallenge.org, closes Sunday 15 November 2026, 23:59 local time)

| Form field | What goes in | Where |
|---|---|---|
| Project Name, Summary, Project Details, Use of SI | The texts, ready to paste | [`form-en.md`](form-en.md) |
| Link to Project Demo | The 7-slide English deck v2 (PDF), never the 30-second video | [`deck/EN_17_SK-Horizons_v2.pdf`](deck/EN_17_SK-Horizons_v2.pdf) |
| Link to Final Project | The live game | https://farpoint-horizon.web.app |
| NASA Data; Space Agency Partner & Other Data | Every source the game uses, from `docs/sources.md`, each link opened | [`links.md`](links.md) (also inside `form-en.md`) |

The same texts in Spanish: [`formulario-es.md`](formulario-es.md).

## The deck

- **v2, for the global form** ([`deck/`](deck/)): the presented deck made richer with v0.3.0 (the six NASA missions and
  the cuyes, in-game captures), no `TODO` left, 7 slides, English. `EN_17_SK-Horizons_v2.pptx` is the editable file,
  the PDF is what the form links. `build_v2.py` is how it was made from the presented deck (python-pptx); the PDF is
  exported by PowerPoint.
- **As presented at the venue on 15 November** ([`presented/`](presented/)): the English and Spanish decks, the
  project sheet (`Ficha_Proyecto_ES_EN.pdf`, the venue's third file) and the pitch script.

## Other pieces

- The 30-second gameplay video: [`../demo/farpoint_horizon_30s.mp4`](../demo/farpoint_horizon_30s.mp4), also at
  https://youtu.be/3xZdPJr71bg. It goes inside the deck, not in the demo field.
- The README of the repository is the project's public page; the repository is public with an MIT `LICENSE`.

## Regenerate

```
python tools/submission_links.py      # the link lists, checked again
python tools/credits.py               # the in-game credits, after a new source
```
