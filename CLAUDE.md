# story: e38s08
# story: e51s05
# story: e45s22
# story: e45s23
# story: e55s03

# bigpowers — Claude Code

Read CONVENTIONS.md before any GitHub or git operation.

[`constitution.md`](constitution.md) is a consolidated entry point synthesizing
this project's doctrine (this file, CONVENTIONS.md, docs/PRINCIPLES.md,
docs/references/*.md) into bigspec's B0-B10 + Capstone blocks, with citations
back to the fuller text. It's a starting point for a reader, not a
replacement — this file remains fully authoritative for its own content today.

<!-- BEGIN bigpowers:context-routing -->
## Context Routing

Load subdirectory context **by file glob** — do not read the full doc tree up front.

| Glob / trigger | Load first | Fallback |
|----------------|------------|----------|
| `skills/**` | Active skill's `SKILL.md` + sibling `REFERENCE.md` if linked | `SKILL-INDEX.md` |
| `specs/epics/**` | Capsule `epic.yaml` + active story `-tasks.yaml` | `specs/release-plan.yaml` |
| `specs/product/**` | `SCOPE_LATEST.yaml`, `VISION_LATEST.yaml` | `specs/README.md` |
| `specs/tech-architecture/**` | `tech-stack.md` + epic `eNN-TEST_PLAN_LATEST.md` if present | `CONVENTIONS.md` |
| `scripts/**` | `CONVENTIONS.md` § Generated artifact targets | This file § Commands |
| `website/**` | `website/README.md` if present | Never edit `website/src/content/docs/` (generated) |
| `docs/**` | Matching doc under `docs/` | `docs/references/` |
| Default / session start | This file → `CONVENTIONS.md` → `specs/state.yaml` | `survey-context` |

Sub-AGENTS.md files (when present in consumer projects) override this table for their directory only.
<!-- END bigpowers:context-routing -->

<!-- BEGIN bigpowers:learned-preferences -->
## Learned User Preferences

_Durable preferences discovered across sessions. Update via `session-state` — do not infer from chat alone._

- Prefer `rtk`-prefixed shell commands for git, test, and build output (token savings).
- Run Preflight before forward work; never dismiss red gates as pre-existing.
- Edit `skills/*/SKILL.md` sources only — never `.cursor/rules/` or `.gemini/` artifacts.

## Workspace Facts

_Stable repo facts — prefer these over re-discovery._

- Stack: Markdown / Bash documentation project; skills sync via `bash scripts/sync-skills.sh`.
- Planning SoT: `specs/state.yaml`, `specs/release-plan.yaml`, `specs/execution-status.yaml`.
- Story traceability: `# story: eNNsNN` tags in implementing files; `bash scripts/trace-stories.sh --strict` in CI.
- Rule matrix: `bash scripts/compile-rule-matrix.sh` → `specs/rule-matrix.json` (P0–P3 tiers from CONVENTIONS.md).
<!-- END bigpowers:learned-preferences -->

## Project

bigpowers — agent skills for spec-driven, test-first software development by solo developers (skill count and catalog are auto-generated in `SKILL-INDEX.md`; never hardcode the count in docs).
Stack: Markdown / Bash (documentation-based; skills integrate with Claude Code, Cursor, Gemini CLI)

## Commands

| Action  | Command |
|---------|---------|
| Install | `npm install -g bigpowers && bigpowers setup` |
| Run     | `bash scripts/sync-skills.sh` |
| Test    | N/A (documentation project) |
| Build   | `bash scripts/install.sh` (from source) |
| Lint    | `bash scripts/sync-skills.sh` (validates SKILL.md syntax) |
| Validate specs YAML | `bash scripts/validate-specs-yaml.sh` |
| Typecheck | N/A (Markdown / Bash project) |
| CI platform | GitHub Actions (`.github/workflows/publish.yml`, `sync-skills.yml`, `golden-suite.yml`) |
| Compliance | `npm run compliance` |
| Verification Gates | `bash scripts/run-verification-gates.sh` |
| Traceability | `bash scripts/trace-stories.sh --strict` | grep for story tags (traceability check) |
| Preflight | `npm run compliance && bash scripts/run-verification-gates.sh && bash scripts/sync-skills.sh && bash scripts/trace-stories.sh --strict` | Full local green stack before forward work. Chain ends on `--strict` traceability — no trailing always-exit-0 step. |
| Catalog drift (advisory) | `bash scripts/check-catalog-drift.sh` | e54s02 Confirm gate during catalog freeze — always exits 0; run manually when changing skills, not part of Preflight. |
| CI | `gh pr checks` | Remote CI green when a PR is open |

