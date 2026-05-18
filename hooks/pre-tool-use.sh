#!/usr/bin/env bash
# bigpowers — pre-tool-use.sh
# Harness-agnostic Git Safety Hook for Claude Code, Cursor, and Gemini CLI.
# Enforces:
# 1. Block dangerous commands (push, reset --hard, etc.)
# 2. Enforce Conventional Commits for 'git commit'
# 3. Block direct commits/pushes to protected branches (main, master)

set -euo pipefail

# Configuration
PROTECTED_BRANCHES=("main" "master")
DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \\."
  "git restore \\."
  "push --force"
  "reset --hard"
)
CONVENTIONAL_COMMITS_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\(.+\))?:[[:space:]].+'

# Detect mode from environment (for Gemini/Claude/Cursor parity)
# GIT_GUARDRAILS_MODE: claude (default) | cursor | gemini
MODE="${GIT_GUARDRAILS_MODE:-claude}"

# Read input from stdin
INPUT=$(cat)

# Extract command using jq (standard in bigpowers)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  [ "$MODE" = "gemini" ] && echo '{"decision":"allow"}'
  exit 0
fi

# 1. Check for dangerous patterns
for p in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$p"; then
    REASON="BLOCKED: '$COMMAND' matches dangerous pattern '$p'. Use a safer approach or ask the user."
    if [ "$MODE" = "gemini" ]; then
      jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
    else
      echo "$REASON" >&2
      exit 2
    fi
    exit 0
  fi
done

# 2. Check for git commit / git push
if [[ "$COMMAND" =~ git[[:space:]]+commit ]] || [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Branch protection
  if [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$COMMAND" =~ [[:space:]]+$b ]] || [[ "$CURRENT_BRANCH" == "$b" ]]; then
        REASON="BLOCKED: Direct push to protected branch '$b' is forbidden. Use a feature branch and PR."
        if [ "$MODE" = "gemini" ]; then
          jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
        else
          echo "$REASON" >&2
          exit 2
        fi
        exit 0
      fi
    done
  fi

  # Conventional Commits for 'git commit'
  if [[ "$COMMAND" =~ git[[:space:]]+commit ]]; then
    # Extract message from -m flag
    MSG=""
    if [[ "$COMMAND" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
      MSG="${BASH_REMATCH[1]}"
    elif [[ "$COMMAND" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
      MSG="${BASH_REMATCH[1]}"
    fi

    if [ -n "$MSG" ]; then
      SUBJECT=$(echo "$MSG" | head -n 1)
      if [[ ! "$SUBJECT" =~ $CONVENTIONAL_COMMITS_REGEX ]]; then
        REASON="BLOCKED: Commit message must follow Conventional Commits: <type>(<scope>): <subject>. Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore."
        if [ "$MODE" = "gemini" ]; then
          jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
        else
          echo "$REASON" >&2
          exit 2
        fi
        exit 0
      fi

      if [ ${#SUBJECT} -gt 72 ]; then
        REASON="BLOCKED: Commit subject line must be 72 characters or less."
        if [ "$MODE" = "gemini" ]; then
          jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
        else
          echo "$REASON" >&2
          exit 2
        fi
        exit 0
      fi
    fi

    # Block direct commits to main
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$CURRENT_BRANCH" == "$b" ]]; then
        REASON="BLOCKED: Direct commits to protected branch '$b' are forbidden. Use kickoff-branch to start a feature branch."
        if [ "$MODE" = "gemini" ]; then
          jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
        else
          echo "$REASON" >&2
          exit 2
        fi
        exit 0
      fi
    done
  fi
fi

# Allow everything else
if [ "$MODE" = "gemini" ]; then
  echo '{"decision":"allow"}'
fi
exit 0
