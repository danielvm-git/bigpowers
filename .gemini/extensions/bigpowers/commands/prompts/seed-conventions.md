
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

`specs/state.yaml` carries a top-level `workflow_mode` key (`team-pr` | `solo-git`, default `team-pr`). This is the **canonical integrate-mode signal** for all skills — set it once here and skills such as `release-branch` read it from this file instead of sniffing profile files.

## Verify

- [ ] CLAUDE.md exists and is populated
- [ ] CONVENTIONS.md exists and includes specs/ output convention
- [ ] specs/product/ exists with SCOPE_LATEST.yaml, VISION_LATEST.yaml, GLOSSARY_LATEST.yaml
- [ ] specs/tech-architecture/ exists with tech-stack.md, security.md, test.md, design.md
- [ ] specs/verifications/ exists
- [ ] specs/epics/archive/ exists
- [ ] specs/bugs/registry.yaml exists
- [ ] Confirm with user: "Does CLAUDE.md accurately describe your project?"

---

# Seed Conventions — Reference Templates

## Agent config template (CLAUDE.md / GEMINI.md / AGENTS.md)

All three files use the same structure — only the header differs:
- `CLAUDE.md` → `# [Project Name] — Claude Code`
- `GEMINI.md` → `# [Project Name] — Gemini CLI`
- `AGENTS.md` → `# [Project Name] — OpenCode`

```markdown
# [Project Name] — [Agent]

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

## opencode.json template

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [".cursor/rules/*.mdc"]
}
```

## CONVENTIONS.md

Use the standard bigpowers CONVENTIONS.md as the base. Fill in the project-specific defensive code categories from the interview answers.

## Stack profile fragments

If the user selected a stack profile, merge the matching `profiles/<name>.md` fragment into the generated `CONVENTIONS.md` under a `## Stack Conventions` section. Profiles supply language-specific commands, architecture patterns, and never-do additions.
