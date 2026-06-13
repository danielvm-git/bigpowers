---
name: grill-with-docs
description: Doc-grounded variant of grill-me — stress-tests plan assumptions by fetching and citing real library or API documentation. Every challenge must cite a real URL. Use when the plan depends on a specific library or external API.
model: opus
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

## Verify

→ verify: dialogue log contains at least one `https://` doc URL per challenged assumption

See [REFERENCE.md](REFERENCE.md) for question templates.
