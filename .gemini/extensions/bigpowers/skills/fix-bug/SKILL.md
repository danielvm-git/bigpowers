---
name: fix-bug
description: "Bug fix orchestrator — active_flow fix_bug; reads specs/bugs/BUG-*.md; chains investigate-bug, develop-tdd, validate-fix. Use when user reports a defect."
---


# Fix Bug

**Boundary**: Orchestrator flow — chains `investigate-bug` (entry point + RCA via `diagnose-root`) → `develop-tdd` → `validate-fix`. Does not implement RCA or write bug files directly.

Orchestrates **fix_bug** flow without mixing epic build state.

> **HARD GATE** — Set `specs/state.yaml` `active_flow: fix_bug` and `bug_cycle.current_step: 1` before starting.

## Five steps (`bug_cycle` in state.yaml)

| Step | Skill / action |
|------|----------------|
| 1 | `investigate-bug` — create BUG-*.md with RCA |
| 2 | `diagnose-root` — 4-phase root cause analysis |
| 3 | `develop-tdd` — red-green against bug file verify steps |
| 4 | `validate-fix` — re-run failing test, full suite, lint |
| 5 | `release-branch` — PR or solo land the fix |

### Checkpoint / resume

Track progress via `specs/state.yaml` `bug_cycle`:
- `bug_cycle.current_step`: current step (1–5)
- `bug_cycle.completed_steps`: completed step numbers
- `handoff.next_skill`: skill for the current step
- On resume, read `bug_cycle.current_step` and continue from there

## Process

1. **Step 1 — investigate-bug:** If no `specs/bugs/BUG-*.md`, run `investigate-bug` first — it handles history check, RCA (via `diagnose-root`), fix approach, and writes the bug file. Increment `bug_cycle.current_step` to 2 on completion.
2. **Step 2 — diagnose-root:** Run 4-phase RCA (reproduce → isolate → hypothesize → verify). Record findings in the bug file. Increment to step 3.
3. **Step 3 — develop-tdd:** `develop-tdd` against the bug file's verify steps. Increment to step 4 on all-green.
4. **Step 4 — validate-fix:** `validate-fix` — re-run failing test, full suite, typecheck, lint. Increment to step 5.
5. **Step 5 — release-branch:** Land the fix via `release-branch`. Clear `bug_cycle` and `active_flow` when done.

## Bug file SoT

One markdown file per bug with frontmatter:

```yaml
bug_id: BUG-001
status: open
severity: high
scope: api
title: Short title
```

## Verify

→ verify: `test -d specs/bugs && bash scripts/sync-bugs-registry.sh`
