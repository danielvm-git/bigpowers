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

# bash-3.2-portable membership test (no associative arrays — macOS ships bash 3.2)
in_array() {
  local needle="$1"; shift
  local x
  for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

[[ -f "$EPIC_YAML" ]] || report CRITICAL "Missing epic.yaml in $CAPSULE"

# Story IDs declared in epic.yaml
EPIC_STORIES=()
if [[ -f "$EPIC_YAML" ]]; then
  while IFS= read -r sid; do
    [[ -n "$sid" ]] && EPIC_STORIES+=("$sid")
  done < <(grep -E '^[[:space:]]*- id: e[0-9]+s[0-9]+' "$EPIC_YAML" | awk '{print $3}')
fi

shopt -s nullglob
SPECS=("$CAPSULE"/e*s*.md)
TASKS=("$CAPSULE"/e*s*-tasks.yaml)
shopt -u nullglob

(( ${#SPECS[@]} > 0 )) || report CRITICAL "No story spec .md files in capsule (run slice-tasks first)"
(( ${#TASKS[@]} > 0 )) || report CRITICAL "No *-tasks.yaml files in capsule (run plan-work first)"

# A story's real spec is whatever its own tasks.yaml declares via `spec:` —
# not every e*s*.md file, which also matches non-spec deliverables a story
# produces (e.g. an audit story's own eNNsYY-<slug>.md output document).
SPEC_IDS=()
for tasks in "${TASKS[@]+"${TASKS[@]}"}"; do
  base="$(basename "$tasks" -tasks.yaml)"
  sid="$(echo "$base" | grep -oE 'e[0-9]+s[0-9]+' | head -1)"
  [[ -n "$sid" ]] || continue

  spec_name="$(grep -E '^spec:' "$tasks" | head -1 | sed -E 's/^spec:[[:space:]]*//; s/^"(.*)"$/\1/')"
  spec="$CAPSULE/$spec_name"
  if [[ -z "$spec_name" || ! -f "$spec" ]]; then
    report CRITICAL "Story $sid tasks.yaml declares no valid spec: file"
  else
    SPEC_IDS+=("$sid")
    in_array "$sid" "${EPIC_STORIES[@]+"${EPIC_STORIES[@]}"}" \
      || report HIGH "Story $sid in spec file but missing from epic.yaml manifest"
    grep -qE '^#{2,3} (17\.|Acceptance|Verification Script)' "$spec" \
      || report HIGH "Story $sid spec missing §17 acceptance criteria or Verification Script"
    grep -qiE 'ambiguous|TBD|TODO|FIXME' "$spec" \
      && report MED "Story $sid spec contains ambiguous/TBD markers"
  fi

  grep -qE '^[[:space:]]*verify:' "$tasks" \
    || report CRITICAL "Story $sid tasks.yaml missing runnable verify: commands"
  grep -qE '^status:[[:space:]]*(failing|todo|passing)' "$tasks" \
    || report MED "Story $sid tasks.yaml should use status: failing|passing ledger (e45s06)"
done

for sid in "${EPIC_STORIES[@]+"${EPIC_STORIES[@]}"}"; do
  in_array "$sid" "${SPEC_IDS[@]+"${SPEC_IDS[@]}"}" \
    || report HIGH "epic.yaml lists $sid but no story spec .md exists"
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
