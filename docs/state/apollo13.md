# Mission 1, Apollo 13: the adapter game (issue #45)

- `go("apollo13")` plays it on its own; inside the story the "Your turn" card (`data/story/apollo13.json`, scene
  `mission`, `"play": "apollo13"`) hands over to it and the outro follows when it is done.
- An emergency against the clock in the dark lunar module: the air left counts down (about two minutes), the master
  alarm and a heartbeat speed up, the lights flicker, and in the danger zone the view blurs and darkens at the edges.
  Mission Control reads the four steps (cardboard, bag, tape on the timing ring, hose); a wrong part costs 6 s.
  Never a fail: past the line the clock reads Overtime and the right part is lit. The win: slow motion, a flash, the
  needle turns around, "Saved!", then NASA's photo of the real "Mail Box" (AS13-62-9004) and up to three stars.
- Rules in `scripts/missions/apollo13/adapter.gd` (tested by `tests/apollo13.gd`), data in
  `data/missions/apollo13.json`. NASA facts only from S-apollo13-nasa and S-apollo13-mailbox; the steps' order and
  the gauge's pace are our simplification, said on screen.
- Next: the flight home (free return, `scripts/flight/transfer.gd`) and re-entry (#67); a card in the Missions screen
  once the campaign (#43) decides where story missions are listed.
