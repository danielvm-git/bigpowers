---
bug_id: BUG-2026-07-23-completeness-critic-code-tags-schema-drift
status: fixed
severity: high
scope: ci
title: "completeness-critic.sh checks a .code_tags field that no longer exists in traceability-matrix.json, and scans the whole repo instead of the story being verified"
security_impact: NONE
risk_level: low
commit_message: "fix(scripts): repair completeness-critic's story-tag check (schema drift + repo-wide scope)"
---

# BUG-2026-07-23: completeness-critic's zero-code-tags BLOCKER is structurally broken

## Problem

**Actual:** `bash scripts/lib/completeness-critic.sh` (verify-work step 5a2) reports a
BLOCKER — `"N active story(ies) with zero code tags"` — that fires for every story in
the entire repository that isn't `status: "done"`, unconditionally aborting the merge
gate. This tripped during e53s01's verify-work even though e53s01 was fully built and
tagged, first because of unrelated stories in a different epic (e54, not yet started),
and — after scoping to the active epic — because of e53s01's own not-yet-built sibling
stories (e53s02-04), since `build-epic` builds and verifies one story at a time.

**Expected:** The check should fire only when the story actually being verified lacks
implementing evidence — not for every not-yet-started story elsewhere in the backlog,
including its own future siblings.

**Reproduce (schema drift):**

```bash
jq '.stories.e53s01 // (.stories[] | select(.id=="e53s01"))' specs/traceability-matrix.json
# → no ".code_tags" key anywhere in the object; the real field is "link_count" /
#   "links[].method" (one of which is "explicit_tag" for a real `# story:` comment)

grep -rn "code_tags" scripts/ --include="*.sh" --include="*.py"
# → only hit: scripts/lib/completeness-critic.sh:31 — the field it checks was never
#   emitted by scripts/lib/trace-stories.py, which writes specs/traceability-matrix.json
```

**Reproduce (repo-wide scope):**

```bash
jq '[.stories[]? | select(.status != "done" and (.code_tags // 0) == 0)] | map(.id)' \
  specs/traceability-matrix.json
# → ["e53s01","e53s02","e53s03","e53s04"]  (before this fix — e53s01 already had a
#   real tag via state.yaml's `active_story: e53s01`, but the missing field always
#   evaluates to 0, so status alone determined the result)
```

**Security impact:** NONE — CI/merge-gate logic only, no data or credential exposure.

## Root Cause Analysis

1. **Schema drift:** `completeness-critic.sh` was written against an earlier or assumed
   `traceability-matrix.json` shape with a `code_tags` count per story.
   `scripts/lib/trace-stories.py` (the actual generator) instead emits `links[]` — a
   list of `{file, line, confidence, method}`, where `method` is `explicit_tag`
   (a real `story: eNNsNN` comment/tag), `file_heuristic`, or `task_reference`. Since
   `code_tags` never exists, `.code_tags // 0` always evaluates to `0`, so the check
   degenerates to "is `status != done`" — true for every backlog/todo/in-progress
   story, regardless of whether it's actually tagged.
2. **Wrong scope — whole repo, then whole epic:** even after fixing the field lookup,
   the `jq` query scans `.stories[]` across the **entire** matrix — every epic. A
   first fix attempt scoped it to `active_epic` from `specs/state.yaml`, which still
   left every not-yet-built sibling story in the same epic (e53s02-04) permanently
   blocking e53s01's own verify-work, because `build-epic` verifies one story at a
   time (`active_story`), not a whole epic at once. The check must scope to the
   single story `verify-work` is currently gating — `active_story`, not `active_epic`
   and not the whole backlog.

## Fix

`scripts/lib/completeness-critic.sh`:

1. Replace the `.code_tags // 0` lookup with a check for zero `explicit_tag`-method
   links: `((.links // []) | map(select(.method == "explicit_tag")) | length) == 0`.
2. Scope the check to the single story being verified: read `active_story` from
   `specs/state.yaml`, and filter to `.id == "$ACTIVE_STORY"` before applying the
   zero-tag check — matching how `build-epic`/`verify-work` already scope every other
   per-story action.

## Verify

```bash
ACTIVE_STORY="$(grep '^active_story:' specs/state.yaml | awk '{print $2}')"
jq --arg s "$ACTIVE_STORY" \
  '[.stories[]? | select(.id == $s and .status != "done" and ((.links // []) | map(select(.method == "explicit_tag")) | length) == 0)] | map(.id)' \
  specs/traceability-matrix.json
# → [] once the active story has a real tag — no longer polluted by siblings or
#   other epics

bash scripts/lib/completeness-critic.sh
# → BLOCKER=0 for e53s01 (tagged via e53s01-tasks.yaml's new `# story: e53s01`
#   header); e53s02-04 and other epics no longer evaluated at all until it's their
#   own turn to be the active story.
```
