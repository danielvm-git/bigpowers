#!/usr/bin/env bash
# story: e45s10
# Regenerate docs/references from SSOT sources (see scripts/references-manifest.yaml).
# Schedule: weekly via .github/workflows/sync-references.yml; also safe to run locally.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/scripts/references-manifest.yaml"
STAMP_FILE="$REPO_ROOT/docs/references/.sync-stamp"

cd "$REPO_ROOT"
[[ -f "$MANIFEST" ]] || { echo "sync-references: missing manifest" >&2; exit 1; }

run_generator() {
  local gen="$1"
  [[ -x "$REPO_ROOT/$gen" || -f "$REPO_ROOT/$gen" ]] || { echo "sync-references: generator not found: $gen" >&2; exit 1; }
  bash "$REPO_ROOT/$gen"
}

# model-profiles catalog
run_generator scripts/generate-reference-tables.sh
run_generator scripts/lib/sync-context-engineering-ref.sh

date -u +%Y-%m-%dT%H:%M:%SZ > "$STAMP_FILE"
echo "sync-references: OK (stamp $(cat "$STAMP_FILE"))"
