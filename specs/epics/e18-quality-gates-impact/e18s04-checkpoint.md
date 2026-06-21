# e18s04: Universalize resume/checkpoint pattern to fix-bug and orchestrate-project

**Status:** done

## Changes
- `fix-bug/SKILL.md` already had 5-step counter with `bug_cycle.current_step` checkpoint/resume
- `orchestrate-project/SKILL.md` already had 6-phase counter with `project_cycle.current_phase` checkpoint/resume
- `session-state/SKILL.md` already had "Universal checkpoint pattern" section
- Added `bug_cycle` and `project_cycle` schema placeholders to `specs/state.yaml`

## Verify
```bash
grep -c "current_step\|checkpoint\|resume" fix-bug/SKILL.md | awk '{if($1>=3) print "OK"; else print "FAIL"}'
grep -c "current_phase\|checkpoint\|resume" orchestrate-project/SKILL.md | awk '{if($1>=3) print "OK"; else print "FAIL"}'
grep -q "bug_cycle:" specs/state.yaml && grep -q "project_cycle:" specs/state.yaml && echo "OK: state.yaml schema" || echo "FAIL: state.yaml schema"
```
