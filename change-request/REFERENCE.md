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
