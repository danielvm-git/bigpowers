<!-- wayfinder resolution artifact — T20 (impact-refactor-traceability), closed -->
<!-- Single evolving document (unlike IMPACT) — no per-target siblings found in the live repo,
     confirmed only one REFACTOR_LATEST.md exists. `_LATEST` dropped per standing doctrine
     (git + location is current); refined in place like scope.md, not versioned per-instance. -->
<!-- Narrative-OKF (T5's pattern). Interview-driven authorship (plan-refactor's own Steps 1-4
     are an explicit user interview) — human-collaborative, not machine-derived. -->

---
okf_kind: refactor
okf_version: "1.0"
generated_by: "skill:plan-refactor"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
---

# Refactor Plan — {Title}

**Author:** {name}
**Date:** {YYYY-MM-DD}
**Status:** {Draft | In progress | Complete}

## Problem Statement

{The problem, from the developer's perspective — what's wrong with the current state and why
it matters. Document current behavior before proposing to change it; extract the one invariant
that must be preserved.}

## Solution

{The solution, from the developer's perspective. What changes, what deliberately doesn't.}

## Commits

{A long, detailed plan broken into the tiniest safe commits possible — "make each refactoring
step as small as possible, so you can always see the program working" (Fowler). Each commit
leaves the codebase in a working state.}

1. {commit description} → verify: `{runnable command}`
2. {commit description} → verify: `{runnable command}`
