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
