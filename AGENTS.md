# Agent guide: orbit-horizon

This repository holds a game for the 2026 NASA Space Apps Challenge, challenge "Space Mission Design Game": players,
alone or in teams of up to four, design, manage and simulate a complete space mission and see the trade-offs of
every engineering decision. Two people build it, each with their own AI agents from different vendors. This file is
for every agent, whatever tool runs it. "orbit-horizon" is the repository's working name; the game's name comes out
of the team's brainstorm.

## Read first
1. `kb/README.md`: the knowledge base index.
2. `kb/challenge/requirements.md`: what the challenge expects, as IDs to cite.
3. `kb/decisions.md`: what the team decided and what is still open. Open items are the team's to decide: bring them
   evidence, alternatives and your recommendation.
Then read what your task needs.

## How we work
- **The team defines the idea; agents help reach it.** Brainstorm with the person you work for, propose concepts,
  mechanics, names and directions freely, argue for them, and align them with that person's preferences. They choose.
- **Kerbal Space Program is the main inspiration.** Take what serves this game (building a craft from parts, the
  satisfaction of a launch, learning by failing and trying again) and make it our own product, with its own names,
  look and mechanics.
- **Real data at the core.** The judges score how much NASA data is part of the solution (criterion Relevance). Game
  values come from `kb/data/reference.json` or another cited source; where the game simplifies a value, the data file
  says so.
- **Each person's part.** Agents work in the part their person owns (decision D5). A change to something both sides
  use (data formats, the shared mission state, project settings) is agreed with the other person first, so nobody's
  work breaks.
- **Data apart from code.** Missions, components, launch vehicles, orbits, events and texts live in data files, so
  content and balance change without touching code.
- **Small steps, shared often.** Pull before starting, commit each working step with a clear English message, push
  right after. The main branch stays playable.
- **Proven by playing.** A feature is done when someone ran the game and used it as a player; say what you checked.
- **Plain explanations.** Every concept a player meets is explained in simple words, inside the game (challenge E1 to
  E4).

## What the event requires (sources in `kb/challenge/event-and-judging.md`)
- **AI tools** are allowed. The rules say they "should not be used to come up with your idea of how to solve the
  challenge" and require disclosure: generated images and videos carry a visible watermark; generated code, audio and
  data are acknowledged in text and metadata (how we do it: decision D7).
- **NASA branding:** generated content may not contain NASA logos, insignia, flags or mission identifiers, and nothing
  may imply NASA's endorsement. Crediting the NASA data and resources we use, in text, is expected.
- **Minors:** the demo and the project contain no image, video, voice or likeness of anyone under 18.
- **References:** every outside asset (code, libraries, fonts, images, sounds, models, data) is listed with its source
  and license; copyrighted material only with permission.
- **English** for the game, the repository, the pitch deck and the submission.

## Layout
- `docs/`: raw material gathered from the challenge page.
- `kb/`: the knowledge base (see `kb/README.md`).
- The game's code layout is set with the engine (decision D3).
