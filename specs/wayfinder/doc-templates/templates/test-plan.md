<!-- wayfinder resolution artifact — T15 (test-plan), closed -->
<!-- No collision to resolve — checked, no TGDP candidate exists, no bigspec conflict, no
     public-facing companion warranted (a per-epic P0-P3 risk matrix isn't reader content).
     Straightforward application of T5's ADR pattern: OKF envelope + preserve the existing,
     already gate-dependent body structure verbatim. Per-epic, like ADR is per-decision — one
     file per eNN, sequential by epic. -->
<!-- SC-ID FORMAT IS LOAD-BEARING, DO NOT CHANGE: SC-eNNsYY-P{0|1|2|3}-NN, referenced in test
     files as `// scenario: SC-eNNsYY-P0-NN` alongside `// story: eNNsNN`. gate-trace treats a
     P0 story with zero SC-*-P0-* references as a CONCERNS finding. -->

---
okf_kind: test-plan
okf_version: "1.0"
generated_by: "skill:plan-tests"
generated_at: {YYYY-MM-DDTHH:MM:SSZ}
epic: {eNN}
---

# Test Design: {eNN} — {Epic Title}

Epic: {eNN-slug} | Risk owner: plan-tests | Date: {YYYY-MM-DD}

---

## 1. Risk Matrix & Scenarios

| Scenario ID | Behavior | Risk | Level | Target |
|-------------|----------|------|-------|--------|
| SC-{eNNsYY}-{P0-3}-{NN} | {observable behavior under test} | {P0-P3} | {Unit \| Integration \| E2E \| Manual UAT} | {file/script under test} |

**Traceability:** implementing scripts/tests MUST include `// scenario: SC-eNNsYY-Px-NN`
comments alongside `// story: eNNsNN` tags. `gate-trace` treats a P0 scenario with zero SC refs
as CONCERNS.

## 2. Test Level Strategy

{Which levels this epic actually uses and why — push tests to the lowest level that proves the
behavior. Name the default level for this project's stack.}

## 3. Notable dependencies or constraints

{Anything a scenario's implementation depends on that isn't obvious from the matrix — a tooling
choice, a prerequisite check, a rationale for an unusual test approach. Omit if none.}

## 4. Per-story verify matrix (summary)

| Phase | Stories | Primary verify |
|-------|---------|----------------|
| {phase name} | {sNN–sNN} | {the runnable command(s)} |

## 5. Known verification gaps (honest)

{Where a scenario's verify is a proxy, not a full proof — say so plainly, and name the
mitigation. A test plan that hides its own gaps is worse than one that states them.}

| Story | Gap | Mitigation |
|-------|-----|------------|

## 6. Manual UAT steps (P0 and P1)

{Numbered, runnable-by-a-human steps for anything that can't be scripted.}

## 7. Hard gates

| Gate | Command | Block? |
|------|---------|--------|
