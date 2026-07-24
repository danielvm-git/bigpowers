#!/usr/bin/env bash
# story: e70s01
# scenario: SC-e70s01-P1-02
# Regression tests for Trae adapter render + hook templates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-trae-adapter.sh ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if echo '{"name":"test-skill","description":"test desc","body":"test body"}' \
  | TRAE_SKILLS="$TMP" bash "$REPO_ROOT/scripts/adapters/trae.sh" \
    && [[ -f $TMP/test-skill/SKILL.md ]] \
  && grep -q 'name: test-skill' $TMP/test-skill/SKILL.md  \
  && grep -q 'test body' $TMP/test-skill/SKILL.md; then
  pass "render_skill emits artifact from stdin SkillIR"
else
  fail "render_skill emits artifact from stdin SkillIR"
fi

if ! echo '{"name":"../escape","description":"d","body":"b"}' \
  | TRAE_SKILLS="$TMP/bad" bash "$REPO_ROOT/scripts/adapters/trae.sh" 2>/dev/null; then
  pass "rejects path traversal in skill name"
else
  fail "rejects path traversal in skill name"
fi

if [[ -f "$REPO_ROOT/scripts/hooks/trae/pre-tool-git-guard.sh" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/trae/hooks-manifest.json" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/trae/settings.example.json" ]]; then
  pass "hook template bundle present"
else
  fail "hook template bundle present"
fi

BLOCK_OUT=$(echo '{"tool_input":{"command":"git push --force origin main"}}' \
  | bash "$REPO_ROOT/scripts/hooks/trae/pre-tool-git-guard.sh")
if echo "$BLOCK_OUT" | grep -q 'block'; then
  pass "pre-tool guard blocks dangerous command"
else
  fail "pre-tool guard blocks dangerous command"
fi

ADAPTER_OUT=$(bash "$REPO_ROOT/scripts/test-adapters.sh" trae 2>&1 || true)
if echo "$ADAPTER_OUT" | grep -q '0 failed'; then
  pass "test-adapters.sh trae"
else
  fail "test-adapters.sh trae"
  echo "$ADAPTER_OUT"
fi

echo "test-trae-adapter: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
