---
story_id: e20s05
title: "develop-tdd --config mode + build-epic --fast mode"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e20s05: operational modes

Add two operational modes to reduce overhead for specific task types.

## 1. develop-tdd --config mode

For pure-config tasks like "update package.json" there's no test file to write.
The natural RED state is "verify command fails" and GREEN is "verify command passes."

Cycle: RED (verify fails) → GREEN (config change passes verify) → COMMIT

Skips test-writing phase entirely. Still gated: verify must have runnable command,
commit message follows Conventional Commits.

## 2. build-epic --fast mode

Steps 1 (survey-context), 6 (audit-code), and 7 (commit-message) are pure
read-and-report operations. Running them as separate invocations adds token overhead.

Coalesced steps with --fast:
- Step 1+2 together (survey-context + plan-work)
- Step 6+7 together (audit-code + commit-message)
- Steps 3, 4, 5, 8 still run sequentially
- Reduces invocations from 8 to 6

## Acceptance Criteria

- [ ] `develop-tdd/SKILL.md` documents `--config` mode
- [ ] `build-epic/SKILL.md` documents `--fast` mode

## Gherkin Scenarios

```gherkin
Given a task to "add bts_find to package.json keywords"
And no test infrastructure exists for package.json
When develop-tdd --config runs
Then the cycle is: run verify → verify fails (RED) → add keyword → verify passes (GREEN) → commit
And no test file is created

Given build-epic e21 with --fast flag
When the agent invokes build-epic
Then steps 1+2 execute in one invocation
And steps 6+7 execute in one invocation
And total invocations = 6 (not 8)
```

## Verification

```bash
grep -c "\-\-config\|config.mode" develop-tdd/SKILL.md | awk '{if($1>=2) print "OK: --config mode"; else print "FAIL: only " $1 " refs"}'
grep -c "\-\-fast\|fast.mode\|coalesce" build-epic/SKILL.md | awk '{if($1>=2) print "OK: --fast mode"; else print "FAIL: only " $1 " refs"}'
```
