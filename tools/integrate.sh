#!/usr/bin/env bash
# Integrates a finished work branch into the version branch, with no pull request:
#   tools/integrate.sh work/<issue>-<name> "<what it adds>" [version-branch]
# Run by a lead agent (or a team member) once the piece is finished, reviewed and green; no need to ask. It never
# touches main: the complete version branch reaches main only through its one pull request, which a team member
# reviews and merges.
# It checks that every CI check on the work branch's last pushed commit passed, puts the branch on the version branch
# as one commit named with the next step number (0.1.N: <what it adds>), keeps the author of the work, pushes, and
# deletes the work branch. Pieces built in parallel get their numbers in the order they are integrated.
set -euo pipefail
work=${1:?work branch}; what=${2:?what it adds}
[[ $work == work/* ]] || { echo "$work is not a work branch (work/<issue>-<name>)"; exit 1; }
if [[ $what =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then echo "Say what it adds without a number; the number is given here"; exit 1; fi
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Commit or stash your own changes first"; exit 1; }
git fetch -q --prune origin
base=${3:-$(git for-each-ref refs/remotes/origin --format='%(refname:lstrip=3)' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)}
[[ $base =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || { echo "No version branch to integrate into"; exit 1; }
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}
git rev-parse -q --verify "origin/$work" >/dev/null || { echo "origin/$work does not exist: push it first"; exit 1; }
sha=$(git rev-parse "origin/$work")

# CI must be green on the work branch's last pushed commit.
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
api="repos/$repo/commits/$sha/check-runs"
total=$(gh api "$api" --jq '.check_runs | length')
notgreen=$(gh api "$api" --jq '[.check_runs[] | select(.status != "completed" or ((.conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral") | not)) | .name] | join(", ")')
if [ "$total" -eq 0 ] || [ -n "$notgreen" ]; then
  echo "CI is not green on ${sha:0:7} of $work: ${notgreen:-no checks yet}. Nothing integrated."; exit 1
fi

# The next step number on the version branch.
last=$(git log "origin/$base" --format=%s | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+:' | head -1 | tr -d ':' || true)
if [ -n "$last" ]; then IFS=. read -r a b c <<<"$last"; next="$a.$b.$((c + 1))"; else next="$major.$((minor - 1)).1"; fi

# Keep the author: one author becomes the commit's author; several people become co-authors (people only, never AI).
mapfile -t authors < <(git log --format='%an <%ae>' "origin/$base..origin/$work" | sort -u)
[ "${#authors[@]}" -gt 0 ] || { echo "$work has nothing that $base does not already have"; exit 1; }
trailers=""
for a in "${authors[@]:1}"; do trailers+=$'\n'"Co-authored-by: $a"; done

start=$(git rev-parse --abbrev-ref HEAD)
if git rev-parse -q --verify "$base" >/dev/null; then git switch -q "$base"; else git switch -q -c "$base" "origin/$base"; fi
git merge -q --ff-only "origin/$base"
if ! git merge --squash -q "origin/$work"; then
  git reset -q --merge
  echo "Conflicts with $base: bring it into the work branch (git pull --rebase origin $base), resolve there, push, and run this again."
  git switch -q "$start" 2>/dev/null || true
  exit 1
fi
git commit -q --author="${authors[0]}" -m "$next: $what" -m "Integrated from $work.${trailers}"
git push -q origin "$base"
git push -q origin --delete "$work"
git branch -q -D "$work" 2>/dev/null || true
echo "Integrated $work into $base as $next"
[ "$start" = "$work" ] || git switch -q "$start" 2>/dev/null || true
