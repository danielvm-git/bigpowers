<!-- wayfinder resolution artifact — T16 (cockpit-yaml), closed -->
<!-- SCHEMA CONTRACT, not a fill-in template. Always machine-written (build-epic, gate-trace),
     validated structurally by validate-okf. Feeds the Epic Status Board — the "which epics are
     done" view named explicitly in this project's original brief. -->

## OKF envelope

```yaml
---
okf_kind: execution-status
okf_version: "1.0"
generated_by: {skill name — e.g. "skill:build-epic" | "skill:gate-trace"}
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---
```

## Field contract

| Field | Type | Required | Notes |
|---|---|---|---|
| `development_status.downgrade_applied` | boolean | yes | true if a story's status was ever manually reverted — a signal worth surfacing, not hiding |
| `development_status.<eNN>` | enum: `todo \| in_progress \| done` | yes, one per epic | epic-level rollup |
| `development_status.<eNNsYY>` | enum: `todo \| in_progress \| done` | yes, one per story | story-level, sole source of truth per CONVENTIONS.md — never duplicated into `epic.yaml`'s own status field |

This is deliberately a **flat key-value map**, not nested — that's the existing, working shape;
the schema formalizes it rather than restructuring it.

## Dashboard mapping

**Epic Status Board** — group by `eNN` prefix, roll story-level statuses up into a completion
percentage per epic, sort by `build_order` from `release-plan.md`. This is the single source for
"which epics are done" — never re-derive epic status from `epic.yaml`'s own field (that file's
status can drift, per the historical bug this project already fixed once: epic-status drift
between `epic.yaml` and this file).
