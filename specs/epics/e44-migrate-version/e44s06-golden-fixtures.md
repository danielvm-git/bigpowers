# e44s06: Golden Test Fixtures & Roundtrip Validation

BCP: 2 | story: e44s06

## Summary

Create golden test fixtures representing downstream projects frozen at different
bigpowers versions. Run `migrate-version` against each, assert the output matches
expected results. Wire as G-06 golden story in the golden suite.

## Fixture Versions

Three fixtures covering the major spec format eras:

| Fixture | Era | Key markers |
|---------|-----|-------------|
| `tests/fixtures/v1.x-project/` | Pre-v2.0.0 (Markdown) | STATE.md, RELEASE-PLAN.md, SCOPE.md, CONTEXT.md, adr/ |
| `tests/fixtures/v2.0.0-project/` | YAML cockpit (no stamp) | state.yaml (no bigpowers_version), release-plan.yaml, execution-status.yaml, product/SCOPE_LATEST.yaml |
| `tests/fixtures/v2.20-project/` | Capsule era (no stamp) | state.yaml (has epic_cycle, no bigpowers_version), epics/e01/ capsule directory |

Each fixture is a minimal but valid downstream project:

```
tests/fixtures/v1.x-project/
├── specs/
│   ├── STATE.md
│   ├── RELEASE-PLAN.md
│   ├── SCOPE.md
│   ├── CONTEXT.md
│   └── adr/
│       └── 0001-use-kebab-case.md
├── CLAUDE.md
└── CONVENTIONS.md

tests/fixtures/v2.0.0-project/
├── specs/
│   ├── state.yaml              # no bigpowers_version key
│   ├── release-plan.yaml
│   ├── execution-status.yaml
│   └── product/
│       └── SCOPE_LATEST.yaml
├── CLAUDE.md
└── CONVENTIONS.md

tests/fixtures/v2.20-project/
├── specs/
│   ├── state.yaml              # has epic_cycle, no bigpowers_version
│   ├── release-plan.yaml
│   ├── execution-status.yaml
│   ├── metrics/
│   │   └── cycle-times.yaml
│   ├── product/
│   │   └── SCOPE_LATEST.yaml
│   └── epics/
│       └── e01-security.yaml   # flat YAML (pre-capsule)
├── CLAUDE.md
└── CONVENTIONS.md
```

## Expected Outputs

For each fixture, `tests/fixtures/vX.Y-expected/` contains the expected state
after migration to the current bigpowers version:

```
tests/fixtures/v1.x-expected/
├── specs/
│   ├── state.yaml              # migrated from STATE.md, has bigpowers_version
│   ├── release-plan.yaml       # migrated from RELEASE-PLAN.md
│   ├── execution-status.yaml   # created from scaffold
│   ├── product/
│   │   └── SCOPE_LATEST.yaml   # renamed from specs/SCOPE.md
│   └── tech-architecture/
│       ├── TECH_STACK_LATEST.md # renamed from specs/CONTEXT.md
│       └── adr/
│           └── 0001-use-kebab-case.md
│   └── archive/
│       └── STATE.md            # archived source
├── specs/migration-report-*.md # generated
├── CLAUDE.md
└── CONVENTIONS.md
```

## Roundtrip Validation

For each fixture:

1. Copy fixture to temp directory
2. Run `migrate-version.sh` in temp directory
3. Assert: exit code 0
4. Assert: `bigpowers_version` stamp present in state.yaml
5. Assert: `validate-specs-yaml.sh` passes on migrated specs
6. Assert: migrated files match expected outputs (diff -r)
7. Assert: `check_spec_version_gap.sh` returns exit 0 (no gap) on migrated output
8. Clean up temp directory

## Golden Story (G-06)

Wire `tests/run-golden-migrate-version.sh` into the golden suite as G-06:

```bash
# tests/run-golden-migrate-version.sh
# G-06: migrate-version roundtrip validation
# Runs all three fixture migrations, asserts correctness

for fixture in v1.x v2.0.0 v2.20; do
  tempdir=$(mktemp -d)
  cp -r tests/fixtures/${fixture}-project/ "$tempdir/"
  bash scripts/migrate-version.sh --force --target "$tempdir"
  assert_eq $? 0 "Migration $fixture must succeed"
  bash scripts/validate-specs-yaml.sh "$tempdir/specs/"
  assert_eq $? 0 "Migrated specs must validate"
  diff -r "$tempdir/specs/" "tests/fixtures/${fixture}-expected/specs/"
  assert_eq $? 0 "Migrated output must match expected"
  rm -rf "$tempdir"
done
```

Register in `.github/workflows/e44-golden-migrate-version.lock.yml` for per-epic
golden story cadence (matching e37 G-01 pattern).
