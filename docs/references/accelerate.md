# Accelerate: The DORA Four Keys

**Purpose:** Documents the DORA (DevOps Research and Assessment) Four Keys metrics — deployment frequency, lead time for changes, time to restore service, and change failure rate — and how bigpowers skills embody these performance indicators.

**Credit:** Nicole Forsgren, Jez Humble, and Gene Kim. Key work: *Accelerate: The Science of Lean Software and DevOps* (2018).

---

## The DORA Four Keys

DORA's research identified four metrics that distinguish high-performing software delivery teams from low performers. These "four keys" are statistically validated predictors of organizational performance:

| Metric | What it measures | Elite Performance |
|---|---|---|
| **Deployment Frequency** | How often code is deployed to production | On demand (multiple per day) |
| **Lead Time for Changes** | Time from code committed to code in production | Less than one hour |
| **Time to Restore Service** | Time to recover from a production incident | Less than one hour |
| **Change Failure Rate** | Percentage of deployments causing a failure | 0–15% |

These metrics form a balanced scorecard: speed (deployment frequency, lead time) is balanced by stability (restore time, failure rate). Teams that optimize only for speed sacrifice stability; teams that optimize only for stability sacrifice speed. Elite performers achieve both.

---

## The Accelerate Model

Forsgren's research goes beyond the four keys to identify 24 capabilities that drive software delivery performance. The capabilities cluster into five categories:

1. **Continuous Delivery** — version control, test automation, deployment automation, trunk-based development
2. **Architecture** — loosely coupled architecture, empowered teams
3. **Product and Process** — customer feedback, small batch sizes, lightweight change approval
4. **Lean Management** — limit WIP, visual displays, monitoring
5. **Cultural** — Westrum organizational culture (generative, not pathological), learning culture

---

## Classification

DORA classifies teams into four performance tiers based on their four-key metrics:

| Tier | Deployment Frequency | Lead Time | Restore Time | Failure Rate |
|---|---|---|---|---|
| **Elite** | On demand | < 1 hour | < 1 hour | 0–15% |
| **High** | Daily–weekly | 1 day–1 week | < 1 day | 0–15% |
| **Medium** | Weekly–monthly | 1 week–1 month | < 1 day | 0–15% |
| **Low** | Monthly–yearly | 1–6 months | 1 week–1 month | 46–60% |

---

## How bigpowers uses

| DORA Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Deployment frequency | `release-branch` | Supports frequent small releases with PR/solo-land options |
| Lead time | `kickoff-branch` | Feature branches enable parallel work and fast integration |
| Change failure rate | `audit-code` | Gates prevent regressions from reaching production |
| Restore time | `commit-message` | Conventional Commits enable fast rollback identification |
| Small batch sizes | `plan-work` | Capsules decompose work into small, independently releasable stories |
| Trunk-based development | `release-branch` | Feature branches merge cleanly to main with squashed state commits |

---

## See Also

- [`bcp.md`](bcp.md) — BCP sizing (complementary: BCP/hr is a derived metric from cycle time)
- [`bcp-plus.md`](bcp-plus.md) — Extended 13-dimension sizing with NFR dimensions
- [`verification-patterns.md`](verification-patterns.md) — How outputs are verified (affects change failure rate)
- [`gates.md`](gates.md) — Quality gates that reduce change failure rate
