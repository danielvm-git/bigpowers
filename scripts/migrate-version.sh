#!/usr/bin/env bash
# story: e44s03 e44s04
# migrate-version.sh — one-shot ordered migration engine with triple safety net.
# Safety: (1) backup, (2) dry-run diff, (3) auto-commit.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIGPOWERS_ROOT="$REPO_ROOT"
YAML_TOOLS="$REPO_ROOT/scripts/yaml-tools.py"
SPECS_DIR="$REPO_ROOT/specs"
MIGRATIONS_DIR="$SPECS_DIR/migrations"
REGISTRY="$MIGRATIONS_DIR/registry.okf.md"
BACKUP_DIR="$SPECS_DIR/.pre-upgrade-backup"

DRY_RUN=false
FORCE=false
SKIP_COMMIT=false
VERBOSE=false
SUCCEEDED=()
FAILED=()
SKIPPED=()
STALE_FILES=()
UNCERTAINTY_COUNT=0

# ── usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage: scripts/migrate-version.sh [flags]

Flags:
  --help         Show this message
  --dry-run      Compose migration plan and show diff, but make no changes
  --force        Skip active-work block detection
  --no-commit    Skip auto-commit (still applies transforms and stamps)
  --verbose      Show detailed progress for each transform step
EOF
  exit 0
}

# ── helpers ───────────────────────────────────────────────────────────────
installed_version() {
  node -e "console.log(require('$BIGPOWERS_ROOT/package.json').version)" 2>/dev/null || echo "unknown"
}

yaml_get() {
  local file="$1" key="$2"
  $PYTHON -c "
import yaml, sys
try:
    d = yaml.safe_load(open('$file'))
    val = d
    for k in '$key'.split('.'):
        if not isinstance(val, dict): sys.exit(1)
        val = val.get(k)
    if val is None: sys.exit(1)
    print(val)
except: sys.exit(1)
" 2>/dev/null
}

log_info()  { echo "  [INFO] $*"; }
log_warn()  { echo "  [WARN] $*"; }
log_done()  { echo "  [OK] $*"; }
log_fail()  { echo "  [FAIL] $*"; }
log_skip()  { echo "  [SKIP] $*"; }

# ── argument parsing ──────────────────────────────────────────────────────
PROJECT_DIR=""

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --no-commit) SKIP_COMMIT=true ;;
    --verbose) VERBOSE=true ;;
    --project)
      # Next argument is the project dir
      ;;
    *)
      if [ "${PREV_ARG:-}" = "--project" ]; then
        PROJECT_DIR="$arg"
      else
        echo "migrate-version: unknown flag: $arg" >&2; exit 4
      fi
      ;;
  esac
  PREV_ARG="$arg"
done

# If --project given, override paths to target project; migrations remain in bigpowers
if [ -n "$PROJECT_DIR" ]; then
  REPO_ROOT="$PROJECT_DIR"
  SPECS_DIR="$REPO_ROOT/specs"
  BACKUP_DIR="$SPECS_DIR/.pre-upgrade-backup"
fi

