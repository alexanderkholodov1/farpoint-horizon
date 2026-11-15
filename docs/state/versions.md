# Version lines (2026-11-15)

- `main` holds v0.2.2 (pull request #89).
- **`v0.2.3`**: phone fixes on top of v0.2.2; its version pull request is #92. No new story, missions or modes.
- **`v0.3.0`**: the story campaign (the cuyes, six NASA missions), minigames, and the crew of friends; its version
  pull request is #93. Free missions stay playable apart from the campaign.
- `v0.2.3` is not in `v0.3.0` yet: when #92 is merged, `v0.3.0` merges `main` so the story is built on the fixed game.
- A fix goes on `v0.2.3` (`git switch -c work/<issue>-<name> origin/v0.2.3`, and `tools/pr-when-green.sh "<what>"
  body.md v0.2.3`); everything else on `v0.3.0`, the tools' default.
- `v0.2.2` is merged and can be deleted by a team member.

Delete this note when only one version line is open.
