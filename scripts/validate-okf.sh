#!/usr/bin/env bash
# story: e38s09
# validate-okf.sh — kind-aware, fail-closed provenance gate for OKF bundles.
# Validates story-metrics, spec-migration, and migration-registry bundles.
# Multi-dir default: specs/metrics/ + specs/migrations/.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "validate-okf: not inside a git repo"; exit 1; }
EXIT_CODE=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

usage_okf() {
  cat <<'EOF'
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
EOF
  exit 0
}

# ---- Helpers ------------------------------------------------------------

# True if value is empty, null JSON literal, or Python None string.
val_nullish() { [ -z "$1" ] || [ "$1" = "null" ] || [ "$1" = "None" ]; }

# True if value is nullish OR the JSON empty array literal.
val_nullish_or_empty() { val_nullish "$1" || [ "$1" = "[]" ]; }

# ---- YAML frontmatter parser (datetime-safe) ---------------------------
parse_frontmatter() {
  local file="$1"
  python3 -c "
import yaml, sys, json

class SafeEncoder(json.JSONEncoder):
    def default(self, obj):
        try:
            return super().default(obj)
        except TypeError:
            return str(obj)

content = open('$file').read()
parts = content.split('---')
if len(parts) < 3:
    sys.exit(1)
try:
    fm = yaml.safe_load(parts[1])
    if fm is None:
        sys.exit(1)
    print(json.dumps(fm, cls=SafeEncoder))
except Exception as e:
    print(f'YAML parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

# ---- Kind-specific validators ------------------------------------------

validate_story_metrics() {
  local file="$1" fm="$2" name="$3"
  local errs=0

  for key in id epic bcps commit_range source generated_at generator; do
    local val
    val="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }

  # Source enum
  local source
  source="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('source',''))" 2>/dev/null)"
  if ! echo "measured estimated backfilled" | grep -qw "$source"; then
    printf "${RED}FAIL${NC} %s: invalid source '%s' — must be measured|estimated|backfilled\n" "$name" "$source"
    EXIT_CODE=1; return
  fi

  # Generator
  local generator
  generator="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('generator',''))" 2>/dev/null)"
  if [ "$generator" != "scripts/record-cycle-time.sh" ]; then
    printf "${RED}FAIL${NC} %s: wrong generator '%s' — expected scripts/record-cycle-time.sh\n" "$name" "$generator"
    EXIT_CODE=1; return
  fi

  # commit_range resolves
  local commit_range
  commit_range="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('commit_range',''))" 2>/dev/null)"
  if ! git -C "$ROOT" log --oneline -1 "$commit_range" >/dev/null 2>&1; then
    printf "${RED}FAIL${NC} %s: commit_range '%s' does not resolve\n" "$name" "$commit_range"
    EXIT_CODE=1; return
  fi

  # effort.effort_hours present and non-negative
  local eff
  eff="$(echo "$fm" | python3 -c "
import json,sys
d=json.load(sys.stdin)
e=d.get('effort',{}).get('effort_hours')
if e is None: sys.exit(1)
if e < 0: sys.exit(2)
print(e)
" 2>/dev/null)" || {
    local rc=$?
    if [ "$rc" -eq 1 ]; then
      printf "${RED}FAIL${NC} %s: effort.effort_hours missing or null\n" "$name"
    else
      printf "${RED}FAIL${NC} %s: effort_hours out of bounds\n" "$name"
    fi
    EXIT_CODE=1; return
  }

  printf "${GREEN}PASS${NC} %s (source=%s, generator=%s, commit_range resolves)\n" "$name" "$source" "$generator"
}

validate_spec_migration() {
  local file="$1" fm="$2" name="$3"
  local errs=0

  for key in id title since_version order actions_needed; do
    local val
    val="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish_or_empty "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }

  # fingerprint.any has at least one check
  local fp_count
  fp_count="$(echo "$fm" | python3 -c "
import json,sys
d=json.load(sys.stdin)
fp=d.get('fingerprint',{}).get('any',[])
print(len(fp))
" 2>/dev/null)"
  if [ "${fp_count:-0}" -eq 0 ]; then
    printf "${RED}FAIL${NC} %s: fingerprint.any is empty — no detection criteria\n" "$name"
    EXIT_CODE=1; return
  fi

  printf "${GREEN}PASS${NC} %s (actions=%s, fingerprint has %s check(s))\n" \
    "$name" \
    "$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('actions_needed',[])))" 2>/dev/null)" \
    "$fp_count"
}

