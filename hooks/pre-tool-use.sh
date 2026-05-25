#!/usr/bin/env bash
# bigpowers — pre-tool-use.sh
# Harness-agnostic Git Safety Hook for Claude Code, Cursor, and Gemini CLI.
# Enforces:
# 1. Block dangerous commands (force push, reset --hard, etc.)
# 2. Enforce Conventional Commits for 'git commit'
# 3. Block direct commits/pushes to protected branches (main, master)
#    unless GIT_BIGPOWERS_LAND=1 (scripts/land-branch.sh only)

set -euo pipefail

# Configuration
PROTECTED_BRANCHES=("main" "master")
DANGEROUS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \\."
  "git restore \\."
  "push --force"
  "push -f"
  "reset --hard"
)
CONVENTIONAL_COMMITS_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:[[:space:]].+'
LAND_MODE="${GIT_BIGPOWERS_LAND:-}"

# Detect mode from environment (for Gemini/Claude/Cursor parity)
# GIT_GUARDRAILS_MODE: claude (default) | cursor | gemini
MODE="${GIT_GUARDRAILS_MODE:-claude}"

deny() {
  local reason="$1"
  if [ "$MODE" = "gemini" ]; then
    jq -nc --arg reason "$reason" '{decision: "deny", reason: $reason}'
  else
    echo "$reason" >&2
    exit 2
  fi
}

# Read input from stdin
INPUT=$(cat)

# Extract command using jq (standard in bigpowers)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  [ "$MODE" = "gemini" ] && echo '{"decision":"allow"}'
  exit 0
fi

# 1. Check for dangerous patterns (git push is NOT blanket-blocked)
for p in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$p"; then
    deny "BLOCKED: '$COMMAND' matches dangerous pattern '$p'. Use a safer approach or ask the user."
  fi
done

# 2. Check for git commit / git push
if [[ "$COMMAND" =~ git[[:space:]]+commit ]] || [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Push to protected branches
  if [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
    PUSH_TARGETS_PROTECTED=false
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$COMMAND" =~ [[:space:]]+$b([[:space:]]|$) ]] \
        || [[ "$COMMAND" =~ :$b([[:space:]]|$) ]] \
        || [[ "$COMMAND" =~ refs/heads/$b ]]; then
        PUSH_TARGETS_PROTECTED=true
        break
      fi
    done
    # Bare `git push` / `git push origin` with no ref (uses upstream from protected HEAD)
    if [ "$PUSH_TARGETS_PROTECTED" = false ]; then
      for b in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$CURRENT_BRANCH" == "$b" ]] && {
          [[ "$COMMAND" =~ ^git[[:space:]]+push$ ]] \
          || [[ "$COMMAND" =~ ^git[[:space:]]+push[[:space:]]+origin$ ]];
        }; then
          PUSH_TARGETS_PROTECTED=true
          break
        fi
      done
    fi
    if [ "$PUSH_TARGETS_PROTECTED" = true ] && [ "$LAND_MODE" != "1" ]; then
      deny "BLOCKED: Direct push to protected branch is forbidden. Use kickoff-branch + release-branch (solo-local: scripts/land-branch.sh) or team-pr via gh."
    fi
  fi

  # Conventional Commits for 'git commit'
  if [[ "$COMMAND" =~ git[[:space:]]+commit ]]; then
    MSG=""
    if [[ "$COMMAND" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
      MSG="${BASH_REMATCH[1]}"
    elif [[ "$COMMAND" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
      MSG="${BASH_REMATCH[1]}"
    fi

    if [ -n "$MSG" ]; then
      SUBJECT=$(echo "$MSG" | head -n 1)
      if [[ ! "$SUBJECT" =~ $CONVENTIONAL_COMMITS_REGEX ]]; then
        deny "BLOCKED: Commit message must follow Conventional Commits: <type>(<scope>): <subject>. Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore."
      fi

      if [ ${#SUBJECT} -gt 72 ]; then
        deny "BLOCKED: Commit subject line must be 72 characters or less."
      fi
    fi

    # Block direct commits to main unless land script is active
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$CURRENT_BRANCH" == "$b" ]]; then
        if [ "$LAND_MODE" != "1" ]; then
          deny "BLOCKED: Direct commits to protected branch '$b' are forbidden. Use kickoff-branch to start a feature branch, or scripts/land-branch.sh to integrate."
        fi
      fi
    done
  fi
fi

# Allow everything else
if [ "$MODE" = "gemini" ]; then
  echo '{"decision":"allow"}'
fi
exit 0
