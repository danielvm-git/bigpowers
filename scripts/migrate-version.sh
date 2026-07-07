#!/usr/bin/env bash
# story: e44s03 e44s04
# migrate-version.sh — one-shot ordered migration engine with triple safety net.
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
PROJECT_DIR=""
PREV_ARG=""

for arg in "$@"; do
  case "$arg" in
    --help|-h) source "$SCRIPT_DIR/lib/migrate-version-common.sh"; migrate_usage ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --no-commit) SKIP_COMMIT=true ;;
    --verbose) VERBOSE=true ;;
    --project) ;;
    *)
      if [ "${PREV_ARG:-}" = "--project" ]; then
        PROJECT_DIR="$arg"
      else
        echo "migrate-version: unknown flag: $arg" >&2
        exit 4
      fi
      ;;
  esac
  PREV_ARG="$arg"
done

if [ -n "$PROJECT_DIR" ]; then
  REPO_ROOT="$PROJECT_DIR"
  SPECS_DIR="$REPO_ROOT/specs"
  BACKUP_DIR="$SPECS_DIR/.pre-upgrade-backup"
fi

source "$SCRIPT_DIR/lib/migrate-version-run.sh"
migrate_version_main
