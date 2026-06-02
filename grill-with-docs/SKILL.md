---
name: grill-with-docs
description: Stress-test plan assumptions grounded in real library or API documentation URLs. Use when the plan depends on a specific library or external API, or as a docs-grounded variant of grill-me.
model: opus
---

# Grill With Docs

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
