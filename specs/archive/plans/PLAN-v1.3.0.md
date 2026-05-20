# Plan: v1.3.0 (Context Integrity & Process Hardening)

## Context
This release introduces the `session-state` utility skill to prevent context rot and hardens several key execution skills with behavioral gates ("HARD GATES"), "Red Flags" for TDD, and an "Agent Readability" lens for audits. This aligns with the "Gap Closure Strategy" outlined in `specs/RELEASE_PLAN.md` and `specs/COMPARISON.md`.

## Steps

1. **Implement `session-state` skill** → verify: `ls session-state/SKILL.md && grep "session-state" session-state/SKILL.md`
   - Goal: Track implementation decisions and progress in `specs/STATE.md`.
   - Content: Instructions for initializing and updating session state.

2. **Harden `plan-work`, `execute-plan`, and `develop-tdd` with HARD-GATE blocks** → verify: `grep "HARD GATE" plan-work/SKILL.md execute-plan/SKILL.md develop-tdd/SKILL.md`
   - `plan-work`: HARD GATE for `define-success`.
   - `execute-plan`: HARD GATE for `specs/PLAN.md`.
   - `develop-tdd`: HARD GATE for `specs/PLAN.md` or `specs/DIAGNOSIS.md`.

3. **Add "Red Flags" table to `develop-tdd`** → verify: `grep "Red Flags" develop-tdd/SKILL.md`
   - Identifies common agent rationalizations ("tests are already comprehensive", "refactor is out of scope").

4. **Add "Agent Readability" lens to `audit-code`** → verify: `grep "Agent Readability" audit-code/SKILL.md`
   - Checklist for small functions (fits in window), unique naming (grep-able), and explicit types.

5. **Update `RELEASE_PLAN.md` status** → verify: `grep "v1.3.0" specs/RELEASE_PLAN.md | grep "✅"` (after implementation, for now just update sequence)
   - Reconcile already closed gaps (#10, #11).

6. **Regenerate artifacts** → verify: `bash scripts/sync-skills.sh && ls .cursor/rules/session-state.mdc`

7. **Bump version to 1.3.0** → verify: `grep '"version": "1.3.0"' package.json`

## Out of scope
- Implementation of `zoom-out` (v1.6.0).
- Implementation of `handoff` (v1.10.0).

## Risks
- Skill size: Adding documentation to existing skills might make them slightly harder to read, but the benefit of the HARD GATE callouts outweighs this.
