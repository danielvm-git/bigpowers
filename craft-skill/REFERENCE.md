# Craft Skill — Reference

## Naming Rules (full)

Every skill name must be a **two-word verb-noun pair**:
- First word: a verb (survey, model, define, develop, audit…)
- Second word: a noun from PMBOK 6 / Agile vocabulary (context, domain, language, tdd, code…)
- Pronounceable in any language, searchable, no noise words, no encodings
- Exception precedent: `grill-me` — kept for recognizability

Good: `survey-context`, `audit-code`, `validate-fix`
Bad: `context-surveyor`, `code-auditing-skill`, `fix-validator`

Any new naming exception requires an entry in CONVENTIONS.md before the skill is published.

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
Investigate a bug by exploring the codebase to find root cause, then write a TDD-based fix plan to specs/bugs/BUG-*.md. Use when user reports a bug, wants to investigate a problem, or mentions "triage".
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

## sync-skills.sh Propagation

After adding a new skill directory with SKILL.md, run `scripts/sync-skills.sh` from the bigpowers repo root. This automatically generates:
- `.cursor/rules/<name>.mdc` — for Cursor
- `.gemini/extensions/bigpowers/skills/<name>/SKILL.md` — Agent Skill
- `.gemini/extensions/bigpowers/commands/<name>.toml` — Slash Command
- `.gemini/extensions/bigpowers/commands/prompts/<name>.md` — Command Prompt
- Updated `gemini-extension.json`

verify: `bash scripts/sync-skills.sh 2>&1 | grep "skills synced"`
