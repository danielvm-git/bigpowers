# bigpowers-mcp — Architecture and Operator Guide

Epic e32 delivers a project-specific MCP server that gives agents semantic understanding of the bigpowers skill catalog without reading every `SKILL.md` file.

## Architecture

```
skills/*/SKILL.md
       │
       ▼
 remark-parse pipeline ──► structured JSON (frontmatter, headings, code blocks)
       │
       ▼
 entity-relation graph (Memory server pattern) ──► graph.jsonl
       │
       ▼
 MCP tools (stdio) ──► Claude Code / Cursor / OpenCode clients
```

### Parsing pipeline

- **remark-parse** walks Markdown AST for headings, code fences, links, and prose sections.
- **js-yaml** parses YAML frontmatter (with fallback for edge-case descriptions).
- Path guards restrict all reads to `skills/<name>/SKILL.md` under the repo root.

### Knowledge graph

The **entity-relation** model (inspired by the MCP Memory server reference) stores:

| Entity type | Observations |
|-------------|--------------|
| Skill | model, effort, description from frontmatter |

| Relation type | Source pattern |
|---------------|----------------|
| `depends_on` | `run X after Y` in prose |
| `gates` | `HARD GATE:` lines |
| `references` | `see skills/X/SKILL.md` |
| `enforces` | `CONVENTIONS.md` references |
| `handoff_to` | handoff chain hints |

Graph persists to `bigpowers-mcp/graph.jsonl` for fast cold start.

## Tool catalog

| Tool | Purpose | Example use |
|------|---------|-------------|
| `index_skills` | List all skills with phase | Bootstrap session context |
| `read_skill` | Parse one SKILL.md to JSON | Deep-read before invoking a skill |
| `build_skill_graph` | Build + persist graph | After catalog changes |
| `read_graph` | Dump full graph | Architecture visualization |
| `search_nodes` | Search graph entities | Find skills mentioning "TDD" |
| `open_nodes` | Fetch entities by name | Inspect one node |
| `search_skills` | Substring search on catalog | "Which skill handles deploy?" |
| `get_dependencies` | Forward/reverse deps + handoff chain | Blast-radius before refactor |
| `get_git_context` | Git status/log/diff for skills/ + specs/ | Drift detection |
| `validate_skill` | Convention compliance check | Pre-merge skill lint |

## Development

```bash
cd bigpowers-mcp
npm install
npm run build
npm test
node build/index.js   # stdio MCP server
```

### MCP Inspector

```bash
npx @modelcontextprotocol/inspector node bigpowers-mcp/build/index.js
```

### Adding a new tool

1. Add handler in `src/tools/index.ts` (or extract to `src/tools/<name>.ts`).
2. Register with `server.registerTool()` and zod input schema.
3. Add vitest coverage under `test/` with `// scenario: SC-e32sNN-...` trace tag.
4. Rebuild: `npm run build`.

### Regenerating the graph

Call `build_skill_graph` via Inspector or any MCP client after skill catalog changes.

## Integration

Project `.mcp.json` registers the server:

```json
{
  "mcpServers": {
    "bigpowers-mcp": {
      "command": "node",
      "args": ["bigpowers-mcp/build/index.js"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

Agents discover tools on session start. Set `BIGPOWERS_ROOT` if cwd is not the repo root.

## Performance

| Metric | Target |
|--------|--------|
| Cold start + index 74 skills | < 2s |
| Graph size | ~74 entities, ~200 relations (typical) |
| `read_skill` response | capped at 512KB |

Caching: `graph.jsonl` warm start avoids re-parsing on every query.

## Provenance

- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk) — server transport
- [MCP servers reference implementations](https://github.com/modelcontextprotocol/servers) — Everything, Memory, Git patterns
- [remark/unified](https://github.com/remarkjs/remark) — Markdown parsing
- Supersedes `scripts/mcp-server.js` (e21 prototype) — deprecate note only until e32 fully landed

## Security

See `specs/security/epics/e32/THREAT_MODEL.md`. Key mitigations:

- Path allowlist on `read_skill`
- Git subprocess scoped to `skills/` and `specs/` only
- Secret path denylist in diff output
- No network listeners in v1
