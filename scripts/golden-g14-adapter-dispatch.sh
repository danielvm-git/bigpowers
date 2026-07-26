#!/usr/bin/env bash
# story: e37s05
# golden-g14-adapter-dispatch.sh — an adapter that can render must be dispatched.
#
# scripts/lib/srp-engine.py builds its dispatch list from targets.yaml entries
# carrying a skill.adapter. An adapter that defines render_skill() but is
# declared `skill: null` therefore never runs during sync, while its install
# function still reads a rendered directory that is never produced — the target
# reports success and installs nothing
# (BUG-2026-07-26-null-skill-adapters-install-nothing).
#
# Context-only bridges (aider, goose, ...) are exempt by construction: they
# define no render_skill, so there is nothing to dispatch.
#
# Usage: bash scripts/golden-g14-adapter-dispatch.sh [--self-test]
# Exit 0: every rendering adapter is dispatched
# Exit 1: at least one rendering adapter is undispatched (or, under
#         --self-test, the gate failed to notice an injected one)

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/skill-common.sh"
resolve_repo_root
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check() { # $1 = targets.yaml path
  $PYTHON - "$1" <<'PY'
import sys, os, re
import yaml

targets_path = sys.argv[1]
data = yaml.safe_load(open(targets_path, encoding="utf-8")) or {}

dispatched = set()
for t in data.get("targets") or []:
    skill = t.get("skill")
    if isinstance(skill, dict) and skill.get("adapter"):
        dispatched.add(skill["adapter"])

problems = []
adapter_dir = os.path.join("scripts", "adapters")
for fn in sorted(os.listdir(adapter_dir)):
    if not fn.endswith(".sh"):
        continue
    aid = fn[:-3]
    src = open(os.path.join(adapter_dir, fn), encoding="utf-8").read()
    if not re.search(r"^render_skill\(\)", src, re.M):
        continue  # context-only bridge — nothing to dispatch
    if aid not in dispatched:
        problems.append(
            f"{aid}: defines render_skill() but targets.yaml does not dispatch it "
            f"(skill.adapter missing or null) — sync renders nothing for it"
        )

if problems:
    for p in problems:
        print(f"  UNDISPATCHED {p}")
    print(f"\n{len(problems)} rendering adapter(s) never run during sync")
    sys.exit(1)

print(f"  ok  : all rendering adapters are dispatched ({len(dispatched)} in registry)")
sys.exit(0)
PY
}

if [[ "${1:-}" == "--self-test" ]]; then
  echo "=== G-14 self-test: prove the gate can fail ==="
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  $PYTHON - "$TMP/targets.yaml" <<'PY'
import sys, yaml
d = yaml.safe_load(open("scripts/targets.yaml", encoding="utf-8"))
# Null out the first dispatched adapter — the gate must notice.
for t in d.get("targets") or []:
    s = t.get("skill")
    if isinstance(s, dict) and s.get("adapter"):
        print(f"injected: {t['id']} skill -> null")
        t["skill"] = None
        break
yaml.dump(d, open(sys.argv[1], "w", encoding="utf-8"), default_flow_style=False, sort_keys=False)
PY
  set +e
  check "$TMP/targets.yaml" >/dev/null 2>&1
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo -e "${GREEN}PASS${NC} G-14 detected an injected undispatched adapter"
    echo "G-14 self-test: PASS"
    exit 0
  fi
  echo -e "${RED}FAIL${NC} G-14 passed on an injected null adapter — vacuous gate"
  echo "G-14 self-test: FAIL"
  exit 1
fi

echo "=== G-14: adapter dispatch coverage ==="
set +e
out=$(check "scripts/targets.yaml" 2>&1)
rc=$?
set -e
echo "$out"
if [[ $rc -eq 0 ]]; then
  echo -e "${GREEN}PASS${NC}"
  echo "G-14: PASS"
  exit 0
fi
echo -e "${RED}FAIL${NC} see BUG-2026-07-26-null-skill-adapters-install-nothing"
echo "G-14: FAIL"
exit 1
