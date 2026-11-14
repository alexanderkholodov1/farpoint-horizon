# The rocket builder (C1, #6)

- From the launcher step ("Build your own rocket"), the player stacks real parts (`data/parts.json`, models in
  `assets/parts/`): engines, tanks, stage separators, fairings and a pair of side boosters. Gauges update live: payload
  to the mission's orbit against the craft's mass, delta-v per stage, thrust to weight at liftoff, cost, and what still
  stops it from flying. "Fly this rocket" makes it the mission's launcher (`custom`), which the mission model reads like
  any catalog launcher (`scripts/craft/rocket_design.gd`).
- The launch screen flies the assembled rocket: the boosters fall away, then the first stage separates and the second
  stage's engine takes over.
- Checked against the real vehicles, with no tuning: the Electron-type preset carries 313 kg to low orbit (real
  300 kg), the Falcon 9-type 17.2 t (real about 17.5 t reusable) and 5.3 t toward GEO (real about 5.5 t).
- The builder's text is English; the rest of the game is still Spanish until B2.