# ── pre-flight: active-work block ─────────────────────────────────────────
if [ "$FORCE" != "true" ]; then
  branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)" || true
  if [ -n "${branch:-}" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
    echo "migrate-version: BLOCKED — on non-main branch '$branch'. Use --force to override." >&2
    exit 3
  fi
  if ! git -C "$REPO_ROOT" diff --quiet -- specs/ 2>/dev/null || \
     ! git -C "$REPO_ROOT" diff --cached --quiet -- specs/ 2>/dev/null; then
    echo "migrate-version: BLOCKED — uncommitted changes in specs/. Commit or stash first." >&2
    exit 3
  fi
  if [ -f "$SPECS_DIR/state.yaml" ]; then
    af="$(yaml_get "$SPECS_DIR/state.yaml" "active_flow" 2>/dev/null)" || true
    if [ -n "${af:-}" ] && [ "$af" != "null" ]; then
      echo "migrate-version: BLOCKED — active_flow '$af' is set (mid-epic work). Use --force." >&2
      exit 3
    fi
  fi
fi

# ── verify pre-conditions ─────────────────────────────────────────────────
if [ ! -d "$SPECS_DIR" ]; then
  echo "migrate-version: no specs/ directory found" >&2
  exit 2
fi
if [ ! -f "$REGISTRY" ]; then
  echo "migrate-version: migration registry not found at $REGISTRY" >&2
  exit 4
fi

INSTALLED="$(installed_version)"

# Detect version
DETECTED=""
if [ -f "$SPECS_DIR/state.yaml" ]; then
  stamped="$(yaml_get "$SPECS_DIR/state.yaml" "bigpowers_version" 2>/dev/null)" || true
  if [ -n "${stamped:-}" ] && [ "$stamped" != "null" ]; then
    DETECTED="$stamped"
  fi
fi
if [ -z "$DETECTED" ]; then
  if [ -f "$SPECS_DIR/STATE.md" ] && [ ! -f "$SPECS_DIR/state.yaml" ]; then
    DETECTED="1.0.0"
  elif [ -f "$SPECS_DIR/state.yaml" ]; then
    if yaml_get "$SPECS_DIR/state.yaml" "epic_cycle" >/dev/null 2>&1; then
      DETECTED="2.20.0"
    else
      DETECTED="2.0.0"
    fi
  else
    echo "migrate-version: cannot determine spec version" >&2
    exit 4
  fi
fi

echo "migrate-version: detected=$DETECTED installed=$INSTALLED"

if [ "$DETECTED" = "$INSTALLED" ]; then
  echo "migrate-version: no version gap — specs are current"
  exit 0
fi

# ── build migration plan ──────────────────────────────────────────────────
echo "migrate-version: building migration plan from $REGISTRY …"

MIGRATION_PLAN="$($PYTHON -c "
import yaml, json, sys

with open('$REGISTRY') as f:
    parts = f.read().split('---')
    fm = yaml.safe_load(parts[1])

detected = '$DETECTED'
installed = '$INSTALLED'

plan = []
for m in sorted(fm.get('migrations', []), key=lambda x: x.get('order', 99)):
    sid = m['id']
    since = m.get('since_version', '0')
    order = m.get('order', 99)
    deps = m.get('depends_on', [])
    plan.append({'id': sid, 'file': m.get('file', sid + '.okf.md'),
                 'since_version': since, 'order': order,
                 'depends_on': deps, 'title': m.get('title', sid)})

applicable = [m for m in plan if m['since_version'] > detected and m['since_version'] <= installed]
print(json.dumps(applicable))
" 2>/dev/null)"

MIGRATION_COUNT="$(echo "$MIGRATION_PLAN" | $PYTHON -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)"

if [ "${MIGRATION_COUNT:-0}" -eq 0 ]; then
  echo "migrate-version: no applicable migrations for $DETECTED → $INSTALLED — stamping version only"
fi

echo "migrate-version: $MIGRATION_COUNT migration(s) to apply"

if [ "$VERBOSE" = "true" ]; then
  echo "$MIGRATION_PLAN" | $PYTHON -c "
import json,sys
for m in json.load(sys.stdin):
    print(f\"  {m['order']}. {m['id']}: {m['title']} (since {m['since_version']})\")
"
fi

# ── Safety Layer 1: backup ────────────────────────────────────────────────
if [ "$DRY_RUN" != "true" ]; then
  log_info "Creating backup: $BACKUP_DIR"
  rm -rf "$BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp -r "$SPECS_DIR"/* "$BACKUP_DIR"/ 2>/dev/null || true
  rm -rf "$BACKUP_DIR/.pre-upgrade-backup" 2>/dev/null || true
fi

# ── Safety Layer 2: dry-run ───────────────────────────────────────────────
if [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "=========================================="
  echo "  DRY RUN — no changes will be made"
  echo "=========================================="
  echo ""
  echo "Detected version: $DETECTED"
  echo "Target version:   $INSTALLED"
  echo "Migrations:"
  echo "$MIGRATION_PLAN" | $PYTHON -c "
import json,sys
for m in json.load(sys.stdin):
    deps = m.get('depends_on', [])
    dep_str = ' (depends on: ' + ', '.join(deps) + ')' if deps else ''
    print(f\"  [{m['order']}] {m['id']}: {m['title']}{dep_str}\")
"

  echo ""
  echo "Transforms preview:"
  echo "$MIGRATION_PLAN" | $PYTHON -c "
import json, sys, os
for m in json.load(sys.stdin):
    bundle_path = os.path.join('$MIGRATIONS_DIR', m['file'])
    if not os.path.exists(bundle_path):
        print(f\"  WARN {m['id']}: bundle file not found ({m['file']})\")
        continue
    with open(bundle_path) as f:
        parts = f.read().split('---')
        fm = __import__('yaml').safe_load(parts[1])
    transforms = fm.get('transforms', [])
    print(f\"\n  -- {m['id']}: {m['title']} --\")
    for t in transforms:
        action = t.get('action', '?')
        note = t.get('note', '')
        note_str = f' ({note})' if note else ''
        if action == 'convert_md_to_yaml':
            src = t.get('source', '?')
            tgt = t.get('target', '?')
            unc = t.get('uncertainty', [])
            print(f\"  {action}: {src} -> {tgt}{note_str}\")
            for u in unc:
                print(f\"    GUESS: {u.get('field','?')} - {u.get('reason','?')}\")
        elif action in ('rename_file', 'move_file'):
            print(f\"  {action}: {t.get('source','?')} -> {t.get('target','?')}{note_str}\")
        elif action == 'delete_file':
            print(f\"  {action}: {t.get('path','?')}{note_str}\")
        elif action in ('set_yaml_key', 'rename_yaml_key', 'delete_yaml_key'):
            print(f\"  {action}: {t.get('file','?')} {t.get('key','?') or t.get('old_key','?')} = {t.get('value','?')}{note_str}\")
        elif action == 'create_file_from_template':
            print(f\"  {action}: {t.get('source','?')} -> {t.get('target','?')}{note_str}\")
        else:
            print(f\"  {action}{note_str}\")
    for a in fm.get('actions_needed', []):
        v = a.get('verify', '')
        if v: print(f\"  verify: {v}\")
" 2>/dev/null

  echo ""
  echo "Run without --dry-run to apply these migrations."
  exit 0
fi

# ── Apply phase ───────────────────────────────────────────────────────────
echo ""
echo "Applying migrations …"
SUCCEEDED=()
FAILED=()
SKIPPED=()
# Default empty values for subshell-safe access
SUCCEEDED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
UNCERTAINTY_COUNT=0

apply_transform() {
  local mig_id="$1" action="$2" tjson="$3"

  case "$action" in
    convert_md_to_yaml)
      local src tgt hm unc_count arch
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      arch="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('archive_source','false'))" 2>/dev/null)" || arch="false"
      if [ ! -f "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found"
        SKIPPED+=("$action:$src"); return
      fi
      hm="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('heuristic_map',{})))")"
      $PYTHON -c "
import json, re, yaml, sys, os
src = '$REPO_ROOT/$src'
tgt = '$REPO_ROOT/$tgt'
heuristic_map = json.loads('''$hm''')
content = open(src).read()
result = {}
for md_key, yaml_key in heuristic_map.items():
    pat = re.compile(r'^' + re.escape(md_key.rstrip(':')) + r'\\s*[:=]\\s*(.+)$', re.MULTILINE | re.IGNORECASE)
    m = pat.search(content)
    if m:
        val = m.group(1).strip()
        try: val = yaml.safe_load(val) or val
        except: pass
        parts = yaml_key.split('.')
        cur = result
        for p in parts[:-1]:
            if p not in cur or not isinstance(cur[p], dict):
                cur[p] = {}
            cur = cur[p]
        cur[parts[-1]] = val
os.makedirs(os.path.dirname(tgt), exist_ok=True)
with open(tgt, 'w') as f:
    yaml.safe_dump(result, f, sort_keys=False, allow_unicode=True, width=100)
"
      unc_count="$(echo "$tjson" | $PYTHON -c "import json,sys; print(len(json.load(sys.stdin).get('uncertainty',[])))")"
      UNCERTAINTY_COUNT=$((UNCERTAINTY_COUNT + unc_count))
      # Archive source file if requested
      if [ "$arch" = "true" ] || [ "$arch" = "True" ]; then
        local archive_dir="$REPO_ROOT/specs/archive"
        mkdir -p "$archive_dir"
        mv "$REPO_ROOT/$src" "$archive_dir/"
        log_done "$action: $src -> $tgt (source archived to specs/archive/)"
      else
        log_done "$action: $src -> $tgt"
      fi
      ;;

    rename_file)
      local src tgt
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      if [ ! -e "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      mv "$REPO_ROOT/$src" "$REPO_ROOT/$tgt"
      log_done "$action: $src -> $tgt"
      ;;

    move_file)
      local src tgt
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      if [ ! -e "$REPO_ROOT/$src" ]; then
        log_skip "$action: source '$src' not found"
        SKIPPED+=("$action:$src"); return
      fi
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$src"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      mv "$REPO_ROOT/$src" "$REPO_ROOT/$tgt"
      log_done "$action: $src -> $tgt"
      ;;

    delete_file)
      local path
      path="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('path',''))")"
      if [ ! -e "$REPO_ROOT/$path" ]; then
        log_skip "$action: '$path' not found — idempotent"
        SKIPPED+=("$action:$path"); return
      fi
      rm -f "$REPO_ROOT/$path"
      log_done "$action: $path"
      ;;

    set_yaml_key)
      local file key val if_missing
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      key="$(echo "$tjson" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('path') or d.get('key',''))")"
      val="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('value',''))")"
      if_missing="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('if_missing','false'))" 2>/dev/null)" || if_missing="false"
      if [ "$if_missing" = "true" ] || [ "$if_missing" = "True" ]; then
        if yaml_get "$REPO_ROOT/$file" "$key" >/dev/null 2>&1; then
          log_skip "$action: $file $key already set (if_missing=true) — idempotent"
          SKIPPED+=("$action:$key")
          return
        fi
      fi
      $PYTHON "$YAML_TOOLS" set "$REPO_ROOT/$file" "$key" "$val"
      log_done "$action: $file $key = $val"
      ;;

    rename_yaml_key)
      local file old_key new_key old_val
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      old_key="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('old_key',''))")"
      new_key="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('new_key',''))")"
      old_val="$(yaml_get "$REPO_ROOT/$file" "$old_key" 2>/dev/null)" || true
      if [ -z "${old_val:-}" ]; then
        log_skip "$action: key '$old_key' not found in $file"
        SKIPPED+=("$action:$old_key"); return
      fi
      $PYTHON "$YAML_TOOLS" set "$REPO_ROOT/$file" "$new_key" "$old_val"
      $PYTHON -c "
import yaml
data = yaml.safe_load(open('$REPO_ROOT/$file'))
parts = '$old_key'.split('.')
cur = data
for p in parts[:-1]:
    if not isinstance(cur, dict): break
    cur = cur.get(p, {})
if isinstance(cur, dict) and parts[-1] in cur:
    del cur[parts[-1]]
with open('$REPO_ROOT/$file', 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True, width=100)
" 2>/dev/null
      log_done "$action: $file $old_key -> $new_key = $old_val"
      ;;

    delete_yaml_key)
      local file key
      file="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('file',''))")"
      key="$(echo "$tjson" | $PYTHON -c "import json,sys; d=json.load(sys.stdin); print(d.get('path') or d.get('key',''))")"
      if ! yaml_get "$REPO_ROOT/$file" "$key" >/dev/null 2>&1; then
        log_skip "$action: key '$key' not found in $file — idempotent"
        SKIPPED+=("$action:$key"); return
      fi
      $PYTHON -c "
import yaml
data = yaml.safe_load(open('$REPO_ROOT/$file'))
parts = '$key'.split('.')
cur = data
for p in parts[:-1]:
    if not isinstance(cur, dict): break
    cur = cur.get(p, {})
if isinstance(cur, dict) and parts[-1] in cur:
    del cur[parts[-1]]
with open('$REPO_ROOT/$file', 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True, width=100)
" 2>/dev/null
      log_done "$action: $file $key"
      ;;

    create_file_from_template)
      local src tgt subs inline_tmpl
      src="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('source',''))")"
      tgt="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('target',''))")"
      subs="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('substitutions',{})))")"
      inline_tmpl="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('template',''))")"
      if [ -e "$REPO_ROOT/$tgt" ]; then
        log_skip "$action: target '$tgt' already exists — idempotent"
        SKIPPED+=("$action:$tgt"); return
      fi
      mkdir -p "$(dirname "$REPO_ROOT/$tgt")"
      # Inline template (content embedded in OKF bundle)
      if [ -n "$inline_tmpl" ]; then
        echo "$inline_tmpl" > "$REPO_ROOT/$tgt"
        if [ "$subs" != "{}" ]; then
          $PYTHON -c "
