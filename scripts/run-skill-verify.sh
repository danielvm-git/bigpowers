#!/usr/bin/env bash
# Run all SKILL.md → verify: commands and report PASS/FAIL/SKIP.
# Exit 0 only when zero FAILs.
# Usage: bash scripts/run-skill-verify.sh [skill-name]
#   No args: runs all skills
#   With arg: runs only the named skill

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0; FAIL=0; SKIP=0
TARGET="${1:-}"

run_skill() {
  local skill_md="$1"
  local skill
  skill=$(dirname "$skill_md")

  local cmd
  cmd=$(grep '→ verify:' "$skill_md" 2>/dev/null | head -1 | sed 's/.*→ verify: *//')

  if [ -z "$cmd" ]; then
    echo "SKIP: $skill"
    SKIP=$((SKIP + 1))
    return
  fi

  local output
  if output=$(timeout 10 bash -c "$cmd" 2>&1); then
    echo "PASS: $skill"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $skill — $cmd"
    echo "      output: $(echo "$output" | head -1)"
    FAIL=$((FAIL + 1))
  fi
}

if [ -n "$TARGET" ]; then
  if [ -f "$TARGET/SKILL.md" ]; then
    run_skill "$TARGET/SKILL.md"
  else
    echo "ERROR: $TARGET/SKILL.md not found"
    exit 1
  fi
else
  for skill_md in */SKILL.md; do
    run_skill "$skill_md"
  done
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL, $SKIP SKIP"

[ "$FAIL" -eq 0 ]
