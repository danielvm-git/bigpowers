---
bug_id: BUG-2026-10-29-mcp-secret-diffs
title: Exclude secret files from every MCP diff block
status: open
severity: medium
scope: mcp
---

# Exclude secret files from every MCP diff block

## Problem and verified root cause

Security impact: MEDIUM. A denied secret diff followed by another file was returned to the MCP caller. The final diff block was filtered correctly, but intermediate buffers skipped the policy.

Reproduce: run `node tests/security/git-context.cjs` on the test-only
commit. It fails on the unsafe behavior and passes with the implementation
commit. Existing bug history contains no matching security-boundary fix.

## TDD fix plan

1. RED: assert the public behavior described below against the unfixed code.
2. GREEN: Use one guarded buffer flush for every diff block. Preserve the response shape and allowed-file diffs. Regenerate the shipped runtime and source map from the TypeScript source.
3. Verify: `node tests/security/git-context.cjs` and register it in the
   deterministic verification gates.

## Validation evidence and limits

Tests cover a secret in first, middle, last and only positions, allowed-file contents, out-of-scope files, and an empty diff.

The test-only RED commit was checked in isolation with
`TDD_VERIFY_CMD='node tests/security/git-context.cjs' bash scripts/verify-tdd-red-commit.sh`.
The TypeScript compiler is unavailable (`tsc: not found`). The runtime and source map were regenerated with Node 24.22.1 stripTypeScriptTypes in transform mode; the emitted runtime was tested. A normal tsc build/typecheck and Vitest suite remain pending.

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
