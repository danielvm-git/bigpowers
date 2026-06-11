---
name: grill-me
model: sonnet
description: Stress-test a plan or design through relentless questioning until every decision is resolved. Two modes: Design (default Q&A on decisions) and Docs (grounds every challenge in real library or API documentation). Use when user wants to challenge a plan, validate API assumptions, or mentions "grill me" or "grill me with docs".
---

# Grill Me

Two modes. Default is **Design**. Switch to **Docs** by saying "grill me with docs" or when the plan relies on a specific library or external API.

> **HARD GATE** — Do NOT accept a design until every hard decision has been stress-tested. "Seems right" is not a decision. Grilling must identify and resolve tensions before build begins.

## Design mode (default)

Interview relentlessly about every aspect of this plan until reaching shared understanding. Walk each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer. Ask one question at a time.

If a question can be answered by exploring the codebase, explore it instead.

## Docs mode

Ground every challenge in real documentation — no assumption about a library's behavior goes unchecked. See [REFERENCE.md](REFERENCE.md) for the full process.

Short form:
1. List every external library, third-party API, and framework behavior relied upon.
2. Fetch the actual docs for each (`WebFetch` the official API reference).
3. Challenge each plan assumption against the real docs: correct method signature? right version? deprecated?
4. Report confirmed ✓, corrected ✗ (with the real behavior), and uncertain → `spike-prototype`.
5. Update the plan for each confirmed discrepancy.
