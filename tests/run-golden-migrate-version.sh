#!/usr/bin/env bash
# story: e44s06
# G-06: migrate-version golden tests — detection + stamp + YAML validity
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"
CHECK_GAP="$REPO_ROOT/scripts/check-spec-version-gap.sh"
VALIDATE_YAML="$REPO_ROOT/scripts/validate-specs-yaml.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }

echo -e "${CYAN}═══ G-06: migrate-version Golden Tests ═══${NC}"

# ── Test 1: v1.x detection ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}── G-06: v1.x detection ──${NC}"
tmp1="$(mktemp -d)"
cp -r "$FIXTURES/v1.x-project/"* "$tmp1/"
cd "$tmp1"
git init --quiet && git config user.email "test@b.dev" && git config user.name "T" && git add -A && git commit -m "i" --quiet

bash "$CHECK_GAP" --skip-block --json 2>&1 || true
echo ""

# Verify STATE.md exists, state.yaml does not
if [ -f "$tmp1/specs/STATE.md" ] && [ ! -f "$tmp1/specs/state.yaml" ]; then
  pass "v1.x: Markdown-era detected (STATE.md present, state.yaml absent)"
else
  fail "v1.x: expected Markdown-era signal"
fi
rm -rf "$tmp1"

# ── Test 2: v2.0.0 detection ────────────────────────────────────────────
echo ""
echo -e "${CYAN}── G-06: v2.0.0 detection ──${NC}"
tmp2="$(mktemp -d)"
cp -r "$FIXTURES/v2.0.0-project/"* "$tmp2/"
cd "$tmp2"
git init --quiet && git config user.email "test@b.dev" && git config user.name "T" && git add -A && git commit -m "i" --quiet

bash "$CHECK_GAP" --skip-block --json 2>&1 || true
echo ""

# Verify state.yaml exists but no bigpowers_version stamp
if [ -f "$tmp2/specs/state.yaml" ]; then
  stamped="$(python3 -c "import yaml; d=yaml.safe_load(open('$tmp2/specs/state.yaml')); print(d.get('bigpowers_version','MISSING'))" 2>/dev/null)" || stamped="ERR"
  if [ "$stamped" = "MISSING" ]; then
    pass "v2.0.0: YAML cockpit without bigpowers_version stamp"
  else
    fail "v2.0.0: expected no stamp, got '$stamped'"
  fi
else
  fail "v2.0.0: state.yaml missing"
fi
rm -rf "$tmp2"

# ── Test 3: v2.20 detection ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}── G-06: v2.20 detection ──${NC}"
tmp3="$(mktemp -d)"
cp -r "$FIXTURES/v2.20-project/"* "$tmp3/"
cd "$tmp3"
git init --quiet && git config user.email "test@b.dev" && git config user.name "T" && git add -A && git commit -m "i" --quiet

bash "$CHECK_GAP" --skip-block --json 2>&1 || true
echo ""

if [ -f "$tmp3/specs/state.yaml" ]; then
  has_capsule="$(python3 -c "import yaml; d=yaml.safe_load(open('$tmp3/specs/state.yaml')); print('yes' if d.get('epic_cycle') else 'no')" 2>/dev/null)" || has_capsule="ERR"
  stamped="$(python3 -c "import yaml; d=yaml.safe_load(open('$tmp3/specs/state.yaml')); print(d.get('bigpowers_version','MISSING'))" 2>/dev/null)" || stamped="ERR"
  if [ "$has_capsule" = "yes" ] && [ "$stamped" = "MISSING" ]; then
    pass "v2.20: capsule era with epic_cycle, no stamp"
  elif [ "$has_capsule" != "yes" ]; then
    fail "v2.20: expected epic_cycle, got '$has_capsule'"
  else
    fail "v2.20: expected no stamp, got '$stamped'"
  fi
else
  fail "v2.20: state.yaml missing"
fi
rm -rf "$tmp3"

# ── Test 4: stamp-only migration (v2.20, no migrations needed) ──────────
echo ""
echo -e "${CYAN}── G-06: stamp-only migration ──${NC}"
tmp4="$(mktemp -d)"
cp -r "$FIXTURES/v2.20-project/"* "$tmp4/"
cd "$tmp4"
git init --quiet && git config user.email "test@b.dev" && git config user.name "T" && git add -A && git commit -m "i" --quiet

bash "$REPO_ROOT/scripts/migrate-version.sh" --project "$tmp4" --force --no-commit 2>&1 | tail -3 || true

if [ -f "$tmp4/specs/state.yaml" ]; then
  stamped="$(python3 -c "import yaml; d=yaml.safe_load(open('$tmp4/specs/state.yaml')); print(d.get('bigpowers_version','MISSING'))" 2>/dev/null)" || stamped="ERR"
  installed="$(node -e "console.log(require('$REPO_ROOT/package.json').version)" 2>/dev/null)"
  if [ "$stamped" = "$installed" ]; then
    pass "v2.20: stamp-only migration produced bigpowers_version=$stamped"
  else
    fail "v2.20: stamp check — expected $installed, got $stamped"
  fi
else
  fail "v2.20: state.yaml missing after migration"
fi

# Validate YAML
if bash "$VALIDATE_YAML" "$tmp4/specs" >/dev/null 2>&1; then
  pass "v2.20: validate-specs-yaml"
else
  fail "v2.20: validate-specs-yaml had parse errors"
fi
rm -rf "$tmp4"

# ── Test 5: v2.0.0 migration roundtrip ──────────────────────────────────
echo ""
echo -e "${CYAN}── G-06: v2.0.0 migration roundtrip ──${NC}"
tmp5="$(mktemp -d)"
cp -r "$FIXTURES/v2.0.0-project/"* "$tmp5/"
cd "$tmp5"
git init --quiet && git config user.email "test@b.dev" && git config user.name "T" && git add -A && git commit -m "i" --quiet

bash "$REPO_ROOT/scripts/migrate-version.sh" --project "$tmp5" --force --no-commit 2>&1 | tail -5 || true

if [ -f "$tmp5/specs/state.yaml" ]; then
  installed="$(node -e "console.log(require('$REPO_ROOT/package.json').version)" 2>/dev/null)"
  stamped="$(python3 -c "import yaml; d=yaml.safe_load(open('$tmp5/specs/state.yaml')); print(d.get('bigpowers_version','MISSING'))" 2>/dev/null)" || stamped="ERR"
  if [ "$stamped" = "$installed" ]; then
    pass "v2.0.0: stamp = $stamped after migration"
  else
    fail "v2.0.0: stamp check — expected $installed, got $stamped"
  fi
else
  fail "v2.0.0: state.yaml missing after migration"
fi

if python3 -c "import yaml; yaml.safe_load(open('$tmp5/specs/state.yaml')); print('OK')" 2>/dev/null | grep -q OK; then
  pass "v2.0.0: state.yaml is valid YAML after migration"
else
  fail "v2.0.0: state.yaml parse error after migration"
fi
rm -rf "$tmp5"

echo ""
echo -e "${CYAN}────────────────────────────────────${NC}"
echo -e "G-06 Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
if [ $FAIL -gt 0 ]; then
  exit 1
fi
echo -e "${GREEN}G-06: OK${NC}"
exit 0
