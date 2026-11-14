#!/usr/bin/env bash
# Runs locally what CI runs: import, a short headless run of the main scene, the fuzz test, the web export.
set -euo pipefail
cd "$(dirname "$0")/.."
G=tools/godot.sh
log=$(mktemp)
echo "1/4 import"
# A first import has once exited non-zero after importing everything; one retry tells a real failure from that.
bash "$G" --headless --path . --import >"$log" 2>&1 || bash "$G" --headless --path . --import >"$log" 2>&1 || { cat "$log"; exit 1; }
echo "2/4 main scene, 120 frames headless"
bash "$G" --headless --path . --quit-after 120 >"$log" 2>&1 || { cat "$log"; exit 1; }
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script|Invalid call|Invalid access" "$log"; then
  echo "The main scene logged errors (above)"; exit 1
fi
echo "3/4 fuzz test"
bash "$G" --headless --path . -s res://tests/fuzz.gd >"$log" 2>&1 || { cat "$log"; exit 1; }
grep -q "^ok 600" "$log" || { cat "$log"; echo "The fuzz test did not finish its 600 designs"; exit 1; }
grep "^ok" "$log"
echo "4/4 web export"
mkdir -p build/web
bash "$G" --headless --path . --export-release "Web" build/web/index.html >"$log" 2>&1 || { cat "$log"; exit 1; }
ls -la build/web | awk 'NR>1 {print $5, $9}'
rm -f "$log"
echo "All checks passed"
