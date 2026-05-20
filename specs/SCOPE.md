# Scope: bigpowers

**Core value:** "Maintain senior-grade quality (audit score) while scaling agentic autonomy."

A collection of 44+ high-integrity agent skills for solo developers using AI agents (Claude Code, Gemini CLI, Cursor). Enforces a prescriptive 5-phase BMAD lifecycle and prioritizes architectural depth, surgical changes, and empirical verification.

See `specs/CONTEXT.md` for full vision, technology, architecture, and glossary.
See `specs/adr/` for decision rationale.

---

## Scope

### In-Scope (Core)
- **Skill Lifecycle:** Standardized verb-noun skills with `SKILL.md` sources.
- **Audit Harness:** Gherkin-based compliance suite (`scripts/audit-compliance.sh`).
- **Orchestration:** High-level project coordination meta-skills (Standard, Fast-Track, Ad-Hoc).
- **Context Isolation:** Fresh 200K window per skill spawn to prevent "context rot."
- **Supply-Chain Security:** Automated package legitimacy gates (slopcheck integration).
- **Wave-Based Execution:** Parallel execution of independent tasks to optimize speed.
- **Local-First:** All state maintained in `specs/` (Markdown/Git).

### Out-of-Scope (Non-Goals)
- **Domain-Specific Skills:** (e.g., `scaffold-react-app`) — bigpowers provides the *how*, not the *what*.
- **Platform Locks:** Integration with specific SaaS trackers (Jira/Linear).
- **Marketplace/Plugins:** bigpowers is a discipline, not a plugin store.

---

## Key Decisions

See `specs/adr/` for full ADRs. Summary:

| ADR | Decision | Rationale |
|-----|----------|-----------|
| 0001 | Verb-Noun Naming | Atomic, searchable, aligns with PMBOK/Agile verbs |
| 0002 | Local-First Specs | Full context without external API calls or latency |
| 0003 | Prescriptive Core Loop | Gates prevent hallucination loops and skipped validation |
| 0004 | Context Isolation | Fresh windows prevent recency bias and quality degradation |
| 0005 | Hard Gate Mandate | Explicit stop conditions enforce quality at transition points |
| 0006 | Model Routing | Haiku/Sonnet/Opus per task complexity optimises cost-quality ROI |

---

## Constraints
- **Context Efficiency:** No file should exceed 300 lines (to avoid model truncation).
- **Searchability:** All symbols must return < 5 results in a global `grep`.
- **Zero-Redundancy:** Every fact must live in exactly one canonical location.

---

## Success Criteria (v2.x Baseline)

- [x] 100% compliance in `audit-compliance.sh` suite.
- [x] All 44 skills present in `SKILL-INDEX.md`.
- [x] Zero "placeholder" scripts in `specs/audit/steps/`.
- [x] Documentation hierarchy (CONTEXT → SCOPE → RELEASE-PLAN → STATE) fully implemented.
