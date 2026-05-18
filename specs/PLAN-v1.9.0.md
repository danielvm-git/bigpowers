# Plan: v1.9.0 (Git-Worktree Lifecycle Hardening)

## Context
Improve the reliability of `kickoff-branch` and `release-branch` when using `git worktree`. Current implementations are optimistic and don't handle collisions, "ghost" worktrees, or manual directory deletions well.

## Goals
- [x] Prevent `kickoff-branch` from failing due to existing directories or branches.
- [x] Ensure `release-branch` can recover from manually deleted worktree directories.
- [x] Introduce a standalone cleanup utility for "ghost" worktrees.

## Steps

### 1. Harden `kickoff-branch/SKILL.md`
- **Pre-flight Checks:**
    - Check if `../<task-slug>` directory exists.
    - Check if branch `<task-slug>` exists (`git branch --list <task-slug>`).
- **Conflict Resolution:**
    - If branch exists but no worktree: prompt to use existing branch or delete it.
    - If worktree metadata exists but directory is gone: run `git worktree prune`.
- **Validation:**
    - Verify `cd ../<task-slug>` succeeds before running tests.

### 2. Harden `release-branch/SKILL.md`
- **Robust Cleanup:**
    - Run `git worktree prune` before removal to clear stale metadata.
    - Handle cases where `../<branch-name>` is already missing (success instead of error).
    - Add instruction to use `git worktree remove -f` if uncommitted changes prevent standard removal (after user confirmation).

### 3. Create `scripts/cleanup-worktrees.sh`
- A utility script that:
    1. Runs `git worktree prune`.
    2. Lists all current worktrees.
    3. Identifies and offers to remove "stale" worktrees (where the branch has been merged or deleted).

### 4. Propagate & Verify
- Run `bash scripts/sync-skills.sh` to update artifacts.
- Test `kickoff-branch` in a scenario with a pre-existing "ghost" worktree.

## Out of Scope
- Automatic stashing of changes in `main` (staying with current "clean tree required" rule).
- Support for worktrees inside the repo directory (standardizing on `../<task-slug>`).
