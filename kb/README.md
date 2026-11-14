# Knowledge base

What every agent and teammate needs to build the game, in one place. This repository is public: nothing private
goes here (no personal data, accounts, credentials or internal notes of any team member's tools).

Read `AGENTS.md` first. Then read only what your task needs; the table says what each file is for.

| Path | What it holds | Read it when |
|---|---|---|
| `challenge/requirements.md` | The challenge's expectations as traceable IDs (C1-C9 core, G/M/S/O/R/T/E considerations, F1-F13 optional features), plus the local event schedule | Always, before designing or claiming anything |
| `challenge/event-and-judging.md` | Official dates, what the submission must contain, the five judging criteria, the rules (AI use, NASA branding, minors, licensing, prior work) | Before the pitch, the submission, any asset or any use of AI-generated media |
| `research/prior-art.md` | Existing games and tools (Webb telescope game, KSP, JPL Team X, board games...), with patterns to take and pitfalls to avoid | Before game design |
| `domain/mission-lifecycle.md` | How a real mission goes from need to operations (NASA phases, segments, Concept Maturity Levels, CubeSat process) | Before designing the game's stages |
| `domain/tradeoffs.md` | What each design decision affects, with simple formulas and rules of thumb | Before designing or coding any rule of the simulation |
| `data/reference.json`, `data/README.md` | Real-world reference values with a source for each (orbits, launch vehicles, buses, components, instruments, ground networks) | Before writing game data or balance |
| `tech/platform-options.md` | Godot, web and hybrid options with current facts, and what is installed | Before choosing or setting up the engine |
| `tech/godot-agent-tooling.md` | Tools that let agents operate Godot (MCP servers, headless runs and screenshots, tests, Blender for 3D models, asset sources and licenses), with a recommended toolkit and its risks | Before setting up an agent to work on the game |
| `tech/collaboration.md` | How two people with several AI agents share this repository without collisions | Before your first commit |
| `decisions.md` | Decisions taken (with who decided and when) and decisions still open | Always; a decision here overrides anything older |

## Sources
The raw material gathered from the challenge page lives in `docs/` (challenge text, resources, three NASA PDFs, the
local schedule). Every fact in this folder cites its source; anything inferred is labeled "(inference)".

## Keeping it current
- A new decision goes to `decisions.md` with its date and who took it.
- A fact that turns out wrong is corrected where it lives, with the correct source.
- Game design documents will live in `design/` once the design round starts.
