#!/usr/bin/env bash
# story: e37s10
render_skill() {
  local out="${ZED_OUT:-.zed/skills}"
  mkdir -p "$out/${IR_NAME:-_stub}" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode copy "${1:-AGENTS.md}"
}
