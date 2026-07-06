#!/usr/bin/env bash
# story: e37s10
render_skill() {
  local out="${HERMES_SKILLS:-.hermes/skills}"
  mkdir -p "$out/${IR_NAME:-_stub}" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode config-bridge ".hermes/config.yaml" "instructions" "AGENTS.md"
}
