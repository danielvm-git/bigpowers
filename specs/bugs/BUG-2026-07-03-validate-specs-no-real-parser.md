---
bug_id: BUG-2026-07-03-validate-specs-no-real-parser
status: open
severity: high
scope: scripts
title: "validate-specs-yaml.sh does no real YAML parsing — grep-only checks let 40 corrupt files pass every gate"
risk_level: high
---

## Summary

`scripts/validate-specs-yaml.sh` is the project's only spec-YAML validation
gate, but it never parses YAML. It only `grep`s for the presence of a handful
of key strings. Flattened, structurally-destroyed YAML still contains those
strings, so the gate reports `validate-specs-yaml: OK` on catastrophically
corrupt files. This is the "who watches the watchmen" hole that hid
[[BUG-2026-07-03-yaml-roundtrip-corruption]] across dozens of releases.

## Root Cause

The validator is a sequence of `grep -qE` presence checks:

```bash
need "$SPECS/release-plan.yaml" '^epics:'  'missing epics list'
need "$SPECS/release-plan.yaml" 'version:' 'missing release.version'
```

A file collapsed to 49 lines of flattened garbage still matches `^epics:` and
`version:`, so it passes. There is no `yaml.safe_load` anywhere in the
validation path. This is the same fail-open pattern as the validate-okf and
trace-stories incidents: a gate that structurally cannot fail on the input it
is meant to catch.

## Fix Approach

1. Add a real parse pass: iterate every `specs/**/*.yaml`, run
   `python3 -c "import yaml; yaml.safe_load(open(f))"`, and FAIL (exit non-zero)
   on the first `ParserError`, printing file + line.
2. Keep the required-key checks, but run them against the *parsed* object, not
   grep.
3. Add this to CI (`sync-skills.yml`) so corruption can never be committed
   silently again.
4. Consider a G-08 anti-vacuity golden check: feed the validator a known-corrupt
   fixture and assert it FAILs (mirrors G-07's negative-path pattern).

## Verify Steps

- [ ] `printf 'a:\n b: [\n' > /tmp/bad.yaml; bash scripts/validate-specs-yaml.sh` FAILs when a corrupt file is present (fixture)
- [ ] `bash scripts/validate-specs-yaml.sh && echo OK` passes only when all specs `yaml.safe_load` cleanly
- [ ] CI job runs the parse gate on push
