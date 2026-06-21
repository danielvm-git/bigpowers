# e18s05: Add auto-timing to critical-path skills for stocktake effectiveness

**Status:** done

## Changes
- `scripts/bp-timing.sh` already existed with start/end commands
- `stocktake-skills/SKILL.md` already documented `metrics.skill_timings` effectiveness report
- Added `metrics.skill_timings` section to `specs/state.yaml`
- Instrumented 5 critical-path skills with `bp-timing.sh start|end` calls:
  - `survey-context/SKILL.md`
  - `plan-work/SKILL.md`
  - `develop-tdd/SKILL.md`
  - `verify-work/SKILL.md`
  - `release-branch/SKILL.md`

## Verify
```bash
grep -c "skill_timings\|timing\|effectiveness" stocktake-skills/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'
grep -c "bp-timing" survey-context/SKILL.md plan-work/SKILL.md develop-tdd/SKILL.md verify-work/SKILL.md release-branch/SKILL.md | awk '{sum+=$1} END {if(sum>=5) print "OK: " sum " timing refs"; else print "FAIL: only " sum " refs"}'
test -f scripts/bp-timing.sh && echo "OK: timing script exists" || echo "FAIL: no timing script"
```
