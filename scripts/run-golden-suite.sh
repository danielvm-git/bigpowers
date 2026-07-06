#!/usr/bin/env bash
# run-golden-suite.sh — Deterministic golden suite runner
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
GOLDEN_GENERATED_BY="scripts/run-golden-suite.sh"
GOLDEN_USAGE_NAME="run-golden-suite.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/golden-suite-run.sh"
golden_suite_main "$@"
