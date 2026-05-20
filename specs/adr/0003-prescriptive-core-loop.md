# ADR-0003: Prescriptive Core Loop with Fast-Track Mode

**Status:** Accepted
**Date:** 2026-05-20

## Context

Without an enforced sequence, users skip validation gates (no `grill-me`, no `audit-code`) and
ship with untested assumptions. Free-form skill selection puts the orchestration burden entirely on
the user. GSD's fully prescriptive loop (no skips) is too rigid for brownfield projects.

## Decision

bigpowers enforces a prescriptive 6-phase core loop — discover → elaborate → plan → build →
verify → release — via `orchestrate-project`, with two opt-in modes:

- **Standard**: all gates enforced; no phase can be skipped without explicit confirmation.
- **Fast-track**: phases with measurable skip conditions (e.g., survey already done, coverage ≥ 95%) may be skipped with a logged rationale.
- **Ad-hoc**: legacy / experimental; no gate enforcement. User accepts full responsibility.

## Consequences

- Users can no longer silently skip `elaborate-spec` or `validate-fix`.
- Fast-track conditions are data-driven (file exists, metric threshold met) — not discretionary.
- Ad-hoc mode exists for experiments but is explicitly marked as lower-quality.
- Orchestration overhead: ~2% more tokens, ~15% more orchestrator complexity.
