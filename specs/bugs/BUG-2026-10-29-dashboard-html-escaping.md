---
bug_id: BUG-2026-10-29-dashboard-html-escaping
title: Render dashboard project metadata as text
status: open
severity: medium
scope: dashboard
---

# Render dashboard project metadata as text

## Problem and verified root cause

Security impact: MEDIUM. Project-controlled state, epic, release and cycle-time strings were interpolated directly into innerHTML, allowing project metadata to become executable HTML when the dashboard was opened.

Reproduce: run `node tests/security/dashboard-render.cjs` on the test-only
commit. It fails on the unsafe behavior and passes with the implementation
commit. Existing bug history contains no matching security-boundary fix.

## TDD fix plan

1. RED: assert the public behavior described below against the unfixed code.
2. GREEN: Escape all project-controlled text interpolations in the state, metric, epic and ledger panels. Keep the existing layouts and numeric formatting.
3. Verify: `node tests/security/dashboard-render.cjs` and register it in the
   deterministic verification gates.

## Validation evidence and limits

The shipped client receives hostile metadata through both initial fetch and SSE. All eleven affected text positions contain escaped literal text; ordinary branch names, zero metrics and empty states still render.

The test-only RED commit was checked in isolation with
`TDD_VERIFY_CMD='node tests/security/dashboard-render.cjs' bash scripts/verify-tdd-red-commit.sh`.
The test executes the full client script in a VM with a mocked DOM and captures rendered HTML. It does not claim a real-browser XSS execution test; browser UAT remains pending.

Full preflight remains pending: the working environment contains a fetched
source subset and lacks installed npm dependencies. Compliance fails because
verification features are absent; the gate runner lacks golden-suite-agent.sh.
The sync script was exercised in a disposable checkout, but partial-catalog
output is not full sync validation. No unrelated generated output is included.

- [x] Regression fails on the unfixed code and passes with this fix.
- [x] Regression registered in the deterministic gates.
- [ ] Full checkout preflight and applicable manual verification pass.

## Upstream rebase verification

Rebased onto `37824eb41502f0204b9f119676bbeee37c5a0278` (2.88.17) on
2026-10-31. The targeted regression still fails on this upstream snapshot and
passes with this fix. Upstream's existing bug records are preserved. Full-suite
validation remains pending for the environment limitations described above.