import json
subs = json.loads('''$subs''')
content = open('$REPO_ROOT/$tgt').read()
for k, v in subs.items():
    content = content.replace(k, v)
with open('$REPO_ROOT/$tgt', 'w') as f:
    f.write(content)
" 2>/dev/null
        fi
        log_done "$action: inline template -> $tgt"
        return
      fi
      # File-based template resolution
      template_path=""
      if [ -n "$src" ]; then
        # Try source as relative path first, then as template name
        if [ -f "$REPO_ROOT/$src" ]; then
          template_path="$REPO_ROOT/$src"
        elif [ -f "$REPO_ROOT/specs/templates/${src##*/}" ]; then
          template_path="$REPO_ROOT/specs/templates/${src##*/}"
        fi
      fi
      if [ -z "$template_path" ] || [ ! -f "$template_path" ]; then
        log_skip "$action: template not found (src='$src')"
        SKIPPED+=("$action:$src"); return
      fi
      cp "$template_path" "$REPO_ROOT/$tgt"
      $PYTHON -c "
import json
subs = json.loads('''$subs''')
content = open('$REPO_ROOT/$tgt').read()
for k, v in subs.items():
    content = content.replace(k, v)
with open('$REPO_ROOT/$tgt', 'w') as f:
    f.write(content)
