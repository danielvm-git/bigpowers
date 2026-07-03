# story: e38s09

# Traceability Gate — Architecture & Operator Guide

**Generated:** 2026-07-03
**Version:** 1.0
**Epic:** e38 — Spec-to-Code Traceability Gate

---

## Overview

The traceability gate is a three-tier pipeline that ensures every story in the bigpowers spec-driven workflow has traceable code artifacts. It moves beyond simple percentage coverage to detect structural quality gaps (blind spots) and produce a deterministic PASS/CONCERNS/FAIL/WAIVED verdict before release.

**Provenance:**
- Market survey of 5 traceability tools (2026-07-02): spec-kit, speckit-utils, spec-kit V-Model, BMAD TEA, bigpowers trace-requirement.
- Inspired by BMAD TEA's heuristic blind-spot detection and synthetic oracle confidence downgrades.
- Referenced article: "The Agentic Coding Stack — 5 Layers and the Missing Link Nobody Has Built Yet" (Murat Aslan, 2026).

---

## Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1: Coverage Matrix                                    │
│  scripts/trace-stories.sh                                    │
│  Parses release-plan.yaml + execution-status.yaml            │
│  Greps codebase for `story: eNNsNN` tags                    │
│  Produces: specs/traceability-matrix.json                    │
│            specs/TRACEABILITY_LATEST.md                      │
│            specs/codebase-wiki/ (OKF bundle)                  │
├─────────────────────────────────────────────────────────────┤
│  Tier 2: Blind-Spot Detector                                 │
│  scripts/check-blind-spots.sh                                │
│  Reads execution-status.yaml + traceability-matrix.json      │
│  Runs 6 heuristic checks beyond % coverage                   │
│  Produces: specs/blind-spots.json                            │
├─────────────────────────────────────────────────────────────┤
│  Tier 3: Quality Gate                                        │
│  skills/gate-trace/SKILL.md                                  │
│  Reads matrix + blind-spots, applies decision rules          │
│  Applies oracle confidence downgrade                         │
│  Produces: PASS/CONCERNS/FAIL/WAIVED verdict                 │
│            Updated specs/execution-status.yaml                │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. `trace-stories.sh --json` generates the coverage matrix.
2. `check-blind-spots.sh` consumes the matrix to produce blind-spot findings.
3. `gate-trace` consumes both artifacts to produce a gate verdict.

Tiers 1 and 2 can run independently; Tier 3 requires both inputs.

---

## Oracle Resolution Tiers

Story-to-code trace links are resolved via a three-tier oracle, in order of confidence:

| Tier | Method | Confidence | Description |
|------|--------|-----------|-------------|
| 1 | **Explicit tag** | High | `story: eNNsNN` comment tag found via grep in the codebase |
| 2 | **File-name heuristic** | Medium | File name or path matches story title keywords (e.g., `trace-stories.sh` for "traceability matrix") |
| 3 | **Epic capsule task reference** | Low | Task YAML in the epic capsule references a file by name |

### Oracle Confidence Downgrade

The `gate-trace` skill applies confidence downgrades based on the heuristic link ratio:

| Heuristic Ratio (Tier 2 + Tier 3 links) | Downgrade |
|----------------------------------------|-----------|
| > 50% of total links | One level: PASS → CONCERNS, CONCERNS → FAIL |
| > 80% of total links | Two levels: PASS → FAIL, CONCERNS → FAIL |

This ensures the gate is honest — when the agent is guessing (relying on heuristics rather than explicit tags), the verdict reflects lower confidence.

---

## Heuristic Blind-Spot Catalog

`check-blind-spots.sh` runs 6 structural quality checks beyond percentage coverage:

| # | Check | Severity | Description | Remediation |
|---|-------|----------|-------------|-------------|
| A | **verify-gap** | HIGH | Story marked done in execution-status.yaml but no verification evidence at `specs/verifications/eNNsNN-verify.yaml` | Run `verify-work` for the story and persist evidence |
| B | **test-gap** | MEDIUM | Code files tagged for a story but no matching test file found | Add test coverage for the tagged files |
| C | **epic-orphan** | LOW | Story has capsule tasks but no story tags found in any code file | Add `story: eNNsNN` tags to implementing files |
| D | **stale-tag** | LOW | Story marked done but story tags still present in code | Remove old `story:` tags or confirm the story should remain active |
| E | **double-tag** | MEDIUM | Same file tagged with multiple stories | Review whether the file genuinely implements multiple stories (acceptable for shared utilities) |
| F | **bootstrap-testless** | HIGH | Active story has tagged code files but no test files detected | Add test files for the tagged code |

