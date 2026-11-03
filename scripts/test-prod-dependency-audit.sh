#!/usr/bin/env bash
# story: BUG-2026-11-03-prod-dependency-advisories
# test-prod-dependency-audit.sh — the shipped dependency graph must stay advisory-free.
#
# `npm audit --omit=dev` covers what users actually install. It was 10 advisories
# (1 critical) on 2.93.1 with nothing watching it: the only dependency gates were
# about whether the package *builds*, not whether its tree is safe.
#
# Two failure modes, both loud:
#   1. any advisory in the production tree        → FAIL, listing package + severity
#   2. the audit could not run (no registry)      → FAIL, naming the escape hatch
#
# Nothing here passes silently. To skip it deliberately (offline work), the golden
# runner's own mechanism is the documented path:
#   GOLDEN_SKIP_GATES=prod-dependency-audit bash scripts/run-verification-gates.sh
# ...which records the gate as SKIPPED in the report rather than green.
#
# Dev-tree advisories are out of scope: they are concentrated in the npm bundle
# inside @semantic-release/npm and need major release-tool upgrades
# (BUG-2026-11-03-dev-dependency-advisories).
#
# Usage: bash scripts/test-prod-dependency-audit.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

source scripts/lib/test-assertions.sh
TA_PASS=0
TA_FAIL=0
TA_TMPDIR="$(mktemp -d)"
trap ta_cleanup EXIT

echo "=== test-prod-dependency-audit.sh ==="

if ! command -v npm >/dev/null 2>&1; then
  ta_fail "npm is unavailable — cannot audit the production dependency graph"
  echo "$TA_PASS passed, $TA_FAIL failed"
  exit 1
fi

AUDIT_JSON="$TA_TMPDIR/audit-prod.json"
# npm audit exits 1 when it finds advisories — capture, do not abort.
npm audit --omit=dev --json >"$AUDIT_JSON" 2>"$TA_TMPDIR/audit-prod.err" || true

REPORT="$(
  python3 - "$AUDIT_JSON" <<'PY'
import json, sys

path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    print("UNPARSEABLE")
    sys.exit(0)

meta = data.get("metadata") or {}
counts = meta.get("vulnerabilities")
if counts is None:
    print("UNPARSEABLE")
    sys.exit(0)

total = counts.get("total", 0)
rows = []
for name, info in sorted((data.get("vulnerabilities") or {}).items()):
    severity = info.get("severity", "?")
    via = info.get("via") or []
    title = ""
    for entry in via:
        if isinstance(entry, dict) and entry.get("title"):
            title = entry["title"]
            break
    rows.append(f"{severity:<9} {name}  {title[:70]}")
print(f"TOTAL={total}")
for row in rows:
    print(f"  {row}")
PY
)"

if [[ "$REPORT" == UNPARSEABLE* ]]; then
  ta_fail "npm audit produced no parseable report — the registry was probably unreachable:"
  sed -n '1,5p' "$TA_TMPDIR/audit-prod.err" | sed 's/^/    /' >&2
  ta_fail "run with network, or skip deliberately: GOLDEN_SKIP_GATES=prod-dependency-audit"
else
  TOTAL="$(grep -oE 'TOTAL=[0-9]+' <<< "$REPORT" | cut -d= -f2)"
  if [[ "${TOTAL:-0}" -eq 0 ]]; then
    ta_pass "no advisories in the production dependency tree (npm audit --omit=dev)"
  else
    ta_fail "$TOTAL advisor$([[ "$TOTAL" -eq 1 ]] && echo 'y' || echo 'ies') in the production dependency tree:"
    sed -n '2,$p' <<< "$REPORT" | sed 's/^/    /' >&2
  fi
fi

echo "$TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]]
