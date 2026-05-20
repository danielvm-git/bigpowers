# Plan: v1.6.0 (Atomic Commit-on-Green)

## Context
Update the TDD loop to require a git commit immediately following the "Green" phase (tests passing). This prevents large, untraceable diffs and enforces incremental progress.

## Steps

1. **Update `develop-tdd/SKILL.md` to mandate commits after Green phase** → verify: `grep "Atomic Commits" develop-tdd/SKILL.md`
2. **Update TDD checklist with "Progress committed" item** → verify: `grep "Progress committed" develop-tdd/SKILL.md`
3. **Update `specs/RELEASE_PLAN.md` status** → verify: `grep "v1.6.0" specs/RELEASE_PLAN.md | grep "✅"`

## Out of scope
- Git-aware session state (v1.8.0).
