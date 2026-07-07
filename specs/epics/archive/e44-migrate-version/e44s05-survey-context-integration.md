# e44s05: survey-context Integration

BCP: 1 | story: e44s05

## Summary

Wire `check_spec_version_gap()` into `survey-context` so every session start detects
format gaps. Surface the gap as a recommendation with `handoff.next_skill: migrate-version`.

## Integration Pattern

`survey-context` already reads `specs/state.yaml` on every session start. The integration
adds a new check after the existing phase mapping:

```
Survey Context (current flow):
  1. Read CONVENTIONS.md
  2. Read specs/
  3. Read CLAUDE.md
  4. Check git state
  5. Map lifecycle phase        ← NEW CHECK inserted here
  6. Suggest next skill
  7. Surface blockers

Survey Context (with e44s05):
  ...
  5. Map lifecycle phase
  5a. Run check_spec_version_gap()     ← ADDED
      ├─ Exit 0 (no gap) → silent
      ├─ Exit 1 (gap)     → surface as recommendation
      │   "⚠ Spec format gap detected: v2.0.0 → v2.54.0 (2 migrations available)."
      │   handoff.next_skill: migrate-version
      ├─ Exit 2 (no specs) → silent (not a bigpowers project)
      └─ Exit 3 (blocked)  → surface as blocker
          "⚠ Active work detected. Complete current epic before migrating specs."
  6. Suggest next skill
  7. Surface blockers
```

## Handoff Contract

When a gap is detected and no active work blocks it:

```yaml
handoff:
  next_skill: migrate-version
  context: "Spec format gap: v2.0.0 → v2.54.0. 2 migrations available (m1, m2). Run migrate-version to upgrade your specs directory."
```

When active work blocks migration:

```yaml
handoff:
  next_skill: develop-tdd   # continue current work
  context: "Active epic e38 in progress. Finish or stash current work before running migrate-version."
```

## Changes Required

| File | Change |
|------|--------|
| `skills/survey-context/SKILL.md` | Add step 5a: "Check for spec version gap — run check_spec_version_gap.sh. If gap detected, surface as recommendation." |
| `skills/survey-context/SKILL.md` | Add gap details to the lifecycle phase mapping table (new row for "migration needed"). |
