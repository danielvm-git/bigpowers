#!/usr/bin/env bash
# story: e86s01
# Test suite for generated-path edit blocking in pre-tool-use.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/pre-tool-use.sh"

pass_count=0
fail_count=0

assert_denied() {
  local label="$1"
  local input="$2"
  local output exit_code=0
  output=$(echo "$input" | bash "$HOOK" 2>&1) || exit_code=$?
  if [ "$exit_code" -ne 0 ] || echo "$output" | grep -q '"decision"[[:space:]]*:[[:space:]]*"deny"'; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (expected deny, got allow: $output)"
    fail_count=$((fail_count + 1))
  fi
}

assert_allowed() {
  local label="$1"
  local input="$2"
  local output exit_code=0
  output=$(echo "$input" | bash "$HOOK" 2>&1) || exit_code=$?
  if [ "$exit_code" -eq 0 ] && ! echo "$output" | grep -q '"decision"[[:space:]]*:[[:space:]]*"deny"'; then
    echo "  PASS $label"
    pass_count=$((pass_count + 1))
  else
    echo "  FAIL $label (expected allow, got deny: $output)"
    fail_count=$((fail_count + 1))
  fi
}

echo "=== Generated Path Hook Tests (e86s01) ==="

assert_denied "Deny direct edit to .cursor/rules" \
  '{"tool": "Edit", "file_path": ".cursor/rules/skill.mdc"}'

assert_denied "Deny direct edit to .gemini/extensions" \
  '{"tool": "Write", "file_path": ".gemini/extensions/bigpowers/skills/skill.md"}'

assert_allowed "Allow edit to source skills/ directory" \
  '{"tool": "Edit", "file_path": "skills/plan-work/SKILL.md"}'

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed ==="
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
