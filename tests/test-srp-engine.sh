#!/usr/bin/env bash
# story: e48s15
# Tests srp-engine.py functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Running srp-engine.py Tests ==="

# Check if script exists
if [ ! -f "$REPO_ROOT/scripts/lib/srp-engine.py" ]; then
  echo "FAIL: scripts/lib/srp-engine.py does not exist"
  exit 1
fi

# Run dry-run parse on skills/plan-work/SKILL.md
JSON_OUT=$(python3 "$REPO_ROOT/scripts/lib/srp-engine.py" "$REPO_ROOT/skills/plan-work/SKILL.md" --dry-run)

# Validate it is valid JSON and extract fields
NAME=$(echo "$JSON_OUT" | jq -r '.name')
DESC=$(echo "$JSON_OUT" | jq -r '.description')
BODY=$(echo "$JSON_OUT" | jq -r '.body')

echo "Parsed skill: $NAME"

if [ "$NAME" != "plan-work" ]; then
  echo "FAIL: Expected name to be 'plan-work', got '$NAME'"
  exit 1
fi

if [ -z "$DESC" ] || [ "$DESC" = "null" ]; then
  echo "FAIL: Description is missing or null"
  exit 1
fi

if [ -z "$BODY" ] || [ "$BODY" = "null" ]; then
  echo "FAIL: Body is missing or null"
  exit 1
fi

# Test 2: Pipe synthetic JSON to cursor.sh adapter
echo "=== Test 2: Pipe synthetic JSON to cursor.sh ==="
rm -f "$REPO_ROOT/.cursor/rules/test-skill.mdc"
echo '{"name":"test-skill","description":"test desc","body":"test body"}' | CURSOR_RULES="$REPO_ROOT/.cursor/rules" bash "$REPO_ROOT/scripts/adapters/cursor.sh"

if [ ! -f "$REPO_ROOT/.cursor/rules/test-skill.mdc" ]; then
  echo "FAIL: .cursor/rules/test-skill.mdc was not created"
  exit 1
fi

MDC_CONTENT=$(cat "$REPO_ROOT/.cursor/rules/test-skill.mdc")
if [[ "$MDC_CONTENT" != *"description: \"test desc\""* ]] || [[ "$MDC_CONTENT" != *"test body"* ]]; then
  echo "FAIL: .cursor/rules/test-skill.mdc content is invalid"
  echo "$MDC_CONTENT"
  exit 1
fi
rm -f "$REPO_ROOT/.cursor/rules/test-skill.mdc"

# Test 3: Run full pipeline using --target cursor on srp-engine.py
echo "=== Test 3: Run full pipeline using --target cursor ==="
rm -f "$REPO_ROOT/.cursor/rules/plan-work.mdc"
python3 "$REPO_ROOT/scripts/lib/srp-engine.py" "$REPO_ROOT/skills/plan-work/SKILL.md" --target cursor

if [ ! -f "$REPO_ROOT/.cursor/rules/plan-work.mdc" ]; then
  echo "FAIL: .cursor/rules/plan-work.mdc was not created by --target"
  exit 1
fi

MDC_CONTENT_PW=$(cat "$REPO_ROOT/.cursor/rules/plan-work.mdc")
if [[ "$MDC_CONTENT_PW" != *"description:"* ]] || [[ "$MDC_CONTENT_PW" != *"Plan the work:"* ]]; then
  echo "FAIL: .cursor/rules/plan-work.mdc content is invalid"
  echo "$MDC_CONTENT_PW"
  exit 1
fi
rm -f "$REPO_ROOT/.cursor/rules/plan-work.mdc"

# Test 4: Run full pipeline using --target gemini on srp-engine.py
echo "=== Test 4: Run full pipeline using --target gemini ==="
rm -rf "$REPO_ROOT/.gemini/extensions/bigpowers/skills/plan-work"
rm -f "$REPO_ROOT/.gemini/extensions/bigpowers/commands/prompts/plan-work.md"
GEMINI_EXT_DIR="$REPO_ROOT/.gemini/extensions/bigpowers" GEMINI_SKILLS="$REPO_ROOT/.gemini/extensions/bigpowers/skills" GEMINI_COMMANDS="$REPO_ROOT/.gemini/extensions/bigpowers/commands" python3 "$REPO_ROOT/scripts/lib/srp-engine.py" "$REPO_ROOT/skills/plan-work/SKILL.md" --target gemini

if [ ! -f "$REPO_ROOT/.gemini/extensions/bigpowers/skills/plan-work/SKILL.md" ] || [ ! -f "$REPO_ROOT/.gemini/extensions/bigpowers/commands/prompts/plan-work.md" ]; then
  echo "FAIL: gemini artifacts were not created by --target"
  exit 1
fi

# Test 5: Run full pipeline using --target pi on srp-engine.py
echo "=== Test 5: Run full pipeline using --target pi ==="
rm -rf "$REPO_ROOT/.pi/skills/plan-work"
rm -f "$REPO_ROOT/.pi/prompts/plan-work.md"
PI_SKILLS="$REPO_ROOT/.pi/skills" PI_PROMPTS="$REPO_ROOT/.pi/prompts" python3 "$REPO_ROOT/scripts/lib/srp-engine.py" "$REPO_ROOT/skills/plan-work/SKILL.md" --target pi

if [ ! -f "$REPO_ROOT/.pi/skills/plan-work/SKILL.md" ] || [ ! -f "$REPO_ROOT/.pi/prompts/plan-work.md" ]; then
  echo "FAIL: pi artifacts were not created by --target"
  exit 1
fi

echo "PASS: srp-engine.py parses SKILL.md correctly"
exit 0
