#!/usr/bin/env bash
# wait-for-ci.sh — Poll GitHub Actions until all workflow runs complete
# Usage: wait-for-ci.sh [--timeout SECONDS] [--interval SECONDS] [--branch BRANCH]
#   --timeout   Max seconds to wait (default: 600)
#   --interval  Seconds between polls (default: 30)
#   --branch    Branch to check (default: current branch)
#   --commit    Specific commit SHA to verify (default: HEAD)
#   --json      Output machine-readable JSON on completion
#   --help      Show this message
#
# Exit codes: 0 = all workflows green, 1 = any workflow failed, 2 = timeout, 3 = no gh CLI

set -euo pipefail

TIMEOUT=600
INTERVAL=30
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
COMMIT=""
OUTPUT_JSON=false

usage_ci() {
  sed -n '2,12p' "$0" | sed 's/^# //'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --commit) COMMIT="$2"; shift 2 ;;
    --json) OUTPUT_JSON=true; shift ;;
    --help) usage_ci; exit 0 ;;
    *) echo "Unknown flag: $1"; usage_ci; exit 2 ;;
  esac
done

COMMIT="${COMMIT:-$(git rev-parse HEAD)}"
COMMIT_SHORT="${COMMIT:0:7}"

# ── Git-only fallback ─────────────────────────────────────────────────
if ! command -v gh >/dev/null 2>&1; then
  echo "⚠️  gh CLI not found — using git-only fallback (cannot verify CI status)"
  git fetch origin "$BRANCH" 2>/dev/null || true
  REMOTE_SHA=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")
  if [[ -n "$REMOTE_SHA" ]] && [[ "$REMOTE_SHA" == "$COMMIT" ]]; then
    echo "✅ Push confirmed: remote $BRANCH matches $COMMIT_SHORT"
    echo "⚠️  CI status UNVERIFIED — gh CLI required for workflow polling"
    exit 0
  else
    echo "❌ Push unconfirmed: remote $BRANCH does not match $COMMIT_SHORT"
    exit 1
  fi
fi

# ── Verify gh auth ────────────────────────────────────────────────────
if ! gh auth status 2>/dev/null; then
  echo "⚠️  gh CLI not authenticated — falling back to git-only"
  git fetch origin "$BRANCH" 2>/dev/null || true
  REMOTE_SHA=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")
  if [[ -n "$REMOTE_SHA" ]] && [[ "$REMOTE_SHA" == "$COMMIT" ]]; then
    echo "✅ Push confirmed: remote $BRANCH matches $COMMIT_SHORT"
    echo "⚠️  CI status UNVERIFIED — gh auth required for workflow polling"
    exit 0
  else
    echo "❌ Push unconfirmed"
    exit 1
  fi
fi

# ── Poll CI ───────────────────────────────────────────────────────────
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "unknown")
echo "==> Polling CI for $BRANCH ($COMMIT_SHORT) in $REPO"
echo "    Timeout: ${TIMEOUT}s, Interval: ${INTERVAL}s"

ELAPSED=0
FAILED_WORKFLOWS=()
PASSED_WORKFLOWS=()

while [[ $ELAPSED -lt $TIMEOUT ]]; do
  # Fetch all runs for the branch
  RUNS_JSON=$(gh run list --branch "$BRANCH" --limit 20 --json workflowName,status,conclusion,headSha,databaseId,displayTitle 2>/dev/null || echo "[]")

  # Filter to runs matching our commit
  MATCHING_RUNS=$(echo "$RUNS_JSON" | jq --arg sha "$COMMIT" '[.[] | select(.headSha == $sha)]' 2>/dev/null || echo "[]")

  RUN_COUNT=$(echo "$MATCHING_RUNS" | jq 'length' 2>/dev/null || echo "0")

  if [[ "$RUN_COUNT" -eq 0 ]]; then
    echo "  (${ELAPSED}s) No runs found for $COMMIT_SHORT — waiting for CI to start..."
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
    continue
  fi

  # Check completion
  INCOMPLETE=$(echo "$MATCHING_RUNS" | jq '[.[] | select(.status != "completed")] | length' 2>/dev/null || echo "0")
  FAILURES=$(echo "$MATCHING_RUNS" | jq '[.[] | select(.status == "completed" and .conclusion == "failure")]' 2>/dev/null || echo "[]")
  FAILURE_COUNT=$(echo "$FAILURES" | jq 'length' 2>/dev/null || echo "0")
  SUCCESSES=$(echo "$MATCHING_RUNS" | jq '[.[] | select(.status == "completed" and .conclusion == "success")]' 2>/dev/null || echo "[]")
  SUCCESS_COUNT=$(echo "$SUCCESSES" | jq 'length' 2>/dev/null || echo "0")

  echo "  (${ELAPSED}s) $RUN_COUNT runs: $SUCCESS_COUNT passed, $FAILURE_COUNT failed, $INCOMPLETE pending"

  # All complete?
  if [[ "$INCOMPLETE" -eq 0 ]]; then
    if [[ "$FAILURE_COUNT" -eq 0 ]]; then
      echo "✅ All $SUCCESS_COUNT workflow(s) passed for $COMMIT_SHORT"
      if $OUTPUT_JSON; then
        echo "$SUCCESSES" | jq '{status:"success",commit:$sha,workflows:.}' --arg sha "$COMMIT_SHORT"
      fi
      exit 0
    else
      echo "❌ $FAILURE_COUNT workflow(s) FAILED:"
      echo "$FAILURES" | jq -r '.[] | "    \(.workflowName) — https://github.com/'"$REPO"'/actions/runs/\(.databaseId)"'
      echo ""
      echo "Handoff: set handoff.next_skill = fix-bug in specs/state.yaml"
      if $OUTPUT_JSON; then
        echo "$FAILURES" | jq '{status:"failure",commit:$sha,failed_workflows:.}' --arg sha "$COMMIT_SHORT"
      fi
      exit 1
    fi
  fi

  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "❌ Timeout: CI did not complete within ${TIMEOUT}s"
echo "    Branch: $BRANCH, Commit: $COMMIT_SHORT"
exit 2
