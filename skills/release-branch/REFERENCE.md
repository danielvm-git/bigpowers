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

After landing the branch, record delivery metrics using the git-derived,
additive script (replaces hand-arithmetic):

```bash
bash scripts/record-cycle-time.sh append \
  --story <story_id> --bcps <bcps> \
  --range "$(git merge-base main HEAD)..HEAD" \
  --file specs/metrics/cycle-times.yaml
```

This appends a row to the cycle-times ledger with two separated metrics:

- **effort_hours** — ADDITIVE. Idle-stripped estimated effort from git commit
  history (git-hours model: 120-min session threshold, 120-min first-commit pad).
  Sums exactly to whole-repo effort. NO hand-arithmetic, NO wall-clock includes.
- **lead_time_minutes** — calendar latency from first commit to merge.
  Median-aggregated across stories; NEVER summed.

The script also runs an additivity self-check: Σ(story effort) == whole-repo effort
within rounding tolerance.

### Why not story_start minus story_end?

The previous hand-arithmetic approach (survey-context writes `story_start`,
release-branch writes `story_end`, agent hand-computes `cycle_minutes`) was
retired because:

1. It was **agent-self-reported** — trivially fabricated or mis-subtracted.
2. Wall-clock included **overnight/weekend/UAT gaps** — calendar latency,
   not coding effort.
3. The `bcp_per_hour` metric was **computationally meaningless** (velocity
   derived from a latency measurement).

The new approach derives effort from commit history (objective, reproducible)
and lead time from first commit → merge (honest calendar latency). See
`docs/references/bcp.md` for BCP sizing context and
`scripts/record-cycle-time.sh` for the full algorithm.

---

## CI verification

The CI polling logic has been extracted to `scripts/wait-for-ci.sh`.
See the script's `--help` for usage. Step 7b of the main SKILL.md invokes it directly:

```bash
bash scripts/wait-for-ci.sh --timeout 600 --interval 30
```

The script handles: auto-discovery of all workflows for the current
branch/commit, polling until completion, success/failure/timeout exit codes,
and git-only fallback when `gh` CLI is unavailable.

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
