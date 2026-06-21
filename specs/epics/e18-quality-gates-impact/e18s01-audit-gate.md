# e18s01: audit-code as hard gate in build-epic step 6

**Status:** done

## Changes
- Modified `build-epic/SKILL.md` step 6 to invoke audit-code as non-optional gate
- Modified `audit-code/SKILL.md` with `--gate` mode (non-zero exit on failure)
- loop-back: failed audit resets `epic_cycle.current_step` to 4 (develop-tdd)
- Audit artifact: `specs/verifications/AUDIT-<epic>-<story>.md`
- `epic_cycle.audit_result: pass|fail` in state.yaml

## Verify
```bash
grep -c "audit-code" build-epic/SKILL.md | awk '{if($1>=3) print "OK"; else print "FAIL"}'
grep -c "gate\|--gate\|non-zero" audit-code/SKILL.md | awk '{if($1>=2) print "OK"; else print "FAIL"}'
```
