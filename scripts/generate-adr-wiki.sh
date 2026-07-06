#!/usr/bin/env bash
# story: e45s01 e45s06
# generate-adr-wiki.sh — emit OKF concept bundles from specs/adr/*.md
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADRS="$ROOT/specs/adr"
WIKI="$ROOT/specs/adr-wiki"
mkdir -p "$WIKI"

if [ ! -d "$ADRS" ]; then
  echo "generate-adr-wiki: no ADR directory at $ADRS"
  exit 0
fi

count=0

assign_tier() {
  local adr_id="$1"
  case "$adr_id" in
    ADR-0001|ADR-0002|ADR-0003|0001-*|0002-*|0003-*) echo "core" ;;
    *)                                          echo "extended" ;;
  esac
}

for adr_file in "$ADRS"/*.md; do
  [ -f "$adr_file" ] || continue
  adr_name=$(basename "$adr_file" .md)

  # Parse YAML frontmatter if present
  fm="{}"
  if head -1 "$adr_file" 2>/dev/null | grep -q '^---$'; then
    fm=$($PYTHON -c "
import sys, yaml, json
content = open('$adr_file').read()
parts = content.split('---')
if len(parts) >= 3:
    try:
        d = yaml.safe_load(parts[1])
        if d:
            print(json.dumps(d))
    except: pass
" 2>/dev/null) || fm="{}"
  fi

  title=$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('title',''))" 2>/dev/null || echo "")
  status=$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('status','accepted'))" 2>/dev/null || echo "accepted")
  decision=$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('decision',''))" 2>/dev/null || echo "")

  # Fallback title from first heading
  if [ -z "$title" ]; then
    title=$(grep -m1 '^# ' "$adr_file" 2>/dev/null | sed 's/^# //' || echo "$adr_name")
  fi
  [ -z "$title" ] && title="$adr_name"

  tier=$(assign_tier "$adr_name")

  bundle="$WIKI/${adr_name}.okf.md"

  cat > "$bundle" << OKFEOF
---
okf_kind: concept
okf_version: "0.1"
id: "${adr_name}"
title: "${title}"
category: adr
tier: ${tier}
status: ${status}
decision: "${decision}"
generator: scripts/generate-adr-wiki.sh
references:
    - specs/adr/${adr_name}.md
---

# ${title}

**ADR:** ${adr_name} | **Status:** ${status} | **Tier:** ${tier}

See \`specs/adr/${adr_name}.md\` for the full architectural decision record.
OKFEOF

  count=$((count + 1))
  echo "  → ${adr_name}: ${title} [${tier}]"
done

echo "generate-adr-wiki: ${count} concept bundles → $WIKI/"