### Pre-Merge Checklist

Before opening a PR or landing a branch, run:

```bash
npm run compliance && bash scripts/run-verification-gates.sh
```

If any gate fails, fix before merging. Run `--baseline` after any intentional increase in skill count or structure.

**BCP Plus:** For stories sized with the 13-dimension BCP Plus methodology, confirm the `bcp_plus_breakdown` is present in the epic YAML and carried into `state.yaml` as `epic_cycle.bcp_plus`. See `docs/references/bcp-plus.md` for the NFR Gate pattern.

## Architecture

Collection of verb-noun skills under `skills/`, each with a SKILL.md source file and supporting documentation. Runtime specs live in `specs/state.yaml`, `specs/release-plan.yaml`, and `specs/execution-status.yaml`; intent in `specs/product/`; epic shards in `specs/epics/`. The sync-skills.sh script auto-generates artifacts for Cursor (.cursor/rules) and Gemini CLI (.gemini/extensions/bigpowers/) from SKILL.md sources. All planning output goes to specs/ at the project root.

## Conventions

- Skill directories under `skills/` use verb-noun naming (two words, kebab-case)
- Every skill has a single SKILL.md file as its source of truth
- All planning/spec output goes to specs/ at project root
- Artifacts in .cursor/rules and .gemini/ are auto-generated; edit SKILL.md, not artifacts
- Run sync-skills.sh after any SKILL.md changes to regenerate artifacts
- Website content in website/src/content/docs/ is auto-generated by prebuild; edit repo sources, not site files

## Never

- Never edit .cursor/rules or .gemini/extensions/ directly — these are generated files
- Never edit website/src/content/docs/ directly — these are generated files; website/ is the fourth generated artifact target (alongside .cursor/, .gemini/, .pi/)
- Never create a skill without a SKILL.md file and proper verb-noun naming
- Never push changes without running sync-skills.sh first

## Token Management

