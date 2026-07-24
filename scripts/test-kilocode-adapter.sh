#!/usr/bin/env bash
# story: e67s01
# scenario: SC-e67s01-P1-02
# Regression tests for Kilo adapter render + hook templates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-kilocode-adapter.sh ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if echo '{"name":"test-skill","description":"test desc","body":"test body"}' \
  | KILOCODE_RULES="$TMP" bash "$REPO_ROOT/scripts/adapters/kilocode.sh" \
    && [[ -f $TMP/test-skill.md ]] \
  && grep -q 'name: test-skill' $TMP/test-skill.md  \
  && grep -q 'test body' $TMP/test-skill.md; then
  pass "render_skill emits artifact from stdin SkillIR"
else
  fail "render_skill emits artifact from stdin SkillIR"
fi

if ! echo '{"name":"../escape","description":"d","body":"b"}' \
  | KILOCODE_RULES="$TMP/bad" bash "$REPO_ROOT/scripts/adapters/kilocode.sh" 2>/dev/null; then
  pass "rejects path traversal in skill name"
else
  fail "rejects path traversal in skill name"
fi

if [[ -f "$REPO_ROOT/scripts/hooks/kilocode/plugin/guard-git-plugin.ts" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/kilocode/hooks-manifest.json" ]] \
  && grep -q 'registerHook' "$REPO_ROOT/scripts/hooks/kilocode/plugin/guard-git-plugin.ts"; then
  pass "plugin hook template present"
else
  fail "plugin hook template present"
fi

ADAPTER_OUT=$(bash "$REPO_ROOT/scripts/test-adapters.sh" kilocode 2>&1 || true)
if echo "$ADAPTER_OUT" | grep -q '0 failed'; then
  pass "test-adapters.sh kilocode"
else
  fail "test-adapters.sh kilocode"
  echo "$ADAPTER_OUT"
fi

echo "test-kilocode-adapter: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
