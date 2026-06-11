---
name: kickoff-branch
description: "Create a git worktree and feature branch, then verify a clean test baseline before any code is written. Use when starting a new feature or task, when user wants to work in isolation from main, or mentions "start a branch" or "new worktree"."
---


# Kickoff Branch

> **HARD GATE** — Direct work on `main` or `master` is PROHIBITED. Every task MUST start with this skill to create a feature branch or worktree.
>
> **HARD GATE** — Do NOT proceed with development until a clean test baseline is verified. If the current base branch is failing tests, stop and fix the baseline before creating a new worktree.

Create an isolated working environment before touching any code. A clean baseline proves tests pass before you start — so any failure you see later was caused by your changes, not pre-existing issues.

## Process

### 1. Confirm task name

Ask if not already known: "What's the name of this feature or task?" Use it as the branch name slug (kebab-case, max 40 chars).

### 2. Anchor on default branch (main or master)

> **HARD GATE** — Kickoff MUST start from an updated, clean default branch in the **primary** repository root (not a linked worktree).

```bash
# Detect default branch
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)

git checkout "$DEFAULT"
git pull --ff-only origin "$DEFAULT"   # skip if no remote
git status                             # working tree MUST be clean
git log --oneline -5
```

If working tree is dirty, ask the user to stash or commit first. If not on `$DEFAULT` after checkout, stop and fix before continuing.

### 3. Pre-flight & Conflict Resolution

Before creating the worktree, verify the target environment is clean:

```bash
# 1. Check for existing directory
ls -d ../<task-slug> 2>/dev/null

# 2. Check for existing branch
git branch --list <task-slug>

# 3. Check for "ghost" worktrees (metadata exists but directory is gone)
git worktree list | grep "<task-slug>"
```

**Handling Conflicts:**
- **Directory exists:** If `../<task-slug>` already exists, ask the user if they want to use it or delete it.
- **Branch exists:** If the branch exists but no worktree is attached, ask to use the existing branch (`git worktree add ../<task-slug> <task-slug>`) or delete it.
- **Ghost worktree:** If `git worktree list` shows the path but the directory is missing, run `git worktree prune` to clear the stale metadata.

### 4. Create worktree + branch

```bash
# From the main repo root (not another worktree)
git worktree add ../<task-slug> -b <task-slug>
cd ../<task-slug>
```

If the user prefers a branch without a worktree:
```bash
git checkout -b <task-slug>
```

### 4. Verify clean baseline

Run the full test suite and confirm it passes before writing any code:

```bash
# Use the project's test command from CLAUDE.md or package.json
npm test    # or: pytest, go test ./..., cargo test, etc.
```

- [ ] All tests pass
- [ ] No type errors (`npm run typecheck` or equivalent)
- [ ] No lint errors (`npm run lint` or equivalent)

If the baseline is broken, **stop and tell the user**. Do not proceed with development on a broken baseline.

### 5. Confirm readiness

Report the baseline result:
```
✓ Baseline clean: 42 tests passed, 0 failed
Branch: <task-slug>
Worktree: ../<task-slug>
Ready to develop.
```

Suggest next skill: `develop-tdd` to start the TDD loop, or `execute-plan` if `specs/release-plan.yaml + epic capsule directories` already exists.

## Handoff

Gate: READY -> next: develop-tdd
Writes: state.yaml handoff.next_skill = develop-tdd
