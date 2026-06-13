---
name: scope-work
description: "PLANNING SPINE STEP 1 of 3 — Scope the work: define what is in and out of scope and save as specs/product/SCOPE_LATEST.yaml. Use before slice-tasks or plan-release on any new initiative. Not a substitute for slice-tasks (step 2) or plan-work (step 3)."
model: sonnet
---

# Scope Work

> **Spine position:** Step 1 — scope-work → slice-tasks → plan-work.

Turn the current conversation into a bounded PRD at `specs/product/SCOPE_LATEST.yaml`.

## Process

1. Read existing `specs/` artifacts (`release-plan.yaml`, `plans/TECH_STACK_LATEST.md`, `requirements/VISION_LATEST.yaml` if any).
2. Interview (if needed): goal, users, in-scope, out-of-scope, constraints, success metrics.
3. Write `specs/product/SCOPE_LATEST.yaml` with: `core_value`, `summary`, `in_scope[]`, `out_of_scope[]`, `constraints`, `success_criteria`, `references`.
4. Run `research-first` if external dependencies are proposed.

> **HARD GATE** — Every `in_scope` item must map to a future epic/story ID or explicit deferred note in `out_of_scope`.

## Verify

→ verify: `test -f specs/product/SCOPE_LATEST.yaml && grep -c 'out_of_scope' specs/product/SCOPE_LATEST.yaml | awk '{if($1>0) print "OK"; else print "MISSING"}'`
