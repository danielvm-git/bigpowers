#!/usr/bin/env bash
# And there should be no "magic strings" or numbers (G25)
# Check: hardcoded absolute user paths in scripts.
#
# -I / --exclude-dir=__pycache__: compiled .pyc artifacts under a gitignored
# __pycache__/ inherited the /Users/ literal from lib/link_utils.py's own
# source and flagged as violations depending only on whether Python had
# recently byte-compiled that module — an environment-dependent false
# positive, not a property of the codebase.
#
# lib/link_utils.py exclusion: MACHINE_PATH_RE's own literal IS the
# machine-path detector's payload (its header comment says so), not a leaked
# path — the same "the detector's own definition is not a violation of what
# it detects" reasoning already applied to check-spec-version-gap.sh below.
#
# hermes-verify-e39 exclusion removed: that file no longer exists in this
# repo; a stale exclusion for a deleted file is exactly the kind of unaudited
# machinery this check exists to catch.
VIOLATIONS=$(grep -rn -I --exclude-dir=__pycache__ '/Users/' scripts/ 2>/dev/null \
  | grep -vE ':[0-9]+:[[:space:]]*#' \
  | grep -v 'scripts/lib/link_utils.py:')

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Magic paths found:"
  echo "$VIOLATIONS"
  exit 1
fi
