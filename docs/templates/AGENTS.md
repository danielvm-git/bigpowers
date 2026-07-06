# story: e37s01
# scenario: SC-e37s01-P1-01
# [Project Name] — AI Agents

> **Multi-agent context** — This file is the canonical project context for **Cline**, **Aider**, **OpenCode**, and other AGENTS.md-native tools. Claude Code and Cursor read it via the `CLAUDE.md` symlink.

Read CONVENTIONS.md before any GitHub or git operation.

## Project

[One sentence. What this codebase does.]
Stack: [language, framework, runtime]

## Commands

| Action | Command |
|--------|---------|
| Run | `[cmd]` |
| Test | `[cmd]` or N/A |
| Build | `[cmd]` |
| Lint | `[cmd]` |
| Preflight | `[test && lint && build chain — or user-named full-green cmd]` |
| CI | `gh pr checks` (when a PR is open) |

## Test

`[cmd]` or N/A

## Lint

`[cmd]` or N/A

## Build

`[cmd]` or N/A

## Architecture

[1–2 sentences. Key modules and their relationships.]

## Conventions

- [e.g. Named exports only]
- [e.g. All queries go through the repository layer]

## Never

- Never dismiss reproducible gate failures as pre-existing or out of scope
- Never proceed on red Preflight or red CI — invoke quick-fix or fix-bug first
- [Hard stop — e.g. Never touch legacy/]

## Agent Rules

- **Workflow Mandate:** Use bigpowers skills (e.g. `plan-work`, `develop-tdd`) for structured work.
- **Always Green:** Preflight and CI must be green before forward work.
- Read specs/ and CONVENTIONS.md before writing code.
- Write the minimum code that solves the stated problem.
- Run tests after every change. Show evidence before declaring done.
- All planning output goes in specs/.
