#!/usr/bin/env bash
# story: e61s01
# Regression tests for Hermes adapter render + hook templates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-hermes-adapter.sh ==="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Task 1+2: stdin SkillIR render
if echo '{"name":"test-skill","description":"test desc","body":"test body"}' \
  | HERMES_SKILLS="$TMP/skills" bash "$REPO_ROOT/scripts/adapters/hermes.sh" \
  && [[ -f "$TMP/skills/test-skill/SKILL.md" ]] \
  && grep -q 'name: test-skill' "$TMP/skills/test-skill/SKILL.md" \
  && grep -q 'test body' "$TMP/skills/test-skill/SKILL.md"; then
  pass "render_skill emits SKILL.md from stdin SkillIR"
else
  fail "render_skill emits SKILL.md from stdin SkillIR"
fi

# IR_NAME sanitization rejects path traversal
if ! echo '{"name":"../escape","description":"d","body":"b"}' \
  | HERMES_SKILLS="$TMP/bad" bash "$REPO_ROOT/scripts/adapters/hermes.sh" 2>/dev/null; then
  pass "rejects path traversal in skill name"
else
  fail "rejects path traversal in skill name"
fi

# Gateway template
if [[ -f "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log/HOOK.yaml" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log/handler.py" ]] \
  && grep -q 'agent:start' "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log/HOOK.yaml" \
  && grep -q 'async def handle' "$REPO_ROOT/scripts/hooks/hermes/gateway/session-log/handler.py"; then
  pass "gateway hook template present"
else
  fail "gateway hook template present"
fi

# Shell template
if [[ -f "$REPO_ROOT/scripts/hooks/hermes/shell/block-dangerous-terminal.sh" ]] \
  && [[ -f "$REPO_ROOT/scripts/hooks/hermes/shell/hooks-config.example.yaml" ]] \
  && grep -q 'pre_tool_call' "$REPO_ROOT/scripts/hooks/hermes/shell/hooks-config.example.yaml"; then
  pass "shell hook template present"
else
  fail "shell hook template present"
fi

# Plugin template
if [[ -f "$REPO_ROOT/scripts/hooks/hermes/plugin/guard-git-plugin.py" ]] \
  && grep -q 'register_hook' "$REPO_ROOT/scripts/hooks/hermes/plugin/guard-git-plugin.py"; then
  pass "plugin hook template present"
else
  fail "plugin hook template present"
fi

# Shell hook block decision shape
BLOCK_OUT=$(echo '{"tool_name":"terminal","tool_input":{"command":"git push --force origin main"}}' \
  | bash "$REPO_ROOT/scripts/hooks/hermes/shell/block-dangerous-terminal.sh")
if echo "$BLOCK_OUT" | grep -q 'block'; then
  pass "shell hook blocks dangerous terminal command"
else
  fail "shell hook blocks dangerous terminal command"
fi

# test-adapters smoke (exit code may be 1 due to ta_cleanup trap when TA_TMPDIR unset — pre-existing e37)
ADAPTER_OUT=$(bash "$REPO_ROOT/scripts/test-adapters.sh" hermes 2>&1 || true)
if echo "$ADAPTER_OUT" | grep -q '0 failed' && echo "$ADAPTER_OUT" | grep -q 'PASS hermes: idempotent wire_context'; then
  pass "test-adapters.sh hermes"
else
  fail "test-adapters.sh hermes"
  echo "$ADAPTER_OUT"
fi

echo "test-hermes-adapter: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
