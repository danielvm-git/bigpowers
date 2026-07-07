#!/usr/bin/env bash
# story: e44s03 e44s04
# migrate-version orchestrator — sources lib modules and runs the migration pipeline

if [ -n "${MIGRATE_VERSION_RUN_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_RUN_LOADED=1

_LIB="$(dirname "${BASH_SOURCE[0]}")"
source "$_LIB/migrate-version-common.sh"
source "$_LIB/migrate-version-plan.sh"
source "$_LIB/migrate-version-transforms.sh"
source "$_LIB/migrate-version-execute.sh"
source "$_LIB/migrate-version-post.sh"

migrate_version_main() {
  if [ "$FORCE" != "true" ]; then
    migrate_preflight_block || exit $?
  fi

  if [ ! -d "$SPECS_DIR" ]; then
    echo "migrate-version: no specs/ directory found" >&2
    exit 2
  fi
  if [ ! -f "$REGISTRY" ]; then
    echo "migrate-version: migration registry not found at $REGISTRY" >&2
    exit 4
  fi

  INSTALLED="$(migrate_installed_version)"
  migrate_detect_version || exit $?

  echo "migrate-version: detected=$DETECTED installed=$INSTALLED"

  if [ "$DETECTED" = "$INSTALLED" ]; then
    echo "migrate-version: no version gap — specs are current"
    exit 0
  fi

  migrate_build_plan

  if [ "$DRY_RUN" != "true" ]; then
    migrate_backup_specs
  fi

  if [ "$DRY_RUN" = "true" ]; then
    migrate_print_dry_run
    exit 0
  fi

  migrate_execute_migrations
  migrate_finalize
  exit 0
}
