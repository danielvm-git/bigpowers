---
name: model-domain
model: sonnet
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates specs/tech-architecture/tech-stack.md and specs/adr/ inline as decisions crystallise. Use when user wants to stress-test a plan against their project's domain language and documented decisions.
---

# Model Domain

**Distinct from `define-language` and `deepen-architecture`:** Use this skill to stress-test a plan through a grilling interview that resolves domain model decisions and captures invariants. Use `define-language` to produce a canonical glossary of terms. Use `deepen-architecture` to find module-level refactoring opportunities in code.

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

> **HARD GATE** — Capture invariants (what MUST always be true) and state machines (what transitions are legal) for core entities. If these are fuzzy, design will fail.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Domain awareness

During codebase exploration, also look for existing documentation:

### File structure

Most repos have a single context:

```
/
├── specs/
│   ├── CONTEXT.md
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `specs/tech-architecture/tech-stack.md` exists, the repo has multiple contexts. The map points to where each one lives:

```
/
├── specs/
│   ├── CONTEXT-MAP.md
│   └── adr/                          ← system-wide decisions
└── src/
    ├── ordering/
    │   └── specs/
    │       ├── CONTEXT.md
    │       └── adr/                  ← context-specific decisions
    └── billing/
        └── specs/
            ├── CONTEXT.md
            └── adr/
```

Create files lazily — only when you have something to write. If no `specs/tech-architecture/tech-stack.md` exists, create it when the first term is resolved. If no `specs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `specs/tech-architecture/tech-stack.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update specs/tech-architecture/tech-stack.md inline

When a term is resolved, update `specs/tech-architecture/tech-stack.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Don't couple `specs/tech-architecture/tech-stack.md` to implementation details. Only include terms that are meaningful to domain experts.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

## Concurrency safety audit

When the plan touches shared state, async, or multi-threaded code:

- [ ] List every **shared mutable** location (globals, singletons, module-level caches).
- [ ] For each: who reads, who writes, synchronization mechanism (lock, actor, immutable copy).
- [ ] Flag **race risks** (check-then-act, non-atomic read-modify-write) with severity.
- [ ] Record findings in `specs/tech-architecture/tech-stack.md` under `## Concurrency` or in an ADR if architectural.
