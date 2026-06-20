---
story_id: e21s03
title: "CI-aware skills — read preflight commands from AGENTS.md"
status: backlog
bcps: 1
type: feat
context: infra
---

# Story e21s03: CI-aware skills

Make skills CI-aware by reading preflight/check commands from `AGENTS.md` instead of
hardcoding them. In BigBase, `npm run preflight` (Go vet + tests + UI build) is the
CI gate, but no bigpowers skill knows about it.

## Acceptance Criteria

- [ ] `scripts/bp-read-agents.sh` extracts preflight commands from AGENTS.md
- [ ] `verify-work/SKILL.md` references bp-read-agents.sh
- [ ] Any skill that runs project commands checks AGENTS.md first

## Gherkin Scenarios

```gherkin
Given AGENTS.md contains:
  ## Preflight
  npm run preflight
When verify-work runs
Then it executes npm run preflight instead of its default checks
And the output includes "Using preflight from AGENTS.md: npm run preflight"
```

## Verification

```bash
grep -c "AGENTS.md\|bp-read-agents\|preflight" verify-work/SKILL.md | awk '{if($1>=1) print "OK: CI-aware in verify-work"; else print "FAIL: not CI-aware"}'
test -f scripts/bp-read-agents.sh && echo "OK: parser script" || echo "WARN: no script yet"
```

## Implementation Notes

- bp-read-agents.sh parses AGENTS.md (or CLAUDE.md, CURSOR.md) for Preflight/Test/Build/Lint/Deploy sections
- Outputs as env vars or JSON: BP_PREFLIGHT, BP_TEST, BP_BUILD, BP_LINT, BP_DEPLOY
- Fall back to default behavior if no AGENTS.md found
- Pattern: any skill that runs project commands checks AGENTS.md first
