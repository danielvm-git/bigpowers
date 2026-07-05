#!/usr/bin/env bash
# And names should describe side-effects (N7)
# Check: scripts/functions named get_* or check_* or is_* that contain write operations.
# Exclusions: check-spec-version-gap.sh (intentionally named, side-effect is the point)
VIOLATIONS=$(grep -rln '^get_\|^check_\|^is_\|^function get_\|^function check_\|^function is_' scripts/ 2>/dev/null \
  | grep -v 'check-spec-version-gap.sh' \
  | xargs -I{} grep -l '>>\|rm \|> ' {} 2>/dev/null)

if [[ -z "$VIOLATIONS" ]]; then
  exit 0
else
  echo "Functions with pure names but write side-effects: $VIOLATIONS"
  exit 1
fi
