#!/usr/bin/env bash
# story: e64s01
# BeforeTool wrapper — token management backstop (delegates to repo hook when present).
set -euo pipefail

find_repo_root() {
  local d
  d="$(cd "$(dirname "$0")" && pwd)"
  while [[ "$d" != "/" && ! -d "$d/scripts" ]]; do
    d="$(dirname "$d")"
  done
  [[ -d "$d/scripts" ]] && echo "$d" && return 0
  return 1
}

ROOT="$(find_repo_root)" || exit 0
HOOK="$ROOT/scripts/hooks/token-mgmt-pre-tool-use.sh"
[[ -f "$HOOK" ]] || exit 0
exec bash "$HOOK"
