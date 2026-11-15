# Version lines

Decided by the team on 2026-11-15 (issue #72).

- **`v0.2.1`**, branch cut from `main` after v0.2.0 was merged; milestone v0.2.1. Fixes and adjustments to v0.2.0
  only: bugs, readability, controls, what play sessions found. No new story, missions or modes. It reaches `main`
  through one version pull request, opened only when every issue in milestone v0.2.1 is done and closed; until then
  finished pieces are integrated into `v0.2.1` and wait there.
- **`v0.3.0`**, milestone v0.3.0. The story campaign (the cuyes, six NASA missions), minigames, and the crew of
  friends where each role matters. Free missions stay playable apart from the campaign.
- A fix: `git fetch origin && git switch -c work/<issue>-<name> origin/v0.2.1`, and
  `tools/pr-when-green.sh "<what it adds>" body.md v0.2.1` (the tool defaults to the newest branch, `v0.3.0`).
- When `v0.2.1` is merged into `main`, `v0.3.0` merges `main` so the story is built on the fixed game.

Delete this note when only one version line is open.
