---
name: organize-workspace
model: haiku
description: Scans the active workspace for disposable artifacts—logs, caches, stale build output, and stray draft markdown—and proposes consolidation of scattered assets. Produces a reviewable list, asks for explicit confirmation before any delete or move, and optionally revises .gitignore. Use when the user says "clean my room", "organize workspace", "workspace cleanup", "remove temp files", "organize assets", "gitignore", or wants a safe tidy pass.
---

# Organize Workspace
> **HARD GATE** — **HARD GATE** — Workspace structure must reflect domain structure. If the codebase feels disorganized, flag it. Disorganization != 'just a style thing;' it is a signal of domain misalignment.


## Principles

- **Read-only first**: inventory and size (`du`, `ls -la`) before any change.
- **Never delete or move** without a numbered list and **explicit user approval** (item-level or "approve all").
- **Prefer `fd` / `ripgrep` / `find`** in that order; avoid blind `rm -rf` on vague globs.
- **Do not** touch `.git/`, `node_modules/`, `venv/`, `.env*`, or SSH keys; flag them only if the user asked about them.
- Confirm prompts in the **user's language** if they are not writing in English.

## 1. Establish scope

- Default: **current project root** (where the user is working) or the path they name.
- Record OS (macOS vs Linux) for ignore patterns (e.g. `.DS_Store`).

## 2. Classify candidates (scan)

Group findings under these **buckets**:

| Bucket | Examples | Typical action |
|--------|----------|----------------|
| **Logs & temp** | `*.log`, `logs/`, `tmp/`, `temp/`, `*.pid` | Delete after confirm |
| **Build / cache** | `dist/`, `build/`, `.next/`, `coverage/`, `.turbo/` | Delete if rebuildable |
| **Package caches** | root `.cache/`, `__pycache__/` | Offer delete |
| **Stray drafts** | root-level `*.md` named `draft`, `scratch`, `temp` | User picks: delete, move to `specs/`, or keep |
| **Duplicate / dump dirs** | `old/`, `backup/`, `copy/`, `*_backup` | List + ask |

Use quick size hints: `du -sh` per top-level dir; sort large items first.

## 3. Assets & data (organize, not only delete)

If the user wants **organization**:

1. Propose a **single convention**, e.g.:
   - `assets/` — images, fonts, static media
   - `data/` — JSON, CSV, fixtures, samples
   - `specs/` — all planning and domain documents
2. For each cluster of loose files, suggest **one target path** and a short rationale.
3. Use **git-aware moves** when in a repo: `git mv` if tracked; otherwise `mv` and report.
4. Never move secrets or production DB dumps into `docs/` or public `assets/`.

## 4. Present the plan

Output a table or numbered list:

- Path
- Kind (log / build / draft / asset / other)
- Approx size
- Proposed action: **delete** | **move to …** | **keep**

Ask: *"Delete items 1–3? Move 4–5? Skip 6?"*

## 5. Execute after approval

- Deletes: on macOS, prefer a Trash-capable tool (e.g. `trash` from Homebrew) if installed; else `rm` with paths echoed back.
- Moves: create dirs with `mkdir -p` first; one batch at a time.
- **Verify**: re-run listing on affected parents; if anything failed, report stderr.

## 6. Post-cleanup and `.gitignore` revision

Do this when the repo is under Git and the cleanup surfaced **untracked** noise:

1. **Inventory ignore sources**: root `.gitignore`, `.git/info/exclude`, any subpackage `.gitignore` files.
2. **Map findings to rules**: for each deleted or recurring artifact class, check whether a pattern already exists; note gaps.
3. **Propose a patch**: list only **concrete** changes — `+` add / `-` remove / `~` reword — with one-line why.
4. **User must approve** the exact diff before editing the file.
5. **Verify**: run `git check-ignore -v <path>` on 2–3 representative paths.

See [REFERENCE.md](REFERENCE.md) for shell patterns, `.gitignore` mechanics, and safety checks.
