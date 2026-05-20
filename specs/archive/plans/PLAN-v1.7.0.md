# Plan: v1.7.0 (Red Flags Table)

## Context
Add a "Red Flags" section to `develop-tdd/SKILL.md` that lists common agent rationalizations and their corresponding realities. This serves as a behavioral guardrail to prevent agents from skipping discipline during the TDD loop.

## Steps

1. **Update `develop-tdd/SKILL.md` with Red Flags table** → verify: `grep -A 10 "## Red Flags" develop-tdd/SKILL.md`
2. **Propagate changes to artifacts** → verify: `bash scripts/sync-skills.sh`
3. **Update `specs/RELEASE_PLAN.md` status** → verify: `grep "v1.7.0" specs/RELEASE_PLAN.md | grep "✅"`

## Out of scope
- Implementation of other gaps identified in `specs/COMPARISON.md`.
