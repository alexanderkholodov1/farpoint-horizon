# Priority now (alexanderkholodov1, 2026-11-14)

**A complete proof of concept first, judged by the challenge's requirements** (`kb/challenge/requirements.md`,
`kb/challenge/event-and-judging.md`): one mission played end to end that feels whole. Nothing that is not crucial for
that, even if part of the plan is left out. Within that, the mechanics before any more missions:

Rules in `AGENTS.md` (How we work).
Everything that moves must behave as in real life, in real time with a visible time warp. Known wrong and being redone:
- Done on `work/8-pilot` (#8): the launch climb runs in real time with the flight panel's time warp, and the trip to
  the Moon is real physics with a planned departure; see `pilot-flight.md`.
- Still to check against the same rule: the operation screen and the orbit views of `scripts/world.gd` (#30).
