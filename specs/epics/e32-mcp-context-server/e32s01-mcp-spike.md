STORY KEY: E32-S01
TITLE:     Spike — bigpowers-mcp with index_skills + read_skill
TYPE:      Story
PARENT:    e32
STATUS:    Draft
AUTHOR:    dvm           DATE: 2026-07-04
MATURITY:  3
SIZE:      M
RISK:      P0

### 1. Business narrative
Agents today discover bigpowers skills via static prompt blocks or the e21
prototype (`scripts/mcp-server.js`), which returns raw SKILL.md text without
structured parsing. Epic e32 replaces that prototype with a TypeScript MCP
server using remark for frontmatter and section extraction. Story e32s01 proves
the parsing pipeline against the full live catalog before graph tools land.

### 2. Value statement
As a maintainer, I want a spike MCP server that indexes and parses every
SKILL.md reliably, so subsequent stories can build the knowledge graph on
proven structured data instead of regex-on-raw-text.

### 3. Actors and permissions
- Maintainer — runs build + MCP Inspector locally.
- Agent (via MCP client) — calls `index_skills` and `read_skill` after e32s06.

### 4. Trigger and preconditions
Trigger: `kickoff-branch` on `feat/e32s01-mcp-spike`, then `develop-tdd`.
Preconditions:
- `specs/tech-architecture/e32-TEST_PLAN_LATEST.md` exists.
- `specs/security/epics/e32/THREAT_MODEL.md` reviewed.

### 5. Main flow and business logic
1. Scaffold `bigpowers-mcp/` with TypeScript, `@modelcontextprotocol/sdk`, vitest.
2. Implement `index_skills` — glob `skills/*/SKILL.md`, return name + path + phase hint.
3. Implement `read_skill` — remark-parse + remark-frontmatter → JSON (frontmatter, headings, code blocks).
4. Path guard: skill name resolves only under `skills/` (threat model §Mitigation 1).
5. Integration test: parse all catalog SKILL.md files — zero failures.
6. MCP Inspector smoke: both tools callable on built server.

### 6. Alternative flows and exceptions
6a. Parse failure on one SKILL.md — spike HALTs; fix source or parser before proceeding.
6b. Skill name not found — tool returns structured error, not stack trace to client.

### 7. Interface elements
- MCP tools: `index_skills`, `read_skill`.
- CLI: `npm run build && node build/index.js` (stdio).
- Inspector: `npx @modelcontextprotocol/inspector node bigpowers-mcp/build/index.js`.

### 8. Domain model
Entities: Skill (name, path, frontmatter, sections), ParseResult (ok | error).
Artifacts: `bigpowers-mcp/`, `graph.jsonl` (not in s01).

### 9. Integrations and boundaries
- Supersedes: `scripts/mcp-server.js` (deprecate in e32s07, not delete in s01).
- Consumes: `skills-lock.json` optional for catalog validation.
- Does not write to `skills/`, `specs/`, or `.cursor/`.

### 10. Background processes
MCP server long-lived stdio process per client session.

### 11. Notifications
stderr: `bigpowers-mcp started` on boot; structured JSON errors to client.

### 12. Audit and logging
No persistent audit trail in spike. Log parse failure count to stderr on catalog run.

### 13. Solution variabilities
- Parser: remark/unified (chosen) vs tree-sitter-markdown (rejected per epic research).
- Test runner: vitest (new for repo).

### 14. Quality attributes *NFR*
- Catalog parse: 0 failures on 73 SKILL.md files.
- `read_skill` response < 512KB per file (truncate with flag if exceeded).

### 15. Security and compliance *NFR*
- Path traversal blocked on `read_skill` name parameter.
- No git subprocess in s01.

### 16. UX and accessibility *NFR*
N/A — developer tooling.

### 17. Acceptance criteria
Scenario: SC-e32s01-P0-01 — index discovers catalog
  Given the bigpowers repo with skills/*/SKILL.md
  When  index_skills is called via MCP
  Then  the result includes every skill directory with a SKILL.md
  And   each entry has name and relative path

Scenario: SC-e32s01-P0-02 — remark parse succeeds on full catalog
  Given the live skills catalog
  When  read_skill is called for each skill name
  Then  every call returns valid frontmatter JSON
  And   zero parse errors are recorded

Scenario: SC-e32s01-P0-03 — MCP Inspector smoke
  Given a built bigpowers-mcp server
  When  MCP Inspector invokes index_skills and read_skill
  Then  both return structured JSON without transport errors

### 18. Out of scope
- build_skill_graph, search, git, validate tools (e32s02–s05).
- Client registration (e32s06).
- Deleting scripts/mcp-server.js.

### 19. Open questions
- Root package.json workspace vs standalone bigpowers-mcp/package.json — use standalone per epic.yaml.

### 20. References
- specs/epics/e32-mcp-context-server/epic.yaml (e32s01)
- specs/tech-architecture/e32-TEST_PLAN_LATEST.md
- specs/security/epics/e32/THREAT_MODEL.md
- specs/tech-architecture/IMPACT_LATEST.md
- scripts/mcp-server.js (e21 prototype)
- docs/references/agent-config-files-and-okf.md
