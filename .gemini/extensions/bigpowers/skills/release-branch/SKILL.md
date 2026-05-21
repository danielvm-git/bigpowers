---
name: release-branch
description: "Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says "release", "merge", or "open a PR"."
---


# Release Branch

> **HARD GATE** — Do NOT merge or release if tests fail or if coverage gates are not met. If the branch is red, return to `develop-tdd` to fix regressions or add missing tests before proceeding.

Finalize a completed feature branch: verify coverage gates, open a PR, and clean up the worktree.

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

### 5. Decision

Present the user with the options:

| Option | When to choose |
|--------|---------------|
| **Open PR for Release** | Feature is complete, tests pass, ready to trigger automated release |
| **Keep branch** | More work needed; preserve for later |
| **Discard** | Approach was wrong; start over |

### 6. Create PR (Triggers Automated Release)

The PR title is the **single source of truth** for the version bump. It MUST follow Conventional Commits.

```bash
# Verify PR Title first
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

### 7. Merge (Automated)

Wait for CI to pass. Merge using **Squash and Merge** to ensure the PR title becomes the commit message on `main`.

```bash
gh pr merge --squash --delete-branch
```

`semantic-release` will now automatically:
1. Detect the commit on `main`.
2. Determine the SemVer bump from the commit type.
3. Tag the repo (e.g., `v2.1.0`).
4. Generate release notes.

### 8. Clean up worktree (if using git worktree)

```bash
# From the main repo root
git worktree prune             # clear stale metadata
git worktree remove ../<branch-name> 2>/dev/null || true
git branch -d <branch-name>
```

- If `git worktree remove` fails due to uncommitted changes, ask the user: "There are uncommitted changes in the worktree. Force remove? (y/n)". If yes: `git worktree remove -f ../<branch-name>`.
- If the directory `../<branch-name>` is already missing, `git worktree remove` might fail; the `|| true` ensures the process continues to branch deletion.

Report: "Branch released. PR: <URL>. Worktree cleaned up."
