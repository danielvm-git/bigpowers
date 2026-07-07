#!/usr/bin/env bash
# story: e45s03
# Mechanical PreToolUse backstop — block oversized Read/Grep/Bash before context bloat.
set -euo pipefail

READ_MAX_BYTES=102400   # 100KB
GREP_MAX_MATCHES=200
BASH_WARN_PATTERNS='^(npm test|pnpm test|yarn test|cargo test|go test|jest|vitest|pytest|rake test|rspec|git log|git diff|docker logs|kubectl logs|find |rg |grep )'

token_mgmt_deny() {
  echo "TOKEN-MGMT BLOCK: $1" >&2
  echo "Use sqz_read_file / sqz_grep / rtk / bts compress per CLAUDE.md § Token Management." >&2
  exit 2
}

INPUT="$(cat)"
TOOL="$(echo "$INPUT" | jq -r '.tool_name // .tool // empty')"
TOOL_INPUT="$(echo "$INPUT" | jq -c '.tool_input // .input // {}')"

case "$TOOL" in
  Read|read)
    PATH_ARG="$(echo "$TOOL_INPUT" | jq -r '.path // .file_path // .file // empty')"
    [[ -n "$PATH_ARG" && -f "$PATH_ARG" ]] || exit 0
    SIZE="$(wc -c < "$PATH_ARG" | tr -d ' ')"
    if (( SIZE > READ_MAX_BYTES )); then
      token_mgmt_deny "Read $PATH_ARG is ${SIZE} bytes (max ${READ_MAX_BYTES}). Use sqz_read_file or bts compress."
    fi
    ;;
  Grep|grep)
    LIMIT="$(echo "$TOOL_INPUT" | jq -r '.head_limit // .max_matches // empty')"
    if [[ -z "$LIMIT" || "$LIMIT" == "null" ]]; then
      token_mgmt_deny "Grep without head_limit (max ${GREP_MAX_MATCHES}). Set head_limit<=${GREP_MAX_MATCHES} or use sqz_grep."
    fi
    if [[ "$LIMIT" =~ ^[0-9]+$ ]] && (( LIMIT > GREP_MAX_MATCHES )); then
      token_mgmt_deny "Grep head_limit=${LIMIT} exceeds ${GREP_MAX_MATCHES}. Lower limit or use sqz_grep."
    fi
    ;;
  Bash|bash|Shell|shell)
    CMD="$(echo "$TOOL_INPUT" | jq -r '.command // empty')"
    [[ -n "$CMD" ]] || exit 0
    if echo "$CMD" | grep -qE 'sqz compress|bts compress|rtk |SQZ_NO_DEDUP'; then
      exit 0
    fi
    if echo "$CMD" | grep -qE "$BASH_WARN_PATTERNS"; then
      token_mgmt_deny "Bash may exceed 500 lines of output. Prefix with rtk or pipe through sqz compress."
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0
