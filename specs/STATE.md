# Session State: bigpowers

## Current Milestone

**v3.0.0 — Consolidation Release** (in progress)

- 58 active skills (14 new), Verify phase, stack profiles, benchmark-gated evolve-skill
- Supersedes phased v2.2.0→v3.0.0 sequence in RELEASE-PLAN.md

## Git Metadata

- **Branch**: main
- **Hash**: (update at commit)

## Completed Releases

- [x] v2.0.0 — orchestrate-project + reference library
- [x] v2.1.0 — Repo health, SKILL-INDEX reconciliation
- [x] v2.1.1 — OpenCode integration

## Pending

- [ ] v3.0.0 merge — compliance 85/85 PASS; run full benchmark scoring at merge if required by release checklist

## Active Decisions

- **Solo Git profile** active — integrate via `scripts/land-branch.sh` (solo-local); see `profiles/solo-git.md` and `specs/WORKFLOW-solo-git.md`.
- **RELEASE-PLAN.md** is the single planning artifact (no PLAN.md).
- **handoff** folded into `session-state` (no standalone handoff skill).
- **search-skills** uses lexical index only (no embeddings).
- **Benchmark hard gate** for `evolve-skill` via bigpowers-benchmark repo.
