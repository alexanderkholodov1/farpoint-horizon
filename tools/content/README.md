# Content tools

| Script | What it makes |
|---|---|
| `credits.py` | `data/credits.json`, the in-game credits, from `docs/sources.md` and the README (run after a new source) |
| `submission_links.py` | the form's link lists from `docs/sources.md`, each link opened; written to links.md in `spaceapps/global-submission/` when it runs (not kept in the repository) |
| `tools/content/data/` | The NASA data in `data/nasa/` and the mission photos (`fetch_nasa_data.py`, `fetch_lola_terrain.py`; see its README) |
| `tools/content/audio/compose_music.py` | The game's music in `assets/audio/` |
| `tools/content/brand/make_splash.py` | The loading screen's image |
| `tools/content/video/make_trailer.py` | The 30-second video, cut from a recording of `tests/look/trailer.tscn` |
| `tools/content/deck/` | The decks: `pitch.py` and `pitch_pptx.py` (drafts from `spaceapps/local-pitch/source/`, into `build/deck/`), `pitch_art.py` (their backgrounds), `build_v2.py` (the deck v2 of the global submission) |
