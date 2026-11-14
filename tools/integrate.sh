#!/usr/bin/env bash
# Integrates a finished piece into the version branch: tools/integrate.sh <pull request number>
# Run by a team member or by a lead agent, once the piece is finished and green. It never touches main: the version
# branch reaches main only through one pull request that a team member reviews and merges.
# It checks that the pull request goes from a work branch (work/*) into a version branch (vX.Y.Z) and that every check
# passed, then puts the piece on the version branch as one commit named with the next step number (0.1.N: <title>) and
# deletes the work branch. Pieces built in parallel get their numbers in the order they are integrated.
set -euo pipefail
pr=${1:?pull request number}
base=$(gh pr view "$pr" --json baseRefName -q .baseRefName)
head=$(gh pr view "$pr" --json headRefName -q .headRefName)
state=$(gh pr view "$pr" --json state -q .state)
title=$(gh pr view "$pr" --json title -q .title)
[ "$state" = OPEN ] || { echo "Pull request #$pr is $state"; exit 1; }
[[ $base =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || { echo "#$pr goes into $base: this script only integrates into a version branch. Only a person merges into main."; exit 1; }
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}
[[ $head == work/* ]] || { echo "#$pr comes from $head, not a work branch (work/*)"; exit 1; }
pending=$(gh pr view "$pr" --json statusCheckRollup --jq '[.statusCheckRollup[] | select((.conclusion // .state) as $c | ($c != "SUCCESS" and $c != "SKIPPED" and $c != "NEUTRAL"))] | length')
total=$(gh pr view "$pr" --json statusCheckRollup --jq '.statusCheckRollup | length')
if [ "$total" -eq 0 ] || [ "$pending" -ne 0 ]; then
  gh pr view "$pr" --json statusCheckRollup --jq '.statusCheckRollup[] | "\(.name): \(.conclusion // .state // .status)"'
  echo "Not every check is green on #$pr; nothing integrated."; exit 1
fi
git fetch -q origin "$base"
last=$(git log "origin/$base" --format=%s | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+:' | head -1 | tr -d ':' || true)
if [ -n "$last" ]; then
  IFS=. read -r a b c <<<"$last"; next="$a.$b.$((c + 1))"
else
  next="$major.$((minor - 1)).1"
fi
gh pr comment "$pr" --body "Integrated into \`$base\` as \`$next\` with \`tools/integrate.sh\`."
gh pr merge "$pr" --squash --subject "$next: $title" --body "Integrated from \`$head\` (#$pr)." --delete-branch
echo "Integrated #$pr into $base as $next"
