# bigpowers — Claude Code

Read CONVENTIONS.md before any GitHub or git operation.

## Project

bigpowers — 44 agent skills for spec-driven, test-first software development by solo developers.
Stack: Markdown / Bash (documentation-based; skills integrate with Claude Code, Cursor, Gemini CLI)

## Commands

| Action | Command |
|--------|---------|
| Run    | `bash scripts/sync-skills.sh` |
| Test   | N/A (documentation project) |
| Build  | `bash scripts/install.sh` |
| Lint   | `bash scripts/sync-skills.sh` (validates SKILL.md syntax) |

## Architecture

Collection of 44 verb-noun skills, each with a SKILL.md source file and supporting documentation. The sync-skills.sh script auto-generates artifacts for Cursor (.cursor/rules) and Gemini CLI (.gemini/extensions/bigpowers/) from SKILL.md sources. All planning and spec output goes to specs/ at the project root.

## Conventions

- Skill directories use verb-noun naming (two words, kebab-case)
- Every skill has a single SKILL.md file as its source of truth
- All planning/spec output goes to specs/ at project root
- Artifacts in .cursor/rules and .gemini/ are auto-generated; edit SKILL.md, not artifacts
- Run sync-skills.sh after any SKILL.md changes to regenerate artifacts

## Never

- Never edit .cursor/rules or .gemini/extensions/ directly — these are generated files
- Never create a skill without a SKILL.md file and proper verb-noun naming
- Never push changes without running sync-skills.sh first

## Session Start

Before any task, run this sequence — not optional:

1. Read `CLAUDE.md` (this file)
2. Read `CONVENTIONS.md`
3. Read `specs/STATE.md` if it exists — current milestone and pending work
4. Read `specs/RELEASE-PLAN.md` if it exists — active release context

## Agent Rules

- **Workflow Mandate:** You MUST use the bigpowers skills (e.g., `plan-work`, `develop-tdd`, `craft-skill`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ and CONVENTIONS.md before writing code.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
- All written output (plans, specs, investigations) goes in specs/.
