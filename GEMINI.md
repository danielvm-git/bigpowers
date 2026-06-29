# bigpowers — Gemini CLI

> **Auto-generated** by `sync-skills.sh` from `CLAUDE.md`. Edit CLAUDE.md, not this file.

Read CONVENTIONS.md before any GitHub or git operation.

## Project

bigpowers — 58 agent skills for spec-driven, test-first software development by solo developers.
Stack: Markdown / Bash (documentation-based; skills integrate with Claude Code, Cursor, Gemini CLI)

## Commands

| Action  | Command |
|---------|---------|
| Install | `npx bigpowers` or `npm install -g bigpowers` |
| Run     | `bash scripts/sync-skills.sh` |
| Test    | N/A (documentation project) |
| Build   | `bash scripts/install.sh` (from source) |
| Lint    | `bash scripts/sync-skills.sh` (validates SKILL.md syntax) |

## Architecture

Collection of 58 verb-noun skills, each with a SKILL.md source file and supporting documentation. Includes Verify phase and profiles/. The sync-skills.sh script auto-generates artifacts for Cursor (.cursor/rules) and Gemini CLI (.gemini/extensions/bigpowers/) from SKILL.md sources. All planning and spec output goes to specs/ at the project root.

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

## Token Management

- **Auto-Terse**: When a session exceeds 20 turns or the context window feels "heavy" (latency increasing), you MUST switch to `terse-mode` to save tokens.
- **Context Compaction**: Every 10 turns, summarize the current session state and implementation decisions into a short, high-density note.
- **Minimal Output**: Prefer text-only output for simple status; use `web_fetch` or `run_shell_command` only for evidence.

## Agent Rules

- **Workflow Mandate:** You MUST use the bigpowers skills (e.g., `plan-work`, `develop-tdd`, `craft-skill`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ and CONVENTIONS.md before writing code.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
- All written output (plans, specs, investigations) goes in specs/.

## bts toolchain

`bts` is installed. Prefer its verbs over ad-hoc shell commands.

| Task | Command | Avoid |
|------|---------|-------|
| Search code | `bts find --print <pattern>` | grep / find / cat |
| Interactive search | `bts find <pattern>` | manual grep pipes |
| Compress for context | `bts compress <file>` or `cmd \| bts compress` | summarising by hand |
| Repo map | `bts map` | listing files by hand |
| Library docs | `bts docs <lib>` | guessing from training data |
| Package source | `bts src <pkg>` | git clone |
| Toolchain health | `bts doctor` | which / command -v |

**Rules**
- Search with `bts find` before opening files to locate a symbol or pattern.
- Pipe anything > 200 lines through `bts compress` before adding to context.
- Run `bts map` when asked for a repo overview.
- Use `bts docs <lib>` before answering questions about library APIs.
- If a tool is missing, say so and run `bts doctor` — do not silently substitute.
