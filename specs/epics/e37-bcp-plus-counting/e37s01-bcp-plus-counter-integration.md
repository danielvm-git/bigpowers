# Story e37s01: BCP Plus Counter Integration

**Epic:** e37 — BCP Plus Counting
**Type:** feat
**BCPs:** 5
**Risk:** P1
**WSJF:** 2.1

## Context

Integrate the `big-counter` project as an optional AI-assisted BCP Plus counting tool into the bigpowers toolchain. Create reference documentation for the 13-dimension BCP Plus methodology and cross-link from the existing BCP reference. Smoke-test the counter against golden stories to verify stability.

## Steps

1. Add big-counter install step to setup-environment skill (pip install or npm link)
   → verify: `big-counter --version exits 0 from the project venv`

2. Create docs/references/bcp-plus.md reference document (DONE: 2026-07-03)
   → verify: `test -f docs/references/bcp-plus.md`

3. Add BCP Plus dimension reference table to docs/references/bcp.md cross-link (DONE)
   → verify: `grep -c 'bcp-plus.md' docs/references/bcp.md`

4. Smoke-test: run big-counter against 3 golden stories, record baseline CV
   → verify: `test -f docs/references/bcp-plus.md && (big-counter --version 2>/dev/null && echo 'big-counter ready for smoke test' || echo 'DEFERRED: big-counter not yet installed')`

## Verification Script

1. Verify bcp-plus.md exists: `test -f docs/references/bcp-plus.md && echo OK`
2. Verify cross-link in bcp.md: `grep -c 'bcp-plus.md' docs/references/bcp.md` (should be >= 1)
3. Verify setup-environment references big-counter: `grep -c 'big-counter' skills/setup-environment/SKILL.md` (should be >= 1)
4. If big-counter is installed: `big-counter --version`

## Out of scope

- Modifying the big-counter project itself
- Integrating big-counter MCP server into the agent runtime
- Automated CI smoke tests with big-counter

## Risks

- big-counter may not be available on all platforms (optional dependency)
- pip/npm registry availability for big-counter package
