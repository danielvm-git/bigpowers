# e25s02: Emit FR-XX / UJ-XX REQUIREMENTS_TRACE.yaml on migration

**GitHub:** #23
**BCPs:** 2
**Status:** todo

## Problem

BMAD sources have rigorous FR-XX (functional requirement) and UJ-XX (user journey) IDs, but migrate-spec produces no traceability artifact. These IDs are silently lost after migration, preventing `trace-requirement` from linking requirements → epics → tests.

## Proposed change

When source has FR-XX or UJ-XX IDs, emit `specs/product/REQUIREMENTS_TRACE.yaml`:

```yaml
# Auto-generated from BMAD FR-XX / UJ-XX IDs
trace:
  - id: FR-001
    description: "User can register with email/password"
    epic: e02-auth-ui
    story: 0.2.3
    verify: "Playwright: fill form, observe redirect to /login"
  - id: UJ-001
    description: "New user completes registration flow"
    epic: e02-auth-ui
    story: 0.2.3
    verify: "Playwright: register → login → dashboard"
```

During migration, the skill should:
1. Detect FR-XX / UJ-XX patterns in source artifacts
2. Map each to its destination epic/story (if determinable from source structure)
3. Emit the trace file
4. Cross-reference with `trace-requirement` skill in REFERENCE.md

## Gherkin

```gherkin
Given source artifacts contain FR-XX or UJ-XX IDs
When migrate-spec Step 3 runs
Then a file specs/product/REQUIREMENTS_TRACE.yaml is created
And every FR-XX or UJ-XX ID from the source appears in the trace

Given source artifacts have NO FR-XX or UJ-XX IDs
When migrate-spec Step 3 runs
Then no REQUIREMENTS_TRACE.yaml is emitted
And a note is added: "No FR-XX/UJ-XX IDs found — traceability file skipped"

Given the trace file already exists (re-migration)
When migrate-spec Step 3 runs
Then it prompts: "REQUIREMENTS_TRACE.yaml exists. Overwrite? [yes / merge / skip]"
```

## Acceptance Criteria

- [ ] `specs/product/REQUIREMENTS_TRACE.yaml` emitted when FR-XX/UJ-XX detected
- [ ] Trace file not emitted when no IDs found (with note)
- [ ] Existing trace file triggers overwrite/merge/skip prompt
- [ ] `REFERENCE.md` learnings table updated: FR-XX/UJ-XX checkbox → checkmark (adopted)

## Files to modify

- `migrate-spec/SKILL.md` — add Step 3 substep for REQUIREMENTS_TRACE.yaml emission
- `migrate-spec/REFERENCE.md` — add output format for trace file, update learnings table

## Create

- `migrate-spec/templates/REQUIREMENTS_TRACE.yaml`

## Verify

```bash
grep -c "REQUIREMENTS_TRACE" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: trace in SKILL.md"; else print "FAIL"}'
test -f migrate-spec/templates/REQUIREMENTS_TRACE.yaml && echo "OK: template exists" || echo "FAIL: no template"
```
