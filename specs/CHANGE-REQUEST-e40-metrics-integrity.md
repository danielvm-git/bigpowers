## Change Request: Add epic e40 — Metrics Integrity (Honest, Additive, Benchmarkable)

**Requester:** Daniel | **Date:** 2026-07-03 | **Priority:** High
**Status:** Draft — Pending Approval

### Description

Add a new epic (e40) to the v2.45.0 "Deepening" release that replaces bigpowers'
per-story cycle-time metric with a git-/telemetry-derived, additive, gated
metric emitted as a per-story OKF bundle. The epic bundles all work produced in
the 2026-07-03 session: the `record-cycle-time.sh` script, the
`story-metrics.okf.md` template, the cycle-time research doc, and two adversarial
red-team passes. It absorbs and corrects the existing e35 "DORA Metrics
Extension".

### Business Justification

The current metric (`specs/metrics/cycle-times.yaml`) is unreliable and — because
bigpowers was built with bigpowers — the defect is **self-replicating**: the
same `survey-context` → `release-branch` hand-arithmetic that produced the bad
data ships to every downstream project. Evidence gathered this session: agent
self-reported wall-clock, hand-computed, ungated; outliers up to 120 BCP/hr;
eleven identical templated 45-min/1.3 rows; three `e13` stories sharing identical
start *and* end timestamps. Fixing the data file alone is cosmetic; the fix must
live in the skills. Correcting it also unlocks a trustworthy foundation for a
future benchmark (delivery + cost-efficiency axes), which the current metric
cannot support.

### Impact Analysis

| Area | Impact | Details |
|------|--------|---------|
| Users | Med | Downstream projects gain honest metrics; per-story fields change (`bcp_per_hour` retired → `effort`/`lead_time`/`cost_usd`). Migration is additive. |
| Systems | Med | Touches `release-branch`, `survey-context`, compliance CI, `specs/metrics/`; new `scripts/record-cycle-time.sh` + `scripts/validate-okf.sh`. |
| Processes | Med | build-epic step 8 now derives metrics from git/telemetry instead of agent arithmetic; new provenance gate. |
| Cost | Low | Documentation/skills project; effort is 18 BCP. No infra spend. |

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Additive effort mis-computed (per-story ≠ Σ) | L | H | Global commit-partition rule + runtime `--self-test` asserting Σ == whole-repo; verified this session on interleaving + overnight cases. |
| Harness lacks session usage (Cursor/Gemini) | M | M | Telemetry-first with git-derived effort as documented portable fallback. |
| Lead time summed by mistake | M | M | Field tagged `⌀ median`; validate-okf rejects summing; documented in template + CONVENTIONS. |
| Provenance gate blocks legit merges | L | M | Gate on pipeline ran + `commit_range` resolves, never on a value; warn-then-fail rollout. |
| Overlap/conflict with e35, e39, e31, e23 | M | L | e35 explicitly superseded; e40 reuses e31 gate pattern, e39 OKF bundles, e23 benchmark schema — coordinated, not duplicated. |

### Implementation Plan

| Step | Owner | Timeline | Dependencies |
|------|-------|----------|--------------|
| e40s01 Land `record-cycle-time.sh` + self-test | Agent | Deepening | — (drafted this session) |
| e40s02 Wire into `release-branch`; deprecate hand-arithmetic | Agent | Deepening | e40s01 |
| e40s03 Emit per-story OKF bundle | Agent | Deepening | e40s01, template |
| e40s04 Agent telemetry capture (pi/Claude Code) | Agent | Deepening | e40s03 |
| e40s05 DORA four keys from git/deploy events | Agent | Deepening | e40s02 |
| e40s06 `validate-okf.sh` + provenance gate in CI | Agent | Deepening | e31 gates, e40s03 |
| e40s07 Quarantine fabricated rows (`source: backfilled`) | Agent | Deepening | — |
| e40s08 Benchmark axes scaffold in `specs/benchmarks` | Agent | Deepening | e23, e40s03 |

### Communication Plan

| Audience | Message | Channel | Timing |
|----------|---------|---------|--------|
| bigpowers users | `bcp_per_hour` retired; honest additive effort + DORA + cost telemetry; migration is additive | CHANGELOG + README metrics note | On release |
| Contributors | New metric pipeline: derive from git, gate on provenance, never hand-compute | CONVENTIONS.md + this CR | On approval |

### Rollback Plan

- **Trigger:** provenance gate produces false failures, or the additivity self-test regresses in CI.
- **Steps:** revert the `release-branch`/`survey-context` edits to restore prior (informational) timestamping; leave `record-cycle-time.sh` and OKF template in place (additive, non-breaking); disable the compliance gate via its feature flag.
- **Verification:** `npm run compliance` passes; `bash scripts/run-golden-suite.sh` green; no story blocked from landing.

### Approvals Required

| Approver | Role | Status |
|----------|------|--------|
| Daniel | Maintainer / Solo Developer | Pending |

---

*Artifacts from this session:* `scripts/record-cycle-time.sh`,
`specs/templates/story-metrics.okf.md`, `specs/RESEARCH-cycle-time-metrics.md`,
`specs/epics/e40-metrics-integrity/epic.yaml`. Registered in
`specs/release-plan.yaml`; supersedes `specs/epics/e35-dora-metrics`.
