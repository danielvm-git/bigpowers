#!/usr/bin/env bash
# story: e80s05
# Negative fixture: proper exit-code propagation (must NOT be flagged as fail-open)
set -euo pipefail
test -f scripts/run-skill-verify.sh
