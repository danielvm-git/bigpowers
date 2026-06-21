---
story_id: e18s01
title: "audit-code as hard gate in build-epic step 6"
status: planned
bcps: 2
type: feat
context: infra
---

# Story e18s01: audit-code hard gate

Modify `build-epic/SKILL.md` to make `audit-code` a non-optional gate at step 6, and add `--gate` mode to `audit-code/SKILL.md` with non-zero exit on failure and audit artifact persistence.

## Acceptance Criteria

- [ ] `build-epic/SKILL.md` step 6 invokes audit-code unconditionally
- [ ] `audit-code/SKILL.md` supports `--gate` mode (non-zero exit on failure)
- [ ] Audit result saved to `specs/verifications/AUDIT-<epic>-<story>.md`
- [ ] Failed audit → loop back to develop-tdd (step 4)
- [ ] state.yaml records `epic_cycle.audit_result`

## Gherkin Scenarios

```gherkin
Given build-epic step 5 (verify-work) has passed
And the story has tests + implementation
When build-epic advances to step 6
Then audit-code runs automatically
And if audit-code fails, build-epic resets to step 4 (develop-tdd)
And audit findings written to specs/verifications/AUDIT-e18s01.md
And state.yaml records audit_result: pass or audit_result: fail
```

## Implementation Steps

**type:** feat
**context:** infra
**Context:** Add a hard gate to build-epic step 6 that runs audit-code unconditionally, with automatic fail-loop back to develop-tdd. audit-code gains a --gate mode for automated CI integration. Audit artifacts are persisted in state.yaml and specs/verifications/.

### 1. Add --gate mode to audit-code/SKILL.md

Add a `--gate` mode section to `audit-code/SKILL.md`:
- In `--gate` mode, exit with non-zero status code when any checklist item fails
- Document the mode in the existing "Modes" section alongside "--quick"
- Gate mode produces: exit 0 (all pass) or exit 1 (any fail), with ✗ items printed to stderr

→ verify: `grep -c 'gate\|--gate\|non-zero\|exit 0\|exit 1' audit-code/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL: only " $1 " matches for gate mode"}'`

### 2. Add audit-code as non-optional gate in build-epic step 6

Modify `build-epic/SKILL.md`:
- Change step 6 table entry from "`audit-code` — self-review checklist" to "`audit-code` — **non-optional gate** (pass/fail; fail → loop back to step 4)"
- Add a process sub-section documenting:
  - Step 6 runs audit-code automatically after verify-work passes
  - audit-code runs with `--gate` mode for automated integration
  - On pass: continue to step 7 (commit-message)
  - On fail: reset to step 4 (develop-tdd) with audit findings
  - Audit result recorded in state.yaml under `epic_cycle.audit_result`

→ verify: `grep -c 'audit-code' build-epic/SKILL.md | awk '{if($1>=4) print "OK: audit-code referenced " $1 " times"; else print "FAIL: only " $1 " refs"}'`

### 3. Add audit result persistence to state.yaml

In `build-epic/SKILL.md`, document that after audit-code runs, state.yaml records:
- `epic_cycle.audit_result: pass` or `epic_cycle.audit_result: fail`
- This can be done via `bash scripts/bp-yaml-set.sh specs/state.yaml epic_cycle.audit_result pass`

→ verify: `grep -c 'audit_result' build-epic/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'`

### 4. Add audit report output to specs/verifications/

In `build-epic/SKILL.md`, document that audit findings are saved to:
- `specs/verifications/AUDIT-<epic>-<story>.md`
- The audit report is written before the loop-back decision

→ verify: `grep -c 'specs/verifications\|AUDIT-' build-epic/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'`

## Verification Script (Step-by-Step)

1. Run `grep -c '--gate\|gate mode\|non-zero\|exit 1' audit-code/SKILL.md` — expect ≥2 matches for gate mode
2. Run `grep -c 'audit-code' build-epic/SKILL.md` — expect ≥4 references (up from 2 currently)
3. Run `grep 'audit_result' build-epic/SKILL.md` — expect at least 1 match for audit_result persistence
4. Run `grep -c 'specs/verifications\|AUDIT-' build-epic/SKILL.md` — expect ≥1 match for audit report output
5. Run `grep 'loop back\|step 4\|develop-tdd' build-epic/SKILL.md` — expect at least 1 match for fail-loop-back

## Out of scope

- Adding new audit checklist items to audit-code (existing checklist is sufficient)
- Modifying other build-epic steps (only step 6)
- Creating the specs/verifications/ directory (created at runtime)
- Integrating with CI pipeline or GitHub Actions

## Risks

- If grep counts are too strict, actual docs may be correct but verify commands fail — use `awk` with flexible thresholds where appropriate
- The --gate mode is documentation-only (agent instructions) — there's no executable code to test, only SKILL.md text patterns
