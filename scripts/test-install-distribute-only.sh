#!/usr/bin/env bash
# story: BUG-2026-07-24-installer-runs-dev-maintenance-pipeline
# Regression test: bigpowers setup must not run bigpowers' own dev-maintenance
# regen (lockfile, SKILL-INDEX, OKF wikis) against an end-user install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== test-install-distribute-only.sh ==="

SYNC_SH="$REPO_ROOT/scripts/sync-skills.sh"
SETUP_JS="$REPO_ROOT/bin/setup.js"

grep -q -- '--distribute-only' "$SYNC_SH" && pass 'sync-skills.sh: --distribute-only flag defined' \
  || fail 'sync-skills.sh: missing --distribute-only flag'
grep -q "sync-skills.sh --distribute-only" "$SETUP_JS" && pass 'setup.js: invokes sync-skills.sh with --distribute-only' \
  || fail 'setup.js: does not pass --distribute-only'

hash_of() { [[ -f "$1" ]] && shasum -a 256 "$1" | awk '{print $1}' || echo "absent"; }
listing_of() { [[ -d "$1" ]] && (find "$1" -maxdepth 1 -type f | sort) || echo "absent"; }

LOCK_BEFORE=$(hash_of "$REPO_ROOT/skills-lock.json")
INDEX_BEFORE=$(hash_of "$REPO_ROOT/SKILL-INDEX.md")
SEARCH_INDEX_BEFORE=$(hash_of "$REPO_ROOT/specs/SKILL-SEARCH-INDEX_LATEST.md")
EPICS_WIKI_BEFORE=$(listing_of "$REPO_ROOT/specs/epics-wiki")

OUT="$(cd "$REPO_ROOT" && bash scripts/sync-skills.sh --distribute-only 2>&1)"
echo "$OUT" | grep -q -- '--distribute-only: dev-maintenance regen skipped' \
  && pass 'sync-skills.sh --distribute-only: confirmation message printed' \
  || fail 'sync-skills.sh --distribute-only: missing confirmation message'
echo "$OUT" | grep -q 'Generating OKF wikis' \
  && fail 'sync-skills.sh --distribute-only: still generated OKF wikis' \
  || pass 'sync-skills.sh --distribute-only: no OKF wiki generation'
echo "$OUT" | grep -q 'regenerate-lockfile' \
  && fail 'sync-skills.sh --distribute-only: still regenerated lockfile' \
  || pass 'sync-skills.sh --distribute-only: no lockfile regen'

[[ "$(hash_of "$REPO_ROOT/skills-lock.json")" == "$LOCK_BEFORE" ]] \
  && pass 'skills-lock.json untouched' || fail 'skills-lock.json was modified'
[[ "$(hash_of "$REPO_ROOT/SKILL-INDEX.md")" == "$INDEX_BEFORE" ]] \
  && pass 'SKILL-INDEX.md untouched' || fail 'SKILL-INDEX.md was modified'
[[ "$(hash_of "$REPO_ROOT/specs/SKILL-SEARCH-INDEX_LATEST.md")" == "$SEARCH_INDEX_BEFORE" ]] \
  && pass 'SKILL-SEARCH-INDEX_LATEST.md untouched' || fail 'SKILL-SEARCH-INDEX_LATEST.md was modified'
[[ "$(listing_of "$REPO_ROOT/specs/epics-wiki")" == "$EPICS_WIKI_BEFORE" ]] \
  && pass 'specs/epics-wiki/ untouched' || fail 'specs/epics-wiki/ was modified'

[[ -f "$REPO_ROOT/.cursor/rules/fix-bug.mdc" ]] && pass 'skills still distributed (.cursor/rules populated)' \
  || fail 'skill distribution did not run'

bash -n "$SYNC_SH" && pass 'bash -n sync-skills.sh' || fail 'bash -n sync-skills.sh'
node --check "$SETUP_JS" && pass 'node --check setup.js' || fail 'node --check setup.js'

echo "test-install-distribute-only: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