" 2>/dev/null
      log_done "$action: $src -> $tgt"
      ;;

    *)
      log_skip "$action: unknown transform type"
      SKIPPED+=("$action")
      ;;
  esac
}

# Execute each migration in order
MIG_LIST="$(echo "$MIGRATION_PLAN" | $PYTHON -c "import json,sys; [print(json.dumps(m)) for m in json.load(sys.stdin)]")"
while IFS= read -r mig_json; do
  [ -z "$mig_json" ] && continue
  MIG_ID="$(echo "$mig_json" | $PYTHON -c "import json,sys; print(json.load(sys.stdin)['id'])")"
  MIG_FILE="$(echo "$mig_json" | $PYTHON -c "import json,sys; print(json.load(sys.stdin)['file'])")"
  MIG_TITLE="$(echo "$mig_json" | $PYTHON -c "import json,sys; print(json.load(sys.stdin)['title'])")"

  BUNDLE_PATH="$MIGRATIONS_DIR/$MIG_FILE"
  if [ ! -f "$BUNDLE_PATH" ]; then
    log_warn "$MIG_ID: bundle file not found — skipping"
    SKIPPED+=("$MIG_ID:bundle_missing")
    continue
  fi

  echo ""
  echo "── $MIG_ID: $MIG_TITLE ──"

  TRANSFORMS="$($PYTHON -c "
