---
bug_id: BUG-2026-11-03-story-verify-ab-sandbox-daemon-required
status: fixed
severity: high
scope: ci / story-verify
title: "e58s07 story-verify fails in CI because ab-sandbox.sh status requires background Docker containers"
files_changed: "specs/epics/e58-evals-over-compliance/epic.yaml, specs/epics/e58-evals-over-compliance/e58s07-tasks.yaml, specs/epics/e58-evals-over-compliance/e58s07-docker-sandbox.md, tests/test_ab_sandbox.py"
approach: "Remove daemon status check from story-verify directive, relying on test_ab_sandbox.py which gates grade wrapper and timeout while cleanly handling offline sandbox"
risk_level: low
commit_message: "fix(ci): remove live docker daemon requirement from e58s07 story verify"
---

# BUG-2026-11-03: e58s07 story-verify fails in CI because ab-sandbox.sh status requires background Docker containers

## Problem

- **Actual behavior:** GitHub Actions CI run `41572822780` on PR #187 failed in job `story-verify` during `bash scripts/run-story-verify.sh`:
  `FAIL: e58s07 [specs/epics/e58-evals-over-compliance/epic.yaml] — python3 tests/test_ab_sandbox.py && bash scripts/ab-sandbox.sh status`
  `output: MISSING bp-ab-internal MISSING bp-ab-egress MISSING bp-ab-proxy running`
- **Expected behavior:** `run-story-verify.sh` passes cleanly on fresh CI runners and clean workspaces without requiring an active, pre-running Docker proxy daemon.
- **How to reproduce:** On any environment where `bash scripts/ab-sandbox.sh up` has not been executed, run `bash scripts/run-story-verify.sh e58s07`. It exits non-zero.

## Security Impact

Security impact: NONE. No security exploit path identified. The change affects verification command assertions for sandbox configuration.

## Root Cause Analysis

1. **Phase 1: Reproduce:** Running `bash scripts/ab-sandbox.sh status` in an environment without pre-started Docker containers returns exit code 1 with:
   `MISSING bp-ab-internal`, `MISSING bp-ab-egress`, `MISSING bp-ab-proxy running`.
2. **Phase 2: Isolate:** In `specs/epics/e58-evals-over-compliance/epic.yaml`, story `e58s07` declares:
   `verify: python3 tests/test_ab_sandbox.py && bash scripts/ab-sandbox.sh status`
   Commit `8b36284e` changed `verify:` from `python3 tests/test_ab_sandbox.py` to add `&& bash scripts/ab-sandbox.sh status`.
3. **Phase 3: Hypothesize:**
   - *H1:* The verification command assumes the developer's local state (where `ab-sandbox.sh up` was run) rather than an isolated, stateless CI runner.
   - *H2:* `tests/test_ab_sandbox.py` was already designed with `@unittest.skipUnless(sandbox_up(), ...)` specifically so that tests pass whether the sandbox is running or not.
4. **Phase 4: Verify:** Confirmed that `tests/test_ab_sandbox.py` executes successfully in clean environments (testing grade wrappers, timeout exports, and script properties), while `bash scripts/ab-sandbox.sh status` fails because GitHub Actions does not run background daemons for story verification.

## TDD Fix Plan

1. **RED**: Add a unit test to `tests/test_ab_sandbox.py` (`TestSandboxScript`) verifying `scripts/ab-sandbox.sh` command line behavior without requiring docker (existence, executable permissions, syntax validation via `bash -n`, usage message on invalid arguments).
   **GREEN**: Ensure `tests/test_ab_sandbox.py` tests all offline properties of `scripts/ab-sandbox.sh`.
   **verify**: `python3 tests/test_ab_sandbox.py`

2. **RED**: Verify that `e58s07` story verify passes when decoupled from the daemon status check.
   **GREEN**: Update `specs/epics/e58-evals-over-compliance/epic.yaml` `verify:` for `e58s07` to `python3 tests/test_ab_sandbox.py`, and update `e58s07-tasks.yaml` task 3.
   **verify**: `bash scripts/run-story-verify.sh e58s07`

## Acceptance Criteria

- [ ] `python3 tests/test_ab_sandbox.py` passes without requiring Docker containers to be running.
- [ ] `bash scripts/run-story-verify.sh e58s07` passes in clean environments.
- [ ] `bash scripts/run-story-verify.sh` passes all done stories.
- [ ] No git attribution footers (Co-authored-by).

## Resolution

**Fixed:** 2026-11-03
**Root cause confirmed:** `epic.yaml` chained `&& bash scripts/ab-sandbox.sh status` to story `e58s07`'s verify command, failing in fresh CI environments where the Docker proxy daemon is not running.
**Fix applied:** Updated `specs/epics/e58-evals-over-compliance/epic.yaml` and `e58s07-tasks.yaml` to verify via `python3 tests/test_ab_sandbox.py`, and added `TestSandboxScript` to verify `ab-sandbox.sh` syntax and usage without requiring running containers.
**Hardening added:** Invariant test `TestSandboxScript` in `tests/test_ab_sandbox.py` covering script permissions, bash syntax, and command-line usage.
**Evidence:** `python3 tests/test_ab_sandbox.py` (7/7 passed), `bash scripts/run-story-verify.sh e58s07` passed, full `bash scripts/run-story-verify.sh` (50 PASS, 0 FAIL).
**Commit:** `fix(ci): remove live docker daemon requirement from e58s07 story verify`
