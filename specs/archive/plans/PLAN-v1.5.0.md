# Plan: v1.5.0 (HARD-GATE Process Hardening)

## Context
Inject bold, high-visibility "HARD GATE" callouts into all execution-heavy skills to prevent agents from skipping critical checkpoints (like planning or success definition).

## Steps

1. **Inject HARD-GATE blocks into `kickoff-branch` and `release-branch`** → verify: `grep "HARD GATE" kickoff-branch/SKILL.md release-branch/SKILL.md`
2. **Inject HARD-GATE blocks into `plan-work`, `execute-plan`, and `develop-tdd`** → verify: `grep "HARD GATE" plan-work/SKILL.md execute-plan/SKILL.md develop-tdd/SKILL.md`
3. **Update `specs/RELEASE_PLAN.md` status** → verify: `grep "v1.5.0" specs/RELEASE_PLAN.md | grep "✅"`

## Out of scope
- Atomic commits (v1.6.0).
