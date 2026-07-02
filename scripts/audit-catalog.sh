#!/usr/bin/env bash
# audit-catalog.sh — Verify all .pi/skills/ have matching source SKILL.md and vice versa.
# Output: "OK: N/N skills synced" or "MISMATCH: X orphans, Y missing"
# Exit code: 0 if synced, 1 if mismatch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
# SKILLS_ROOT: use skills/ when it exists, fall back to repo root
SKILLS_ROOT="$REPO_ROOT"
[[ -d "$REPO_ROOT/skills" ]] && SKILLS_ROOT="$REPO_ROOT/skills"

ORPHANS=()
MISSING=()

# Check: every .pi/skills/<name>/ dir must have a matching source SKILL.md
for d in .pi/skills/*/; do
  name=$(basename "$d")
  if [ ! -f "$SKILLS_ROOT/$name/SKILL.md" ]; then
    ORPHANS+=("$name")
  fi
done

# Check: every SKILLS_ROOT SKILL.md dir must have a matching .pi/skills/<name>/SKILL.md
for f in "$SKILLS_ROOT"/*/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  # Skip non-skill directories
  case "$name" in
    docs|node_modules|scripts|specs|dashboard|test) continue ;;
  esac
  if [ ! -f ".pi/skills/$name/SKILL.md" ]; then
    MISSING+=("$name")
  fi
done

PI_COUNT=$(ls -d .pi/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
SRC_COUNT=0
for f in "$SKILLS_ROOT"/*/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  case "$name" in
    docs|node_modules|scripts|specs|dashboard|test) continue ;;
  esac
  SRC_COUNT=$((SRC_COUNT + 1))
done

if [ "${#ORPHANS[@]}" -eq 0 ] && [ "${#MISSING[@]}" -eq 0 ]; then
  echo "OK: $PI_COUNT/$SRC_COUNT skills synced"
  exit 0
else
  echo "MISMATCH: ${#ORPHANS[@]} orphans, ${#MISSING[@]} missing"
  if [ "${#ORPHANS[@]}" -gt 0 ]; then
    echo ""
    echo "Orphans (in .pi/skills/ but no source SKILL.md):"
    for o in "${ORPHANS[@]}"; do
      echo "  - $o"
    done
  fi
  if [ "${#MISSING[@]}" -gt 0 ]; then
    echo ""
    echo "Missing (source SKILL.md but not in .pi/skills/):"
    for m in "${MISSING[@]}"; do
      echo "  - $m"
    done
  fi
  exit 1
fi
