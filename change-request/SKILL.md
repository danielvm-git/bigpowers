---
name: change-request
model: sonnet
description: Add a new requirement or reorder epics by WSJF against specs/release-plan.yaml and epic shards. Modes Add and Reorder. Use when a new requirement arrives mid-release or the plan needs prioritization.
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
4. **Place**: Append story under existing epic shard, or create `specs/epics/eNN-slug.yaml` and register in `release-plan.yaml` `epics[]`.
5. **Score**: Compute WSJF; note if it outranks in-progress work.

→ verify: `grep -c 'stories:' specs/epics/*.yaml`

## Mode B — Reorder

Value-engineering pass over the full release using WSJF.

See [REFERENCE.md](REFERENCE.md) for the full WSJF scoring rubric.

1. **Score** each epic/story: BV + TC + RR / Job Size.
2. **Re-sort** `release-plan.yaml` `epics[]` and per-epic `wsjf` fields.
3. **Flag cut candidates**: WSJF < 1.5.
4. **Update** `specs/release-plan.yaml` and epic `wsjf` keys with rationale.
5. **Report** the delta.

→ verify: `grep -c 'wsjf' specs/release-plan.yaml specs/epics/*.yaml`

## After either mode

Run `bash scripts/sync-status-from-epics.sh`. Suggest `plan-work` or `build-epic` for the top-ranked unstarted story.
