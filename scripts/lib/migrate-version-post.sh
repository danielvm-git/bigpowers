#!/usr/bin/env bash
# story: e44s03 e44s04
# Post-migration stamp, gates, report, and commit for migrate-version.sh

if [ -n "${MIGRATE_VERSION_POST_LOADED:-}" ]; then return 0; fi
MIGRATE_VERSION_POST_LOADED=1

migrate_stamp_version() {
  if [ -f "$SPECS_DIR/state.yaml" ]; then
    log_info "Stamping bigpowers_version=$INSTALLED in state.yaml"
    $PYTHON "$YAML_TOOLS" set "$SPECS_DIR/state.yaml" "bigpowers_version" "$INSTALLED"
    log_done "stamp applied"
  fi
}

migrate_run_soft_gates() {
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

  if [ -f "$SCRIPT_DIR/validate-specs-yaml.sh" ]; then
    log_info "Running global validate-specs-yaml.sh …"
    if bash "$SCRIPT_DIR/validate-specs-yaml.sh" 2>&1; then
      log_done "validate-specs-yaml: PASS"
    else
      log_fail "validate-specs-yaml: FAIL"
      FAILED+=("validate-specs-yaml")
    fi
  fi
}

migrate_check_staleness() {
  local proj_lines bp_lines delta
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
}

migrate_write_report() {
  local m ISO_DATE FAILED_COUNT
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
}

migrate_print_summary() {
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
}

migrate_auto_commit() {
  local COMMIT_MSG
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
}

migrate_finalize() {
  migrate_stamp_version
  migrate_run_soft_gates
  migrate_check_staleness
  migrate_write_report
  migrate_print_summary
  migrate_auto_commit
}
