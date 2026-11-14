#!/usr/bin/env bash
# Opens a pull request only when every CI check on the branch's last pushed commit passed.
#   On a version branch (vX.Y.Z): the version pull request into main. Its title always leads with the branch's version
#   (`v0.2.0: <what it delivers>`): added when missing, refused when a different version is typed.
#   On a work branch (work/<issue>-<name>): the integration pull request into the newest version branch (or the one
#   given as third argument), titled with what the piece adds and no number.
# Usage: tools/pr-when-green.sh "<what it delivers>" <body-file> [version-branch]
# Exit 0: opened (or already open). Exit 1: a check failed or the branch is not ready. Exit 2: checks still running
# after 30 minutes.
set -euo pipefail
title=${1:?title}; body=${2:?body file}
[ -f "$body" ] || { echo "No body file: $body"; exit 1; }
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ $branch =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  base=main
  if [[ $title =~ ^v[0-9]+\.[0-9]+\.[0-9]+:\  ]]; then
    [[ $title == "$branch: "* ]] || { echo "The title claims ${title%%:*} but the branch is $branch"; exit 1; }
  else
    title="$branch: $title"
  fi
elif [[ $branch == work/* ]]; then
  git fetch -q origin
  base=${3:-$(git for-each-ref refs/remotes/origin --format='%(refname:lstrip=3)' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)}
  [[ $base =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "No version branch to integrate into"; exit 1; }
  if [[ $title =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "An integration title carries no number; it is given at integration"; exit 1
  fi
else
  echo "Run it on a version branch (vX.Y.Z) or a work branch (work/<issue>-<name>); this is $branch"; exit 1
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
    gh pr create --base "$base" --head "$branch" --title "$title" --body-file "$body"
    exit 0
  fi
  echo "Waiting for checks on ${sha:0:7}: $pending of $total still running"
  sleep 20
done
echo "Checks still running after 30 minutes"; exit 2
