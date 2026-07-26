#!/usr/bin/env bash
# story: BUG-2026-07-26-story-verify-never-executed
# Execute story-level verify: commands declared in specs/epics/*/epic.yaml.
# Tier 2 of the verify arc (GH #106). Tier 1 is run-skill-verify.sh.
#
# Only stories marked `status: done` are gated: a done story asserts its own
# acceptance criteria hold. Backlog/in-progress stories are reported as SKIP.
#
# Usage:
#   bash scripts/run-story-verify.sh              # gate all done stories
#   bash scripts/run-story-verify.sh e80s05       # one story
#   bash scripts/run-story-verify.sh --self-test  # prove the gate can fail

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck source=lib/fail-open-detect.sh
source "$REPO_ROOT/scripts/lib/fail-open-detect.sh"
# shellcheck source=lib/python-env.sh
source "$REPO_ROOT/scripts/lib/python-env.sh"
resolve_python || exit 1

VERIFY_TIMEOUT_SECONDS=120

# Portable timeout: macOS lacks GNU timeout; use perl alarm as fallback.
# stdin is closed for every verify command: gate_all reads its record list on
# fd 0, and a child that reads stdin (any test-*.sh sourcing a read loop) would
# otherwise swallow the remaining records and silently shrink the gate.
if command -v timeout >/dev/null 2>&1; then
  run_with_timeout() { timeout "$VERIFY_TIMEOUT_SECONDS" bash -c "$1" </dev/null 2>&1; }
elif command -v perl >/dev/null 2>&1; then
  run_with_timeout() { perl -e "alarm $VERIFY_TIMEOUT_SECONDS; exec @ARGV" bash -c "$1" </dev/null 2>&1; }
else
  run_with_timeout() { bash -c "$1" </dev/null 2>&1; }
fi

GATED_STATUS="done"
PASS=0; FAIL=0; SKIP=0
TARGET="${1:-}"

extract_records() {
  "$PYTHON" "$REPO_ROOT/scripts/lib/extract-story-verify.py" "$REPO_ROOT"
}

# Report a story whose directive can never fail. Kept separate from execution so
# a fail-open directive is a FAIL even when the command happens to exit 0.
reject_fail_open() {
  local sid="$1" src="$2" cmd="$3"
  echo "FAIL: $sid [$src] — fail-open directive (cannot exit non-zero): $cmd"
  FAIL=$((FAIL + 1))
}

reject_non_executable() {
  local sid="$1" src="$2" cmd="$3"
  echo "FAIL: $sid [$src] — verify is prose, not a runnable command: $cmd"
  FAIL=$((FAIL + 1))
}

run_story_verify() {
  local sid="$1" src="$2" cmd="$3"

  if ! is_executable_verify "$cmd"; then
    reject_non_executable "$sid" "$src" "$cmd"
    return 1
  fi
  if is_fail_open_directive "$cmd"; then
    reject_fail_open "$sid" "$src" "$cmd"
    return 1
  fi

  local output
  if output=$(run_with_timeout "$cmd"); then
    echo "PASS: $sid"
    PASS=$((PASS + 1))
    return 0
  fi
  echo "FAIL: $sid [$src] — $cmd"
  echo "      output: $(echo "$output" | tail -3 | tr '\n' ' ')"
  FAIL=$((FAIL + 1))
  return 1
}

gate_all() {
  local sid src status cmd
  while IFS=$'\t' read -r sid src status cmd; do
    [ -z "${sid:-}" ] && continue
    if [ -n "$TARGET" ] && [ "$sid" != "$TARGET" ]; then
      continue
    fi
    if [ -z "$TARGET" ] && [ "$status" != "$GATED_STATUS" ]; then
      echo "SKIP: $sid (status: $status)"
      SKIP=$((SKIP + 1))
      continue
    fi
    run_story_verify "$sid" "$src" "$cmd" || true
  done < <(extract_records)
}

# Anti-vacuity proof: seed a capsule whose done story must fail, and one that
# must pass, then require the runner to agree. A gate that cannot fail is the
# defect this script exists to close (#96/#106) — so it must prove otherwise.
run_self_test() {
  echo "=== run-story-verify self-test ==="
  local tmp_root
  tmp_root=$(mktemp -d)
  trap 'rm -rf "$tmp_root"' EXIT

  mkdir -p "$tmp_root/specs/epics/e99-selftest"
  cat > "$tmp_root/specs/epics/e99-selftest/epic.yaml" <<'YAML'
id: e99
title: self-test capsule
stories:
  - id: e99s01
    title: passing story
    status: done
    verify: test -d specs
  - id: e99s02
    title: failing story
    status: done
    verify: test -f /nonexistent/path/for/story-verify-self-test
  - id: e99s03
    title: fail-open story
    status: done
    verify: test -f /nonexistent || true
  - id: e99s04
    title: prose story
    status: done
    verify: node bin/bigpowers.js setup (interactive in TTY)
  - id: e99s05
    title: backlog story is not gated
    status: backlog
    verify: test -f /nonexistent/should/not/run
YAML

  local records
  records=$("$PYTHON" "$REPO_ROOT/scripts/lib/extract-story-verify.py" "$tmp_root")

  local checked=0 problems=0
  local sid src status cmd
  while IFS=$'\t' read -r sid src status cmd; do
    [ -z "${sid:-}" ] && continue
    checked=$((checked + 1))
    case "$sid" in
      e99s01)
        if is_fail_open_directive "$cmd" || ! is_executable_verify "$cmd"; then
          echo "FAIL: self-test — genuine assertion rejected: $cmd"; problems=$((problems + 1))
        elif ! run_with_timeout "$cmd" >/dev/null; then
          echo "FAIL: self-test — passing fixture did not pass"; problems=$((problems + 1))
        fi
        ;;
      e99s02)
        if run_with_timeout "$cmd" >/dev/null; then
          echo "FAIL: self-test — failing fixture exited 0 (gate cannot fail)"; problems=$((problems + 1))
        fi
        ;;
      e99s03)
        if ! is_fail_open_directive "$cmd"; then
          echo "FAIL: self-test — fail-open directive not detected: $cmd"; problems=$((problems + 1))
        fi
        ;;
      e99s04)
        if is_executable_verify "$cmd"; then
          echo "FAIL: self-test — prose accepted as a command: $cmd"; problems=$((problems + 1))
        fi
        ;;
      e99s05)
        if [ "$status" = "$GATED_STATUS" ]; then
          echo "FAIL: self-test — backlog story reported as done"; problems=$((problems + 1))
        fi
        ;;
    esac
  done <<EOF
$records
EOF

  rm -rf "$tmp_root"
  trap - EXIT

  if [ "$checked" -lt 5 ]; then
    echo "FAIL: self-test — extractor found $checked/5 fixture stories"
    return 1
  fi
  if [ "$problems" -gt 0 ]; then
    echo "FAIL: self-test — $problems assertion(s) failed"
    return 1
  fi
  echo "PASS: self-test — gate fails on broken stories, passes on sound ones"
  return 0
}

if [ "$TARGET" = "--self-test" ]; then
  run_self_test
  exit $?
fi

gate_all

echo ""
echo "Results: $PASS PASS, $FAIL FAIL, $SKIP SKIP"

if [ -n "$TARGET" ] && [ "$((PASS + FAIL))" -eq 0 ]; then
  echo "ERROR: no story matching '$TARGET' declares a verify: command" >&2
  exit 2
fi

[ "$FAIL" -eq 0 ]
