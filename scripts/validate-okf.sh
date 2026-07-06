#!/usr/bin/env bash
# story: e38s09 e45s02
# validate-okf.sh — kind-aware, fail-closed provenance gate for OKF bundles.
# Validates story-metrics, spec-migration, migration-registry, concept,
# and verification-report bundles.
# Multi-dir default: specs/metrics/ + specs/migrations/.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

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

# ---- Helpers ------------------------------------------------------------

val_nullish() { [ -z "$1" ] || [ "$1" = "null" ] || [ "$1" = "None" ]; }
val_nullish_or_empty() { val_nullish "$1" || [ "$1" = "[]" ]; }

parse_frontmatter() {
  local file="$1"
  $PYTHON -c "
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
    val="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }

  local source
  source="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('source',''))" 2>/dev/null)"
  if ! echo "measured estimated backfilled" | grep -qw "$source"; then
    printf "${RED}FAIL${NC} %s: invalid source '%s' — must be measured|estimated|backfilled\n" "$name" "$source"
    EXIT_CODE=1; return
  fi

  local generator
  generator="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('generator',''))" 2>/dev/null)"
  if [ "$generator" != "scripts/record-cycle-time.sh" ]; then
    printf "${RED}FAIL${NC} %s: wrong generator '%s' — expected scripts/record-cycle-time.sh\n" "$name" "$generator"
    EXIT_CODE=1; return
  fi

  local commit_range
  commit_range="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('commit_range',''))" 2>/dev/null)"
  if ! git -C "$ROOT" log --oneline -1 "$commit_range" >/dev/null 2>&1; then
    printf "${RED}FAIL${NC} %s: commit_range '%s' does not resolve\n" "$name" "$commit_range"
    EXIT_CODE=1; return
  fi

  local eff
  eff="$(echo "$fm" | $PYTHON -c "
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
    val="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish_or_empty "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }

  local fp_count
  fp_count="$(echo "$fm" | $PYTHON -c "
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
    "$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('actions_needed',[])))" 2>/dev/null)" \
    "$fp_count"
}

validate_migration_registry() {
  local file="$1" fm="$2" name="$3"
  local count
  count="$(echo "$fm" | $PYTHON -c "
import json,sys
d=json.load(sys.stdin)
migrations=d.get('migrations',[])
print(len(migrations))
" 2>/dev/null)"
  if [ "${count:-0}" -eq 0 ]; then
    printf "${RED}FAIL${NC} %s: migrations list is empty\n" "$name"
    EXIT_CODE=1; return
  fi

  local bad
  bad="$(echo "$fm" | $PYTHON -c "
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

# ---- Concept validator (e45s02) ----
validate_concept() {
  local file="$1" fm="$2" name="$3"
  local errs=0
  for key in id title category; do
    local val
    val="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  local ref_count
  ref_count="$(echo "$fm" | $PYTHON -c "
import json,sys
d=json.load(sys.stdin)
r=d.get('references',[])
print(len(r) if isinstance(r,list) else 0)
" 2>/dev/null)"
  if [ "${ref_count:-0}" -eq 0 ]; then
    printf "${RED}FAIL${NC} %s: references[] is empty or missing\n" "$name"
    errs=$((errs + 1))
  fi
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }
  local cat
  cat="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('category',''))" 2>/dev/null)"
  printf "${GREEN}PASS${NC} %s (category=%s, %s reference(s))\n" "$name" "$cat" "$ref_count"
}

# ---- Verification-report validator (e45s02) ----
validate_verification_report() {
  local file="$1" fm="$2" name="$3"
  local errs=0
  for key in score gate_status threshold total_pass total_fail generated_by; do
    local val
    val="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null)"
    if val_nullish "$val"; then
      printf "${RED}FAIL${NC} %s: missing required key '%s'\n" "$name" "$key"
      errs=$((errs + 1))
    fi
  done
  [ "$errs" -gt 0 ] && { EXIT_CODE=1; return; }

  local gs
  gs="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('gate_status',''))" 2>/dev/null)"
  if ! echo "pass fail concerns waived" | grep -qw "$gs"; then
    printf "${RED}FAIL${NC} %s: invalid gate_status '%s' — must be pass|fail|concerns|waived\n" "$name" "$gs"
    EXIT_CODE=1; return
  fi

  local score
  score="$(echo "$fm" | $PYTHON -c "
import json,sys
d=json.load(sys.stdin)
s=d.get('score')
if s is None or not isinstance(s,(int,float)):
    sys.exit(1)
if s < 0 or s > 100:
    sys.exit(2)
print(s)
" 2>/dev/null)" || {
    local rc=$?
    if [ "$rc" -eq 1 ]; then
      printf "${RED}FAIL${NC} %s: score missing or not numeric\n" "$name"
    else
      printf "${RED}FAIL${NC} %s: score out of bounds (0-100)\n" "$name"
    fi
    EXIT_CODE=1; return
  }

  printf "${GREEN}PASS${NC} %s (score=%.1f, gate=%s, threshold=%.1f)\n" \
    "$name" "$score" "$gs" \
    "$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('threshold',0))" 2>/dev/null)"
}

# ---- Receipts validation (e41s04) ----
validate_receipts() {
  local f="$ROOT/specs/receipts.json"
  if [ ! -f "$f" ]; then printf "${YELLOW}SKIP${NC} receipts.json not found\n"; return; fi
  $PYTHON -c "
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

# ---- Main validation dispatcher ----
validate_bundle() {
  local file="$1"
  local name; name="$(basename "$file")"
  local fm
  fm="$(parse_frontmatter "$file")" || {
    printf "${RED}FAIL${NC} %s: cannot parse YAML frontmatter\n" "$name"
    EXIT_CODE=1
    return
  }

  # ── OKF v0.1 Generic Frontmatter Conformance (e39s10) ──
  # Check required 'type' field
  local fm_type
  fm_type="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('type',''))" 2>/dev/null)"
  if [ -z "$fm_type" ]; then
    printf "${RED}FAIL${NC} %s: OKF v0.1 — missing required 'type' field\n" "$name"
    EXIT_CODE=1
    return
  fi

  # Reserved filenames: index.md must have type: Index
  if [ "$name" = "index.md" ] && [ "$fm_type" != "Index" ]; then
    printf "${RED}FAIL${NC} %s: OKF v0.1 — index.md must have type: Index (got '%s')\n" "$name" "$fm_type"
    EXIT_CODE=1
    return
  fi

  local kind
  kind="$(echo "$fm" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('okf_kind',''))" 2>/dev/null)"
  case "$kind" in
    story-metrics)       validate_story_metrics "$file" "$fm" "$name" ;;
    spec-migration)      validate_spec_migration "$file" "$fm" "$name" ;;
    migration-registry)  validate_migration_registry "$file" "$fm" "$name" ;;
    concept)             validate_concept "$file" "$fm" "$name" ;;
    verification-report) validate_verification_report "$file" "$fm" "$name" ;;
    "")
      printf "${YELLOW}SKIP${NC} %s: no okf_kind — not an OKF bundle\n" "$name"
      ;;
    *)
      printf "${YELLOW}SKIP${NC} %s: unknown okf_kind '%s'\n" "$name" "$kind"
      ;;
  esac
}

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

# ---- main ----
DIRS=()
BUNDLE=""
STAMPLINE="# e45s02 stamp -- concept and verification-report validators added"

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
  for d in "${DIRS[@]}"; do scan_dir "$d"; done
else
  echo "validate-okf: nothing to validate (no --dir or --bundle)" >&2
  exit 1
fi

validate_receipts
exit "$EXIT_CODE"
