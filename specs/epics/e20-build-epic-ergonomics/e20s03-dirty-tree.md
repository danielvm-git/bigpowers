---
story_id: e20s03
title: "kickoff-branch pre-commit for spec artifacts — dirty-tree fix"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s03: spec artifact dirty-tree handling

Fix the dirty-tree conflict in `kickoff-branch` where spec artifacts modified
by build-epic itself (state.yaml, execution-status.yaml, epic YAMLs) cause the
"working tree must be clean" gate to fail.

In big-token-saver, this forced 2 stash/pop cycles in one session. The dirty
files were ALL spec artifacts — not unrelated work.

## Acceptance Criteria

- [ ] `kickoff-branch/SKILL.md` has spec-only dirty detection
- [ ] Auto-commit for spec-only dirty trees with user confirmation

## Gherkin Scenarios

```gherkin
Given working tree has uncommitted changes to specs/state.yaml
And specs/epics/e20-build-epic-ergonomics/epic.yaml
And no other files are dirty
When kickoff-branch runs
Then it detects "spec-only" dirty state
And asks: "Commit spec artifacts before kickoff? [Y/n]"
And if confirmed, runs git add specs/ && git commit -m "chore(state): checkpoint before e21s01 kickoff"
And proceeds with the clean tree gate satisfied

Given working tree has uncommitted changes to src/main.rs
And specs/state.yaml
When kickoff-branch runs
Then it reports: "Dirty tree: src/main.rs (not a spec artifact). Stash or commit before proceeding."
```

## Verification

```bash
grep -c "spec.only\|spec.artifact\|auto.commit.*spec\|pre.kickoff" kickoff-branch/SKILL.md | awk '{if($1>=2) print "OK: spec artifact handling"; else print "FAIL: only " $1 " refs"}'
```

## Implementation Notes

- Before checking for clean tree, check if dirty files are only spec artifacts
- Pattern: `specs/state.yaml`, `specs/epics/*.yaml`, `specs/execution-status.yaml`, `specs/epics/*/epic.yaml`
- Auto-commit with user confirmation: `git add specs/ && git commit -m "chore(state): checkpoint before <story> kickoff"`
- Non-spec artifacts still enforce the clean-tree gate
