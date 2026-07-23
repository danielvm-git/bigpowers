---
bug_id: BUG-2026-07-23-epics-wiki-empty-references
status: fixed
severity: high
scope: ci
title: "generate-epics-wiki.sh emits an invalid OKF bundle (empty references[]) for epics with zero sliced stories"
security_impact: NONE
risk_level: low
commit_message: "fix(scripts): skip epics-wiki generation for epics with zero stories"
---

# BUG-2026-07-23: generate-epics-wiki.sh emits invalid bundles for unsliced epics

## Problem

**Actual:** CI (`Sync Skills on Push` and `Publish to Wiki` workflows) fails at
"Validate OKF bundles" / "Validate OKF" with:

```
FAIL e55.okf.md: references[] is empty or missing
FAIL e56.okf.md: references[] is empty or missing
FAIL e57.okf.md: references[] is empty or missing
FAIL e58.okf.md: references[] is empty or missing
FAIL e59.okf.md: references[] is empty or missing
```

This surfaced when `specs/epics-wiki/e54.okf.md` through `e59.okf.md` were committed
for the first time (via `scripts/sync-skills.sh`, during e53s01's build cycle) — these
5 epics were scoped via `elaborate-spec` (each has `epic.yaml` + `planning-context.yaml`)
but not yet sliced into stories via `plan-work`, so they have zero entries in
`epic.yaml`'s `stories:` list. `e54` (already plan-worked-to-build-ready, with 3 full
story files) passed cleanly; `e55`-`e59` did not.

**Expected:** `sync-skills.sh` should not emit an OKF bundle that structurally cannot
satisfy `scripts/lib/validate-okf-kinds.sh`'s hard requirement (`references[]` must be
non-empty — confirmed in `validate-okf-kinds.sh:154`, no `references: []` exemption
exists) for an epic that has no stories yet.

**Reproduce:**

```bash
bash scripts/sync-skills.sh
bash scripts/validate-okf.sh --dir specs/epics-wiki
# → FAIL e55.okf.md / e56.okf.md / e57.okf.md / e58.okf.md / e59.okf.md:
#   references[] is empty or missing
```

**Security impact:** NONE — CI validation logic only.

## Root Cause Analysis

`scripts/generate-epics-wiki.sh` builds each epic's `references:` frontmatter list
purely from `epic.yaml`'s `stories:` array (`grep '^\s*- id:' "$epic_yaml"`). For an
epic with zero stories (scoped but not yet sliced), this produces an empty list, and
the template still emits a bare `references:` key with nothing under it — invalid per
`validate-okf-kinds.sh`'s hard requirement that every concept bundle have at least one
reference. `references: []` (an explicit empty array) would not pass either — the
validator counts list length, and 0 always fails regardless of syntax. There is no
valid `references:` value that would satisfy the check for a genuinely story-less
epic, so the bundle should not be generated at all until the epic has stories.

## Fix

`scripts/generate-epics-wiki.sh`: skip bundle generation for any epic whose
`story_count` is 0 (`[[ "$story_count" -eq 0 ]] && continue`), matching how a
not-yet-sliced epic has no meaningful OKF concept bundle to publish yet. Also removes
the 5 already-committed invalid stubs (`specs/epics-wiki/e55-e59.okf.md`).

## Verify

```bash
bash scripts/sync-skills.sh
ls specs/epics-wiki/e55.okf.md specs/epics-wiki/e56.okf.md 2>&1
# → No such file or directory (correctly skipped, zero stories)

bash scripts/validate-okf.sh --dir specs/epics-wiki
# → all PASS, no references[] failures
```
