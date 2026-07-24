#!/usr/bin/env bash
# story: e66s01
# scenario: SC-e66s01-P1-02
# Regression tests for Cline adapter render + hook templates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-cline-adapter.sh ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if echo '{"name":"test-skill","description":"test desc","body":"test body"}' \
  | CLINE_SKILLS="$TMP" bash "$REPO_ROOT/scripts/adapters/cline.sh" \
    && [[ -f $TMP/test-skill/SKILL.md ]] \
  && grep -q 'name: test-skill' $TMP/test-skill/SKILL.md  \
  && grep -q 'test body' $TMP/test-skill/SKILL.md; then
  pass "render_skill emits artifact from stdin SkillIR"
else
  fail "render_skill emits artifact from stdin SkillIR"
fi

if ! echo '{"name":"../escape","description":"d","body":"b"}' \
  | CLINE_SKILLS="$TMP/bad" bash "$REPO_ROOT/scripts/adapters/cline.sh" 2>/dev/null; then
  pass "rejects path traversal in skill name"
else
  fail "rejects path traversal in skill name"
fi

if [[ -f "$REPO_ROOT/scripts/hooks/cline/plugin/guard-git-plugin.ts" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/cline/hooks-manifest.json" ]] \
  && grep -q 'registerHook' "$REPO_ROOT/scripts/hooks/cline/plugin/guard-git-plugin.ts"; then
  pass "plugin hook template present"
else
  fail "plugin hook template present"
fi

ADAPTER_OUT=$(bash "$REPO_ROOT/scripts/test-adapters.sh" cline 2>&1 || true)
if echo "$ADAPTER_OUT" | grep -q '0 failed'; then
  pass "test-adapters.sh cline"
else
  fail "test-adapters.sh cline"
  echo "$ADAPTER_OUT"
fi

echo "test-cline-adapter: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
