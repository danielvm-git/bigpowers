#!/usr/bin/env bash
# story: e86 / GH #182 / GH #183
# Tests for mechanical artifact assertions and epic audit gate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass_count=0
fail_count=0

assert_true() {
  local label="$1"
  shift
  if "$@"; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label"
    fail_count=$((fail_count + 1))
  fi
}

assert_false() {
  local label="$1"
  shift
  if ! "$@"; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label"
    fail_count=$((fail_count + 1))
  fi
}

echo "=== Artifact & Gate Assertion Tests (GH #182, GH #183) ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"
mkdir -p specs/product specs/epics/e01-test

# 1. Test assert-planning-artifacts.sh for scope-work (missing -> fail, present -> pass)
assert_false "scope-work fails when SCOPE_LATEST.yaml missing" \
  bash "$REPO_ROOT/scripts/lib/assert-planning-artifacts.sh" scope-work

echo "scope: test" > specs/product/SCOPE_LATEST.yaml
assert_true "scope-work passes when SCOPE_LATEST.yaml exists and non-empty" \
  bash "$REPO_ROOT/scripts/lib/assert-planning-artifacts.sh" scope-work

# 2. Test assert-planning-artifacts.sh for slice-tasks
assert_false "slice-tasks fails when no *-tasks.yaml exists" \
  bash "$REPO_ROOT/scripts/lib/assert-planning-artifacts.sh" slice-tasks

cat > specs/epics/e01-test/e01s01-tasks.yaml <<'YAML'
story_id: e01s01
tasks: []
YAML
assert_true "slice-tasks passes when *-tasks.yaml exists" \
  bash "$REPO_ROOT/scripts/lib/assert-planning-artifacts.sh" slice-tasks

# 3. Test assert-epic-gate.sh (Issue #182)
assert_false "assert-epic-gate fails when no audit report exists" \
  bash "$REPO_ROOT/scripts/lib/assert-epic-gate.sh" commit

cat > specs/AUDIT_LATEST.md <<'MD'
# Audit Report
VERDICT: FAIL
MD
assert_false "assert-epic-gate fails when audit report is FAIL" \
  bash "$REPO_ROOT/scripts/lib/assert-epic-gate.sh" commit

cat > specs/AUDIT_LATEST.md <<'MD'
# Audit Report
VERDICT: PASS
MD
assert_true "assert-epic-gate passes when audit report is PASS" \
  bash "$REPO_ROOT/scripts/lib/assert-epic-gate.sh" commit

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed ==="
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