### Severity Levels

- **HIGH:** Blocks the verify-work PASS gate and release-branch merge. Must be resolved.
- **MEDIUM:** Warns but does not block. Review and address at discretion.
- **LOW:** Informational. No action required, but documented for completeness.

---

## Gate Decision Rules

`gate-trace` applies rules in priority order (first match wins):

| Rule | Condition | Verdict |
|------|-----------|---------|
| R1 | Any undone story with 0 code tags | FAIL |
| R2 | Any story marked done but no verification evidence | CONCERNS |
| R3 | P0 story (top WSJF quartile) with 0% code coverage | FAIL |
| R4 | Overall story coverage < 60% | CONCERNS |
| R5 | Overall coverage ≥ 80% + no critical gaps + all verify done | PASS |

### Verdict Semantics

| Verdict | Meaning | Action |
|---------|---------|--------|
| **PASS** | All gates satisfied, oracle confidence acceptable | Proceed with merge |
| **CONCERNS** | Non-critical issues found | Requires explicit human override in `specs/state.yaml` |
| **FAIL** | Critical traceability gap | Block merge — fix gap before proceeding |
| **WAIVED** | Cannot evaluate (missing inputs) | Skip gate — data not available |

---

## CI/CD Integration Points

### sync-skills.yml (CI Pipeline)

```yaml
- name: Traceability Gate
  run: |
    bash scripts/trace-stories.sh --json --strict
    bash scripts/check-blind-spots.sh
```

The `--strict` flag on `trace-stories.sh` fails the CI job if any P0 story has 0% coverage.

### release-branch (Pre-Merge Gate)

The `release-branch` skill invokes `gate-trace` as step 2b before creating a PR or merging. FAIL blocks the merge; CONCERNS requires a human override in `state.yaml`.

### verify-work (Pre-Verification Gate)

The `verify-work` skill runs `check-blind-spots.sh` as step 5a. HIGH-severity blind-spot findings block the PASS gate.

---

## How to Interpret Results

### Reading the Coverage Matrix

Open `specs/TRACEABILITY_LATEST.md` for a human-readable table. Key fields:
- **Dark Stories:** Stories with no code links at all. These are the highest priority to fix.
- **Orphan Tags:** Story tags found in code that don't match any known story.
- **Stale Tags:** Tags for stories that are marked done but still present in code.

### Reading Blind Spots

Open `specs/blind-spots.json`. Each finding includes:
- `check`: Which heuristic triggered (verify-gap, test-gap, etc.)
- `story_id` or `file`: The affected entity
- `severity`: HIGH, MEDIUM, or LOW
- `remediation`: Actionable hint for fixing the finding

### Resolving a FAIL Verdict

1. Read the gate-trace rationale in the output.
2. Check `specs/TRACEABILITY_LATEST.md` for dark stories.
3. Check `specs/blind-spots.json` for HIGH-severity findings.
4. Add `story: eNNsNN` tags to the implementing code files.
5. Re-run `bash scripts/trace-stories.sh --json`.
6. Re-run `bash scripts/check-blind-spots.sh`.
7. Re-run `gate-trace` to confirm PASS.

### Overriding a CONCERNS Verdict

When `gate-trace` returns CONCERNS:
1. Review the rationale — understand what non-critical issues exist.
2. Add to `specs/state.yaml` under `handoff.context`:
   ```yaml
   traceability_override: "CONCERNS accepted, reason: <your explanation>"
   ```
3. Proceed with the release.

CONCERNS overrides should be rare and well-documented. They exist for cases where the heuristic is correct but contextually justified (e.g., a documentation-only story with no code tags is technically "dark" but intentional).

---

## References

- `scripts/trace-stories.sh` (e38s01) — coverage matrix builder.
- `scripts/check-blind-spots.sh` (e38s04) — blind-spot detector.
- `skills/gate-trace/SKILL.md` (e38s06) — quality gate skill.
- `skills/verify-work/SKILL.md` — verification with blind-spot integration (e38s05).
- `skills/release-branch/SKILL.md` — release with traceability gate (e38s07).
- `CONVENTIONS.md` — Traceability Mandate (e38s08).
- `CLAUDE.md` — Commands table entry (e38s08).
- Market survey of 5 traceability tools (2026-07-02) — TEA heuristic blind-spot detection inspiration.
- "The Agentic Coding Stack" article (Murat Aslan, 2026).
