#!/usr/bin/env bash
# story: e83s01
# test-manifest-skill-count-once.sh — the generated host manifests must state the
# skill count exactly once.
#
# Regression guard for the sync-post.sh double-prefix: package.json's description
# is stamped with the count ("80 agent skills …") by stamp-skill-counts.sh, and
# sync-post.sh then prefixed the count again, producing
# "80 skills — 80 agent skills …" in .pi/package.json and gemini-extension.json.
# Because the committed artifacts predate the stamp, that made `sync-skills.sh`
# unable to reproduce what the branch commits, so CI's
# `git diff --exit-code .pi .gemini/extensions/bigpowers` went red on every run.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

n=$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
[ "$n" -gt 0 ] || { echo "FAIL: no skills found — cannot compute count"; exit 1; }

fail=0

check_once() {
  local file="$1" desc occurrences
  [ -f "$file" ] || { echo "FAIL: $file missing"; fail=1; return; }
  desc=$(jq -r '.description' "$file")
  # Count the bare number as a whole token: "80 skills — 80 agent skills" has two.
  occurrences=$(grep -oE "(^|[^0-9])${n}([^0-9]|$)" <<<"$desc" | wc -l | tr -d ' ')

  if [ "$occurrences" -gt 1 ]; then
    echo "FAIL: $file states the count ($n) more than once:"
    echo "  \"$desc\""
    fail=1
  elif [ "$occurrences" -eq 0 ]; then
    echo "FAIL: $file does not state the live skill count ($n):"
    echo "  \"$desc\""
    fail=1
  fi
}

check_once .pi/package.json
check_once .gemini/extensions/bigpowers/gemini-extension.json

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Regenerate with scripts/sync-skills.sh after fixing scripts/lib/sync-post.sh."
  exit 1
fi

echo "PASS: manifest descriptions state the skill count ($n) exactly once"