import yaml, json
with open('$BUNDLE_PATH') as f:
    parts = f.read().split('---')
    fm = yaml.safe_load(parts[1])
print(json.dumps(fm.get('transforms', []), default=str))
" 2>/dev/null)"

  T_LIST="$(echo "$TRANSFORMS" | $PYTHON -c "import json,sys; [print(json.dumps(t, default=str)) for t in json.load(sys.stdin)]")"
  while IFS= read -r tjson; do
    [ -z "$tjson" ] && continue
    action="$(echo "$tjson" | $PYTHON -c "import json,sys; print(json.load(sys.stdin).get('action',''))")"
    apply_transform "$MIG_ID" "$action" "$tjson"
  done <<< "$T_LIST"

  # Run verify commands
  VERIFY_CMDS="$($PYTHON -c "
import yaml, json
with open('$BUNDLE_PATH') as f:
    parts = f.read().split('---')
    fm = yaml.safe_load(parts[1])
for a in fm.get('actions_needed', []):
    v = a.get('verify', '')
    if v: print(v)
" 2>/dev/null)"

  VERIFY_OK=true
  while IFS= read -r vcmd; do
    [ -z "$vcmd" ] && continue
    log_info "verify: $vcmd"
    if eval "$vcmd" 2>&1; then
      log_done "verify passed"
    else
      log_fail "verify failed"
      VERIFY_OK=false
    fi
  done <<< "$VERIFY_CMDS"

  if [ "$VERIFY_OK" = "true" ]; then
    SUCCEEDED+=("$MIG_ID")
  else
    FAILED+=("$MIG_ID")
  fi
