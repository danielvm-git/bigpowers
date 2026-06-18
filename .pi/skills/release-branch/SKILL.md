---
name: release-branch
description: "Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says \"release\", \"merge\", or \"open a PR\"."
model: haiku
---


# Release Branch

> **HARD GATE** — Do NOT merge or release if tests fail or if coverage gates are not met. If the branch is red, return to `develop-tdd` to fix regressions or add missing tests before proceeding.

Finalize a completed feature branch: verify coverage gates, integrate onto `main`, and clean up the worktree.

## Additional modes

- `--hotfix`: Emergency fix. Cherry-pick to main plus immediate tag. Skip PR in solo profile.

## Integrate mode

Read `specs/state.yaml` key `workflow_mode` first (`team-pr` | `solo-git`). Fall back to sniffing `profiles/solo-git.md` only when the key is absent.

| Mode | When | Ship path |
|------|------|-----------|
| **solo-local** | `workflow_mode: solo-git` (or `profiles/solo-git.md` present as fallback) | `bash scripts/land-branch.sh <branch> "<conventional message>"` |
| **team-pr** | `workflow_mode: team-pr` (default) | `gh pr create` → `gh pr merge --squash` |

If unsure and working alone, prefer **solo-local**.

## Process

### 1. Final verification

```bash
<full test command> && <typecheck command> && <lint command>
git log main...HEAD --oneline | grep -vE "^[a-f0-9]+ (feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+$" && echo "❌ Non-conventional commits found" || echo "✅ Commits verified"
```

- [ ] All tests pass, no type errors, no lint violations, all commits follow Conventional Commits

### 2. Coverage check

- [ ] Overall coverage ≥ 80%; business logic coverage ≥ 95%

### 3. Diff review

- [ ] All commits intentional, no secrets, CONVENTIONS.md compliance

### 4. Decision

Options: **Release (solo-local)** / **Open PR** / **Keep branch** / **Discard**

### 5. Solo-local integrate

Run `commit-message` to produce the squash commit subject, then:
```bash
bash scripts/land-branch.sh <task-slug> "feat(scope): description"
```

### 6. Create PR (team-pr only)

See [REFERENCE.md](REFERENCE.md) for the full PR body template and gh commands.

### 7. Merge (team-pr only)

```bash
gh pr merge --squash --delete-branch
```

`semantic-release` auto-detects the commit, bumps SemVer, tags the repo, generates release notes.

### 7a. Archive completed epic capsule

> **HARD GATE** — When all epic stories are done (all `done` in `execution-status.yaml`), archive the capsule:

```bash
mv specs/epics/eNN-slug specs/epics/archive/
```

### 8. Clean up worktree

```bash
git worktree prune
git worktree remove ../<branch-name> 2>/dev/null || true
git branch -d <branch-name>
```

### 8a. Cycle-time recording

After landing, record delivery metrics. See [REFERENCE.md](REFERENCE.md) for fields and example row.

### 9. Return to main

```bash
git checkout main && git status && pwd
```

Report: "Branch released. Integrate mode: <solo-local|team-pr>. cwd: $(pwd) on $(git branch --show-current)."

## Handoff

Gate: READY -> next: survey-context
Writes: state.yaml handoff.next_skill = survey-context

---

# Release Branch — Reference

## PR body template (team-pr mode)

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

## Worktree cleanup details

```bash
# From the main repo root
git worktree prune
git worktree remove ../<branch-name> 2>/dev/null || true
git branch -d <branch-name>
```

If `git worktree remove` fails due to uncommitted changes, ask: "There are uncommitted changes in the worktree. Force remove? (y/n)". If yes: `git worktree remove -f ../<branch-name>`.

## Cycle-time recording

After landing the branch, record delivery metrics for this story:

1. Write `metrics.story_end` (ISO 8601) to `specs/state.yaml`
2. Compute `cycle_minutes`: `story_end` minus `story_start` in minutes
3. Compute `bcp_per_hour`: `epic_cycle.story_bcps / (cycle_minutes / 60)`
4. Append a row to `specs/metrics/cycle-times.yaml`:

```yaml
- id: e01s01
  bcps: 3
  start: "2026-06-10T09:45:00Z"
  end: "2026-06-10T11:15:00Z"
  cycle_minutes: 90
  bcp_per_hour: 2.0
```
