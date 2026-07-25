#!/usr/bin/env bash
# story: e22s01
# Run all SKILL.md → verify: commands and report PASS/FAIL/SKIP.
# Exit 0 only when zero FAILs.
# Usage: bash scripts/run-skill-verify.sh [skill-name]
#   No args: runs all skills + negative-path self-test
#   With arg: runs only the named skill (skips self-test)

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
SKILLS_ROOT="$REPO_ROOT"
[[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"

PASS=0; FAIL=0; SKIP=0
TARGET="${1:-}"

is_fail_open_directive() {
  local cmd="$1"
  echo "$cmd" | grep -qE '\|\|[[:space:]]*echo|\|[[:space:]]*awk'
}

normalize_verify_cmd() {
  local raw="$1"
  raw=$(echo "$raw" | sed 's/^> // ; s/^→ verify: *//')
  raw=$(echo "$raw" | sed 's/^`//; s/`$//')
  echo "$raw"
}

is_executable_verify() {
  local cmd="$1"
  echo "$cmd" | grep -qE '^[a-zA-Z][a-zA-Z0-9_.-]*\b|^\['
}

run_verify_cmd() {
  local skill="$1"
  local cmd="$2"
  local label="${3:-$skill}"

  if is_fail_open_directive "$cmd"; then
    echo "FAIL: $label — fail-open pattern (|| echo or | awk): $cmd"
    FAIL=$((FAIL + 1))
    return 1
  fi

  local output
  if output=$(run_with_timeout "$cmd"); then
    echo "PASS: $label"
    PASS=$((PASS + 1))
    return 0
  else
    echo "FAIL: $label — $cmd"
    echo "      output: $(echo "$output" | head -1)"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

run_skill() {
  local skill_md="$1"
  local skill
  skill=$(dirname "$skill_md")

  mapfile -t verify_lines < <(grep -E '^(> )?→ verify:' "$skill_md" 2>/dev/null || true)

  if [ "${#verify_lines[@]}" -eq 0 ]; then
    echo "SKIP: $skill"
    SKIP=$((SKIP + 1))
    return
  fi

  local idx=0 ran=0
  for line in "${verify_lines[@]}"; do
    idx=$((idx + 1))
    local cmd
    cmd=$(normalize_verify_cmd "$line")
    [ -z "$cmd" ] && continue
    if ! is_executable_verify "$cmd"; then
      if [ "$idx" -eq "${#verify_lines[@]}" ] && [ "$ran" -eq 0 ]; then
        echo "SKIP: $skill (non-executable verify)"
        SKIP=$((SKIP + 1))
      fi
      continue
    fi
    ran=1
    local label="$skill"
    [ "${#verify_lines[@]}" -gt 1 ] && label="$skill#$idx"
    run_verify_cmd "$skill" "$cmd" "$label" || true
  done
  if [ "$ran" -eq 0 ] && [ "${#verify_lines[@]}" -gt 0 ]; then
    echo "SKIP: $skill (non-executable verify)"
    SKIP=$((SKIP + 1))
  fi
}

run_negative_fixture_self_test() {
  local fixture_md="$REPO_ROOT/specs/verifications/fixtures/skill-verify-fail-open/SKILL.md"
  echo ""
  echo "=== Skill-verify negative-path self-test ==="
  if [[ ! -f "$fixture_md" ]]; then
    echo "FAIL: negative fixture missing at $fixture_md"
    FAIL=$((FAIL + 1))
    return 1
  fi
  local fail_open_cmd='test -f /nonexistent/path/for/skill-verify-self-test && echo OK || echo FAIL'
  if ! is_fail_open_directive "$fail_open_cmd"; then
    echo "FAIL: self-test — fail-open detector did not match canonical || echo pattern"
    FAIL=$((FAIL + 1))
    return 1
  fi
  echo "PASS: self-test — fail-open detector rejects || echo pattern"
  local real_fail_cmd='test -f /nonexistent/path/for/skill-verify-self-test'
  local output
  if output=$(run_with_timeout "$real_fail_cmd"); then
    echo "FAIL: self-test — real failing check exited 0 (fail-open risk)"
    FAIL=$((FAIL + 1))
    return 1
  fi
  echo "PASS: self-test — real failing check exits non-zero"
  local saved_fail=$FAIL saved_pass=$PASS
  run_skill "$fixture_md"
  if [ "$FAIL" -le "$saved_fail" ]; then
    echo "FAIL: self-test — fixture skill did not register a failure"
    FAIL=$((FAIL + 1))
    return 1
  fi
  FAIL=$((FAIL - 1))
  PASS=$saved_pass
  echo "PASS: self-test — fixture skill correctly fails verification"
}

if [ -n "$TARGET" ]; then
  if [ -f "$TARGET/SKILL.md" ]; then
    run_skill "$TARGET/SKILL.md"
  elif [ -f "$SKILLS_ROOT/$TARGET/SKILL.md" ]; then
    run_skill "$SKILLS_ROOT/$TARGET/SKILL.md"
  else
    echo "ERROR: $TARGET/SKILL.md not found"
    exit 1
  fi
else
  for skill_md in "$SKILLS_ROOT"/*/SKILL.md; do
    run_skill "$skill_md"
  done
  run_negative_fixture_self_test
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL, $SKIP SKIP"
[ "$FAIL" -eq 0 ]
