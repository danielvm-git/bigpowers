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
