# Andy Hunt & Dave Thomas: The Pragmatic Programmer

**Purpose:** Documents the pragmatic philosophy of software development from Hunt & Thomas — DRY, broken windows, tracer bullets, and the craftsmanship mindset — and how bigpowers skills embody these practices.

**Credit:** Andy Hunt and Dave Thomas. Key work: *The Pragmatic Programmer: From Journeyman to Master* (1999), 20th Anniversary Edition (2019).

---

## DRY — Don't Repeat Yourself

Every piece of knowledge must have a single, unambiguous, authoritative representation within a system. Duplication isn't just about code — it applies to documentation, configuration, build scripts, and even team communication. When knowledge is duplicated, a change in one place requires finding and updating every copy.

---

## Broken Windows Theory

In criminology, a building with one broken window left unrepaired soon has all its windows broken. In software, one piece of technical debt left unfixed — a bad variable name, a skipped test, a messy module — signals that quality doesn't matter, inviting more decay. Fix broken windows as soon as you see them, before the rot spreads.

---

## Tracer Bullets

Instead of building a system layer by layer (bottom-up) or feature by feature from a spec (top-down), build a thin vertical slice that touches every layer end-to-end — a "tracer bullet." This gives immediate feedback on architecture, integration, and assumptions. Once the tracer works, flesh out the system around it.

---

## Other Key Concepts

| Concept | What it means |
|---|---|
| **Cat Eats Source Code** | Take responsibility for your work; no excuses |
| **Stone Soup** | Start with something simple others can build on |
| **Boiling Frogs** | Watch for gradual degradation that's easy to miss |
| **Good-Enough Software** | Ship when quality is sufficient; perfection delays value |
| **Orthogonality** | Independent, non-overlapping components |
| **Prototype to Learn** | Build throwaways to answer questions, not to ship |

---

## How bigpowers uses

| Pragmatic Concept | bigpowers Skill | How it's embodied |
|---|---|---|
| DRY | `craft-skill` | Skills are the single authoritative source; artifacts are generated, not duplicated |
| Tracer bullets | `spike-prototype` | Throwaway prototypes validate assumptions before building |
| Broken windows | `audit-code` | Gates prevent quality decay from accumulating |
| Orthogonality | `dispatch-agents` | Independent workstreams that don't overlap |
| Prototype to learn | `spike-prototype` | Time-boxed experiments to answer open questions |

---

## See Also

- [`kent-beck.md`](kent-beck.md) — Beck's TDD and XP (complementary discipline)
- [`fowler.md`](fowler.md) — Fowler's refactoring catalog
- [`feathers.md`](feathers.md) — Feathers' legacy code techniques
- [`uncle-bob.md`](uncle-bob.md) — Martin's Clean Code principles
