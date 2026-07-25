#!/usr/bin/env bash
# land-branch-push.sh — push + protected-branch fallback helpers for land-branch.sh
# story: BUG-2026-07-25-land-branch-protected
set -euo pipefail

if [[ -n "${LAND_BRANCH_PUSH_LOADED:-}" ]]; then return 0; fi
LAND_BRANCH_PUSH_LOADED=1

LAND_PR_FALLBACK=0

is_protected_branch_rejection() {
  local output="$1"
  echo "$output" | grep -qE '(^|[[:space:]])GH006|Changes must be made through a pull request'
}

land_recovery_branch_name() {
  local feature_branch="$1"
  echo "land-recovery/${feature_branch}"
}

land_print_recovery_commands() {
  local recovery_branch="$1"
  local land_sha="$2"
  local default_branch="$3"
  local commit_msg="$4"

  {
    echo "ERROR: Protected-branch fallback failed. Run these commands to recover manually:"
    echo ""
    echo "  git branch $recovery_branch $land_sha"
    echo "  git checkout $default_branch"
    echo "  git fetch origin $default_branch"
    echo "  git reset --hard origin/$default_branch"
    echo "  git push -u origin $recovery_branch"
    echo "  gh pr create --base $default_branch --head $recovery_branch --title \"$commit_msg\""
  } >&2
}

land_fallback_to_pr() {
  local default_branch="$1"
  local land_sha="$2"
  local feature_branch="$3"
  local commit_msg="$4"
  local recovery_branch
  recovery_branch="$(land_recovery_branch_name "$feature_branch")"
  local full_sha
  full_sha="$(git rev-parse "$land_sha")"

  echo "==> Protected branch push rejected; falling back to PR workflow"
  echo "    Recovery branch: $recovery_branch @ $land_sha"

  if git show-ref --verify --quiet "refs/heads/$recovery_branch"; then
    git branch -D "$recovery_branch"
  fi
  git branch "$recovery_branch" "$full_sha"

  git fetch origin "$default_branch"
  git reset --hard "origin/$default_branch"

  if ! git push -u origin "$recovery_branch"; then
    land_print_recovery_commands "$recovery_branch" "$full_sha" "$default_branch" "$commit_msg"
    return 1
  fi

  local pr_body
  pr_body="Automated recovery from \`land-branch.sh\` after protected-branch push rejection on \`$default_branch\`.

Squash commit: \`$land_sha\`
Source feature branch: \`$feature_branch\`"

  if ! gh pr create \
    --base "$default_branch" \
    --head "$recovery_branch" \
    --title "$commit_msg" \
    --body "$pr_body"; then
    land_print_recovery_commands "$recovery_branch" "$full_sha" "$default_branch" "$commit_msg"
    return 1
  fi

  LAND_PR_FALLBACK=1
  echo "==> PR created via protected-branch fallback (local $default_branch reset to origin)"
  return 0
}

land_push_default_branch() {
  local default_branch="$1"
  local land_sha="$2"
  local feature_branch="$3"
  local commit_msg="$4"
  local push_output=""
  local push_status=0

  if push_output=$(git push origin "$default_branch" 2>&1); then
    return 0
  fi
  push_status=$?

  if is_protected_branch_rejection "$push_output"; then
    echo "$push_output" >&2
    land_fallback_to_pr "$default_branch" "$land_sha" "$feature_branch" "$commit_msg"
    return $?
  fi

  echo "$push_output" >&2
  return "$push_status"
}
