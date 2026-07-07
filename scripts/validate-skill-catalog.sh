#!/usr/bin/env bash
# story: e45s12
# validate-skill-catalog.sh — code-enforced skill catalog hygiene (Hermes Curator pattern)
# Exit 0 when catalog passes; 1 on violations. --archive lists zero-usage skills for archiving.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SKILLS_ROOT="$REPO_ROOT/skills"
[[ -d "$SKILLS_ROOT" ]] || SKILLS_ROOT="$REPO_ROOT"

ARCHIVE_MODE=false
STRICT=false
TARGET_SKILL=""
VIOLATIONS=0
WARNINGS=0

# Documented naming exceptions (craft-skill REFERENCE.md)
VERB_NOUN_EXCEPTIONS="grill-me grill-with-docs context7-mcp using-bigpowers deploy"

catalog_usage() {
  echo "Usage: bash scripts/validate-skill-catalog.sh [--archive] [--strict] [--skill <name>]"
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive) ARCHIVE_MODE=true; shift ;;
    --strict) STRICT=true; shift ;;
    --skill) TARGET_SKILL="${2:-}"; shift 2 ;;
    --skill=*) TARGET_SKILL="${1#*=}"; shift ;;
    -h|--help) catalog_usage ;;
    *) echo "Unknown flag: $1" >&2; catalog_usage ;;
  esac
done

report_catalog_violation() { echo "FAIL: $1" >&2; VIOLATIONS=$((VIOLATIONS + 1)); }
report_catalog_warning() { echo "WARN: $1" >&2; WARNINGS=$((WARNINGS + 1)); }

catalog_validate_verb_noun() {
  local name="$1"
  if echo " $VERB_NOUN_EXCEPTIONS " | grep -q " $name "; then
    return 0
  fi
  if [[ ! "$name" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*)+$ ]]; then
    report_catalog_violation "$name: not verb-noun kebab-case"
    return 1
  fi
  local segments
  segments=$(echo "$name" | tr '-' '\n' | wc -l | tr -d ' ')
  if [[ "$segments" -gt 2 ]]; then
    report_catalog_violation "$name: more than two hyphen segments (verb-noun only)"
  fi
}

catalog_validate_skill() {
  local skill_md="$1"
  local name
  name=$(basename "$(dirname "$skill_md")")

  catalog_validate_verb_noun "$name" || true

  if ! grep -q 'HARD GATE' "$skill_md" 2>/dev/null; then
    if $STRICT; then report_catalog_violation "$name: missing HARD GATE block"; else report_catalog_warning "$name: missing HARD GATE block"; fi
  fi

  local desc
  desc=$(awk 'BEGIN{f=0} /^---$/{f++; next} f==1{print} f==2{exit}' "$skill_md" \
    | grep -E '^description:' | head -1 | sed 's/^description: *//; s/^\x3e //' | tr -d '"' || true)
  if [[ -n "$desc" && ${#desc} -gt 1024 ]]; then
    report_catalog_violation "$name: description ${#desc} chars (max 1024)"
  fi

  local lines
  lines=$(wc -l < "$skill_md" | tr -d ' ')
  if [[ "$lines" -gt 300 ]]; then
    report_catalog_warning "$name: SKILL.md $lines lines (target ≤300; split to REFERENCE.md)"
  fi

  local cmd
  cmd=$(grep 'verify:' "$skill_md" 2>/dev/null | tail -1 | sed 's/^\x3e //; s/^→ verify: *//' || true)
  if [[ -z "$cmd" ]]; then
    if $STRICT; then report_catalog_violation "$name: missing → verify: command"; else report_catalog_warning "$name: missing → verify: command"; fi
  fi
}

echo "Validating skill catalog under $SKILLS_ROOT ..."
if [[ -n "$TARGET_SKILL" ]]; then
  skill_md="$SKILLS_ROOT/$TARGET_SKILL/SKILL.md"
  [[ -f "$skill_md" ]] || { echo "FAIL: $skill_md not found" >&2; exit 1; }
  catalog_validate_skill "$skill_md"
else
  for skill_md in "$SKILLS_ROOT"/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    catalog_validate_skill "$skill_md"
  done
fi

if $ARCHIVE_MODE; then
  STATE="$REPO_ROOT/specs/state.yaml"
  echo ""
  echo "=== Archive candidates (zero calls in metrics.skill_timings) ==="
  if [[ ! -f "$STATE" ]]; then
    echo "  (no specs/state.yaml — skip usage scan)"
  else
    python3 - "$STATE" "$SKILLS_ROOT" <<'PY'
import sys, glob, os
from pathlib import Path

state_path, skills_root = sys.argv[1], sys.argv[2]
text = Path(state_path).read_text(encoding="utf-8")
timings = set()
in_timings = False
for line in text.splitlines():
    if line.strip() == "skill_timings:":
        in_timings = True
        continue
    if in_timings:
        if line.startswith("  ") and not line.startswith("    ") and line.rstrip().endswith(":"):
            timings.add(line.strip().rstrip(":"))
        elif line.strip() and not line.startswith(" "):
            in_timings = False

skills = [os.path.basename(os.path.dirname(p)) for p in glob.glob(f"{skills_root}/*/SKILL.md")]
zero = sorted(s for s in skills if s not in timings)
if zero:
    for s in zero:
        print(f"  ARCHIVE_CANDIDATE: {s} (0 calls — move to specs/epics/archive/ or delete)")
else:
    print("  (no zero-usage skills)")
PY
  fi
fi

echo ""
if [[ "$VIOLATIONS" -gt 0 ]]; then
  echo "CATALOG INVALID: $VIOLATIONS violation(s), $WARNINGS warning(s)"
  exit 1
fi
if $STRICT && [[ "$WARNINGS" -gt 0 ]]; then
  echo "CATALOG INVALID (strict): $WARNINGS warning(s)"
  exit 1
fi
echo "CATALOG OK: $WARNINGS warning(s)"
exit 0
