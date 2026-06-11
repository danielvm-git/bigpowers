---
name: simulate-agents
description: "Run Mock User and Auditor agents against a feature in fresh contexts before human review. Use after verify-work, before request-review, when user wants pre-review simulation.model: sonnet"
---


# Simulate Agents
> **HARD GATE** — **HARD GATE** — Simulations are hypothetical. Do NOT use sim results to make production decisions without validation on real agents. Sims help discover gaps, not replace testing.


Two roles, **isolated contexts** (no shared state with BUILD agent):

1. **Mock User** — follows Verification Script; reports UX gaps in plain language.
2. **Auditor** — checks CONVENTIONS.md, security checklist, test coverage; structured pass/fail.

## Process

1. Read story Verification Script + changed files diff.
2. Spawn Mock User: step through UAT script; log failures.
3. Spawn Auditor: run `audit-code` checklist cold.
4. Write `specs/SIMULATION-<feature>.md` with both reports.
5. Failed items → `respond-review` or `plan-work` gaps — do not skip human review.

## Verify

→ verify: `test -f specs/SIMULATION-*.md && grep -c "Mock User\|Auditor" specs/SIMULATION-*.md | awk '{if($1>=2) print "OK"}'`
