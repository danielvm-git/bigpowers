# Plan: v1.8.0 (Git Sync in Session State)

## Context
Improve `session-state` by automatically anchoring `specs/STATE.md` to the current git branch and commit hash. This prevents "context rot" by making it clear which version of the code the state corresponds to.

## Steps

1. **Update `session-state/SKILL.md` template** → Include `Git Metadata` section in the example format.
2. **Update `session-state/SKILL.md` workflow** → Add steps to fetch and record `git branch` and `git rev-parse HEAD`.
3. **Update `specs/STATE.md` for this project** → Manually sync current git info to verify the new format.
4. **Propagate changes** → Run `bash scripts/sync-skills.sh`.
5. **Finalize** → Update `specs/RELEASE_PLAN.md` status.

## Out of scope
- Automated git-hook based updates (this is agent-driven for now).
- `v1.9.0` git-worktree hardening.
