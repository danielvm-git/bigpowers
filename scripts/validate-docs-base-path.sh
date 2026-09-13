#!/usr/bin/env bash
# story: e33s02
# Docs site base-path guard — generated content must include /bigpowers prefix
# for GitHub Pages (see BUG-2026-09-13, #127).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEBSITE="$REPO_ROOT/website"
SITE_BASE="/bigpowers"
ERRORS=0

fail() {
  echo "FAIL: $*"
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "ok  : $*"
}

INDEX_MDX="$WEBSITE/src/content/docs/index.mdx"
LLMS_TXT="$WEBSITE/public/llms.txt"

echo "--- [docs] generated landing hero link ---"
if [[ ! -f "$INDEX_MDX" ]]; then
  fail "missing $INDEX_MDX — run cd website && npm run generate"
elif grep -q "link: ${SITE_BASE}/skills/" "$INDEX_MDX"; then
  pass "hero Browse skills link includes SITE_BASE"
else
  fail "hero link missing ${SITE_BASE}/skills/ prefix in index.mdx"
fi

echo "--- [docs] no root-absolute skill links in landing page ---"
if [[ -f "$INDEX_MDX" ]] && grep -E '\]\(/skills/' "$INDEX_MDX" >/dev/null 2>&1; then
  fail "index.mdx still contains root-absolute /skills/ links"
else
  pass "index.mdx skill links are base-prefixed or absent"
fi

echo "--- [docs] llms.txt URL shape ---"
if [[ ! -f "$LLMS_TXT" ]]; then
  fail "missing $LLMS_TXT — run cd website && npm run generate"
elif grep -q '/bigpowers/bigpowers/' "$LLMS_TXT"; then
  fail "llms.txt double-prefixes SITE_BASE in URLs"
else
  pass "llms.txt has no /bigpowers/bigpowers/ double prefix"
fi

echo "--- [docs] production build hero href ---"
if ! command -v npm >/dev/null 2>&1; then
  echo "warn: npm unavailable — skipping dist/index.html check"
else
  BUILD_ERR=$(mktemp)
  if (cd "$WEBSITE" && npm run build >/dev/null 2>"$BUILD_ERR"); then
    if grep -q 'href="/bigpowers/skills/"' "$WEBSITE/dist/index.html" 2>/dev/null; then
      pass "dist/index.html hero href includes /bigpowers/skills/"
    else
      fail "dist/index.html missing href=\"/bigpowers/skills/\" for Browse skills"
    fi
  else
    fail "website build failed — $(head -3 "$BUILD_ERR" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -f "$BUILD_ERR"
fi

echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "Docs base-path validation passed"
else
  echo "Docs base-path validation FAILED ($ERRORS error(s))"
  exit 1
fi
