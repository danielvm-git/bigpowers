# Refactor Plan — Cross-Tool Skill Distribution (install.sh + seed-conventions)

## Problem Statement

bigpowers already ships a working global installer (`scripts/install.sh`, invoked via
`bigpowers setup`) that symlinks all 73 skills into `~/.claude/skills/` (Claude Code)
and `~/.gemini/extensions/bigpowers` (Gemini CLI) once per machine — no per-project
step needed, "type `/` and see bigpowers skills" already works for those two tools
today.

But the distribution story is inconsistent and incomplete:

- **pi has zero coverage.** Users currently have to run `pi install npm:bigpowers`
  manually per project. Source-verified (`packages/coding-agent/src/core/skills.ts` +
  `config.ts` in `earendil-works/pi`): pi already reads a **global** user-skills
  directory at `~/.pi/agent/skills/` (`getAgentDir()` → `~/.pi/agent`, `CONFIG_DIR_NAME
  = ".pi"`) the exact same way Claude Code reads `~/.claude/skills/`. There's no
  reason pi should need a separate per-project install step when the same global
  pattern already works.
- **`install_opencode()` in install.sh is dead weight for real installs.** It writes
  `opencode.json` into `$REPO_ROOT`, which for a real `npm install -g bigpowers`
  consumer resolves to the global `node_modules/bigpowers` directory — not any
  location OpenCode's project-root-scoped config loader (confirmed in
  `docs/references/agent-config-files-and-okf.md` row 17) will ever read. It only
  "works" when someone runs `bigpowers setup` from inside a git clone of bigpowers
  itself.
- **A prior design conversation proposed extending `seed-conventions`** (the
  per-project scaffolding skill) to copy `.pi/skills/` and create per-project
  `.claude/skills/`, `.agents/skills/`, `.continue/rules/` symlinks in every new
  project. That duplicates what `install.sh`'s global mechanism already does for
  Claude Code, and — per `docs/references/agent-config-files-and-okf.md` (already
  committed, source-verified) — most of the other tools in that list (Cline, Roo
  Code, Continue, Aider, Amazon Q, Codex CLI, Windsurf, Lovable, Kiro) don't have a
  discrete invokable skill/slash-command system at all. They're instruction-file or
  rules-directory tools (always-on context), not skill catalogs. Building
  skill-symlink infrastructure for them solves a problem they don't have.

## Solution

Two mechanisms, two clearly separated jobs, no duplication:

1. **`install.sh` (global, once per machine)** — extend the existing per-skill
   symlink pattern to pi (`~/.pi/agent/skills/<name>` → source skill dir), and remove
   the broken `install_opencode()` step since it has no real target.
2. **`seed-conventions` (local, once per project)** — gains one new *optional*
   interview step for the two tools whose config is structurally per-project only,
   and therefore genuinely can't be solved by a global installer: Cursor (a global
   `~/.cursor/rules` symlink exists today, but Cursor doesn't scan it — install.sh
   already prints a manual per-project instruction for this) and OpenCode (project-
   root scoped by design). This step stays opt-in, matching the earlier
   already-settled decision that generating 70+ tool-specific files unconditionally
   in every project is context bloat.
3. **Everyone else (Cline, Roo Code, Continue, Codex CLI, Aider, Amazon Q, GitHub
   Copilot, Windsurf, Lovable, Kiro)** gets nothing new here — they're already served
   by `seed-conventions`'s existing AGENTS.md/CLAUDE.md generation, which is the only
   thing they read. No skill-symlink work needed or possible.
4. **Gemini CLI** — no new work. Already correctly handled globally and
   source-verified; the user confirmed it's being deprecated soon, so no further
   investment is justified.
5. **AGY (Antigravity CLI)** — explicitly excluded. Its GitHub repo contains no
   source (docs/examples only, closed-source binary); its config format is
   unverifiable. Not built against a guess.

## Commits

1. Add `scripts/verify-install.sh` — a dry-run assertion harness that captures
   *current* behavior only (Claude Code, Gemini, Cursor symlink lines + the existing
   `opencode.json` line) before anything changes. This is the "document current
   behavior" baseline required before refactoring it.
   → verify: `bash scripts/verify-install.sh`

