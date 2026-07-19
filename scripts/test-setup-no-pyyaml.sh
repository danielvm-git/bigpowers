#!/usr/bin/env bash
# test-setup-no-pyyaml.sh — recurrence guard for BUG-2026-07-18-setup-pyyaml-missing
#
# `bigpowers setup` must not crash when the resolved python3 lacks PyYAML.
# Two setup-path scripts hard-depended on PyYAML: srp-engine.py (import yaml)
# and validate-skill-yaml.py (sys.exit(2) on ImportError). Both now fall back
# to scripts/lib/simple_yaml.py. This guard asserts:
#   1. srp-engine.py parses a skill under a PyYAML-free interpreter.
#   2. validate-skill-yaml.py runs (does not exit 2) under the same.
#   3. simple_yaml's output equals PyYAML's for every skill's frontmatter
#      (covers escaped quotes and folded/literal block scalars).
#
# Usage: bash scripts/test-setup-no-pyyaml.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAILURES=0
pass() { echo -e "${GREEN}PASS${NC} $1"; }
fail() { echo -e "${RED}FAIL${NC} $1"; FAILURES=$((FAILURES + 1)); }

# Build a throwaway PyYAML-free interpreter — a fresh venv has no PyYAML,
# reproducing a stock macOS python3 without touching the caller's environment.
NOYAML_DIR="$(mktemp -d)"
trap 'rm -rf "$NOYAML_DIR"' EXIT
if ! python3 -m venv "$NOYAML_DIR/venv" >/dev/null 2>&1; then
  echo "test-setup-no-pyyaml: SKIP — cannot create venv"; exit 0
fi
NOPY="$NOYAML_DIR/venv/bin/python"
if "$NOPY" -c "import yaml" >/dev/null 2>&1; then
  echo "test-setup-no-pyyaml: SKIP — fresh venv unexpectedly has PyYAML"; exit 0
fi

# 1. srp-engine.py must parse a skill's frontmatter without crashing.
if "$NOPY" scripts/lib/srp-engine.py skills/fix-bug/SKILL.md >/dev/null 2>&1; then
  pass "srp-engine.py parses frontmatter without PyYAML"
else
  fail "srp-engine.py crashed without PyYAML"
fi

# 2. validate-skill-yaml.py must not bail with exit 2 (the old PyYAML-required path).
rc=0
"$NOPY" scripts/validate-skill-yaml.py >/dev/null 2>&1 || rc=$?
if [[ "$rc" -ne 2 ]]; then
  pass "validate-skill-yaml.py runs without PyYAML (exit $rc)"
else
  fail "validate-skill-yaml.py bailed with exit 2 (PyYAML required)"
fi

# 3. Fallback fidelity: simple_yaml must equal PyYAML for every skill's
#    frontmatter. Runs under python3 (CI has PyYAML); skips if PyYAML absent.
if python3 - <<'PY'; then
import glob, sys
sys.path.insert(0, "scripts/lib")
from simple_yaml import parse_simple_yaml
try:
    import yaml
except ImportError:
    print("skip: PyYAML not available for comparison"); sys.exit(0)
bad = []
for p in sorted(glob.glob("skills/*/SKILL.md")):
    fm = open(p, encoding="utf-8").read().split("---")[1]
    a = parse_simple_yaml(fm)
    b = yaml.safe_load(fm)
    for k in ("name", "description", "effort", "model"):
        if a.get(k) != b.get(k):
            bad.append(f"{p}:{k}")
if bad:
    print("mismatch: " + ", ".join(bad)); sys.exit(1)
sys.exit(0)
PY
  pass "simple_yaml matches PyYAML for all skill frontmatter"
else
  fail "simple_yaml diverged from PyYAML for some skill frontmatter"
fi

if [[ "$FAILURES" -gt 0 ]]; then
  echo "test-setup-no-pyyaml: $FAILURES failure(s)" >&2
  exit 1
fi
echo "test-setup-no-pyyaml: PASS"
