# Stack Profile: Solo Git (local squash land)

Opt-in git integrate profile for solo developers. Keeps protected `main`, worktrees, and verification gates; drops PR ceremony as the default ship path.

## When to use

- Working alone; PR UI feels like overhead
- You still want Conventional Commits, semantic-release, and no direct work on `main`
- Remote CI on PR is optional, not required every task

## Integrate

| Setting | Value |
|---------|--------|
| Mode | `release-branch` → **solo-local** |
| Ship script | `bash scripts/land-branch.sh <branch> "<message>"` |
| PR | Opt-in only (team-pr / branch protection) |
| End state | Primary repo on `main`, worktree removed |

## Day-to-day arc

1. **On main:** `survey-context` → plan skills → `kickoff-branch` (forces clean, updated `main`)
2. **In worktree:** `develop-tdd` / `execute-plan` → `run-evals` → `verify-work` → `audit-code` → `commit-message`
3. **Integrate:** `release-branch` (solo-local) → `scripts/land-branch.sh`
4. **Done when:** `git branch --show-current` is `main`, feature worktree gone

## Hooks

Install via `guard-git`. Hooks block commits/pushes to `main` unless `GIT_BIGPOWERS_LAND=1` (set only by `land-branch.sh`).

## Register in project

Run `compose-workflow` or copy `specs/WORKFLOW-solo-git.md` and note in `specs/STATE.md` Active Decisions.

## Never

- Never land without `release-branch` §1–3 gates (tests, coverage, diff review)
- Never commit on `main` outside `land-branch.sh`
- Never skip `kickoff-branch` for feature work
