---
okf_kind: migration-registry
okf_version: "0.1"
generated_at: 2026-07-03T00:00:00Z
# bigpowers_version: mirror, not the authority — the real version lives in git tags (gh release view).
# Stamp this at generation time; do not hand-maintain.
bigpowers_version: "2.56.1"

migrations:
  - id: m1-yaml-cockpit
    file: m1-yaml-cockpit.okf.md
    since_version: "2.0.0"
    order: 1
    depends_on: []
    actions_needed: [convert_md_to_yaml, rename_file, set_yaml_key, delete_file]
    status: implemented
    description: >
      Converts Markdown-era specs (STATE.md, RELEASE-PLAN.md) to YAML cockpit
      format (state.yaml, release-plan.yaml, execution-status.yaml). Renames
      SCOPE.md → product/SCOPE_LATEST.yaml, CONTEXT.md → tech-architecture/.
      Adds missing v2.0.0 keys: handoff.next_skill, metrics.story_start,
      bigpowers_version stamp. Archives old Markdown files to specs/archive/.

  - id: m2-legacy-paths
    file: m2-legacy-paths.okf.md
    since_version: "2.0.0"
    order: 2
    depends_on: [m1-yaml-cockpit]
    actions_needed: [set_yaml_key]
    status: implemented
    description: >
      Adds missing YAML keys (release.ci_verified, active_flow) with safe
      defaults. The ADR move (specs/adr/ → specs/tech-architecture/adr/) was
      removed — bigpowers itself keeps ADRs at specs/adr/. Downstream projects
      that prefer tech-architecture/adr/ can apply the move manually.

  - id: m3-epic-capsule
    file: m3-epic-capsule.okf.md
    since_version: "2.20.0"
    order: 3
    depends_on: [m1-yaml-cockpit]
    actions_needed: [restructure_epic_capsule]
    status: planned
    description: >
      Converts flat epic YAML files (epics/eNN-name.yaml) to capsule
      directories (epics/eNN-name/ with epic.yaml + story files).
      ACTION NOT YET IMPLEMENTED — will be built lazily when needed.

  - id: m4-cycle-times
    file: m4-cycle-times.okf.md
    since_version: "2.0.0"
    order: 4
    depends_on: [m1-yaml-cockpit]
    actions_needed: [create_file_from_template]
    status: planned
    description: >
      Creates specs/metrics/cycle-times.yaml from template if missing.
      REQUIRES: specs/templates/cycle-times.yaml to exist as template source.
      ACTION NOT YET IMPLEMENTED — will be built lazily when needed.
---
# Migration Registry

Canonical index of all spec format migrations. Used by `check_spec_version_gap.sh`
and `migrate-version.sh` to discover applicable migrations for a given version gap.

## How to add a migration

1. Create `specs/migrations/mN-short-name.okf.md` using the template at
   `specs/templates/migration.okf.md`.
2. Add an entry to this registry's `migrations:` list.
3. Set `status: implemented` once the action engine supports the needed actions.
4. Run `bash scripts/validate-okf.sh specs/migrations/` to validate.

## Migration status

| Status | Meaning |
|--------|---------|
| `implemented` | Migration bundle exists AND engine supports all actions. Ready. |
| `planned` | Migration bundle exists BUT engine does not yet support all actions. Will be skipped with a warning. |

## Ordering

Migrations execute in `order` within their version group. The engine topologically
sorts by `depends_on` across all applicable migrations. `order` is the fallback
when dependencies don't fully constrain the sequence.
