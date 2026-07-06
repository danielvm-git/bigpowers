#!/usr/bin/env bash
# story: e37s13
wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode symlink "${1:-AGENTS.md}"
}
