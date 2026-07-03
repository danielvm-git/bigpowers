---
# ─────────────────────────────────────────────────────────────────────
# OKF bundle — spec-migration template
# Format: OKF (markdown + YAML frontmatter). One file per migration.
# Canonical schema: spec/migrations/registry.okf.md indexes all migrations.
# ─────────────────────────────────────────────────────────────────────
okf_kind: spec-migration
okf_version: "0.1"

# Identity
id: mN-short-name                # unique, grep-able, kebab-case
title: "Human-readable title"    # display title
since_version: "2.0.0"           # bigpowers version that introduced this change
deprecated: false                 # true if superseded by later migration
order: 1                         # execution order within version group
depends_on: []                   # IDs this migration requires to run first
actions_needed:                  # which action types this migration uses
  - rename_file
  - set_yaml_key

# Detection: is this migration needed for the downstream project?
fingerprint:
  any:                           # ANY condition matches → migration applies
    - file: specs/some-old-file.md
      exists: true
  # all: []                      # alternative: ALL conditions must match

# Transforms: ordered list of actions to apply
transforms:
  - action: rename_file
    source: specs/old-file.md
    target: specs/new-path/new-file.md
    if_source_exists: true

  - action: set_yaml_key
    file: specs/state.yaml
    path: "some.nested.key"
    value: null
    if_missing: true

# Post-migration verification (all commands must pass)
verify:
  - test -f specs/new-path/new-file.md
  - grep -q 'some.nested.key' specs/state.yaml
---
# Migration: M-N — Human-Readable Title

## What changed

Explain the structural change this migration addresses. What was the old
format, what is the new format, and why did it change?

## What this migration does

Describe each transform action in plain language so a human can understand
what the migration will do to their project.

## Manual steps after migration

List any manual work the user must do that the migration cannot automate.

- [ ] Review ⚠ GUESS fields in `specs/state.yaml`
- [ ] Verify epic structure in `specs/epics/`

## Related

- ADR: specs/adr/NNNN-some-decision.md
- Epic: eNN
