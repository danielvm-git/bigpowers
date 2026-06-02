#!/usr/bin/env bash
# validate-specs-yaml.sh — required keys for state, release-plan, execution-status
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="${1:-$REPO_ROOT/specs}"

err=0
need() {
  local file="$1" pattern="$2" msg="$3"
  if [[ ! -f "$file" ]]; then
    echo "missing: $file"
    err=1
    return
  fi
  if ! grep -qE "$pattern" "$file"; then
    echo "$file: $msg"
    err=1
  fi
}

need "$SPECS/state.yaml" '^active_flow:' 'missing active_flow'
need "$SPECS/release-plan.yaml" '^release:' 'missing release block'
need "$SPECS/release-plan.yaml" 'version:' 'missing release.version'
need "$SPECS/release-plan.yaml" '^epics:' 'missing epics list'
need "$SPECS/execution-status.yaml" '^development_status:' 'missing development_status'

if [[ -f "$SPECS/release-plan.yaml" ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    path="$SPECS/$f"
    if [[ ! -f "$path" ]]; then
      echo "release-plan: missing epic file $path"
      err=1
    fi
  done < <(grep -E '^\s+file:' "$SPECS/release-plan.yaml" | sed 's/.*file:[[:space:]]*//')
fi

if [[ "$err" -ne 0 ]]; then
  exit 1
fi
echo "validate-specs-yaml: OK"
