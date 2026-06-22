---
name: change-request
description: "Add a new requirement or reorder epics by WSJF against specs/release-plan.yaml and epic capsule directories. Modes Add and Reorder. Use when a new requirement arrives mid-release or the plan needs prioritization."
model: sonnet
---


# Change Request

> **HARD GATE** — `specs/release-plan.yaml` must exist before running either mode. If it doesn't, run `plan-release` first.
>
> → verify: `[ -f specs/release-plan.yaml ] && echo "ready" || echo "BLOCKED: run plan-release first"`

Two modes. State which one you want or the skill will ask.

## Mode A — Add

Intake a new requirement mid-flight without disrupting work in progress.

1. **Capture**: What is the change? What problem does it solve?
2. **Locate**: Which existing stories in `specs/epics/` does it affect or replace?
3. **Draft**: Add story + `tasks[]` with Gherkin-style AC in epic YAML (each task has `verify`).
4. **Place**: Append story under existing epic capsule, or create `specs/epics/eNN-slug.yaml` and register in `release-plan.yaml` `epics[]`.
5. **Score**: Compute WSJF; note if it outranks in-progress work.

→ verify: `grep -c 'stories:' specs/epics/*/epic.yaml`

## Mode B — Reorder

Value-engineering pass over the full release using WSJF.

See [REFERENCE.md](REFERENCE.md) for the full WSJF scoring rubric.

1. **Score** each epic/story: BV + TC + RR / Job Size.
2. **Re-sort** `release-plan.yaml` `epics[]` and per-epic `wsjf` fields.
3. **Flag cut candidates**: WSJF < 1.5.
4. **Update** `specs/release-plan.yaml` and epic `wsjf` keys with rationale.
5. **Report** the delta.

→ verify: `grep -c 'wsjf' specs/release-plan.yaml specs/epics/*/epic.yaml`

## Conversational Mode

If the user's request is in natural language and does not match the structured format of Mode A or Mode B, enter Conversational Mode to extract the change parameters through interactive dialogue.

### 5-Step Flow

1. **Capture**: Parse the natural-language request for what, why, and where. Ask at most 3 clarifying questions before drafting.
2. **Locate**: Identify which epic or capability in `specs/epics/` the request affects or replaces.
3. **Draft**: Present a structured draft of the proposed story and tasks for user confirmation.
4. **Score**: Estimate the WSJF score and explain the calculation so the user understands the priority.
5. **Place**: Confirm the final epic placement with the user before writing files.

## After either mode

Run `bash scripts/sync-status-from-epics.sh`. Suggest `plan-work` or `build-epic` for the top-ranked unstarted story.

---

# WSJF Scoring Reference

Weighted Shortest Job First: **WSJF = (Business Value + Time Criticality + Risk Reduction) / Job Size**

All dimensions scored 1–10 using a Fibonacci-like scale: 1, 2, 3, 5, 8, 10.

## Business Value

| Score | Meaning |
|-------|---------|
| 10 | Core revenue path, legal requirement, blocking launch |
| 8  | Significant user value, major pain point removed |
| 5  | Notable improvement, medium user segment affected |
| 3  | Nice-to-have, minor convenience |
| 1  | Cosmetic or speculative |

## Time Criticality

| Score | Meaning |
|-------|---------|
| 10 | Hard deadline (regulatory, contract, launch date) |
| 8  | Competitive window closing, partner dependency |
| 5  | Would delay next milestone if deferred |
| 3  | Flexible, can slip one sprint |
| 1  | No urgency |

## Risk Reduction (or Opportunity Enablement)

| Score | Meaning |
|-------|---------|
| 10 | Eliminates critical architectural risk or enables a new capability |
| 8  | Reduces a known failure mode or unblocks high-value work |
| 5  | Moderate risk mitigation or enablement |
| 3  | Low risk reduction |
| 1  | No risk relevance |

## Job Size (effort denominator — larger = lower WSJF)

| Score | Meaning |
|-------|---------|
| 1  | Hours |
| 2  | 1 day |
| 3  | 2–3 days |
| 5  | 1 week |
| 8  | 2 weeks |
| 10 | 1 month+ |

## Cut threshold

Stories with WSJF < 1.5 are cut candidates: high effort, low combined value.

## Example

Story: "Add OAuth login"
- Business Value: 8 (removes major sign-up friction)
- Time Criticality: 5 (Q3 launch nice, not hard)
- Risk Reduction: 3 (minor security improvement)
- Job Size: 5 (one week)

WSJF = (8 + 5 + 3) / 5 = **3.2** — healthy, implement early.
