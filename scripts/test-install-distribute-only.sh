#!/usr/bin/env bash
# story: BUG-2026-07-24-installer-runs-dev-maintenance-pipeline
# Regression test: bigpowers setup must not run bigpowers' own dev-maintenance
# regen (lockfile, SKILL-INDEX, OKF wikis) against an end-user install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TA_PASS=0
TA_FAIL=0
TA_TMPDIR=""

source "$REPO_ROOT/scripts/lib/test-assertions.sh"
trap ta_cleanup EXIT

echo "=== test-install-distribute-only.sh ==="

SYNC_SH="$REPO_ROOT/scripts/sync-skills.sh"
SETUP_JS="$REPO_ROOT/bin/setup.js"

grep -q -- '--distribute-only' "$SYNC_SH" && ta_pass 'sync-skills.sh: --distribute-only flag defined' \
  || ta_fail 'sync-skills.sh: missing --distribute-only flag'
grep -q "sync-skills.sh --distribute-only" "$SETUP_JS" && ta_pass 'setup.js: invokes sync-skills.sh with --distribute-only' \
  || ta_fail 'setup.js: does not pass --distribute-only'
grep -q "runInheritedAsync('bash scripts/sync-skills.sh --distribute-only')" "$SETUP_JS" \
  && ta_pass 'setup.js: sync-skills call is async (spinner can animate)' \
  || ta_fail 'setup.js: sync-skills call reverted to blocking runInherited (spinner would freeze)'

hash_of() { [[ -f "$1" ]] && shasum -a 256 "$1" | awk '{print $1}' || echo "absent"; }
listing_of() { [[ -d "$1" ]] && (find "$1" -maxdepth 1 -type f | sort) || echo "absent"; }

LOCK_BEFORE=$(hash_of "$REPO_ROOT/skills-lock.json")
INDEX_BEFORE=$(hash_of "$REPO_ROOT/SKILL-INDEX.md")
SEARCH_INDEX_BEFORE=$(hash_of "$REPO_ROOT/specs/SKILL-SEARCH-INDEX_LATEST.md")
EPICS_WIKI_BEFORE=$(listing_of "$REPO_ROOT/specs/epics-wiki")

OUT="$(cd "$REPO_ROOT" && bash scripts/sync-skills.sh --distribute-only 2>&1)"
echo "$OUT" | grep -q -- '--distribute-only: dev-maintenance regen skipped' \
  && ta_pass 'sync-skills.sh --distribute-only: confirmation message printed' \
  || ta_fail 'sync-skills.sh --distribute-only: missing confirmation message'
echo "$OUT" | grep -q 'Generating OKF wikis' \
  && ta_fail 'sync-skills.sh --distribute-only: still generated OKF wikis' \
  || ta_pass 'sync-skills.sh --distribute-only: no OKF wiki generation'
echo "$OUT" | grep -q 'regenerate-lockfile' \
  && ta_fail 'sync-skills.sh --distribute-only: still regenerated lockfile' \
  || ta_pass 'sync-skills.sh --distribute-only: no lockfile regen'

[[ "$(hash_of "$REPO_ROOT/skills-lock.json")" == "$LOCK_BEFORE" ]] \
  && ta_pass 'skills-lock.json untouched' || ta_fail 'skills-lock.json was modified'
[[ "$(hash_of "$REPO_ROOT/SKILL-INDEX.md")" == "$INDEX_BEFORE" ]] \
  && ta_pass 'SKILL-INDEX.md untouched' || ta_fail 'SKILL-INDEX.md was modified'
[[ "$(hash_of "$REPO_ROOT/specs/SKILL-SEARCH-INDEX_LATEST.md")" == "$SEARCH_INDEX_BEFORE" ]] \
  && ta_pass 'SKILL-SEARCH-INDEX_LATEST.md untouched' || ta_fail 'SKILL-SEARCH-INDEX_LATEST.md was modified'
[[ "$(listing_of "$REPO_ROOT/specs/epics-wiki")" == "$EPICS_WIKI_BEFORE" ]] \
  && ta_pass 'specs/epics-wiki/ untouched' || ta_fail 'specs/epics-wiki/ was modified'

[[ -f "$REPO_ROOT/.cursor/rules/fix-bug.mdc" ]] && ta_pass 'skills still distributed (.cursor/rules populated)' \
  || ta_fail 'skill distribution did not run'

bash -n "$SYNC_SH" && ta_pass 'bash -n sync-skills.sh' || ta_fail 'bash -n sync-skills.sh'
node --check "$SETUP_JS" && ta_pass 'node --check setup.js' || ta_fail 'node --check setup.js'

echo "test-install-distribute-only: $TA_PASS passed, $TA_FAIL failed"
[[ "$TA_FAIL" -eq 0 ]] || exit 1
