# What works today (checked 2026-11-14)

- The game is playable from start to finish: menu, team, objective, 8-step design, review, launch, month-by-month operation, report, ranking.
- The teammate reports that it ran without errors on Godot 4.5.1 and 4.7.1 (Linux, Compatibility renderer) using `tests/autoshot.tscn` and `tests/fuzz.gd`. Not re-run by us on Linux.
- Five scenarios, three difficulties, six platforms, 15 instruments, five orbits, four launchers, four team roles. Details in `README.md` and `docs/architecture.md`.

## Verified on 2026-11-14 (lead's laptop)

Godot 4.7.2 Steam, Windows, Compatibility renderer: the autoshot walkthrough ran end to end and produced all 16
screenshots; the only messages were GPU texture-leak warnings at exit. `tools/check.sh` passed: import, the main scene
for 120 frames headless with no script errors, the fuzz test (600 random designs, all simulated), and the web export
(`index.pck` 1.8 MB, `index.wasm` 37.7 MB raw, about 9.7 MB compressed).
