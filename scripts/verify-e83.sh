#!/usr/bin/env bash
# story: e83s01 e83s02 e83s03 e83s04 e83s05
# verify-e83.sh <story-id> — the acceptance checks for epic e83, one case per story.
# Called from the story verify: lines in specs/epics/e83-*/epic.yaml. It must never
# call run-story-verify.sh (that recurses; see the guard in run-story-verify.sh).
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:?usage: verify-e83.sh <e83s01..e83s05>}" in
  e83s01)
    grep -q 'last_tag' scripts/sync-version-mirrors.sh
    n=$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
    grep -q "$n agent skills" package.json
    grep -q "$n skills" scripts/mcp-server.js ;;
  e83s02)
    grep -q 'foreign' bin/bigpowers.js
    grep -q 'skills installed' bin/bigpowers.js ;;
  e83s03)
    grep -q 'cycle-times.yaml' scripts/build-receipts.sh
    out=$(mktemp); trap 'rm -f "$out"' EXIT
    RECEIPTS_OUT="$out" bash scripts/build-receipts.sh >/dev/null 2>&1
    python3 - "$out" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))['metrics']
v, b = d['value'], d['value']['source_breakdown']
assert 'stale' in v, 'missing stale flag'
n = sum(b.values())
want = ('measured' if b['measured'] == n else 'mixed' if b['measured'] else
        'backfilled' if b['backfilled'] == n else 'estimated')
assert d['source'] == want, f"source {d['source']} != {want}"
PY
    ;;
  e83s04)
    if grep -q '61 skills' specs/product/VISION_LATEST.yaml; then echo 'VISION still says 61 skills'; exit 1; fi
    out=$(bash scripts/check-catalog-drift.sh 2>&1 </dev/null)
    if grep -q '^WARNING' <<<"$out"; then echo "$out"; exit 1; fi ;;
  e83s05)
    ls specs/bugs/BUG-*spec-version-gap*.md >/dev/null
    bash tests/test-spec-version-gap-trigger.sh >/dev/null
    grep -qE '^status: (fixed|resolved)' specs/bugs/BUG-*spec-version-gap*.md ;;
  *) echo "verify-e83: unknown story $1" >&2; exit 2 ;;
esac
