#!/usr/bin/env bash
# story: e32s06
# MCP package integrity guard — shipped .mcp.json must start from OMP plugin installs
# and root package.json must declare bigpowers-mcp runtime dependencies.
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

MCP_JSON="$REPO_ROOT/.mcp.json"
echo "--- [MCP] shipped .mcp.json OMP compatibility ---"
if [[ ! -f "$MCP_JSON" ]]; then
  fail ".mcp.json missing at repo root"
else
  if grep -q 'workspaceFolder' "$MCP_JSON" 2>/dev/null; then
    fail ".mcp.json uses workspaceFolder — not valid in OMP env expansion (#123)"
  else
    pass ".mcp.json does not reference workspaceFolder"
  fi
  if grep -q 'OMP_PLUGIN_ROOT' "$MCP_JSON" 2>/dev/null; then
    pass ".mcp.json references OMP_PLUGIN_ROOT for plugin installs"
  else
    fail ".mcp.json must reference OMP_PLUGIN_ROOT for OMP plugin cwd/args"
  fi
fi

echo "--- [MCP] root runtime dependencies ---"
for dep in "@modelcontextprotocol/sdk" "unified" "remark-parse" "zod"; do
  if node -e "const p=require('./package.json'); process.exit(p.dependencies?.['$dep'] ? 0 : 1)"; then
    pass "root dependencies include $dep"
  else
    fail "root dependencies missing $dep (bigpowers-mcp runtime)"
  fi
done

echo "--- [MCP] built server entry ---"
if [[ -f "$REPO_ROOT/bigpowers-mcp/build/index.js" ]]; then
  pass "bigpowers-mcp/build/index.js exists"
else
  fail "bigpowers-mcp/build/index.js missing — run cd bigpowers-mcp && npm run build"
fi

echo "--- [MCP] runtime load smoke (scripts/mcp-smoke.ts) ---"
if ! command -v node >/dev/null 2>&1; then
  echo "warn: node unavailable — skipping runtime load smoke"
elif [[ ! -f "$REPO_ROOT/scripts/mcp-smoke.ts" ]]; then
  fail "scripts/mcp-smoke.ts not found"
else
  SMOKE_ERR=$(mktemp)
  if node "$REPO_ROOT/scripts/mcp-smoke.ts" >/dev/null 2>"$SMOKE_ERR"; then
    pass "MCP server loads from simulated OMP plugin root"
  else
    fail "MCP smoke failed — $(head -3 "$SMOKE_ERR" 2>/dev/null | tr '\n' ' ')"
  fi
  rm -f "$SMOKE_ERR"
fi

echo "---"
if [[ "$ERRORS" -eq 0 ]]; then
  echo "MCP package validation passed"
else
  echo "MCP package validation FAILED ($ERRORS error(s))"
  exit 1
fi
