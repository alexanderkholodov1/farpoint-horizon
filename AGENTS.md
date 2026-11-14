# Agent guide: Farpoint HORIZON

The one rulebook for every agent in this repository, whoever runs it (Claude Code, Codex, Cursor, Gemini or any
other) and whichever team member it works for. `CLAUDE.md` only imports this file.

The game: **Farpoint HORIZON** (always written this way), a 3D space-mission game in Godot 4.7 for the 2026 NASA Space
Apps Challenge, challenge "Space Mission Design Game", by team SK Horizon (Quito, Ecuador). Alone or with up to three friends, players build a craft, plan its
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
- **Only a person merges into `main`**, either team member, never an agent. Lead agents integrate finished work
  branches into the version branch themselves, with no need to ask, once the checks are green; the complete version
  branch goes to `main` only through one pull request that a team member reviews and merges.
- Agents talk with their person in that person's language. The repository and the game are in English by default; the
  game also offers Spanish, and the project description and deliverables for the platform exist in Spanish too
  (the local venue requires both; the live pitch in Sangolquí is in Spanish).

## How we work
- **Fun and satisfaction first.** The player should feel the pride of watching their own craft lift off, deploy,
  arrive and land. Missing something is never a failure screen; achieving more is rewarded. Kerbal Space Program is
  the main inspiration (the builder, route and orbit planning, the whole journey, freedom to invent, humor, the
  spectacle of launch and landing); its difficulty and its fail-and-retry loop are not.
- **Nothing that looks AI-made.** `docs/design/criteria.md` holds the team's design criteria; they apply to models,
  UI, motion, sound and copy.
- **Real data at the core, and everything cited.** The judges score how much NASA data is part of the game, and they
  will read our sources. Every number, formula, fact, dataset, image, model or sound that comes from outside carries
  its source where it is used (a data field, a code comment, a document line) and is listed once in
  `docs/sources.md` with an ID, in a form fit to show the judges. Our own simplifications say so and cite what they
  simplify. The README and the game's credits are built from that list. Research notes in `kb/` keep their URLs.
- **Data apart from code.** Missions, parts, launchers, orbits, events and texts live in data (today
  `scripts/game_data.gd`), so content and balance change without touching logic.
- **Measure before you claim.** Run it, read the log, look at the screenshot; cite the file and line or the command.
  A guess is labeled as a guess.
- **Proven by playing.** A feature is done when someone played it as a player would and looked at the screen;
  say what you checked.
- **Plain explanations.** Every concept a player meets is explained in simple words inside the game (challenge E1-E4).

## The cycle of a version
1. The version branch (now `v0.2.0`) collects finished pieces. Its pull request into `main` opens only when the
   version is complete.
2. Every piece of work is a GitHub issue. Claim it by assigning it to your person before starting.
3. Build it on a work branch of your own, made from the version branch and named after the issue:
   `git fetch origin && git switch -c work/12-rockets origin/v0.2.0`. Commit small working steps in English, with no
   version numbers, and push often (CI runs on every push). Bring in the version branch often:
   `git pull --rebase origin v0.2.0`.
4. When the piece works (CI green, played as a player, screenshots in the issue, every outside value cited), open an
   integration pull request from the work branch into the version branch, titled with what it adds, with
   `tools/pr-when-green.sh "<what it adds>" <body-file>` (it waits for green CI first). Someone who did
   not build it reviews it; findings are verified before they are fixed, and fixed at their cause.
5. A lead agent (or a team member) integrates it once its checks are green, with no need to ask, using
   `tools/integrate.sh <pull request number>`: it checks that every check is green, puts the piece on the version
   branch as one commit named with the next step number (`0.1.5: <title>`) and deletes the work branch.
6. When the version is complete and verified, its pull request into `main` opens with `tools/pr-when-green.sh`. Only a
   team member merges it, never an agent. The release workflow tags it and publishes it; then someone checks the live
   game.

## Versions
- `v0.1.0` is the first playable sketch with this base. `v0.2.0` is the second version, with everything the vision
  asks for. The line stays `v0.X.Y` until the team calls the game impeccable; only then `v1.0.0`.
