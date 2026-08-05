# Agent Code Economy — the "8 rules" AGENTS.md pattern

<!-- story: e81s01 -->

**Source:** [X post — @ayi_ainotes](https://x.com/ayi_ainotes/status/2084522269745820010)
**Origin:** A Vercel Next.js engineer burned ~60B tokens (~six-figure USD) building with AI coding agents, then distilled the lesson into an 8-rule AGENTS.md.
**Warning:** The author states the rules suit **side projects**. Rule 1 once nearly deleted a production database table (~$2000 of data).

## The 8 rules

| # | Rule | Production-safe in bigpowers? |
|---|------|-------------------------------|
| 1 | No backward compatibility — delete, no compat layers, no migrations, no fallbacks | **No — excluded deliberately** (see warning) |
| 2 | Simplest implementation for current needs — no preventive abstraction, no extra config layers | Yes |
| 3 | Vertical-slice-first — run a minimal end-to-end version, then add; never dismantle working code for unfinished complexity | Yes |
| 4 | Modular components, separation of concerns | Yes |
| 5 | Prefer mature, maintained libraries — no self-rewrites without a clear reason | Yes |
| 6 | Check existing dependencies first — before adding packages or writing your own | Yes |
| 7 | Long-term architecture decisions — no "fix later" temporary solutions | Yes |
| 8 | Copy validated patterns — study how mature products solve the same problem before inventing | Yes |

## Codified in bigpowers

| Rule | bigpowers encoding |
|------|--------------------|
| 2 | CLAUDE.md §Agent Rules "minimum code"; AGENTS.md template §Token Economy; CONVENTIONS.md §Code Style |
| 3 | `slice-tasks` (vertical-slice stories); `develop-tdd` (vertical slices) |
| 4 | CONVENTIONS.md §Code Style (SRP, 300-line caps, Stepdown Rule) |
| 5 | `research-first` prior art; AGENTS.md template §Token Economy (e81s01) |
| 6 | AGENTS.md template §Token Economy (e81s01); `opensrc` skill reads existing dependency source |
| 7 | `specs/adr/` ADRs; `model-domain`; `deepen-architecture` |
| 8 | `research-first`; `docs/references/` upstream distillations (fowler, karpathy, kent-beck) |

## Production warning → bigpowers countermeasures

Rule 1 is the one the author warns about. bigpowers inverts it by design:

- **Tombstone aliases** (e53s02) — renamed skills keep a one-release stub instead of breaking consumers.
- **Semantic-release** — breaking changes bump the major version deliberately, never silently.
- **Migration registry** — `specs/migrations/` tracks schema/data migrations instead of skipping them.
- **ADRs** — architecture changes get a recorded decision, not a silent "change it later".
- **Always Green** — Preflight/CI gate merges; data-loss risks are caught before landing.

## Why it saves tokens

AI's biggest waste is not writing wrong code — it is writing too much: three dependencies and five abstraction layers for a standard-library ten-liner. The 8 rules constrain the agent *before* it writes. bigpowers pairs this with after-the-fact compression (RTK, sqz, context-engineering write/select/compress/isolate).
