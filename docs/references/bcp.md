# BCP: Business Complexity Points

**Purpose:** BCP (Business Complexity Points) is the canonical pre-build story sizing method used in bigpowers. It measures *functional complexity* before implementation begins, enabling velocity tracking and scope discipline.

**Credit:** Methodology sourced from [`flow-ciandt/bcp-agent`](https://github.com/flow-ciandt/bcp-agent). `bigpowers` adopts BCP as its primary story-sizing instrument for spec-driven development.

---

## What BCP measures

BCP measures the *functional complexity of a user story*, estimated before building starts. It is **not**:
- A time estimate (hours or days)
- A task-level annotation (`[BCP 2]` per task is slop)
- A throughput/velocity count (it's an input size, not output)

A story's BCP is its pre-build complexity size. After release, BCP/hr = BCPs delivered / cycle hours, which is a meaningful velocity metric.

---

## The 6-Step Sizing Method

| Step | What to do |
|------|-----------|
| **1. Classify** | Is the story functional (new behavior) or non-functional (perf, infra, docs)? Non-functional stories score differently — apply judgment. |
| **2. Story Maturity** | Score 1–5: Is the story well-understood (5) or still fuzzy (1)? Gate: stories < 3 must go back to elaboration. |
| **3. INVEST Maturity** | Score each INVEST criterion (Independent, Negotiable, Valuable, Estimable, Small, Testable) 1–5. Gate: sum < 20 → return to elaboration. |
| **4. Decompose** | Break the story into three categories of elements: **Business Rules** (logic, conditions, calculations), **Interface Elements** (UI, API, input/output shapes), **Boundaries** (external systems, integrations, data stores touched). |
| **5. Score on Fibonacci** | Score each element 1, 2, 3, 5, or 8 by complexity: 1 = trivial, 8 = very complex. |
| **6. Sum** | Sum all element scores → that is the **story's BCP**. |

### Example

Story: "User can filter the dashboard by date range"

| Element | Type | Score |
|---------|------|-------|
| Date-range filter logic | Business Rule | 3 |
| Filter UI component | Interface Element | 2 |
| Date param in API query | Interface Element | 1 |
| Database date-indexed query | Boundary | 3 |
| **Total BCP** | | **9** |

---

## How bigpowers uses BCP

| Where | How |
|-------|-----|
| `plan-release` | Sizes each story's BCP during release planning; written to `specs/release-plan.yaml` as the BCP baseline |
| `plan-work` | Confirms BCP baseline; stories under 3 BCP can skip zoom-out (`--fast` flag) |
| `specs/state.yaml` | `epic_cycle.story_bcps` holds the story's BCP size for the active session |
| `release-branch` | Computes `bcp_per_hour = story_bcps / cycle_minutes * 60`; appends to `specs/metrics/cycle-times.yaml` |
| `specs/metrics/cycle-times.yaml` | Velocity ledger: tracks BCP/hr per story, enabling trend analysis |

---

## Interpretation

| BCP | Size | Notes |
|-----|------|-------|
| 1–5 | Small | < half a day typical |
| 6–15 | Medium | 1–2 days typical |
| 16–30 | Large | Consider splitting |
| 30+ | Epic | Must split into stories ≤ 30 BCP each |

---

## See Also

- `plan-release` — where BCP sizing happens for the release backlog
- `plan-work` — where BCP is confirmed before build starts
- `specs/metrics/cycle-times.yaml` — velocity ledger
- [flow-ciandt/bcp-agent](https://github.com/flow-ciandt/bcp-agent) — canonical source
