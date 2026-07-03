---
okf_kind: spec-migration
okf_version: "0.1"
id: m2-legacy-paths
title: "Legacy Path Migration"
since_version: "2.0.0"
deprecated: false
order: 2
depends_on: [m1-yaml-cockpit]
actions_needed: [set_yaml_key]
note: >
  Originally included an ADR move (specs/adr/ → specs/tech-architecture/adr/),
  but the mother repo (bigpowers itself) keeps ADRs at specs/adr/ (see README
  Hierarchy of Truth). The migration no longer teaches a layout the mother repo
  doesn't use. Downstream projects that prefer tech-architecture/adr/ can apply
  the move manually or via a separate migration added lazily.

fingerprint:
  any:
    - file: specs/state.yaml
      exists: true
    - file: specs/adr
      exists: true
      is_dir: true

transforms:
  # ── Add missing v2.0.0 YAML keys (safety net for partial m1) ────

  - action: set_yaml_key
    file: specs/state.yaml
    path: "release.ci_verified"
    value: false
    if_missing: true

  - action: set_yaml_key
    file: specs/state.yaml
    path: "active_flow"
    value: null
    if_missing: true

  - action: set_yaml_key
    file: specs/state.yaml
    path: "bug_cycle.current_step"
    value: 0
    if_missing: true

  - action: set_yaml_key
    file: specs/state.yaml
    path: "bug_cycle.completed_steps"
    value: null
    if_missing: true

verify:
  - grep -q 'release' specs/state.yaml
  - grep -q 'bug_cycle' specs/state.yaml
---
# M2: Legacy Path Migration (introduced in bigpowers v2.0.0)

## What changed

bigpowers v2.0.0 added new YAML keys to `state.yaml` for bug cycle tracking
and CI verification state. Projects created or migrated during the v2.0
window may have `state.yaml` but missing these keys if m1 was applied
partially.

> **Note:** An earlier version of this migration included moving `specs/adr/`
> to `specs/tech-architecture/adr/`, but bigpowers itself keeps ADRs at
> `specs/adr/` (see README Hierarchy of Truth). The move was removed so the
> migration doesn't teach a layout the mother repo doesn't use.

## What this migration does

1. **Adds missing YAML keys** that may not have been set if m1 was partially
   applied or if the project was created between format versions.

2. **Safety checks** for projects that had both old and new formats.

## Manual steps after migration

- [ ] Verify ADR files are accessible at `specs/tech-architecture/adr/`
- [ ] Update any documentation or links that referenced `specs/adr/`
- [ ] Review `bug_cycle` keys in `specs/state.yaml` if you track bugs

## Related

- Epic: e44 (Spec Version Migration)
- CONVENTIONS.md: Legacy paths table