2. Remove the `install_opencode()` call from install.sh's main install/uninstall
   dispatch (delete the function and its `print_opencode_instructions` companion if
   unused elsewhere). It writes into `$REPO_ROOT`, which for a real global npm
   install is the package's own `node_modules` path — not a location OpenCode reads.
   Update `verify-install.sh` to drop the now-removed assertion.
   → verify: `bash scripts/install.sh --dry-run` shows no opencode.json step; `bash scripts/verify-install.sh`

3. Add `install_pi()` / `uninstall_pi()` to install.sh: per-skill symlinks
   `~/.pi/agent/skills/<name>` → `$SKILLS_ROOT/<name>`, mirroring the exact pattern
   `install_claude()` already uses for `~/.claude/skills/<name>`. Wire both into the
   main install/uninstall dispatch blocks alongside `install_claude`.
   → verify: `bash scripts/install.sh --dry-run | grep -A3 "pi →"`

4. Extend `verify-install.sh` to assert the new pi symlinks appear in dry-run output
   (one per skill, matching the skill count already asserted for Claude Code).
   → verify: `bash scripts/verify-install.sh`

5. Update `docs/references/agent-config-files-and-okf.md`: add a short "skill-catalog
   vs instruction-only" distinction — Claude Code and pi are skill-catalog tools
   (discrete invokable SKILL.md units); every other tool in the table is
   instruction-file/rules-directory only (always-on context, no per-skill
   invocation). This becomes the authoritative scoping reference so a future
   contributor doesn't re-propose per-skill symlinks for tools that structurally
   can't use them.
   → verify: manual review (`bts read docs/references/agent-config-files-and-okf.md`)

6. Update `skills/seed-conventions/SKILL.md`: add one optional interview step —
   "local tool wiring" — offered after the standard interview, covering only Cursor
   (project-local `.cursor/rules` symlink) and OpenCode (project-local `AGENTS.md` +
   `opencode.json`), since those are the two tools install.sh's global mechanism
   structurally cannot reach. Keep it opt-in per the interview, not automatic.
   → verify: `bts find --print "local tool wiring" skills/seed-conventions/SKILL.md`

7. Update `skills/seed-conventions/REFERENCE.md`: add the "local tool wiring"
   templates — the Cursor symlink command (identical to the instruction install.sh
   already prints today) and the corrected project-local `opencode.json` +
   `AGENTS.md` content (adapted from the old, now-removed, broken install.sh step).
   → verify: manual review (`bts read skills/seed-conventions/REFERENCE.md`)

8. Run `bash scripts/sync-skills.sh` to regenerate the derived artifacts
   (`.cursor/rules/seed-conventions.mdc`, `.gemini/extensions/bigpowers/skills/seed-conventions/`,
   `.pi/skills/seed-conventions/`, `.pi/prompts/seed-conventions.md`) from the updated
   SKILL.md source. Mechanical — required by CONVENTIONS.md after any SKILL.md edit.
   → verify: `git diff --stat -- .cursor/rules/seed-conventions.mdc .pi/skills/seed-conventions .gemini/extensions/bigpowers/skills/seed-conventions`

9. Extend `verify-install.sh` with a smoke test that runs the new seed-conventions
   local-wiring templates against a scratch tmp directory and asserts the
   `.cursor/rules` symlink and `opencode.json`/`AGENTS.md` are created with the
   expected content.
   → verify: `bash scripts/verify-install.sh`

10. Run the full pre-merge checklist.
    → verify: `npm run compliance && bash scripts/run-golden-suite.sh`

## Decision Document

- `install.sh` gains `install_pi()`/`uninstall_pi()`, symmetric with the existing
  `install_claude()`/`uninstall_claude()` pair — same per-skill-directory symlink
  strategy, same managed-uninstall safety check (`unlink_if_managed`, which only
  removes symlinks whose target is under `$REPO_ROOT/`, so it never touches a user's
  own personal pi skills).
- Target path `~/.pi/agent/skills/<name>` is source-verified against pi's
  `core/skills.ts` (`loadSkills` reads `join(resolvedAgentDir, "skills")` when
  `includeDefaults` is set) and `config.ts` (`getAgentDir()` defaults to
  `~/.pi/agent`, `CONFIG_DIR_NAME = ".pi"`) — not a guess from documentation alone.
