---
title: "ADR-0004: Context Isolation — Fresh Window per Skill Spawn"
description: "ADR-0004: Context Isolation — Fresh Window per Skill Spawn"
---

# ADR-0004: Context Isolation — Fresh Window per Skill Spawn

**Status:** Accepted (shipped in v2.x — evolved from the original v2.4.0 estimate)
**Date:** 2026-05-20
**Amended:** 2026-07-03 (update status and implementation details post-ship)

## Context

When multiple skills run in the same session, the context window fills progressively. After skill 3,
the window is ~60% full and recency bias degrades reasoning quality. By skill 5, quality degrades
~50% relative to a fresh start. Re-reading the same files (`CONVENTIONS.md`, `state.yaml`) in every
skill wastes tokens redundantly.

## Decision

Each skill spawn receives a fresh, isolated context window (target: 200K tokens). The orchestrator
passes only the files explicitly required by that skill via a `&lt;files_to_read>` declaration.
Session history is not passed. Prior decisions are surfaced via `specs/state.yaml`, not conversation replay.

## What shipped (v2.x implementation)

The original design envisioned a single `orchestrate-project` coordinator. The shipped implementation
uses two complementary mechanisms:

1. **`delegate-task` / `dispatch-agents`:** Sub-agents get fresh context windows with only the
   skill's SKILL.md, the current epic capsule, and state.yaml — no session history or prior
   conversation. `dispatch-agents` runs multiple sub-agents in parallel on disjoint tasks.

2. **`session-state`:** Handoff data (`handoff.next_skill`, `epic_cycle.*`, `metrics.*`) is
   written to `specs/state.yaml` at the end of each critical-path skill. The next agent reads
   state.yaml to resume — no conversation replay needed. This replaced the original `STATE.md`
   concept (state.yaml is the YAML cockpit format adopted in v2.0.0).

## Consequences

- Quality is consistent across all skills regardless of session length.
- Token cost per skill drops ~20% (no re-reading).
- Orchestrator complexity increased as forecast, but the dual-mechanism design (isolated agents +
  state.yaml handoff) proved simpler than the original single-coordinator model.
- Skills can chain themselves via `handoff.next_skill` in state.yaml — the isolation is at the
  agent level, not the skill level. A skill's SKILL.md declares its next step, and the host
  harness launches a fresh agent to execute it.
