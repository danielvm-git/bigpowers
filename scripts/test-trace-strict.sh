#!/usr/bin/env bash
# test-trace-strict.sh — strict mode must not block unimplemented P0 stories
#
# Covers BUG-2026-07-06T205700:
#   - todo/planned/backlog P0 stories with 0 links do not fail --strict
#   - done P0 stories with 0 links still fail --strict
#
# Usage: bash scripts/test-trace-strict.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TRACE_ENGINE="$REPO_ROOT/scripts/lib/trace-stories.py"
FAILURES=0

trace_strict_pass() { echo -e "${GREEN}PASS${NC} $1"; }
trace_strict_fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }

run_strict() {
  local root="$1"
  local matrix_json
  local trace_md
  local okf_dir
  matrix_json=$(mktemp)
  trace_md=$(mktemp)
  okf_dir=$(mktemp -d)
  set +e
  local output
  output=$($PYTHON "$TRACE_ENGINE" "$root" "$matrix_json" "$trace_md" "$okf_dir" 1 "" 2>&1)
  local exit_code=$?
  set -e
  rm -f "$matrix_json" "$trace_md"
  rm -rf "$okf_dir"
  printf '%s\n' "$output"
  return "$exit_code"
}

write_fixture() {
  local root="$1"
  local done_story="${2:-}"

  mkdir -p "$root/specs/epics/e99-test"
  cat >"$root/specs/release-plan.yaml" <<'EOF'
release:
  version: "1.0.0"
  codename: "Strict Test"
  status: "proposed"
epics:
  - id: e99
    title: "Strict Test Epic"
    wsjf: 5.0
    bcps: 51
    mode: capsule
    status: proposed
    capsule_dir: epics/e99-test
EOF

  {
    echo "stories:"
    for i in $(seq 1 51); do
      sid=$(printf 'e99s%02d' "$i")
      printf '  - id: %s\n    title: "Story %d"\n    bcp: 1\n' "$sid" "$i"
    done
  } >"$root/specs/epics/e99-test/epic.yaml"

  {
    echo "development_status:"
    for i in $(seq 1 51); do
      sid=$(printf 'e99s%02d' "$i")
      if [[ -n "$done_story" && "$sid" == "$done_story" ]]; then
        echo "  $sid: done"
      else
        echo "  $sid: todo"
      fi
    done
  } >"$root/specs/execution-status.yaml"
}

echo "=== trace-strict: integration (real repo) ==="
set +e
bash "$REPO_ROOT/scripts/trace-stories.sh" --strict --json >/dev/null 2>&1
repo_exit=$?
set -e
if [[ $repo_exit -eq 0 ]]; then
  trace_strict_pass "trace-stories.sh --strict exits 0 on repo"
else
  trace_strict_fail "trace-stories.sh --strict exits $repo_exit on repo (expected 0)"
fi

echo ""
echo "=== trace-strict: fixture — all todo P0, 0 links ==="
FIXTURE_ROOT=$(mktemp -d)
trap 'rm -rf "$FIXTURE_ROOT"' EXIT
write_fixture "$FIXTURE_ROOT"
set +e
todo_output=$(run_strict "$FIXTURE_ROOT")
todo_exit=$?
set -e
if [[ $todo_exit -eq 0 ]]; then
  trace_strict_pass "strict passes when P0 stories are todo with 0 links"
else
  trace_strict_fail "strict exits $todo_exit on all-todo fixture (expected 0)"
  echo "$todo_output"
fi

echo ""
echo "=== trace-strict: fixture — done P0 with 0 links ==="
write_fixture "$FIXTURE_ROOT" "e99s01"
set +e
done_output=$(run_strict "$FIXTURE_ROOT")
done_exit=$?
set -e
if [[ $done_exit -eq 2 ]] && grep -q "P0 stories with 0% coverage" <<<"$done_output"; then
  trace_strict_pass "strict fails when a done P0 story has 0 links"
else
  trace_strict_fail "strict exits $done_exit on done-dark fixture (expected 2 with P0 message)"
  echo "$done_output"
fi

echo ""
if [[ $FAILURES -eq 0 ]]; then
  echo "test-trace-strict: PASS"
  exit 0
fi
echo "test-trace-strict: FAIL ($FAILURES failure(s))"
exit 1
