---
name: scope-work
description: "\"PLANNING SPINE STEP 1 of 3 — Scope the work: define what is in and out of scope and save as specs/product/SCOPE_LATEST.yaml. Use before slice-tasks or plan-release on any new initiative. Not a substitute for slice-tasks (step 2) or plan-work (step 3).\""
model: sonnet
---


# Scope Work

> **Spine position:** Step 1 — scope-work → slice-tasks → plan-work.

Turn the current conversation into a bounded PRD at `specs/product/SCOPE_LATEST.yaml`. Without a scope boundary, implementation drifts — stories expand, estimates blow up, and "done" becomes undefined.

## Pre-flight

- [ ] Do you have a clear user need or problem statement? If not, run `elaborate-spec` first.
- [ ] Does `specs/product/VISION_LATEST.yaml` exist? If yes, read it for north-star alignment.
- [ ] Is there an existing `SCOPE_LATEST.yaml`? If yes, you're refining, not creating from scratch.

## Process

1. **Gather context** — Read existing `specs/` artifacts (`release-plan.yaml`, `plans/TECH_STACK_LATEST.md`, `requirements/VISION_LATEST.yaml` if any). Understand what the project is building and why.

2. **Interview (if needed)** — Clarify: What is the goal? Who are the users? What is definitely in scope? What is explicitly out of scope? What constraints exist (time, budget, tech)? How will success be measured?

3. **Write `specs/product/SCOPE_LATEST.yaml`** with these fields:
   - `core_value` — one-sentence value proposition
   - `summary` — 2-3 paragraph scope overview
   - `in_scope[]` — list of what this initiative covers (each maps to an epic/story)
   - `out_of_scope[]` — explicit exclusions (prevents scope creep)
   - `constraints` — tech, time, resource boundaries
   - `success_criteria` — observable outcomes that prove the scope is delivered
   - `references` — links to related specs, ADRs, or documents

4. **Lightweight trade-off analysis** — For each `out_of_scope` item, note *why* it's excluded (deferred, not valuable, too risky, depends on external factor). This protects against "what about X?" questions later.

5. **Run `research-first`** if external dependencies are proposed — verify the dependency exists, is maintained, and fits the scope before committing to it.

> **HARD GATE** — Every `in_scope` item must map to a future epic/story ID or explicit deferred note in `out_of_scope`. If an item can't be mapped, the scope is too vague — refine before proceeding.

> **HARD GATE** — Do NOT include implementation details in SCOPE_LATEST.yaml. Scope is *what* and *why*, not *how*. Implementation detail belongs in epic capsules and slice-tasks.

## Common Anti-Patterns

- **"Everything is in scope"** — If nothing is out of scope, you haven't defined a scope. You've described a universe. Cut aggressively.
- **"We'll figure it out later"** — Ambiguity in scope propagates to every downstream decision. Resolve now or explicitly defer in writing.
- **Scope as architecture** — Saying "we need a PostgreSQL database" is architecture, not scope. Scope says "we need to store user profiles and transaction history."

## Output

`specs/product/SCOPE_LATEST.yaml` — the bounded PRD. Subsequent skills (`slice-tasks`, `plan-work`) reference this as the source of truth for what to build.

## Verify

→ verify: `test -f specs/product/SCOPE_LATEST.yaml && grep -c 'out_of_scope' specs/product/SCOPE_LATEST.yaml | awk '{if($1>0) print "OK"; else print "MISSING"}'`
