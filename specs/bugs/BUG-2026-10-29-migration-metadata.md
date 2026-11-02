---
bug_id: BUG-2026-10-29-migration-metadata
title: Keep migration version metadata out of executable code
status: open
severity: high
scope: migrate
---

# Keep migration version metadata out of executable code

## Problem and verified root cause

Security impact: HIGH. A quoted Python statement in a project version stamp executed while the migration plan was built, even with --dry-run. Paths were also interpolated into preview Python and installed-version JavaScript.

Reproduce: run `node tests/security/migration.cjs` on the test-only
commit. It fails on the unsafe behavior and passes with the implementation
commit. Existing bug history contains no matching security-boundary fix.

## TDD fix plan

1. RED: assert the public behavior described below against the unfixed code.
2. GREEN: Pass version strings and preview paths through argv, and reject malformed detected/installed version stamps before planning. Accept numeric major.minor.patch with optional prerelease/build metadata. Preserve existing migration ordering and selection semantics.
3. Verify: `node tests/security/migration.cjs` and register it in the
   deterministic verification gates.

## Validation evidence and limits

The public CLI rejects a marker-writing version stamp without executing it. Valid release/prerelease stamps and quoted installation/project paths produce a dry-run preview without modifying project files. Controlled migration bundles isolate this boundary. Existing G-06 golden tests: 7 passed, 0 failed.

The test-only RED commit was checked in isolation with
`TDD_VERIFY_CMD='node tests/security/migration.cjs' bash scripts/verify-tdd-red-commit.sh`.
Migration bundles remain trusted executable tooling. The tests do not claim to sandbox bundle transforms. An existing v1 bundle preview also fails on string-valued actions_needed entries; that separate behavior is outside this security fix.

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
