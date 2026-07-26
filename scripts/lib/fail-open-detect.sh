#!/usr/bin/env bash
# story: BUG-2026-07-26-story-verify-never-executed
# fail-open-detect.sh — shared verify-directive fail-open detector.
#
# Extracted from run-skill-verify.sh (#96) so tier-1 (SKILL.md → verify:) and
# tier-2 (epic.yaml story verify:, #106) share ONE detector. A new evasion
# idiom must be rejected everywhere at once; two copies would drift.
#
# Source this file, then call is_fail_open_directive "<cmd>".

if [[ -n "${FAIL_OPEN_DETECT_LOADED:-}" ]]; then return 0; fi
FAIL_OPEN_DETECT_LOADED=1

# A directive is fail-open when it cannot exit non-zero on a broken repo.
# Two families, both checked syntactically because a pipeline's exit status
# is the status of its LAST command:
#   1. explicit swallow  — `|| echo ...`, `|| true`, `|| :`, `; true`, `; exit 0`
#   2. non-asserting tail — pipeline ends in a filter that always exits 0
#      (head/wc/cat/tee/sort/tr/sed/awk/echo/true/:). `grep x | wc -l` is the
#      canonical offender: wc always succeeds, so the grep result is discarded.
# Use an assertion instead, e.g. [ "$(... | wc -l)" -gt 0 ].
FAIL_OPEN_TAIL_CMDS='head|wc|cat|tee|sort|tr|sed|awk|echo|true|:'

is_fail_open_directive() {
  local cmd="$1"

  # Family 1: explicit exit-status swallowing.
  if echo "$cmd" | grep -qE '\|\|[[:space:]]*(echo|true|:)|;[[:space:]]*(true|:|exit[[:space:]]+0)[[:space:]]*$'; then
    return 0
  fi

  # Family 2: pipeline whose last stage never fails.
  # Strip $(...) first — a pipe inside a command substitution feeds an
  # assertion, e.g. [ "$(ls x | wc -l)" -gt 0 ], and is NOT fail-open.
  local stripped="$cmd" prev=""
  while [ "$stripped" != "$prev" ]; do
    prev="$stripped"
    stripped=$(printf '%s' "$stripped" | sed 's/\$([^()]*)/SUBST/g')
  done

  # Only inspect the segment after the final `|` that is not part of `||`.
  local tail_seg
  tail_seg=$(printf '%s' "$stripped" | sed 's/||/\
/g' | tail -1)
  case "$tail_seg" in
    *\|*)
      tail_seg=${tail_seg##*|}
      tail_seg=$(printf '%s' "$tail_seg" | sed 's/^[[:space:]]*//')
      echo "$tail_seg" | grep -qE "^($FAIL_OPEN_TAIL_CMDS)([[:space:]]|$)" && return 0
      ;;
  esac

  return 1
}

# A verify string must be a runnable command, not prose. Guards the e60s01 class:
# `node bin/bigpowers.js setup (interactive in TTY)` is documentation, and a
# story gate that cannot be executed is as useless as one never executed.
#
# Two conditions, both required. The leading-token check alone accepts the
# example above (it starts with `node`), so shape is also checked with `bash -n`
# — the parenthetical is a syntax error, which is exactly what marks it as prose.
is_executable_verify() {
  local cmd="$1"
  echo "$cmd" | grep -qE '^[a-zA-Z][a-zA-Z0-9_.-]*\b|^\[' || return 1
  bash -n -c "$cmd" 2>/dev/null
}
