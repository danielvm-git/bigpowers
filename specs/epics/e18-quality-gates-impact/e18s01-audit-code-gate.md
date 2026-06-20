---
story_id: e18s01
title: "audit-code as hard gate in build-epic step 6"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e18s01: audit-code hard gate

Modify `build-epic/SKILL.md` to make `audit-code` a non-optional gate at step 6.
Current behavior: audit-code is mentioned but not enforced.

## Acceptance Criteria

- [ ] `build-epic/SKILL.md` step 6 invokes audit-code unconditionally
- [ ] `audit-code/SKILL.md` supports `--gate` mode (non-zero exit on failure)
- [ ] Audit result saved to `specs/verifications/AUDIT-<epic>-<story>.md`
- [ ] Failed audit → loop back to develop-tdd
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

## Verification

```bash
grep -c "audit-code" build-epic/SKILL.md | awk '{if($1>=3) print "OK: audit-code referenced"; else print "FAIL: only " $1 " refs"}'
grep -c "gate\|--gate\|non-zero" audit-code/SKILL.md | awk '{if($1>=2) print "OK: gate mode"; else print "FAIL: no gate mode"}'
```

## Implementation Notes

- build-epic step 6: invoke audit-code automatically after verify-work passes
- audit-code produces pass/fail checklist → file specs/verifications/AUDIT-<epic>-<story>.md
- Failed audit → loop back to develop-tdd with audit findings
- Audit result recorded in state.yaml under epic_cycle.audit_result
- audit-code --gate mode exits non-zero on failure for automated integration
