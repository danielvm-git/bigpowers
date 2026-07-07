#!/usr/bin/env bash
# story: e44s03
# Migration execution loop for migrate-version.sh

if [ -n "${MIGRATE_VERSION_EXECUTE_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_EXECUTE_LOADED=1

migrate_execute_migrations() {
  local MIG_LIST mig_json MIG_ID MIG_FILE MIG_TITLE BUNDLE_PATH TRANSFORMS T_LIST tjson action VERIFY_CMDS VERIFY_OK vcmd

  echo ""
  echo "Applying migrations …"
  SUCCEEDED=()
  FAILED=()
  SKIPPED=()
  SUCCEEDED_COUNT=0
  FAILED_COUNT=0
  SKIPPED_COUNT=0
  UNCERTAINTY_COUNT=0

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
}
