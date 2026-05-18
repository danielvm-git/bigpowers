
# Kickoff Branch

Create an isolated working environment before touching any code. A clean baseline proves tests pass before you start — so any failure you see later was caused by your changes, not pre-existing issues.

## Process

### 1. Confirm task name

Ask if not already known: "What's the name of this feature or task?" Use it as the branch name slug (kebab-case, max 40 chars).

### 2. Check current state

```bash
git status          # ensure working tree is clean
git log --oneline -5  # confirm you're on the right base branch
```

If working tree is dirty, ask the user to stash or commit first.

### 3. Create worktree + branch

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

Suggest next skill: `develop-tdd` to start the TDD loop, or `execute-plan` if a specs/PLAN.md already exists.
