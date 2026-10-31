---
bug_id: BUG-2026-10-29-agents-export-quoting
title: Escape AGENTS command exports before Bash import
status: open
severity: medium
scope: scripts
---

# Escape AGENTS command exports before Bash import

## Problem and verified root cause

Security impact: MEDIUM. A single quote in an extracted AGENTS command broke out of its export value. The documented eval import could execute the suffix before the command was invoked.

Reproduce: run `node tests/security/agents-import.cjs` on the test-only
commit. It fails on the unsafe behavior and passes with the implementation
commit. Existing bug history contains no matching security-boundary fix.

## TDD fix plan

1. RED: assert the public behavior described below against the unfixed code.
2. GREEN: Emit each command with Bash printf %q, preserving it as one value during import. Keep --print output unchanged. Explicitly running imported commands still executes project-provided commands.
3. Verify: `node tests/security/agents-import.cjs` and register it in the
   deterministic verification gates.

## Validation evidence and limits

All five exports round-trip exactly for AGENTS.md, CLAUDE.md and CURSOR.md, including single/double quotes, dollar/backtick substitutions, spaces and shell operators. Harmless marker files prove import does not execute the values.

The test-only RED commit was checked in isolation with
`TDD_VERIFY_CMD='node tests/security/agents-import.cjs' bash scripts/verify-tdd-red-commit.sh`.
The regression runs on Bash 5. printf %q is supported by Bash 3.2, but a macOS/Bash 3.2 execution check remains pending.

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