- Only the version branch carries version numbers. Each integrated piece is one commit whose message starts with its
  step number, the patch numbers of the current line (`0.1.5`, `0.1.6`, ...), never a `-1`/`-2` suffix. The number
  is given at integration, so pieces built in parallel never collide on one. Work branches carry no numbers.
- The version itself comes from the branch name, never from memory: `tools/pr-when-green.sh` puts it at the head of
  the pull request title into `main`, and the release workflow tags the merge with it.

## Pull requests
- **Integration pull requests**: a work branch (`work/*`) into the version branch, one per finished piece, titled
  with what it adds and no number.
- **The version pull request**: the version branch into `main`, one per functional version, never one per fix. It
  opens only when every CI check is green (`tools/pr-when-green.sh "<what it delivers>" <body-file>`); its title leads
  with the version (`v0.2.0: <what a player can now do>`). Only a team member merges it.
- CI refuses a pull request into `main` that does not come from a version branch with its version leading the title,
  and a pull request into a version branch that does not come from a work branch. A red check is fixed on its branch;
  a pull request never sits red.
- Bodies follow `.github/pull_request_template.md`. Commits and pull requests carry no AI co-author lines or
  generated-by signatures (`.claude/settings.json` turns them off for Claude Code; set the same in other tools). AI
  use is disclosed in the README instead.

## Working beside other agents
- Nobody owns a part: both team members work side by side. Each piece is claimed through its issue and built on its
  own work branch, so two agents never write the same branch. If your piece must change files that another open
  issue is changing, say so in both issues and agree who goes first. A change to something everyone uses (data
  formats, the mission model, `GameState`, project settings, this file) is agreed by both team members.
- Never rewrite, reformat or revert someone else's work, and never push to someone else's work branch; ask in the
  issue.
- Before integrating anything, list the open pull requests of the branches involved (`gh pr list --base v0.2.0`) and
  integrate through the pull request itself, so its author sees what happened.
- Several agents on one machine work in separate git worktrees, one per work branch.
- Leave every branch better than you found it: the game runs, the checks pass, `docs/STATE.md` says what changed.

## Godot
- Godot 4.7.2, renderer GL Compatibility (it runs in browsers and on integrated GPUs). The web build is the
  single-threaded export (`export_presets.cfg`, preset "Web"), so any static host works.
- `tools/godot.sh` finds the Godot binary (or set `GODOT`); `tools/check.sh` runs what CI runs: import, a short
  headless run of the main scene, the fuzz test, the web export. `tools/shots.sh` plays the scripted walkthrough with
  a window and saves screenshots to `shots/` (headless runs draw nothing).
- GDScript is Godot 4 syntax (`await`, `@onready`, `@export`, typed signals); the project's own pitfalls are in
  `docs/architecture.md`. Tools that let agents drive Godot, Blender and the browser: `kb/tech/godot-agent-tooling.md`.

## What the event requires (sources: `kb/challenge/event-and-judging.md`, global; `kb/challenge/local-event.md`, the venue)
- AI tools are allowed and their use is disclosed: the README names the agents used and cites every source.
- No NASA logos, insignia, flags or mission identifiers in anything generated, and nothing implying NASA endorses us;
  crediting NASA data in text is expected.
- No image, video, voice or likeness of anyone under 18.
- No AI-generated images: models come from our scripts, textures and imagery from cited sources, so no watermark is
  needed (the venue deducts a point for an AI image without one).
- Every outside asset (code, fonts, images, sounds, models, data) is listed with its source and license.
- English by default; Spanish versions of the description and deliverables for the venue. At most 7 slides; a demo
  video of at most 30 s; every link opens in a private window.

## Layout
- Godot project at the root: `project.godot`, `scenes/`, `scripts/`, `shaders/`, `fonts/`, `textures/`, `tests/`.
- `docs/`: `STATE.md`, `architecture.md`, `design/`, `agents/`, `changelog/`, `challenge/` (the challenge page
  material), `team/` (the team's notes, schedule and pitch outline).
- `kb/`: the knowledge base. `tools/`: scripts for people and agents. `.github/`: CI, release, pull request template.
