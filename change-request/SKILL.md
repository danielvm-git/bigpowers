---
name: change-request
description: Add a new requirement or reorder epics by WSJF value engineering against specs/RELEASE-PLAN.md. Two modes: Add (intake a new requirement mid-flight) and Reorder (re-score and re-sort all epics/stories). Use when a new requirement arrives mid-release, or when the plan needs prioritization.
---

# Change Request

> **HARD GATE** — `specs/RELEASE-PLAN.md` must exist before running either mode. If it doesn't, run `plan-release` first.
>
> → verify: `[ -f specs/RELEASE-PLAN.md ] && echo "ready" || echo "BLOCKED: run plan-release first"`

Two modes. State which one you want or the skill will ask.

## Mode A — Add

Intake a new requirement mid-flight without disrupting work in progress.

1. **Capture**: What is the change? What problem does it solve?
2. **Locate**: Which existing stories does it affect or replace?
3. **Draft**: Write the new story in RELEASE-PLAN.md format (with Gherkin AC and tasks + verify commands).
4. **Place**: Append as a new story under an existing epic, or open a new epic if needed.
5. **Score**: Compute WSJF score for the new story; note if it outranks in-progress work.

→ verify: `grep -c "Story" specs/RELEASE-PLAN.md`

## Mode B — Reorder

Value-engineering pass over the full release plan using WSJF.

See [REFERENCE.md](REFERENCE.md) for the full WSJF scoring rubric.

1. **Score** each epic/story: Business Value (1–10) + Time Criticality (1–10) + Risk Reduction (1–10) / Job Size (1–10).
2. **Re-sort** epics and stories by WSJF score descending.
3. **Flag cut candidates**: stories where Effort is L and Value is Low (WSJF < 1.5).
4. **Update** `specs/RELEASE-PLAN.md` — add WSJF scores, new order, short rationale for any reordering.
5. **Report** the delta: what moved up, what moved down, what is a cut candidate.

→ verify: `grep -c "WSJF:" specs/RELEASE-PLAN.md`

## After either mode

Suggest `plan-work` for the top-ranked unstarted story.
