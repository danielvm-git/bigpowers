#!/usr/bin/env bash
# story: e64s01
# BeforeTool wrapper — git guardrails for Gemini CLI (GIT_GUARDRAILS_MODE=gemini).
set -euo pipefail

find_repo_root() {
  local d
  d="$(cd "$(dirname "$0")" && pwd)"
  while [[ "$d" != "/" && ! -d "$d/scripts" ]]; do
    d="$(dirname "$d")"
  done
  if [[ ! -d "$d/scripts" ]]; then
    echo "before-tool-git-guard: repo root not found" >&2
    echo '{"decision":"allow"}'
    exit 0
  fi
  echo "$d"
}

ROOT="$(find_repo_root)"
GUARD="$ROOT/skills/guard-git/scripts/block-dangerous-git.sh"
if [[ ! -x "$GUARD" && ! -f "$GUARD" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi
exec env GIT_GUARDRAILS_MODE=gemini bash "$GUARD"
