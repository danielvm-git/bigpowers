# ADR-0007: Single AGENTS.md Spine with Tool-Specific Context Derivatives

**Status:** Accepted
**Date:** 2026-07-06
**Epic:** e37 (Reach — Universal Agent Portability)

## Context

Before e37, bigpowers maintained multiple tool-specific context files:
- `CLAUDE.md` — operational root doc for Claude Code (also read by Cursor)
- `GEMINI.md` — root doc for Gemini CLI
- `opencode.json` — OpenCode configuration
- `.aider.conf.yml` — Aider bridge configuration

Each was written independently, causing drift between files, unclear ownership, and
maintenance burden. Users running multiple agent tools (e.g., Cursor + Cline + Aider)
needed duplicate setup steps.

The epic redesign (2026-07-06) merged e50 (AGENTS.md spine) and e52 (Integration Registry)
into one portability arc. The convergence question was: should bigpowers maintain N context
files (one per tool) or converge on a single source of truth?

## Options Considered

### Option A: Multi-file (status quo ante)
- Each tool gets its own context file (CLAUDE.md, GEMINI.md, etc.)
- Each file contains the same bigpowers instructions in different formatting
- Pro: Familiar to users of each tool
- Con: Drift, maintenance burden, inconsistent coverage, higher cognitive load for multi-tool users

### Option B: Single AGENTS.md spine with symlink derivatives (selected)
- One `AGENTS.md` is the canonical source of truth
- Tool-specific files (`CLAUDE.md`, `GEMINI.md`, etc.) become symlinks to AGENTS.md
- Tools that read AGENTS.md natively get no derivative (Cline, native AGENTS.md readers)
- Tools requiring a config bridge get `.aider.conf.yml` pointing at AGENTS.md
- Declared in `scripts/targets.yaml` per target via `context.mode`

### Option C: Single AGENTS.md spine with content-copy derivatives
- Same single source as Option B
- But copies the file content rather than symlinking
- Pro: Works on Windows without Developer Mode; survives file moves
- Con: Drift possible if copy is not refreshed; hash-based matrix check needed

## Decision

Adopt **Option B** as the primary strategy with **Option C as fallback**:

1. `AGENTS.md` is the single canonical source for all bigpowers instructions.
2. Tool-specific context files are **Context Derivatives** — generated artifacts, not sources.
3. Default mode is **symlink** (`AGENTS.md` → `CLAUDE.md` on POSIX).
4. **copy fallback** when symlink fails (Windows without Developer Mode, CI sandboxes).
5. `context.mode` in `targets.yaml` declares per-target strategy:
   - `native` — tool reads AGENTS.md directly (no derivative)
   - `symlink` — create symlink to AGENTS.md
   - `copy` — content copy of AGENTS.md
   - `config-bridge` — write config file referencing AGENTS.md
6. The Integration Registry (`scripts/targets.yaml`) is the single source for which
   derivatives exist, using which mode.

## Consequences

### Positive
- Single source of truth — no drift between CLAUDE.md and GEMINI.md
- New tool integration = one registry row, not a new context file
- `generate-context-bundle.sh` regenerates all derivatives from one command
- `verify-install.sh --matrix` detects drift via hash comparison
- Multi-tool users get consistent instructions across all tools

### Negative
- Symlinks break on Windows without Developer Mode — mitigated by copy fallback
- Tools that don't follow symlinks (some CI sandboxes) need explicit copy mode
- Legacy users expecting `CLAUDE.md` may be confused (mitigated by CLAUDE.md symlink)
- `open code` command in some editors may not follow symlinks

### Migration
- Old `CLAUDE.md` content moves to `AGENTS.md` as canonical source
- `CLAUDE.md` becomes a Context Derivative (managed symlink)
- `seed-conventions` emits AGENTS.md from `docs/templates/AGENTS.md`
- `verify-install.sh` asserts AGENTS.md shape (Preflight row, multi-agent preamble, etc.)
- All existing consumers (CI scripts, hooks, docs) that read CLAUDE.md continue to work via symlink

## References
- epic.yaml (e37 Reach — Universal Agent Portability)
- docs/templates/AGENTS.md (canonical template)
- scripts/targets.yaml (Integration Registry — target declarations)
- scripts/lib/context-wire.sh (symlink_or_copy implementation)
- specs/tech-architecture/tech-stack.md § Reach Domain (invariants 13–25)
