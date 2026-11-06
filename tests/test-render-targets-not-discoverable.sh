#!/usr/bin/env bash
# story: BUG-2026-11-06-agents-skills-render-hijack
# Guard for issue #209: no host render target may live at a path another host
# auto-discovers. .agents/skills is an Agent Skills discovery root that pi
# scans, so rendering the Antigravity output there made a generated copy
# outrank the maintained source. The render output must live under
# .bigpowers/rendered/antigravity/skills instead.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0
ok()  { printf 'ok   %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL %s\n' "$1"; fail=$((fail + 1)); }

RENDER_PATH=".bigpowers/rendered/antigravity/skills"

# T1 — targets.yaml declares the relocated output.
if grep -q "output: $RENDER_PATH" "$REPO_ROOT/scripts/targets.yaml"; then
  ok "T1 targets.yaml agy output is $RENDER_PATH"
else
  bad "T1 targets.yaml still points at a discovery root"
fi

# T2 — the agy adapter's default output is the relocated path.
AGY_DEFAULT="$(grep -o 'AGY_SKILLS="\${AGY_SKILLS:-[^}]*}' "$REPO_ROOT/scripts/adapters/agy.sh")"
if [[ "$AGY_DEFAULT" == *"$RENDER_PATH"* ]] && [[ "$AGY_DEFAULT" != *".agents/skills"* ]]; then
  ok "T2 agy.sh renders to $RENDER_PATH, not .agents/skills"
else
  bad "T2 agy.sh default is '$AGY_DEFAULT'"
fi

# T3 — the install-targets source dir is the relocated path.
if grep -q "AGY_RENDERED=\"\$REPO_ROOT/$RENDER_PATH\"" "$REPO_ROOT/scripts/lib/install-targets-b.sh"; then
  ok "T3 install-targets-b.sh reads $RENDER_PATH"
else
  bad "T3 install-targets-b.sh still reads .agents/skills"
fi

# T4 — install-helpers.js renders from the relocated path.
if grep -q "'rendered', 'antigravity', 'skills'" "$REPO_ROOT/scripts/lib/install-helpers.js"; then
  ok "T4 install-helpers.js renders from the relocated path"
else
  bad "T4 install-helpers.js still renders from .agents/skills"
fi

# T5 — no render output equals a discovery root pi scans (.agents/skills or
# .pi/skills). The render roots are .pi/skills (pi package, intentional) and
# .bigpowers/rendered/antigravity/skills (Antigravity, relocated).
PI_OUTPUT="$(grep -m1 -A3 'id: pi' "$REPO_ROOT/scripts/targets.yaml" | grep -o 'output: .*' || true)"
AGY_OUTPUT="$(grep -m1 -A3 'id: agy' "$REPO_ROOT/scripts/targets.yaml" | grep -o 'output: .*' || true)"
if ! printf '%s\n%s\n' "$PI_OUTPUT" "$AGY_OUTPUT" | grep -q "output: \.agents/skills"; then
  ok "T5 no render output is the .agents/skills discovery root"
else
  bad "T5 a render output still targets .agents/skills"
fi

printf '\n%s\n' "$( [ "$fail" -eq 0 ] && echo "PASS: $pass/$((pass + fail)) render-target checks" || echo "FAIL: $fail of $((pass + fail)) checks" )"
[ "$fail" -eq 0 ] || exit 1
