#!/usr/bin/env bash
# story: e48s15
# story: e37s05 e37s07
# scenario: SC-e37s07-P0-02
# Cursor skill adapter — renders .cursor/rules/*.mdc from IR globals.

render_skill() {
  # shellcheck source=../lib/adapter-guard.sh
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/adapter-guard.sh"
  bp_assert_safe_skill_name "${IR_NAME-}" cursor >/dev/null || return 1
  if declare -f render_cursor >/dev/null 2>&1; then
    render_cursor
    return
  fi
  local cursor_file="${CURSOR_RULES:-.cursor/rules}/$IR_NAME.mdc"
  {
    echo "---"
    echo "description: \"$IR_DESC_ESCAPED\""
    echo "alwaysApply: false"
    echo "---"
    echo ""
    echo "$IR_BODY"
  } > "$cursor_file"
}

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-CLAUDE.md}"
}

# If stdin is a pipe/redirect, read the SkillIR JSON and render
if [[ ! -t 0 ]]; then
  JSON_INPUT=$(cat)
  if [[ -n "$JSON_INPUT" ]]; then
    IR_NAME=$(echo "$JSON_INPUT" | jq -r '.name')
    IR_DESCRIPTION=$(echo "$JSON_INPUT" | jq -r '.description')
    IR_BODY=$(echo "$JSON_INPUT" | jq -r '.body')
    IR_DESC_ESCAPED=$(echo "$IR_DESCRIPTION" | sed 's/\\/\\\\/g; s/\"/\\"/g')
    render_skill
  fi
fi
