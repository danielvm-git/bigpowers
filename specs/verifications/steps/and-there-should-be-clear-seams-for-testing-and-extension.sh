#!/usr/bin/env bash
# And there should be clear "seams" for testing and extension
# Check: audit harness seams exist — features/, steps/, and runner are separate.
if [[ -d "specs/verifications/features" && -d "specs/verifications/steps" && -f "scripts/audit-compliance.sh" ]]; then
  exit 0
else
  echo "Audit seams missing: need specs/verifications/features/, specs/verifications/steps/, scripts/audit-compliance.sh"
  exit 1
fi
