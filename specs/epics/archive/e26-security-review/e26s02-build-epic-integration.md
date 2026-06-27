# e26s02: build-epic integration — threat model step

**BCPs:** 3
**Status:** todo

## Problem

`build-epic` has an 8-step cycle that starts with reading epics and ends with
release. There is no step where security concerns are surfaced before work
begins on an epic. Epic-level threat modeling is absent.

## Proposed change

Add **Step 0** to the `build-epic` cycle: *Threat-model the epic scope*.

The step runs the security-review skill against the epic's scope (read from
the epic capsule's `scope.md` or `WORKSPACE.md`). Output is saved to
`specs/security/epics/<epic-id>/THREAT_MODEL.md` with:

- Epic surface area (auth? data pipeline? config parsing? CLI? API?)
- Vulnerability categories most relevant to this epic
- Risk level: LOW / MEDIUM / HIGH / CRITICAL
- Mitigation guidance for each concern

The threat model feeds into story planning (e26s03) and the verify-work scan
(e26s05) later in the cycle.

The cycle becomes:

```
Step 0: Threat-model epic scope → specs/security/epics/<id>/THREAT_MODEL.md
Step 1: Read spec + state
Step 2: Read execution status
...
```

## Gherkin

```gherkin
Given an epic capsule directory exists for an active epic
When build-epic reaches the new Step 0
Then it invokes security-review against the epic scope
And writes THREAT_MODEL.md to specs/security/epics/<epic-id>/
And the threat model includes surface area, risk level, and mitigation guidance

Given an epic with no security-relevant surface area
When Step 0 runs
Then the threat model documents "LOW risk — no security-sensitive paths identified"
And the file still exists for traceability
```

## Acceptance Criteria

- [ ] `build-epic/SKILL.md` updated — Step 0 added before existing Step 1
- [ ] Step 0 produces `specs/security/epics/<epic-id>/THREAT_MODEL.md`
- [ ] Threat model contains: surface area, vuln categories, risk level, mitigation
- [ ] Step numbering in the cycle re-indexed (Step 0 → 8 becomes Step 1 → 9)
- [ ] verify command added for Step 0 output

## Files to modify

- `.pi/skills/build-epic/SKILL.md`

## Verify

```bash
grep -c "Step 0" build-epic/SKILL.md | awk '{if($1>=1) print "OK: Step 0 exists"; else print "FAIL"}'
grep -c "THREAT_MODEL" build-epic/SKILL.md | awk '{if($1>=1) print "OK: THREAT_MODEL.md referenced"; else print "FAIL"}'
```
