#!/usr/bin/env bash
# story: e37s12
render_skill() {
  # shellcheck source=../lib/adapter-guard.sh
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/adapter-guard.sh"
  bp_assert_safe_skill_name "${IR_NAME-}" continue >/dev/null || return 1
  local rules_dir="${CONTINUE_RULES:-.continue/rules}"
  mkdir -p "$rules_dir" 2>/dev/null || true
  [[ -n "${IR_NAME:-}" ]] && touch "$rules_dir/$IR_NAME.md" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode copy "${1:-AGENTS.md}"
}
