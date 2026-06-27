# Release Branch — Reference

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

---

## Solo-local fallback detail

The fallback sequence (Path B above) handles the "remote has moved" case with `git pull --rebase`. Use when `scripts/land-branch.sh` is absent.

**Acceptance:** When fallback runs, main is updated, feature branch is deleted locally, and output states `"used fallback merge (land-branch.sh not found)"`.

## Handoff

Gate: READY -> next: survey-context
Writes: state.yaml handoff.next_skill = survey-context

---

## Reference block 1

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

---

## Reference block 2

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