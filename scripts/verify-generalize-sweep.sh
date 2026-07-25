#!/usr/bin/env bash
# story: e80s04
# Validates generalize-fix sweep artifact exists and has required fields.
# Usage:
#   bash scripts/verify-generalize-sweep.sh [--self-test]
#   bash scripts/verify-generalize-sweep.sh specs/verifications/generalize-sweep-BUG-*.json
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

validate_artifact() {
  local file="$1"
  [[ -f "$file" ]] || { echo "FAIL: missing $file"; return 1; }
  grep -q '"defect_class"' "$file" || { echo "FAIL: $file missing defect_class"; return 1; }
  grep -q '"grep_pattern"' "$file" || { echo "FAIL: $file missing grep_pattern"; return 1; }
  grep -q '"match_count"' "$file" || { echo "FAIL: $file missing match_count"; return 1; }
  echo "PASS: $file"
}

self_test() {
  local dir="$REPO_ROOT/specs/verifications/fixtures"
  mkdir -p "$dir"
  local sample="$dir/generalize-sweep-selftest.json"
  cat > "$sample" <<'JSON'
{
  "defect_class": "fail-open-verify",
  "grep_pattern": "|| echo",
  "match_count": 0,
  "sweep_scope": "skills/*/SKILL.md",
  "notes": "self-test fixture for verify-generalize-sweep.sh"
}
JSON
  validate_artifact "$sample"
  grep -q 'generalize-fix' skills/validate-fix/SKILL.md
  echo "verify-generalize-sweep: self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

if [[ $# -gt 0 ]]; then
  for f in "$@"; do validate_artifact "$f"; done
  exit 0
fi

shopt -s nullglob
artifacts=(specs/verifications/generalize-sweep-*.json)
if [[ ${#artifacts[@]} -eq 0 ]]; then
  echo "FAIL: no specs/verifications/generalize-sweep-*.json artifact (generalize-fix not evidenced)"
  exit 1
fi
for f in "${artifacts[@]}"; do validate_artifact "$f"; done