done <<< "$MIG_LIST"

# ── stamp ─────────────────────────────────────────────────────────────────
if [ -f "$SPECS_DIR/state.yaml" ]; then
  log_info "Stamping bigpowers_version=$INSTALLED in state.yaml"
  $PYTHON "$YAML_TOOLS" set "$SPECS_DIR/state.yaml" "bigpowers_version" "$INSTALLED"
  log_done "stamp applied"
fi

# ── validate-okf soft gate ────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/validate-okf.sh" ]; then
  log_info "Running validate-okf.sh (soft gate) …"
  if bash "$SCRIPT_DIR/validate-okf.sh" --dir "$MIGRATIONS_DIR" 2>&1; then
    log_done "validate-okf: PASS"
  else
    log_warn "validate-okf: some checks failed (soft gate — non-blocking)"
  fi
else
  log_info "validate-okf.sh not found — skipping soft gate"
fi

# ── global validate-specs-yaml gate ───────────────────────────────────────
if [ -f "$SCRIPT_DIR/validate-specs-yaml.sh" ]; then
  log_info "Running global validate-specs-yaml.sh …"
  if bash "$SCRIPT_DIR/validate-specs-yaml.sh" 2>&1; then
    log_done "validate-specs-yaml: PASS"
  else
    log_fail "validate-specs-yaml: FAIL"
    FAILED+=("validate-specs-yaml")
  fi
fi

# ── CLAUDE.md / CONVENTIONS.md staleness check ────────────────────────────
STALE_FILES=()
BIGPOWERS_CLAUDE="$SCRIPT_DIR/../CLAUDE.md"
if [ -f "$REPO_ROOT/CLAUDE.md" ] && [ -f "$BIGPOWERS_CLAUDE" ]; then
  proj_lines="$(wc -l < "$REPO_ROOT/CLAUDE.md")"
  bp_lines="$(wc -l < "$BIGPOWERS_CLAUDE")"
  delta=$((bp_lines - proj_lines))
  if [ $delta -gt 20 ]; then
    STALE_FILES+=("CLAUDE.md")
    log_warn "CLAUDE.md: $delta lines behind bigpowers template — consider updating"
  fi
fi
if [ -f "$REPO_ROOT/CONVENTIONS.md" ] && [ -f "$SCRIPT_DIR/../CONVENTIONS.md" ]; then
  proj_lines="$(wc -l < "$REPO_ROOT/CONVENTIONS.md")"
  bp_lines="$(wc -l < "$SCRIPT_DIR/../CONVENTIONS.md")"
  delta=$((bp_lines - proj_lines))
  if [ $delta -gt 20 ]; then
    STALE_FILES+=("CONVENTIONS.md")
    log_warn "CONVENTIONS.md: $delta lines behind bigpowers template — consider updating"
  fi
fi

