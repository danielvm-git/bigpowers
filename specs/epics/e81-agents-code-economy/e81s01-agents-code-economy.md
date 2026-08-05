# e81s01 — Agent code economy: AGENTS.md template + reference doc

**Epic:** e81 | **Story:** e81s01 | **Status:** scoped | **BCPs:** 2

## Goal

Ship the 60B-token "8 rules" AGENTS.md knowledge (Vercel engineer, reported by
X @ayi_ainotes) into bigpowers: (1) a production-safe Token Economy section in
the `seed-conventions` AGENTS.md template, and (2) a distilled reference doc
with the full rules, the codified-in-bigpowers mapping, and the production
warning mapped to bigpowers countermeasures.

## Scope

- `docs/templates/AGENTS.md` — add "Token Economy — Minimal Footprint" section
  inside the `BEGIN/END bigpowers:project` fence. Directives: rules 2 (simplest
  implementation), 5 (prefer mature maintained libraries), 6 (check existing
  dependencies first), 8 (copy validated patterns). Rule 1 (no backward
  compatibility) explicitly excluded with a production-safety note. Prose must
  pass `validate-agentic-ste.sh --strict` (no banned modals, ≤20 words/sentence).
- `docs/references/agents-code-economy.md` — slim provenance-pointer reference:
  source URL, the 8 rules table, codified-in-bigpowers mapping (rule → CLAUDE.md /
  CONVENTIONS.md / skill), production warning → bigpowers countermeasures
  (tombstone aliases e53s02, semantic-release, migration registry, ADRs,
  Always Green).

## Out of scope

- New skills (catalog frozen until e56 unfreezes)
- `research-first` dependency-first checklist (future story)
- Rule 1 adoption in any form
- `docs/AGENTS.md` (root-level legacy template; seed source is
  `docs/templates/AGENTS.md`)

## Acceptance Criteria

1. `docs/templates/AGENTS.md` contains a Token Economy section with rules 2/5/6/8
   as directive lines and an explicit rule-1 exclusion note.
2. The template still passes `bash scripts/validate-agentic-ste.sh --strict docs/templates/AGENTS.md`.
3. `docs/references/agents-code-economy.md` exists, cites the source tweet URL,
   and lists all 8 rules.

## Verify

```bash
grep -q 'Token Economy' docs/templates/AGENTS.md &&
bash scripts/validate-agentic-ste.sh --strict docs/templates/AGENTS.md &&
test -f docs/references/agents-code-economy.md &&
grep -q '8 rules' docs/references/agents-code-economy.md
```
