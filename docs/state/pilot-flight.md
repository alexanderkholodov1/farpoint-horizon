# The pilot's flight to the Moon (#8): what is real and checked

Kept by the lead agent of alexanderkholodov1. Everything below runs in real time by default, with the flight panel's
time warp (×1 to ×100,000, keys `,` `.`; at most ×10 with an engine on; real time only near the ground).

- **Launch** (`scripts/flight/ascent.gd`, `scripts/screens/launch.gd`): about eight minutes to orbit, as a real
  climb; the climb's look is the teammate's (#12). `tests/flight.gd` flies it with a bot, a lazy, an idle and a wild pilot.
- **Trip** (`scripts/flight/transfer.gd`, `scripts/screens/flight.gd`): the Earth's and the Moon's pull, the Moon from
  JPL Horizons, as a map at true scale. Mission control plans the departure (phasing); the pilot burns at the mark,
  cuts, fires the mid-course correction and brakes into lunar orbit. Checked in `tests/flight.gd` against real
  values: low orbit 87.7 min; plan 110 km over the Moon, trip 82 h (Apollo 11: 76 h); burn 371 s to 10.78 km/s;
  correction about 53 m/s; capture 846 m/s into a 109 × 145 km orbit.
- **Landing** (`scripts/flight/terrain.gd`, `descent.gd`, `scripts/screens/landing.gd`): NASA LOLA ground at Shackleton's
  rim, the Moon's gravity, real time.
- Simplified, and said in the code: all in the plane of the ecliptic, no Sun's pull, the engine a steady push.
