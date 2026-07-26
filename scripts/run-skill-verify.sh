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

# A directive is fail-open when it cannot exit non-zero on a broken repo.
# Two families, both checked syntactically because a pipeline's exit status
# is the status of its LAST command:
#   1. explicit swallow  — `|| echo ...`, `|| true`, `|| :`, `; true`, `; exit 0`
#   2. non-asserting tail — pipeline ends in a filter that always exits 0
#      (head/wc/cat/tee/sort/tr/sed/awk/echo/true/:). `grep x | wc -l` is the
#      canonical offender: wc always succeeds, so the grep result is discarded.
# Use an assertion instead, e.g. [ "$(... | wc -l)" -gt 0 ].
FAIL_OPEN_TAIL_CMDS='head|wc|cat|tee|sort|tr|sed|awk|echo|true|:'

is_fail_open_directive() {
  local cmd="$1"

  # Family 1: explicit exit-status swallowing.
  if echo "$cmd" | grep -qE '\|\|[[:space:]]*(echo|true|:)|;[[:space:]]*(true|:|exit[[:space:]]+0)[[:space:]]*$'; then
    return 0
  fi

  # Family 2: pipeline whose last stage never fails.
  # Strip $(...) first — a pipe inside a command substitution feeds an
  # assertion, e.g. [ "$(ls x | wc -l)" -gt 0 ], and is NOT fail-open.
  local stripped="$cmd" prev=""
  while [ "$stripped" != "$prev" ]; do
    prev="$stripped"
    stripped=$(printf '%s' "$stripped" | sed 's/\$([^()]*)/SUBST/g')
  done

  # Only inspect the segment after the final `|` that is not part of `||`.
  local tail_seg
  tail_seg=$(printf '%s' "$stripped" | sed 's/||/\
/g' | tail -1)
  case "$tail_seg" in
    *\|*)
      tail_seg=${tail_seg##*|}
      tail_seg=$(printf '%s' "$tail_seg" | sed 's/^[[:space:]]*//')
      echo "$tail_seg" | grep -qE "^($FAIL_OPEN_TAIL_CMDS)([[:space:]]|$)" && return 0
      ;;
  esac

  return 1
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
    echo "FAIL: $label — fail-open directive (cannot exit non-zero; swallowed status or non-asserting pipeline tail): $cmd"
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

  # bash 3.2 (macOS default shell) has no `mapfile`. Read the lines portably —
  # regression guard for the class of BUG-2026-07-02T103911 (`declare -A`).
  local verify_lines=()
  local _line
  while IFS= read -r _line; do
    [ -n "$_line" ] && verify_lines+=("$_line")
  done < <(grep -E '^(> )?→ verify:' "$skill_md" 2>/dev/null || true)

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
  # Every known fail-open idiom must be rejected. Add a row here whenever a new
  # evasion is found — this is the anti-vacuity proof for the detector itself.
  local bad_patterns='test -f /nope && echo OK || echo FAIL
test -f /nope || true
test -f /nope || :
test -f /nope; true
test -f /nope; exit 0
grep -rn "x" . | wc -l
ls specs/*.md 2>/dev/null | head -15
git diff --name-only HEAD | head -20
find . -name "*.md" | cat
grep x file | awk "{print}"'
  local bad_line
  while IFS= read -r bad_line; do
    [ -z "$bad_line" ] && continue
    if ! is_fail_open_directive "$bad_line"; then
      echo "FAIL: self-test — detector missed fail-open idiom: $bad_line"
      FAIL=$((FAIL + 1))
      return 1
    fi
  done <<EOF
$bad_patterns
EOF
  echo "PASS: self-test — detector rejects all $(printf '%s\n' "$bad_patterns" | grep -c .) known fail-open idioms"

  # And must NOT reject genuine assertions that merely contain a pipe inside $().
  local good_patterns='[ "$(ls specs/*.yaml 2>/dev/null | wc -l | tr -d " ")" -gt 0 ]
test -d specs && test -f specs/state.yaml
[ "$(find specs -name "*.yaml" | wc -l | tr -d " ")" -ge 1 ]'
  local good_line
  while IFS= read -r good_line; do
    [ -z "$good_line" ] && continue
    if is_fail_open_directive "$good_line"; then
      echo "FAIL: self-test — detector false-positived on a real assertion: $good_line"
      FAIL=$((FAIL + 1))
      return 1
    fi
  done <<EOF
$good_patterns
EOF
  echo "PASS: self-test — detector accepts genuine assertions with \$() pipes"
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

# SKIP ratchet: skills with no (or non-executable) → verify: are invisible to
# this gate. Cap the count so the blind spot can only shrink. Lower the ceiling
# as skills gain real directives; see issue #97.
SKIP_CEILING="${SKILL_VERIFY_SKIP_CEILING:-34}"
if [ -z "$TARGET" ] && [ "$SKIP" -gt "$SKIP_CEILING" ]; then
  echo "FAIL: SKIP count $SKIP exceeds ceiling $SKIP_CEILING — new skills must ship a → verify: directive"
  FAIL=$((FAIL + 1))
fi

[ "$FAIL" -eq 0 ]
