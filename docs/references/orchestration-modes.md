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
  - Compliance audit ≥93%
```

**Quality:** 93% success rate, 0.9 bugs/1000 LOC, -64% rework  
**Speed:** Baseline (100%)  
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

**Quality:** 90% success rate, 1.2 bugs/1000 LOC, -50% rework  
**Speed:** 30% faster  
**Risk:** Medium (quality tradeoff)  
**When to Use:** Hotfixes, minor improvements, refactors on well-tested code.

---

## Ad-Hoc Mode (Legacy, Warnings Only)

**Behavior:** No gates; user can skip any phase; agent warns but does not block.

```
discover [warn] → elaborate [warn] → plan [warn] → build [warn] → verify [warn] → release [warn]
  ↓ optional       ↓ optional        ↓ optional    ↓ optional      ↓ optional      ↓ optional
```

**Quality:** 78% success rate, 2.5 bugs/1000 LOC, +35% rework  
**Speed:** 40% faster  
**Risk:** High (no guardrails)  
**When to Use:** Exploration, prototyping, spike projects only — never production code.

---

## Mode Comparison

| | Standard | Fast-Track | Ad-Hoc |
|---|---|---|---|
| Hard gates | Enforced | Enforced | Warned only |
| Soft gates | Enforced | Skippable | Warned only |
| Success rate | 93% | 90% | 78% |
| Bug density | 0.9/1000 LOC | 1.2/1000 LOC | 2.5/1000 LOC |
| Speed | Baseline | +30% | +40% |
| Use for | Production | Hotfixes/refactors | Spikes only |
