#!/usr/bin/env bash
# story: e45s31
# Rank files by git churn for review prioritization (aidd-churn pattern).
# Usage: bash scripts/bp-churn-rank.sh [--since 90.days] [--limit N] [path...]
set -euo pipefail

SINCE="90.days"
LIMIT=20
PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE="${2:?--since requires a value}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:?--limit requires a number}"
      shift 2
      ;;
    -h|--help)
      echo "Usage: bash scripts/bp-churn-rank.sh [--since 90.days] [--limit 20] [path...]"
      exit 0
      ;;
    *)
      PATHS+=("$1")
      shift
      ;;
  esac
done

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "FAIL: not a git repository" >&2
  exit 1
fi

PATHSPEC=""
if [[ ${#PATHS[@]} -gt 0 ]]; then
  PATHSPEC="-- ${PATHS[*]}"
fi

# shellcheck disable=SC2086
git log --since="$SINCE" --name-only --pretty=format: $PATHSPEC \
  | grep -v '^$' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk -v limit="$LIMIT" 'NR <= limit {printf "%4d  %s\n", $1, $2}'
# awk reads to the end instead of `head -n`, which closed the pipe early and
# made `sort` die with SIGPIPE under pipefail (BUG-2026-11-02-pipefail-pipe-race).
