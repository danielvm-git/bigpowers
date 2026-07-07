# e44s03: Migration Engine

BCP: 4 | story: e44s03

## Summary

Create `scripts/migrate-version.sh` — the core migration engine. Implements triple safety net
(backup → dry-run → auto-commit), one-shot gap resolution with internal dependency ordering,
and idempotent action execution.

## Architecture

```
migrate-version.sh (entry point)
  │
  ├─ 1. SAFETY: cp -r specs/ → specs/.pre-upgrade-backup/
  │
  ├─ 2. DETECT: call check_spec_verson_gap()
  │    ├─ Block if active work detected (exit 3)
  │    └─ Load applicable migrations from registry.okf.md
  │
  ├─ 3. DRY-RUN: for each migration, for each transform, show WHAT WILL CHANGE
  │    ├─ ⚠ GUESS markers for heuristic extractions
  │    ├─ ⚠ PARTIAL markers for planned-but-unimplemented actions
  │    └─ Present full diff → wait for user confirmation
  │
  ├─ 4. APPLY: execute transforms in dependency order
  │    ├─ Each action is idempotent
  │    ├─ Internal ordering respects depends_on graph
  │    └─ Track succeeded / failed / partial
  │
  ├─ 5. STAMP: write bigpowers_version to state.yaml
  │
  └─ 6. COMMIT: git add specs/ && git commit -m "chore(migrate-version): vX → vY"
```

## Safety Net (triple)

| Layer | When | Purpose |
|-------|------|---------|
| Backup | Before ANY file access | `cp -r specs/ specs/.pre-upgrade-backup/` — belt |
| Dry-run diff | After loading migrations, before applying | Full diff preview with ⚠ markers — suspenders |
| Auto-commit | After successful apply | `git add specs/ && git commit` — rollback via `git reset --hard HEAD~1` |

## Idempotent Action Implementation

Each action must be safe to run twice:

| Action | Idempotency strategy |
|--------|---------------------|
| `convert_md_to_yaml` | Deep-merge heuristic extractions into target if it exists, with existing target keys taking strict precedence. Archive source when done. |
| `rename_file` | Check if target exists. If yes and source missing → skip. If both exist → warn, don't overwrite. |
| `move_file` | Same as rename_file. |
| `set_yaml_key` | `if_missing: true` only sets when key absent. Already-present keys are untouched. |
| `rename_yaml_key` | Check if `new_path` already exists. If yes and `old_path` missing → skip. |
| `delete_yaml_key` | `if_exists: true` — no-op if key already absent. |
| `create_file_from_template` | Check if target exists. Skip if present (preserve user edits). |
| `delete_file` | `if_exists: true` — no-op if file already gone. |

## Dependency Ordering (topological sort)

Migrations declare `depends_on` in their OKF frontmatter. The engine builds a DAG
and executes in topological order. Example:

```
m1 (depends_on: [])
  ↓
m2 (depends_on: [m1])
  ↓
m4 (depends_on: [m2])
```

If a migration in the chain fails, subsequent migrations that depend on it are skipped.
The engine continues with independent migrations. Partial results are reported.

## Action Implementation Priority

Initial ship (this story) implements actions 1-7 and 9:

1. `convert_md_to_yaml` — heuristic STATE.md/RELEASE-PLAN.md → YAML
2. `rename_file` — mv with idempotency check
3. `move_file` — mv to target directory
4. `set_yaml_key` — bp-yaml-set.sh integration
5. `rename_yaml_key` — YAML path rename
6. `delete_yaml_key` — YAML key removal
7. `create_file_from_template` — cp template with variable substitution
9. `delete_file` — rm with if_exists guard

Actions 8 (`restructure_epic_capsule`) and 10 (`merge_yaml_files`) are declared
in the schema and registry but throw "not yet implemented" with status output.
