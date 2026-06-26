# e25s03: Promote handoff block from optional to mandatory Step 4 output

**GitHub:** #24
**BCPs:** 1
**Status:** todo

## Problem

The GSD learning framework has a `handoff` block (last step completed, open decisions, required reading, next skill). migrate-spec currently lists it as an optional checkbox, but manual use during a real migration proved it's immediately useful — the next agent reads the handoff before anything else.

## Proposed change

Make the handoff block a **mandatory** part of Step 4 (generate state.yaml):

```yaml
# In specs/state.yaml (bigpowers state.yaml YAML format, not the legacy markdown template)

handoff:
  last_step_completed: "migrate-spec from {source_framework} to bigpowers"
  open_decisions:
    - "{{list of unresolved decisions found during migration}}"
  required_reading:
    - specs/product/VISION_LATEST.yaml
    - specs/product/SCOPE_LATEST.yaml
    - specs/tech-architecture/TECH_STACK_LATEST.md
    - specs/release-plan.yaml
  next_skill: survey-context
```

The data is already collected during Steps 1–3 (decisions, reading list, source framework). This just formalizes the output.

## Gherkin

```gherkin
Given migrate-spec has completed Steps 1-3
When Step 4 (generate state.yaml) runs
Then the output state.yaml contains a "handoff:" block
And the handoff includes "last_step_completed", "open_decisions", "required_reading", and "next_skill"

Given no open decisions were found during migration
When Step 4 generates the handoff
Then "open_decisions:" is present but empty
And a comment explains: "# None — all decisions resolved during migration"

Given the state.yaml already exists (re-migration)
When Step 4 runs
Then the handoff block is updated (not duplicated)
And the user is prompted: "Handoff block already exists. Update? [yes / skip / merge]"
```

## Acceptance Criteria

- [ ] `handoff:` block is mandatory in Step 4 output
- [ ] Block contains all 4 fields: `last_step_completed`, `open_decisions`, `required_reading`, `next_skill`
- [ ] Empty `open_decisions` annotated with explanation comment
- [ ] Existing handoff triggers update/skip/merge prompt
- [ ] `REFERENCE.md` learnings table updated: handoff checkbox → checkmark (adopted)

## Files to modify

- `migrate-spec/SKILL.md` — update Step 4 to mandate handoff block
- `migrate-spec/REFERENCE.md` — update state.yaml template, update learnings table

## Verify

```bash
grep -c "handoff" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: handoff in SKILL.md"; else print "FAIL"}'
grep -c "last_step_completed" migrate-spec/REFERENCE.md | awk '{if($1>=1) print "OK: handoff fields in REFERENCE.md"; else print "FAIL"}'
```
