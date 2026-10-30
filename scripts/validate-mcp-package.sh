#!/usr/bin/env bash
# story: e32s06
# MCP package integrity guard — shipped .mcp.json must start from OMP plugin installs
# and root package.json must declare bigpowers-mcp runtime dependencies.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0

source "$REPO_ROOT/scripts/lib/test-assertions.sh"

MCP_JSON="$REPO_ROOT/.mcp.json"
echo "--- [MCP] shipped .mcp.json OMP compatibility ---"
if [[ ! -f "$MCP_JSON" ]]; then
  ta_err ".mcp.json missing at repo root"
else
  if grep -q 'workspaceFolder' "$MCP_JSON" 2>/dev/null; then
    ta_err ".mcp.json uses workspaceFolder — not valid in OMP env expansion (#123)"
  else
    ta_ok ".mcp.json does not reference workspaceFolder"
  fi
  if grep -q 'OMP_PLUGIN_ROOT' "$MCP_JSON" 2>/dev/null; then
    ta_ok ".mcp.json references OMP_PLUGIN_ROOT for plugin installs"
  else
    ta_err ".mcp.json must reference OMP_PLUGIN_ROOT for OMP plugin cwd/args"
  fi
  if grep -q '\${OMP_PLUGIN_ROOT}' "$MCP_JSON" 2>/dev/null; then
    ta_err ".mcp.json uses \${OMP_PLUGIN_ROOT} without a :- default — hosts that do not set it spawn a literal path (#168)"
  else
    ta_ok ".mcp.json OMP_PLUGIN_ROOT references carry a :- default"
  fi
fi

echo "--- [MCP] root runtime dependencies ---"
for dep in "@modelcontextprotocol/sdk" "unified" "remark-parse" "zod"; do
  if node -e "const p=require('./package.json'); process.exit(p.dependencies?.['$dep'] ? 0 : 1)"; then
    ta_ok "root dependencies include $dep"
  else
    ta_err "root dependencies missing $dep (bigpowers-mcp runtime)"
  fi
done

echo "--- [MCP] built server entry ---"
if [[ -f "$REPO_ROOT/bigpowers-mcp/build/index.js" ]]; then
  ta_ok "bigpowers-mcp/build/index.js exists"
else
  ta_err "bigpowers-mcp/build/index.js missing — run cd bigpowers-mcp && npm run build"
fi

echo "--- [MCP] runtime load smoke (scripts/mcp-smoke.ts) ---"
if ! command -v node >/dev/null 2>&1; then
  echo "warn: node unavailable — skipping runtime load smoke"
elif [[ ! -f "$REPO_ROOT/scripts/mcp-smoke.ts" ]]; then
  ta_err "scripts/mcp-smoke.ts not found"
else
  SMOKE_ERR=$(mktemp)
  if node "$REPO_ROOT/scripts/mcp-smoke.ts" >/dev/null 2>"$SMOKE_ERR"; then
    ta_ok "MCP server loads from simulated OMP plugin root"
  else
    ta_err "MCP smoke failed — $(head -3 "$SMOKE_ERR" 2>/dev/null | tr '\n' ' ')"
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
