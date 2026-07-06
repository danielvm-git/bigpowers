#!/usr/bin/env bash
# story: e37s05 e37s07
# scenario: SC-e37s07-P0-02
# Cursor skill adapter — renders .cursor/rules/*.mdc from IR globals.

render_skill() {
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
