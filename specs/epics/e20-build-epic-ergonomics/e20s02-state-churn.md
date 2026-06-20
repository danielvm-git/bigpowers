---
story_id: e20s02
title: "Reduce state.yaml commit noise — squash or out-of-band tracking"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s02: state churn reduction

Reduce `state:` commit noise in git history. In big-token-saver, 9% of commits
(3/34) were `chore(state):` — each step of build-epic rewrites `epic_cycle.step`
and handoff fields.

## Acceptance Criteria

- [ ] `release-branch/SKILL.md` documents `--squash-state` flag
- [ ] OR `build-epic/SKILL.md` documents `.bigpowers/cycle-state.json` pattern
- [ ] CONVENTIONS.md has state commit policy

## Options (at least one implemented)

**Option A: --squash-state flag on release-branch**
- release-branch squashes all `chore(state):` commits into one before merging
- `chore(state): eNN cycle (steps 1-8)` — body lists each step transition

**Option B: Non-committed state file**
- Move step tracking to `.bigpowers/cycle-state.json` (gitignored)
- Commit state.yaml only at story boundaries (build-epic step 8)

## Verification

```bash
grep -c "squash.state\|cycle-state.json\|state.commit" release-branch/SKILL.md build-epic/SKILL.md | awk '{sum+=$1} END {if(sum>=2) print "OK: state churn solution (" sum " refs)"; else print "FAIL: only " sum " refs"}'
```

## Gherkin Scenarios

```gherkin
Given an epic with 8 build-epic steps
And each step writes a chore(state): commit
When release-branch --squash-state merges the feature branch
Then 8 chore(state): commits become 1 squashed commit
And the commit body lists each step transition
```
