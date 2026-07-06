#!/usr/bin/env bash
# story: e38s09 e45s02
# validate-okf.sh — kind-aware, fail-closed provenance gate for OKF bundles.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/validate-okf-kinds.sh"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "validate-okf: not inside a git repo"; exit 1; }
EXIT_CODE=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

usage_okf() {
  cat <<'USAGEEOF'
Usage: scripts/validate-okf.sh [flags]

Flags:
  --dir <path>       Validate all OKF bundles in directory
  --bundle <file>    Validate a single OKF bundle
  --help             Show this message

Description:
  Kind-aware provenance gate for OKF bundles. Without flags, validates all
  bundles in specs/metrics/ AND specs/migrations/. NEVER gates on a specific
  metric value — only on provenance and schema conformance.

  OKF kinds validated:
    story-metrics       — effort/lead-time provenance (e40)
    spec-migration      — migration bundle schema (e44)
    migration-registry  — registry index integrity (e44)
    concept             — domain concept / wiki entry (e45)
    verification-report — compliance/golden suite gate report (e45)
USAGEEOF
  exit 0
}

DIRS=()
BUNDLE=""

if [ $# -eq 0 ]; then
  DIRS=("$ROOT/specs/metrics" "$ROOT/specs/migrations")
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     DIRS+=("$2"); shift 2 ;;
    --bundle)  BUNDLE="$2"; shift 2 ;;
    --help|-h) usage_okf ;;
    *)         echo "validate-okf: unknown flag: $1" >&2; exit 2 ;;
  esac
done

echo "validate-okf: scanning for OKF bundles..."

if [ -n "$BUNDLE" ]; then
  [ ! -f "$BUNDLE" ] && { printf "${RED}FAIL${NC} bundle not found: %s\n" "$BUNDLE"; exit 1; }
  validate_bundle "$BUNDLE"
elif [ ${#DIRS[@]} -gt 0 ]; then
  for d in "${DIRS[@]}"; do okf_scan_dir "$d"; done
else
  echo "validate-okf: nothing to validate (no --dir or --bundle)" >&2
  exit 1
fi

validate_receipts
exit "$EXIT_CODE"
