---
description: "PLANNING SPINE STEP 2 of 3 — Slice the work: break a scoped PRD into vertical-slice stories in specs/epics/. Use after scope-work (step 1), before plan-work (step 3). Not a substitute for scope-work or plan-work."model: sonnet
---


# Slice Tasks

> **Spine position:** Step 2 — scope-work → slice-tasks → plan-work.

Produce **epic capsule story tasks** in `specs/epics/eNN-slug/` — vertical slices, each independently deliverable and testable. Output: decoupled `eNNsYY-tasks.yaml` files with runnable verify commands. Legacy `specs/epics/ (see slice-tasks)` is deprecated; use capsule dirs + `execution-status.yaml`.

## Process

1. Read `specs/product/SCOPE_LATEST.yaml` and/or `specs/release-plan.yaml`.
2. Cut **tracer-bullet slices** (thin end-to-end paths first, then depth).
3. Each story: writes `eNNsYY-tasks.yaml` with `story_id`, `title`, `status`, `bcps`, `tasks[]` (each with `id`, `description`, `verify`, `status`). Story spec `.md` files are written by `plan-work` and follow [countable-story-format.md](file:///Users/danielvm/Developer/bigpowers/countable-story-format.md).
4. Order by WSJF in `release-plan.yaml` epic list.

> **HARD GATE** — No horizontal-only slices ("add all models") without a vertical path that proves integration.

## Verify

→ verify: `find specs/epics -name "*-tasks.yaml" | wc -l | awk '{if($1>0) print "OK: "$1" task files"; else print "MISSING"}'`
