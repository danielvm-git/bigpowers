#!/usr/bin/env bash
# check-spec-version-gap.sh — detect spec format gap (e44s02)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: check-spec-version-gap.sh [--help] [--project <dir>] [--json]
Exit codes: 0=no gap, 1=gap, 2=no specs, 3=blocked, 4=error
EOF
  exit 0
}

PROJECT_DIR="."
JSON_STDOUT=false
SKIP_BLOCK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage ;;
    --project) PROJECT_DIR="${2:?}"; shift 2 ;;
    --json) JSON_STDOUT=true; shift ;;
    --skip-block) SKIP_BLOCK=true; shift ;;
    *) echo "unknown: $1" >&2; exit 4 ;;
  esac
done

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "bad dir: $PROJECT_DIR" >&2; exit 4; }
SPECS="$PROJECT_DIR/specs"

emit_json() {
  if $JSON_STDOUT; then echo "$1"; else echo "$1" >&2; fi
}

get_installed_version() {
  python3 -c "import json; d=json.load(open('$BP_ROOT/package.json')); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown"
}

yaml_get() {
  [[ ! -f "$1" ]] && { echo ""; return; }
  python3 -c "
import sys, yaml
d = yaml.safe_load(open('$1')) or {}
parts = '$2'.split('.')
cur = d
for p in parts:
    if isinstance(cur, dict): cur = cur.get(p)
    else: print(''); sys.exit(0)
print('' if cur is None else cur)
" 2>/dev/null
}

version_lt() {
  if [[ "$1" == "$2" ]]; then return 1; fi
  local IFS=.; local a=($1) b=($2)
  for i in "${!a[@]}"; do
    local av="${a[$i]:-0}" bv="${b[$i]:-0}"
    if (( av < bv )); then return 0; fi
    if (( av > bv )); then return 1; fi
  done
  return 1
}

find_migrations() {
  local ver="$1" reg="$BP_ROOT/specs/migrations/registry.okf.md"
  [[ ! -f "$reg" ]] && { echo "[]"; return; }
  python3 -c "
import json, yaml
def vt(v): return tuple(int(p) if p.isdigit() else 0 for p in v.lstrip('v').split('.')[:3])
dt = vt('$ver')
c = open('$reg').read()
parts = c.split('---')
fm = yaml.safe_load(parts[1]) if len(parts) >= 3 else {}
out = []
for m in fm.get('migrations', []):
    if m.get('status') not in ('implemented','planned'): continue
    st = vt(m.get('since_version','0'))
    if dt < st:
        out.append({'id': m['id'], 'since_version': m['since_version'], 'order': m.get('order',0), 'depends_on': m.get('depends_on',[]), 'actions_needed': m.get('actions_needed',[]), 'status': m.get('status','')})
print(json.dumps(out))
" 2>/dev/null
}

check_active_work() {
  local branch; branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")
  if [[ -n "$branch" && "$branch" != "main" && "$branch" != "master" ]]; then echo "true"; return; fi
  if [[ -d "$SPECS" ]] && git -C "$PROJECT_DIR" status --porcelain -- specs/ 2>/dev/null | grep -q .; then echo "true"; return; fi
  local af; af=$(yaml_get "$SPECS/state.yaml" "active_flow")
  if [[ -n "$af" && "$af" != "null" && "$af" != "None" ]]; then
    case "$af" in build_epic|develop_tdd|fix_bug) echo "true"; return ;; esac
  fi
  echo "false"
}

# Main
[[ ! -d "$SPECS" ]] && { emit_json '{"gap":false,"reason":"NO_SPECS"}'; exit 2; }
IV=$(get_installed_version)
if [ "$SKIP_BLOCK" != "true" ] && [[ "$(check_active_work)" == "true" ]]; then
  emit_json '{"gap":true,"blocked":true,"reason":"ACTIVE_WORK","installed_version":"'"$IV"'"}'
  exit 3
fi

SV=$(yaml_get "$SPECS/state.yaml" "bigpowers_version")

if [[ -n "$SV" && "$SV" != "null" && "$SV" != "None" ]]; then
  if [[ "$SV" == "$IV" ]]; then
    emit_json '{"gap":false,"stamp":true,"detected_version":"'"$SV"'","installed_version":"'"$IV"'","detection_method":"stamp","confidence":"high"}'
    exit 0
  fi
  APP=$(find_migrations "$SV")
  CNT=$(echo "$APP" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
  emit_json "$(python3 -c "import json; a=json.loads('''$APP'''); print(json.dumps({'gap':True,'stamp':True,'detected_version':'$SV','detection_method':'stamp','installed_version':'$IV','applicable_migrations':len(a),'migration_ids':[m['id'] for m in a],'confidence':'high','active_work_blocked':False}))")"
  exit 1
fi

# Fingerprint
DV=""; CONF="medium"; MARKERS=()
[[ -f "$SPECS/STATE.md" ]] && { DV="1.0.0"; CONF="high"; MARKERS+=("STATE.md"); }
[[ -f "$SPECS/state.yaml" ]] && { [[ -z "$DV" ]] && { DV="2.0.0"; MARKERS+=("state.yaml"); } || MARKERS+=("state.yaml (dual-era)"); }
for f in release-plan.yaml execution-status.yaml product/SCOPE_LATEST.yaml metrics/cycle-times.yaml; do
  [[ -f "$SPECS/$f" ]] && { MARKERS+=("$f"); [[ -z "$DV" ]] && DV="2.0.0"; }
done
if [[ -f "$SPECS/state.yaml" ]]; then
  ec=$(yaml_get "$SPECS/state.yaml" "epic_cycle.current_step")
  if [[ -n "$ec" && "$ec" != "null" && "$ec" != "None" ]]; then
    MARKERS+=("epic_cycle"); [[ "$DV" == "2.0.0" ]] && DV="2.20.0"
  fi
fi
if ls "$SPECS"/epics/*/epic.yaml 2>/dev/null | head -1 | grep -q .; then
  MARKERS+=("epic capsules"); [[ "$DV" == "2.0.0" ]] && DV="2.20.0"; [[ -z "$DV" ]] && DV="2.20.0"
fi
[[ -z "$DV" ]] && { DV="unknown"; CONF="low"; }

if [[ "$DV" != "unknown" ]] && ! version_lt "$DV" "$IV"; then
  [[ "$DV" == "$IV" ]] && { emit_json '{"gap":false,"stamp":false,"detected_version":"'"$DV"'","installed_version":"'"$IV"'","detection_method":"fingerprint","confidence":"'"$CONF"'"}'; exit 0; }
fi

APP=$(find_migrations "$DV")
CNT=$(echo "$APP" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
MJ=$(printf '%s\n' "${MARKERS[@]}" | python3 -c "import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))" 2>/dev/null || echo "[]")

emit_json "$(python3 -c "import json; a=json.loads('''$APP'''); m=json.loads('''$MJ'''); print(json.dumps({'gap':True,'stamp':False,'detected_version':'$DV','detection_method':'fingerprint','installed_version':'$IV','applicable_migrations':len(a),'migration_ids':[x['id'] for x in a],'confidence':'$CONF','active_work_blocked':False,'matched_markers':m}))")"
exit 1
