---
story_id: e21s01
title: "MCP-native skill discovery — register skills as MCP tools"
status: backlog
bcps: 3
type: feat
context: infra
---

# Story e21s01: MCP server

Register bigpowers skills as MCP (Model Context Protocol) tools so agents can call
`list_skills()` and get the live catalog with descriptions and parameters, rather than
reading a static `<available_skills>` block in the system prompt.

BigBase built an MCP server (epic e38) with `list_services`, `get_service_docs`,
`get_code_example`, `list_frameworks` — specifically so agents could discover capabilities
dynamically. Bigpowers should do the same.

## Acceptance Criteria

- [ ] `scripts/mcp-server.js` (or .py) implements 5 tools
- [ ] Server starts with a single command: `node scripts/mcp-server.js` or `python3 scripts/mcp-server.py`
- [ ] `bigpowers_list_skills` returns all 62 skills
- [ ] `bigpowers_get_skill` returns full SKILL.md for any valid skill name
- [ ] `bigpowers_search_skills` returns relevant results for a query
- [ ] README documents MCP server setup

## MCP Tools

1. `bigpowers_list_skills` → returns all 62 skills with name, description, phase
2. `bigpowers_get_skill` → takes skill name, returns full SKILL.md content
3. `bigpowers_search_skills` → takes query string, returns matching skills (semantic or keyword)
4. `bigpowers_get_state` → returns current state.yaml (active flow, epic, step)
5. `bigpowers_invoke_skill` → takes skill name + context, returns skill instructions

## Verification

```bash
test -f scripts/mcp-server.js -o -f scripts/mcp-server.py && echo "OK: MCP server exists" || echo "FAIL: no MCP server"
node -e "require('./scripts/mcp-server.js')" 2>/dev/null && echo "OK: server loads" || python3 -c "import importlib; importlib.import_module('scripts.mcp-server')" 2>/dev/null && echo "OK: server loads" || echo "CHECK: manual load test"
```

## Gherkin Scenarios

```gherkin
Given bigpowers is installed with 62 skills
When an agent calls MCP tool bigpowers_list_skills
Then it returns a JSON array with 62 entries
And each entry has name, description, and phase fields
And the agent can filter by phase: bigpowers_list_skills(phase="verify")

Given the agent wants to use survey-context
When it calls bigpowers_get_skill(name="survey-context")
Then it returns the full SKILL.md content with instructions

Given the agent types "I need to deploy"
When it calls bigpowers_search_skills(query="deploy")
Then it returns [deploy, release-branch, smoke-test] ranked by relevance
```

## Implementation Notes

- Thin MCP server wrapper — auto-discovers skills from .pi/skills/ directory
- Declare in .pi/mcp.json or equivalent manifest
- Document in README.md: "Add bigpowers as an MCP server: pi mcp add bigpowers"
