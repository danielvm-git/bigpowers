<!-- wayfinder resolution artifact — T23 (workflows-yaml), closed — the map's last fog item -->
<!-- No collision — no TGDP candidate, no public-facing companion (pure internal orchestration
     recipe, same class as tasks.yaml/TEST_PLAN). Confirmed against real live files (plan.yaml,
     ship.yaml, tdd.yaml, etc.): fields match compose-workflow's documented contract exactly, no
     drift. The skill itself confirms this YAML format already superseded a legacy
     `specs/WORKFLOW-<name>.md` markdown predecessor — nothing to reconcile, already settled. -->
<!-- Narrative-OKF (T5's pattern) — authored via an interview (goal, phases, skills, gates),
     human-collaborative, not machine-derived. Per-recipe naming, already correct. -->

---
okf_kind: workflow-recipe
okf_version: "1.0"
generated_by: "skill:compose-workflow"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---

```yaml
name: {recipe-name}
command: /{recipe-name}
description: {one line — what this chain accomplishes}
skills:
  - {skill-1}
  - {skill-2}
args: {optional — skill-specific arguments}
verify: "{a runnable command confirming every skill in the chain actually exists}"
```

{Workflows are orchestration, not automation — do not create one for a task that should be a
single skill; complexity must be justified. Register in `state.yaml`'s Active Decisions, and
reference from `AGENTS.md` so `/{command}` invokes the recipe directly.}
