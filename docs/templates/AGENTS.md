# story: e37s01
# story: e45s21
# story: e81s01
# scenario: SC-e37s01-P1-01
# [Project Name] — AI Agents

> **Multi-agent context** — This file is the canonical project context for **Cline**, **Aider**, **OpenCode**, and other AGENTS.md-native tools. Claude Code and Cursor read it via the `CLAUDE.md` symlink.

Read CONVENTIONS.md before any GitHub or git operation.

<!-- BEGIN bigpowers:context-routing -->
## Context Routing

Load subdirectory context by file glob — see project-specific routing table (seeded by `seed-conventions`).
<!-- END bigpowers:context-routing -->

<!-- BEGIN bigpowers:learned-preferences -->
## Learned User Preferences

- (none yet — updated via `session-state`)

## Workspace Facts

- (none yet — durable facts discovered across sessions)
<!-- END bigpowers:learned-preferences -->

<!-- BEGIN bigpowers:project -->
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

## Token Economy — Minimal Footprint

> Production-safe subset of the 8-rule AGENTS.md pattern (Vercel engineer, ~60B tokens).
> Rule 1 ("no backward compatibility") is excluded deliberately: it risks data loss in production.

1. **Check existing dependencies first.** DO inspect what your current dependencies already do before adding a package or writing your own code.
2. **Prefer mature, maintained libraries.** DO NOT rewrite a capability a maintained library provides without a documented reason.
3. **Copy validated patterns.** DO study how established products solve the same problem before inventing a new approach.
4. **Keep the simplest working implementation.** DO write the least code that satisfies the stated requirement. NEVER add preventive abstraction or unused config layers.
<!-- END bigpowers:project -->
