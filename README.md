# bigpowers

**38 agent skills for spec-driven, TDD-first software by solo developers.**

Every skill is a two-word verb-noun pair (Uncle Bob / Clean Code naming). Every skill that produces output writes to `specs/` at your project root — spec-driven development before any code is written.

Works with: **Claude Code · Gemini CLI · Cursor · OpenCode**

---

## Lifecycle Workflow

![bigpowers Workflow](specs/assets/bigpowers-workflow.svg)

---

## Skill Index

| Phase | Skill | What it does |
|-------|-------|-------------|
| Bootstrap | `using-bigpowers` | Lifecycle overview; where to start |
| Discover | `survey-context` | Reads specs/, maps phase, suggests next skill |
| Discover | `elaborate-spec` | Refines an idea via dialogue (no files written) |
| Design | `model-domain` | Domain model → specs/CONTEXT.md + specs/adr/ |
| Design | `define-language` | Ubiquitous language → specs/UBIQUITOUS_LANGUAGE.md |
| Design | `grill-me` | Challenges assumptions one question at a time |
| Design | `grill-with-docs` | grill-me grounded in real library/API docs |
| Design | `deepen-architecture` | Architecture depth → updates specs/CONTEXT.md |
| Design | `design-interface` | API shape via parallel subagent proposals |
| Plan | `scope-work` | Feature scope → specs/SCOPE.md |
| Plan | `slice-tasks` | Task breakdown → specs/TASKS.md |
| Plan | `define-success` | Converts task to step → verify pairs |
| Plan | `plan-work` | Implementation plan → specs/PLAN.md |
| Plan | `plan-refactor` | Refactor plan → specs/REFACTOR.md |
| Initiate | `kickoff-branch` | Creates git worktree + feature branch |
| Initiate | `guard-git` | Installs destructive-git pre-command hook |
| Initiate | `hook-commits` | Installs pre-commit (lint/format/typecheck/test) |
| Initiate | `seed-conventions` | Generates CLAUDE.md + CONVENTIONS.md + specs/ |
| Spike | `spike-prototype` | Throwaway spike → specs/SPIKE-name.md |
| Execute | `develop-tdd` | Red → green → refactor, one behavior at a time |
| Execute | `enforce-first` | F.I.R.S.T rubric check (sub-skill of develop-tdd) |
| Execute | `delegate-task` | One subagent task with two-stage review |
| Execute | `dispatch-agents` | Parallel independent subagents |
| Execute | `execute-plan` | Runs specs/PLAN.md step by step |
| Harden | `wire-observability` | Structured JSON logging + idempotent setup |
| Bug | `investigate-bug` | Root cause investigation → specs/DIAGNOSIS.md |
| Bug | `diagnose-root` | 4-phase: reproduce → isolate → hypothesize → verify |
| Bug | `validate-fix` | Re-runs suite + typecheck + lint; updates DIAGNOSIS.md |
| Review | `audit-code` | Self-review against CONVENTIONS.md + SOLID |
| Review | `request-review` | Fresh reviewer agent with clean context |
| Review | `respond-review` | Categorizes findings; applies must-fix |
| Integrate | `commit-message` | Conventional Commits message + semver prediction |
| Integrate | `release-branch` | gh pr create + coverage gates + worktree cleanup |
| Sustain | `inspect-quality` | Structured audit → specs/BUG-LOG.md |
| Sustain | `organize-workspace` | Classify → show → confirm → execute |
| Utility | `terse-mode` | Token-saving fallback (context critically long) |
| Utility | `craft-skill` | Build a new bigpowers skill |
| Utility | `edit-document` | Restructure a doc in specs/ |

---

## Install

### 1. Clone

```bash
git clone https://github.com/danielvm-git/skills ~/Developer/bigpowers
cd ~/Developer/bigpowers
```

### 2. Generate tool artifacts

```bash
./scripts/sync-skills.sh
```

This generates `.cursor/rules/*.mdc` and `.gemini/extensions/bigpowers/` from the SKILL.md source files.

### 3. Install globally

```bash
./scripts/install.sh
```

What this does:

| Tool | Install path | Mechanism |
|------|-------------|-----------|
| **Claude Code** | `~/.claude/skills/<name>/` | symlink per skill |
| **Gemini CLI** | `~/.gemini/extensions/bigpowers/` | symlink to generated dir |
| **Cursor** | `~/.cursor/rules/` | symlink to generated dir (see note) |
| **OpenCode** | your project's `opencode.json` | manual (see below) |

**Cursor note:** Cursor does not scan `~/.cursor/rules/` globally. For per-project access, run this once in your project root:

```bash
ln -sfn ~/Developer/bigpowers/.cursor/rules .cursor/rules
```

**OpenCode:** Add to your project's `opencode.json`:

```json
{
  "rules": ["~/Developer/bigpowers/.cursor/rules/**/*.mdc"]
}
```

Or symlink the same Cursor rules directory into your project (same command as above).

### 4. Preview before installing

```bash
./scripts/install.sh --dry-run
```

### 5. Uninstall

```bash
./scripts/install.sh --uninstall
```

---

## Update

```bash
git pull && ./scripts/sync-skills.sh
```

That's it. Symlinks mean changes propagate to every tool automatically — no re-install needed.

---

## specs/ — Spec-Driven Development

All skills write output to `specs/` at **your project root** (not this repo).

| Document | Path |
|----------|------|
| Domain context + ADRs | `specs/CONTEXT.md` + `specs/adr/` |
| Domain glossary | `specs/UBIQUITOUS_LANGUAGE.md` |
| Scope definition | `specs/SCOPE.md` |
| Task breakdown | `specs/TASKS.md` |
| Implementation plan | `specs/PLAN.md` |
| Refactor plan | `specs/REFACTOR.md` |
| Spike learnings | `specs/SPIKE-<name>.md` |
| Bug investigation | `specs/DIAGNOSIS.md` |
| QA audit log | `specs/BUG-LOG.md` |

Run `seed-conventions` to create the `specs/` directory and generate starter `CLAUDE.md` + `CONVENTIONS.md` files in a new project.

---

## Install artifacts

The four AI config files at the repo root are **templates** — copy them into your project and fill in the placeholders:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code project config (stack, commands, architecture) |
| `GEMINI.md` | Gemini CLI project config (same structure) |
| `AGENTS.md` | OpenAI Agents / Codex project config |
| `CONVENTIONS.md` | Code, test, git, and specs/ conventions for all agents |

---

## Source of truth

Each skill lives in its own directory as `SKILL.md`. Support docs (reference sheets, format templates, examples) live alongside it. `sync-skills.sh` concatenates everything and generates the Cursor and Gemini artifacts — you never edit `.cursor/rules/` or `.gemini/extensions/` by hand.

```
bigpowers/
├── <skill-name>/
│   ├── SKILL.md           ← source of truth
│   └── *.md               ← optional support docs
├── .cursor/rules/         ← generated by sync-skills.sh
├── .gemini/extensions/bigpowers/
│   ├── gemini-extension.json   ← generated
│   └── commands/               ← generated
├── scripts/
│   ├── sync-skills.sh     ← generate Cursor + Gemini artifacts
│   └── install.sh         ← global symlink install / uninstall
├── CLAUDE.md / GEMINI.md / AGENTS.md / CONVENTIONS.md
└── skills-lock.json
```

---

## License

MIT
