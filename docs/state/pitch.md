# The pitch deck (draft)

- Seven slides in English and Spanish, written as text in `docs/pitch/en.md` and `es.md` and built into HTML and PDF by
  `python tools/pitch.py` (rules and format in `docs/pitch/README.md`). The order is the one the venue recommends,
  which replaces the older outline in `docs/team/pitch-outline.md` (that one had seven slides without a cover).
- Draft: the NASA pictures and the data slide are real; the game's screenshots are dashed frames to fill, and the
  live link, the final mission list, the source count, the teammate's AI tools and a classroom step are `TODO`.
  `python tools/pitch.py --final` passes only when none is left.
- In the game's look (deep space, the horizon arc, glass cards, the title over the Earth from the credits film), and
  also as editable PowerPoint (`python tools/pitch_pptx.py`). The built PDFs and PPTXs are committed in
  `docs/pitch/build/`; rebuild and commit them after any text change.
