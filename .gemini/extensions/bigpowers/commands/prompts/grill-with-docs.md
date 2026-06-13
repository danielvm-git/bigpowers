
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

---

# Grill With Docs — Question templates

- "Docs at [URL] show signature `foo(bar?: Baz)`. Your plan calls `foo(bar, baz)` — which is correct?"
- "The changelog at [URL] deprecates X in v3. Your plan still uses X — migrate or pin version?"
- "Error handling in [URL] throws `NetworkError`. Your plan catches `Error` only — is that sufficient?"
