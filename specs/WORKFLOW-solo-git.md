# WORKFLOW: solo-git

**Trigger:** Use when working alone and PRs feel like overhead; you still want protected `main`, worktrees, Conventional Commits, and semantic-release.

**Profile:** [profiles/solo-git.md](../profiles/solo-git.md)

## Integrate mode

`release-branch` → **solo-local** (not team-pr).

## Steps

| Step | Skill | Output | verify |
|------|-------|--------|--------|
| 1 | survey-context | STATE.md update | `test -f specs/STATE.md` |
| 2 | plan-work / plan-release | RELEASE-PLAN.md | `grep -c "verify:" specs/RELEASE-PLAN.md` |
| 3 | kickoff-branch | worktree + feature branch | `git worktree list \| grep -q <slug>` |
| 4 | develop-tdd or execute-plan | src/ changes | project test command |
| 5 | run-evals | EVALS doc (if applicable) | `test -f specs/EVALS-*.md 2>/dev/null \|\| true` |
| 6 | verify-work | UAT evidence | branch ≠ main |
| 7 | audit-code | checklist pass | (dialogue) |
| 8 | commit-message | conventional message | message matches regex |
| 9 | release-branch (solo-local) | land on main | `bash scripts/land-branch.sh <slug> "<msg>"` |
| 10 | session-state | STATE.md | `git branch --show-current` = main |

## HARD GATEs

- **Plan on main only** — no feature code on `main`/`master`
- **kickoff-branch** before `develop-tdd` / `execute-plan`
- **verify-work** not on `main`/`master`
- **land-branch.sh** only from primary repo root after gates §1–3 of `release-branch`

## End state

- `git branch --show-current` → `main`
- cwd → primary repository root
- Feature worktree at `../<slug>` removed
