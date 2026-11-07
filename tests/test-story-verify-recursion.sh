#!/usr/bin/env bash
# story: e83s04
# A done story whose verify calls run-story-verify.sh must FAIL fast, never recurse.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/specs/epics/e99-fixture"
cat > "$T/specs/epics/e99-fixture/epic.yaml" <<'YAML'
id: e99
stories:
- id: e99s01
  status: done
  verify: bash scripts/run-story-verify.sh e99s01
YAML
out=$(cd "$ROOT" && EXTRACT_ROOT="$T" perl -e 'alarm 60; exec @ARGV' bash scripts/run-story-verify.sh e99s01 </dev/null 2>&1) && rc=0 || rc=$?
[[ $rc -ne 0 ]] || { echo "FAIL: self-referential verify passed"; exit 1; }
grep -q 'self-referential' <<<"$out" || { echo "FAIL: no clear message: $out"; exit 1; }
echo "PASS"
