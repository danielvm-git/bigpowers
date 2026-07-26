# Archived workflow diagrams

<!-- story: e37s05 -->

Retired 2026-07-26. Both files are BMad Method charts:
`workflow-method-greenfield.*` is the original, and `bigpowers-workflow.*` is a
find-and-replace of it with bigpowers skill names dropped into BMad's agent slots
(identical structure, `PHASE 1-4`, `Include Discover?`, `Tests Pass?`,
`More Sprints?`, same legend layout; both Excalidraw sources are 116.0K).

Nothing regenerated them, so the bigpowers one drifted from the catalog:

- routed PLAN through `define-success`, archived and since tombstoned
- placed `seed-conventions` in PHASE 4 (Implement) when it is the greenfield
  entry point that writes CLAUDE.md before anything else runs
- put `validate-fix`, a bug-fix skill, inside the greenfield task loop
- omitted the planning spine (`scope-work` → `slice-tasks` → `plan-work`)
- omitted `build-epic`, the nine-step loop where the work actually happens
- omitted `verify-work`, `audit-code` and `release-branch` entirely
- used "Sprints", a word that appears in no bigpowers doctrine file

Replaced by `docs/WORKFLOWS.md`, generated from `specs/workflows/*.yaml` by
`scripts/generate-workflow-diagrams.sh` and kept fresh by a `--check` gate.