**Mechanical backstop (e45s03):** `scripts/hooks/token-mgmt-pre-tool-use.sh` blocks oversized tool calls when prose rules are ignored. Wire as a `PreToolUse` hook for `Read`, `Grep`, and `Bash` (alongside `hooks/pre-tool-use.sh` for git safety). Thresholds: Read >100KB, Grep >200 matches without `head_limit`, Bash commands likely to exceed 500 output lines without `rtk`/`sqz compress`. Install snippet:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read|Grep|Bash", "hooks": [{ "type": "command", "command": "bash scripts/hooks/token-mgmt-pre-tool-use.sh" }] }
    ]
  }
}
```

Context engineering (write/select/compress/isolate — see `docs/references/context-engineering.md`):

- **Write (token-efficient content):** Short functions (4-20 lines), unique symbol names, headless tests. Don't restate code in comments.
- **Select (include only what's relevant):** Use `bts_map` for ranked file lists, `survey-context` for phase bootstrap. Don't read files you don't need.
- **Compress (reduce without losing structure):** Use `bts_compress` or pipe through `sqz compress`. Use `rtk` for build/test/git output (60-99% savings). Prefer `terse-mode` when context is heavy.
- **Isolate (partition work):** Use `kickoff-branch` for isolated worktrees, `dispatch-agents` for parallel tasks with disjoint scopes, `session-state` for cold-start handoff.

**Effort classification:** Skills carry an `effort:` frontmatter field (`light` | `standard` | `heavy`). Prefer `light` skills for bootstrap/status checks; reserve `heavy` for epic builds and multi-phase planning.

- **Auto-Terse**: When a session exceeds 20 turns or the context window feels "heavy" (latency increasing), you MUST switch to `terse-mode` to save tokens.
- **Context Compaction**: Every 10 turns, summarize the current session state and implementation decisions into a short, high-density note.
- **Minimal Output**: Prefer text-only output for simple status; use `web_fetch` or `run_shell_command` only for evidence.
- **Stream Stability**: When writing large files or long documents, output continuously in chunks of ~200 lines. Do not pause. If you need time to process, emit a placeholder comment rather than going silent.

## Session Start

Before any task, run this sequence — not optional:

1. Read `CLAUDE.md` (this file)
2. Read `CONVENTIONS.md`
3. Read `specs/state.yaml` if it exists — current session and active epic
4. Read `specs/release-plan.yaml` if it exists — active release context

## Agent Rules

- **Workflow Mandate:** You MUST use the bigpowers skills (e.g., `plan-work`, `develop-tdd`, `craft-skill`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- **Always Green / fix-or-log:** Preflight and CI must be green before forward work. Any reproducible gate failure during unrelated work requires **quick-fix** or **fix-bug** — see CONVENTIONS § Discovered Defects. Never dismiss failures as pre-existing or out of scope.
- Read specs/ and CONVENTIONS.md before writing code.
- Write the minimum code that solves the stated problem. Nothing extra.
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
- Use `bts docs <lib>` before answering questions about library APIs. Doc fetches use `scripts/lib/doc-fetch-cache.sh` (ETag-revalidated, 300s TTL — see `context7-mcp` skill, e45s20).
- If a tool is missing, say so and run `bts doctor` — do not silently substitute.

<!-- BEGIN rtk-pretooluse-hook (e45s16 — mechanical PreToolUse backstop; remove block to disable) -->

**RTK hook (installed):** `scripts/hooks/rtk-rewrite.sh` is symlinked into `~/.claude/hooks/` by `bash scripts/install.sh` and registered as a Bash `PreToolUse` hook. It delegates to `rtk hook claude` — prose rules below are a fallback only when the hook is absent.

<!-- END rtk-pretooluse-hook -->

<!-- BEGIN sqz-claude-guidance (auto-installed by sqz init; remove this block to disable) -->

## sqz — Context Compression (READ FIRST)

sqz is installed in this project. It compresses tool output so large
files, long logs, and verbose command output cost far fewer tokens.
There are **two ways** sqz is wired in, and you should prefer each
one in the situations below.

### Preferred tools (MCP)

The `sqz-mcp` server is registered in this project's MCP config. It
exposes three read-only tools that compress their output through the
sqz pipeline:

- **`sqz_read_file`** — read a file from disk and return a compressed
  view. **PREFER this over the built-in `Read` tool** for any file
  larger than ~2KB or any file you might read more than once in the
  same session. Repeat reads return a 13-token `§ref:HASH§` reference
  instead of the full content.

- **`sqz_grep`** — search files for a literal string or regex.
  **PREFER this over the built-in `Grep`** for anything that might
  match more than a handful of lines. Caps at 200 matches by default;
  raise with `max_matches` if needed.

- **`sqz_list_dir`** — list a directory. Skips `.git`, `node_modules`,
  `target`, `dist`, `build`, `vendor`, `__pycache__` so the output
  stays focused. **PREFER this over `ls -la` via Bash** when you want
  to see a project layout.

The built-in `Read`, `Grep`, `Glob` tools remain available. Use them for:
- Tiny config files (<1KB) where compression can't help.
- Byte-exact reads you'll hash or diff (lockfiles, signatures).
- Globbing (sqz has no glob tool; `Glob` is still the right choice).

### Bash commands (hooked automatically)

When you run a shell command through the `Bash` tool, a PreToolUse hook
rewrites it to pipe output through `sqz compress`. This is transparent:
you don't need to remember to add anything, but it's useful to know
that these commands get compressed automatically:

```bash
git status           # → git status 2>&1 | sqz compress --cmd git
cargo test           # → cargo test 2>&1 | sqz compress --cmd cargo
docker ps            # → docker ps 2>&1 | sqz compress --cmd docker
kubectl get pods     # → kubectl get pods 2>&1 | sqz compress --cmd kubectl
```

The rewrite is skipped for interactive commands (`vim`, `ssh`,
`python`), compound commands (`a && b`, `a > file.txt`), and anything
already going through sqz.

### Escape hatch — when you see a `§ref:HASH§` token

If tool output contains a `§ref:a1b2c3d4§` token and you need the full
content it points at, resolve it. Three equivalent ways:

- Shell: `/Users/danielvm/.local/bin/sqz expand a1b2c3d4` (or paste the whole token
  `/Users/danielvm/.local/bin/sqz expand §ref:a1b2c3d4§`).
- MCP tool: call `expand` with `{ "prefix": "a1b2c3d4" }`.
- To get uncompressed output for one command: prefix it with
  `SQZ_NO_DEDUP=1` (e.g. `SQZ_NO_DEDUP=1 git log | sqz compress`).

If the compressed output is actively making the task harder (looping
on refs, small retries replacing one big read), call the `passthrough`
MCP tool to get raw text.

### When NOT to use sqz tools

- Writing or editing files — use the built-in `Write`/`Edit` tools.
  sqz has no write tools (by design; see issue #5 follow-up).
- Running commands interactively or in watch mode.
- Reading very small files (<1KB) where compression can't help.

<!-- END sqz-claude-guidance -->

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
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

### Git (59-80% savings)
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

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%). Format flags (-c, -l, -L, -o, -Z) run raw.
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

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
<!-- /rtk-instructions -->