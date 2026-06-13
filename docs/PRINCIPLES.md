# bigpowers Principles: The Evolution of Agentic Engineering

The `bigpowers` skill set is the result of a chronological evolution of software engineering discipline, starting from classic human-centric craftsmanship and culminating in a high-integrity, agent-first methodology.

---

## 1. The Foundation: Classical Craftsmanship (2008)
*Source:* [Uncle Bob (Clean Code)](references/uncle-bob.md)

Before agents, there was the **Software Craftsman**. We inherit the non-negotiable foundations of clean code:
- **SRP (Single Responsibility Principle):** Each function and module must do one thing.
- **The Boy Scout Rule:** Always leave the code cleaner than you found it.
- **F.I.R.S.T Testing:** Tests must be Fast, Independent, Repeatable, Self-Validating, and Timely.
- **Intention-Revealing Names:** Names must reveal why code exists and what it does.

---

## 2. Refining the Structure: Complexity Management (2018)
*Source:* [John Ousterhout (A Philosophy of Software Design)](references/ousterhout.md)

As systems grew, we learned that "small functions" (from Uncle Bob) could lead to "shallow modules." `bigpowers` upgrades the foundation with:
- **Deep Modules:** We favor modules with simple interfaces that hide significant internal complexity.
- **Information Hiding:** Reducing the "cognitive surface area" (and later, the token surface area) that an agent must understand.
- **Define Errors Out of Existence:** Designing APIs so that agents cannot easily trigger invalid states.

---

## 3. The Agentic Pivot: Behavioral Integrity (2023-2024)
*Sources:* [Karpathy](references/karpathy.md), [Superpowers](references/superpowers.md), [Pocock](references/pocock.md)

With the rise of LLMs, engineering shifted from *writing* code to *orchestrating* it. We introduced:
- **Think First:** Surfacing assumptions and planning before a single line of code is written.
- **Skill-Based Architecture:** Organizing capabilities into discrete, verb-noun "skills" (the `superpowers` model).
- **Zoom-Out Strategy:** Understanding the callers and the broader context before modifying internals (the `Pocock` mandate).
- **Surgical Edits:** Touching only what is required to fulfill the goal.

---

## 4. The Interface for Agents: Spec-Driven Development (2024)
*Source:* [Jaroslaw Wasowski](references/wasowski.md)

We recognized that the "Missing Link" between human intent and agent execution is the **Specification**.
- **SDD (Spec-Driven Development):** The specification is the primary driver of behavior.
- **BDD as the Link:** Using Gherkin and scenarios to provide unambiguous, verifiable instructions.
- **The Verification Loop:** Closing the loop between spec, plan, and empirical proof.

---

## 5. The Modern Standard: Agent-Centric Refinement (2026)
*Source:* [Akita (Clean Code for AI Agents)](references/akita.md)

This is the definitive "Update" to Uncle Bob. We optimize the foundation specifically for the "Agentic Turn":
- **Searchability is King (Grep-ability):** Unique *code symbol* naming (functions, classes, constants) to ensure a global `grep` returns < 5 results. Skill directory names are intentionally referenced across docs and indexes — the < 5 rule applies to code symbols only.
- **Structured Observability:** Mandatory JSON logging and idempotent setup. If an agent can't observe it, it can't fix it.
- **Token Economy:** Eliminating filler and redundant output to preserve the context window.
- **Remediation Hints:** Error messages that explicitly tell the agent *how* to recover.

---

## 6. The Synthesis: bigpowers Discipline (Current)
*Sources:* [BMAD](references/bmad.md), [GSD](references/gsd.md)

`bigpowers` consolidates these decades of learning into a single, cohesive discipline:
- **The 6-Phase Lifecycle:** A canonical arc (Discover → Elaborate → Plan → Build → Verify → Release). Note: *Sustain* is a session flow state, not a lifecycle phase.
- **Hard Gates:** Explicit blocks that prevent execution until quality criteria are met.
- **Session Governance:** Using `specs/state.yaml` and `specs/release-plan.yaml` to prevent context rot and drift.
- **94% Quality Threshold:** A near-perfect compliance mandate against all the above heuristics.

---

## 7. Verification & Compliance: Turning Philosophy into Proof

Principles without verification are merely suggestions. We use **Gherkin-based Audit Features** to empirically prove compliance. Every philosophical pillar is backed by a detailed `.feature` file in `specs/verifications/features/`:

| Philosophical Pillar | Verification Source (Feature File) |
|---|---|
| **Classical Craftsmanship** | [`cleancode.feature`](specs/verifications/features/cleancode.feature) |
| **Complexity Management** | [`pocock.feature`](specs/verifications/features/pocock.feature) |
| **Behavioral Integrity** | [`karpathy.feature`](specs/verifications/features/karpathy.feature) |
| **Spec-Driven Development** | [`wasowski.feature`](references/wasowski.md) (Implicit in SDD workflow) |
| **Agentic Standard** | [`akita.feature`](specs/verifications/features/akita.feature) |
| **Project Conventions** | [`conventions.feature`](specs/verifications/features/conventions.feature) |
| **Original Baseline** | [`superpowers.feature`](specs/verifications/features/superpowers.feature) |

### How to Verify
To ensure these principles are being followed, we run the following mandate:
1. **Audit Check:** Periodically run the audit suite against the codebase to generate a quality score.
2. **Red-Flag Detection:** If a scenario in a `.feature` file fails, it is treated as a **Hard Stop**.
3. **Continuous Refinement:** As we learn from new agents, we update the `.feature` files to harden our "Best-in-Class" standard.

---

## 8. The Anatomy of a High-Integrity Skill: Definition of Ready

When creating a new skill, it must meet these "Best-in-Class" requirements derived from our principles:

1.  **Atomic Naming (Akita/Superpowers):** Must be a unique two-word `verb-noun` pair. Searchable with a single `grep` (< 5 results).
2.  **High-Density Description:** The description must contain specific triggers ("Use when...") to minimize unnecessary skill loading (Token Economy).
3.  **Hard-Gated Workflows:** Processes must include explicit checkpoints or checklists to stop execution if quality criteria are not met.
4.  **Information Hiding (Ousterhout):** The `SKILL.md` must be < 100 lines. Advanced details, examples, and logic must be delegated to `REFERENCE.md` or `scripts/`.
5.  **Provenance-Ready:** If the skill modifies code, it must include a step to document *why* (link to ADR or spec).
6.  **Empirically Verifiable:** Every new skill should have a corresponding `.feature` file in `specs/audit/features/` to verify its own implementation.

---

*“Classic foundations, modern orchestration, agentic integrity.”*
