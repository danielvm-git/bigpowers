---
bug_id: BUG-2026-07-06-craft-skill-sync-oversized
status: fixed
severity: medium
scope: skills/craft-skill
title: "craft-skill: Underlying compilation script sync-skills.sh exceeds line limits and contains duplicate helper function names"
---

# BUG-2026-07-06-craft-skill-sync-oversized

## Problem

**Actual behavior:** The underlying compilation and sync engine `scripts/sync-skills.sh` had grown to 707 lines, violating both the 300-line context window limit and the 500-line newspaper metaphor limit. It also shadowed `parse_frontmatter` from `skill-common.sh` and duplicated OKF post-sync logic already present in `okf-post-sync.sh`.

**Expected behavior:** Code compilation and rule synchronization should reside in small, modular scripts under 300 lines with unique function signatures.

## Root Cause Analysis

Procedural build and verification logic for the skills compiler was kept in a single monolithic script. OKF post-sync was inlined instead of delegating to `okf-post-sync.sh`; `okf-add-references.py` was referenced but never created. `parse_frontmatter` was redefined locally, shadowing the library version.

## TDD Fix Plan

1. **GREEN:** Extract render helpers to `scripts/lib/sync-render.sh`; post-sync to `scripts/lib/sync-post.sh`.
   **verify:** `wc -l scripts/sync-skills.sh | awk '{if($1<300) print "OK"; else print "FAIL: "$1}'`

2. **GREEN:** Wire `okf-post-sync.sh` and create `okf-add-references.py`; remove duplicate inline OKF block.
   **verify:** `bash scripts/sync-skills.sh --okf`

3. **GREEN:** Use `skill-common.sh` `parse_frontmatter` / `parse_frontmatter_okf` — no local shadow.
   **verify:** `bash scripts/sync-skills.sh`

## Acceptance Criteria

- [x] `sync-skills.sh` under 300 lines (109 after fix)
- [x] `sync-skills.sh` and `--okf` mode pass
- [x] Golden suite 9/9 PASS

## Resolution

**Fixed:** Split monolithic `sync-skills.sh` (707 → 109 lines) into `scripts/lib/sync-render.sh`, `scripts/lib/sync-post.sh`, and `scripts/okf-add-references.py`. Delegated OKF post-sync to existing `okf-post-sync.sh`. Moved `parse_frontmatter_okf` to `skill-common.sh`; removed shadowing local `parse_frontmatter`. Also resolves BUG-2026-07-06-evolve-skill-sync-oversized (same root script).
