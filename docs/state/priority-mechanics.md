# Priority now: the mechanics before any more missions (alexanderkholodov1, 2026-11-14)

Rules in `AGENTS.md` (How we work).
Everything that moves must behave as in real life, in real time with a visible time warp. Known wrong and being redone:
- The flight to the Moon integrated in 0.1.18 (`scripts/screens/flight.gd`: the burn and the coast) is wrong (no
  physics, wrong scale, no phasing, no stated time) and is being rebuilt on `work/8-pilot` (#8) with real two-body
  physics, the Moon from JPL Horizons, planned departure, mid-course correction and lunar orbit capture. Do not build
  on it until that lands.
- The launch climb runs 8 times faster than real time without saying so (`TIME_SCALE` in `scripts/flight/ascent.gd`);
  it moves to real time with the time warp of the flight panel (#8).
- Other screens that show motion (the orbit views of `scripts/world.gd` used by the menu, the design and the
  operation) must be checked against the same rule.
