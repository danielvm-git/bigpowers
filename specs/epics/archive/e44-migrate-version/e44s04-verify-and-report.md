# e44s04: Verification & Migration Report

BCP: 2 | story: e44s04

## Summary

Post-migration verification: run per-migration verify blocks, run global
`validate-specs-yaml.sh` as final gate, generate timestamped migration report,
surface CLAUDE.md/CONVENTIONS.md staleness notification, and remind about
`sync-skills.sh` resync.

## Verification Pipeline

```
After migrations applied:
  │
  ├─ 1. PER-MIGRATION VERIFY BLOCKS
  │    For each applied migration, run its verify: commands.
  │    All must pass for the migration to count as "applied" (vs "partial").
  │
  ├─ 2. GLOBAL VALIDATION
  │    Run bash scripts/validate-specs-yaml.sh
  │    Run bash scripts/validate-okf.sh specs/migrations/  (if available)
  │
  ├─ 3. STALENESS NOTIFICATIONS
  │    Compare downstream CLAUDE.md vs bigpowers template.
  │    Compare downstream CONVENTIONS.md vs bigpowers template.
  │    If differences: surface with line counts (not diffs).
  │    "Your CLAUDE.md is 14 lines behind the current template."
  │
  └─ 4. SYNC-SKILLS REMINDER
       "Run `bash scripts/sync-skills.sh` to regenerate agent artifacts
        (.cursor/rules/, .gemini/extensions/) for the new version."
```

## Migration Report

Generated at `specs/migration-report-<ISO8601>.md` and printed as terminal summary.

### Report sections

1. **Gap summary** — detected version → target version, detection method, confidence
2. **Migrations applied** — per migration: ID, title, status (✓ applied / ⚠ partial / ✗ failed), actions executed
3. **Manual steps required** — extracted from each migration's body section "Manual steps after migration"
4. **Uncertain extractions** — fields flagged with ⚠ GUESS during heuristic conversion
5. **Skipped migrations** — migrations that were applicable but skipped due to dependency failures
6. **Verification results** — per-migration verify blocks pass/fail, global validate-specs-yaml.sh result
7. **Staleness notices** — CLAUDE.md/CONVENTIONS.md behind by X lines
8. **Next steps** — run sync-skills.sh, review ⚠ GUESS fields in state.yaml, manual fix instructions
9. **Rollback instructions** — `rm -rf specs/ && cp -r specs/.pre-upgrade-backup/ specs/` or `git reset --hard HEAD~1`

## Terminal Summary

Printed after migration completes (compact, not the full report):

```
Migration complete: v2.0.0 → v2.54.0
  2 migrations applied: m1-yaml-cockpit ✓, m2-legacy-paths ✓
  Verification: validate-specs-yaml.sh passed
  1 ⚠ uncertain field in state.yaml (see report)
  Staleness: CLAUDE.md 14 lines behind
  Full report: specs/migration-report-2026-07-03T120000Z.md
  Next: run `bash scripts/sync-skills.sh`
```
