#!/usr/bin/env bash
# story: e61s01
# Hermes shell hook template — blocks dangerous terminal commands on pre_tool_call.
# Reads JSON event on stdin; emits {"decision":"block","reason":"..."} to block.
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.cmd // empty')

if [[ "$TOOL" != "terminal" || -z "$CMD" ]]; then
  exit 0
fi

case "$CMD" in
  *'git push --force'*|*'git push -f '*|*'reset --hard'*|*'git clean -f'*|*'rm -rf /'*)
    jq -nc --arg reason "BLOCKED: dangerous command pattern in terminal tool" \
      '{decision: "block", reason: $reason}'
    exit 0
    ;;
esac

exit 0
