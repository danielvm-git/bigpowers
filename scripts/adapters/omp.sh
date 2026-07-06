#!/usr/bin/env bash
# story: e37s10
render_skill() {
  local out="${OMP_SKILLS:-.omp/skills}"
  mkdir -p "$out/${IR_NAME:-_stub}" 2>/dev/null || true
}
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-CLAUDE.md}"
}
