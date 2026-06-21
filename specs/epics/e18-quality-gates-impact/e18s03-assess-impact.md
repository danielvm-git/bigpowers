# e18s03: Wire assess-impact into build-epic step 2 (plan-work)

**Status:** done

## Changes
- Modified `assess-impact/SKILL.md` with `--lightweight` mode
- Modified `build-epic/SKILL.md` step 2 to invoke assess-impact before writing tasks
- Risk score > 7 gates grill-me session

## Verify
```bash
grep -c "assess-impact" build-epic/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'
grep -c "lightweight\|--lightweight\|quick.mode" assess-impact/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'
```
