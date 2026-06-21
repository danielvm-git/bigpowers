---
story_id: e19s01
title: "craft-skill: quick-fix — fast-path for trivial data-only fixes"
status: backlog
bcps: 3
type: feat
context: infra
---

# Story e19s01: quick-fix skill

Create a `quick-fix` skill that provides a streamlined path for trivial fixes.

Collapses 6 skills into 2 for fixes that are: purely data, no logic change, verifiable
with one assertion. Example: Bosnia flag fix (one dictionary entry) should not require
diagnose-root + TDD plan + bug file + kickoff-branch + release-branch.

## Acceptance Criteria

- [ ] Skill file: `quick-fix/SKILL.md` with verb-noun naming
- [ ] Documents entry criteria as a checklist the agent must evaluate
- [ ] Documents guardrails as hard aborts (>1 file, >5 lines, logic change, etc.)
- [ ] Verification: skill self-test with a mock data fix
- [ ] Skill is listed in SKILL-INDEX.md

## Entry Criteria (ALL must be true)

1. Purely data change — add missing key, fix typo, update config value, correct a constant
2. No logic change, no refactor risk, no API surface change
3. Verifiable with a single assertion (one test, one curl, one grep)
4. Affects ≤ 1 file, ≤ 5 lines changed

## Guardrails (MUST abort if)

- Change touches > 1 file
- Change is > 5 lines
- Any function signature, condition, or loop is modified
- Verify command is more than one pipeline
- Any existing test breaks

## Fast-Path Workflow

1. `quick-fix` — apply the change, run the one-line verify, commit with `fix:` message
2. `release-branch` — merge and ship (existing skill)

Skipped skills (with justification logged in commit body):
- investigate-bug, diagnose-root, develop-tdd, kickoff-branch

## Verification

```bash
test -f quick-fix/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: quick-fix" quick-fix/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "data.only\|trivial\|fast.path\|guardrail\|abort" quick-fix/SKILL.md && echo "OK: entry criteria and guardrails"
grep -q "quick-fix" SKILL-INDEX.md && echo "OK: in SKILL-INDEX"
```

## Gherkin Scenarios

```gherkin
Given a bug where FLAGS dictionary is missing entry "Bosnia"
And no logic depends on the missing entry (purely a data gap)
When the agent invokes quick-fix
Then the missing entry is added to the dictionary
And a one-line verify confirms the key exists: grep -q "Bosnia" src/flags.js
And a fix: commit is created with the skipped-skills rationale in the body
And the change is ready for release-branch
```

## Implementation Notes

- Entry criteria checklist must be evaluated before every quick-fix invocation
- Guardrails are hard aborts — if any trigger, suggest investigate-bug instead
- Commit message body documents which skills were skipped and why
