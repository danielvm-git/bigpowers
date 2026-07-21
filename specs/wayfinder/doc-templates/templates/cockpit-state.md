<!-- wayfinder resolution artifact — T16 (cockpit-yaml), closed -->
<!-- SCHEMA CONTRACT, not a fill-in template. This file is always machine-written by the active
     skill at session boundaries — no human ever authors it directly. Structure only, so
     validate-okf can gate it. Tool-owned per bigspec B8: the producing skill owns this schema. -->
<!-- DISPOSITION: INTERNAL ONLY. Never published to the site. This is session-scratchpad state
     (in-flight handoff notes, skill timings), not project information a reader wants — the one
     deliberate exception in the cockpit group, for a different reason than REVIEW.md (process
     noise, not a safety concern). EXCEPTION: the single derived fact "currently active epic"
     may surface as one line on the Roadmap dashboard view — nothing else from this file renders. -->

## OKF envelope

```yaml
---
okf_kind: cockpit-state
okf_version: "1.0"
generated_by: {skill name that last wrote this — e.g. "skill:survey-context"}
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---
```

## Field contract

| Field | Type | Required | Notes |
|---|---|---|---|
| `active_flow` | string \| null | yes | Which multi-step flow is in progress (e.g. `fix_bug`), or `null` |
| `active_epic` | string \| null | yes | The `eNN` currently being worked, drives the Roadmap dashboard's derived "in progress" line |
| `active_story` | string \| null | yes | |
| `bug_id`, `bug_cycle` | string \| null | if `active_flow` is bug-related | |
| `bigpowers_version` | string | yes | mirror of the tool version in use, non-authoritative |
| `handoff.context` | string | yes | free-text scratchpad note for the next session — internal only, never rendered |
| `handoff.next_skill` | string | yes | drives `next_skill` resumption |
| `handoff.epic` | string | no | |
| `epic_cycle.step` | integer | if in an epic cycle | 0-8, per `build-epic`'s step ladder |
| `epic_cycle.fast_mode` | boolean | if in an epic cycle | |
| `epic_cycle.story_bcps` | number | if in an epic cycle | |
| `epic_cycle.audit_result` | string \| null | no | |
| `epic_cycle.completed_steps` | string (csv) | if in an epic cycle | |
| `metrics.story_start`, `metrics.story_end` | ISO 8601 | while a story is active | feeds `cycle-times.yaml` on completion, see that schema |
| `metrics.skill_timings.<skill>.{calls,total_seconds,avg_seconds}` | object | no | internal telemetry, never rendered |
| `release.ci_verified` | boolean | no | |
| `release.last_commit`, `release.last_epic` | string | no | |

## Dashboard mapping

None. This file does not feed any published view except: the current value of `active_epic`
(and only that field) may be pulled into the Roadmap dashboard's "in progress" indicator. No
other field, including `handoff.context`, is ever rendered.
