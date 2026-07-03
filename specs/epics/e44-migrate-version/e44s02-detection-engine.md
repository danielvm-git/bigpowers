# e44s02: Version Detection Engine

BCP: 2 | story: e44s02

## Summary

Create `scripts/check-spec-version-gap.sh` — the shared detection function used by both
`survey-context` and `migrate-version`. Implements dual detection: fingerprint-based
bootstrap for projects without a stamp, and stamp-based detection for projects that
have been upgraded before.

## Detection Algorithm

```
check_spec_version_gap()
  ↓
  Read state.yaml → bigpowers_version key?
  │
  ├─ YES (stamp exists) ──→ compare vs installed version
  │                         │
  │                         ├─ match → no gap (exit 0, SKIP)
  │                         └─ mismatch → gap detected
  │
  └─ NO (pre-v2.0.0 or un-stamped) ──→ run fingerprint scan
                                        │
                                        ├─ STATE.md exists → v1.x (pre-YAML)
                                        ├─ state.yaml + no bigpowers_version → v2.0.0+ (unstamped)
                                        └─ no specs/ at all → UNKNOWN
```

## Fingerprint Table

Heuristic markers that identify a downstream project's spec era:

| Fingerprint | Inferred Version | Confidence |
|-------------|-----------------|------------|
| `specs/STATE.md` exists | pre-v2.0.0 | High |
| `specs/state.yaml` exists, no `bigpowers_version` key | v2.0.0 – v2.53.0 | Medium |
| `specs/state.yaml` has `epic_cycle` key | v2.20.0+ | Medium |
| `specs/state.yaml` has `handoff.next_skill` | v2.0.0+ | Medium |
| `specs/metrics/cycle-times.yaml` exists | v2.0.0+ | Medium |
| `specs/epics/*/` capsule directories exist | v2.20+ | Medium |
| `specs/execution-status.yaml` exists | v2.0.0+ | Medium |
| `specs/product/SCOPE_LATEST.yaml` exists | v2.0.0+ | Medium |

When no stamp exists: run all fingerprints, pick the lowest version that matches
all present markers. Flag confidence in the output.

## Script Interface

```bash
# Exit codes:
#   0: no gap (version matches)
#   1: gap detected (stderr has JSON with gap details)
#   2: NO_SPECS (no specs/ directory, not a bigpowers project)
#   3: BLOCKED (active work detected: non-main branch, uncommitted specs/)
#   4: ERROR (unexpected failure)

# Output (on gap, exit code 1, to stderr as JSON):
{
  "gap": true,
  "stamp": false,
  "detected_version": "2.0.0",
  "detection_method": "fingerprint",
  "installed_version": "2.54.0",
  "applicable_migrations": 2,
  "migration_ids": ["m1-yaml-cockpit", "m2-legacy-paths"],
  "confidence": "medium",
  "active_work_blocked": false
}
```

## Integration Points

| Consumer | How it uses |
|----------|-------------|
| `survey-context` | Calls `check_spec_version_gap` at session start. If gap, surfaces as recommendation with `handoff.next_skill: migrate-version`. |
| `migrate-version` | Calls `check_spec_version_gap` as its entry point. Uses the JSON output to load applicable migrations. |
| `build-epic` Step 0 | Optionally calls `check_spec_version_gap` as a pre-flight check. |
