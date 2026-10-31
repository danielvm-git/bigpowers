---
bug_id: BUG-2026-10-29-dashboard-loopback
title: Bind the project dashboard to loopback
status: open
severity: medium
scope: dashboard
---

# Bind the project dashboard to loopback

## Problem and verified root cause

Security impact: MEDIUM. Omitting the listen host bound the project dashboard to the wildcard address, exposing its unauthenticated project snapshots to reachable peers.

Reproduce: run `node tests/security/dashboard-bind.cjs` on the test-only
commit. It fails on the unsafe behavior and passes with the implementation
commit. Existing bug history contains no matching security-boundary fix.

## TDD fix plan

1. RED: assert the public behavior described below against the unfixed code.
2. GREEN: Bind to 127.0.0.1 while retaining the existing port and callback API. This intentionally restricts connections to the local machine.
3. Verify: `node tests/security/dashboard-bind.cjs` and register it in the
   deterministic verification gates.

## Validation evidence and limits

A real TCP listener reports 127.0.0.1, and ephemeral-port allocation and the listen callback work. The unfixed listener reports :: in this environment.

The test-only RED commit was checked in isolation with
`TDD_VERIFY_CMD='node tests/security/dashboard-bind.cjs' bash scripts/verify-tdd-red-commit.sh`.
The test substitutes Express routing and filesystem watching at their I/O boundaries, then uses a real Node HTTP/TCP listener. An installed-Express browser smoke test remains pending.

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
