<!-- wayfinder resolution artifact — T22 (design-and-spike), closed -->
<!-- Per-target, like ADR/IMPACT/TEST_PLAN — one file per spike question, not a _LATEST
     singleton (already the live naming convention: SPIKE-<name>.md). -->
<!-- FLEXIBLE BY DESIGN, not rigid — the skill's own framing resists heavy process for
     deliberately throwaway work. Checked real live spikes: most follow the shape below
     (narrow technical question), but at least one (SPIKE-frameworks.md, a full comparison
     matrix against 6 external references) took a broader form the exploration warranted. Don't
     force every spike into the narrow shape if the question genuinely needs more room. -->
<!-- Narrative-OKF (T5's pattern). A spike with no question is unplanned coding — refuse to
     start without one, per the skill's own hard rule. -->

---
okf_kind: spike
okf_version: "1.0"
generated_by: "skill:spike-prototype"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
timebox: {e.g. "1 hour"}
---

# Spike: {name}

## Question

{The specific question this spike was answering. Pattern: "Can we [thing] using [approach]
within [constraint]?" — no question, no spike.}

## Result

{Answered | Partially answered | Not answered}

## Findings

{What you learned — concrete observations, not opinions.}

## Evidence

{Code snippet, benchmark result, API response, or screenshot that proves the finding. The code
itself is thrown away; this is what's kept.}

## Implications for the plan

{How this changes the approach, the design, or the estimate.}

## What was NOT explored

{Scope the spike deliberately left out — as important as what it covered.}
