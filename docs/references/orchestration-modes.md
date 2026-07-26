# Orchestration Modes Reference

**Source of Truth:** `docs/references/orchestration.md` (pinned)  
**Purpose:** Detailed comparison of the three orchestration modes and their quality/speed tradeoffs.

---

## Standard Mode (Enforce All Gates)

**Behavior:** Hard gates are non-negotiable; soft gates can be overridden with evidence.

```
discover -[gate]→ elaborate -[gate]→ plan -[gate]→ build -[gate]→ verify -[gate]→ release
         confirm  ✅        confirm  ✅       confirm  ✅       confirm  ✅       confirm  ✅

Quality gates:
  - request-review must be ≥94%
  - audit-code must pass all checks
  - Compliance audit ≥94% (authoritative value: scripts/lib/audit-compliance-report.sh)
```

**Quality:** highest — every gate enforced  
**Speed:** baseline  
**Risk:** Minimal  
**When to Use:** All production features and bug fixes.

---

## Fast-Track Mode (Skip Negotiable Gates)

**Behavior:** Skip gates where conditions are obviously met.

```
discover -[maybe]→ elaborate -[maybe]→ plan -[soft]→ build -[soft]→ verify -[maybe]→ release
         confirm?  ✅        confirm?  ✅      soft     ✅     soft     ✅      confirm?  ✅

Conditional skips:
  - Skip discover if: specs/product/SCOPE_LATEST.yaml exists + codebase already surveyed
  - Skip elaborate if: decisions already locked in prior release
  - Skip verify if: test coverage ≥95% + all tests PASS (skip audit)
```

**Quality:** slightly reduced — negotiable gates skipped  
**Speed:** faster than standard  
**Risk:** Medium (quality tradeoff)  
**When to Use:** Hotfixes, minor improvements, refactors on well-tested code.

---

## Ad-Hoc Mode (Legacy, Warnings Only)

**Behavior:** No gates; user can skip any phase; agent warns but does not block.

```
discover [warn] → elaborate [warn] → plan [warn] → build [warn] → verify [warn] → release [warn]
  ↓ optional       ↓ optional        ↓ optional    ↓ optional      ↓ optional      ↓ optional
```

**Quality:** lowest — no gate enforcement  
**Speed:** fastest  
**Risk:** High (no guardrails)  
**When to Use:** Exploration, prototyping, spike projects only — never production code.

---

## Mode Comparison

| | Standard | Fast-Track | Ad-Hoc |
|---|---|---|---|
| Hard gates | Enforced | Enforced | Warned only |
| Soft gates | Enforced | Skippable | Warned only |
| Relative quality | Highest | Reduced | Lowest |
| Relative speed | Baseline | Faster | Fastest |
| Use for | Production | Hotfixes/refactors | Spikes only |

> **On numbers:** this file previously carried precise-looking figures
> (success rates, bugs/1000 LOC, rework percentages) with no cited study or
> measurement behind them. They were removed rather than re-sourced —
> quantifying mode quality is exactly what outcome evals (e58) are meant to
> produce, from this repo's own runs. Until that exists, the ordering above
> is a design intent, not a measurement.
