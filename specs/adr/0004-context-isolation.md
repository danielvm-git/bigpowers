# ADR-0004: Context Isolation — Fresh Window per Skill Spawn

**Status:** Accepted (implementation pending — v2.4.0)
**Date:** 2026-05-20

## Context

When multiple skills run in the same session, the context window fills progressively. After skill 3,
the window is ~60% full and recency bias degrades reasoning quality. By skill 5, quality degrades
~50% relative to a fresh start. Re-reading the same files (`PROJECT.md`, `STATE.md`) in every
skill wastes tokens redundantly.

## Decision

Each skill spawn receives a fresh, isolated context window (target: 200K tokens). The orchestrator
passes only the files explicitly required by that skill via a `<files_to_read>` declaration.
Session history is not passed. Prior decisions are surfaced via `STATE.md`, not conversation replay.

## Consequences

- Quality is consistent across all skills regardless of session length.
- Token cost per skill drops ~20% (no re-reading).
- Orchestrator complexity increases ~20% (file-passing logic, STATE.md synchronisation).
- Requires `orchestrate-project` to be the coordinator — skills cannot chain themselves.
