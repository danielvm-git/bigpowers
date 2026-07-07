#!/usr/bin/env bash
# story: e45s16
# rtk-rewrite.sh — PreToolUse hook delegating to rtk's native Bash rewriter.
set -euo pipefail

if command -v rtk >/dev/null 2>&1; then
  exec rtk hook claude
fi

# rtk missing — pass through unchanged (agent should run `bts doctor` / install rtk)
exit 0
