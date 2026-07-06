#!/usr/bin/env bash
# run-verification-gates.sh — Deterministic verification gates runner
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
GOLDEN_GENERATED_BY="scripts/run-verification-gates.sh"
GOLDEN_USAGE_NAME="run-verification-gates.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/golden-suite-run.sh"
golden_suite_main "$@"
