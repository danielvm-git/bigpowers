# BUG-2026-07-03T134500: Backlog capsule release: labels drifted from their release trains

## Problem

**Actual behavior:** e44, e43, and e39 epic capsules carry `release: v2.45.0 "Deepening"` while their release train is v2.7x/v3.0. This is the same drift class GAP-3 just fixed for e42 (which had `release: v2.8x` while its train is now v2.7x).

**Expected behavior:** Every epic capsule's `release:` field matches the release train it's slotted into in `specs/release-plan.yaml`.

**How to reproduce:**
1. `grep 'release:' specs/epics/e43-mcp-context-server/epic.yaml` → `v2.45.0`
2. `grep 'release:' specs/epics/e44-migrate-version/epic.yaml` → `v2.45.0`
3. `grep 'release:' specs/epics/e39-knowledge-graph/epic.yaml` → likely `v2.45.0`
4. Release train says v2.7x/v3.0 for all three

## Root Cause Analysis

The `release:` field in epic capsules was set when these epics were planned under the original "Deepening" release. When the release trains were reorganized (2026-07-03), the train list was updated but the individual capsule fields were not. This is a synchronization gap between the release-plan index and individual capsule metadata.

**Risk level:** LOW — the authoritative sequencing is `release_trains` in release-plan.yaml, not the capsule field. But stale metadata creates confusion for agents reading capsule files directly.

## TDD Fix Plan

### 1. Update e43 capsule
**GREEN:** Change `release: v2.45.0` to `release: v2.7x/v3.0` in `specs/epics/e43-mcp-context-server/epic.yaml`, add provenance comment.
**verify:** `grep -q 'v2.7x/v3.0' specs/epics/e43-mcp-context-server/epic.yaml && echo OK`

### 2. Update e44 capsule
**GREEN:** Change `release: v2.45.0` to `release: v2.7x/v3.0` in `specs/epics/e44-migrate-version/epic.yaml`, add provenance comment.
**verify:** `grep -q 'v2.7x/v3.0' specs/epics/e44-migrate-version/epic.yaml && echo OK`

### 3. Update e39 capsule
**GREEN:** Change `release: v2.80` to `release: v2.7x/v3.0` in `specs/epics/e39-knowledge-graph/epic.yaml` (if it exists with the stale label), add provenance comment.
**verify:** `grep -q 'v2.7x/v3.0' specs/epics/e39-knowledge-graph/epic.yaml && echo OK`

### 4. Audit remaining capsules
**GREEN:** Run `grep -r 'release: v2.45.0' specs/epics/*/epic.yaml` and verify only completed epics retain the label. Any active/backlog epics with v2.45.0 are drift candidates.
**verify:** Zero hits among non-archive, non-done epics.

## Acceptance Criteria

- [ ] e43 capsule `release:` → v2.7x/v3.0
- [ ] e44 capsule `release:` → v2.7x/v3.0
- [ ] e39 capsule `release:` → v2.7x/v3.0 (if stale)
- [ ] All other active/backlog capsules have correct release train labels
- [ ] Provenance comments explain the drift correction date

## Resolution

**Open** — registered 2026-07-03 from PLAN-AUDIT red-team gap list (P2 #8).
