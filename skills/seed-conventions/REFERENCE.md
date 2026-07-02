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
