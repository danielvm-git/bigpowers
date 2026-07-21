<!-- wayfinder resolution artifact — T18 (agents-and-conventions), closed -->
<!-- CANONICAL FILE: this is AGENTS.md. CLAUDE.md and GEMINI.md are filesystem SYMLINKS to it —
     never separate files, so they cannot diverge (per big-docs DESIGN.md §3.11). -->
<!-- DELIBERATELY THIN. This file does not absorb CONVENTIONS.md — it points to it. If you find
     yourself writing a full section here that restates something CONVENTIONS.md already owns
     (a past, real mistake: a duplicate "Pre-Merge Checklist" section existed in both files),
     cut it to a one-line pointer instead. One rule, one home. -->
<!-- Composed from the real, already-built big-docs/docs/templates/AGENTS.md — not invented here. -->
<!-- Wave 2, plain markdown, no OKF envelope (consistent with every other Wave 2 template). -->

# {Project Name} — AI Agents

> **Multi-agent context** — this file is the canonical project context for Cline, Aider,
> OpenCode, and other AGENTS.md-native tools. Claude Code and Cursor read it via the `CLAUDE.md`
> symlink; Gemini CLI via `GEMINI.md`.

Read `CONVENTIONS.md` before any GitHub or git operation.

<!-- BEGIN bigpowers:context-routing -->
## Context Routing

{Load subdirectory context by file glob — project-specific routing table, seeded by
`seed-conventions`. Point at CONVENTIONS.md/specs layout rather than re-describing it.}
<!-- END bigpowers:context-routing -->

<!-- BEGIN bigpowers:learned-preferences -->
## Learned User Preferences

- (none yet — updated via `session-state`, never hand-authored)

## Workspace Facts

- (none yet — durable facts discovered across sessions)
<!-- END bigpowers:learned-preferences -->

<!-- BEGIN bigpowers:project -->
## Project

{One sentence — what this codebase does.}
Stack: {language, framework, runtime}

## Commands

| Action | Command |
|--------|---------|
| Run | `{cmd}` |
| Test | `{cmd}` or N/A |
| Build | `{cmd}` |
| Lint | `{cmd}` |
| Preflight | `{the full local green-gate chain}` |
| CI | `gh pr checks` (when a PR is open) |

## Architecture

{1-2 sentences — key modules and their relationships. Link to `docs/concept/architecture.md`
for the full curated explanation; do not restate it here.}

## Conventions

{2-3 bullets max — the ones a contributor needs before their first commit. Everything else
lives in CONVENTIONS.md.}

- {e.g. Named exports only}

## Never

- Never dismiss reproducible gate failures as pre-existing or out of scope
- Never proceed on red Preflight or red CI
- {project-specific hard stop}

## Agent Rules

- **Workflow Mandate:** route feature work through this project's skills/process, not ad-hoc.
- **Always Green:** Preflight and CI must be green before forward work.
- Read `specs/`/`docs/project/` and CONVENTIONS.md before writing code.
- Write the minimum code that solves the stated problem.
- Run tests after every change. Show evidence before declaring done.
<!-- END bigpowers:project -->
