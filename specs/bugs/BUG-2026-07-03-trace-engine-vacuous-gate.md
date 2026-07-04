---
bug_id: BUG-2026-07-03-trace-engine-vacuous-gate
status: open
severity: high
scope: scripts
title: "trace-stories.py uses lossy hand-rolled YAML parser — collects 1 of ~240 stories, --strict gate passes vacuously"
risk_level: high
---

## Summary

`scripts/lib/trace-stories.py` builds the spec-to-code coverage matrix but
parses `release-plan.yaml` with its own copy of the lossy `parse_simple_yaml()`.
Against the current release-plan it collects **1 story** (e19s01) instead of
~240. With only one non-P0 story in the matrix, `--strict` finds no uncovered
P0 stories and **exits 0** — the e38 traceability gate, the crown jewel of the
methodology, is blind and reporting green. This is the third fail-open incident
in three sessions (validate-okf ×2, now trace).

## Root Cause

Two compounding causes:

1. **Upstream data corruption** — `release-plan.yaml` is destroyed
   (see [[BUG-2026-07-03-yaml-roundtrip-corruption]]), so even a correct parser
   would find few stories until the file is recovered.
2. **Own lossy parser** — `trace-stories.py` embeds `parse_simple_yaml()`
   (duplicated from `yaml-tools.py`) rather than using PyYAML. On the
   pre-corruption file it already mis-parsed the nested `epics:` list, and it
   provides no floor on story count, so a near-empty inventory silently yields a
   passing strict gate.

`--strict` computes a P0 threshold from the WSJF distribution of whatever
stories it found. With 1 story, the threshold logic degenerates and no story is
flagged. There is no assertion that the matrix is non-trivially populated.

## Fix Approach

1. Replace the embedded `parse_simple_yaml()` with `yaml.safe_load` (PyYAML
   6.0.3 is installed). Acceptance: regenerated matrix contains >= 230 stories.
2. Add a floor assertion: `--strict` FAILs if `total_stories` drops below a
   committed baseline (guards against a future parser/data regression silently
   emptying the matrix).
3. Add a **G-08 anti-vacuity golden check**: (a) matrix story-count >= baseline,
   and (b) `--strict` FAILs on a fixture whose P0 story has its tag removed.
   G-07 does this for the compliance step scripts; the trace engine — which has
   now failed open — has no equivalent.
4. Depends on [[BUG-2026-07-03-yaml-roundtrip-corruption]] recovery for the
   story count to actually reach baseline.

## Verify Steps

- [ ] `bash scripts/trace-stories.sh --json && python3 -c "import json; d=json.load(open('specs/traceability-matrix.json')); assert len(d['stories'])>=230, len(d['stories'])" && echo OK`
- [ ] Remove a P0 story tag in a fixture → `trace-stories.sh --strict` exits 2
- [ ] `bash scripts/golden-g08-*.sh` (new) passes
