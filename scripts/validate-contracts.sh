#!/usr/bin/env bash
# story: e80s02
# Contract validation runner for validate-contracts skill.
# Supports key-set mode (sources.reference vs sources.target JSON key comparison).
# Usage: bash scripts/validate-contracts.sh <contract.yaml> [--self-test]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

self_test() {
  local dir="$REPO_ROOT/specs/verifications/fixtures/contracts-selftest"
  mkdir -p "$dir"
  echo '{"a":1,"b":2,"c":3}' > "$dir/ref.json"
  echo '{"a":1,"b":2}' > "$dir/target.json"
  cat > "$dir/keyset.yaml" <<YAML
sources:
  reference: specs/verifications/fixtures/contracts-selftest/ref.json
  target: specs/verifications/fixtures/contracts-selftest/target.json
mode: subset
YAML
  if bash "$0" "$dir/keyset.yaml"; then
    echo "FAIL: expected divergence on missing key c"
    exit 1
  fi
  echo '{"a":1,"b":2,"c":3}' > "$dir/target.json"
  bash "$0" "$dir/keyset.yaml"
  echo "validate-contracts: self-test OK"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

CONTRACT="${1:-}"
if [[ -z "$CONTRACT" || ! -f "$CONTRACT" ]]; then
  echo "Usage: bash scripts/validate-contracts.sh <contract.yaml>"
  exit 2
fi

if grep -q '^sources:' "$CONTRACT"; then
  REF=$(grep 'reference:' "$CONTRACT" | head -1 | awk '{print $2}')
  TGT=$(grep 'target:' "$CONTRACT" | head -1 | awk '{print $2}')
  [[ -f "$REF" && -f "$TGT" ]] || { echo "FAIL: missing source files"; exit 1; }
  REF_KEYS=$(python3 -c "import json; print('\n'.join(sorted(json.load(open('$REF')).keys())))")
  TGT_KEYS=$(python3 -c "import json; print('\n'.join(sorted(json.load(open('$TGT')).keys())))")
  MISSING=$(comm -23 <(echo "$REF_KEYS") <(echo "$TGT_KEYS") | wc -l | tr -d ' ')
  if [[ "$MISSING" -gt 0 ]]; then
    echo "FAIL: key-set — $MISSING keys in reference missing from target"
    exit 1
  fi
  echo "PASS: key-set contract"
  exit 0
fi

echo "SKIP: unsupported contract type in $CONTRACT"
exit 0
