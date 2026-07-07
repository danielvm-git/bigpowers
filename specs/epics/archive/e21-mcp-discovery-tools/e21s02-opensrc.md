---
story_id: e21s02
title: "Wire opensrc into research-first for learn-before-build"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e21s02: opensrc integration

Integrate `opensrc` (202 repos + 31 npm/PyPI packages cached) into `research-first`
so agents do `npx opensrc fetch` before building integrations with external libraries.

BigBase has a massive cached library of source code that could dramatically improve
code quality for integrations.

## Acceptance Criteria

- [ ] `research-first/SKILL.md` has an opensrc integration section
- [ ] `scripts/bp-opensrc-check.sh` exists and works

## Gherkin Scenarios

```gherkin
Given a story requires integrating with @modelcontextprotocol/sdk
And opensrc has the MCP TypeScript SDK cached locally
When research-first runs
Then it calls npx opensrc search @modelcontextprotocol/sdk
And finds the cached source at ~/.opensrc/modelcontextprotocol-sdk/
And reads the src/ directory for API shapes
And appends "opensrc: found MCP SDK v1.x — exports Client, Server, Transport classes"
```

## Verification

```bash
grep -c "opensrc" research-first/SKILL.md | awk '{if($1>=2) print "OK: opensrc in research-first"; else print "FAIL: only " $1 " refs"}'
test -f scripts/bp-opensrc-check.sh && echo "OK: opensrc check script" || echo "WARN: no script yet"
```

## Implementation Notes

- Add "Check opensrc cache" step to research-first workflow
- bp-opensrc-check.sh: takes package.json or requirements.txt, checks each dependency against opensrc cache
- Append findings to Prior Art section of the spec
