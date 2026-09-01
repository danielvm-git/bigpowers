#!/usr/bin/env bash
# story: e82s03
# OMP extension integrity guard — validates the extension entry is wired
# correctly and all source skills are discoverable via skills/<name>/SKILL.md.
# Run before merging any branch that touches extensions/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

fail() {
  echo "FAIL: $*"
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "ok  : $*"
}

# ── 1. Package has exactly one omp.extensions entry ────────────────────────
echo "--- [OMP] manifest: single extension entry ---"
EXT_COUNT=$(node -e "const p = require('./package.json'); const exts = p.omp?.extensions; if (!exts) { console.log(0); } else { console.log(exts.length); }")
if [[ "$EXT_COUNT" -eq 1 ]]; then
  pass "omp.extensions has exactly 1 entry"
else
  fail "omp.extensions has $EXT_COUNT entries (expected 1)"
fi

# ── 2. Extension file exists ───────────────────────────────────────────────
echo "--- [OMP] extension file exists ---"
EXT_PATH=$(node -e "const p = require('./package.json'); console.log(p.omp?.extensions?.[0] || '')")
if [[ -z "$EXT_PATH" ]]; then
  fail "No omp.extensions entry found"
else
  if [[ -f "$EXT_PATH" ]]; then
    pass "extension file '$EXT_PATH' exists"
  else
    fail "extension file '$EXT_PATH' does not exist"
  fi
fi

# ── 3. Extension source contains required symbols ──────────────────────────
echo "--- [OMP] required runtime symbols in extension ---"
if [[ -n "$EXT_PATH" && -f "$EXT_PATH" ]]; then
  for sym in "registerCommand" "registerTool" "tool_call"; do
    if grep -q "$sym" "$EXT_PATH" 2>/dev/null; then
      pass "symbol '$sym' found in extension source"
    else
      fail "symbol '$sym' NOT found in extension source"
    fi
  done
else
  fail "Cannot scan extension symbols — file not resolved"
fi

# ── 4. Skill discovery root is skills/ ────────────────────────────────────
echo "--- [OMP] source skill discoverability (skills/<name>/SKILL.md) ---"
SKILLS_ROOT="$REPO_ROOT/skills"
if [[ ! -d "$SKILLS_ROOT" ]]; then
  fail "skills/ directory not found at $SKILLS_ROOT"
else
  TOTAL=0
  MISSING=0
  while IFS= read -r skill_md; do
    rel="${skill_md#"$SKILLS_ROOT"/}"
    # Each should be exactly <name>/SKILL.md (one level of nesting).
    if [[ "$rel" != */SKILL.md || "${rel%%/*}" == "" ]]; then
      fail "unexpected SKILL.md path: $rel"
      MISSING=$((MISSING + 1))
      continue
    fi
    TOTAL=$((TOTAL + 1))
  done < <(find "$SKILLS_ROOT" -maxdepth 2 -name SKILL.md 2>/dev/null | sort)

  if [[ "$TOTAL" -eq 0 ]]; then
    fail "no skills found under skills/"
  elif [[ "$MISSING" -eq 0 ]]; then
    pass "$TOTAL source skills all at skills/<name>/SKILL.md"
  else
    fail "$MISSING/$TOTAL skills at unexpected paths"
  fi
fi

# ── 5. Extension scans skills/ not the repo root ──────────────────────────
echo "--- [OMP] extension targets skills/ root ---"
if [[ -n "$EXT_PATH" && -f "$EXT_PATH" ]]; then
  if grep -q 'join(pluginRoot(), "skills")' "$EXT_PATH" 2>/dev/null; then
    pass "extension calls discoverSkills with skills/ subdirectory"
  else
    fail "extension does not target skills/ — check discoverSkills call in $EXT_PATH"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "OMP extension validation passed"
else
  echo "OMP extension validation FAILED ($ERRORS error(s))"
  exit 1
fi
