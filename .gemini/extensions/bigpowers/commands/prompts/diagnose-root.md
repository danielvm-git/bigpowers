
# Diagnose Root

Four phases — do not skip. Update the active `specs/bugs/BUG-*.md` file at each phase.

## Phases

1. **Reproduce** — minimal steps; record environment; capture logs.
2. **Isolate** — narrow to module/function; binary-search commits or config.
3. **Hypothesize** — list ranked hypotheses with falsification test each.
4. **Verify** — run falsification; confirm single root cause; link to fix plan.

> **HARD GATE** — Do not propose a fix until phase 4 confirms one root cause with evidence.

## Verify

→ verify: `BUG_FILE=$(ls -t specs/bugs/BUG-*.md 2>/dev/null | head -1); test -n "$BUG_FILE" && grep -cE "Reproduce|Isolate|Hypothesize|Verify" "$BUG_FILE" | awk '{if($1>=4) print "OK"; else print "INCOMPLETE"}' || echo "MISSING"`
