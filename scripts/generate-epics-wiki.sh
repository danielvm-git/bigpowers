#!/usr/bin/env bash
# story: e48s01
# story: e45s01 e45s06
# generate-epics-wiki.sh — emit OKF concept bundles from specs/epics/*/epic.yaml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI="$ROOT/specs/epics-wiki"
mkdir -p "$WIKI"

# Helper: extract YAML scalar field (graceful missing → empty)
extract() {
  local file="$1" key="$2"
  grep -m1 "^${key}:" "$file" 2>/dev/null | sed "s/^${key}: *//" | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" || echo ""
}

count=0

assign_tier() {
  local epic_id="$1"
  case "$epic_id" in
    e28|e38|e40|e41|e44|e45|e46) echo "core" ;;
    e39|e42|e43|e47|e48|e49)       echo "extended" ;;
    e12|e18|e19|e21|e25)            echo "extended" ;;
    e33|e35|e36|e37)                echo "extended" ;;
    *)                              echo "specialized" ;;
  esac
}

for epic_yaml in "$ROOT"/specs/epics/*/epic.yaml "$ROOT"/specs/epics/archive/*/epic.yaml; do
  [ -f "$epic_yaml" ] || continue

  epic_dir=$(dirname "$epic_yaml")
  epic_slug=$(basename "$epic_dir")

  epic_id=$(extract "$epic_yaml" "id")
  title=$(extract "$epic_yaml" "title" | tr -d '"')
  wsjf=$(extract "$epic_yaml" "wsjf")
  bcps=$(extract "$epic_yaml" "bcps")
  status=$(extract "$epic_yaml" "status")
  release=$(extract "$epic_yaml" "release")
  codename=$(extract "$epic_yaml" "codename" | tr -d '"')

  [[ -z "$epic_id" ]] && continue

  tier=$(assign_tier "$epic_id")

  # Build references array from story list
  story_count=$(grep -c '^\s*- id:' "$epic_yaml" 2>/dev/null || true)
  refs=$(grep '^\s*- id:' "$epic_yaml" 2>/dev/null | sed 's/.*- id: */    - /' || true)

  bundle="$WIKI/${epic_id}.okf.md"

  cat > "$bundle" << OKFEOF
---
okf_kind: concept
okf_version: "0.1"
type: epic
id: "${epic_id}"
title: "${title:-${epic_slug}}"
category: epic
tier: ${tier}
wsjf: ${wsjf:-0}
bcps: ${bcps:-0}
status: ${status:-proposed}
release: ${release:-unknown}
codename: "${codename:-}"
story_count: ${story_count}
generator: scripts/generate-epics-wiki.sh
references:
${refs}
---

# ${title:-${epic_slug}}

**Epic:** ${epic_id} | **WSJF:** ${wsjf:-0} | **BCP:** ${bcps:-0} | **Status:** ${status:-proposed}
**Release:** ${release:-unknown} | **Tier:** ${tier}

${story_count} stories. See \`${epic_yaml}\` for full specifications.
OKFEOF

  count=$((count + 1))
  echo "  → ${epic_id}: ${title:-${epic_slug}} [${tier}]"
done

echo "generate-epics-wiki: ${count} concept bundles → $WIKI/"
