#!/usr/bin/env bash
# cleanup-worktrees.sh — Identify and remove stale git worktrees
set -euo pipefail

# 1. Prune stale metadata (ghost worktrees where directory was manually deleted)
echo "Pruning stale worktree metadata..."
git worktree prune

# 2. List current worktrees
echo "Current worktrees:"
git worktree list --porcelain | grep "^worktree" | awk '{print $2}'

# 3. Identify worktrees whose branches are merged or deleted
echo ""
echo "Checking for stale worktrees (merged branches)..."
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

git worktree list --porcelain | while read -r line; do
    if [[ $line =~ ^worktree\ (.*) ]]; then
        WT_PATH="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^branch\ refs/heads/(.*) ]]; then
        WT_BRANCH="${BASH_REMATCH[1]}"
        
        # Skip main branch
        if [[ "$WT_BRANCH" == "$MAIN_BRANCH" ]]; then
            continue
        fi

        # Check if branch is merged into main
        if git merge-base --is-ancestor "$WT_BRANCH" "$MAIN_BRANCH" 2>/dev/null; then
            echo "MERGED: $WT_BRANCH at $WT_PATH"
            echo "  Run: git worktree remove $WT_PATH && git branch -d $WT_BRANCH"
        else
            # Check if branch still exists (might have been deleted elsewhere)
            if ! git show-ref --verify --quiet "refs/heads/$WT_BRANCH"; then
                echo "MISSING BRANCH: $WT_BRANCH at $WT_PATH (branch was deleted)"
                echo "  Run: git worktree remove $WT_PATH"
            fi
        fi
    fi
done

echo ""
echo "Cleanup complete."
