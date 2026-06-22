---
name: release-branch
description: "Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says \"release\", \"merge\", or \"open a PR\"."
---


# Release Branch

> **HARD GATE** — Do NOT merge or release if tests fail or if coverage gates are not met. If the branch is red, return to `develop-tdd` to fix regressions or add missing tests before proceeding.

Finalize a completed feature branch: verify coverage gates, integrate onto `main`, and clean up the worktree.

## Additional modes

- `--hotfix`: Emergency fix. Cherry-pick to main plus immediate tag. Skip PR in solo profile.
- `--squash-state`: Squashes all intermediate `chore(state):` commits on the feature branch into a single clean commit before merging. Use this to reduce noise in the main git repository history.

## Integrate mode

Read `specs/state.yaml` key `workflow_mode` first (`team-pr` | `solo-git`). Fall back to sniffing `profiles/solo-git.md` only when the key is absent.

| Mode | When | Ship path |
|------|------|-----------|
| **solo-local** | `workflow_mode: solo-git` (or `profiles/solo-git.md` present as fallback) | Auto-detect: if `scripts/land-branch.sh` exists → use it; else → fallback (see Step 5) |
| **team-pr** | `workflow_mode: team-pr` (default) | `gh pr create` → `gh pr merge --squash` |

If unsure and working alone, prefer **solo-local**.

> **Auto-detect note:** The solo-local path first checks if `scripts/land-branch.sh` exists and is executable. If present, the script handles the full squash-merge workflow. If absent, the built-in fallback sequence runs instead.

## Process

> **Timing:** `bash scripts/bp-timing.sh start release-branch` at invocation; `bash scripts/bp-timing.sh end release-branch` before handoff.

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

Run `commit-message` to produce the squash commit subject. Then auto-detect the integration path:

**Path A — `scripts/land-branch.sh` exists (happy path):**
```bash
bash scripts/land-branch.sh <task-slug> "feat(scope): description"
```

**Path B — `scripts/land-branch.sh` missing (fallback):**
```bash
# Fallback: manual squash-merge when land-branch.sh is absent
FEATURE_BRANCH=<task-slug>
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)

# Ensure we're on the feature branch
if [ "$(git branch --show-current)" != "$FEATURE_BRANCH" ]; then
  git checkout "$FEATURE_BRANCH"
fi

# Checkout default branch and update
git checkout "$DEFAULT_BRANCH"
git pull --rebase origin "$DEFAULT_BRANCH" 2>/dev/null || git pull origin "$DEFAULT_BRANCH"

# Squash-merge the feature branch
git merge --no-ff "$FEATURE_BRANCH" -m "<conventional-commit-message>"

# Push
git push origin "$DEFAULT_BRANCH"

# Clean up local feature branch
git branch -d "$FEATURE_BRANCH"
```

**Report which path was taken.** Print exactly:
- `"used land-branch.sh"` if Path A
- `"used fallback merge (land-branch.sh not found)"` if Path B

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

### 7b. CI verification (solo-local and team-pr)

> **HARD GATE** — Do NOT declare success until CI completes. A push that fails CI is a regression, not a release.

After push (solo-local step 5 or team-pr step 7), verify the CI workflow completes successfully:

```bash
echo "==> Polling CI for main branch..."
TIMEOUT=600   # 10 minutes
INTERVAL=30   # poll every 30 seconds
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  CI_JSON=$(gh run list --limit 1 --branch main --workflow CI --json status,conclusion,headSha,databaseId 2>/dev/null)
  CI_STATUS=$(echo "$CI_JSON" | jq -r '.[0].status // "unknown"')
  CI_CONCLUSION=$(echo "$CI_JSON" | jq -r '.[0].conclusion // ""')
  CI_SHA=$(echo "$CI_JSON" | jq -r '.[0].headSha // ""')
  CI_ID=$(echo "$CI_JSON" | jq -r '.[0].databaseId // ""')

  if [ "$CI_STATUS" = "completed" ] && [ "$CI_CONCLUSION" = "success" ]; then
    echo "OK: CI passed for $(git rev-parse --short HEAD)"
    bp-yaml-set.sh specs/state.yaml release.ci_verified true 2>/dev/null || \
      echo "  (bp-yaml-set not available — manually set release.ci_verified: true in state.yaml)"
    break
  fi

  if [ "$CI_STATUS" = "completed" ] && [ "$CI_CONCLUSION" = "failure" ]; then
    echo "FAIL: CI failed for $(git rev-parse --short HEAD)"
    echo "  Run URL: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$CI_ID"
    echo "  Handoff to fix-bug with the failure URL above."
    return 1
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
  echo "  Waiting... (${ELAPSED}s / ${TIMEOUT}s)"
done

echo "FAIL: CI did not complete within ${TIMEOUT}s timeout"
return 1
```

- [ ] CI workflow passes after push
- [ ] `release.ci_verified: true` documented in state.yaml
- On failure: `handoff.next_skill = fix-bug` with the CI failure URL

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

## Solo-local fallback detail

The fallback sequence (Path B above) handles the "remote has moved" case with `git pull --rebase`. Use when `scripts/land-branch.sh` is absent.

**Acceptance:** When fallback runs, main is updated, feature branch is deleted locally, and output states `"used fallback merge (land-branch.sh not found)"`.

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
