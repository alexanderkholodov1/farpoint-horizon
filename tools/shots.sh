#!/usr/bin/env bash
# Plays the scripted walkthrough (tests/autoshot.tscn) in a window and saves screenshots to shots/.
# Headless runs draw nothing, so this needs a desktop session. Look at every screenshot before calling a change done.
set -euo pipefail
cd "$(dirname "$0")/.."
bash tools/godot.sh --path . --resolution 1600x900 res://tests/autoshot.tscn
ls shots
