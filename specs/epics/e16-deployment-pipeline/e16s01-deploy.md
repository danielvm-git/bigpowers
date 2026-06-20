---
story_id: e16s01
title: "craft-skill: deploy — build → verify → deploy → wait → smoke"
status: backlog
bcps: 3
type: feat
context: infra
---

# Story e16s01: deploy skill

Create a `deploy` skill that orchestrates the full deployment pipeline:
build artifact, verify it, deploy via platform tool, wait for status, smoke-test the URL.

Closes the biggest gap from big-bolao feedback — every fix/feature cycle ended with
manual `npm run build` + `commit dist/` + push + manual deploy. Would have prevented
bugs like SPA interception breaking version and og:image being SVG from reaching production.

## Acceptance Criteria

- [ ] Skill file: `deploy/SKILL.md` with verb-noun naming
- [ ] References MCP deploy tools (BigBase, Vercel, etc.) but is platform-agnostic
- [ ] Has configurable timeout and retry with backoff
- [ ] Verification step includes `curl -sSf $DEPLOY_URL` as baseline smoke
- [ ] Skill is listed in SKILL-INDEX.md

## Gherkin Scenarios

```gherkin
Given a project with package.json
And a build script: "npm run build"
When deploy runs
Then it executes npm run build
And verifies dist/ exists and is non-empty
And invokes the platform deploy tool (MCP or CLI)
And polls deploy status every 30s for up to 5 minutes
And on success, runs curl -sSf $DEPLOY_URL
And reports: "Deploy successful — $DEPLOY_URL responds 200"

Given the build artifact is empty or missing
When deploy runs
Then it reports: "FAIL: build artifact not found at dist/"
And exits non-zero without attempting deploy
```

## Verification

```bash
test -f deploy/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: deploy" deploy/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "build\|artifact\|deploy\|smoke" deploy/SKILL.md && echo "OK: covers pipeline stages" || echo "FAIL: missing stages"
grep -q "deploy" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- Detect build command from package.json, Cargo.toml, Makefile, or AGENTS.md
- Platform-agnostic: reference MCP deploy tools but accept CLI fallback
- Configurable timeout (default 5 min), retry with exponential backoff
- Smoke step: `curl -sSf $DEPLOY_URL` as baseline; handoff to smoke-test skill for full validation
