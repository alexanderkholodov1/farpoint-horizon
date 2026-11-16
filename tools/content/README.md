# Content tools

| Script | What it makes |
|---|---|
| `credits.py` | `data/credits.json`, the in-game credits, from `docs/sources.md` and the README (run after a new source) |
| `submission_links.py` | `spaceapps/global-submission/links.md`, the form's link lists from `docs/sources.md`, each link opened |
| `data/` | The NASA data in `data/nasa/` and the mission photos (`fetch_nasa_data.py`, `fetch_lola_terrain.py`; see its README) |
| `audio/compose_music.py` | The game's music in `audio/` |
| `brand/make_splash.py` | The loading screen's image |
| `video/make_trailer.py` | The 30-second video, cut from a recording of `tests/trailer.tscn` |
| `deck/` | The decks: `pitch.py` and `pitch_pptx.py` (drafts from `spaceapps/local-pitch/source/`, into `build/deck/`), `pitch_art.py` (their backgrounds), `build_v2.py` (the deck v2 of the global submission) |
