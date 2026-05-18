---
name: guard-git
description: Block dangerous git commands (push, force push, reset --hard, clean, branch -D, checkout/restore .) and enforce Conventional Commits & Branch Protection before an AI agent runs them. Installs hook scripts for Claude Code, Cursor, Cursor CLI, and Gemini CLI; documents Google Antigravity Terminal deny lists. Use when the user wants git safety hooks, to block git push or destructive git in agents, or to mirror the same policy across AI coding tools.
---

# Guard Git

Installs a shared hook that blocks destructive git operations and enforces workflow discipline. **Requires `jq` on the agent's PATH** when the hook runs.

## What gets blocked/enforced

- **Safety**: `git push` (including `--force`), `git reset --hard`, `git clean -f`, `git branch -D`, `git checkout .`, `git restore .`.
- **Discipline**: Blocks direct commits or pushes to protected branches (`main`, `master`).
- **Standardization**: Enforces [Conventional Commits](https://www.conventionalcommits.org/) for all `git commit` commands.

## Quick start

1. **Scope**: ask project-only vs global (paths differ per product).
2. **Copy the hook bundle** from the root [hooks/](hooks/) directory to the client's hooks directory.
3. **Run `chmod +x`** on `pre-tool-use.sh`.
4. **Merge** the hook snippet from [REFERENCE.md](REFERENCE.md) into the right settings file — do not wipe unrelated keys.
5. **Verify** with the tests in [REFERENCE.md](REFERENCE.md).

| Client | Mechanism | Config |
|--------|-----------|--------|
| Claude Code | `PreToolUse` (Bash) | `.claude/settings.json` or `~/.claude/settings.json` |
| Cursor / Cursor CLI | `beforeShellExecution` | `.cursor/hooks.json` or `~/.cursor/hooks.json` |
| Gemini CLI | `BeforeTool` + `run_shell_command` | `.gemini/settings.json` or `~/.gemini/settings.json` |
| Google Antigravity | Built-in Terminal **Deny list** | Settings UI (no shell hook) |

**Modes (env on the hook command):** `GIT_GUARDRAILS_MODE` is `claude` (default) or `cursor` → stderr + exit `2` on block. Set `gemini` for Gemini CLI → JSON `decision` on stdout.

## Customization

To add or remove patterns or protected branches, edit `pre-tool-use.sh`.

## Advanced

Full JSON examples, merge rules, Antigravity deny-list entries, and test commands: [REFERENCE.md](REFERENCE.md).
