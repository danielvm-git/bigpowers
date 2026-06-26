# e25s05: Add two-pass spec writing gate (spec-kit learning)

**GitHub:** #26
**BCPs:** 2
**Status:** todo

## Problem

spec-kit prescribes a two-pass approach: user-journey spec first (approved by stakeholder), then technical-decisions spec. migrate-spec mentions this as a checkbox but provides no mechanism. Mixing user-facing and technical concerns in one pass produces muddy specs.

## Proposed change

Add an optional post-migration substep that coordinates with `elaborate-spec`:

1. After migration, prompt: "Use two-pass spec writing? [yes / no]"
2. If yes, store the gate state in `specs/state.yaml`:

```yaml
two_pass_spec:
  journey_pass: pending
  technical_pass: pending
  approved_at: ""
```

3. On first pass, run `elaborate-spec` for user journeys only
4. Gate: `journey_pass` must be "complete" before technical pass begins
5. On second pass, run `elaborate-spec` for technical decisions

## Gherkin

```gherkin
Given migration is complete
When the two-pass spec gate is offered
Then the user is prompted: "Use two-pass spec writing? [yes / no]"

Given the user opts in to two-pass spec writing
When the gate is activated
Then specs/state.yaml contains a "two_pass_spec:" block
And "journey_pass" is set to "pending"
And "technical_pass" is set to "pending"

Given journey_pass is "pending"
When the user runs elaborate-spec for user journeys
Then the output must be approved by the user (stakeholder sign-off)
And on approval, journey_pass is set to "complete"

Given journey_pass is "complete" but technical_pass is "pending"
When the user runs elaborate-spec for technical decisions
Then it proceeds without the journey-pass gate
And on completion, technical_pass is set to "complete"
```

## Acceptance Criteria

- [ ] Optional post-migration substep with yes/no gate
- [ ] `two_pass_spec:` block written to `specs/state.yaml` when activated
- [ ] Journey pass must complete before technical pass begins
- [ ] `REFERENCE.md` learnings table updated: two-pass checkbox → checkmark (adopted)

## Files to modify

- `migrate-spec/SKILL.md` — add two-pass spec gate substep
- `migrate-spec/REFERENCE.md` — update state.yaml template, learnings table

## Verify

```bash
grep -c "two.pass\|two_pass" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: two-pass gate in SKILL.md"; else print "FAIL"}'
grep -c "two_pass_spec" migrate-spec/REFERENCE.md | awk '{if($1>=1) print "OK: two-pass in REFERENCE.md"; else print "FAIL"}'
```
