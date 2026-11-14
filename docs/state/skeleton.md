# The skeleton (phase B of the plan)

- **B1 done:** every screen in its own script under `scripts/screens/`, a small flow controller (`scripts/main.gd`),
  the 3D world in `scripts/world.gd`, shared state in the `GameState` autoload, the UI kit in `scripts/ui/kit.gd`.
  How to add a screen: `docs/architecture.md`. Verified: `tools/check.sh` green, the 16 walkthrough screenshots match
  v0.1.0 except where events are random.
- **Next:** B2 (catalogs to `data/*.json`, every value cited in `docs/sources.md`, English text with Spanish as an
  option, the game's name), then B3 (the shared room: one screen and Firebase).
- The two bugs kept from the sketch (the telescope's orbit overwritten to LEO, a double launch on a double click) were
  fixed in 0.1.8.
