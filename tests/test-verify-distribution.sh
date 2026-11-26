#!/usr/bin/env bash
# story: BUG-2026-11-06-install-multi-channel-collisions
# Guard for issue #208: verify-distribution.sh must detect when more than one
# install channel owns pi, and report clean when exactly one is present. The
# real symptom was 80 skill-name collisions per start from four overlapping
# roots; the check names each channel and fails on overlap.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY="$REPO_ROOT/scripts/verify-distribution.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok()  { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

# Fixture: a fake pi agent dir under a fake HOME, so the check never reads the
# real machine state.
run() {
  HOME="$WORK/home" bash "$VERIFY" "$@" 2>&1
}

# T1 — a clean HOME (no channels) reports clean.
mkdir -p "$WORK/home"
OUT="$(run)"
if printf '%s' "$OUT" | grep -q "clean"; then
  ok "T1 clean HOME reports clean"
else
  bad "T1 got: $(printf '%s' "$OUT" | tr '\n' ' ')"
fi

# T2 — package channel only reports clean.
mkdir -p "$WORK/home/.pi/agent"
printf '{"packages":["npm:bigpowers"]}\n' > "$WORK/home/.pi/agent/settings.json"
OUT="$(run)"
if printf '%s' "$OUT" | grep -q "clean" && printf '%s' "$OUT" | grep -q "package channel"; then
  ok "T2 package-only reports clean and names the channel"
else
  bad "T2 got: $(printf '%s' "$OUT" | tr '\n' ' ')"
fi

# T3 — package + symlink channels conflict, and --strict exits 1.
mkdir -p "$WORK/home/.pi/agent/skills"
mkdir -p "$WORK/node_modules/bigpowers/skills/survey-context"
printf -- '---\nname: survey-context\ndescription: x\n---\nbody\n' > "$WORK/node_modules/bigpowers/skills/survey-context/SKILL.md"
ln -s "$WORK/node_modules/bigpowers/skills/survey-context" "$WORK/home/.pi/agent/skills/survey-context"
set +e
OUT="$(run --strict)"
STATUS=$?
set -e
if [ "$STATUS" -ne 0 ] && printf '%s' "$OUT" | grep -q "package channel and the global symlink channel"; then
  ok "T3 package+symlink conflict detected, --strict exits 1"
else
  bad "T3 status=$STATUS out=$(printf '%s' "$OUT" | tr '\n' ' ')"
fi

# T4 — symlink-only reports clean (package removed).
printf '{"packages":["npm:pi-web-access"]}\n' > "$WORK/home/.pi/agent/settings.json"
OUT="$(run)"
if printf '%s' "$OUT" | grep -q "clean" && printf '%s' "$OUT" | grep -q "symlink channel"; then
  ok "T4 symlink-only reports clean"
else
  bad "T4 got: $(printf '%s' "$OUT" | tr '\n' ' ')"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) distribution-verify checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
