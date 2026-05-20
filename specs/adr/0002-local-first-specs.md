# ADR-0002: Local-First Specs

**Status:** Accepted
**Date:** 2026-05-19

## Context

External trackers (Jira, Linear, GitHub Issues) require API calls, authentication, and introduce
latency. Agents relying on remote state cannot operate offline and incur token cost fetching
context that could be present in the local working tree.

## Decision

All planning and spec output goes to `specs/` at the project root, as Markdown files tracked by
Git. No bigpowers skill creates or reads from an external issue tracker. Skills that bridge to
external systems (e.g., future `to-issues`) are opt-in utilities, not core workflow steps.

## Consequences

- Full agent context is available without network calls.
- `specs/` becomes the project's long-term memory, accumulating across every phase.
- Losing external tracker sync means no sprint boards, no Gantt charts — deliberate trade-off.
- `git blame` on `specs/` files gives a full audit trail of decisions.
