---
story_id: e21s04
title: "compose-workflow → AGENTS.md agentic stack mapping"
status: backlog
bcps: 2
type: feat
context: infra
---

# Story e21s04: agentic stack mapping

Map BigBase's agentic stack commands (defined in AGENTS.md) to bigpowers skill compositions
using `compose-workflow`.

BigBase uses fixed commands: `/check-stack`, `/ship`, `/tdd`, `/code-review`, `/security`,
`/plan`, `/build-fix`, `/e2e`. These should be compose-workflow recipes so the skill set
and the agentic stack don't diverge.

## Acceptance Criteria

- [ ] 8 workflow recipe files in `specs/workflows/`
- [ ] `compose-workflow/SKILL.md` documents the standard recipe library
- [ ] Each recipe has a `verify:` command

## Standard Recipes

| Command | Workflow |
|---------|----------|
| `/check-stack` | survey-context → assess-impact → verify-work |
| `/ship` | audit-code → commit-message → release-branch |
| `/tdd` | develop-tdd (F.I.R.S.T enforced) |
| `/code-review` | audit-code → request-review → respond-review |
| `/security` | audit-code (security focus) → request-review |
| `/plan` | survey-context → research-first → plan-work |
| `/build-fix` | investigate-bug → diagnose-root → quick-fix → validate-fix |
| `/e2e` | smoke-test → verify-work |

## Verification

```bash
ls specs/workflows/*.yaml 2>/dev/null | wc -l | awk '{if($1>=8) print "OK: " $1 " workflow recipes"; else print "FAIL: only " $1 " recipes"}'
```

## Gherkin Scenarios

```gherkin
Given a user types /ship in their agent
And AGENTS.md maps /ship to compose-workflow ship
When compose-workflow ship runs
Then it chains audit-code → commit-message → release-branch
And each skill runs in sequence with gates between them
```

## Implementation Notes

- Recipe files in specs/workflows/: check-stack.yaml, ship.yaml, tdd.yaml, code-review.yaml, security.yaml, plan.yaml, build-fix.yaml, e2e.yaml
- Each recipe: name, skills[], description, verify command
- AGENTS.md template shows mapping: `/check-stack` = `compose-workflow check-stack`