# ── generate migration report ─────────────────────────────────────────────
ISO_DATE="$(date -u +%Y-%m-%dT%H%M%SZ)"
REPORT_FILE="$SPECS_DIR/migration-report-$ISO_DATE.md"

cat > "$REPORT_FILE" <<REPORT
# Migration Report — $ISO_DATE

## Gap Summary

| Field | Value |
|-------|-------|
| Detected version | $DETECTED |
| Installed version | $INSTALLED |
| Migration count | ${MIGRATION_COUNT:-0} |

## Migrations Applied

REPORT

for m in "${SUCCEEDED[@]:-}"; do
  [ -z "$m" ] && continue
  echo "- $m PASS" >> "$REPORT_FILE"
done
FAILED_COUNT="${#FAILED[@]}"
if [ "${FAILED_COUNT}" -gt 0 ]; then
  echo "" >> "$REPORT_FILE"
  echo "## Migrations Failed" >> "$REPORT_FILE"
  for m in "${FAILED[@]}"; do
    echo "- $m FAIL" >> "$REPORT_FILE"
  done
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "" >> "$REPORT_FILE"
  echo "## Skipped" >> "$REPORT_FILE"
  for m in "${SKIPPED[@]}"; do
    echo "- $m" >> "$REPORT_FILE"
  done
fi
echo "" >> "$REPORT_FILE"
echo "## Uncertainties" >> "$REPORT_FILE"
echo "WARN count: $UNCERTAINTY_COUNT — review specs/ for GUESS markers and adjust if needed." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Verification" >> "$REPORT_FILE"
echo "- validate-specs-yaml: ran as final gate" >> "$REPORT_FILE"

if [ ${#STALE_FILES[@]} -gt 0 ]; then
  echo "" >> "$REPORT_FILE"
  echo "## Staleness Notice" >> "$REPORT_FILE"
  for f in "${STALE_FILES[@]:-}"; do
    [ -z "$f" ] && continue
    echo "- $f is behind the current bigpowers template" >> "$REPORT_FILE"
  done
fi

echo "" >> "$REPORT_FILE"
echo "## Next Steps" >> "$REPORT_FILE"
echo "1. Review the migration report and verify spec correctness" >> "$REPORT_FILE"
echo "2. Run \`bash scripts/sync-skills.sh\` to regenerate agent artifacts" >> "$REPORT_FILE"
echo "3. Commit changes if not auto-committed" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Rollback" >> "$REPORT_FILE"
echo "To rollback, restore from backup:" >> "$REPORT_FILE"
echo "\`\`\`bash" >> "$REPORT_FILE"
echo "rm -rf specs/ && cp -r $BACKUP_DIR/ specs/" >> "$REPORT_FILE"
echo "\`\`\`" >> "$REPORT_FILE"

log_done "Migration report: $REPORT_FILE"

# ── terminal summary ──────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Migration complete: $DETECTED -> $INSTALLED"
echo "=========================================="
echo "  Applied:  ${#SUCCEEDED[@]}"
echo "  Failed:   ${#FAILED[@]}"
echo "  Skipped:  ${#SKIPPED[@]}"
echo "  WARN:     $UNCERTAINTY_COUNT"
[ ${#STALE_FILES[@]} -gt 0 ] && echo "  Stale:    ${STALE_FILES[*]:-}"
echo "  Report:   $REPORT_FILE"
echo "=========================================="
echo "  Remember: run 'bash scripts/sync-skills.sh'"
echo "=========================================="

# ── Safety Layer 3: auto-commit ───────────────────────────────────────────
if [ "$SKIP_COMMIT" != "true" ] && [ "${MIGRATION_COUNT:-0}" -gt 0 ]; then
  log_info "Auto-committing migration …"
  git -C "$REPO_ROOT" add specs/ 2>/dev/null || true
  COMMIT_MSG="migrate-version: $DETECTED -> $INSTALLED (${MIGRATION_COUNT:-0} migration(s))"
  if git -C "$REPO_ROOT" commit -m "$COMMIT_MSG" 2>/dev/null; then
    log_done "committed: $COMMIT_MSG"
  else
    log_info "nothing to commit (already clean)"
  fi
fi

exit 0
