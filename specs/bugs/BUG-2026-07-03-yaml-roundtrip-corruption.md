---
bug_id: BUG-2026-07-03-yaml-roundtrip-corruption
status: open
severity: critical
scope: release-pipeline
title: "Release prepare-hook corrupts YAML cockpit via lossy round-trip — 40 spec files flattened and committed"
risk_level: critical
---

## Summary

The semantic-release `prepareCmd` destroys the project's YAML spec cockpit on
**every release**. As of 2026-07-03, **40 spec YAML files are corrupt and
committed to `main`**, including the two most load-bearing files:
`specs/release-plan.yaml` (collapsed from ~470 lines to 49 lines of garbage)
and `specs/state.yaml`.

This is the root cause of the traceability gate seeing only 1 story (see
[[BUG-2026-07-03-trace-engine-vacuous-gate]]) and is the same fail-open class
as the earlier validate-okf incidents.

## Root Cause

`.releaserc.json` wires a prepare hook:

```json
"prepareCmd": "bash scripts/sync-version-mirrors.sh ${nextRelease.version}"
```

`scripts/sync-version-mirrors.sh` calls `python3 scripts/yaml-tools.py set` to
stamp the new version into `specs/state.yaml` (`bigpowers_version`) and
`specs/release-plan.yaml` (`release.version`).

`scripts/yaml-tools.py` reads with a lossy hand-rolled `_parse_simple_yaml()`
and re-serializes with `dump_yaml()`. The round trip is **not information-
preserving**:

- All nesting is flattened to a fixed 2-space indent, destroying list/mapping structure.
- Block scalars (`note: >`, `rationale: >`) are emitted as `key: ">"` and their prose bodies are left as orphan lines.
- Every colon inside prose (`Source: "market survey..."`, `Delivered: "..."`) becomes a bogus top-level key.

Because this runs inside `@semantic-release/git`, the flattened file is
committed automatically as `chore(release): x.y.z [skip ci]` — so the
corruption is invisible in normal workflow and accumulates every release.

Ironic provenance: this hook was introduced as the *fix* for
[[BUG-2026-07-03-version-mirror-drift]]. The fix for drift created the
corruption.

## Blast Radius (measured 2026-07-03)

40 corrupt files confirmed via `python3 -c "import yaml; yaml.safe_load(open(f))"`:

- `specs/release-plan.yaml` (49L, was ~470L) — epic index destroyed
- `specs/state.yaml` (86L)
- `specs/epics/e36-doc-dedup/epic.yaml`, `e43-showcase-repo/epic.yaml`, `e46-risk-based-verification/epic.yaml` (e43/e46 born corrupt — no clean git version exists)
- ~33 `*-tasks.yaml` files, mostly under `specs/epics/archive/`
- `specs/benchmarks/reports/BASELINE-GOLDEN.yaml`, `specs/verifications/e13s03-verify.yaml`

## Fix Approach

1. **Stop the bleeding:** rewrite `scripts/yaml-tools.py` to use PyYAML
   (`yaml.safe_load` / `yaml.safe_dump`, installed 6.0.3) for both read and
   write, OR change `sync-version-mirrors.sh` to a surgical in-place line edit
   (`sed`-style single-field replace) that never re-serializes the whole file.
   Do not cut a release until this lands.
2. **Recover the 40 files** — reconstruct `release-plan.yaml` + `state.yaml`
   from the pre-corruption structure plus the ~224 still-valid capsule files;
   git-restore archive `*-tasks.yaml` where a clean version exists; hand-rebuild
   e43/e46 epic.yaml (born corrupt). Recovery source is a data-loss decision:
   reconstruct-to-preserve-plan vs git-restore-and-lose-recent-planning.
3. Depends on [[BUG-2026-07-03-validate-specs-no-real-parser]] landing first so
   recovery is gated by a real parse check.

## Verify Steps

- [ ] `python3 -c "import yaml,glob,sys; [yaml.safe_load(open(f)) for f in glob.glob('specs/**/*.yaml',recursive=True)]" && echo OK` (all specs parse)
- [ ] `bash scripts/sync-version-mirrors.sh 9.9.9-test && python3 -c "import yaml; yaml.safe_load(open('specs/release-plan.yaml'))" && echo OK` then revert (round-trip is now lossless)
- [ ] `python3 -c "import yaml; d=yaml.safe_load(open('specs/release-plan.yaml')); assert len(d['epics'])>=30" && echo OK`
