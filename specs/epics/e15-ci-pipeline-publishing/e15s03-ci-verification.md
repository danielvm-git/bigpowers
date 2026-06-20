---
story_id: e15s03
title: "CI verification step in release-branch + CI dry-run in develop-tdd"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e15s03: CI verification and dry-run

Add CI awareness to two existing skills to close the "push and pray" gap.

In big-token-saver, after pushing to main, the Release workflow failed twice.
There's no step in release-branch to check CI status after push — the agent
declares success and moves on.

## Acceptance Criteria

- [ ] `release-branch/SKILL.md` has step 8b (CI verification)
- [ ] `develop-tdd/SKILL.md` has CI dry-run sub-step for workflow changes
- [ ] `gh run list --limit 1 --branch main --workflow CI --json status,conclusion` documented
- [ ] Timeout: 10 minutes with 30s polling
- [ ] If CI fails: handoff to fix-bug

## Gherkin Scenarios

```gherkin
Given release-branch has pushed feat/bts-map to main
When step 8b (CI verification) runs
Then gh run list shows the CI workflow for main
And if conclusion is success, advance to cleanup
And if conclusion is failure, handoff to fix-bug with the failure URL

Given develop-tdd is modifying .github/workflows/release.yaml
And the workflow has npm publish without NPM_TOKEN secret reference
When the CI dry-run sub-step runs
Then it flags: "WARNING: npm publish step found but no NPM_TOKEN in secrets"
```

## Verification

```bash
grep -c "gh run list\|CI verification\|workflow" release-branch/SKILL.md | awk '{if($1>=2) print "OK: CI verification in release-branch"; else print "FAIL: only " $1 " refs"}'
grep -c "workflow\|actionlint\|pitfall.*ci" develop-tdd/SKILL.md | awk '{if($1>=1) print "OK: CI aware in develop-tdd"; else print "FAIL: not CI aware"}'
```

## Implementation Notes

- release-branch: Step 8b polling with timeout, documented in state.yaml as `release.ci_verified: true`
- develop-tdd: Run yamllint or actionlint on changed workflow files, check common pitfalls
