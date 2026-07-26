---
name: grill-with-docs
model: opus
description: "Doc-grounded variant of grill-me — stress-tests plan assumptions by fetching and citing real library or API documentation. Every challenge must cite a real URL. Use when the plan depends on a specific library or external API."
---

# Grill With Docs

> **Use this vs grill-me:** `grill-with-docs` is the doc-grounded variant of `grill-me`. Use it when the plan relies on external libraries or APIs and every challenge must be grounded in and cite a real documentation URL. Use `grill-me` for context-only assumption surfacing without fetching docs.

> **HARD GATE** — Every challenge must cite a real documentation URL. No hallucinated APIs.

## Process

1. Read the plan or design under test (`specs/release-plan.yaml + epic shards`, INTERFACE-OPTIONS.md, etc.).
2. List assumptions that depend on external libraries or APIs.
3. For each assumption: fetch or quote official docs; challenge with "docs say X, plan says Y."
4. Resolve or update the plan inline; unresolved items block `plan-work`.

## Docs mode rules

- Cite URL + quoted snippet (method name, parameter, version).
- If docs contradict the plan, plan loses until updated.
- Prefer official docs over blog posts.

## Facts vs. Decisions Boundary

Distinguish between **facts** and **decisions**:
- **Facts** — things discoverable by reading docs, checking APIs, or exploring the codebase. Do not ask the user to confirm facts; find them yourself.
- **Decisions** — choices that require user input (trade-offs, preferences, priorities). Always present options and ask the user to choose.

Never "grill yourself" — if the answer is in the docs, go fetch it. Only ask questions where the user's judgment is needed.

## Confirmation Gate

> **HARD GATE** — Do NOT enact the plan or generate specifications until the user explicitly confirms shared understanding. Wait for explicit approval (e.g., "looks good", "confirmed", "proceed") before transitioning to any implementation, spec-writing, or task-slicing step.

## Verify

→ verify: `test -f skills/grill-with-docs/SKILL.md && test -f skills/grill-with-docs/REFERENCE.md`

See [REFERENCE.md](../../../skills/grill-with-docs/REFERENCE.md) for question templates.


<!-- story: e03s01 -->

---

# Grill With Docs — Question templates

- "Docs at [URL] show signature `foo(bar?: Baz)`. Your plan calls `foo(bar, baz)` — which is correct?"
- "The changelog at [URL] deprecates X in v3. Your plan still uses X — migrate or pin version?"
- "Error handling in [URL] throws `NetworkError`. Your plan catches `Error` only — is that sufficient?"
