<!-- wayfinder resolution artifact — T16 (cockpit-yaml), closed -->
<!-- SCHEMA CONTRACT, not a fill-in template. Always machine-written (release-branch skill on
     story completion), validated structurally by validate-okf. Feeds the Metrics dashboard. -->
<!-- DATA-INTEGRITY REQUIREMENT (user-confirmed, non-negotiable): a real past incident in this
     data (documented `backfill_note` entries: "Fabricated by agent-self-reported hand-arithmetic,
     e40 remediation") means the dashboard MUST visually distinguish `source: measured` from
     `source: backfilled` — never average or blend them into a single headline number without
     disclosure. This is a rendering rule the dashboard is required to enforce, not optional
     polish. -->

## OKF envelope

```yaml
---
okf_kind: cycle-times
okf_version: "1.0"
generated_by: "skill:release-branch"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---
```

## Field contract

| Field | Type | Required | Notes |
|---|---|---|---|
| `stories[].id` | string (`eNNsYY`) | yes | |
| `stories[].epic` | string (`eNN`) | yes | |
| `stories[].bcps` | number | yes | story-level BCP only — task-level `[BCP N]` annotations are prohibited (CONVENTIONS.md) |
| `stories[].start`, `.end` | ISO 8601 | yes | |
| `stories[].cycle_minutes` | number | yes | derived, `end - start` |
| `stories[].bcp_per_hour` | number | yes | `bcps / cycle_minutes * 60` |
| `stories[].source` | enum: `measured \| backfilled` | **yes, mandatory** | see data-integrity requirement above |
| `stories[].backfill_note` | string | **required when `source: backfilled`** | must state why/how the value was reconstructed, not just that it was |

## Dashboard mapping

**Metrics dashboard** — BCP burndown and velocity (BCP/hr) charts, segmented by epic. **Hard
rule:** `measured` and `backfilled` points render with a distinct visual marker (e.g. solid vs.
hollow point, or a separate series) — a chart that blends them into one indistinguishable line is
a silent lie about how reliable the historical velocity actually is. Any headline "average
BCP/hr" stat must either exclude `backfilled` entries or disclose the split explicitly.
