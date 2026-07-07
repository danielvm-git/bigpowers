#!/usr/bin/env bash
# test-assertions.sh — shared pass/fail/cleanup helpers for verification scripts

if [[ -n "${TEST_ASSERTIONS_LOADED:-}" ]]; then return 0; fi
TEST_ASSERTIONS_LOADED=1

ta_cleanup() { [[ -n "${TA_TMPDIR:-}" && -d "$TA_TMPDIR" ]] && rm -rf "$TA_TMPDIR"; }

ta_pass() { echo "  PASS $1"; TA_PASS=$((TA_PASS + 1)); }

ta_fail() { echo "  FAIL $1"; TA_FAIL=$((TA_FAIL + 1)); }
