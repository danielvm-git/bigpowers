---
story_id: e16s02
title: "craft-skill: smoke-test — post-deploy health-check against live URL"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e16s02: smoke-test skill

Create a `smoke-test` skill that validates a deployed application is healthy.
Runnable standalone OR as the final step of the `deploy` skill.

## Acceptance Criteria

- [ ] Skill file: `smoke-test/SKILL.md` with verb-noun naming
- [ ] Define a `smoke-checks.yaml` or inline checklist pattern
- [ ] Each check has: url, method, expected_status, content_signal (regex or jq)
- [ ] Verification: `bash scripts/run-smoke.sh` or equivalent one-liner
- [ ] Skill is listed in SKILL-INDEX.md

## Gherkin Scenarios

```gherkin
Given a deployed application at https://example.com
And smoke-checks.yaml defines: homepage 200, API /health 200, content contains "bigpowers"
When smoke-test runs
Then homepage returns HTTP 200
And /api/health returns HTTP 200
And response body contains "bigpowers"
And report shows: "3/3 checks passed"

Given smoke-checks.yaml defines a check for /api/jogos with expected_status: 200
And the endpoint returns 503
When smoke-test runs
Then the check is reported as FAIL
And the final exit code is non-zero
And the failing check details are shown
```

## Verification

```bash
test -f smoke-test/SKILL.md && echo "OK: skill file exists" || echo "FAIL: no skill file"
grep -q "name: smoke-test" smoke-test/SKILL.md && echo "OK: frontmatter" || echo "FAIL: frontmatter"
grep -qi "health\|check\|endpoint\|assert" smoke-test/SKILL.md && echo "OK: health-check semantics" || echo "FAIL: missing semantics"
grep -q "smoke-test" SKILL-INDEX.md && echo "OK: in SKILL-INDEX" || echo "FAIL: not indexed"
```

## Implementation Notes

- Accept base URL from env, config, or user prompt
- Load critical pages/endpoints and assert HTTP 200
- Check key content signals via regex or jq
- Report pass/fail summary with specific failures
- Referenceable as final step of deploy skill
