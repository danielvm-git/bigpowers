#!/usr/bin/env bash
# story: e44s03 e44s04
# Shared helpers for migrate-version.sh

if [ -n "${MIGRATE_VERSION_COMMON_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_COMMON_LOADED=1

migrate_usage() {
  cat <<'EOF'
Usage: scripts/migrate-version.sh [flags]

Flags:
  --help         Show this message
  --dry-run      Compose migration plan and show diff, but make no changes
  --force        Skip active-work block detection
  --no-commit    Skip auto-commit (still applies transforms and stamps)
  --verbose      Show detailed progress for each transform step
  --project <dir>  Target project directory (migrations from bigpowers)
EOF
  exit 0
}

migrate_installed_version() {
  node -e "console.log(require('$BIGPOWERS_ROOT/package.json').version)" 2>/dev/null || echo "unknown"
}

migrate_yaml_get() {
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

migrate_yaml_value_set() {
  local value="$1"
  [[ -n "$value" ]] || return 1
  [[ "$value" == "null" ]] && return 1
  return 0
}

migrate_on_feature_branch() {
  local branch="$1"
  [[ -n "$branch" ]] || return 1
  [[ "$branch" == "main" || "$branch" == "master" ]] && return 1
  return 0
}

migrate_specs_clean() {
  git -C "$REPO_ROOT" diff --quiet -- specs/ 2>/dev/null \
    && git -C "$REPO_ROOT" diff --cached --quiet -- specs/ 2>/dev/null
}

migrate_preflight_block() {
  local branch af
  branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)" || true
  if migrate_on_feature_branch "${branch:-}"; then
    echo "migrate-version: BLOCKED — on non-main branch '$branch'. Use --force to override." >&2
    return 3
  fi
  if ! migrate_specs_clean; then
    echo "migrate-version: BLOCKED — uncommitted changes in specs/. Commit or stash first." >&2
    return 3
  fi
  if [[ -f "$SPECS_DIR/state.yaml" ]]; then
    af="$(migrate_yaml_get "$SPECS_DIR/state.yaml" "active_flow" 2>/dev/null)" || true
    if migrate_yaml_value_set "${af:-}"; then
      echo "migrate-version: BLOCKED — active_flow '$af' is set (mid-epic work). Use --force." >&2
      return 3
    fi
  fi
  return 0
}

migrate_detect_version() {
  local stamped
  DETECTED=""
  if [[ -f "$SPECS_DIR/state.yaml" ]]; then
    stamped="$(migrate_yaml_get "$SPECS_DIR/state.yaml" "bigpowers_version" 2>/dev/null)" || true
    if migrate_yaml_value_set "${stamped:-}"; then
      DETECTED="$stamped"
    fi
  fi
  if [[ -z "$DETECTED" ]]; then
    if [[ -f "$SPECS_DIR/STATE.md" && ! -f "$SPECS_DIR/state.yaml" ]]; then
      DETECTED="1.0.0"
    elif [[ -f "$SPECS_DIR/state.yaml" ]]; then
      if migrate_yaml_get "$SPECS_DIR/state.yaml" "epic_cycle" >/dev/null 2>&1; then
        DETECTED="2.20.0"
      else
        DETECTED="2.0.0"
      fi
    else
      echo "migrate-version: cannot determine spec version" >&2
      return 4
    fi
  fi
  return 0
}
