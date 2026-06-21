---
story_id: e18s02
title: "Wire enforce-first (F.I.R.S.T) into build-epic gate chain"
status: planned
bcps: 1
type: feat
context: infra
---

# Story e18s02: enforce-first integration

Integrate `enforce-first` (F.I.R.S.T rubric) into the build-epic step 6 gate chain as a sub-check after `audit-code`.

## Acceptance Criteria

- [ ] `enforce-first/SKILL.md` has a `--quick` mode (Fast + Independent + Self-Validating)
- [ ] `build-epic/SKILL.md` step 6 invokes enforce-first after audit-code
- [ ] enforce-first violations appended to audit report

## Implementation Steps

**type:** feat
**context:** infra
**Context:** enforce-first exists as a skill but is never called by build-epic. Add --quick mode and wire it into step 6 gate chain.

### 1. Add --quick mode to enforce-first/SKILL.md

Add a `Modes` section at the top with `--quick` mode that checks only F+I+S:
- F (Fast): no slow tests >100ms, full suite <30s
- I (Independent): no shared mutable state between tests
- S (Self-Validating): tests use assertions, not console.log

→ verify: `grep -c 'quick\|--quick\|Fast.*Independent.*Self' enforce-first/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'`

### 2. Add enforce-first --quick to build-epic step 6

In `build-epic/SKILL.md` step 6 sub-section, add enforce-first as sub-check after audit-code:
- Runs `enforce-first --quick` after audit-code passes
- Appends violations to the audit report at `specs/verifications/AUDIT-<epic>-<story>.md`
- On failure: same loop-back to step 4 (develop-tdd)

→ verify: `grep -c 'enforce-first' build-epic/SKILL.md | awk '{if($1>=2) print "OK: " $1 " refs"; else print "FAIL: " $1 " refs"}'`

## Verification Script

1. Run `grep -c '--quick\|quick mode' enforce-first/SKILL.md` — expect ≥1
2. Run `grep -c 'enforce-first' build-epic/SKILL.md` — expect ≥2
3. Run `grep 'enforce-first' build-epic/SKILL.md` — confirm it's in the step 6 sub-section

## Out of scope

- Full F.I.R.S.T mode (R and T checks) — deferred to future
- Modifying develop-tdd to call enforce-first
- Enforce-first awareness of specific test frameworks

## Risks

- The --quick mode relies on agent judgment for "fast" vs "slow" test detection — no timer hook
