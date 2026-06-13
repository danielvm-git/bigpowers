---
name: seed-conventions
model: sonnet
description: Generate CLAUDE.md and CONVENTIONS.md for a brand-new project through a brief interview, and create the specs/ directory with evolved bigpowers structure (product/, tech-architecture/, verifications/, epics/archive/). Entry point for greenfield projects. Use when starting a new project from scratch, when user asks to set up AI agent conventions, or when there is no CLAUDE.md yet.
---

# Seed Conventions
> **HARD GATE** — Before any new code lands, confirm the project conventions are understood. Ask: 'What does a good commit message look like in this project?'

Bootstrap a new project with the AI agent conventions it needs. Run this once at the start of a greenfield project.

## What this creates

- `CLAUDE.md` — Claude Code session config (project-specific)
- `CONVENTIONS.md` — shared rules for all AI agents
- `specs/` — the specs directory where all planning output will live
- `AGENTS.md` — for OpenCode and other agents (optional)
- `GEMINI.md` — for Gemini CLI (optional)

## Interview

Ask the user these questions (one at a time, wait for each answer):

1. **Project name and one-sentence description** — "What is this project? One sentence."
2. **Stack** — "What language, framework, and runtime? (e.g. TypeScript / Next.js / Node 22)"
2b. **Stack profile (optional)** — Offer: `swift`, `typescript-vue`, `node-service`, or none. If chosen, merge the matching fragment from `profiles/<name>.md` into generated `CONVENTIONS.md`.
3. **Commands** — "What commands do you use for: run, test, build, lint?"
4. **Architecture** — "Key modules and relationships in 1–2 sentences."
5. **Conventions** — "Any naming, file organization, or patterns all agents must follow?"
6. **Never-do list** — "What are the hard stops? Things an agent must never touch?"
7. **Defensive code categories** — "Which apply? (Rate limit / Retry / Circuit breaker / Timeout / Graceful degradation)"

## Generate files

After the interview, generate each file using the templates in [REFERENCE.md](REFERENCE.md):
- `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` — from the agent-config template
- `opencode.json` — from the opencode template
- `CONVENTIONS.md` — bigpowers standard template + project defensive code categories

### `specs/` directory

```bash
mkdir -p specs/product specs/product/snapshots specs/epics/archive
mkdir -p specs/tech-architecture specs/adr specs/verifications specs/bugs
touch specs/product/SCOPE_LATEST.yaml specs/product/VISION_LATEST.yaml specs/product/GLOSSARY_LATEST.yaml
touch specs/release-plan.yaml specs/execution-status.yaml specs/planning-status.yaml specs/state.yaml
touch specs/tech-architecture/tech-stack.md specs/tech-architecture/security.md
touch specs/tech-architecture/test.md specs/tech-architecture/design.md
touch specs/tech-architecture/REFACTOR_LATEST.md specs/tech-architecture/IMPACT_LATEST.md
touch specs/bugs/registry.yaml
echo "# Specs\n\nAll planning documents for this project." > specs/README.md
```

**Note:** `specs/state.yaml.lock` is NOT pre-created — acquired/released dynamically.

## Verify

- [ ] CLAUDE.md exists and is populated
- [ ] CONVENTIONS.md exists and includes specs/ output convention
- [ ] specs/product/ exists with SCOPE_LATEST.yaml, VISION_LATEST.yaml, GLOSSARY_LATEST.yaml
- [ ] specs/tech-architecture/ exists with tech-stack.md, security.md, test.md, design.md
- [ ] specs/verifications/ exists
- [ ] specs/epics/archive/ exists
- [ ] specs/bugs/registry.yaml exists
- [ ] Confirm with user: "Does CLAUDE.md accurately describe your project?"
