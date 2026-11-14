#!/usr/bin/env bash
# Runs locally what CI runs: import, a short headless run of the main scene, the fuzz test, the web export.
set -euo pipefail
cd "$(dirname "$0")/.."
G=tools/godot.sh
log=$(mktemp)
echo "1/5 import"
# A first import has once exited non-zero after importing everything; one retry tells a real failure from that.
bash "$G" --headless --path . --import >"$log" 2>&1 || bash "$G" --headless --path . --import >"$log" 2>&1 || { cat "$log"; exit 1; }
echo "2/5 main scene, 120 frames headless"
bash "$G" --headless --path . --quit-after 120 >"$log" 2>&1 || { cat "$log"; exit 1; }
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script|Invalid call|Invalid access" "$log"; then
  echo "The main scene logged errors (above)"; exit 1
fi
echo "3/5 fuzz test"
bash "$G" --headless --path . -s res://tests/fuzz.gd >"$log" 2>&1 || { cat "$log"; exit 1; }
grep -q "^ok 600" "$log" || { cat "$log"; echo "The fuzz test did not finish its 600 designs"; exit 1; }
grep "^ok" "$log"
echo "4/5 translations, flight, room and crew"
# Each test prints its own verdict line; the check fails unless that line appears.
for t in "i18n|0 texts without a Spanish version" "flight|flight test: 0 failure" "room|^ok room" "crew|^ok crew"; do
  name=${t%%|*}; want=${t#*|}
  bash "$G" --headless --path . -s "res://tests/$name.gd" >"$log" 2>&1 || true
  grep -qE "$want" "$log" || { cat "$log"; echo "tests/$name.gd did not pass"; exit 1; }
  echo "ok $name"
done
echo "5/5 web export"
mkdir -p build/web
bash "$G" --headless --path . --export-release "Web" build/web/index.html >"$log" 2>&1 || { cat "$log"; exit 1; }
ls -la build/web | awk 'NR>1 {print $5, $9}'
rm -f "$log"
echo "All checks passed"
