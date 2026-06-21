# e18s02: Wire enforce-first (F.I.R.S.T) into build-epic gate chain

**Status:** done

## Changes
- Modified `enforce-first/SKILL.md` with `--quick` mode (Fast, Independent, Self-Validating)
- Modified `build-epic/SKILL.md` step 6 to add enforce-first --quick sub-check after audit-code passes

## Verify
```bash
grep -c "enforce-first" build-epic/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'
grep -c "quick\|--quick\|fast.mode" enforce-first/SKILL.md | awk '{if($1>=1) print "OK"; else print "FAIL"}'
```
