# OKF — Open Knowledge Format (v0.1)

**Authority:** This document is the single source of truth for the OKF
convention layer in bigpowers. Previously this lived only inside
`specs/IMPACT-e38-okf-adoption.md`; e44 added kinds that document doesn't
know about. This file consolidates.

> **Status:** v0.1 — active use in e40 (story-metrics), e44 (spec-migration,
> migration-registry), e41 (public receipts). Additional types defined here
> for e45 (OKF Completion).

## What is OKF?

OKF is a lightweight convention for **self-describing, machine-validatable
markdown bundles.** Every OKF file:

1. Is a standard `.md` file (human-readable).
2. Has a YAML frontmatter block between `---` markers.
3. Declares an `okf_kind` — a type tag that tells validators which rules
   to apply.
4. Carries enough metadata that `validate-okf.sh` can gate on structure
   and provenance without knowing the domain.

The rule: **gate on provenance and structure, never on a specific value.**

## Type taxonomy (okf_kind)

| okf_kind | Purpose | Validator in validate-okf.sh | Epic |
|----------|---------|------------------------------|------|
| `story-metrics` | Per-story effort/lead-time/metrics bundle | provenance gate: generator, commit_range, source enum | e40 |
| `spec-migration` | Named migration: fingerprint, transforms, verify | id, since_version, actions_needed, fingerprint, transforms, verify | e44 |
| `migration-registry` | Canonical index of all spec migrations | okf_version, migrations[] structural check | e44 |
| `concept` | Domain concept / ubiquitous-language entry (skills-wiki, adr-wiki) | id, title, category, references[] | e39 → e45 |
| `verification-report` | Compliance / golden-suite / traceability gate report | score, gate_status (pass/fail/concerns/waived), threshold | e45 |
| `bug-registry-entry` | Bug record with investigation/fix provenance | id, severity, status, root_cause, fix_story | e45 |

## Custom frontmatter fields

Every OKF bundle carries these **standard** fields:

| Field | Required | Description |
|-------|----------|-------------|
| `okf_kind` | Yes | Type tag (see taxonomy above) |
| `okf_version` | Yes | OKF spec version (currently `"0.1"`) |

**Kind-specific** fields:

### story-metrics (e40)

| Field | Description | Aggregation |
|-------|-------------|-------------|
| `id` | Story ID (e.g. `e40s03`) | • |
| `epic` | Parent epic | • |
| `bcps` | Pre-build story size | • |
| `commit_range` | Git range (`sha..sha`) | • |
| `source` | `measured` \| `estimated` \| `backfilled` | • |
| `generated_at` | ISO 8601 timestamp | • |
| `generator` | `scripts/record-cycle-time.sh` | • |
| `dora.*` | The four keys (market standard) | ⌀ |
| `agent.*` | Harness telemetry (GSD-2 style) | Σ |
| `effort.*` | Git-derived, idle-stripped effort | Σ |
| `quality.*` | Gate scores | ⌀ |
| `flow.*` | Worktree telemetry | ⌀ |

Aggregation tags: **Σ** additive (sum → total) · **⌀** median/p95 (never sum)
· **%** rate (ratio over window) · **•** static (identity).

### spec-migration (e44)

| Field | Description |
|-------|-------------|
| `id` | Migration ID (e.g. `m1-yaml-cockpit`) |
| `since_version` | Minimum bigpowers version this migration applies to |
| `actions_needed` | List of action types required |
| `fingerprint` | Detection: `file` (exists/absent checks) or `any` (OR of conditions) |
| `transforms` | Ordered list of actions to apply |
| `verify` | Shell commands to confirm migration succeeded |

### migration-registry (e44)

| Field | Description |
|-------|-------------|
| `migrations[]` | List of migration entries (id, file, order, status, actions_needed) |
| `bigpowers_version` | Mirror, not the authority — stamp at generation time |

### concept (e45)

| Field | Description |
|-------|-------------|
| `id` | Concept ID (e.g. `verify-work`) |
| `title` | Human-readable name |
| `category` | `skill` \| `convention` \| `adr` \| `metric` \| `reference` |
| `references[]` | List of authority documents |

### verification-report (e45)

| Field | Description |
|-------|-------------|
| `score` | Numeric score (e.g. 95.0 for compliance) |
| `gate_status` | `pass` \| `fail` \| `concerns` \| `waived` |
| `threshold` | Minimum score to pass |
| `total_pass` / `total_fail` | Counts |
| `generated_by` | Script that produced the report |

## Validation

```bash
# Validate a single bundle
bash scripts/validate-okf.sh --bundle specs/metrics/e40s03.okf.md

# Validate all bundles in a directory
bash scripts/validate-okf.sh --dir specs/migrations

# Default: validates specs/metrics/ (story-metrics)
bash scripts/validate-okf.sh
```

`validate-okf.sh` is kind-aware — it dispatches to the correct validator
based on `okf_kind`. Unknown kinds are SKIP-ped gracefully.

## CI Integration (e48s05 HARD GATE)

OKF bundles are validated on every push to `main` and `develop` via the
`sync-skills.yml` workflow. The CI step (`Validate OKF bundles`) scans
six standard directories and **fails the build** on any validation error:

```yaml
# .github/workflows/sync-skills.yml — OKF validation step (blocking)
for dir in \
  specs/metrics \
  specs/migrations \
  specs/epics-wiki \
  specs/adr-wiki \
  specs/bugs \
  specs/verifications/reports; do
  bash scripts/validate-okf.sh --dir "$dir" || exit 1
done
```

This closes the loop: OKF bundles are validated on every push, not just
when someone remembers to run the script manually. Bundle generation is
idempotent — re-run the generator script, validate, and commit.

**Wiki bundles** (`epics-wiki/`, `adr-wiki/`, `bugs/`) are generated by:
- `scripts/generate-epics-wiki.sh` — concept bundles per epic
- `scripts/generate-adr-wiki.sh` — concept bundles per ADR
- `scripts/sync-bugs-registry.sh` — concept bundles per bug (+ registry.yaml)

**Verification report bundles** (`verifications/reports/`) are generated by:
- `scripts/run-golden-suite.sh` — `GOLDEN-YYYY-MM-DD.okf.md`
- `scripts/audit-compliance.sh` — `audit-YYYY-MM-DD.okf.md`

## Provenance gate rule

The validator **NEVER** gates on a specific metric value. It gates on:

1. **Structure:** Are the required keys present?
2. **Provenance:** Did the right generator run? (knows the pipeline, not the output)
3. **Freshness:** Does `commit_range` resolve? Is `generated_at` recent?

This is the e40 honesty rule: gate on the pipeline, not the value. A
fabricated value gets through — but the provenance check catches whether
the right tool produced it.

## History

- **v0.1 (2026-07-03):** story-metrics (e40), spec-migration + migration-registry
  (e44). Validated by `scripts/validate-okf.sh`.
- **Planned:** concept, verification-report, bug-registry-entry (e45). Agent
  guide generation from OKF bundles (e39 phase 4).

## Related

- `specs/IMPACT-e38-okf-adoption.md` — phased rollout risk assessment
- `specs/templates/story-metrics.okf.md` — template for story-metrics bundles
- `specs/migrations/registry.okf.md` — canonical migration registry (OKF bundle)
- `scripts/validate-okf.sh` — kind-aware provenance validator
- `scripts/record-cycle-time.sh` — git-derived effort + lead time (story-metrics generator)
