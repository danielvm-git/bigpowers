#!/usr/bin/env bash
# story: e37s10
render_skill() {
  # shellcheck source=../lib/adapter-guard.sh
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/adapter-guard.sh"
  bp_assert_safe_skill_name "${IR_NAME-}" zed >/dev/null || return 1
  local out="${ZED_OUT:-.zed/skills}"
  mkdir -p "$out/${IR_NAME:-_stub}" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode copy "${1:-AGENTS.md}"
}
