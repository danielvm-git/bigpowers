#!/usr/bin/env bash
# story: e68s01
# scenario: SC-e68s01-P2-02
# qwen hook template — blocks dangerous terminal/git commands (fixed guard logic).
set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.cmd // .command // empty')

if [[ -z "$CMD" ]]; then
  exit 0
fi

case "$CMD" in
  *'git push --force'*|*'git push -f '*|*'reset --hard'*|*'git clean -f'*|*'rm -rf /'*)
    jq -nc --arg reason "BLOCKED: dangerous command pattern" \
      '{decision: "block", reason: $reason, hookVersion: "1.0.0"}'
    exit 0
    ;;
esac

exit 0
