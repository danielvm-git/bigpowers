---
bug_id: BUG-2026-10-25-release-not-gated
status: open
severity: high
scope: ci / release
title: "Release publishes without waiting for the golden suite or sync gates — three workflows, no needs: edge"
files_changed: ".github/workflows/test-build-release.yml (new), .github/workflows/publish.yml, sync-skills.yml, golden-suite.yml (removed), docs-site.yml, publish-wiki.yml, sync-references.yml, scripts/test-ci-pipeline-contract.sh, scripts/lib/golden-suite-gates.sh, CLAUDE.md, docs/references/*.md, skills/gate-trace/SKILL.md"
approach: "One test-build-release pipeline per the portfolio template (danielvm-git/.github): gate jobs → release via needs:; pinned runner and SHA-pinned actions; a golden gate asserts the contract"
risk_level: medium
commit_message: "fix(ci): gate release on every check in one test-build-release pipeline"
---

# BUG-2026-10-25: Release is not gated on the golden suite or sync gates

## Problem

- **Actual:** `Release` (`publish.yml`), `Golden Anti-Vacuity Suite` (`golden-suite.yml`) and `Sync Skills on Push` (`sync-skills.yml`) are separate workflows triggered by the same push. Release `needs:` only its own `skill-health` job, so semantic-release tags and publishes to npm while the golden suite, the generated-artifact drift check and `trace-stories.sh --strict` are still running — or after they fail.
- **Expected:** A push to `main` publishes only after every gate passes (portfolio template: "Single pipeline per repo (ci → verify → semantic-release → deploy) … one-piece flow — no handoffs between separate workflow files").
- **Evidence:** On 2026-10-25 Release #449 (`120a0d99`) failed only because its own `compliance` step happened to repeat the failing check. Any golden-only or sync-only failure (e.g. G-13, story-verify, stale generated artifacts — #158 left 22 SKILL.md copies stale) would not have stopped the publish. The same check ran in up to three places: compliance ×3, `validate-doctrine` ×3, `run-skill-verify.sh` ×2.

**Security impact: LOW** — supply chain hygiene: publishes unverified builds to npm. Actions also float on major tags and `ubuntu-latest`, against the template's pinning rules.

## Root Cause Analysis

1. **Reproduce:** `gh run list --commit 120a0d99` — Release, Golden Suite and Sync Skills start at the same second; Release has no dependency on the other two.
2. **Isolate:** GitHub Actions `needs:` works only between jobs in one workflow. Cross-workflow gating would require `workflow_run`, which none of these use.
3. **Hypothesize:** Each gate was added as its own workflow (e38s03 sync/trace, e51s04 golden, #96 skill-health) and Release was patched case by case (`skill-health` after the 2.85.1 incident), never re-shaped.
4. **Verify:** `publish.yml` `release.needs: [skill-health]` is the only edge.

## Fix approach

1. New `scripts/test-ci-pipeline-contract.sh` (golden gate) — fails today, passes after the fix:
   - one workflow holds every gate job and the release job;
   - `release` `needs:` every gate job and runs only on push to `main`;
   - no workflow uses `ubuntu-latest`; every `uses:` of a non-local action is SHA-pinned;
   - every job has `timeout-minutes`; release and Pages never cancel in progress;
   - the retired workflows (`publish.yml`, `sync-skills.yml`, `golden-suite.yml`) are gone.
2. `.github/workflows/test-build-release.yml`: jobs `sync`, `verification-gates`, `skill-verify`, `story-verify` → `release`. Triggers: push/PR to `main`/`develop`, nightly cron, dispatch. PR runs cancel stale runs; `main` runs queue.
3. Pin `docs-site.yml`, `publish-wiki.yml`, `sync-references.yml` the same way. Agent workflows (`agent-locks.yml`, generated `agentics-maintenance.yml`) stay as-is per migration plan v2.
4. Update live references (CLAUDE.md commands, docs/references, gate-trace skill).

## Verify

- `bash scripts/test-ci-pipeline-contract.sh` — red before, green after; self-test proves it fails on a release without `needs:`.
- Local Preflight green.
- PR run: all gate jobs green, `release` skipped (PR); `main` run: `release` starts only after all gates finish.

## Results

Local, on `fix/ci-single-pipeline` over 2.88.13 (`5b091bda`):

- `test-ci-pipeline-contract.sh` before the fix: 33 violations (pipeline missing, 3 retired workflows present, `ubuntu-latest` and tag-pinned actions in every non-agent workflow). After: `OK`.
- Self-test: conforming fixture passes; release missing `needs`, `ubuntu-latest`, tag-pinned action, cancellable release and a retired workflow each fail (bash 5 and macOS `/bin/bash` 3.2).
- `actionlint` clean on all changed workflows. Action SHAs resolved from each tag via the GitHub API and match the template's version list.
- Preflight: compliance exit 0 (96 PASS / 2 FAIL, same as main), golden 46/46 PASS, sync-skills exit 0, trace `--strict` exit 0.

_CI evidence (PR run, then main run with release waiting on all gates) recorded below after merge._
