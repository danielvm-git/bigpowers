# story: e54s01 e54s02 e84s01
# Catalog Freeze (e54-e59 migration)

The 80-skill catalog is frozen as of `specs/tech-architecture/CATALOG-BASELINE-<date>.yaml` (e54s01) so e56's reclassification work (80 skills → ~28 procedures) has a stable starting point. `bash scripts/check-catalog-drift.sh` (e54s02) diffs the live catalog against that baseline on every Preflight run and prints `WARNING:` lines for drift — it is advisory only (exits 0) and never blocks Preflight or CI.

## Drift Triggers

- **Frozen (triggers drift warning):**
  - Adding a new `skills/<name>/SKILL.md` directory
  - Structural changes to an existing skill's `phase`, `effort`, or `model` frontmatter fields
- **Not frozen (no warning; proceed as normal):**
  - Bug fixes within an existing skill's shape
  - `description:` edits
  - Any other content fix not touching `phase`/`effort`/`model`

## Exit Criterion
The freeze ends when e56 (reclassify-catalog) merges. e56 completion is the unfreeze event itself.

## Exception Marker
A change genuinely unrelated to the migration can suppress its drift warning by adding a comment containing `freeze-exception` to the affected `SKILL.md`:

```html
<!-- freeze-exception: urgent security fix, unrelated to the e54-e59 migration -->
```

`scripts/check-catalog-drift.sh` checks for this exact substring. Use sparingly.

## Re-baselines
- 2026-11-07 (e83s04): five post-freeze breaks (define-success tombstone, simple-english added, smoke-test and validate-contracts phase set, context7-mcp removed) were resolved by a fresh `snapshot-catalog-baseline.sh` run. The 2026-07-23 file stays as the frozen e56 starting point; the drift check reads the newest baseline.
