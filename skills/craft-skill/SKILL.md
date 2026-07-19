# story: e45s02
<!-- story: e45s12 -->
---
name: craft-skill
model: sonnet
effort: standard
description: Create new bigpowers skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill for the bigpowers lifecycle.
---

# Craft Skill

> **HARD GATE** — Do NOT name a skill without a two-word verb-noun pair. Do NOT merge a new skill without running `sync-skills.sh` — the generated `.cursor/rules/` and `.gemini/` artifacts must match the source SKILL.md.

## CSO Description Discipline (e45s02)

The YAML `description` is the **Catalog Selection Object** — the only field agents see when picking a skill.

| Rule | Limit |
|------|-------|
| Max length | 1024 characters |
| Voice | Third person |
| Content | Capability + `Use when …` triggers only |
| Forbidden | Workflow steps, phase chains, numbered lists, `→ verify:`, HARD GATE prose |

Move process detail into the SKILL.md body or REFERENCE.md — never into `description`.

## Process

1. **Gather requirements** — ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?
   - What specs/ output does it produce (if any)?

2. **Verify Principles** — Ensure the skill aligns with [PRINCIPLES.md](https://github.com/danielvm-git/bigpowers/blob/main/docs/PRINCIPLES.md):
   - Is it atomic (verb-noun)?
   - Is it "deep" (simple interface, complex internal logic)?
   - Does it include Hard Gates?
   - Is it verifiable with a `.feature` file?

3. **Draft the skill** — create:
   - SKILL.md with concise instructions (see [REFERENCE.md](REFERENCE.md) for template)
   - Additional reference files if content exceeds 100 lines
   - Utility scripts if deterministic operations needed

   **Auto-skill from library README:** When user provides a library README or API docs URL, extract: triggers, HARD GATEs, verify commands, specs/ output — draft SKILL.md without inventing APIs not in the source.

4. Add `model:` frontmatter (`haiku` | `sonnet` | `opus`) per [model-profiles.md](https://github.com/danielvm-git/bigpowers/blob/main/docs/references/model-profiles.md).

> **STREAM CONTINUITY** — When writing file content, output in continuous chunks of ~200 lines. Do not pause. Continue immediately until complete. If you need time, emit a placeholder comment rather than going silent.

5. **Review with user** — present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

6. **Completion-honesty gate (HARD GATE — e45s02)** — Before declaring done:
   - Run `bash scripts/validate-skill-description.sh skills/<name>/SKILL.md` — must exit 0
   - Run `bash scripts/sync-skills.sh` — must complete without error
   - Run `bash scripts/run-skill-verify.sh <name>` if the skill defines a verify command
   - Show terminal output for each — narration without evidence is rejected

## Naming Rules

Every skill name must be a **two-word verb-noun pair**. See [REFERENCE.md](REFERENCE.md) for full rules, examples, and documented exceptions.

## specs/ Output

If the skill produces written output, it goes in `specs/` at the project root. Document the output file path in the skill body and in CONVENTIONS.md's output files table.

## Review Checklist

After drafting, verify:

- [ ] Name is a two-word verb-noun pair (or follows grill-me exception)
- [ ] Description < 1024 chars, triggers only, no workflow-summary leakage
- [ ] Description includes triggers ("Use when...")
- [ ] SKILL.md under 100 lines
- [ ] No time-sensitive info
- [ ] Consistent terminology with CONVENTIONS.md
- [ ] specs/ output documented if applicable
- [ ] `validate-skill-description.sh` exits 0
- [ ] `sync-skills.sh` run to propagate to Cursor/Gemini
- [ ] `bash scripts/validate-skill-catalog.sh` passes for the new skill (HARD GATE — completion honesty)

> **HARD GATE** — Do NOT declare the skill done until `bash scripts/validate-skill-catalog.sh --strict --skill <name>` exits 0. Validator enforces verb-noun name, HARD GATE block, description ≤1024 chars, and `→ verify:` command.

## Verify

→ verify: `bash scripts/validate-skill-catalog.sh --strict --skill craft-skill && bash scripts/validate-skill-description.sh skills/craft-skill/SKILL.md && echo OK || echo FAIL`
