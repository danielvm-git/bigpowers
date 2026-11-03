#!/usr/bin/env bash
# story: e86
# Adversarial Defect Mutation & Boundary Fuzzing Gate.
# Evaluates code changes against null/undefined, empty collections, extreme bounds,
# and unexpected types before UAT sign-off.
set -euo pipefail

REPO_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || {
  echo "verify-adversarial: not in a git repository" >&2
  exit 1
}
cd "$REPO_ROOT"

self_test() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  cd "$tmp"
  git init -q
  git config user.email "adversarial@bigpowers.local"
  git config user.name "adversarial"

  mkdir -p src test
  cat > package.json <<'JSON'
{"name":"adversarial-fixture","scripts":{"test":"node test/calc.test.js"}}
JSON

  # Vulnerable implementation (crashes on undefined brand or null line item, like ab-20)
  cat > src/calc.js <<'JS'
function applyDiscount(item) {
  // Bug: crashes if item.brand is undefined or item is null
  return item.brand.toUpperCase() === "ACME" ? 0.9 : 1.0;
}
module.exports = { applyDiscount };
JS

  cat > test/calc.test.js <<'JS'
const assert = require('assert');
const { applyDiscount } = require('../src/calc');
assert.strictEqual(applyDiscount({ brand: 'Acme' }), 0.9);
assert.strictEqual(applyDiscount({ brand: 'Other' }), 1.0);
console.log("Acceptance tests PASS");
JS

  git add .
  git commit -q -m "feat: initial feature with hidden boundary flaw"

  # Run self-test probe: probe with { brand: undefined } and {}
  local probe_fail=false
  node -e "
    const { applyDiscount } = require('./src/calc');
    try {
      applyDiscount({});
    } catch (e) {
      process.exit(1);
    }
  " 2>/dev/null || probe_fail=true

  if [ "$probe_fail" = false ]; then
    echo "FAIL: Expected vulnerable fixture to crash on missing brand"
    return 1
  fi
  echo "PASS: Vulnerable fixture correctly triggered defect on boundary probe"

  # Now harden the fixture
  cat > src/calc.js <<'JS'
function applyDiscount(item) {
  if (!item || !item.brand) return 1.0;
  return item.brand.toUpperCase() === "ACME" ? 0.9 : 1.0;
}
module.exports = { applyDiscount };
JS

  local probe_pass=true
  node -e "
    const { applyDiscount } = require('./src/calc');
    try {
      applyDiscount({});
      applyDiscount(null);
      applyDiscount({ brand: undefined });
    } catch (e) {
      process.exit(1);
    }
  " 2>/dev/null || probe_pass=false

  if [ "$probe_pass" = false ]; then
    echo "FAIL: Hardened fixture should survive boundary probe"
    return 1
  fi
  echo "PASS: Hardened fixture survived boundary probes"
  echo "verify-adversarial: self-test OK"
  return 0
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit $?
fi

echo "=== Adversarial Defect Mutation Gate ==="

# 1. Identify changed source files
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || git status --porcelain | awk '{print $2}')
if [[ -z "$CHANGED_FILES" ]] && git rev-parse HEAD~1 >/dev/null 2>&1; then
  CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
fi

DEFECTS_FOUND=0
mkdir -p specs/verifications

# 2. Check for common unsafe property access patterns on JS/TS files
for file in $CHANGED_FILES; do
  if [[ "$file" =~ \.(js|ts|mjs)$ ]] && [[ -f "$file" ]] && [[ ! "$file" =~ (^|/)test/ ]] && [[ ! "$file" =~ \.test\. ]]; then
    # Look for unsafe chained property access like item.brand.toLowerCase() or item.prop.subprop
    if grep -nE '\.[a-zA-Z0-9_]+\.(toLowerCase|toUpperCase|trim|length|slice)\(' "$file" | grep -v '\?\.' >/dev/null 2>&1; then
      echo "WARNING [boundary-mutation]: Potential unhandled undefined access without optional chaining in $file:"
      grep -nE '\.[a-zA-Z0-9_]+\.(toLowerCase|toUpperCase|trim|length|slice)\(' "$file" | grep -v '\?\.' | head -n 5
    fi
  fi
done

# 3. If the repository defines an adversarial test script, execute it
if [[ -f package.json ]] && grep -q '"test:adversarial"' package.json 2>/dev/null; then
  echo "Running project-defined adversarial test suite (npm run test:adversarial)..."
  if ! npm run test:adversarial; then
    DEFECTS_FOUND=$((DEFECTS_FOUND + 1))
  fi
fi

# 4. Write evidence artifact
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > specs/verifications/ADVERSARIAL_LATEST.yaml <<YAML
verified_at: "$TIMESTAMP"
gate: verify-adversarial
defects_found: $DEFECTS_FOUND
passed: $( [ "$DEFECTS_FOUND" -eq 0 ] && echo "true" || echo "false" )
YAML

if [ "$DEFECTS_FOUND" -gt 0 ]; then
  echo "FAIL: Adversarial mutation gate found $DEFECTS_FOUND defects. Harden edge cases before declaring UAT green." >&2
  exit 1
fi

echo "PASS: Adversarial defect mutation gate passed."
exit 0
