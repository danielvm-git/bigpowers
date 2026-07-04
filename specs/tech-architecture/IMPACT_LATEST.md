# Impact Assessment — e32 MCP Semantic Context Server

**Date:** 2026-07-04  
**Story:** e32 (epic) — pre-flight for e32s01 spike  
**Trigger:** survey-context + assess-impact before kickoff-branch

## Blast Radius Summary

| Severity | Count | Theme |
|----------|-------|-------|
| HIGH | 2 | New TypeScript package; supersedes e21 prototype |
| MEDIUM | 4 | e39 graph source; MCP client configs; CI typecheck |
| LOW | 6 | Docs, traceability, optional tool discovery |

## Dependents (what reads / what breaks)

### Directly affected

| Path | Change | Callers |
|------|--------|---------|
| `bigpowers-mcp/` (new) | TypeScript MCP server, 7 tools | Agents via `.mcp.json` (e32s06) |
| `scripts/mcp-server.js` | Superseded, deprecate after e32s06 | Manual `node scripts/mcp-server.js` |
| `.mcp.json` / client configs | New server entry | Claude Code, Cursor, OpenCode |
| `package.json` (root) | Optional workspace script `mcp:build` | CI (future) |

### Downstream epics

| Epic | Relationship |
|------|----------------|
| **e39** | e39s01 standalone `build-skill-graph.sh` **deferred** — consumes e32 `build_skill_graph` tool instead |
| **e39s03** | `check-spec-drift.sh` will consume e32 `get_git_context` (e32s04) |
| **e39s04–s05** | OKF wikis use graph output from e32, not shell script |
| **e43** | Showcase may demo MCP tools (optional) |

### Unaffected

- `scripts/sync-skills.sh` — no change until e39 OKF phase
- Skill sources under `skills/` — read-only from MCP
- Compliance Gherkin suite — additive `plan-tests.feature` only

## Stories touched

| Story | Files expected |
|-------|----------------|
| e32s01 | `bigpowers-mcp/package.json`, `src/index.ts`, `src/tools/index-skills.ts`, `src/tools/read-skill.ts` |
| e32s02–s05 | `bigpowers-mcp/src/tools/*` |
| e32s06 | `.mcp.json`, `skills/orchestrate-project/SKILL.md` (already globs test plans) |
| e32s07 | `docs/references/bigpowers-mcp.md` |

## Test coverage plan

See `specs/tech-architecture/e32-TEST_PLAN_LATEST.md`. P0: e32s01–s02. Vitest introduced in e32s01 spike.

## Build-order waiver

`release-plan.yaml` lists e42 → e47 → e32. **Waived for e32s01 spike only** (2026-07-04):

- e42 golden fixture does not block MCP parsing spike.
- e47 global install does not block local `bigpowers-mcp/` development.
- e32s06 (client registration) should wait for e47s01 pi wiring or document dual setup.

Recorded in `specs/state.yaml` → `active_decisions.e32_build_order_waiver`.

## Verdict

**PROCEED** with e32s01 spike. Coordinate e39s01 before e39 activation. Run security-review on `bigpowers-mcp/` after e32s04 (git tools land).
