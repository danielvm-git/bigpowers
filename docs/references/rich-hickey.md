# Rich Hickey: Simple vs Easy

**Purpose:** Documents Rich Hickey's core distinctions — simple vs easy, complecting, and the value of information over place-oriented programming — and how bigpowers skills embody these principles.

**Credit:** Rich Hickey. Key talk: *Simple Made Easy* (Strange Loop 2011). Creator of Clojure and the Datomic database.

---

## Simple vs Easy

Hickey draws a critical distinction that is often conflated:

| Term | Definition | Litmus test |
|---|---|---|
| **Simple** | One fold, one role, not entangled | Does it have one responsibility? |
| **Easy** | Near at hand, familiar, convenient | Can I reach it quickly? |

Simple is an objective property — something either is simple (unentangled) or it isn't. Easy is subjective — what's easy for one developer may be hard for another. Hickey's thesis: **prioritize simplicity over ease**. An easy but complex (entangled) system becomes progressively harder to change; a simple but unfamiliar system becomes easy with practice.

---

## Complecting

"Complect" is Hickey's term for entangling separate concerns. The verb captures what happens when you interleave things that should remain independent:

- **Complecting** = braiding together what should be separate
- **Composing** = combining independent, simple pieces

The cardinal sin of software design is complecting: tying together concerns that don't need to be tied. Once complected, changing one thing forces changes in the entangled parts.

---

## Information Model

Hickey advocates a design approach that starts with information and its relationships, not with objects and their methods:

1. **What information does the system need?** (data model)
2. **How does it flow?** (processes, not objects)
3. **When you have the information, answer the question** (functions over data)

This data-first approach produces simpler systems because information has no lifecycle or side effects — it just *is*.

---

## How bigpowers uses

| Hickey Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Simple over easy | `plan-refactor` | Refactors extract and disentangle before behavioral changes |
| Avoid complecting | `deepen-architecture` | Identifies where concerns are complected and suggests decomposition |
| Information-first design | `define-language` | Extracts a DDD-style ubiquitous language from the codebase |
| Independent composition | `dispatch-agents` | Parallel agents operate on disjoint scopes |

---

## See Also

- [`fowler.md`](fowler.md) — Fowler's refactoring catalog (refactoring as disentangling)
- [`ddd.md`](ddd.md) — Domain-Driven Design (bounded contexts prevent complecting at system level)
- [`ousterhout.md`](ousterhout.md) — Ousterhout's deep modules (simple interfaces, complex internals)
