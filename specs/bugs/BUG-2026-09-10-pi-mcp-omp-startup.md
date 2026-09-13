---
bug_id: BUG-2026-09-10-pi-mcp-omp-startup
status: open
severity: high
scope: mcp / pi / npm-package
title: "Published MCP server cannot start as an OMP plugin (#123)"
issue: https://github.com/danielvm-git/bigpowers/issues/123
files_changed: ".mcp.json, package.json, package-lock.json, bigpowers-mcp/src/config.ts, scripts/validate-mcp-package.sh, scripts/mcp-smoke.ts, scripts/lib/golden-suite-gates.sh, scripts/test-install-helpers.js, docs/references/bigpowers-mcp.md"
approach: "Use OMP_PLUGIN_ROOT in shipped .mcp.json; hoist bigpowers-mcp runtime deps to root package.json; add installed-package smoke gate"
risk_level: low
commit_message: "fix(mcp): start bigpowers-mcp from OMP plugin installs (#123)"
---

# BUG-2026-09-10: Published MCP server cannot start as an OMP plugin (#123)

## Problem

- **Actual:** Installing `bigpowers@2.88.2` as an OMP user plugin fails MCP startup with
  `ENOENT: ... posix_spawn 'node'` (misleading — cwd is invalid, not Node missing).
  After forcing cwd to the package root, `ERR_MODULE_NOT_FOUND` for
  `@modelcontextprotocol/sdk` because runtime deps live only in `bigpowers-mcp/package.json`
  and are not installed in the published tarball graph.
- **Expected:** The npm package starts its declared MCP server from an arbitrary OMP
  project without a separate dependency installation.
- **Reproduce:** Install bigpowers as an OMP plugin; observe `.mcp.json` MCP server fail
  on connect.

**Security impact: NONE** — packaging/configuration defect; no new attack surface.

## Root Cause Analysis

Two independent failures in the shipped OMP plugin surface:

1. **Invalid cwd placeholder:** `.mcp.json` sets `"cwd": "${workspaceFolder}"`.
   OMP expands `${VAR}` from the process environment ([OMP MCP config docs](https://github.com/can1357/oh-my-pi/blob/HEAD/docs/mcp-config.md)),
   but `workspaceFolder` is a VS Code token, not an env var. OMP resolves the broken
   path under the plugin directory → spawn cwd does not exist → `ENOENT`.

2. **Missing runtime dependencies:** `bigpowers-mcp/package.json` declares
   `@modelcontextprotocol/sdk` and remark/unified deps, but the root `bigpowers`
   package does not. The published tarball ships `bigpowers-mcp/build/` without
   `bigpowers-mcp/node_modules/`, so Node cannot resolve imports when OMP spawns
   `node bigpowers-mcp/build/index.js` from the installed package.

**Prior art:** Related to e32 MCP registration (`.mcp.json`) and BUG-2026-08-07 npm
tarball path coverage — same class of "published artifact not runnable after install".

## TDD Fix Plan

1. **RED:** `scripts/validate-mcp-package.sh` rejects `workspaceFolder` in shipped
   `.mcp.json` and requires `@modelcontextprotocol/sdk` in root `dependencies`.
   **GREEN:** Point cwd/args at `${OMP_PLUGIN_ROOT}`; hoist MCP runtime deps to root.
   **verify:** `bash scripts/validate-mcp-package.sh`

2. **RED:** `scripts/mcp-smoke.ts` simulates OMP spawn from plugin root and expects
   stderr `bigpowers-mcp started` without module-not-found.
   **GREEN:** Keep deps hoisted; adjust `getRepoRoot()` for published package layout
   (skills/ without specs/).
   **verify:** `node scripts/mcp-smoke.ts`

## Acceptance Criteria

- [ ] Shipped `.mcp.json` uses `${OMP_PLUGIN_ROOT}` (not `${workspaceFolder}`).
- [ ] Root `package.json` declares bigpowers-mcp runtime dependencies.
- [ ] MCP server starts from package root without `cd bigpowers-mcp && npm install`.
- [ ] Golden gate `mcp-package` passes.
- [ ] npm tarball includes `.mcp.json` and `bigpowers-mcp/build/index.js`.
- [ ] Full preflight passes.
