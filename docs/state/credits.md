# Credits (C9, #14)

- The menu's **Credits** opens the credits: the team, what the game is built with (engine, font, Blender, outside
  models, NASA data, synthesized sounds), the AI agents used, and every source of `docs/sources.md` by section, with
  links that open in the browser (`scripts/screens/credits.gd`).
- They are built from the bibliography and the README by `python tools/credits.py` into `data/credits.json`;
  `tests/credits.gd` fails when a source is missing from the credits, so after adding a source run the script.
- Still open in #14: the first mission that teaches while you play. The README's AI list still has the teammate's TODO.
