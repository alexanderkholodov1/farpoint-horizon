# Agent guide: SK Horizon, Mission Architect

The one rulebook for every agent in this repository, whoever runs it (Claude Code, Codex, Cursor, Gemini or any
other) and whichever team member it works for. `CLAUDE.md` only imports this file.

The game: a 3D space-mission game in Godot 4.7 for the 2026 NASA Space Apps Challenge, challenge "Space Mission
Design Game", by team SK Horizon (Quito, Ecuador). Alone or with up to three friends, players build a craft, plan its
route, launch it, fly it to its target, land it or keep it talking to Earth, and enjoy what they achieved.

## Read first
1. `docs/STATE.md`: where the project is today and what comes next.
2. `docs/design/vision.md`: what the game will be and what it will have. Every change serves it.
3. `kb/README.md`, then `kb/challenge/requirements.md` (the challenge as IDs) and `kb/decisions.md` (what the team
   decided; open items are theirs to decide).
4. `docs/architecture.md` before touching code; `docs/design/criteria.md` before touching anything players see.
5. If you lead a piece of work (you plan it, brief other agents and integrate their results), `docs/agents/lead.md`.

## Who decides
- **The two team members decide**: the idea, the design, scope, accounts, anything public. Agents bring evidence,
  alternatives and a recommendation, and are free to propose anything, concepts included.
- **Only a person merges**, either team member. Agents prepare one pull request per functional version and never merge.
- Agents talk with their person in that person's language. Everything written into the repository and the game is in
  English.

## How we work
- **Fun and satisfaction first.** The player should feel the pride of watching their own craft lift off, deploy,
  arrive and land. Missing something is never a failure screen; achieving more is rewarded. Kerbal Space Program is
  the main inspiration (the builder, route and orbit planning, the whole journey, freedom to invent, humor, the
  spectacle of launch and landing); its difficulty and its fail-and-retry loop are not.
- **Nothing that looks AI-made.** `docs/design/criteria.md` holds the team's design criteria; they apply to models,
  UI, motion, sound and copy.
- **Real data at the core.** The judges score how much NASA data is part of the game. Values come from
  `kb/data/reference.json` or another cited source; every formula and value is cited where it is defined, and the
  game's credits list them. A simplified value says so.
- **Data apart from code.** Missions, parts, launchers, orbits, events and texts live in data (today
  `scripts/game_data.gd`), so content and balance change without touching logic.
- **Measure before you claim.** Run it, read the log, look at the screenshot; cite the file and line or the command.
  A guess is labeled as a guess.
- **Proven by playing.** A feature is done when someone played it as a player would and looked at the screen;
  say what you checked.
- **Plain explanations.** Every concept a player meets is explained in simple words inside the game (challenge E1-E4).

## The cycle of a version
1. The version's goal and its pieces are GitHub issues; claim one by assigning it to your person before starting.
2. Build on the version branch in small working steps (below).
3. The author verifies its own work: the checks pass and the game runs; screenshots of what changed.
4. Someone who did not build it reviews it (another agent or vendor); findings are verified before they are fixed, and
   fixed at their cause.
5. When the version is complete and verified, the lead opens its one pull request with `tools/pr-when-green.sh`.
6. A team member merges. The release workflow tags the version and publishes it; then someone checks the live game.

## Versions
- `v0.1.0` is the first playable sketch with this base. `v0.2.0` is the second version, with everything the vision
  asks for. The line stays `v0.X.Y` until the team calls the game impeccable; only then `v1.0.0`.
- The work toward the next version lives on one branch named after it (now `v0.2.0`). Each step is one commit that
  leaves the game running, and its message starts with the step number: the patch numbers of the current line,
  `0.1.1`, `0.1.2`, and so on. Before committing, pull and take the next free number. Never a `-1`/`-2` suffix.
- Version numbers are never typed into the game, titles or documents by hand: the release workflow tags the merge
  with the branch's version.
- Agents commit straight to the version branch (no side branches, so nothing needs merging except by a person):
  `git pull --rebase` before you start and before you push; push after every step.

## Pull requests
- One pull request per functional version, from its branch into `main`; never one per fix.
- It opens only when every CI check on its last commit is green: `tools/pr-when-green.sh "<title>" <body-file>`.
  A red check is fixed on the branch; a pull request never sits red.
- The title says what the version delivers, in English, without the version number (the branch carries it); the body
  follows `.github/pull_request_template.md`.
- Commits and pull requests carry no AI co-author lines or generated-by signatures (`.claude/settings.json` turns them
  off for Claude Code; set the same in other tools). AI use is disclosed in the README instead.

## Working beside other agents
- Each person owns parts of the game (listed in `docs/STATE.md`); their agents work there. A change to something both
  sides use (data formats, the mission model, project settings, this file) is agreed with the other person first.
- Never rewrite, reformat or revert someone else's work to suit yours; ask in the issue.
- Several agents on one machine work in separate git worktrees of the same branch.
- Leave the branch better than you found it: the game runs, the checks pass, `docs/STATE.md` says what changed.

## Godot
- Godot 4.7.2, renderer GL Compatibility (it runs in browsers and on integrated GPUs). The web build is the
  single-threaded export (`export_presets.cfg`, preset "Web"), so any static host works.
- `tools/godot.sh` finds the Godot binary (or set `GODOT`); `tools/check.sh` runs what CI runs: import, a short
  headless run of the main scene, the fuzz test, the web export. `tools/shots.sh` plays the scripted walkthrough with
  a window and saves screenshots to `shots/` (headless runs draw nothing).
- GDScript is Godot 4 syntax (`await`, `@onready`, `@export`, typed signals); the project's own pitfalls are in
  `docs/architecture.md`. Tools that let agents drive Godot, Blender and the browser: `kb/tech/godot-agent-tooling.md`.

## What the event requires (sources in `kb/challenge/event-and-judging.md`)
- AI tools are allowed and their use is disclosed: the README names the agents used and cites every source.
- No NASA logos, insignia, flags or mission identifiers in anything generated, and nothing implying NASA endorses us;
  crediting NASA data in text is expected.
- No image, video, voice or likeness of anyone under 18.
- Every outside asset (code, fonts, images, sounds, models, data) is listed with its source and license.
- English for the game, the repository, the pitch deck and the submission.

## Layout
- Godot project at the root: `project.godot`, `scenes/`, `scripts/`, `shaders/`, `fonts/`, `textures/`, `tests/`.
- `docs/`: `STATE.md`, `architecture.md`, `design/`, `agents/`, `changelog/`, `challenge/` (the challenge page
  material), `team/` (the team's notes, schedule and pitch outline).
- `kb/`: the knowledge base. `tools/`: scripts for people and agents. `.github/`: CI, release, pull request template.
