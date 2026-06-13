#!/usr/bin/env bash
# And land-branch script exists for solo-local integrate
set -euo pipefail
if [ -x scripts/land-branch.sh ]; then
  exit 0
fi
echo "scripts/land-branch.sh missing or not executable"
exit 1
