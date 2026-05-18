
# Guard Git

Installs a shared hook that blocks destructive git operations. **Requires `jq` on the agent's PATH** when the hook runs.

## What gets blocked

- `git push` (including `--force`)
- `git reset --hard`, `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

## Quick start

1. **Scope**: ask project-only vs global (paths differ per product).
2. **Copy the hook bundle** from this skill's [scripts/](scripts/) to the client's hooks directory, **keeping** `block-dangerous-git.sh` and `lib/git-guardrails-core.sh` together (the main script sources the core file).
3. **Run `chmod +x`** on `block-dangerous-git.sh`.
4. **Merge** the hook snippet from [REFERENCE.md](REFERENCE.md) into the right settings file — do not wipe unrelated keys.
5. **Verify** with the echo tests in [REFERENCE.md](REFERENCE.md).

| Client | Mechanism | Config |
|--------|-----------|--------|
| Claude Code | `PreToolUse` (Bash) | `.claude/settings.json` or `~/.claude/settings.json` |
| Cursor / Cursor CLI | `beforeShellExecution` | `.cursor/hooks.json` or `~/.cursor/hooks.json` |
| Gemini CLI | `BeforeTool` + `run_shell_command` | `.gemini/settings.json` or `~/.gemini/settings.json` |
| Google Antigravity | Built-in Terminal **Deny list** | Settings UI (no shell hook) |

**Modes (env on the hook command):** `GIT_GUARDRAILS_MODE` is `claude` (default) or `cursor` → stderr + exit `2` on block. Set `gemini` for Gemini CLI → JSON `decision` on stdout (see [REFERENCE.md](REFERENCE.md)).

## Customization

To add or remove patterns, edit `lib/git-guardrails-core.sh` in the copied bundle (array `GIT_GUARDRAILS_PATTERNS`).

## Advanced

Full JSON examples, merge rules, Antigravity deny-list entries, and test commands: [REFERENCE.md](REFERENCE.md).

---

# Git guardrails — reference

## Copy layout

The main script resolves `lib/git-guardrails-core.sh` relative to its own directory. After copy, you should have:

```text
<hooks-dir>/block-dangerous-git.sh
<hooks-dir>/lib/git-guardrails-core.sh
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
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**Global** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

If `hooks` / `PreToolUse` already exists, **append** this object to the `PreToolUse` array (or merge Bash matcher entries) without removing other hooks.

---

## Cursor and Cursor CLI

Use `beforeShellExecution` so stdin includes a top-level `command` field. Set `GIT_GUARDRAILS_MODE=cursor` for explicit mode (behavior matches `claude`: block with exit code `2` and stderr).

**Project** (`.cursor/hooks.json` at repo root). Hooks run with the project root as cwd, so use a **relative** path to the script:

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      {
        "command": "GIT_GUARDRAILS_MODE=cursor .cursor/hooks/block-dangerous-git.sh",
        "matcher": "git"
      }
    ]
  }
}
```

**User** (`~/.cursor/hooks.json`): install scripts under `~/.cursor/hooks/` and reference them as `./hooks/block-dangerous-git.sh` or `hooks/block-dangerous-git.sh` (paths are relative to `~/.cursor/`).

Optional: add `"failClosed": true` if you want the shell action blocked when the hook crashes or times out.

Merge: preserve `version`, other events, and existing `beforeShellExecution` entries.

---

## Gemini CLI

Use `BeforeTool` with matcher `run_shell_command`. The hook must set **`GIT_GUARDRAILS_MODE=gemini`** so blocked commands return JSON `{"decision":"deny","reason":"..."}` on stdout (compact, single-line JSON).

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
            "command": "GIT_GUARDRAILS_MODE=gemini \"$GEMINI_PROJECT_DIR\"/.gemini/hooks/block-dangerous-git.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

**User** (`~/.gemini/settings.json`): point `command` at `~/.gemini/hooks/block-dangerous-git.sh` with the same `GIT_GUARDRAILS_MODE=gemini` prefix.

Gemini CLI merges settings with project over user; see [Gemini CLI hooks](https://github.com/google-gemini/gemini-cli/blob/main/docs/hooks/reference.md).

---

## Google Antigravity

Antigravity does not use this shell hook. Configure the agent in **Antigravity → Settings → Terminal**:

1. Set **Terminal Command Auto Execution** to a mode that respects denials (e.g. avoid full auto-approve if you need guardrails).
2. Add **Deny list** entries for commands that should never auto-run. Suggested substrings aligned with this skill’s policy:

   - `git push`
   - `git push --force`
   - `git reset --hard`
   - `git clean`
   - `git branch -D`
   - `git checkout .`
   - `git restore .`

Adjust to match how your build splits or validates command strings. See [Google’s Antigravity getting started / security](https://codelabs.developers.google.com/getting-started-google-antigravity).

---

## Verify (local tests)

From the directory that contains `block-dangerous-git.sh` (or pass the full path to the script):

**Claude-shaped input (expect stderr + exit 2):**

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | ./block-dangerous-git.sh || true
```

**Cursor-shaped input (expect exit 2 on block):**

```bash
echo '{"command":"git push"}' | GIT_GUARDRAILS_MODE=cursor ./block-dangerous-git.sh || true
```

**Allow (expect exit 0, no stderr for claude/cursor):**

```bash
echo '{"tool_input":{"command":"git status"}}' | ./block-dangerous-git.sh; echo "exit=$?"
```

**Gemini (expect one-line JSON, exit 0):**

```bash
echo '{"tool_input":{"command":"git reset --hard"}}' | GIT_GUARDRAILS_MODE=gemini ./block-dangerous-git.sh
```

**Gemini allow:**

```bash
echo '{"tool_input":{"command":"git log -1"}}' | GIT_GUARDRAILS_MODE=gemini ./block-dangerous-git.sh
```

Expected: `{"decision":"allow"}` or similar one-line allow JSON.

---

## Customization

Edit the copied `lib/git-guardrails-core.sh`: change `GIT_GUARDRAILS_PATTERNS` (extended regex for `grep -E`). Keep patterns conservative—overly broad regex can block benign commands.
