
# Compose Workflow

## Process

1. Interview: goal, phases, which skills, gates between steps.
2. Write `specs/WORKFLOW-<name>.md`:
   - Trigger ("Use when...")
   - Ordered steps: `skill → artefact → verify`
   - HARD GATEs between phases
3. Register in state.yaml Active Decisions.
4. Optional: reference from `orchestrate-project` Ad-Hoc mode.

## Verify

→ verify: `test -f specs/WORKFLOW-*.md && grep -c "verify:" specs/WORKFLOW-*.md | awk '{if($1>0) print "OK"}'`

See [REFERENCE.md](REFERENCE.md) for template.

---

# Workflow template

```markdown
# WORKFLOW: <name>

**Trigger:** Use when ...

| Step | Skill | Output | verify |
|------|-------|--------|--------|
| 1 | survey-context | STATE.md | ... |
| 2 | research-first | Prior Art | ... |
| 3 | plan-work | RELEASE-PLAN.md | ... |
```
