# story: e84s01
# Agent Toolchain — bts, sqz, rtk

Reference documentation for context-saving toolchains used across bigpowers agents.

---

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

### Rules
- Search with `bts find` before opening files to locate a symbol or pattern.
- Pipe anything > 200 lines through `bts compress` before adding to context.
- Run `bts map` when asked for a repo overview.
- Use `bts docs <lib>` before answering questions about library APIs. Doc fetches use `scripts/lib/doc-fetch-cache.sh` (ETag-revalidated, 300s TTL).
- If a tool is missing, say so and run `bts doctor` — do not silently substitute.

---

## Token Management Hook Configuration (e45s03)

`scripts/hooks/token-mgmt-pre-tool-use.sh` blocks oversized tool calls when prose rules are ignored. Wire as a `PreToolUse` hook for `Read`, `Grep`, and `Bash` (alongside `hooks/pre-tool-use.sh` for git safety). Thresholds: Read >100KB, Grep >200 matches without `head_limit`, Bash commands likely to exceed 500 output lines without `rtk`/`sqz compress`. Install snippet:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read|Grep|Bash", "hooks": [{ "type": "command", "command": "bash scripts/hooks/token-mgmt-pre-tool-use.sh" }] }
    ]
  }
}
```

---

## sqz — Context Compression

sqz compresses tool output so large files, long logs, and verbose command output cost far fewer tokens.

### Preferred tools (MCP)

The `sqz-mcp` server exposes three read-only tools that compress their output through the sqz pipeline:

- **`sqz_read_file`** — read a file from disk and return a compressed view. **PREFER this over built-in `Read`** for any file larger than ~2KB or read more than once. Repeat reads return a 13-token `§ref:HASH§` reference instead of full content.
- **`sqz_grep`** — search files for a literal string or regex. **PREFER this over built-in `Grep`** for anything matching more than a handful of lines. Caps at 200 matches by default (`max_matches` to raise).
- **`sqz_list_dir`** — list a directory skipping `.git`, `node_modules`, `target`, `dist`, `build`, `vendor`, `__pycache__`. **PREFER this over `ls -la` via Bash**.

Use built-in `Read`/`Grep`/`Glob` only for:
- Tiny config files (<1KB) where compression can't help.
- Byte-exact reads you'll hash or diff (lockfiles, signatures).
- Globbing (sqz has no glob tool).

### Bash commands (hooked automatically)

A PreToolUse hook rewrites eligible shell commands to pipe output through `sqz compress`:

```bash
git status           # → git status 2>&1 | sqz compress --cmd git
cargo test           # → cargo test 2>&1 | sqz compress --cmd cargo
docker ps            # → docker ps 2>&1 | sqz compress --cmd docker
kubectl get pods     # → kubectl get pods 2>&1 | sqz compress --cmd kubectl
```

The rewrite is skipped for interactive commands (`vim`, `ssh`, `python`), compound commands (`a && b`, `a > file.txt`), and anything already piped through sqz.

### Escape hatch — `§ref:HASH§` token

To expand a `§ref:a1b2c3d4§` token:
- Shell: `~/.local/bin/sqz expand a1b2c3d4` (or `~/.local/bin/sqz expand §ref:a1b2c3d4§`).
- MCP tool: call `expand` with `{ "prefix": "a1b2c3d4" }`.
- Command uncompressed: prefix with `SQZ_NO_DEDUP=1` (e.g. `SQZ_NO_DEDUP=1 git log | sqz compress`).
- Emergency pass-through: call `passthrough` MCP tool for raw text.

### When NOT to use sqz tools
- Writing or editing files — use built-in `Write`/`Edit` tools (sqz has no write tools).
- Running commands interactively or in watch mode.
- Reading very small files (<1KB).

---

## RTK (Rust Token Killer) — Token-Optimized Commands

### Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged.

Even in command chains with `&&`:
```bash
rtk git add . && rtk git commit -m "msg" && rtk git push
```

### PreToolUse Hook (e45s16)

`scripts/hooks/rtk-rewrite.sh` is symlinked into `~/.claude/hooks/` by `bash scripts/install.sh` and registered as a Bash `PreToolUse` hook. It delegates to `rtk hook claude`.

### RTK Commands by Workflow

#### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

#### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

#### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

#### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

#### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

#### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%)
rtk find <pattern>      # Find grouped by directory (70%)
```

#### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

#### Infrastructure & Network (65-85% savings)
```bash
rtk docker ps           # Compact container list (85%)
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

#### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

### Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.

## pi Install Channels (story: BUG-2026-11-06-install-multi-channel-collisions)

pi discovers bigpowers skills through **exactly one** channel. Two channels at
once loads every skill name twice and prints one `collision` block per skill
(80 blocks), and the copy pi keeps is not necessarily the one you edit.

| Channel | What it is | Owned by |
|---|---|---|
| package | `~/.pi/agent/settings.json` → `packages` lists `bigpowers` (serves `.pi/skills`) | `bigpowers setup` / manual |
| symlinks | `~/.pi/agent/skills/<name>` → links into `skills/` | `bash scripts/install.sh` |

Verify which channel owns pi, and fail the build when both are present:

```bash
bash scripts/verify-distribution.sh --strict
# or: bash scripts/install.sh --verify
```

Acceptance line for a clean install: `pi` starts with `bigpowers: 80 skills
loaded` and **zero** skill warnings, collisions, or ignored settings.

A pending pi package update renders as `Package Updates Available` in the pi
banner; refresh with `pi update --extensions`. That banner is pi reporting a
stale pin, not a bigpowers defect.
