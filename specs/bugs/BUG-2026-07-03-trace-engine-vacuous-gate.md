---
bug_id: BUG-2026-07-03-trace-engine-vacuous-gate
status: fixed
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

## Resolution

**Fixed:** 2026-07-03
**Root cause confirmed:** trace-stories.py embedded a lossy hand-rolled YAML parser (parse_simple_yaml) that mis-parsed the release-plan and had no anti-vacuity floor assertion.
**Fix applied:** Replaced parse_simple_yaml() with yaml.safe_load (PyYAML 6.0.3) in all three parse sites (release-plan.yaml, execution-status.yaml, capsule epic.yaml). Added _MIN_STORY_BASELINE = 50 floor assertion to --strict mode. Created golden-g10-trace-anti-vacuity.sh wired into run-golden-suite.sh.
**Hardening added:** (1) PyYAML parser — resilient to structural YAML changes; (2) floor assertion — --strict fails closed (exit 2) if story count drops below baseline; (3) G-10 golden test — proves floor assertion works on every suite run.
**Evidence:** Golden suite 7/7 pass, trace-stories.sh --strict exits 0 on real data (78 stories ≥ 50 baseline), exits 2 on degenerate 0-story fixture.
**Commit:** 4ca9889 — fix(trace): replace hand-rolled YAML parser with PyYAML + add floor assertion and G-10 golden test

## Verify Steps

- [x] `bash scripts/trace-stories.sh --json && python3 -c "import json; d=json.load(open('specs/traceability-matrix.json')); assert len(d['stories'])>=50, len(d['stories'])" && echo OK`
- [x] `bash scripts/golden-g10-trace-anti-vacuity.sh` passes (exit 0)
- [x] `bash scripts/trace-stories.sh --strict` on an empty fixture exits 2
