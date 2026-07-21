<!-- wayfinder resolution artifact — T19 (tasks-yaml), closed -->
<!-- No collision — checked, no TGDP candidate, no public-facing companion warranted (pure
     internal execution tracking, no reader value). Verified against real live files: no
     per-task BCP annotations exist anywhere (checked via grep across specs/epics/**/*-tasks.yaml)
     — confirms constitution B9's "task-level [BCP N] is prohibited" rule is already followed,
     not violated. `bcps:` correctly lives at the story level (top of file) only. -->
<!-- HARD GATE, load-bearing, do not weaken: every task MUST have a runnable `verify:` command.
     No verify: = not a task (skills/plan-release/SKILL.md:55,126). -->
<!-- Narrative-OKF (T5's pattern) — authored collaboratively via plan-work during planning, not
     machine-derived; `description` fields are prose, not data records. -->
<!-- STRUCTURAL NOTE: unlike adr.md/story.md/scope.md, this template's body is a single fenced
     YAML block with no H1/H2 prose sections — intentional, not an oversight. A task list is a
     flat record (id/description/verify/status per row), not a document organized into
     narrative sections. The narrative-OKF classification here tracks *authorship*
     (human/agent-collaborative during planning) rather than body shape — unlike the data-OKF
     cockpit files, which are machine-written by a script after the fact. -->


---
okf_kind: tasks
okf_version: "1.0"
generated_by: "skill:plan-work"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
story_id: {eNNsYY}
---

```yaml
story_id: {eNNsYY}
title: "{story title}"
status: todo
bcps: {story-level BCP total only — never per-task}
tasks:
  - id: 1
    description: "{one imperative sentence — what this task does}"
    verify: "{a real, runnable shell command — no verify: means this is not a task}"
    status: todo
  - id: 2
    description: "{next task}"
    verify: "{runnable command}"
    status: todo
```

{Tasks are decoupled from the story spec on purpose (SRP) — this file tracks execution, the
story `.md` tracks intent. Update `status` per task as `develop-tdd` completes each RED-GREEN
cycle; do not batch-mark all tasks done at once.}
