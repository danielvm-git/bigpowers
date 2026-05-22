---
name: craft-skill
description: Create new bigpowers skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill for the bigpowers lifecycle.
---

# Craft Skill

> **HARD GATE** — Do NOT name a skill without a two-word verb-noun pair. Do NOT merge a new skill without running `sync-skills.sh` — the generated `.cursor/rules/` and `.gemini/` artifacts must match the source SKILL.md.

## Process

1. **Gather requirements** — ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?
   - What specs/ output does it produce (if any)?

2. **Verify Principles** — Ensure the skill aligns with [PRINCIPLES.md](../docs/PRINCIPLES.md):
   - Is it atomic (verb-noun)?
   - Is it "deep" (simple interface, complex internal logic)?
   - Does it include Hard Gates?
   - Is it verifiable with a `.feature` file?

3. **Draft the skill** — create:
   - SKILL.md with concise instructions (see [REFERENCE.md](REFERENCE.md) for template)
   - Additional reference files if content exceeds 100 lines
   - Utility scripts if deterministic operations needed

> **STREAM CONTINUITY** — When writing file content, output in continuous chunks of ~200 lines. Do not pause between sections. Continue immediately until complete. If you need time to think, emit a placeholder heading rather than going silent.

4. **Review with user** — present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Naming Rules

Every skill name must be a **two-word verb-noun pair**. See [REFERENCE.md](REFERENCE.md) for full rules, examples, and documented exceptions.

## specs/ Output

If the skill produces written output, it goes in `specs/` at the project root. Document the output file path in the skill body and in CONVENTIONS.md's output files table.

## Review Checklist

After drafting, verify:

- [ ] Name is a two-word verb-noun pair (or follows grill-me exception)
- [ ] Description includes triggers ("Use when...")
- [ ] SKILL.md under 100 lines
- [ ] No time-sensitive info
- [ ] Consistent terminology with CONVENTIONS.md
- [ ] specs/ output documented if applicable
- [ ] `sync-skills.sh` run to propagate to Cursor/Gemini
