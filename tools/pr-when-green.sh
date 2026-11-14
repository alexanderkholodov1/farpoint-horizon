#!/usr/bin/env bash
# Opens the pull request of the current version branch into main, only when every CI check on its last pushed commit
# passed. Usage: tools/pr-when-green.sh "<what it delivers>" <body-file>
# The title always leads with the branch's version (`v0.2.0: <what it delivers>`): added when missing, refused when a
# different version is typed.
# Exit 0: opened (or already open). Exit 1: a check failed or the branch is not ready. Exit 2: checks still running
# after 30 minutes.
set -euo pipefail
title=${1:?title}; body=${2:?body file}
[ -f "$body" ] || { echo "No body file: $body"; exit 1; }
branch=$(git rev-parse --abbrev-ref HEAD)
[[ $branch =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Run it on a version branch (vX.Y.Z); this is $branch"; exit 1; }
if [[ $title =~ ^v[0-9]+\.[0-9]+\.[0-9]+:\  ]]; then
  [[ $title == "$branch: "* ]] || { echo "The title claims ${title%%:*} but the branch is $branch"; exit 1; }
else
  title="$branch: $title"
fi
git fetch -q origin "$branch"
[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$branch")" ] || { echo "Push first: origin/$branch is not your HEAD"; exit 1; }
if gh pr view "$branch" --json url -q .url 2>/dev/null; then echo "Already open"; exit 0; fi
sha=$(git rev-parse HEAD)
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
api="repos/$repo/commits/$sha/check-runs"
for _ in $(seq 1 90); do
  total=$(gh api "$api" --jq '.check_runs | length')
  pending=$(gh api "$api" --jq '[.check_runs[] | select(.status != "completed")] | length')
  if [ "$total" -gt 0 ] && [ "$pending" -eq 0 ]; then
    failed=$(gh api "$api" --jq '[.check_runs[] | select((.conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral") | not) | .name] | join(", ")')
    if [ -n "$failed" ]; then echo "Checks failed: $failed. Fix them on the branch; no pull request opened."; exit 1; fi
    gh pr create --base main --head "$branch" --title "$title" --body-file "$body"
    exit 0
  fi
  echo "Waiting for checks on ${sha:0:7}: $pending of $total still running"
  sleep 20
done
echo "Checks still running after 30 minutes"; exit 2
