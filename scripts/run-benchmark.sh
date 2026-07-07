#!/usr/bin/env bash
# story: e45s01
# run-benchmark.sh — N-run with/without-skill delta grading + train/validation split.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
exec "$PYTHON" "$(dirname "${BASH_SOURCE[0]}")/lib/run-benchmark.py" "$@"
