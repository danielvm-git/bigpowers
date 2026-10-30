---
bug_id: BUG-2026-10-30-mcp-unset-plugin-root
status: open
severity: medium
scope: mcp / npm-package
title: "bigpowers-mcp fails in hosts that do not set OMP_PLUGIN_ROOT (#168)"
issue: https://github.com/danielvm-git/bigpowers/issues/168
files_changed: ".mcp.json, scripts/mcp-smoke.ts, scripts/validate-mcp-package.sh, docs/references/bigpowers-mcp.md"
approach: "Give every ${OMP_PLUGIN_ROOT} reference a ':-.' default so hosts that do not inject it resolve the package-relative path; smoke-test the manifest under both host profiles"
risk_level: low
commit_message: "fix(mcp): default OMP_PLUGIN_ROOT so bigpowers-mcp starts outside OMP (#168)"
---

# BUG-2026-10-30: bigpowers-mcp fails in hosts that do not set OMP_PLUGIN_ROOT (#168)

## Problem

- **Reported (#168, bigpowers 2.87.3, omp v18.14.0):**
  `ENOENT: ... posix_spawn 'node'`, then `ERR_MODULE_NOT_FOUND` for
  `@modelcontextprotocol/sdk`. The reporter attributes the first error to a bare
  `node` not on `PATH`.
- **Actual on 2.88.16:** both reported failures are already fixed by #125 (2.88.4).
  A residual defect remains: the shipped `.mcp.json` uses `${OMP_PLUGIN_ROOT}` with
  no default. Any host that reads the manifest but does not inject that variable
  (Claude Code project scope — including every Claude Code session in this repo)
  spawns `node '${OMP_PLUGIN_ROOT}/bigpowers-mcp/build/index.js'` literally and
  fails with `CONNECTION_CLOSED`.
- **Expected:** The manifest starts the server in OMP plugin installs and in a
  host that resolves paths from the package/project root.

**Security impact: NONE** — manifest path defaults; no new attack surface.

## Reproduction (2026-10-30)

1. `npm pack` → `npm install <tgz>` into a fresh plugin tree. Spawn
   `node <pkg>/bigpowers-mcp/build/index.js` from the package root and send
   `initialize` + `tools/list` → **both succeed** (2.88.16). Report items 1–2 are
   not reproducible on current releases.
2. `bun -e 'Bun.spawn(["node","-v"],{cwd:"/nonexistent/x"})'` →
   `ENOENT: no such file or directory, posix_spawn 'node'`. Bun names the command
   when the **cwd** is missing; the 2.87.3 error came from the
   `${workspaceFolder}` cwd (fixed in #125), not from `PATH`.
3. `claude mcp list` in this repo →
   `Missing environment variables: OMP_PLUGIN_ROOT`; the session shows
   `bigpowers-mcp (CONNECTION_CLOSED)`.
4. Local-scope health check from the installed package dir:
   - current manifest → `✘ Failed to connect — CONNECTION_CLOSED`
   - `${OMP_PLUGIN_ROOT:-.}` manifest → `✔ Connected`
   - bogus `cwd` (`/nonexistent/zz`) → `✔ Connected` (Claude Code ignores `cwd`)

## Root Cause Analysis

- **Hypothesis:** the manifest assumes `OMP_PLUGIN_ROOT` is always defined.
- **Evidence:** omp (`packages/coding-agent/src/discovery/omp-plugins.ts`) passes
  `OMP_PLUGIN_ROOT: root.path` as extra env to `expandEnvVarsDeep`, which
  supports POSIX `${VAR:-default}` (`discovery/helpers.ts`). Claude Code project
  `.mcp.json` expands only ambient env; an unset `${VAR}` with no `:-default` is
  left as literal text (Claude Code MCP docs, "Configuration warnings").
- **Why #125 missed it:** `scripts/mcp-smoke.ts` hard-codes the entry path and
  injects `OMP_PLUGIN_ROOT`, so it never evaluates the manifest the way a host
  without that variable does.
- **Confirmed:** step 4 above.

**Prior art:** BUG-2026-09-10-pi-mcp-omp-startup (#123) — same "shipped manifest
not runnable in a host" class; that fix covered only the OMP profile.

## TDD Fix Plan

1. **RED:** `scripts/mcp-smoke.ts` expands the manifest's `args` per host profile
   (omp: `OMP_PLUGIN_ROOT` set; claude-code: unset, cwd = project root) and starts
   the server from the expanded path. Fails for the claude-code profile today.
   **GREEN:** `.mcp.json` uses `${OMP_PLUGIN_ROOT:-.}` in `args` and `cwd`.
   **verify:** `node scripts/mcp-smoke.ts`
2. **RED:** `scripts/validate-mcp-package.sh` rejects any `${OMP_PLUGIN_ROOT}`
   reference without a `:-` default. **GREEN:** same manifest change.
   **verify:** `bash scripts/validate-mcp-package.sh`
3. Docs: correct the Integration section in `docs/references/bigpowers-mcp.md`
   (Claude Code does not set `OMP_PLUGIN_ROOT`) and add a troubleshooting note
   for #168 (upgrade to ≥ 2.88.4; Bun's misleading `posix_spawn 'node'`).

## Acceptance Criteria

- [ ] `.mcp.json` resolves under omp (variable set) and Claude Code (unset).
- [ ] `node scripts/mcp-smoke.ts` covers both host profiles.
- [ ] `bash scripts/validate-mcp-package.sh` passes.
- [ ] `claude mcp list` in this repo no longer warns about `OMP_PLUGIN_ROOT`.
- [ ] Full preflight passes.
