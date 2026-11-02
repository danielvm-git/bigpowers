#!/usr/bin/env bash
# story: e58s01
# run-ab-eval.sh — run the same tasks with and without bigpowers; grade only the outcome.
# Advisory: exits 0 after a completed run, 2 on configuration errors. See specs/benchmarks/SCHEMA.md.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
exec "$PYTHON" "$(dirname "${BASH_SOURCE[0]}")/lib/ab-eval.py" "$@"
