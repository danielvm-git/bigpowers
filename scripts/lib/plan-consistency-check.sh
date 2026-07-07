#!/usr/bin/env bash
# story: e45s04
# Pre-build cross-artifact consistency — slice-tasks output vs epic capsule.
# Severity: CRITICAL | HIGH | MED | LOW (LOW is informational only).
set -euo pipefail

CAPSULE="${1:-}"
if [[ -z "$CAPSULE" || ! -d "$CAPSULE" ]]; then
  echo "Usage: bash scripts/lib/plan-consistency-check.sh specs/epics/eNN-slug" >&2
  exit 2
fi

EPIC_YAML="$CAPSULE/epic.yaml"
CRITICAL=0
HIGH=0
MED=0

report() {
  local sev="$1" msg="$2"
  echo "[$sev] $msg"
  case "$sev" in
    CRITICAL) CRITICAL=$((CRITICAL + 1)) ;;
    HIGH) HIGH=$((HIGH + 1)) ;;
    MED) MED=$((MED + 1)) ;;
  esac
}

[[ -f "$EPIC_YAML" ]] || report CRITICAL "Missing epic.yaml in $CAPSULE"

# Story IDs declared in epic.yaml
declare -A EPIC_STORIES=()
if [[ -f "$EPIC_YAML" ]]; then
  while IFS= read -r sid; do
    [[ -n "$sid" ]] && EPIC_STORIES["$sid"]=1
  done < <(grep -E '^[[:space:]]*- id: e[0-9]+s[0-9]+' "$EPIC_YAML" | awk '{print $3}')
fi

shopt -s nullglob
SPECS=("$CAPSULE"/e*s*.md)
TASKS=("$CAPSULE"/e*s*-tasks.yaml)
shopt -u nullglob

(( ${#SPECS[@]} > 0 )) || report CRITICAL "No story spec .md files in capsule (run slice-tasks first)"
(( ${#TASKS[@]} > 0 )) || report CRITICAL "No *-tasks.yaml files in capsule (run plan-work first)"

declare -A SPEC_IDS=()
for spec in "${SPECS[@]}"; do
  base="$(basename "$spec" .md)"
  sid="$(echo "$base" | grep -oE 'e[0-9]+s[0-9]+' | head -1)"
  [[ -n "$sid" ]] || continue
  SPEC_IDS["$sid"]=1
  [[ -n "${EPIC_STORIES[$sid]+x}" ]] || report HIGH "Story $sid in spec file but missing from epic.yaml manifest"
  grep -qE '^## (17\.|Acceptance|Verification Script)' "$spec" \
    || report HIGH "Story $sid spec missing §17 acceptance criteria or Verification Script"
  grep -qiE 'ambiguous|TBD|TODO|FIXME' "$spec" \
    && report MED "Story $sid spec contains ambiguous/TBD markers"
done

for tasks in "${TASKS[@]}"; do
  base="$(basename "$tasks" -tasks.yaml)"
  sid="$(echo "$base" | grep -oE 'e[0-9]+s[0-9]+' | head -1)"
  [[ -n "$sid" ]] || continue
  [[ -n "${SPEC_IDS[$sid]+x}" ]] || report CRITICAL "tasks.yaml for $sid without matching story spec .md"
  grep -qE '^[[:space:]]*verify:' "$tasks" \
    || report CRITICAL "Story $sid tasks.yaml missing runnable verify: commands"
  grep -qE '^status:[[:space:]]*(failing|todo|passing)' "$tasks" \
    || report MED "Story $sid tasks.yaml should use status: failing|passing ledger (e45s06)"
done

for sid in "${!EPIC_STORIES[@]}"; do
  [[ -n "${SPEC_IDS[$sid]+x}" ]] || report HIGH "epic.yaml lists $sid but no story spec .md exists"
done

echo "---"
echo "plan-consistency-check: CRITICAL=$CRITICAL HIGH=$HIGH MED=$MED"

if (( CRITICAL > 0 || HIGH > 0 )); then
  echo "BLOCKED: resolve CRITICAL/HIGH before code generation" >&2
  exit 1
fi

if (( MED > 0 )); then
  echo "WARN: MED findings present — confirm with user before build"
  exit 0
fi

echo "PASS: capsule artifacts consistent"
exit 0
