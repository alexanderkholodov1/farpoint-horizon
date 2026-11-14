# Decisions

Newest last. A decision here overrides anything older in the repository. Open items are the team's to decide;
agents bring evidence, alternatives and a recommendation.

## Decided
| Date (UTC) | Decision | Who |
|---|---|---|
| 2026-11-14 | The team enters the 2026 NASA Space Apps Challenge with the challenge "Space Mission Design Game" | Team |
| 2026-11-14 | Two human members, each with their own AI agents across several accounts, working from this GitHub repository | Team |
| 2026-11-14 | Every material is in English: the game, the repository, the pitch deck, the submission | Team |
| 2026-11-14 | Kerbal Space Program is the main inspiration: we take what is relevant and build our own product | Team |
| 2026-11-14 | The team defines the game idea; agents help with the brainstorm and are free to propose anything | Team |
| 2026-11-14 | Firebase (the lead's account) for online multiplayer and for hosting the playable link; the Firebase project is created once the brainstorm names the game | Team |
| 2026-11-14 | Everything is frozen by 07:00 on Sunday 2026-11-15; no fixed time slots before that. The website submission (closes Sunday 23:59 local) is done as well | Team |
| 2026-11-14 | 3D, with the complete mission as in Kerbal: build the craft in a builder, plan the orbit, reach orbit, travel to the target, land. Kerbal's fail-and-retry loop and its difficulty are not taken | Team |
| 2026-11-14 | Godot, optimized for the web from the start; final call after the lead sees a working demo (a web export with a JavaScript round trip is already measured, `tech/platform-options.md` section 6) | Team |
| 2026-11-14 | Disclosure: every source of information, formula and data is cited, and a disclosure section names the AI agents used; no watermarks | Team |
| 2026-11-14 | The teammate's sketch (about 70% there) is the base; it needs a stronger plot and game design, well-made 3D models and a more unique UI | Team |
| 2026-11-14 | Several mission types | Team |
| 2026-11-14 | Audience: the general public; one complete, satisfying mission, simpler than Kerbal; the main takeaway is that there is no perfect design | Team |
| 2026-11-14 | Only a person merges, the lead or the teammate; agents prepare one pull request per functional version and never merge | Team |
| 2026-11-14 | Versions: v0.1.0 is the first playable sketch with the base; steps toward the next version are 0.1.1, 0.1.2, ... on the version branch; v0.2.0 is the second version with everything corrected; tags come from the release workflow | Team |
| 2026-11-14 | Repository layout: `docs/challenge/` (challenge material), `docs/team/` (team notes), `docs/design/`, `docs/agents/`, `kb/`, `tools/`; one rulebook `AGENTS.md`, imported by `CLAUDE.md` | Team |
| 2026-11-14 | Vision of v0.2.0 (`docs/design/vision.md`): fun and satisfaction first, humor, explosions possible on purpose, stations including a pilot and ground control, varied missions (Earth, Moon, Mars, Venus, one-way and returning, real and imagined), launches from the equator, random extra objectives and role bonuses, in-flight failures as mini-games, a leaderboard and gallery with no head-to-head competition | Team |
| 2026-11-14 | Blender may join the pipeline for 3D models when they are needed (the teammate researched how to connect it) | Team |

## Open
| # | Question | Why it matters | Status |
|---|---|---|---|
| D2 | The game idea, its plot and its name | Everything else follows from it | Design round in progress |
| D4 | Multiplayer form for up to four players: what is shared, who acts when | Core requirement C4 | After the design round |
| D5 | Who owns which part of the game | Keeps two people's agents from colliding | Open; written in `docs/STATE.md` once agreed |
| D6 | The repository's open-source license | The event's terms point to open source | MIT proposed in the v0.1.0 pull request |
