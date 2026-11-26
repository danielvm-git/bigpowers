#!/usr/bin/env bash
# bigpowers — pre-tool-use.sh
# Harness-agnostic Git Safety Hook for Claude Code, Cursor, and Gemini CLI.
# Enforces:
# 1. Block dangerous commands (force push, reset --hard, etc.)
# 2. Enforce Conventional Commits for 'git commit'
# 3. Block direct commits/pushes to protected branches (main, master)
#    unless GIT_BIGPOWERS_LAND=1 (scripts/land-branch.sh only)

set -euo pipefail

# Configuration
PROTECTED_BRANCHES=("main" "master")
# Last-resort literals, used only when the normalizer is unreachable.
LEGACY_DANGEROUS=(
  "git reset --hard"
  "git clean -f"
  "git branch -D"
  "push --force"
  "push -f"
)
CONVENTIONAL_COMMITS_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:[[:space:]].+'
LAND_MODE="${GIT_BIGPOWERS_LAND:-}"

# Detect mode from environment (for Gemini/Claude/Cursor parity)
# GIT_GUARDRAILS_MODE: claude (default) | cursor | gemini
MODE="${GIT_GUARDRAILS_MODE:-claude}"

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

deny() {
  local reason="$1"
  if [ "$MODE" = "gemini" ]; then
    jq -nc --arg reason "$reason" '{decision: "deny", reason: $reason}'
  else
    echo "$reason" >&2
    exit 2
  fi
}

# Read input from stdin
INPUT=$(cat)

# Extract command and file path using jq (standard in bigpowers)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // .tool_input.file_path // .path // .tool_input.path // .target_file // .tool_input.target_file // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool // .name // .tool_name // empty')
# Session working directory from the hook payload. The hook process can start in a
# different checkout than the session (a git worktree session runs from its own
# folder while the harness runs the hook elsewhere), so the branch check below must
# read the session's repo, not the hook's own cwd.
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // .tool_input.cwd // empty')

# 0. Check file editing rules
if [ -n "$FILE_PATH" ]; then
  # e86s01: Generated paths are blocked at edit time
  if [[ "$FILE_PATH" =~ ^\.cursor/rules/ ]] || [[ "$FILE_PATH" =~ ^\.gemini/extensions/ ]] || [[ "$FILE_PATH" =~ ^\.windsurf/ ]]; then
    deny "BLOCKED: Generated file '$FILE_PATH' cannot be edited directly. Edit the source SKILL.md instead and run bash scripts/sync-skills.sh."
  fi

  # e86s02: Tests are locked during fix_bug flow after RED commit
  if [[ "$FILE_PATH" =~ (^|/)test/ ]] || [[ "$FILE_PATH" =~ (^|/)tests/ ]] || [[ "$FILE_PATH" =~ \.test\.[^/]+$ ]] || [[ "$FILE_PATH" =~ _test\.[^/]+$ ]] || [[ "$FILE_PATH" =~ (^|/)test_[^/]+$ ]]; then
    if [ -f specs/state.yaml ] && grep -qE "active_flow:[[:space:]]*fix_bug" specs/state.yaml 2>/dev/null; then
      if git rev-parse --git-dir >/dev/null 2>&1; then
        recent_log=$(git log -n 5 --format=%s 2>/dev/null || true)
        if echo "$recent_log" | grep -qE '^test(\(.+\))?:'; then
          deny "BLOCKED: Test files ($FILE_PATH) are locked during fix_bug after the RED commit. Write the fix in production code (src/), not in tests."
        fi
      fi
    fi
  fi
fi

if [ -z "$COMMAND" ]; then
  [ "$MODE" = "gemini" ] && echo '{"decision":"allow"}'
  exit 0
fi

# 1. Normalized git argv (git push is NOT blanket-blocked)
GIT_VERDICT="$(classify_git_argv "$COMMAND")"
if [ -n "$GIT_VERDICT" ]; then
  deny "BLOCKED: ${GIT_VERDICT#block: }. Use a safer approach or ask the user."
