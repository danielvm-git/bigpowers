
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

---

# Git guardrails — reference

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

- `git push`
- `git push --force`
- `git reset --hard`
- `git clean`
- `git branch -D`
- `git checkout .`
- `git restore .`

---

## Verify (local tests)

**1. Dangerous Pattern (Claude mode):**
```bash
echo '{"tool_input":{"command":"git push origin main"}}' | ./pre-tool-use.sh
# Expected: exit 2, stderr message
```

**2. Conventional Commits (Gemini mode):**
```bash
echo '{"tool_input":{"command":"git commit -m \"bad message\""}}' | GIT_GUARDRAILS_MODE=gemini ./pre-tool-use.sh
# Expected: exit 0, {"decision":"deny", "reason":"..."}
```

**3. Protected Branch (Cursor mode):**
```bash
# Run on 'main' branch
echo '{"command":"git commit -m \"feat: valid message\""}' | GIT_GUARDRAILS_MODE=cursor ./pre-tool-use.sh
# Expected: exit 2, "Direct commits to protected branch 'main' are forbidden"
```

**4. Allow (Gemini mode):**
```bash
echo '{"tool_input":{"command":"git status"}}' | GIT_GUARDRAILS_MODE=gemini ./pre-tool-use.sh
# Expected: exit 0, {"decision":"allow"}
```
