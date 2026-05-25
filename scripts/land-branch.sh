#!/usr/bin/env bash
# land-branch.sh — Solo-local integrate: squash-merge feature branch onto main and push.
# Requires GIT_BIGPOWERS_LAND=1 for hook exceptions on commit/push to protected branches.
# Usage: bash scripts/land-branch.sh <feature-branch> "<conventional commit message>"
# Run from the primary repository root (not a linked worktree).
set -euo pipefail

CONVENTIONAL_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?: .+'

usage() {
  echo "Usage: $0 <feature-branch> \"<conventional commit message>\" [--skip-verify]" >&2
  echo "  Run from primary repo root after release-branch gates (solo-local mode)." >&2
  exit 1
}

deny() {
  echo "ERROR: $1" >&2
  exit 1
}

SKIP_VERIFY=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--skip-verify" ]; then
    SKIP_VERIFY=true
  else
    ARGS+=("$arg")
  fi
done

FEATURE_BRANCH="${ARGS[0]:-}"
COMMIT_MSG="${ARGS[1]:-}"

[ -n "$FEATURE_BRANCH" ] && [ -n "$COMMIT_MSG" ] || usage

if [[ ! "$COMMIT_MSG" =~ $CONVENTIONAL_REGEX ]]; then
  deny "Commit message must follow Conventional Commits: <type>(<scope>): <subject>"
fi

if [ ${#COMMIT_MSG} -gt 72 ]; then
  deny "Commit subject line must be 72 characters or less"
fi

# Primary worktree only (.git is a directory, not a gitdir pointer file)
if [ -f .git ]; then
  deny "Run from the primary repository root, not a linked worktree (cd to main repo first)"
fi

detect_default_branch() {
  local remote_head
  remote_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
  if [ -n "$remote_head" ]; then
    echo "$remote_head"
    return
  fi
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    deny "Could not detect default branch (main/master)"
  fi
}

DEFAULT_BRANCH=$(detect_default_branch)
REPO_ROOT=$(pwd)

echo "==> Land branch: $FEATURE_BRANCH -> $DEFAULT_BRANCH"
echo "    Repo root: $REPO_ROOT"

if ! git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
  deny "Feature branch '$FEATURE_BRANCH' does not exist"
fi

for protected in main master; do
  if [ "$FEATURE_BRANCH" = "$protected" ]; then
    deny "Cannot land protected branch '$FEATURE_BRANCH'"
  fi
done

run_verify_suite() {
  echo "==> Running pre-land verification..."
  if [ -f package.json ] && command -v jq >/dev/null 2>&1; then
    if jq -e '.scripts.compliance' package.json >/dev/null 2>&1; then
      npm run compliance
      return
    fi
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
      local test_script
      test_script=$(jq -r '.scripts.test' package.json)
      if [ "$test_script" != "echo \"Error: no test specified\" && exit 1" ] && [ "$test_script" != "false" ]; then
        npm test
        return
      fi
    fi
    if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
      npm run lint
    fi
  fi
  if [ -f scripts/sync-skills.sh ]; then
    bash scripts/sync-skills.sh
  fi
}

if [ "$SKIP_VERIFY" = false ]; then
  run_verify_suite
else
  echo "==> Skipping verification (--skip-verify)"
fi

echo "==> Updating $DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  deny "Working tree on $DEFAULT_BRANCH is not clean. Stash or commit first."
fi

if git remote get-url origin >/dev/null 2>&1; then
  git pull --ff-only origin "$DEFAULT_BRANCH" || deny "git pull --ff-only failed; resolve before landing"
fi

if ! git merge-base --is-ancestor "$DEFAULT_BRANCH" "$FEATURE_BRANCH" 2>/dev/null; then
  deny "Feature branch '$FEATURE_BRANCH' is not based on current $DEFAULT_BRANCH (rebase or recreate branch)"
fi

export GIT_BIGPOWERS_LAND=1

echo "==> Squash merge $FEATURE_BRANCH"
git merge --squash "$FEATURE_BRANCH"
if git diff-index --quiet HEAD -- 2>/dev/null; then
  deny "Squash merge produced no changes (already merged?)"
fi

git commit -m "$COMMIT_MSG"
LAND_SHA=$(git rev-parse --short HEAD)
echo "==> Land commit: $LAND_SHA"

if git remote get-url origin >/dev/null 2>&1; then
  echo "==> Pushing $DEFAULT_BRANCH to origin"
  git push origin "$DEFAULT_BRANCH"
fi

# Worktree cleanup
WORKTREE_PATH="../$FEATURE_BRANCH"
if git worktree list --porcelain 2>/dev/null | grep -q "^worktree $WORKTREE_PATH$"; then
  echo "==> Removing worktree $WORKTREE_PATH"
  git worktree remove "$WORKTREE_PATH" 2>/dev/null || git worktree remove -f "$WORKTREE_PATH"
fi
git worktree prune 2>/dev/null || true

if git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
  git branch -d "$FEATURE_BRANCH" 2>/dev/null || {
    echo "WARN: Could not delete branch $FEATURE_BRANCH (not fully merged? use -D manually if intended)"
  }
fi

git checkout "$DEFAULT_BRANCH"

echo ""
echo "Land complete."
echo "  Branch:   $FEATURE_BRANCH (removed)"
echo "  Commit:   $LAND_SHA on $DEFAULT_BRANCH"
echo "  Message:  $COMMIT_MSG"
echo "  cwd:      $(pwd)"
echo "  current:  $(git branch --show-current)"
echo ""
echo "semantic-release will pick up the push to $DEFAULT_BRANCH when configured."
