#!/usr/bin/env bash
# story: e37s05 e37s03

wire_context() {
  source "$(dirname "${BASH_SOURCE[0]}")/../lib/context-wire.sh"
  wire_context_mode config-bridge ".aider.conf.yml" read "AGENTS.md"
}
