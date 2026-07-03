#!/usr/bin/env bash
# story: e38s06
# waiver-utils.sh — common waiver subsystem for compliance scripts.
# Provides has_waiver() for bash 3.2+ compatibility.
# Waived steps are excluded from the denominator; expired waivers re-enter as FAILs.
# Source this file in scripts that need waiver checking.
# Requires: WAIVER_FILE variable set before sourcing (defaults to specs/verifications/waivers.yaml).

: "${WAIVER_FILE:=specs/verifications/waivers.yaml}"

has_waiver() {
  local step_sanitized="$1"
  local waiver_file="${WAIVER_FILE:-specs/verifications/waivers.yaml}"

  if [[ ! -f "$waiver_file" ]]; then
    return 1  # No waiver file → not waived
  fi

  # Check if step has any waiver entry
  if ! grep -q "step_sanitized: $step_sanitized" "$waiver_file" 2>/dev/null; then
    return 1  # Not found → not waived
  fi

  # Extract review_date for this step (parses the YAML block)
  local review_date
  review_date=$(awk -v slug="$step_sanitized" '
    $0 ~ "step_sanitized: " slug { found=1; next }
    found && /review_date:/ { gsub(/[^0-9-]/, "", $0); print; exit }
  ' "$waiver_file")

  # Check expiry: if review_date < today, waiver is expired
  local today
  today=$(date +%Y-%m-%d)
  if [[ -n "$review_date" && "$review_date" < "$today" ]]; then
    return 2  # Expired waiver → counts as FAIL
  fi

  return 0  # Valid waiver → excluded from denominator
}
