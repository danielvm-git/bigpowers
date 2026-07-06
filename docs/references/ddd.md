# Domain-Driven Design (DDD)

<!-- story: e35s07 -->

**Purpose:** Documents Eric Evans' Domain-Driven Design — bounded contexts, context mapping, ubiquitous language, and strategic design — and how bigpowers skills embody these patterns for managing complexity at scale.

**Credit:** Eric Evans. Key work: *Domain-Driven Design: Tackling Complexity in the Heart of Software* (2003).

---

## Bounded Contexts

A **bounded context** is a boundary within which a particular domain model applies. Inside the boundary, terms have specific, unambiguous meanings. Outside, the same terms may mean something different. Bounded contexts are DDD's primary tool for managing semantic complexity — instead of one universal model, the system consists of multiple models, each valid within its context.

---

## Context Mapping

**Context mapping** is the practice of explicitly documenting relationships between bounded contexts:

| Pattern | Description |
|---|---|
| **Partnership** | Two contexts cooperate toward a shared goal |
| **Shared Kernel** | Two contexts share a subset of the domain model |
| **Customer/Supplier** | One context (upstream) produces, another (downstream) consumes |
| **Conformist** | Downstream conforms to upstream's model without influence |
| **Anticorruption Layer** | A translation layer that isolates a context from another's model |
| **Open Host Service** | A protocol or API that serves multiple downstream contexts |
| **Published Language** | A well-documented interchange format (e.g., XML schema, JSON schema) |
| **Separate Ways** | No integration — contexts are independent |

Context mapping makes integration relationships explicit, so teams know where coupling exists and how to manage it.

---

## Ubiquitous Language

The **ubiquitous language** is a shared vocabulary between developers and domain experts, used consistently in code, conversations, and documentation. It eliminates translation errors: when the code says `OverdraftPolicy`, domain experts know exactly what it means, and when domain experts say "overdraft policy," developers model it directly.

---

## Strategic Design

DDD distinguishes between:

- **Core Domain** — the part of the business that provides competitive advantage; worth the most investment
- **Supporting Domain** — necessary but not differentiating; can be outsourced or built with less rigor
- **Generic Domain** — solved problems; use off-the-shelf solutions

This triage prevents over-investing in non-differentiating concerns while under-investing in the core.

---

## How bigpowers uses

| DDD Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| Bounded contexts | `define-language` | Extracts context-specific terminology from the codebase |
| Ubiquitous language | `define-language` | Produces a DDD-style glossary from code symbols and documentation |
| Context mapping | `deepen-architecture` | Identifies where context boundaries are violated |
| Anticorruption layer | `plan-refactor` | Plans refactors to isolate bounded contexts |
| Strategic design | `model-domain` | Grills the plan against domain invariants and constraints |

---

## See Also

- [`rich-hickey.md`](rich-hickey.md) — Hickey's simple vs easy (bounded contexts prevent complecting at system level)
- [`fowler.md`](fowler.md) — Fowler's enterprise patterns (complementary to DDD strategic design)
- [`ousterhout.md`](ousterhout.md) — Ousterhout's deep modules (bounded contexts as deep modules at system level)
