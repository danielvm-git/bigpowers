#!/usr/bin/env bash
# test-assertions.sh — shared pass/fail/cleanup helpers for verification scripts

if [[ -n "${TEST_ASSERTIONS_LOADED:-}" ]]; then return 0; fi
TEST_ASSERTIONS_LOADED=1

# Registered as `trap ta_cleanup EXIT`. The exit status of an EXIT trap's last
# command replaces the script's own, so this MUST end with an explicit success:
# the old `[[ ... ]] && rm -rf ...` one-liner returned 1 whenever TA_TMPDIR was
# unset, silently forcing every caller to exit 1 while printing "0 failed".
# That single line broke 22 story verifies across the integration epics (#106).
ta_cleanup() {
  if [[ -n "${TA_TMPDIR:-}" && -d "$TA_TMPDIR" ]]; then
    rm -rf "$TA_TMPDIR"
  fi
  return 0
}

ta_pass() { echo "  PASS $1"; TA_PASS=$((TA_PASS + 1)); }

ta_fail() { echo "  FAIL $1"; TA_FAIL=$((TA_FAIL + 1)); }

# Strip ANSI color codes — used by scripts that grep the colored output of a
# gate/skill they're testing, where the escape codes would break the match.
ta_strip_ansi() { sed -E 's/\x1b\[[0-9;]*m//g'; }
