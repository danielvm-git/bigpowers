---
name: release-branch
description: "Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says "release", "merge", or "open a PR"."
---


# Release Branch

Finalize a completed feature branch: verify coverage gates, open a PR, and clean up the worktree.

## Process

### 1. Final verification

Run the full suite one last time on the feature branch:

```bash
<full test command>
<typecheck command>
<lint command>
```

- [ ] All tests pass
- [ ] No type errors
- [ ] No lint violations

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
| **Merge via PR** | Feature is complete, tests pass, ready to ship |
| **Keep branch** | More work needed; preserve for later |
| **Discard** | Approach was wrong; start over |

### 5. Create PR (if merging)

```bash
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "$(cat <<'EOF'
## Summary
- [What this PR does]
- [Key decisions made]

## Verify
- [ ] All tests pass
- [ ] Coverage gates met (≥80% overall, ≥95% business logic)
- [ ] CONVENTIONS.md compliance verified

## specs/ artifacts
- [List any specs/ files produced or updated]
EOF
)"
```

Wait for CI to pass. Then merge:
```bash
gh pr merge --squash --delete-branch
```

### 6. Clean up worktree (if using git worktree)

```bash
# From the main repo root
git worktree remove ../<branch-name>
git branch -d <branch-name>
```

Report: "Branch released. PR: <URL>. Worktree cleaned up."
