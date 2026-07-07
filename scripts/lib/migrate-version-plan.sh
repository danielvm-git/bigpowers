#!/usr/bin/env bash
# story: e44s03
# Migration plan builder and dry-run preview for migrate-version.sh

if [ -n "${MIGRATE_VERSION_PLAN_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_PLAN_LOADED=1

migrate_build_plan() {
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
}

migrate_backup_specs() {
  log_info "Creating backup: $BACKUP_DIR"
  rm -rf "$BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp -r "$SPECS_DIR"/* "$BACKUP_DIR"/ 2>/dev/null || true
  rm -rf "$BACKUP_DIR/.pre-upgrade-backup" 2>/dev/null || true
}

migrate_print_dry_run() {
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
}
