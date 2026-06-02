# Stack Profile: Obsidian Wiki Cockpit

Opt-in profile for solo developers using Karpathy's llm-wiki pattern with bigpowers. Obsidian reads; the LLM maintains `specs/wiki/`.

## When to use

- `specs/` has grown and cold-start navigation is slow
- You want a PM dashboard without duplicating STATE/RELEASE-PLAN checkboxes
- You land branches via solo-git and want one wiki sync at merge time

## 15-minute bootstrap

### 1. Directory tree

```bash
mkdir -p specs/raw/assets specs/wiki/entities specs/wiki/synthesis
```

Copy from bigpowers or create:

- `specs/wiki/WIKI.md` — schema (see bigpowers repo)
- `specs/COCKPIT.md` — Dataview dashboard template
- `specs/raw/README.md` — clip drop zone

### 2. Obsidian vault

1. Install [Obsidian](https://obsidian.md/)
2. **Open folder as vault** → select `<project>/specs`
3. Install community plugin **Dataview**
4. Settings → Files & links → Default location for new attachments → `raw/assets`
5. Pin or set startup note: `COCKPIT.md`
6. `.obsidian/` stays local (add to `.gitignore`)

### 3. COCKPIT.md template

```markdown
# Project Cockpit

![[STATE.md#Current Milestone]]

```dataview
TASK
FROM "STATE.md"
WHERE !completed
```

```dataview
TASK
FROM "RELEASE-PLAN.md"
WHERE !completed
LIMIT 20
```

- [[wiki/index.md|Wiki index]]
- [[wiki/log.md|Wiki log]]
```

### 4. maintain-wiki skill

Install bigpowers (includes `maintain-wiki` after v3.0.0). Read `specs/wiki/WIKI.md` before first sync.

### 5. First sync

After clone or when wiki is empty:

```
maintain-wiki sync
```

→ verify:

```bash
test -f specs/wiki/index.md && test -f specs/wiki/entities/skills-map.md && echo OK
```

### 6. Merge rhythm (solo-git)

Before `release-branch` / `land-branch.sh`:

1. `bash scripts/sync-skills.sh` (if skills changed)
2. `npm run compliance`
3. **maintain-wiki sync**

## Ownership rules

| Path | Who writes |
|------|------------|
| `specs/wiki/**` (except WIKI.md) | LLM only |
| `specs/COCKPIT.md` | Human |
| STATE.md, RELEASE-PLAN.md, ADRs | Skills + human |
| `specs/raw/**` | Human drops; LLM ingests |

**One-way links:** wiki → sources only. Never inject `[[wikilinks]]` into SKILL.md or operational specs.

## Optional modes

| Mode | When |
|------|------|
| **ingest** | New clip in `specs/raw/` |
| **query** | Exploration; file answers to `wiki/synthesis/` |
| **lint** | Monthly or pre-release |

## Never

- Never edit wiki pages in Obsidian (overwritten on sync)
- Never open whole repo as vault unless you accept graph noise — prefer `specs/` root
- Never skip sync before merge if wiki is part of your release gates

## Register in project

Note in `specs/STATE.md` Active Decisions:

```markdown
- **Obsidian wiki profile** active — vault `specs/`, see `profiles/obsidian-wiki.md`
```

## Related

- [`profiles/solo-git.md`](solo-git.md) — integrate without PR ceremony
- [`maintain-wiki/SKILL.md`](../maintain-wiki/SKILL.md) — full skill reference
