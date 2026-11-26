#!/usr/bin/env bash
# Blocks dangerous git commands for Claude Code, Cursor, and Gemini CLI hooks.
# Requires jq on PATH.
# GIT_GUARDRAILS_MODE: claude (default) | cursor | gemini
#   claude/cursor: stderr message, exit 2 on block, exit 0 on allow
#   gemini: JSON with decision on stdout, exit 0 always (allow or deny)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/git-guardrails-core.sh
. "$SCRIPT_DIR/lib/git-guardrails-core.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty')
MODE="${GIT_GUARDRAILS_MODE:-claude}"

if [ -z "$COMMAND" ]; then
  if [ "$MODE" = "gemini" ]; then
    echo '{"decision":"allow"}'
  fi
  exit 0
fi

if PATTERN=$(git_guardrails_first_match "$COMMAND"); then
  REASON="BLOCKED: '$COMMAND' matches dangerous pattern '$PATTERN'. The user has prevented you from doing this."
  case "$MODE" in
    gemini)
      jq -nc --arg reason "$REASON" '{decision: "deny", reason: $reason}'
      exit 0
      ;;
    claude|cursor|*)
      echo "$REASON" >&2
      exit 2
      ;;
  esac
else
  if [ "$MODE" = "gemini" ]; then
    echo '{"decision":"allow"}'
  fi
  exit 0
fi
