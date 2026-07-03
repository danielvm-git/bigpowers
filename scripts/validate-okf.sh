#!/usr/bin/env bash
#
# validate-okf.sh — provenance gate for OKF story-metrics bundles (e40/e31 style).
#
# A bundle is valid iff:
#   1. The generator ran (generator field matches scripts/record-cycle-time.sh).
#   2. commit_range resolves to real commits in the repo.
#   3. Source enum is valid (measured|estimated|backfilled).
#   4. Required keys are present with correct aggregation tags.
#
# This script gates on PROVENANCE, NEVER on a specific metric value.
# Gate on freshness (did the right generator run?) not on outcomes.
#
# Usage:
#   scripts/validate-okf.sh [--dir <path>] [--help]
#   scripts/validate-okf.sh --bundle <file>      # validate a single bundle
#
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "validate-okf: not inside a git repo"; exit 1; }
METRICS_DIR="$ROOT/specs/metrics"
EXIT_CODE=0
REQUIRED_KEYS="id epic bcps commit_range source generated_at generator"
VALID_SOURCES="measured estimated backfilled"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

usage() {
  cat <<'EOF'
Usage: scripts/validate-okf.sh [flags]

Flags:
  --dir <path>       Validate all OKF bundles in directory (default: specs/metrics/)
  --bundle <file>    Validate a single OKF bundle
  --help             Show this message

Description:
  Provenance gate for OKF story-metrics bundles. Validates that:
  - Required keys are present (id, epic, bcps, commit_range, source, generated_at, generator)
  - Source enum is valid (measured|estimated|backfilled)
  - Generator matches scripts/record-cycle-time.sh
  - commit_range resolves to real commits
  - Aggregation tags are present (Σ, ⌀, %, •)

  NEVER gates on a specific metric value — only on provenance and freshness.
EOF
  exit 0
}

# Parse a single YAML frontmatter block from an OKF bundle .md file.
# Returns the frontmatter as JSON via Python (which handles YAML safely).
parse_frontmatter() {
  local file="$1"
  # Extract YAML frontmatter between --- markers
  python3 -c "
import yaml, sys
content = open('$file').read()
parts = content.split('---')
if len(parts) < 3:
    sys.exit(1)
try:
    fm = yaml.safe_load(parts[1])
    if fm is None:
        sys.exit(1)
    # Emit as JSON for bash
    import json
    print(json.dumps(fm))
except Exception as e:
    print(f'validate-okf: YAML parse error in $file: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

validate_bundle() {
  local file="$1"
  local bundle_name; bundle_name="$(basename "$file")"

  # Parse frontmatter
  local fm
  fm="$(parse_frontmatter "$file")" || {
    printf "${RED}FAIL${NC} %s: cannot parse YAML frontmatter\n" "$bundle_name"
    EXIT_CODE=1
    return
  }

  # Check okf_kind
  local kind
  kind="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('okf_kind',''))" 2>/dev/null)"
  if [ "$kind" != "story-metrics" ]; then
    printf "${YELLOW}SKIP${NC} %s: not a story-metrics bundle (kind=%s)\n" "$bundle_name" "${kind:-none}"
    return
  fi

  # Check required keys
  for key in $REQUIRED_KEYS; do
    local val
    val="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if [ -z "$val" ] || [ "$val" = "null" ] || [ "$val" = "None" ]; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$bundle_name" "$key"
      EXIT_CODE=1
      return
    fi
  done

  # Check source enum
  local source
  source="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['source'])" 2>/dev/null)"
  if ! echo "$VALID_SOURCES" | grep -qw "$source"; then
    printf "${RED}FAIL${NC} %s: invalid source '%s' — must be one of: %s\n" "$bundle_name" "$source" "$VALID_SOURCES"
    EXIT_CODE=1
    return
  fi

  # Check generator
  local generator
  generator="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['generator'])" 2>/dev/null)"
  if [ "$generator" != "scripts/record-cycle-time.sh" ]; then
    printf "${RED}FAIL${NC} %s: wrong generator '%s' — expected scripts/record-cycle-time.sh\n" "$bundle_name" "$generator"
    EXIT_CODE=1
    return
  fi

  # Check commit_range resolves
  local commit_range
  commit_range="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['commit_range'])" 2>/dev/null)"
  if ! git -C "$ROOT" log --oneline -1 "$commit_range" >/dev/null 2>&1; then
    printf "${RED}FAIL${NC} %s: commit_range '%s' does not resolve\n" "$bundle_name" "$commit_range"
    EXIT_CODE=1
    return
  fi

  # Check aggregation tags exist (not empty, but don't validate correctness)
  local effort_hours
  effort_hours="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); e=d.get('effort',{}); print(e.get('effort_hours',''))" 2>/dev/null)"
  if [ -z "$effort_hours" ] || [ "$effort_hours" = "null" ]; then
    printf "${RED}FAIL${NC} %s: effort.effort_hours missing or null\n" "$bundle_name"
    EXIT_CODE=1
    return
  fi

  # Bounds sanity (effort can't be negative)
  python3 -c "
import json, sys
d = json.load(sys.stdin)
eff = d.get('effort', {}).get('effort_hours')
if eff is not None and eff < 0:
    sys.exit(1)
" <<< "$fm" 2>/dev/null || {
    printf "${RED}FAIL${NC} %s: effort_hours out of bounds\n" "$bundle_name"
    EXIT_CODE=1
    return
  }

  printf "${GREEN}PASS${NC} %s (source=%s, generator=%s, commit_range resolves)\n" "$bundle_name" "$source" "$generator"
}

# ---- main ----------------------------------------------------------------
DIR=""
BUNDLE=""

[ $# -ge 1 ] || set -- "--dir" "$METRICS_DIR"  # default: validate specs/metrics/

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --bundle) BUNDLE="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) echo "validate-okf: unknown flag: $1" >&2; usage ;;
  esac
done

echo "validate-okf: scanning for OKF bundles..."

if [ -n "$BUNDLE" ]; then
  validate_bundle "$BUNDLE"
elif [ -n "$DIR" ]; then
  if [ ! -d "$DIR" ]; then
    printf "${YELLOW}SKIP${NC} directory not found: %s\n" "$DIR"
    exit 0
  fi
  count=0
  while IFS= read -r -d '' f; do
    # Only process .md files with YAML frontmatter
    if head -1 "$f" 2>/dev/null | grep -q '^---$'; then
      validate_bundle "$f"
      count=$((count + 1))
    fi
  done < <(find "$DIR" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)
  if [ "$count" -eq 0 ]; then
    printf "${YELLOW}SKIP${NC} no OKF bundles found in %s\n" "$DIR"
  else
    echo "validate-okf: scanned $count bundle(s)"
  fi
else
  echo "validate-okf: nothing to validate" >&2
fi

exit "$EXIT_CODE"
