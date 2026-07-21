<!-- wayfinder resolution artifact — T16 (cockpit-yaml), closed -->
<!-- SCHEMA CONTRACT, not a fill-in template. Always machine-written (plan-release skill),
     validated structurally by validate-okf. Feeds the published Roadmap dashboard. -->

## OKF envelope

```yaml
---
okf_kind: release-plan
okf_version: "1.0"
generated_by: "skill:plan-release"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---
```

## Field contract

| Field | Type | Required | Notes |
|---|---|---|---|
| `release.version` | string | yes | **non-authoritative mirror** — the real version comes from `gh release view` / git tags, never hand-tracked as truth |
| `release.codename` | string | yes | |
| `release.status` | enum: `planning \| in_progress \| released` | yes | |
| `release.next_release` | string | no | |
| `release.semantic_release` | boolean | yes | |
| `release.bump_hint` | enum: `patch \| minor \| major` | yes | CI decides the real bump at merge; this is intent only |
| `build_order` | array of `eNN` | yes | dependency-gated sequence, may differ from raw WSJF order |
| `epics[].id` | string (`eNN`) | yes | |
| `epics[].title` | string | yes | |
| `epics[].wsjf` | number | yes | (Business Value + Time Criticality + Risk Reduction) / Job Size |
| `epics[].bcps` | number | yes | total BCP for the epic, sum of its stories' BCP |
| `epics[].capsule_dir` | string (path) | yes | |
| `epics[].depends_on` | array of `eNN` | no | |
| `epics[].note` | string | no | |
| `bugs.total`, `.fixed`, `.deferred`, `.wontfix` | integer | no | rolled up from `registry.yaml` |

## Dashboard mapping

**Roadmap dashboard** — one row per epic: title, status, WSJF, BCP, dependency chain. Sort by
`build_order` (not raw WSJF — the two can legitimately differ where dependencies bind). The
`active_epic` value from `cockpit-state.md` marks which row is "in progress."
