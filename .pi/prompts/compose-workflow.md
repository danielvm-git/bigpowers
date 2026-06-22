---
description: Chain multiple bigpowers skills into a custom workflow recipe saved in specs/. Use when a project repeats a non-standard skill sequence, or user wants a documented playbook beyond orchestrate-project modes.
---


# Compose Workflow
> **HARD GATE** — **HARD GATE** — Workflows are orchestration, not automation. Do NOT create workflows for tasks that should be single skills. Workflow complexity must be justified.


## Process

1. Interview: goal, phases, which skills, gates between steps.
2. Write `specs/workflows/<name>.yaml`:
   - `name`, `command`, `description`, `skills[]`, `verify`
   - Optional: `args` for skill-specific arguments
3. Register in state.yaml Active Decisions.
4. Optional: reference from `orchestrate-project` Ad-Hoc mode.

> **Prefer the YAML recipe format** over the legacy `specs/WORKFLOW-<name>.md` markdown format.
> YAML recipes are command-mappable, machine-readable, and listed in the Standard Recipe Library.

## Standard Recipe Library

Pre-built recipes in `specs/workflows/` map agentic stack commands to skill chains.
Reference them in AGENTS.md so `/command` directly invokes the matching recipe.

| Command | Workflow | Skill chain |
|---------|----------|-------------|
| `/check-stack` | check-stack | survey-context → assess-impact → setup-environment |
| `/ship` | ship | audit-code → commit-message → release-branch |
| `/tdd` | tdd | develop-tdd → enforce-first |
| `/code-review` | code-review | audit-code → request-review → respond-review |
| `/security` | security | audit-code → request-review |
| `/plan` | plan | survey-context → research-first → plan-work |
| `/build-fix` | build-fix | investigate-bug → diagnose-root → develop-tdd → validate-fix |
| `/e2e` | e2e | smoke-test → verify-work |

Add to `AGENTS.md`:
```
/check-stack = compose-workflow check-stack
/ship        = compose-workflow ship
```

## Verify

→ verify: `ls specs/workflows/*.yaml 2>/dev/null | wc -l | awk '{if($1>=8) print "OK: " $1 " recipes"; else print "FAIL"}'`

See [REFERENCE.md](REFERENCE.md) for template.

---

# Workflow template

```markdown
# WORKFLOW: <name>

**Trigger:** Use when ...

| Step | Skill | Output | verify |
|------|-------|--------|--------|
| 1 | survey-context | state.yaml handoff | ... |
| 2 | research-first | Prior Art in SCOPE_LATEST.yaml | ... |
| 3 | plan-work | epics/eNN-*.yaml tasks | ... |
```
