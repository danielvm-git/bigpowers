---
name: slice-tasks
description: Break a plan or PRD into vertical-slice stories in specs/epics/ (replaces legacy TASKS.md). Use after scope-work or plan-release, before plan-work.
model: sonnet
---

# Slice Tasks

Produce **epic shard stories** in `specs/epics/eNN-*.yaml` — vertical slices, each independently deliverable and testable. Legacy `specs/epics/ (see slice-tasks)` is deprecated; use epics + `execution-status.yaml`.

## Process

1. Read `specs/requirements/SCOPE_LATEST.yaml` and/or `specs/release-plan.yaml`.
2. Cut **tracer-bullet slices** (thin end-to-end paths first, then depth).
3. Each story: `id` (e.g. `e03s01`), `title`, optional `depends-on` in task desc, `tasks[]` with `desc` + `verify`.
4. Order by WSJF in `release-plan.yaml` epic list.

> **HARD GATE** — No horizontal-only slices ("add all models") without a vertical path that proves integration.

## Verify

→ verify: `grep -c 'id: e' specs/epics/*.yaml | awk '{if($1>0) print "OK"; else print "MISSING"}'`
