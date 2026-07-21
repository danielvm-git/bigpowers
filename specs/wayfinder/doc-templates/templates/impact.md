<!-- wayfinder resolution artifact — T20 (impact-refactor-traceability), closed -->
<!-- PER-TARGET, not a _LATEST singleton — confirmed against 9 real live files
     (IMPACT-e20-e20s01.md through IMPACT-e38-okf-adoption.md). Same pattern as ADR (per-decision)
     and TEST_PLAN (per-epic). `IMPACT_LATEST.md` is a vestigial single-file leftover from before
     this naming convention took over — retire it, don't keep it as a parallel "current" file. -->
<!-- Narrative-OKF (T5's pattern), HARD GATE before plan-work per the assess-impact skill. -->

---
okf_kind: impact
okf_version: "1.0"
generated_by: "skill:assess-impact"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
target: {eNNsYY or slug}
---

# IMPACT-{eNN}-{sYY or slug} — {one-line description of the change}

**Date:** {YYYY-MM-DD}
**Assessment:** {Lightweight (doc-only / net-new, no dependents) | Full}

## Risk Score: {0-10}

{One or two sentences: what's being changed and the headline reason for the score.}

## Blast Radius

| Item | Status |
|------|--------|
| Code dependents | {list, or "None"} |
| Test coverage gap | {list, or "N/A"} |
| Affected stories | {story IDs that own the touched modules} |
| Build/lint/typecheck | {impact, or "N/A"} |

## Verdict

{Does this proceed straight to plan-work, or does risk score > 7 trigger the mandatory
grill-me session first?}
