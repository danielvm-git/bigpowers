---
bug_id: BUG-2026-07-04-tautological-verify
status: fixed
severity: medium
scope: skills
title: "Tautological verify commands in 5 non-critical skills — file-existence checks pass vacuously"
---

## Problem

5 skills have verify commands that only test file existence rather than behavior:

| Skill | Verify command | Why tautological |
|-------|----------------|-----------------|
| `publish-package` | `test -f skills/publish-package/SKILL.md` | sync-skills.sh already validates SKILL.md exists |
| `publish-package` | `grep -q "name: publish-package" skills/publish-package/SKILL.md` | sync-skills.sh already validates frontmatter |
| `wire-ci` | `test -f skills/wire-ci/SKILL.md` | sync-skills.sh already validates SKILL.md exists |
| `wire-ci` | `grep -q "name: wire-ci" skills/wire-ci/SKILL.md` | sync-skills.sh already validates frontmatter |
| `run-benchmark` | `test -f skills/run-benchmark/SKILL.md && grep -q 'pass_at_k\|pass.at.k'` | Own-file content check, not behavioral |
| `gate-trace` | `test -f skills/gate-trace/SKILL.md && grep -q 'PASS.*CONCERNS.*FAIL.*WAIVED'` | Own-file content check, not behavioral |
| `visual-dashboard` | `test -f skills/visual-dashboard/scripts/...` | Own-script file existence, not behavioral |

### Expected behavior

- Critical-path skills (build-epic, verify-work, audit-code, release-branch) have behavioral verify commands — they already do.
- Other skills: tautological checks are removed entirely. sync-skills.sh already validates SKILL.md existence and frontmatter globally.

### How to reproduce

```bash
grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md | grep -v ':0$' | wc -l
```

## Root Cause Analysis

The verify sections in SKILL.md files were written early in the bigpowers project lifecycle, before `sync-skills.sh` existed as a global validation layer. The intent was to prove the skill was "configured correctly" but the checks only validate what `sync-skills.sh` already validates — and do so per-skill, adding noise without signal.

**Code path**: Each of the 5 affected skills has a `## Verify` section (or inline verify command) containing one or more file-existence checks.

**Why current code fails**: A verify command like `test -f skills/publish-package/SKILL.md` passes even if the skill's instructions produce garbage output. It tests that a file tree exists, not that the skill works.

**Contributing factors**: No standard was documented for what makes a good verify command. The "test -f" pattern was cargo-culted.

**Risk level**: Low (quality signal, not functional)

## TDD Fix Plan

This is a data-cleanup fix with no logic change. No RED-GREEN cycles needed.

1. **GREEN**: Remove tautological verify commands from `publish-package`, `wire-ci`, `run-benchmark`, `gate-trace`, and `visual-dashboard` SKILL.md files.
   **verify**: `grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md | grep -v ':0$' | wc -l | awk '{if($1==0) print "OK"; else print "REMAINING: "$1}'`

## Acceptance Criteria

- [ ] 7 tautological verify commands removed from 5 SKILL.md files
- [ ] Critical-path skill verify commands unchanged
- [x] Compliance still passes (88/88, 100%)
- [x] Golden suite still passes (7/8, G-11 pre-existing)

## Resolution

**Fixed**: Removed 7 tautological verify commands from 5 SKILL.md files:
- `publish-package`: removed 2 (file existence + frontmatter), kept semantic + index checks
- `wire-ci`: removed 2 (file existence + frontmatter), kept semantic + index checks
- `run-benchmark`: removed whole verify section (self-referential)
- `gate-trace`: removed whole verify section (self-referential)
- `visual-dashboard`: removed inline verify (own-script file existence)

Critical-path skills (build-epic, verify-work, audit-code, release-branch) verified unchanged.

**verify**: `bash scripts/run-golden-suite.sh && grep -c 'test -f.*SKILL.md.*grep.*name:' skills/*/SKILL.md | grep -v ':0$' | wc -l | awk '{if($1==0) print "OK"; else print "REMAINING: "$1}'` → OK
