---
bug_id: BUG-2026-08-31-npm-token-invalid-release
status: fixed
severity: high
scope: ci / release
title: "Release workflow fails EINVALIDNPMTOKEN — npm publish credential expired, v2.87.6 never published"
---

# BUG-2026-08-31: Release workflow fails EINVALIDNPMTOKEN

## Problem

- **Actual**: The `Release` workflow (publish.yml) on push of `f866adca` (PR #114 squash-merge, 2026-08-31) fails at the `Release` step: `@semantic-release/npm` `verifyConditions` → `npm whoami` → `401 Unauthorized`, terminal error `EINVALIDNPMTOKEN Invalid npm token.` ([run 33461454695](https://github.com/danielvm-git/bigpowers/actions/runs/33461454695)). No version was cut: v2.87.6 (containing PR #114 / issue #112's fix) was never published to npm or GitHub Releases.
- **Expected**: semantic-release verifies conditions and publishes the patch release for `fix(install): …` commits, as it did for v2.87.3–v2.87.5.
- **Reproduce**: `gh run rerun 33461454695 --failed` (or push any `fix:`/`feat:` commit to main) → `release` job fails at `verifyConditions` with EINVALIDNPMTOKEN.

**Security impact: NONE** — authentication is *too strict*, not bypassed; nothing published, nothing exposed. The invalid token reveals no privileges.

## Root Cause Analysis

### Reproduce

Run log (release job, 2026-09-01T02:10:29Z):

```
[@semantic-release/npm] › ℹ  Verify authentication for registry https://registry.npmjs.org/
npm error code E401
npm error 401 Unauthorized - GET https://registry.npmjs.org/-/whoami
[semantic-release] › ✘  EINVALIDNPMTOKEN Invalid npm token.
```

### Isolate

- The failure is at `verifyConditions` — **before** analyze/prepare/publish. No repo code is involved: the same commit's `skill-health` job passed, the `Compliance gate` step inside the same `release` job passed, and the only failing plugin call is the npm `whoami` probe using the `NPM_TOKEN` secret.
- Last successful release run: `79bc7040` (v2.87.5 era). The `NPM_TOKEN` GitHub secret became invalid between then and 2026-08-31 (expired, revoked, or rotated on npmjs.com without updating the secret).
- Not a regression of PR #114/#115: neither touches `.releaserc.json`, `publish.yml`, or npm config.

### Hypothesize

The `NPM_TOKEN` secret value in repo settings no longer authenticates against registry.npmjs.org. Replacing it with a fresh valid token (Automation type, or Granular with publish rights on `bigpowers`) restores the release path unchanged.

### Verify

After rotating the secret: `gh run rerun 33461454695 --failed` → `release` job green → `chore(release): 2.87.6 [skip ci]` commit, npm dist-tag `latest` = 2.87.6.

**Contributing factors**: (1) npm tokens expire silently — no CI signal until the next release attempt; (2) releases are the only consumer of this secret, so staleness went unnoticed between 2026-08-07 and 2026-08-31.

**Risk level**: High — all fixes merged after 2026-08-31 remain unpublished until the token is rotated; consumers on `npm:bigpowers` cannot receive them.

## TDD Fix Plan

Not a code defect — no RED/GREEN cycle applies. Remediation is operational:

1. **Maintainer**: create a fresh npm token (npmjs.com → Access Tokens → **Automation**, or Granular with packages: read-write on `bigpowers`; account 2FA must permit automation publishes — "Authorization only" level per the semantic-release error guidance).
2. **Maintainer**: update the `NPM_TOKEN` secret in repo Settings → Secrets and variables → Actions.
3. **Agent**: `gh run rerun 33461454695 --failed` and confirm v2.87.6 publishes; then proceed with the queued PR #115 merge.

## Acceptance Criteria

- [ ] `release` job green on the rerun of run 33461454695
- [ ] `chore(release): 2.87.6 [skip ci]` lands on main; `npm view bigpowers version` → 2.87.6
- [ ] Queued merges (PR #115, fix/pi-scripts-provisioning) release normally afterwards

## Resolution

**Fixed:** 2026-08-31 — NPM_TOKEN secret rotated by the maintainer; failed run rerun green; **v2.87.6 published** (commit `f4dd6dac`, tag `v2.87.6`, `npm view bigpowers version` → 2.87.6, GitHub Release "Latest"). No code change required — root cause confirmed as the expired npm token. Subsequent release (v2.87.7 for PR #115) published normally, proving the fix holds.
