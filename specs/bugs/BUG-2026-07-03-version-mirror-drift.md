---
bug_id: BUG-2026-07-03-version-mirror-drift
status: fixed
severity: medium
scope: release-pipeline
title: "Version mirrors in state.yaml and release-plan.yaml drift after every semantic-release"
---

## Root Cause

`specs/state.yaml` (`bigpowers_version`) and `specs/release-plan.yaml` (`release.version`) are manual mirrors that must be hand-updated after each release. They are not part of the semantic-release pipeline, so they go stale immediately.

Additionally, `.gemini/extensions/bigpowers/gemini-extension.json` and `.pi/package.json` carry version numbers derived from `package.json` via `sync-skills.sh` — but `sync-skills.sh` only runs during development, not during the release workflow. So the versions committed by `@semantic-release/git` are stale.

All impacted files:
| File | Field | How it drifts |
|------|-------|---------------|
| `specs/state.yaml` | `bigpowers_version` | Manual — never bumps |
| `specs/release-plan.yaml` | `release.version` | Manual — never bumps |
| `.gemini/extensions/bigpowers/gemini-extension.json` | `version` | Sync-skills runs during dev only |
| `.pi/package.json` | `version` | Sync-skills runs during dev only |

## Fix Approach

Add a `@semantic-release/exec` prepare hook that runs after `@semantic-release/npm` bumps `package.json` but before `@semantic-release/git` commits:

1. Create `scripts/sync-version-mirrors.sh` — bumps YAML fields + runs `sync-skills.sh`
2. Install `@semantic-release/exec` as devDependency
3. Insert exec plugin into `.releaserc` before `@semantic-release/git`
4. Add generated artifacts to git assets list

## Verify Steps

- [ ] `test -f scripts/sync-version-mirrors.sh && echo OK`
- [ ] `bash scripts/sync-version-mirrors.sh 9.9.9-test && grep -q '9.9.9-test' specs/state.yaml && echo OK` then revert
- [ ] `grep -q '@semantic-release/exec' package.json && echo OK`
- [ ] `grep -q 'sync-version-mirrors' .releaserc && echo OK`
- [ ] `npm run compliance && echo OK`
- [ ] `bash scripts/trace-stories.sh --strict && echo OK`
