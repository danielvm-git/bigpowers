#!/usr/bin/env bash
# story: e62s01
# scenario: SC-e62s01-P1-02
# Regression tests for OpenCode adapter render + hook templates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-opencode-adapter.sh ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if echo '{"name":"test-skill","description":"test desc","body":"test body"}' \
  | OPENCODE_SKILLS="$TMP" bash "$REPO_ROOT/scripts/adapters/opencode.sh" \
    && [[ -f $TMP/test-skill/SKILL.md ]] \
  && grep -q 'name: test-skill' $TMP/test-skill/SKILL.md  \
  && grep -q 'test body' $TMP/test-skill/SKILL.md; then
  pass "render_skill emits artifact from stdin SkillIR"
else
  fail "render_skill emits artifact from stdin SkillIR"
fi

if ! echo '{"name":"../escape","description":"d","body":"b"}' \
  | OPENCODE_SKILLS="$TMP/bad" bash "$REPO_ROOT/scripts/adapters/opencode.sh" 2>/dev/null; then
  pass "rejects path traversal in skill name"
else
  fail "rejects path traversal in skill name"
fi

ADAPTER_OUT=$(bash "$REPO_ROOT/scripts/test-adapters.sh" opencode 2>&1 || true)
if echo "$ADAPTER_OUT" | grep -q '0 failed'; then
  pass "test-adapters.sh opencode"
else
  fail "test-adapters.sh opencode"
  echo "$ADAPTER_OUT"
fi

echo "test-opencode-adapter: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
