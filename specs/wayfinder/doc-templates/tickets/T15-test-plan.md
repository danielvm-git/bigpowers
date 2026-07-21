<!-- wayfinder:grilling -->
# T15 — test-plan

**Type:** Grilling (HITL) · **Status:** CLOSED · **Claim:** driver
**Blocks:** the test-plan slot in the survivor set · **Blocked by:** T1 (doctrine, closed), T5
(exemplar-adr, closed — provides the pattern applied here)

## Question

Does `eNN-TEST_PLAN_LATEST.md` (`plan-tests` skill) need a template, and does it collide with
anything?

## Resolution

**No collision — checked and confirmed clean, straightforward application of T5's pattern.**
No TGDP candidate exists (none of the original 26 folders was test-plan-related). No bigspec
conflict (its B5 risk-tiered verification principle aligns with, doesn't contradict, what
`plan-tests` already does). No public-facing companion warranted — unlike T13's architecture
page, a per-epic P0-P3 risk matrix with SC-IDs isn't reader content a site visitor wants by
default.

Verified against a real live file (`e37-TEST_PLAN_LATEST.md`, 103 lines): Risk Matrix & Scenarios,
Test Level Strategy, Per-story verify matrix, **Known verification gaps** (an "honest gaps"
section — states where a verify is a proxy, not full proof, rather than hiding it), Manual UAT
steps, Hard gates. Per-epic (one file per `eNN`), same numbering pattern as ADR's per-decision
files.

**SC-ID format is load-bearing, untouched:** `SC-eNNsYY-P{0|1|2|3}-NN`, referenced in test files
as `// scenario:` comments alongside `// story:` tags (CONVENTIONS.md). `gate-trace` treats a P0
scenario with zero SC refs as a CONCERNS finding — this convention drives an existing gate and
was preserved exactly, not touched.

**Artifact:** [`templates/test-plan.md`](../templates/test-plan.md) — OKF envelope wrapping the
existing body structure verbatim, per T5's established pattern.