#!/usr/bin/env bash
# story: e64s01
# Validates Gemini adapter hook templates and stdin render path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GEMINI_EXT="$REPO_ROOT/.gemini/extensions/bigpowers"

echo "=== test-gemini-adapter.sh ==="

# Test 1: validate hook templates via adapter CLI
echo "Test 1: validate_hook_templates"
GEMINI_EXT_DIR="$GEMINI_EXT" GEMINI_HOOKS_DIR="$GEMINI_EXT/hooks" \
  bash "$REPO_ROOT/scripts/adapters/gemini.sh" --validate-hooks

# Test 2: event count
echo "Test 2: hook event count"
COUNT="$(GEMINI_EXT_DIR="$GEMINI_EXT" bash "$REPO_ROOT/scripts/adapters/gemini.sh" --list-hook-events | wc -l | tr -d ' ')"
if [[ "$COUNT" != "11" ]]; then
  echo "FAIL: expected 11 events, got $COUNT"
  exit 1
fi

# Test 3: HOOKS.md documents all events
echo "Test 3: HOOKS.md coverage"
for ev in BeforeTool AfterTool BeforeAgent AfterAgent BeforeModel BeforeToolSelection AfterModel SessionStart SessionEnd Notification PreCompress; do
  grep -q "$ev" "$GEMINI_EXT/hooks/HOOKS.md" || { echo "FAIL: HOOKS.md missing $ev"; exit 1; }
done

# Test 4: stdin render smoke (fallback path without sync-render sourced)
echo "Test 4: stdin render smoke"
TMP_SKILL="$GEMINI_EXT/skills/_test-gemini-adapter"
TMP_CMD="$GEMINI_EXT/commands/prompts/_test-gemini-adapter.md"
rm -rf "$TMP_SKILL" "$TMP_CMD"
echo '{"name":"_test-gemini-adapter","model":"","description":"adapter test","body":"test body"}' | \
  GEMINI_SKILLS="$GEMINI_EXT/skills" GEMINI_COMMANDS="$GEMINI_EXT/commands" \
  bash "$REPO_ROOT/scripts/adapters/gemini.sh"
if [[ ! -f "$TMP_SKILL/SKILL.md" ]] || [[ ! -f "$TMP_CMD" ]]; then
  echo "FAIL: gemini adapter did not render test skill"
  exit 1
fi
rm -rf "$TMP_SKILL" "$TMP_CMD"

# Test 5: render_gemini_hooks_manifest via sync-render
echo "Test 5: render_gemini_hooks_manifest"
source "$REPO_ROOT/scripts/lib/skill-common.sh" 2>/dev/null || true
source "$REPO_ROOT/scripts/lib/sync-render.sh"
GEMINI_EXT_DIR="$GEMINI_EXT"
render_gemini_hooks_manifest
grep -q '"events_total": 11' "$GEMINI_EXT/hooks/hooks-manifest.json" || {
  echo "FAIL: hooks-manifest.json invalid after render"
  exit 1
}

# Test 6: before-tool-git-guard gemini JSON shape
echo "Test 6: before-tool-git-guard gemini mode"
OUT="$(echo '{"tool_input":{"command":"git reset --hard"}}' | \
  bash "$GEMINI_EXT/hooks/before-tool-git-guard.sh")"
echo "$OUT" | jq -e '.decision == "deny"' >/dev/null || {
  echo "FAIL: git guard did not deny dangerous reset --hard"
  echo "$OUT"
  exit 1
}

echo "PASS: test-gemini-adapter.sh"
exit 0
