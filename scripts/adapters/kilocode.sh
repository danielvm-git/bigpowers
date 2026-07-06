#!/usr/bin/env bash
# story: e37s11
render_skill() {
  local out="${KILOCODE_RULES:-.kilocode/rules}"
  mkdir -p "$out" 2>/dev/null || true
  [[ -n "${IR_NAME:-}" ]] && touch "$out/$IR_NAME.md" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode copy "${1:-AGENTS.md}"
}
