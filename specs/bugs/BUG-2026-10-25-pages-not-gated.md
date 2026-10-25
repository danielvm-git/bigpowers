---
bug_id: BUG-2026-10-25-pages-not-gated
status: fixed
severity: medium
scope: ci / docs
title: "GitHub Pages deploy runs as its own workflow — docs can publish while a gate job is red"
files_changed: ".github/workflows/test-build-release.yml, .github/workflows/docs-site.yml (removed), scripts/test-ci-pipeline-contract.sh, CLAUDE.md"
approach: "Move the Pages build/deploy into test-build-release.yml behind needs: on every gate job; deploy only on push to main when docs paths changed; contract gate asserts it"
risk_level: low
commit_message: "fix(ci): gate the GitHub Pages deploy on every check in test-build-release"
---

# BUG-2026-10-25: GitHub Pages deploy is not gated on the pipeline

## Problem

- **Actual:** `Deploy Docs (GitHub Pages)` (`.github/workflows/docs-site.yml`) triggers on push to `main` for docs paths, in parallel with `Test Build Release`. It has no `needs:` edge to `sync`, `verification-gates`, `skill-verify` or `story-verify`, so Pages publishes while a gate job is still running or after it fails.
- **Expected:** Portfolio template (danielvm-git/.github, `docs/concept/github-actions-best-practices.md`): one pipeline, ci → verify → release → deploy. The Pages deploy waits for every gate job.
- **Evidence:** main run of `14250d84` (BUG-2026-10-25-release-not-gated): "Deploy Docs and Publish to Wiki ran on their own and passed" — beside the pipeline, not after it.

**Security impact: LOW** — the public docs site can show content from a commit that failed its gates.

## Root Cause Analysis

1. **Reproduce:** `gh run list --commit 14250d84` — `Deploy Docs (GitHub Pages)` starts with `Test Build Release`, not after it.
2. **Isolate:** `needs:` works only between jobs of one workflow; `docs-site.yml` is a separate workflow with a `push` trigger of its own.
3. **Hypothesize:** e33s04 added the Pages workflow before the single pipeline existed; PR #162 consolidated release but left Pages out of scope.
4. **Verify:** `scripts/test-ci-pipeline-contract.sh` checks only that `docs-site.yml` does not cancel in progress — nothing asserts a Pages edge to the gates.

## Fix approach

1. RED — extend `scripts/test-ci-pipeline-contract.sh`: any job that uses `actions/deploy-pages` must live in `test-build-release.yml`, need every gate job (transitively), run only on push to `main` (or dispatch on `main`), and never cancel in progress. Self-test fixtures: a conforming pipeline with Pages passes; Pages missing a gate edge, Pages in a separate workflow, and cancellable Pages each fail.
2. GREEN — move build + deploy into `test-build-release.yml` as `pages-build` (needs all four gates; `dorny/paths-filter` SHA-pinned decides whether docs paths changed) and `pages-deploy` (needs `pages-build`; job `concurrency: pages`, `cancel-in-progress: false`; 3-attempt deploy retry). Delete `docs-site.yml`.
3. Update live references (CLAUDE.md CI row).

## Verify

- `bash scripts/test-ci-pipeline-contract.sh` red before, green after; `--self-test` green.
- Local Preflight green.
- After merge: a docs change on `main` shows `pages-build` starting only after the four gate jobs finish.

## Results

Local, on `fix/ci-pages-gated` over 2.88.14 (`b066588c`):

- `test-ci-pipeline-contract.sh` before the fix: `FAIL: pipeline has no Pages deploy job` and `FAIL: docs-site.yml:deploy: Pages deploy outside the pipeline`. After: `OK`.
- Self-test (bash 5 and macOS `/bin/bash` 3.2): the conforming fixture with `pages-build` → `pages-deploy` passes; Pages missing gate `needs`, Pages with `always()`, Pages not limited to `main`, cancellable Pages and Pages in a separate workflow each fail for their own reason.
- `actionlint` clean. `dorny/paths-filter` pinned to `ceb8a2b8…` (v4.0.3, 2026-08-05), resolved from the tag via the GitHub API.
- `workflow_dispatch` on `main` still redeploys (now behind the gates, too).

### CI measured

**PR #164** (head `b5627ebe`): `sync`, `verification-gates`, `skill-verify`, `story-verify` pass; `release`, `pages-build`, `pages-deploy` skipped (pull_request).

**main** — squash `5f3e4de5`, [Test Build Release run 40203121441](https://github.com/danielvm-git/bigpowers/actions/runs/40203121441), all jobs success:

| Job | Start (UTC) | End (UTC) |
|---|---|---|
| `skill-verify` | 14:37:43 | 14:37:56 |
| `story-verify` | 14:37:43 | 14:38:26 |
| `verification-gates` | 14:37:43 | 14:38:50 |
| `sync` | 14:37:43 | 14:39:04 |
| `release` | 14:39:05 | 14:40:03 |
| **`pages-build`** | **14:39:06** | 14:39:38 |
| **`pages-deploy`** | **14:39:41** | 14:39:53 |

`pages-build` started 2s after the last gate job (`sync`) finished — the `needs:` edge holds — and `pages-deploy` followed it. The merge touched `.github/workflows/test-build-release.yml` (a docs-filter path), so the filter chose to deploy. `release` published 2.88.15 (`117b7607`). No separate Deploy Docs workflow ran; Publish to Wiki (run 40203121320) passed.
