#!/usr/bin/env bash
# story: e60s01
# Wrapper for scripts/test-install-helpers.js
# Usage: bash scripts/test-install-helpers.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec node "$ROOT/scripts/test-install-helpers.js"