validate_migration_registry() {
  local file="$1" fm="$2" name="$3"

  local count
  count="$(echo "$fm" | python3 -c "
import json,sys
d=json.load(sys.stdin)
migrations=d.get('migrations',[])
print(len(migrations))
" 2>/dev/null)"
  if [ "${count:-0}" -eq 0 ]; then
    printf "${RED}FAIL${NC} %s: migrations list is empty\n" "$name"
    EXIT_CODE=1; return
  fi

  # Check each migration has id + file + status
  local bad
  bad="$(echo "$fm" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for m in d.get('migrations',[]):
    if not all(k in m for k in ('id','file','status')):
        print(m.get('id','?')); sys.exit(1)
" 2>/dev/null)" || {
    printf "${RED}FAIL${NC} %s: migration '%s' missing id/file/status\n" "$name" "${bad:-?}"
    EXIT_CODE=1; return
  }

  printf "${GREEN}PASS${NC} %s (%s migrations indexed)\n" "$name" "$count"
}

# ---- Receipts validation (e41s04) ----------------------------------------
validate_receipts() {
  local f="$ROOT/specs/receipts.json"
  if [ ! -f "$f" ]; then printf "${YELLOW}SKIP${NC} receipts.json not found\n"; return; fi
  python3 -c "
import json, sys
d=json.load(open('$f'))
vs={'measured','estimated','backfilled','absent'}
ss=('compliance','golden_suite','metrics','traceability')
errs=0
for sec in ss:
    data=d.get(sec)
    if data is None: continue
    src=data.get('source','')
    if not src: print(f'FAIL: receipts.json — {sec}: missing source tag'); errs+=1; continue
    if src not in vs: print(f'FAIL: receipts.json — {sec}: unknown source \"{src}\"'); errs+=1; continue
    hv='value' in data
    if src=='absent' and hv: print(f'FAIL: receipts.json — {sec}: tagged absent but carries value'); errs+=1
    elif src!='absent' and not hv: print(f'FAIL: receipts.json — {sec}: tagged {src} but missing value'); errs+=1
if errs==0: print('PASS receipts.json')
else: print(f'{errs} violation(s) in receipts.json')
sys.exit(errs)
" || { EXIT_CODE=1; return; }
}

# ---- Main validation dispatcher ----------------------------------------
validate_bundle() {
  local file="$1"
  local name; name="$(basename "$file")"

  local fm
  fm="$(parse_frontmatter "$file")" || {
    printf "${RED}FAIL${NC} %s: cannot parse YAML frontmatter\n" "$name"
    EXIT_CODE=1
    return
  }

  local kind
  kind="$(echo "$fm" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('okf_kind',''))" 2>/dev/null)"

  case "$kind" in
    story-metrics)       validate_story_metrics "$file" "$fm" "$name" ;;
    spec-migration)      validate_spec_migration "$file" "$fm" "$name" ;;
    migration-registry)  validate_migration_registry "$file" "$fm" "$name" ;;
    "")
      printf "${YELLOW}SKIP${NC} %s: no okf_kind — not an OKF bundle\n" "$name"
      ;;
    *)
      printf "${YELLOW}SKIP${NC} %s: unknown okf_kind '%s'\n" "$name" "$kind"
      ;;
  esac
}

# ---- Scan directory ----------------------------------------------------
scan_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    printf "${RED}FAIL${NC} directory not found: %s\n" "$dir"
    EXIT_CODE=1
    return
  fi
  local count=0
  while IFS= read -r -d '' f; do
    if head -1 "$f" 2>/dev/null | grep -q '^---$'; then
      validate_bundle "$f"
      count=$((count + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -name '*.md' -print0 2>/dev/null || true)
  if [ "$count" -eq 0 ]; then
    printf "${YELLOW}SKIP${NC} no OKF bundles found in %s\n" "$dir"
  fi
}

# ---- main ----------------------------------------------------------------
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
    *)
      echo "validate-okf: unknown flag: $1" >&2
      echo "Run 'scripts/validate-okf.sh --help' for help." >&2
      exit 2
      ;;
  esac
done

echo "validate-okf: scanning for OKF bundles..."

if [ -n "$BUNDLE" ]; then
  if [ ! -f "$BUNDLE" ]; then
    printf "${RED}FAIL${NC} bundle not found: %s\n" "$BUNDLE"
    exit 1
  fi
  validate_bundle "$BUNDLE"
elif [ ${#DIRS[@]} -gt 0 ]; then
  for d in "${DIRS[@]}"; do
    scan_dir "$d"
  done
else
  echo "validate-okf: nothing to validate (no --dir or --bundle)" >&2
  exit 1
fi

# e41s04: always validate receipts.json
validate_receipts

exit "$EXIT_CODE"
