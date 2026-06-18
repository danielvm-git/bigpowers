---
description: Block dangerous git commands (push, force push, reset --hard, clean, branch -D, checkout/restore .) and enforce Conventional Commits & Branch Protection before an AI agent runs them. Installs hook scripts for Claude Code, Cursor, Cursor CLI, and Gemini CLI; documents Google Antigravity Terminal deny lists. Use when the user wants git safety hooks, to block git push or destructive git in agents, or to mirror the same policy across AI coding tools.
---


# Guard Git
> **HARD GATE** — **HARD GATE** — Before committing, verify: branch is not main/master, author is correct, git user is configured. Bad commits are hard to fix.


Installs a shared hook that blocks destructive git operations and enforces workflow discipline. **Requires `jq` on the agent's PATH** when the hook runs.

## What gets blocked/enforced

- **Safety**: `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, `git checkout .`, `git restore .`.
- **Discipline**: Blocks direct commits or pushes to protected branches (`main`, `master`) unless `GIT_BIGPOWERS_LAND=1` (set only by `scripts/land-branch.sh`).
- **Allows**: `git push origin <feature-branch>` for backup/CI; solo land push to `main` only inside `land-branch.sh`.
- **Standardization**: Enforces [Conventional Commits](https://www.conventionalcommits.org/) for all `git commit` commands.
- **Secrets**: Blocks commits containing common secret patterns (`sk-`, `ghp_`, `AKIA`, `xoxb-`, `-----BEGIN` private keys) — see [REFERENCE.md](REFERENCE.md).

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

---

# Git guardrails — reference

## Secret patterns (audit + pre-commit)

Agents must not commit files containing:

- `sk-` (OpenAI API keys)
- `ghp_` / `gho_` (GitHub tokens)
- `AKIA` (AWS access key id)
- `xoxb-` (Slack bot tokens)
- `-----BEGIN` private keys

Use `audit-code` supply-chain checklist before commit. Consider `git-secrets` or custom pre-commit hook in target projects.

## Copy layout

The main script is `pre-tool-use.sh`.

```text
<hooks-dir>/pre-tool-use.sh
```

Example project locations:

- Claude: `.claude/hooks/`
- Cursor: `.cursor/hooks/`
- Gemini: `.gemini/hooks/`

Use the same layout for user-level hooks (`~/.claude/hooks`, `~/.cursor/hooks`, `~/.gemini/hooks`).

---

## Claude Code

Hook command does **not** need `GIT_GUARDRAILS_MODE` (defaults to `claude`).

**Project** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-tool-use.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Cursor and Cursor CLI

Use `beforeShellExecution`. Set `GIT_GUARDRAILS_MODE=cursor`.

**Project** (`.cursor/hooks.json`):

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      {
        "command": "GIT_GUARDRAILS_MODE=cursor .cursor/hooks/pre-tool-use.sh",
        "matcher": "git"
      }
    ]
  }
}
```

---

## Gemini CLI

Use `BeforeTool` with matcher `run_shell_command`. Set **`GIT_GUARDRAILS_MODE=gemini`**.

**Project** (`.gemini/settings.json`):

```json
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "run_shell_command",
        "hooks": [
          {
            "name": "git-guardrails",
            "type": "command",
            "command": "GIT_GUARDRAILS_MODE=gemini \"$GEMINI_PROJECT_DIR\"/.gemini/hooks/pre-tool-use.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

---

## Google Antigravity

Add **Deny list** entries in **Antigravity → Settings → Terminal**:

- `git push --force`
- `git push origin main`
- `git push origin master`
- `git reset --hard`
- `git clean`
- `git branch -D`
- `git checkout .`
- `git restore .`

---

## Verify (local tests)

**1. Block push to main without land mode (Claude mode):**
```bash
echo '{"tool_input":{"command":"git push origin main"}}' | ./pre-tool-use.sh
# Expected: exit 2, protected branch message
```

**2. Allow push to main with GIT_BIGPOWERS_LAND=1:**
```bash
GIT_BIGPOWERS_LAND=1 echo '{"tool_input":{"command":"git push origin main"}}' | ./pre-tool-use.sh
# Expected: exit 0 (when on main)
```

**3. Allow push to feature branch:**
```bash
echo '{"tool_input":{"command":"git push -u origin feat/my-task"}}' | ./pre-tool-use.sh
# Expected: exit 0
```

**4. Conventional Commits (Gemini mode):**
```bash
echo '{"tool_input":{"command":"git commit -m \"bad message\""}}' | GIT_GUARDRAILS_MODE=gemini ./pre-tool-use.sh
# Expected: exit 0, {"decision":"deny", "reason":"..."}
```

**5. Protected Branch commit (Cursor mode):**
```bash
# Run on 'main' branch
echo '{"command":"git commit -m \"feat: valid message\""}' | GIT_GUARDRAILS_MODE=cursor ./pre-tool-use.sh
# Expected: exit 2, "Direct commits to protected branch 'main' are forbidden"
```

**6. Land script exists:**
```bash
test -x scripts/land-branch.sh && echo OK
```

**7. Allow (Gemini mode):**
```bash
echo '{"tool_input":{"command":"git status"}}' | GIT_GUARDRAILS_MODE=gemini ./pre-tool-use.sh
# Expected: exit 0, {"decision":"allow"}
```