fi
if [ ! -f "$GIT_ARGV" ]; then
  for p in "${LEGACY_DANGEROUS[@]}"; do
    if echo "$COMMAND" | grep -qE "$p"; then
      deny "BLOCKED: '$COMMAND' matches dangerous pattern '$p'. Use a safer approach or ask the user."
    fi
  done
fi

# 2. Check for git commit / git push
if [[ "$COMMAND" =~ git[[:space:]]+commit ]] || [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
  if [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ]; then
    CURRENT_BRANCH=$(git -C "$HOOK_CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  fi

  # Push to protected branches. Judge only the push segment (up to the next
  # command separator): a protected name in trailing prose or a later command
  # must not block an unrelated feature push
  # (BUG-2026-11-03-guard-push-target-matches-text).
  if [[ "$COMMAND" =~ git[[:space:]]+push ]]; then
    PUSH_SEG="${COMMAND%%[;&|]*}"
    PUSH_TARGETS_PROTECTED=false
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$PUSH_SEG" =~ [[:space:]]+$b([[:space:]]|$) ]] \
        || [[ "$PUSH_SEG" =~ :$b([[:space:]]|$) ]] \
        || [[ "$PUSH_SEG" =~ refs/heads/$b ]]; then
        PUSH_TARGETS_PROTECTED=true
        break
      fi
    done
    # Bare `git push` / `git push origin` with no ref (uses upstream from protected HEAD)
    if [ "$PUSH_TARGETS_PROTECTED" = false ]; then
      for b in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$CURRENT_BRANCH" == "$b" ]] && {
          [[ "$COMMAND" =~ ^git[[:space:]]+push$ ]] \
          || [[ "$COMMAND" =~ ^git[[:space:]]+push[[:space:]]+origin$ ]];
        }; then
          PUSH_TARGETS_PROTECTED=true
          break
        fi
      done
    fi
    if [ "$PUSH_TARGETS_PROTECTED" = true ] && [ "$LAND_MODE" != "1" ]; then
      deny "BLOCKED: Direct push to protected branch is forbidden. Use kickoff-branch + release-branch (solo-local: scripts/land-branch.sh) or team-pr via gh."
    fi
  fi

  # Conventional Commits for 'git commit'
  if [[ "$COMMAND" =~ git[[:space:]]+commit ]]; then
    MSG=""
    if [[ "$COMMAND" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
      MSG="${BASH_REMATCH[1]}"
    elif [[ "$COMMAND" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
      MSG="${BASH_REMATCH[1]}"
    fi

    if [ -n "$MSG" ]; then
      SUBJECT=$(echo "$MSG" | head -n 1)
      if [[ ! "$SUBJECT" =~ $CONVENTIONAL_COMMITS_REGEX ]]; then
        deny "BLOCKED: Commit message must follow Conventional Commits: <type>(<scope>): <subject>. Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore."
      fi

      if [ ${#SUBJECT} -gt 72 ]; then
        deny "BLOCKED: Commit subject line must be 72 characters or less."
      fi

      # Block AI agent attribution (P1 — NEVER Co-authored-by:). The footer may
      # ride ANY -m paragraph, not only the first; the subject check above only
      # reads the first paragraph, so scan the whole command for the token
      # (BUG-2026-11-03-guard-attribution-second-m).
      if echo "$COMMAND" | grep -qiE 'co[- ]authored[- ]by:[[:space:]]'; then
        deny "BLOCKED: Commit must not include Co-authored-by: footer. All commits must appear as if authored solely by the human user (CONVENTIONS.md § Git Attribution)."
      fi
    fi

    # Block direct commits to main unless land script is active
    for b in "${PROTECTED_BRANCHES[@]}"; do
      if [[ "$CURRENT_BRANCH" == "$b" ]]; then
        if [ "$LAND_MODE" != "1" ]; then
          deny "BLOCKED: Direct commits to protected branch '$b' are forbidden. Use kickoff-branch to start a feature branch, or scripts/land-branch.sh to integrate."
        fi
      fi
    done
  fi
fi

# Allow everything else
if [ "$MODE" = "gemini" ]; then
  echo '{"decision":"allow"}'
fi
exit 0