- `install_opencode()` is deleted, not relocated in place — its responsibility moves
  entirely to `seed-conventions`'s new local-wiring step, because OpenCode config is
  project-root scoped by design; there is no global location for install.sh to
  target.
- `seed-conventions`'s new interview step is additive and optional — it does not
  change the three files (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`) or the `specs/`
  scaffolding it already generates unconditionally today.
- No new skill-distribution mechanism is built for Cline, Roo Code, Continue, Codex
  CLI, Aider, Amazon Q, GitHub Copilot, Windsurf, Lovable, or Kiro. Per
  `docs/references/agent-config-files-and-okf.md`, none of them expose a discrete
  skill/slash-command system — they read a single instruction file or a rules
  directory, always-on. That's already `seed-conventions`'s existing job via
  `AGENTS.md`.
- Gemini CLI and AGY receive no new work — Gemini CLI is already correctly handled
  and slated for deprecation per the user; AGY's config format is unverifiable
  (closed-source repo, docs/examples only).

## Testing Decisions

- This project has no automated test suite (Markdown/Bash, per CLAUDE.md) and no
  existing coverage for `install.sh` or `seed-conventions` (confirmed — no script or
  test file references either).
- New coverage is a manual verification script, `scripts/verify-install.sh`, run by
  hand after each relevant commit — matching the project's existing convention of
  standalone bash gate scripts (`scripts/validate-specs-yaml.sh`,
  `scripts/validate-okf.sh`, `scripts/validate-doctrine.sh`), all of which assert
  structural/observable outcomes and exit non-zero on failure. This script is prior
  art for the new one's shape.
- A good test here asserts **observable output** of `install.sh --dry-run` (which
  symlinks it reports) and of running `seed-conventions`'s new templates against a
  scratch directory (which files/symlinks land on disk) — never the internals of the
  bash functions producing them.
- Not wired into CI; kept as an explicit manual step per the user's choice, consistent
  with how the rest of the project's gates are invoked (`npm run compliance`, golden
  suite) rather than auto-run on every commit.

## Out of Scope

- Any new symlink/copy mechanism for Cline, Roo Code, Continue, Codex CLI, Aider,
  Amazon Q, GitHub Copilot, Windsurf, Lovable, or Kiro. They have no discrete skill
  system to target; improving their AGENTS.md/CLAUDE.md content quality is
  `seed-conventions`'s existing, unrelated job.
- AGY / Antigravity CLI support of any kind — unverifiable, closed-source.
- Flipping the canonical-file direction (making `AGENTS.md` the single source with
  `CLAUDE.md` symlinked to it, per `docs/references/agent-config-files-and-okf.md`'s
  own "Key takeaway" recommendation). `seed-conventions` currently generates three
  separate literal files; changing that to a symlink model is a bigger, separate
  decision not requested here.
- Adding CI wiring for `verify-install.sh` — kept manual per the user's explicit
  choice.
- Any other latent install.sh issues unrelated to pi/OpenCode (e.g., the Cursor
  global-symlink-doesn't-scan note is left exactly as-is; guard-git hook wiring is
  untouched).

## Further Notes

- The bigpowers repo's own root `CLAUDE.md` and `GEMINI.md` are two separate real
  files (14 KB / 3.7 KB, not symlinked) — which itself doesn't follow the
  "AGENTS.md canonical, others symlinked" recommendation the project just documented
  in `docs/references/agent-config-files-and-okf.md`. Worth a future decision;
  explicitly out of scope here.
- The bigpowers repo has no root `AGENTS.md` at all today, meaning pi/Cline/Codex CLI
  reading this repo itself (not a project it seeded) get no project instructions
  currently. Flagged, not fixed here — belongs to a future "run seed-conventions on
  bigpowers itself" task.
- `bin/bigpowers.js`'s `status` command counts symlinks under `~/.claude/skills`
  only. After commit 3 it will undercount (doesn't know about the new
  `~/.pi/agent/skills` symlinks). Cosmetic; reasonable fast-follow, not included in
  this refactor's commit list.

