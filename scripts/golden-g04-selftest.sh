#!/usr/bin/env bash
# golden-g04-selftest.sh — Sync-pipeline self-test (G-04)
#
# Asserts:
#   1. All target directories exist (.cursor/rules, .gemini/extensions/bigpowers, .pi)
#   2. Each target directory contains exactly 72 .md artifact files
#   3. skills-lock.json skill count matches SKILL-INDEX.md skill count
#
# Exit 0 on all assertions passing; exit 1 on first failure.
#
# Usage: bash scripts/golden-g04-selftest.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

g04_pass()  { echo -e "${GREEN}PASS${NC} $*"; PASS=$((PASS + 1)); }
g04_fail()  { echo -e "${RED}FAIL${NC} $*"; FAIL=$((FAIL + 1)); }

# ── Task 1: Target directory existence ────────────────────────────────

TARGETS=(
  ".cursor/rules"
  ".gemini/extensions/bigpowers"
  ".pi/skills"
)

for dir in "${TARGETS[@]}"; do
  if [[ -d "$dir" ]]; then
    g04_pass "directory exists: $dir"
  else
    g04_fail "directory not found: $dir"
  fi
done

# ── Task 2: Artifact count assertion (72 per target) ──────────────────

EXPECTED=$(jq '.skills | keys | length' skills-lock.json 2>/dev/null) || {
  echo "FAIL cannot read skills-lock.json"
  exit 1
}

check_count() {
  local dir="$1"
  local label="$2"
  local pattern="${3:-*.md}"

  if [[ ! -d "$dir" ]]; then
    g04_fail "$label: directory not found (skipping count)"
    return
  fi

  # Count files matching pattern (non-recursive for .cursor and .gemini,
  # recursive for .pi which has subdirectories)
  local count
  if [[ "$dir" == ".pi/skills" || "$dir" == *"/skills" ]]; then
    count=$(find "$dir" -maxdepth 2 -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' ')
  else
    count=$(find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  if [[ "$count" -eq "$EXPECTED" ]]; then
    g04_pass "$label: $count artifacts (expected $EXPECTED)"
  else
    g04_fail "$label: expected $EXPECTED artifacts, got $count"
  fi
}

check_count ".cursor/rules" ".cursor/rules" "*.mdc"
check_count ".gemini/extensions/bigpowers/skills" ".gemini/extensions/bigpowers" "SKILL.md"
check_count ".pi/skills" ".pi/skills" "SKILL.md"

# ── Task 3: Lockfile vs SKILL-INDEX count assertion ───────────────────

LOCKFILE="skills-lock.json"
INDEXFILE="SKILL-INDEX.md"

if [[ ! -f "$LOCKFILE" ]]; then
  g04_fail "lockfile not found: $LOCKFILE"
else
  # Parse lockfile: count top-level keys (skill names)
  if command -v jq &>/dev/null; then
    lock_count=$(jq '.skills | keys | length' "$LOCKFILE" 2>/dev/null) || {
      fail "lockfile parse error: $LOCKFILE (invalid JSON)"
      lock_count=""
    }
  else
    # Fallback: count lines with skill name pattern
    lock_count=$(grep -cE '^\s*"[^"]+"\s*:' "$LOCKFILE" 2>/dev/null) || {
      fail "lockfile parse error: $LOCKFILE"
      lock_count=""
    }
  fi
fi

if [[ ! -f "$INDEXFILE" ]]; then
  g04_fail "index not found: $INDEXFILE"
else
  # Count skill entries from SKILL-INDEX.md header (e.g., "**Skills:** 72")
  index_count=$(grep '\*\*Skills:\*\*' "$INDEXFILE" 2>/dev/null | sed 's/.*\*\*Skills:\*\*[[:space:]]*//' | grep -oE '[0-9]+') || {
    g04_fail "index parse error: $INDEXFILE"
    index_count=""
  }
fi

if [[ -n "${lock_count:-}" && -n "${index_count:-}" ]]; then
  if [[ "$lock_count" -eq "$index_count" ]]; then
    g04_pass "lockfile ($lock_count) matches SKILL-INDEX ($index_count)"
  else
    g04_fail "lockfile ($lock_count) != SKILL-INDEX ($index_count)"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────

echo ""
echo "──────────────────────────────────────────"
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "──────────────────────────────────────────"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
