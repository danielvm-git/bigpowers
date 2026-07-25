# story: e79s01
# Agentic STE — Controlled English for Instructional Prose

Agentic STE adapts [ASD-STE100](https://www.asd-ste100.org/) discipline for documents agents **read before acting**. It targets **input precision**, not output compression.

## Scope boundary (Rule 1)

Apply Agentic STE to instructional prose in:

- `skills/*/SKILL.md` body (below frontmatter)
- `CLAUDE.md` / `AGENTS.md` agent-managed fenced blocks
- `CONVENTIONS.md` agent-facing rules

**Out of scope:** YAML frontmatter, code blocks, tables, URLs, story tags, and **`terse-mode`** (output compression under context pressure). Do not conflate input-precision rules with terse-mode.

## Approved directive vocabulary (Rule 2)

Use only these terms for binding instructions:

| Term | Meaning |
|------|---------|
| MUST | Required action |
| MUST NOT | Forbidden action |
| NEVER | Absolute prohibition |
| ALWAYS | Required every time |
| DO | Positive imperative |
| DO NOT | Negative imperative |

Prefer **MUST NOT** / **NEVER** over soft modals for hard stops.

## Banned hedge modals (Rule 3)

Do **NOT** use these words in instructional sentences (case-insensitive, whole word):

`should`, `might`, `could`, `may`, `consider`, `try`, `generally`, `typically`

Replace with directive vocabulary. Example: "You should run tests" → "Run tests before commit."

## Sentence length cap (Rule 4)

Each instruction sentence: **maximum 20 words**. Split long sentences into separate lines. One instruction per sentence.

## Imperative mood (Rule 5)

Start instruction sentences with a verb. Use "Run …", "Write …", "Do NOT …" — not "You should …" or "It is recommended that …".

## Active voice (Rule 6)

Name the actor. "Run Preflight" not "Preflight should be run." "The agent MUST …" when the actor is ambiguous.

## One instruction per line (Rule 7)

Put each instruction on its own line or bullet. Do not chain multiple instructions in one sentence with "and then" or semicolons.

## Pronoun back-reference (Rule 8)

Do not use "it", "this", or "they" to refer to a noun more than one clause away. Repeat the noun or use a bullet label.

## Enforcement (Rule 9)

| When | Tool |
|------|------|
| New or edited skill | `bash scripts/validate-agentic-ste.sh --strict skills/<name>/SKILL.md` |
| Generated CLAUDE.md / CONVENTIONS.md | Apply Rules 2–8 during `seed-conventions` |
| Catalog audit | `bash scripts/validate-agentic-ste.sh --audit skills/` (flags debt; does not rewrite catalog) |

Validator is the mechanical backstop. Writers MUST follow this doc first.

## Numeric summary (Rule 10)

| Limit | Value |
|-------|-------|
| Max words per instruction sentence | 20 |
| Banned hedge modals | 8 terms (Rule 3) |
| Approved directive terms | 6 terms (Rule 2) |
| Scope files | SKILL.md body, CLAUDE.md, CONVENTIONS.md |
