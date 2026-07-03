# e44s01: Migration Registry & OKF Schema

BCP: 3 | story: e44s01

## Summary

Define the OKF schemas for `spec-migration` and `migration-registry` bundles.
Create `specs/templates/migration.okf.md` as the canonical template. Build the
initial `specs/migrations/registry.okf.md` containing the first structural
migrations (m1-m2). Define the 10 domain-specific action types with their config
schemas.

## OKF Schema: okf_kind: spec-migration

Each migration is a standalone `*.okf.md` file in `specs/migrations/`. Frontmatter
provides machine-readable detection + transform instructions; body provides
human-readable rationale and manual steps.

```yaml
---
okf_kind: spec-migration
okf_version: "0.1"
id: m1-yaml-cockpit              # unique, grep-able, kebab-case
title: "Markdown → YAML Cockpit" # display title
since_version: "2.0.0"           # bigpowers version that introduced this change
deprecated: false                 # true if superseded
order: 1                         # execution order within version group
depends_on: []                   # IDs this migration requires to run first
actions_needed:                  # which action types this migration uses
  - convert_md_to_yaml
  - rename_file
  - set_yaml_key

fingerprint:                     # detection: is this migration needed?
  any:                           # ANY condition matches → migration applies
    - file: specs/STATE.md
      exists: true
    - file: specs/RELEASE-PLAN.md
      exists: true
  # all: []                      # alternative: ALL must match

transforms:                      # ordered list of actions to apply
  - action: convert_md_to_yaml
    source: specs/STATE.md
    target: specs/state.yaml
    schema: state-v2
    heuristic_map:               # regex → YAML key mapping
      "Branch:": "git.branch"
      "Current step:": "epic_cycle.current_step"
      "Active flow:": "active_flow"
    uncertain_fields:             # fields flagged as ⚠ GUESS in dry-run
      - "Current milestone text"
      - "Next steps"
    archive_source: true          # move source to specs/archive/

  - action: rename_file
    source: specs/SCOPE.md
    target: specs/product/SCOPE_LATEST.yaml
    if_source_exists: true

  - action: set_yaml_key
    file: specs/state.yaml
    path: "handoff.next_skill"
    value: null
    if_missing: true

verify:                           # post-migration checks (all must pass)
  - test -f specs/state.yaml
  - grep -q 'active_flow' specs/state.yaml
  - test ! -f specs/STATE.md
  - test -f specs/product/SCOPE_LATEST.yaml
---
```

## OKF Schema: okf_kind: migration-registry

A single index file listing all available migrations with version and dependency
info. Used by `check_spec_version_gap.sh` to discover applicable migrations.

```yaml
---
okf_kind: migration-registry
okf_version: "0.1"
generated_at: 2026-07-03T00:00:00Z
bigpowers_version: "2.54.0"     # version this registry ships with

migrations:
  - id: m1-yaml-cockpit
    file: m1-yaml-cockpit.okf.md
    since_version: "2.0.0"
    order: 1
    depends_on: []
    actions_needed: [convert_md_to_yaml, rename_file, set_yaml_key]

  - id: m2-legacy-paths
    file: m2-legacy-paths.okf.md
    since_version: "2.0.0"
    order: 2
    depends_on: [m1-yaml-cockpit]
    actions_needed: [set_yaml_key]
---
```

## Action Catalog

Ten domain-specific actions. Each has a defined config schema.
The engine implements each as an idempotent function.

| # | Action | Config |
|---|--------|--------|
| 1 | `convert_md_to_yaml` | `source`, `target`, `schema`, `heuristic_map`, `uncertain_fields`, `archive_source` |
| 2 | `rename_file` | `source`, `target`, `if_source_exists` |
| 3 | `move_file` | `source`, `target_dir`, `if_source_exists` |
| 4 | `set_yaml_key` | `file`, `path` (dot-notation), `value`, `if_missing` |
| 5 | `rename_yaml_key` | `file`, `old_path`, `new_path` |
| 6 | `delete_yaml_key` | `file`, `path`, `if_exists` |
| 7 | `create_file_from_template` | `target`, `template`, `vars` (substitutions) |
| 8 | `restructure_epic_capsule` | `source` (flat yaml), `target_dir` (capsule), `story_ids` |
| 9 | `delete_file` | `source`, `if_exists` |
| 10 | `merge_yaml_files` | `sources` (ordered list), `target`, `merge_strategy` (deep_merge | append_lists) |

Initial ship implements actions 1-7 and 9. Actions 8 (`restructure_epic_capsule`)
and 10 (`merge_yaml_files`) are declared in the schema but not yet implemented;
they show as `status: planned` in the registry.

## Initial Registry Contents

Two migrations in the initial ship:

### m1-yaml-cockpit (since v2.0.0)
- Converts `specs/STATE.md` → `specs/state.yaml` (heuristic parsing)
- Converts `specs/RELEASE-PLAN.md` → `specs/release-plan.yaml`
- Creates empty `specs/execution-status.yaml`
- Renames `specs/SCOPE.md` → `specs/product/SCOPE_LATEST.yaml`
- Renames `specs/CONTEXT.md` → `specs/tech-architecture/TECH_STACK_LATEST.md` (if no existing tech-stack)
- Adds `handoff.next_skill: null` to state.yaml
- Adds `metrics.story_start: null` to state.yaml
- Adds `bigpowers_version: "2.0.0"` to state.yaml

> **Action implementation:** `scripts/convert-legado.sh` (shipped at v2.x, pre-dates e44)
> already performs most of this migration for bigpowers' own Markdown-era specs.
> m1 absorbs and generalizes that script — convert-legado.sh becomes a consumed
> utility, cited by m1's transforms rather than duplicated. The original script
> remains in-tree for manual invocation until m1 is fully implemented.

### m2-legacy-paths (since v2.0.0)
- Sets `release.ci_verified: false` in state.yaml if key missing
- Sets `active_flow: null` in state.yaml if key missing
- Sets `bug_cycle.current_step: 0` and `bug_cycle.completed_steps: null` if keys missing

> **Note:** An earlier design included moving `specs/adr/` → `specs/tech-architecture/adr/`,
> but bigpowers itself keeps ADRs at `specs/adr/` (see README Hierarchy of Truth).
> The move was removed so the migration doesn't teach a layout the mother repo doesn't use.
