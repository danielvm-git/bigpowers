# story: e32s03
# story: e32s05
# story: e32s04

# Test Design: e32 — MCP Semantic Context Server

Epic: e32-mcp-context-server | Risk owner: plan-tests (e46) | Date: 2026-07-04

## 1. Risk Matrix & Scenarios

| Scenario ID | Behavior | Risk | Level | Target |
|-------------|----------|------|-------|--------|
| SC-e32s01-P0-01 | `index_skills` returns all SKILL.md paths with valid frontmatter | P0 | Integration | `bigpowers-mcp/src/tools/index-skills.ts` |
| SC-e32s01-P0-02 | `read_skill` parses frontmatter + headings via remark without failure on full catalog | P0 | Integration | `bigpowers-mcp/src/tools/read-skill.ts` |
| SC-e32s01-P0-03 | MCP Inspector can call both tools against built server | P0 | E2E | `bigpowers-mcp/build/index.js` |
| SC-e32s02-P0-01 | `build_skill_graph` emits entities + relations matching handoff regex patterns | P0 | Integration | `bigpowers-mcp/src/tools/build-skill-graph.ts` |
| SC-e32s02-P0-02 | Graph persists to `graph.jsonl` and reloads on cold start | P0 | Unit | `bigpowers-mcp/src/graph/store.ts` |
| SC-e32s03-P1-01 | `search_skills` ranks by name/description substring | P1 | Unit | `bigpowers-mcp/src/tools/search-skills.ts` |
| SC-e32s03-P1-02 | `get_dependencies` returns forward + reverse edges for a skill | P1 | Integration | `bigpowers-mcp/src/tools/get-dependencies.ts` |
| SC-e32s04-P2-01 | `get_git_context` returns status grouped by skills/specs dirs only | P2 | Integration | `bigpowers-mcp/src/tools/get-git-context.ts` |
| SC-e32s05-P1-01 | `validate_skill` flags missing verify/handoff on critical-path skills | P1 | Unit | `bigpowers-mcp/src/tools/validate-skill.ts` |
| SC-e32s06-P2-01 | `.mcp.json` registers server with workspace-relative cwd | P2 | Integration | `.mcp.json` |
| SC-e32s07-P3-01 | Reference doc documents architecture + tool catalog | P3 | Manual | `docs/references/bigpowers-mcp.md` |

## 2. Test Level Strategy

- **Unit (Vitest):** remark parsers, graph store, search ranking, validate_skill rules — fast, no MCP transport.
- **Integration:** tool handlers against fixture SKILL.md tree under `bigpowers-mcp/test/fixtures/`.
- **E2E:** MCP Inspector smoke on built `index.js` (e32s01 verify command).
- **Manual:** e32s06 client registration, e32s07 doc review.

Default: lowest level that proves behavior. No browser/E2E beyond MCP Inspector.

## 3. Fixture Architecture

```
bigpowers-mcp/
├── test/fixtures/skills/     # 3 minimal SKILL.md samples (valid, missing verify, broken link)
├── test/fixtures/graph/      # golden graph.jsonl for regression
└── vitest.config.ts
```

- **Data factories:** `makeSkillMd(overrides)` helper for parser tests.
- **Isolation:** fixture dir only; never read live `skills/` in unit tests (integration suite may use repo root in e2e job only).
- **Network:** none — stdio MCP only.

## 4. NFR Verification

| NFR | Threshold | Verify |
|-----|-----------|--------|
| Performance | Cold start + index 73 skills < 2s on M-series Mac | `npm test -- perf` (vitest bench, e32s02+) |
| Reliability | Zero parse failures on catalog run | e32s01 verify + vitest integration |
| Operability | stderr logs tool name on error; no secrets in stdout | manual MCP Inspector + code review |

## 5. Out of Scope

- Contract tests against external MCP clients (Claude/Cursor) — manual e32s06 only.
- Semantic/embedding search — substring rank only in e32s03.
- Replacing `scripts/mcp-server.js` until e32s06 lands (deprecation note in e32s07).

## 6. Consumer Wiring

| Consumer | Reads this plan via |
|----------|---------------------|
| plan-work | Copies SC IDs into §17 Gherkin per story |
| develop-tdd | Implements P0 scenarios before P1 per story |
| verify-work | P0 stories: full gate + NFR row 4 above |
| gate-trace | `// scenario: SC-e32s01-P0-01` in test files |
