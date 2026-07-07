# e25s04: Add adversarial review pass after migration (BMAD learning)

**GitHub:** #25
**BCPs:** 2
**Status:** todo

## Problem

BMAD recommends an adversarial review pass before any implementation begins. migrate-spec currently lists this as a checkbox but provides no mechanism. The first time a migrated plan is reviewed is often when bugs are found in code.

## Proposed change

Add an optional Step 7 that runs a lightweight audit against the newly created bigpowers artifacts:

```bash
# Optional: only if user opts in
bts_find "TODO\\|FIXME\\|MISSING" specs/ --print
```

And/or invoke basic audit checks:

```yaml
post_migration_audit:
  performed: true
  findings:
    - severity: high
      artifact: specs/epics/e02-auth-ui/epic.yaml
      finding: "Auth client URL wiring unspecified — browser cannot reach Neon Auth server"
      recommendation: "Define injection mechanism before implementation"
```

Output goes to `specs/archive/MIGRATION-AUDIT.md`.

## Gherkin

```gherkin
Given migration is complete (Steps 1-6 done)
When Step 7 (adversarial review) is offered
Then the user is prompted: "Run adversarial review? [yes / skip]"

Given the user opts in to adversarial review
When the review runs
Then it scans specs/ for TODO, FIXME, and MISSING markers
And it checks that every epic YAML has at least one verify command
And it checks that state.yaml has open_decisions documented
And output is written to specs/archive/MIGRATION-AUDIT.md

Given the user skips the review
When Step 7 completes
Then a note is added to state.yaml handoff:
  "Adversarial review: skipped — review manually before plan-work"
```

## Acceptance Criteria

- [ ] Optional Step 7 with yes/skip gate
- [ ] Scans spec files for TODO/FIXME/MISSING markers
- [ ] Verifies every epic has `verify:` commands
- [ ] Outputs to `specs/archive/MIGRATION-AUDIT.md`
- [ ] Skip records a note in state.yaml handoff
- [ ] `REFERENCE.md` learnings table updated: adversarial review checkbox → checkmark (adopted)

## Files to modify

- `migrate-spec/SKILL.md` — add Step 7 with adversarial review
- `migrate-spec/REFERENCE.md` — update learnings table

## Verify

```bash
grep -c "adversarial\|MIGRATION-AUDIT" migrate-spec/SKILL.md | awk '{if($1>=1) print "OK: adversarial review in SKILL.md"; else print "FAIL"}'
grep -c "MIGRATION-AUDIT" migrate-spec/REFERENCE.md | awk '{if($1>=1) print "OK: audit output in REFERENCE.md"; else print "FAIL"}'
```
