---
name: seed-conventions
description: "Generate CLAUDE.md and CONVENTIONS.md for a brand-new project through a brief interview, and create the specs/ directory with evolved bigpowers structure (product/, tech-architecture/, verifications/, epics/archive/). Entry point for greenfield projects. Use when starting a new project from scratch, when user asks to set up AI agent conventions, or when there is no CLAUDE.md yet."
---


# Seed Conventions
> **HARD GATE** — **HARD GATE** — Before any new code lands, confirm the project conventions are understood. Ask: 'What does a good commit message look like in this project?'


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

2b. **Stack profile (optional)** — Offer: `swift`, `typescript-vue`, `node-service`, or none. If chosen, merge the matching fragment from `profiles/<name>.md` into generated `CONVENTIONS.md` (commands, architecture, never-do).

3. **Commands** — "What commands do you use for: run, test, build, lint? I'll document them so agents know how to verify their work."

4. **Architecture** — "Describe the key modules and their relationships in 1–2 sentences. What are the main moving parts?"

5. **Conventions** — "Any naming conventions, file organization rules, or patterns that every contributor (human or agent) must follow?"

6. **Never-do list** — "What are the hard stops? Things an agent must never touch or do in this project?"

7. **Defensive code categories** — "Which of these apply to your project? (Rate limit / Retry with backoff / Circuit breaker / Timeout / Graceful degradation)"

## Generate files

After the interview, generate:

### `CLAUDE.md`

```markdown
# [Project Name] — Claude Code

Read CONVENTIONS.md before any GitHub or git operation.

## Project
[One sentence description]
Stack: [language, framework, runtime]

## Commands
| Action | Command |
|--------|---------|
| Run    | `[cmd]` |
| Test   | `[cmd]` |
| Build  | `[cmd]` |
| Lint   | `[cmd]` |

## Architecture
[1–2 sentences. Key modules and their relationships.]

## Conventions
- [convention 1]
- [convention 2]

## Never
- [hard stop 1]
- [hard stop 2]

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g. `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (`product/SCOPE_LATEST.yaml`, `release-plan.yaml`, `epics/`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
```

### `GEMINI.md`

```markdown
# [Project Name] — Gemini CLI

Read CONVENTIONS.md before any GitHub or git operation.

## Project
[One sentence description]
Stack: [language, framework, runtime]

## Commands
| Action | Command |
|--------|---------|
| Run    | `[cmd]` |
| Test   | `[cmd]` |
| Build  | `[cmd]` |
| Lint   | `[cmd]` |

## Architecture
[1–2 sentences. Key modules and their relationships.]

## Conventions
- [convention 1]
- [convention 2]

## Never
- [hard stop 1]
- [hard stop 2]

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g. `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (`product/SCOPE_LATEST.yaml`, `release-plan.yaml`, `epics/`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
```

### `AGENTS.md`

```markdown
# [Project Name] — OpenCode

Read CONVENTIONS.md before any GitHub or git operation.

## Project
[One sentence description]
Stack: [language, framework, runtime]

## Commands
| Action | Command |
|--------|---------|
| Run    | `[cmd]` |
| Test   | `[cmd]` |
| Build  | `[cmd]` |
| Lint   | `[cmd]` |

## Architecture
[1–2 sentences. Key modules and their relationships.]

## Conventions
- [convention 1]
- [convention 2]

## Never
- [hard stop 1]
- [hard stop 2]

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g. `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (`product/SCOPE_LATEST.yaml`, `release-plan.yaml`, `epics/`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
```

### `opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [".cursor/rules/*.mdc"]
}
```

### `CONVENTIONS.md`

Use the standard bigpowers CONVENTIONS.md template, filling in the project-specific defensive code categories from the interview.

### `specs/` directory

Create the evolved bigpowers directory structure:

```bash
mkdir -p specs/product
mkdir -p specs/product/snapshots
mkdir -p specs/epics/archive
mkdir -p specs/tech-architecture
mkdir -p specs/adr
mkdir -p specs/verifications
mkdir -p specs/bugs

# Create empty placeholder files
touch specs/product/SCOPE_LATEST.yaml
touch specs/product/VISION_LATEST.yaml
touch specs/product/GLOSSARY_LATEST.yaml
touch specs/release-plan.yaml
touch specs/execution-status.yaml
touch specs/planning-status.yaml
touch specs/state.yaml
touch specs/tech-architecture/tech-stack.md
touch specs/tech-architecture/security.md
touch specs/tech-architecture/test.md
touch specs/tech-architecture/design.md
touch specs/tech-architecture/REFACTOR_LATEST.md
touch specs/tech-architecture/IMPACT_LATEST.md
touch specs/bugs/registry.yaml
echo "# Specs\n\nAll planning documents for this project. Evolved bigpowers structure (v4.0.0+)." > specs/README.md
```

**Note:** `specs/state.yaml.lock` is NOT pre-created — it is acquired and released dynamically during writes to prevent concurrency conflicts.

### Verify

- [ ] CLAUDE.md exists and is populated
- [ ] CONVENTIONS.md exists and includes specs/ output convention
- [ ] specs/ directory exists
- [ ] specs/product/ exists with SCOPE_LATEST.yaml, VISION_LATEST.yaml, GLOSSARY_LATEST.yaml
- [ ] specs/tech-architecture/ exists with tech-stack.md, security.md, test.md, design.md
- [ ] specs/verifications/ exists
- [ ] specs/epics/archive/ exists
- [ ] specs/bugs/registry.yaml exists
- [ ] Confirm with user: "Does CLAUDE.md accurately describe your project?"
