---
bug_id: BUG-2026-07-06T134600
status: fixed
severity: medium
scope: ci
title: "GitHub Pages deploy job fails with 'Deployment failed, try again later' while build succeeds"
security_impact: NONE
---

# BUG-2026-07-06T134600: GitHub Pages deploy flaky after push

## Problem

**Actual:** Run [28795963238](https://github.com/danielvm-git/bigpowers/actions/runs/28795963238) — **Deploy Docs Site to GitHub Pages** failed on push of `fix(bug): python-interpreter-fragility`. The **build** job completed all steps (receipts, Astro site, artifact upload). The **deploy** job failed at `actions/deploy-pages@v4` with:

```
##[error]Deployment failed, try again later.
```

Deployments UI showed the failed run as the active github-pages deployment even though the site content was unchanged.

**Expected:** After a green build, the deploy job publishes `website/dist` to GitHub Pages and the deployment status is success.

**Reproduce:**

```bash
gh run list --workflow "Deploy Docs Site to GitHub Pages" --limit 5
gh run view 28795963238 --log-failed
```

**Prior history:** Related CI bugs in scope `ci` (docs-site node 22 bump, pages enablement). This is a **novel** failure mode — build artifact valid, deploy API rejects.

**Security impact:** NONE — no exploit path; failed deploy leaves the previous site version live.

## Root Cause Analysis

Verified via `gh run view` and deployment API:

- Build job exit 0; artifact uploaded successfully (~7.6 MB, 94 HTML pages when built locally).
- Deploy job creates a Pages deployment record then polls status; GitHub returns failure within ~5 seconds with no actionable sub-error.
- A subsequent `workflow_dispatch` on current `main` (run [28796393721](https://github.com/danielvm-git/bigpowers/actions/runs/28796393721)) **succeeded** with identical workflow — confirms the artifact and workflow config are sound.
- Re-running **only** the failed deploy job (without rebuild) also fails — consistent with transient Pages API rejection or in-flight deployment lock.
- Workflow uses `concurrency: cancel-in-progress: false`, so overlapping page deploys from rapid pushes are not cancelled and may contend for the Pages deployment slot.

**Risk level:** Medium — site stays on last good deploy, but failed deployment badge and missed auto-publish on push until manual dispatch.

## TDD Fix Plan

1. **RED:** Push-triggered docs-site run can fail at deploy-pages with "try again later" while build is green (observed on run 28795963238).
   **GREEN:** Add up to 3 deploy attempts with 45s backoff in the deploy job; fail only if all attempts fail.
   **verify:** `grep -q 'deploy_attempt_2' .github/workflows/docs-site.yml`

2. **RED:** Concurrent page deploys from rapid main pushes can contend (concurrency group `pages`, cancel-in-progress false).
   **GREEN:** Set `cancel-in-progress: true` so newer deploy supersedes in-flight deploy.
   **verify:** `grep -A2 'group: pages' .github/workflows/docs-site.yml | grep 'cancel-in-progress: true'`

3. **RED:** No automated guard for deploy retry wiring.
   **GREEN:** Add doctrine check or comment in workflow documenting retry contract.
   **verify:** `bash scripts/validate-doctrine.sh 2>&1 | grep -q 'ALL checks passed'`

**REFACTOR:** None.

## Acceptance Criteria

- [ ] docs-site workflow deploy job retries on transient Pages API failure
- [ ] `workflow_dispatch` and push-triggered runs both green on fix branch
- [ ] Live site at https://danielvm-git.github.io/bigpowers/ returns 200
- [ ] Existing tests still pass

## Resolution

**Fixed** in PR #56 — merged to `main` as `f124ff0`.

- Root cause: transient GitHub Pages API rejection after successful build (run 28795963238); not a site build defect.
- Fix: 3-attempt deploy with 45s backoff; `cancel-in-progress: true` on pages concurrency group.
- Verify: post-merge run [28796637544](https://github.com/danielvm-git/bigpowers/actions/runs/28796637544) — build + deploy green on attempt 1.
- Site: https://danielvm-git.github.io/bigpowers/ returns 200.
