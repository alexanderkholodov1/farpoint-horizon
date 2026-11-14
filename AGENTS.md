# Agent guide: orbit-horizon

This repository holds a game for the 2026 NASA Space Apps Challenge, challenge "Space Mission Design Game": players,
alone or in teams of up to four, design, manage and simulate a complete space mission and see the trade-offs of
every engineering decision. Two people build it, each with their own AI agents from different vendors. This file is
for every agent, whatever tool runs it. It is a draft until both team members confirm it.

## Read first
1. `kb/README.md`: the knowledge base index.
2. `kb/challenge/requirements.md`: what the challenge expects, as IDs to cite.
3. `kb/decisions.md`: what is decided and what is still open. Never decide an open item yourself; propose it with
   evidence to the person you work for.
Then read only what your task needs.

## Rules of the event (binding for everyone; sources in `kb/challenge/event-and-judging.md`)
- **The idea is the humans'.** The official rules say AI tools "should not be used to come up with your idea of how
  to solve the challenge". Agents research, structure, ask, propose implementations and build; the core game concept
  and its main mechanics are chosen by the team members.
- **AI use is disclosed.** Never remove a disclosure. AI-generated images and videos carry a visible watermark;
  AI-generated code, audio and data are acknowledged in text and metadata (the exact form is decision D7).
- **No NASA logos, insignia, flags or mission identifiers** in anything generated, and nothing implying NASA's
  endorsement. A plain text credit of the NASA data and resources used is fine.
- **No image, video, voice or likeness of anyone under 18.**
- **Every outside asset is listed**: code, libraries, fonts, images, sounds, models, data, each with its source and
  license. Nothing copyrighted without permission.
- **English** for the repository, the pitch deck and the submission.

## How to work here
- **Real data at the core.** NASA data must be a core part of the solution (judging criterion Relevance). Game values
  come from `kb/data/reference.json` or another cited source. Never invent a number; when the game simplifies a
  value, say so where it is defined.
- **Stay in your part.** Work only in the files your person assigned you (the ownership split is decision D5). Never
  rewrite or reformat another person's work; if you need a change there, ask.
- **Data apart from code.** Game content (missions, components, launch vehicles, orbits, events, text) lives in data
  files, so balance and content change without touching code.
- **Small steps, shared often.** Pull before you start, commit each working step with a clear English message, push
  right after. Do not leave the main branch broken.
- **Prove it runs.** Run the game and use the feature as a player before calling it done; say what you checked.
- **Plain explanations.** Every concept shown to players is explained in simple words (challenge E1 to E4).

## Layout
- `docs/`: raw material gathered from the challenge page (do not edit).
- `kb/`: the knowledge base (see `kb/README.md`).
- The game's code layout is set once the engine is chosen (decision D3).
