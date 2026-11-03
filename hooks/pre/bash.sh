#!/usr/bin/env bash
# story: e82s03
# bigpowers — pre-tool-use hook for OMP bash tool
# Shell fallback for runtimes that invoke hooks as processes rather than
# calling the TypeScript extension directly. Blocks dangerous git commands
# and enforces Conventional Commits. Primary implementation lives in
# extensions/omp-hooks.ts (ExtensionAPI tool_call handler).
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty' 2>/dev/null || true)
[ -z "$COMMAND" ] && exit 0

# Last-resort literals, used only when the normalizer is unreachable.
LEGACY_DANGEROUS=(
  "git reset --hard"
  "git clean -f"
  "git branch -D"
  "push --force"
  "push -f"
)
PROTECTED_BRANCHES=("main" "master")
COMMIT_MSG_RE='-m[[:space:]]+"([^"]+)"'
CONVENTIONAL_RE='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?:[[:space:]].+'

# --- Normalized git argv (BUG-2026-11-03-guard-git-flag-normalize, #184) ------
# Literal substring matching cannot see a global flag in front of the subcommand
# or a flag between the subcommand and the destructive option: the destructive
# tokens are all still there, only their position changed. The rules live in
# scripts/lib/git-argv.py and are mirrored in extensions/omp-hooks.ts;
# scripts/test-guard-git-normalize.sh fails if the two disagree on any fixture.
SELF_PATH="${BASH_SOURCE[0]}"
# Only pay for realpath when the hook actually is a symlink (installed copies).
# This hook runs on every tool call, so a spawn per invocation is real latency.
if [ -L "$SELF_PATH" ] && command -v python3 >/dev/null 2>&1; then
  SELF_PATH="$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$SELF_PATH" 2>/dev/null || echo "$SELF_PATH")"
fi
GUARD_ROOT="$(cd "$(dirname "$SELF_PATH")/.." 2>/dev/null && pwd -P || true)"
GIT_ARGV="$GUARD_ROOT/scripts/lib/git-argv.py"

# classify_git_argv <command>: echoes "block: <reason>" or nothing.
# Fast path: a command with no "git" token cannot contain a git invocation, so
# the helper (a python start) is skipped. Falls back to the legacy literal
# patterns when the helper is unreachable (hook symlinked outside the package).
classify_git_argv() {
  local cmd="$1" out=""
  case "$cmd" in
    *git*) ;;
    *) return 0 ;;
  esac
  if command -v python3 >/dev/null 2>&1 && [ -f "$GIT_ARGV" ]; then
    out="$(python3 "$GIT_ARGV" --command "$cmd" 2>/dev/null || true)"
    case "$out" in
      block:*) printf '%s' "$out"; return 0 ;;
      *) return 0 ;;
    esac
  fi
  return 0
}

GIT_VERDICT="$(classify_git_argv "$COMMAND")"
if [ -n "$GIT_VERDICT" ]; then
  printf '{"decision":"block","reason":"BLOCKED: %s"}\n' "${GIT_VERDICT#block: }"
  exit 0
fi
if [ ! -f "$GIT_ARGV" ]; then
  for p in "${LEGACY_DANGEROUS[@]}"; do
    if echo "$COMMAND" | grep -qE "$p"; then
      printf '{"decision":"block","reason":"BLOCKED: dangerous pattern %q"}\n' "$p"
      exit 0
    fi
  done
fi

if [[ "$COMMAND" =~ git[[:space:]]+commit ]]; then
  MSG=""
  # Parentheses inside [[ =~ ]] must come from a variable, not the literal
  # pattern: bash parses `([^"]+)` as a syntax error (pre-existing since #118,
  # so this fallback hook never ran; BUG-2026-11-03-guard-git-flag-normalize).
  if [[ "$COMMAND" =~ $COMMIT_MSG_RE ]]; then MSG="${BASH_REMATCH[1]}"; fi
  if [ -n "$MSG" ] && [[ ! "$MSG" =~ $CONVENTIONAL_RE ]]; then
    echo '{"decision":"block","reason":"BLOCKED: Conventional Commits required"}'
    exit 0
  fi
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  for b in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$BRANCH" == "$b" ]]; then
      printf '{"decision":"block","reason":"BLOCKED: direct commit to %q"}\n' "$b"
      exit 0
    fi
  done
fi

exit 0
