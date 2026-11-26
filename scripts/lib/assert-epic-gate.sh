#!/usr/bin/env bash
# story: e86 / GH #182 / BUG-2026-11-07-assert-epic-gate-fail-open
# Mechanical audit-code pass gate before commit / release.
set -euo pipefail

STAGE="${1:-commit}"
AEG_AUDIT_FILE="specs/AUDIT_LATEST.md"
AEG_BASE=""
AEG_HEAD=""
AEG_COMMITS=""

aeg_has_pass_verdict() {
  if [[ -f "$AEG_AUDIT_FILE" ]] \
    && grep -qiE "VERDICT:[[:space:]]*PASS|RESULT:[[:space:]]*PASS" "$AEG_AUDIT_FILE"; then
    return 0
  fi
  if [[ "$STAGE" != "release" && -f specs/execution-status.yaml ]] \
    && grep -qE "audit_passed:[[:space:]]*true" specs/execution-status.yaml 2>/dev/null; then
    return 0
  fi
  return 1
}

aeg_parse_audited_range() {
  local line
  line="$(grep -m1 -E '^[[:space:]]*audited_range:' "$AEG_AUDIT_FILE" 2>/dev/null || true)"
  [[ -n "$line" ]] || return 1
  AEG_BASE="$(sed -nE 's/.*base:[[:space:]]*([0-9a-fA-F]+).*/\1/p' <<<"$line")"
  AEG_HEAD="$(sed -nE 's/.*head:[[:space:]]*([0-9a-fA-F]+).*/\1/p' <<<"$line")"
  AEG_COMMITS="$(sed -nE 's/.*commits:[[:space:]]*([0-9]+).*/\1/p' <<<"$line")"
  [[ -n "$AEG_BASE" && -n "$AEG_HEAD" && -n "$AEG_COMMITS" ]]
}

aeg_verify_release_range() {
  if ! aeg_parse_audited_range; then
    echo "ERROR [$STAGE]: $AEG_AUDIT_FILE is missing audited_range: { base: <sha>, head: <sha>, commits: <n> }." >&2
    echo "Remediation: Re-run audit-code on this branch and record audited_range in $AEG_AUDIT_FILE." >&2
    exit 1
  fi
  local actual_commits head_short
  head_short="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  if ! git rev-parse --verify "${AEG_BASE}^{commit}" >/dev/null 2>&1 \
    || ! git rev-parse --verify "${AEG_HEAD}^{commit}" >/dev/null 2>&1; then
    echo "ERROR [$STAGE]: audited_range references unknown commit(s): audit covers ${AEG_BASE}..${AEG_HEAD} (${AEG_COMMITS} commits); branch HEAD is ${head_short}." >&2
    echo "Remediation: Re-run audit-code on the current branch diff and update audited_range in $AEG_AUDIT_FILE." >&2
    exit 1
  fi
  actual_commits="$(git rev-list --count "${AEG_BASE}..HEAD" 2>/dev/null || echo -1)"
  if ! git merge-base --is-ancestor "$AEG_HEAD" HEAD 2>/dev/null \
    || [[ "$actual_commits" != "$AEG_COMMITS" ]]; then
    echo "ERROR [$STAGE]: stale audit evidence — audit covers ${AEG_BASE}..${AEG_HEAD} (${AEG_COMMITS} commits); branch is ${actual_commits} commits at ${head_short}." >&2
    echo "Remediation: Re-run audit-code on the current branch diff and update audited_range in $AEG_AUDIT_FILE." >&2
    exit 1
  fi
}

if ! aeg_has_pass_verdict; then
  echo "ERROR [$STAGE]: audit-code check is missing or did not pass (Issue #182)." >&2
  echo "Remediation: Run audit-code and ensure all checks pass before advancing to $STAGE." >&2
  echo "If audit fails, loop back to develop-tdd to address findings." >&2
  exit 1
fi

if [[ "$STAGE" == "release" ]]; then
  aeg_verify_release_range
fi

echo "PASS [$STAGE]: audit-code verified."
exit 0
