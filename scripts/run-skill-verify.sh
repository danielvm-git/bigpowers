#!/usr/bin/env bash
# Run all SKILL.md → verify: commands and report PASS/FAIL/SKIP.
# Exit 0 only when zero FAILs.
# Usage: bash scripts/run-skill-verify.sh [skill-name]
#   No args: runs all skills
#   With arg: runs only the named skill

set -uo pipefail

# Portable timeout: macOS lacks GNU timeout; use perl alarm as fallback.
if command -v timeout >/dev/null 2>&1; then
  run_with_timeout() { timeout 10 bash -c "$1" 2>&1; }
elif command -v perl >/dev/null 2>&1; then
  run_with_timeout() { perl -e 'alarm 10; exec @ARGV' bash -c "$1" 2>&1; }
else
  run_with_timeout() { bash -c "$1" 2>&1; }
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
# SKILLS_ROOT: use skills/ when it exists, fall back to repo root
SKILLS_ROOT="$REPO_ROOT"
[[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"

PASS=0; FAIL=0; SKIP=0
TARGET="${1:-}"

run_skill() {
  local skill_md="$1"
  local skill
  skill=$(dirname "$skill_md")

  # Only match → verify: at line start (after optional blockquote "> " or numbered-list prefix)
  # This prevents false matches against description prose or template examples.
  local cmd
  cmd=$(grep -E '^(> )?→ verify:' "$skill_md" 2>/dev/null | head -1 | sed 's/^> // ; s/^→ verify: *//')

  if [ -z "$cmd" ]; then
    echo "SKIP: $skill"
    SKIP=$((SKIP + 1))
    return
  fi

  # Strip surrounding backticks — SKILL.md verify: commands use markdown code-span wrapping
  # but bash -c would interpret the backticks as command substitution, causing false FAILs.
  cmd=$(echo "$cmd" | sed 's/^`//; s/`$//')

  # Skip verify directives that are prose, not executable shell commands.
  # Heuristic: if the command doesn't start with a known command word or path,
  # it's likely descriptive text, not a runnable verification.
  if ! echo "$cmd" | grep -qE '^[a-zA-Z][a-zA-Z0-9_.-]*\b|^\['; then
    echo "SKIP: $skill (non-executable verify)"
    SKIP=$((SKIP + 1))
    return
  fi

  local output
  if output=$(run_with_timeout "$cmd"); then
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
  for skill_md in "$SKILLS_ROOT"/*/SKILL.md; do
    run_skill "$skill_md"
  done
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL, $SKIP SKIP"

[ "$FAIL" -eq 0 ]
