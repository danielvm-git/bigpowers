---
name: release-branch
model: haiku
description: Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says "release", "merge", or "open a PR".
---

# Release Branch

> **HARD GATE** — Do NOT merge or release if tests fail or if coverage gates are not met. If the branch is red, return to `develop-tdd` to fix regressions or add missing tests before proceeding.

Finalize a completed feature branch: verify coverage gates, integrate onto `main`, and clean up the worktree.

## Integrate mode

Choose mode from project profile or explicit user request:

| Mode | When | Ship path |
|------|------|-----------|
| **solo-local** | `profiles/solo-git.md` or `specs/WORKFLOW-solo-git.md` active | `bash scripts/land-branch.sh <branch> "<conventional message>"` — no PR |
| **team-pr** | Default, or collaboration / remote CI required | `gh pr create` → `gh pr merge --squash` (§6–7) |

If unsure and working alone, prefer **solo-local**.

## Process

### 1. Final verification

Run the full suite one last time on the feature branch:

```bash
<full test command>
<typecheck command>
<lint command>
# Verify Conventional Commits history
git log main...HEAD --oneline | grep -vE "^[a-f0-9]+ (feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+$" && echo "❌ ERROR: Non-conventional commits found" || echo "✅ Commits verified"
```

- [ ] All tests pass
- [ ] No type errors
- [ ] No lint violations
- [ ] All commits in branch history follow Conventional Commits 1.0.0

### 2. Coverage check

Verify coverage meets the project gates:

- [ ] Overall coverage ≥ 80%
- [ ] Business logic / domain layer coverage ≥ 95%

If coverage is below the gate, stop and return to `develop-tdd` to add missing tests.

### 3. Diff review

```bash
git diff main...HEAD --stat
git log main...HEAD --oneline
```

Confirm:
- [ ] All commits are intentional — no debug commits, no "WIP" commits
- [ ] No secrets, credentials, or personal data in the diff
- [ ] CONVENTIONS.md compliance across all changes

### 4. Decision

Present the user with the options:

| Option | When to choose |
|--------|---------------|
| **Release (solo-local)** | Feature complete; solo profile active — land via script |
| **Open PR for Release** | Feature complete; team-pr mode or remote CI gate needed |
| **Keep branch** | More work needed; preserve for later |
| **Discard** | Approach was wrong; start over |

### 5. Solo-local integrate

From the **primary** repository root (not the feature worktree):

1. Run `commit-message` to produce the squash commit subject.
2. Land:

```bash
bash scripts/land-branch.sh <task-slug> "feat(scope): description"
```

The script will: update `main`, squash-merge, commit, push, remove worktree, delete branch, and leave you on `main`.

Skip duplicate cleanup in §8 if the script succeeded.

### 6. Create PR (team-pr only)

The PR title is the **single source of truth** for the version bump. It MUST follow Conventional Commits.

```bash
PR_TITLE="<type>(<scope>): <description>"
echo "$PR_TITLE" | grep -vE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+$" && echo "❌ ERROR: PR Title must follow Conventional Commits"

gh pr create \
  --title "$PR_TITLE" \
  --body "$(cat <<'EOF'
## Summary
- [What this PR does]
- [Key decisions made]

## Verify
- [ ] All tests pass
- [ ] Coverage gates met (≥80% overall, ≥95% business logic)
- [ ] CONVENTIONS.md compliance verified
- [ ] PR Title follows Conventional Commits (for automated release)

## specs/ artifacts
- [List any specs/ files produced or updated]
EOF
)"
```

### 7. Merge (team-pr only)

Wait for CI to pass. Merge using **Squash and Merge** so the PR title becomes the commit message on `main`.

```bash
gh pr merge --squash --delete-branch
```

`semantic-release` will automatically:
1. Detect the commit on `main`.
2. Determine the SemVer bump from the commit type.
3. Tag the repo (e.g., `v2.1.0`).
4. Generate release notes.

### 8. Clean up worktree (if not done by land-branch.sh)

```bash
# From the main repo root
git worktree prune
git worktree remove ../<branch-name> 2>/dev/null || true
git branch -d <branch-name>
```

- If `git worktree remove` fails due to uncommitted changes, ask the user: "There are uncommitted changes in the worktree. Force remove? (y/n)". If yes: `git worktree remove -f ../<branch-name>`.
- If the directory `../<branch-name>` is already missing, `git worktree remove` might fail; the `|| true` ensures the process continues to branch deletion.

### 9. Return to main (primary worktree)

```bash
cd <primary-repo-root>
git checkout main   # or master
git status
pwd
```

Confirm:
- [ ] Current branch is `main` (or project default)
- [ ] cwd is the primary repository root, not `../<task-slug>`

Report: "Branch released. Integrate mode: <solo-local|team-pr>. cwd: $(pwd) on $(git branch --show-current)."
