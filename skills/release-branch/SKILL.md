<!-- story: e38s07 -->
---
name: release-branch
model: haiku
effort: standard
description: Make the merge/PR/keep/discard decision for a feature branch, verify coverage gates, create the PR with gh, and clean up the worktree. Use when a feature is done and ready to ship, or when user says "release", "merge", or "open a PR".
---

# Release Branch

> **HARD GATE** — Do NOT merge or release if tests fail or if coverage gates are not met. If the branch is red, return to `develop-tdd` to fix regressions or add missing tests before proceeding.

Finalize a completed feature branch: verify coverage gates, integrate onto `main`, and clean up the worktree.

## Additional modes

- `--hotfix`: Cherry-pick to main + tag. Skip PR in solo.
- `--squash-state`: Squash `chore(state):` commits before merge.

## Integrate mode

Read `specs/state.yaml` key `workflow_mode` (`team-pr` | `solo-git`). Fall back to `profiles/solo-git.md`.

| Mode | When | Ship path |
|------|------|-----------|
| **solo-local** | `workflow_mode: solo-git` | Auto: `scripts/land-branch.sh` if present, else fallback (Step 5) |
| **team-pr** | `workflow_mode: team-pr` (default) | `gh pr create` → `gh pr merge --squash` |

If unsure, prefer **solo-local**.

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

### 2a. Security gate

- [ ] `specs/security/REVIEW.md` exists and is fresh (matches current branch diff)
- [ ] No unresolved HIGH findings with confidence ≥ 8 (or all documented in `specs/security/EXCEPTIONS.md` with sign-off rationale)

If REVIEW.md is missing or stale → run `security-review` inline. Findings block the merge unless documented in EXCEPTIONS.md.

### 2b. Traceability gate

Run `gate-trace` before merge. FAIL blocks merge; CONCERNS requires explicit override in `specs/state.yaml` (`traceability_override: CONCERNS accepted, reason: <explanation>`). WAIVED if no matrix available.

### 3. Diff review

- [ ] All commits intentional, no secrets, CONVENTIONS.md compliance

### 4. Decision

Options: **Release (solo-local)** / **Open PR** / **Keep branch** / **Discard**

### 5. Solo-local integrate

Run `commit-message` for the squash subject, then land:

```bash
# Path A (preferred):
bash scripts/land-branch.sh <task-slug> "feat(scope): description"
# Path B (fallback if land-branch.sh missing): see REFERENCE.md
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

### 7b. CI verification (solo-local and team-pr)

> **HARD GATE** — Do NOT declare success until CI completes. A push that fails CI is a regression, not a release.

After push (solo-local step 5 or team-pr step 7), run the CI polling script:

```bash
bash scripts/wait-for-ci.sh --timeout 600 --interval 30
```

The script auto-discovers workflow runs for the pushed commit and polls until completion.
See [REFERENCE.md](REFERENCE.md) for exit code semantics and git-only fallback.

- [ ] CI workflow passes after push (wait-for-ci.sh exit 0)
- [ ] `release.ci_verified: true` documented in state.yaml
- On failure: `handoff.next_skill = fix-bug` with the CI failure URL

### 8. Clean up worktree

```bash
git worktree prune
git worktree remove ../<branch-name> 2>/dev/null || true
git branch -d <branch-name>
```

### 8a. Cycle-time recording

After landing, record delivery metrics with the git-derived, additive script:

```bash
bash scripts/record-cycle-time.sh append \
  --story <story_id> --bcps <bcps> \
  --range "$(git merge-base main HEAD)..HEAD" \
  --file specs/metrics/cycle-times.yaml
```

This replaces the previous hand-arithmetic approach (story_end minus story_start).
See [REFERENCE.md](REFERENCE.md) for the git-hours model and field definitions.

### 9. Return to main

```bash
git checkout main && git status && pwd
```

Report: "Branch released. Integrate mode: <solo-local|team-pr>. cwd: $(pwd) on $(git branch --show-current)."

## Verify

→ verify: `command -v gh >/dev/null 2>&1 && test -f specs/state.yaml && test -d skills/verify-work && echo "OK: release-branch dependencies available" || echo "FAIL"`
