#!/usr/bin/env bash
# story: e83s05
# ACTIVE_WORK block must name the trigger that fired (feature_branch | dirty_specs | active_flow).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/specs"; printf 'bigpowers_version: 0.0.1\nactive_flow: null\n' > "$T/specs/state.yaml"
git -C "$T" init -q -b main
git -C "$T" add -A; git -C "$T" -c user.email=a@b -c user.name=x commit -qm i
run() { bash "$ROOT/scripts/check-spec-version-gap.sh" --project "$T" --json 2>/dev/null || true; }
fail() { echo "FAIL: $1"; exit 1; }
git -C "$T" switch -qc feat/x
run | grep -q '"trigger":"feature_branch"' || fail "feature branch trigger missing: $(run)"
git -C "$T" switch -q main
echo x >> "$T/specs/state.yaml"
run | grep -q '"trigger":"dirty_specs"' || fail "dirty specs trigger missing: $(run)"
git -C "$T" -c user.email=a@b -c user.name=x commit -qam d
printf 'bigpowers_version: 0.0.1\nactive_flow: build_epic\n' > "$T/specs/state.yaml"
git -C "$T" -c user.email=a@b -c user.name=x commit -qam f
run | grep -q '"trigger":"active_flow"' || fail "active_flow trigger missing: $(run)"
echo "PASS"
