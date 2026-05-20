# bigpowers — Best-in-Class Agentic Skills

44+ agent skills for high-integrity, spec-driven development by solo developers.

## Quick Start

```bash
# Sync skills to Cursor (.cursor/rules) and Gemini CLI (.gemini/extensions)
bash scripts/sync-skills.sh

# Run the full compliance audit
npm run compliance
```

## The BMAD Lifecycle

Every task follows a prescriptive 5-phase arc:
1. **Discover**: Investigate context and map unknowns.
2. **Elaborate**: Lock design decisions (ADRs).
3. **Plan**: Write verifiable implementation roadmaps.
4. **Build**: Execute via TDD and vertical slices.
5. **Sustain**: Audit quality and release.

## Hierarchy of Truth

| Level | Document | Responsibility |
|---|---|---|
| **Vision** | `PRINCIPLES.md` | Philosophical foundations and chronological evolution. |
| **Context** | `specs/CONTEXT.md` | Technology, architecture, glossary, and key decisions. |
| **Scope** | `specs/SCOPE.md` | In-scope / out-of-scope / constraints / success criteria. |
| **Decisions** | `specs/adr/` | Individual ADRs for hard, irreversible architectural choices. |
| **Roadmap** | `specs/RELEASE-PLAN.md` | WSJF-prioritized releases and success criteria. |
| **Current** | `specs/STATE.md` | Current milestone, session state, and pending releases. |
| **Index** | `SKILL-INDEX.md` | Canonical list of all 44 active skills (+ 6 planned). |
| **Style** | `CONVENTIONS.md` | Coding, testing, documentation, and naming standards. |

## References

- `references/` — external framework sources (Akita, BMAD, GSD, Karpathy, Ousterhout, Pocock, spec-kit, superpowers, Uncle Bob, Wasowski)
- `docs/` — bigpowers internal reference library (orchestration, gates, TDD, verification, security, model profiles)

---
*“Simplicity is the ultimate sophistication, but integrity is the ultimate requirement.”*
