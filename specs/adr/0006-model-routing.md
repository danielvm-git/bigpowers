# ADR-0006: Model Routing — Skill-Specific Model Assignment

**Status:** Accepted (implementation pending — v2.4.0, alongside context isolation)
**Date:** 2026-05-20

## Context

Using the most capable model (Opus) for every skill wastes ~5x cost on tasks where Sonnet or
Haiku are sufficient. Using the cheapest model everywhere degrades quality on complex reasoning
tasks (planning, architecture decisions, assumption surfacing) by 15–23%.

## Decision

Skills are assigned a model tier based on task complexity:

| Tier | Model | Tasks | Token budget |
|------|-------|-------|-------------|
| Light | Haiku | Code review, verification, commit messages | 100K |
| Standard | Sonnet | Code writing, research, planning | 200K |
| Deep | Opus | Strategic planning, grill-me, ADR decisions | 250K |

The assignment lives in `references/model-profiles.md`. Skills declare their tier in SKILL.md
frontmatter (future: `model: sonnet`). The orchestrator enforces the assignment.

## Consequences

- ~35% cost reduction vs. all-Opus baseline.
- Quality maintained on complex tasks (Opus where it matters).
- Introduces a config surface that must stay in sync with SKILL.md updates.
- Requires `orchestrate-project` to read model assignment before spawning subagents.
