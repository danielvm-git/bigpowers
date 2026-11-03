#!/usr/bin/env bash
# story: e86 / verify-work adversarial mutation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Testing verify-adversarial.sh ==="

# 1. Run self-test
bash "$REPO_ROOT/scripts/verify-adversarial.sh" --self-test
echo "  PASS verify-adversarial self-test"

# 2. Run normal invocation in repo root
bash "$REPO_ROOT/scripts/verify-adversarial.sh"
echo "  PASS verify-adversarial repo root run"

# 3. Assert artifact was created
if [[ -f "$REPO_ROOT/specs/verifications/ADVERSARIAL_LATEST.yaml" ]]; then
  echo "  PASS ADVERSARIAL_LATEST.yaml created"
else
  echo "  FAIL ADVERSARIAL_LATEST.yaml missing"
  exit 1
fi

echo "=== All verify-adversarial tests passed ==="
exit 0
