---
name: craft-skill
description: Create new bigpowers skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill for the bigpowers lifecycle.
---

# Craft Skill

## Process

1. **Gather requirements** — ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?
   - What specs/ output does it produce (if any)?

2. **Verify Principles** — Ensure the skill aligns with [PRINCIPLES.md](../PRINCIPLES.md):
   - Is it atomic (verb-noun)?
   - Is it "deep" (simple interface, complex internal logic)?
   - Does it include Hard Gates?
   - Is it verifiable with a `.feature` file?

3. **Draft the skill** — create:
   - SKILL.md with concise instructions
   - Additional reference files if content exceeds 100 lines
   - Utility scripts if deterministic operations needed

3. **Review with user** — present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Naming Rules (bigpowers)

Every skill name must be a **two-word verb-noun pair**:
- First word: a verb (survey, model, define, develop, audit…)
- Second word: a noun from PMBOK 6 / Agile vocabulary (context, domain, language, tdd, code…)
- Pronounceable in any language, searchable, no noise words, no encodings
- Exception precedent: `grill-me`, `grill-with-docs` — kept for recognizability

Good: `survey-context`, `audit-code`, `validate-fix`
Bad: `context-surveyor`, `code-auditing-skill`, `fix-validator`

## Skill Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.sh
```

## SKILL.md Template

```md
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See [REFERENCE.md](REFERENCE.md)]
```

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load.

**Format**:
- Max 1024 chars
- Write in third person
- First sentence: what it does
- Second sentence: "Use when [specific triggers]"

**Good example**:
```
Investigate a bug by exploring the codebase to find root cause, then write a TDD-based fix plan to specs/DIAGNOSIS.md. Use when user reports a bug, wants to investigate a problem, or mentions "triage".
```

## When to Add Scripts

Add utility scripts when:
- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

## When to Split Files

Split into separate files when:
- SKILL.md exceeds 100 lines
- Content has distinct domains
- Advanced features are rarely needed

## specs/ Output

If the skill produces written output, it goes in `specs/` at the project root. Document the output file path in the skill body and in CONVENTIONS.md's output files table.

## sync-skills.sh Propagation

After adding a new skill directory with SKILL.md, run `scripts/sync-skills.sh` from the bigpowers repo root. This automatically generates:
- `.cursor/rules/<name>.mdc` — for Cursor
- `.gemini/extensions/bigpowers/skills/<name>/SKILL.md` — Agent Skill
- `.gemini/extensions/bigpowers/commands/<name>.toml` — Slash Command
- `.gemini/extensions/bigpowers/commands/prompts/<name>.md` — Command Prompt
- Updated `gemini-extension.json`

## Review Checklist

After drafting, verify:

- [ ] Name is a two-word verb-noun pair (or follows grill-me exception)
- [ ] Description includes triggers ("Use when...")
- [ ] SKILL.md under 100 lines
- [ ] No time-sensitive info
- [ ] Consistent terminology with CONVENTIONS.md
- [ ] specs/ output documented if applicable
- [ ] `sync-skills.sh` run to propagate to Cursor/Gemini
